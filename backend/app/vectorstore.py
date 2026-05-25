import hashlib
import re
from functools import lru_cache

import chromadb
from chromadb.api import ClientAPI
from chromadb.api.models.Collection import Collection

from app.config import get_settings


def _slug(name: str) -> str:
    return re.sub(r"[^a-zA-Z0-9]+", "-", name).strip("-").lower()


def config_hash(embedding_model: str, chunk_size: int, chunk_overlap: int, splitter: str) -> str:
    raw = f"{embedding_model}|{chunk_size}|{chunk_overlap}|{splitter}"
    return hashlib.sha1(raw.encode("utf-8")).hexdigest()[:8]


def collection_name(embedding_model: str, chunk_size: int, chunk_overlap: int, splitter: str) -> str:
    return f"kb_{_slug(embedding_model)}_v{config_hash(embedding_model, chunk_size, chunk_overlap, splitter)}"


@lru_cache(maxsize=1)
def get_client() -> ClientAPI:
    settings = get_settings()
    return chromadb.PersistentClient(path=settings.chroma_path)


def get_or_create_collection(name: str, *, metadata: dict | None = None) -> Collection:
    client = get_client()
    return client.get_or_create_collection(name=name, metadata=metadata or {"hnsw:space": "cosine"})


def delete_collection_if_exists(name: str) -> None:
    client = get_client()
    try:
        client.delete_collection(name=name)
    except Exception:
        pass


def list_collections() -> list[str]:
    return [c.name for c in get_client().list_collections()]
