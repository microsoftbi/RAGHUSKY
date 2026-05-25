from fastapi import APIRouter, Depends, HTTPException

from app.deps import require_admin
from app.models import User
from app.rag.chunker import AgenticChunkingError, make_splitter
from app.schemas import ChunkTestChunk, ChunkTestRequest, ChunkTestResponse

router = APIRouter(prefix="/admin/chunk-test", tags=["admin:chunk-test"])


@router.post("", response_model=ChunkTestResponse)
def chunk_test(
    payload: ChunkTestRequest,
    _: User = Depends(require_admin),
) -> ChunkTestResponse:
    if payload.chunk_overlap >= payload.chunk_size:
        raise HTTPException(status_code=400, detail="chunk_overlap must be less than chunk_size")

    splitter = make_splitter(payload.splitter, payload.chunk_size, payload.chunk_overlap)
    try:
        pieces = splitter.split_text(payload.text)
    except AgenticChunkingError as e:
        raise HTTPException(status_code=502, detail=f"agentic chunking failed: {e}") from e

    chunks = [
        ChunkTestChunk(ordinal=i, text=t, char_count=len(t))
        for i, t in enumerate(pieces)
    ]
    return ChunkTestResponse(
        splitter=payload.splitter,
        chunk_count=len(chunks),
        chunks=chunks,
    )
