from fastapi import APIRouter, Depends
from sqlalchemy import or_
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import require_admin
from app.models import Document
from app.schemas import DocumentDetail

router = APIRouter(prefix="/admin/documents", tags=["admin:documents"])


@router.get("", response_model=list[DocumentDetail])
def list_documents_admin(
    q: str | None = None,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
) -> list[Document]:
    query = db.query(Document)
    if q:
        like = f"%{q}%"
        query = query.filter(or_(Document.title.ilike(like), Document.source.ilike(like)))
    return query.order_by(Document.created_at.desc()).all()
