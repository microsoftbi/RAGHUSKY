from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.db import get_db
from app.deps import require_admin
from app.models import User
from app.schemas import PasswordReset, UserCreate, UserOut, UserUpdate
from app.security import hash_password

router = APIRouter(prefix="/admin/users", tags=["admin:users"])


def _count_active_admins(db: Session, exclude_id: str | None = None) -> int:
    q = db.query(User).filter(User.role == "admin", User.is_active.is_(True))
    if exclude_id:
        q = q.filter(User.user_id != exclude_id)
    return q.count()


@router.get("", response_model=list[UserOut])
def list_users(db: Session = Depends(get_db), _: User = Depends(require_admin)) -> list[User]:
    return db.query(User).order_by(User.created_at.desc()).all()


@router.post("", response_model=UserOut, status_code=201)
def create_user(
    payload: UserCreate, db: Session = Depends(get_db), _: User = Depends(require_admin)
) -> User:
    if db.query(User).filter(User.username == payload.username).first():
        raise HTTPException(status_code=400, detail="Username already exists")
    user = User(
        username=payload.username,
        password_hash=hash_password(payload.password),
        role=payload.role,
        is_active=True,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


@router.patch("/{user_id}", response_model=UserOut)
def update_user(
    user_id: str,
    payload: UserUpdate,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
) -> User:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")

    new_role = payload.role if payload.role is not None else user.role
    new_active = payload.is_active if payload.is_active is not None else user.is_active

    if user.user_id == admin.user_id:
        if new_role != "admin":
            raise HTTPException(status_code=400, detail="Cannot downgrade your own role")
        if not new_active:
            raise HTTPException(status_code=400, detail="Cannot deactivate yourself")

    would_be_admins = _count_active_admins(db, exclude_id=user.user_id)
    if new_role == "admin" and new_active:
        would_be_admins += 1
    if would_be_admins < 1:
        raise HTTPException(status_code=400, detail="At least one active admin must remain")

    user.role = new_role
    user.is_active = new_active
    db.commit()
    db.refresh(user)
    return user


@router.post("/{user_id}/reset-password", status_code=204)
def reset_password(
    user_id: str,
    payload: PasswordReset,
    db: Session = Depends(get_db),
    _: User = Depends(require_admin),
) -> None:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    user.password_hash = hash_password(payload.new_password)
    db.commit()


@router.delete("/{user_id}", status_code=204)
def delete_user(
    user_id: str,
    db: Session = Depends(get_db),
    admin: User = Depends(require_admin),
) -> None:
    user = db.get(User, user_id)
    if user is None:
        raise HTTPException(status_code=404, detail="User not found")
    if user.user_id == admin.user_id:
        raise HTTPException(status_code=400, detail="Cannot delete yourself")
    remaining = _count_active_admins(db, exclude_id=user.user_id)
    if remaining < 1:
        raise HTTPException(status_code=400, detail="At least one active admin must remain")
    db.delete(user)
    db.commit()
