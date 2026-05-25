from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session

from app.config import get_settings
from app.db import get_db
from app.deps import get_current_user
from app.models import Chunk, Document
from app.schemas import ChunkOut, DocumentOut

router = APIRouter(prefix="/documents", tags=["documents"])


@router.get("", response_model=list[DocumentOut])
def list_documents(db: Session = Depends(get_db), _=Depends(get_current_user)) -> list[Document]:
    return db.query(Document).order_by(Document.created_at.desc()).all()


@router.get("/{doc_id}/chunks", response_model=list[ChunkOut])
def list_chunks(
    doc_id: str,
    db: Session = Depends(get_db),
    _=Depends(get_current_user),
) -> list[Chunk]:
    doc = db.get(Document, doc_id)
    if doc is None:
        raise HTTPException(status_code=404, detail="document not found")
    return (
        db.query(Chunk)
        .filter(Chunk.doc_id == doc_id)
        .order_by(Chunk.ordinal.asc())
        .all()
    )


@router.get("/{doc_id}/raw")
def get_raw(
    doc_id: str,
    db: Session = Depends(get_db),
    _=Depends(get_current_user),
):
    doc = db.get(Document, doc_id)
    if doc is None:
        raise HTTPException(status_code=404, detail="document not found")
    docs_root = get_settings().documents_path
    candidate = (docs_root / doc.source).resolve()
    try:
        candidate.relative_to(docs_root)
    except ValueError:
        raise HTTPException(status_code=400, detail="invalid document path")
    if not candidate.is_file():
        raise HTTPException(status_code=404, detail="file not found on disk")
    return FileResponse(
        path=str(candidate),
        media_type=doc.mime_type,
        filename=Path(doc.source).name,
        content_disposition_type="inline",
    )
