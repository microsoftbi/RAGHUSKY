"""Offline ingest script. Run from backend/ as:

    uv run python -m scripts.ingest [--rebuild] [--dry-run] [--no-prune] [--documents-dir PATH]

Routing rule: files under `Documents/Agentic/` are chunked with the agentic
LLM splitter; everything else uses the configured splitter from ingest_config.
Each splitter writes to its own Chroma collection so vectors never mix.
"""

from __future__ import annotations

import argparse
import hashlib
import logging
import sys
from collections import Counter
from pathlib import Path

from app.config import get_settings
from app.db import Base, SessionLocal, engine
from app.embeddings import get_embeddings
from app.logging_setup import log_event, setup_logging
from app.models import Chunk, Document, IngestConfig
from app.rag.chunker import make_splitter
from app.rag.loaders import detect_mime, is_supported, load_text, normalize
from app.vectorstore import (
    collection_name,
    config_hash,
    delete_collection_if_exists,
    get_or_create_collection,
)

log = logging.getLogger("ingest")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")
setup_logging()

AGENTIC_SUBDIR = "Agentic"
AGENTIC_SPLITTER_NAME = "agentic"


def _sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(65536), b""):
            h.update(chunk)
    return h.hexdigest()


def _iter_files(root: Path):
    for p in sorted(root.rglob("*")):
        if not p.is_file():
            continue
        if any(part.startswith(".") for part in p.relative_to(root).parts):
            continue
        yield p


def _route_splitter(rel_path: str, default_splitter: str) -> str:
    parts = Path(rel_path).parts
    if parts and parts[0] == AGENTIC_SUBDIR:
        return AGENTIC_SPLITTER_NAME
    return default_splitter


