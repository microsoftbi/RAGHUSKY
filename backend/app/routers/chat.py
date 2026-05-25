import json
import re
from collections.abc import AsyncIterator

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sse_starlette.sse import EventSourceResponse

from app.config import get_settings
from app.db import SessionLocal, get_db
from app.deps import get_current_user
from app.llm import astream_answer
from app.logging_setup import log_event
from app.models import ChatSession, Message, User
from app.rag.prompt import render
from app.rag.retriever import RetrievedItem, search
from app.schemas import ChatRequest

router = APIRouter(prefix="/chat", tags=["chat"])

_CITE = re.compile(r"\[([0-9a-fA-F-]{6,36})\]")


def _ensure_session(db: Session, session_id: str | None, user_id: str) -> ChatSession:
    if session_id:
        s = db.get(ChatSession, session_id)
        if s is not None:
            return s
    s = ChatSession(user_id=user_id)
    db.add(s)
    db.commit()
    db.refresh(s)
    return s


def _persist(session_id: str, query: str, answer: str, citations: list[str], status: str) -> None:
    db = SessionLocal()
    try:
        db.add(Message(session_id=session_id, role="user", content=query, status="ok"))
        db.add(
            Message(
                session_id=session_id,
                role="assistant",
                content=answer,
                citations_json=citations,
                status=status,
            )
        )
        db.commit()
    finally:
        db.close()


async def _event_stream(
    session_id: str,
    user_id: str,
    username: str,
    chunks: list[RetrievedItem],
    system_prompt: str,
    user_prompt: str,
    query: str,
) -> AsyncIterator[dict]:
    log_event(
        "ragusky.chat",
        "query",
        session_id=session_id,
        user_id=user_id,
        username=username,
        query=query,
        retrieved=[
            {
                "chunk_id": c.chunk_id,
                "doc_id": c.doc_id,
                "source": c.source,
                "score": c.score,
            }
            for c in chunks
        ],
    )
    yield {
        "event": "session",
        "data": json.dumps({"session_id": session_id}, ensure_ascii=False),
    }
    yield {
        "event": "retrieved",
        "data": json.dumps(
            {
                "chunks": [
                    {
                        "chunk_id": c.chunk_id,
                        "doc_id": c.doc_id,
                        "source": c.source,
                        "score": c.score,
                        "snippet": c.text[:200],
                    }
                    for c in chunks
                ]
            },
            ensure_ascii=False,
        ),
    }

    full: list[str] = []
    status = "ok"
    try:
        async for delta in astream_answer(system_prompt, user_prompt):
            full.append(delta)
            yield {"event": "token", "data": json.dumps({"delta": delta}, ensure_ascii=False)}
    except Exception as e:  # surface error to client, persist partial
        status = "error"
        yield {"event": "error", "data": json.dumps({"message": str(e)}, ensure_ascii=False)}

    answer = "".join(full)
    cited_ids = list({m.group(1) for m in _CITE.finditer(answer)})
    valid_cids = {c.chunk_id for c in chunks}
    citations = [cid for cid in cited_ids if cid in valid_cids]
    _persist(session_id, query, answer, citations, status if full else "empty")

    log_event(
        "ragusky.chat",
        "answer",
        session_id=session_id,
        user_id=user_id,
        username=username,
        query=query,
        answer=answer,
        citations=citations,
        status=status if full else "empty",
        answer_chars=len(answer),
    )

    yield {
        "event": "done",
        "data": json.dumps(
            {"session_id": session_id, "answer": answer, "citations": citations, "status": status},
            ensure_ascii=False,
        ),
    }


@router.post("")
async def chat(
    payload: ChatRequest,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
):
    settings = get_settings()
    session = _ensure_session(db, payload.session_id, user.user_id)
    retrieved = search(
        db,
        embedding_model=settings.embedding_model,
        query=payload.query,
        top_k=payload.top_k,
        filters=payload.filters,
    )
    system_prompt, user_prompt = render(payload.query, retrieved)
    return EventSourceResponse(
        _event_stream(
            session.session_id,
            user.user_id,
            user.username,
            retrieved,
            system_prompt,
            user_prompt,
            payload.query,
        )
    )
