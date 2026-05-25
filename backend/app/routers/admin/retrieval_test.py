from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_db
from app.deps import require_admin
from app.logging_setup import log_event
from app.models import User
from app.rag.retriever import search
from app.schemas import RetrievalTestRequest, RetrievalTestResponse, RetrievedChunk

router = APIRouter(prefix="/admin/retrieval-test", tags=["admin:retrieval"])


@router.post("", response_model=RetrievalTestResponse)
def retrieval_test(
    payload: RetrievalTestRequest,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
) -> RetrievalTestResponse:
    settings = get_settings()
    items = search(
        db,
        embedding_model=settings.embedding_model,
        query=payload.query,
        top_k=payload.top_k,
        filters=payload.filters,
    )
    log_event(
        "ragusky.retrieval",
        "retrieval_test",
        admin_user_id=admin.user_id,
        admin_username=admin.username,
        query=payload.query,
        top_k=payload.top_k,
        filters=payload.filters,
        results=[
            {
                "chunk_id": i.chunk_id,
                "doc_id": i.doc_id,
                "source": i.source,
                "score": i.score,
                "snippet": i.text[:200],
            }
            for i in items
        ],
    )
    return RetrievalTestResponse(
        chunks=[
            RetrievedChunk(
                chunk_id=i.chunk_id, doc_id=i.doc_id, source=i.source, score=i.score, text=i.text
            )
            for i in items
        ]
    )
