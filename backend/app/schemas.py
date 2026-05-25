from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    username: str
    password: str


class LoginResponse(BaseModel):
    access_token: str
    token_type: Literal["bearer"] = "bearer"
    role: str
    username: str


class UserOut(BaseModel):
    user_id: str
    username: str
    role: str
    is_active: bool
    created_at: datetime
    last_login_at: datetime | None = None

    model_config = {"from_attributes": True}


class UserCreate(BaseModel):
    username: str = Field(min_length=1, max_length=64)
    password: str = Field(min_length=8, max_length=128)
    role: Literal["user", "admin"] = "user"


class UserUpdate(BaseModel):
    role: Literal["user", "admin"] | None = None
    is_active: bool | None = None


class PasswordReset(BaseModel):
    new_password: str = Field(min_length=8, max_length=128)


class DocumentOut(BaseModel):
    doc_id: str
    title: str
    source: str
    chunk_count: int
    created_at: datetime

    model_config = {"from_attributes": True}


class DocumentDetail(DocumentOut):
    mime_type: str
    sha256: str
    size_bytes: int
    updated_at: datetime


class ChunkOut(BaseModel):
    chunk_id: str
    ordinal: int
    text: str
    token_count: int

    model_config = {"from_attributes": True}


class ChatRequest(BaseModel):
    session_id: str | None = None
    query: str = Field(min_length=1, max_length=4000)
    top_k: int = Field(default=4, ge=1, le=20)
    filters: dict[str, Any] | None = None


class RetrievedChunk(BaseModel):
    chunk_id: str
    doc_id: str
    source: str
    score: float
    text: str


class RetrievalTestRequest(BaseModel):
    query: str = Field(min_length=1, max_length=4000)
    top_k: int = Field(default=4, ge=1, le=20)
    filters: dict[str, Any] | None = None


class RetrievalTestResponse(BaseModel):
    chunks: list[RetrievedChunk]


class ChunkTestRequest(BaseModel):
    text: str = Field(min_length=1, max_length=200_000)
    splitter: Literal["recursive", "agentic"] = "recursive"
    chunk_size: int = Field(default=800, ge=100, le=4000)
    chunk_overlap: int = Field(default=120, ge=0, le=2000)


class ChunkTestChunk(BaseModel):
    ordinal: int
    text: str
    char_count: int


class ChunkTestResponse(BaseModel):
    splitter: str
    chunk_count: int
    chunks: list[ChunkTestChunk]


class IngestConfigOut(BaseModel):
    chunk_size: int
    chunk_overlap: int
    splitter: str
    updated_at: datetime
    updated_by: str | None = None


class IngestConfigUpdate(BaseModel):
    chunk_size: int = Field(ge=100, le=4000)
    chunk_overlap: int = Field(ge=0, le=2000)
    splitter: Literal["recursive", "markdown_aware"] = "recursive"


class IngestConfigUpdateResponse(IngestConfigOut):
    requires_rebuild: bool = True


class IngestConfigHistoryOut(BaseModel):
    history_id: str
    chunk_size: int
    chunk_overlap: int
    splitter: str
    changed_at: datetime
    changed_by: str | None = None

    model_config = {"from_attributes": True}


class MessageOut(BaseModel):
    message_id: str
    role: str
    content: str
    citations_json: list | None = None
    status: str
    created_at: datetime

    model_config = {"from_attributes": True}


class SessionDetail(BaseModel):
    session_id: str
    created_at: datetime
    messages: list[MessageOut]

    model_config = {"from_attributes": True}
