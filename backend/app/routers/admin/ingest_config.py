from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import require_admin
from app.models import IngestConfig, IngestConfigHistory, User
from app.schemas import (
    IngestConfigHistoryOut,
    IngestConfigOut,
    IngestConfigUpdate,
    IngestConfigUpdateResponse,
)

router = APIRouter(prefix="/admin/ingest-config", tags=["admin:ingest-config"])


def _to_out(cfg: IngestConfig) -> IngestConfigOut:
    return IngestConfigOut(
        chunk_size=cfg.chunk_size,
        chunk_overlap=cfg.chunk_overlap,
        splitter=cfg.splitter,
        updated_at=cfg.updated_at,
        updated_by=cfg.updated_by,
    )


@router.get("", response_model=IngestConfigOut)
def get_config(db: Session = Depends(get_db), _=Depends(require_admin)) -> IngestConfigOut:
    cfg = db.get(IngestConfig, 1)
    if cfg is None:
        raise HTTPException(status_code=500, detail="ingest_config not initialized")
    return _to_out(cfg)


@router.put("", response_model=IngestConfigUpdateResponse)
def update_config(
    payload: IngestConfigUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
) -> IngestConfigUpdateResponse:
    if payload.chunk_overlap >= payload.chunk_size:
        raise HTTPException(status_code=400, detail="chunk_overlap must be less than chunk_size")

    cfg = db.get(IngestConfig, 1)
    if cfg is None:
        cfg = IngestConfig(id=1, chunk_size=payload.chunk_size, chunk_overlap=payload.chunk_overlap,
                           splitter=payload.splitter, updated_by=admin.user_id)
        db.add(cfg)
    else:
        cfg.chunk_size = payload.chunk_size
        cfg.chunk_overlap = payload.chunk_overlap
        cfg.splitter = payload.splitter
        cfg.updated_by = admin.user_id

    db.add(
        IngestConfigHistory(
            chunk_size=payload.chunk_size,
            chunk_overlap=payload.chunk_overlap,
            splitter=payload.splitter,
            changed_by=admin.user_id,
        )
    )
    db.commit()
    db.refresh(cfg)
    out = _to_out(cfg)
    return IngestConfigUpdateResponse(**out.model_dump(), requires_rebuild=True)


@router.get("/history", response_model=list[IngestConfigHistoryOut])
def list_history(
    limit: int = 50,
    db: Session = Depends(get_db),
    _=Depends(require_admin),
) -> list[IngestConfigHistory]:
    limit = max(1, min(limit, 500))
    return (
        db.query(IngestConfigHistory)
        .order_by(IngestConfigHistory.changed_at.desc())
        .limit(limit)
        .all()
    )