def main() -> int:
    parser = argparse.ArgumentParser(description="RAGUSKY ingest script")
    parser.add_argument("--documents-dir", default=None)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--no-prune", action="store_true")
    parser.add_argument(
        "--rebuild",
        action="store_true",
        help="Delete the target Chroma collections AND all SQLite documents/chunks, then re-ingest everything.",
    )
    args = parser.parse_args()

    settings = get_settings()
    docs_dir = Path(args.documents_dir or settings.documents_dir).resolve()
    if not docs_dir.exists() or not docs_dir.is_dir():
        log.error("Documents directory not found: %s", docs_dir)
        return 2

    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    try:
        cfg = db.get(IngestConfig, 1)
        if cfg is None:
            db.add(
                IngestConfig(
                    id=1,
                    chunk_size=settings.default_chunk_size,
                    chunk_overlap=settings.default_chunk_overlap,
                    splitter=settings.default_splitter,
                )
            )
            db.commit()
            cfg = db.get(IngestConfig, 1)

        def _collection_for(splitter_name: str) -> str:
            return collection_name(
                settings.embedding_model, cfg.chunk_size, cfg.chunk_overlap, splitter_name
            )

        def _hash_for(splitter_name: str) -> str:
            return config_hash(
                settings.embedding_model, cfg.chunk_size, cfg.chunk_overlap, splitter_name
            )

        default_collection = _collection_for(cfg.splitter)
        agentic_collection = _collection_for(AGENTIC_SPLITTER_NAME)
        log.info(
            "Target collections: default=%s (splitter=%s, hash=%s), agentic=%s (hash=%s)",
            default_collection,
            cfg.splitter,
            _hash_for(cfg.splitter),
            agentic_collection,
            _hash_for(AGENTIC_SPLITTER_NAME),
        )
        log_event(
            "ragusky.ingest",
            "run_start",
            documents_dir=str(docs_dir),
            default_collection=default_collection,
            agentic_collection=agentic_collection,
            default_splitter=cfg.splitter,
            chunk_size=cfg.chunk_size,
            chunk_overlap=cfg.chunk_overlap,
            rebuild=args.rebuild,
            dry_run=args.dry_run,
        )

        if args.rebuild and not args.dry_run:
            log.warning(
                "--rebuild: deleting collections [%s, %s] and all SQLite chunks/documents",
                default_collection,
                agentic_collection,
            )
            delete_collection_if_exists(default_collection)
            delete_collection_if_exists(agentic_collection)
            db.query(Chunk).delete()
            db.query(Document).delete()
            db.commit()

        collections: dict[str, object] = {}

        def _get_collection(splitter_name: str):
            if splitter_name not in collections:
                collections[splitter_name] = get_or_create_collection(
                    _collection_for(splitter_name),
                    metadata={"hnsw:space": "cosine", "config_hash": _hash_for(splitter_name)},
                )
            return collections[splitter_name]

        splitters: dict[str, object] = {}

        def _get_splitter(splitter_name: str):
            if splitter_name not in splitters:
                splitters[splitter_name] = make_splitter(
                    splitter_name, cfg.chunk_size, cfg.chunk_overlap
                )
            return splitters[splitter_name]

        embeddings = get_embeddings()

        stats: Counter = Counter()
        seen_sources: set[str] = set()
        failures: list[tuple[str, str]] = []

        for path in _iter_files(docs_dir):
            rel = str(path.relative_to(docs_dir))
            if not is_supported(path):
                log.info("skip(unsupported) %s", rel)
                stats["skip_unsupported"] += 1
                continue

            try:
                sha = _sha256(path)
            except Exception as e:
                failures.append((rel, f"sha256 failed: {e}"))
                stats["failed"] += 1
                continue

            seen_sources.add(rel)

            existing = db.query(Document).filter(Document.sha256 == sha).one_or_none()
            if existing is not None:
                if existing.source != rel:
                    log.info("skip(duplicate-content) %s (same as %s)", rel, existing.source)
                else:
                    log.info("skip(unchanged) %s", rel)
                stats["skip_duplicate"] += 1
                continue

            splitter_name = _route_splitter(rel, cfg.splitter)

            if args.dry_run:
                log.info("dry-run: would add %s [splitter=%s]", rel, splitter_name)
                stats["would_add"] += 1
                continue

            try:
                raw = load_text(path)
                text = normalize(raw)
                if not text:
                    failures.append((rel, "empty after normalization"))
                    stats["failed"] += 1
                    continue

                splitter = _get_splitter(splitter_name)
                log.info("chunking %s [splitter=%s]", rel, splitter_name)
                pieces = splitter.split_text(text)
                if not pieces:
                    failures.append((rel, "no chunks produced"))
                    stats["failed"] += 1
                    continue

                doc = Document(
                    title=path.stem,
                    source=rel,
                    mime_type=detect_mime(path),
                    sha256=sha,
                    size_bytes=path.stat().st_size,
                    chunk_count=len(pieces),
                )
                db.add(doc)
                db.flush()

                chunk_rows = [
                    Chunk(doc_id=doc.doc_id, ordinal=i, text=t, token_count=len(t) // 4)
                    for i, t in enumerate(pieces)
                ]
                db.add_all(chunk_rows)
                db.flush()

                vectors = embeddings.embed_documents(pieces)
                collection = _get_collection(splitter_name)
                collection.upsert(
                    ids=[c.chunk_id for c in chunk_rows],
                    embeddings=vectors,
                    documents=pieces,
                    metadatas=[
                        {
                            "doc_id": doc.doc_id,
                            "chunk_id": c.chunk_id,
                            "ordinal": c.ordinal,
                            "source": rel,
                            "title": doc.title,
                            "mime_type": doc.mime_type,
                            "splitter": splitter_name,
                        }
                        for c in chunk_rows
                    ],
                )
                db.commit()
                log.info("added %s (%d chunks, splitter=%s)", rel, len(pieces), splitter_name)
                log_event(
                    "ragusky.ingest",
                    "added",
                    source=rel,
                    doc_id=doc.doc_id,
                    sha256=sha,
                    mime_type=doc.mime_type,
                    size_bytes=doc.size_bytes,
                    chunk_count=len(pieces),
                    splitter=splitter_name,
                )
                stats["added"] += 1
            except Exception as e:
                db.rollback()
                failures.append((rel, str(e)))
                stats["failed"] += 1
                log.exception("failed %s", rel)
                log_event(
                    "ragusky.ingest",
                    "failed",
                    source=rel,
                    error=str(e),
                    splitter=splitter_name,
                )

        # Prune orphans
        if not args.no_prune:
            orphans = db.query(Document).filter(~Document.source.in_(seen_sources)).all() if seen_sources else []
            for doc in orphans:
                if args.dry_run:
                    log.info("dry-run: would prune %s", doc.source)
                    stats["would_prune"] += 1
                    continue
                try:
                    splitter_name = _route_splitter(doc.source, cfg.splitter)
                    chunk_ids = [c.chunk_id for c in doc.chunks]
                    if chunk_ids:
                        _get_collection(splitter_name).delete(ids=chunk_ids)
                    db.delete(doc)
                    db.commit()
                    log.info("pruned %s (splitter=%s)", doc.source, splitter_name)
                    log_event(
                        "ragusky.ingest",
                        "pruned",
                        source=doc.source,
                        doc_id=doc.doc_id,
                        splitter=splitter_name,
                    )
                    stats["pruned"] += 1
                except Exception as e:
                    db.rollback()
                    failures.append((doc.source, f"prune failed: {e}"))
                    stats["failed"] += 1

        log.info("Summary: %s", dict(stats))
        log_event("ragusky.ingest", "run_end", stats=dict(stats), failures=len(failures))
        if failures:
            print("\nFailures:", file=sys.stderr)
            for src, msg in failures:
                print(f"  - {src}: {msg}", file=sys.stderr)
            return 1
        return 0
    finally:
        db.close()


if __name__ == "__main__":
    raise SystemExit(main())
