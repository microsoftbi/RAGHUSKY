from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import get_current_user
from app.models import ChatSession, User
from app.schemas import SessionDetail

router = APIRouter(prefix="/sessions", tags=["sessions"])


@router.get("/{session_id}", response_model=SessionDetail)
def get_session(
    session_id: str,
    db: Session = Depends(get_db),
    user: User = Depends(get_current_user),
) -> ChatSession:
    s = db.get(ChatSession, session_id)
    if s is None:
        raise HTTPException(status_code=404, detail="Session not found")
    if user.role != "admin" and s.user_id is not None and s.user_id != user.user_id:
        raise HTTPException(status_code=403, detail="Forbidden")
    return s
