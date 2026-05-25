from dataclasses import dataclass
from typing import Any

from sqlalchemy.orm import Session

from app.embeddings import get_embeddings
from app.models import IngestConfig
from app.vectorstore import collection_name, get_or_create_collection

AGENTIC_SPLITTER_NAME = "agentic"


@dataclass
class RetrievedItem:
    chunk_id: str
    doc_id: str
    source: str
    score: float
    text: str


def _read_config(db: Session) -> IngestConfig:
    cfg = db.get(IngestConfig, 1)
    if cfg is None:
        raise RuntimeError("ingest_config row missing — bootstrap did not run")
    return cfg


def _query_one(name: str, query_vec, top_k: int, filters):
    collection = get_or_create_collection(name)
    res = collection.query(
        query_embeddings=[query_vec],
        n_results=top_k,
        where=filters or None,
        include=["metadatas", "documents", "distances"],
    )
    ids = (res.get("ids") or [[]])[0]
    metas = (res.get("metadatas") or [[]])[0]
    docs = (res.get("documents") or [[]])[0]
    dists = (res.get("distances") or [[]])[0]
    out: list[RetrievedItem] = []
    for cid, meta, text, dist in zip(ids, metas, docs, dists):
        out.append(
            RetrievedItem(
                chunk_id=cid,
                doc_id=(meta or {}).get("doc_id", ""),
                source=(meta or {}).get("source", ""),
                score=float(1.0 - dist) if dist is not None else 0.0,
                text=text or "",
            )
        )
    return out


def search(
    db: Session,
    *,
    embedding_model: str,
    query: str,
    top_k: int = 4,
    filters: dict[str, Any] | None = None,
) -> list[RetrievedItem]:
    cfg = _read_config(db)
    default_name = collection_name(embedding_model, cfg.chunk_size, cfg.chunk_overlap, cfg.splitter)
    agentic_name = collection_name(
        embedding_model, cfg.chunk_size, cfg.chunk_overlap, AGENTIC_SPLITTER_NAME
    )

    embeddings = get_embeddings()
    query_vec = embeddings.embed_query(query)

    names = [default_name]
    if agentic_name != default_name:
        names.append(agentic_name)

    merged: list[RetrievedItem] = []
    seen: set[str] = set()
    for name in names:
        try:
            for item in _query_one(name, query_vec, top_k, filters):
                if item.chunk_id in seen:
                    continue
                seen.add(item.chunk_id)
                merged.append(item)
        except Exception:
            continue

    merged.sort(key=lambda x: x.score, reverse=True)
    return merged[:top_k]
