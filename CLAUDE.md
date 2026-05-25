# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Tech Stack

**Backend**
- **Language / Runtime**: Python 3.11
- **Web Framework**: FastAPI
- **LLM Orchestration**: LangChain 1.1
- **Vector Store**: Chroma
- **Relational DB**: SQLite
- **Agents**: deepagents 0.5.1 (pin exact version)

**Frontend**
- **Framework**: Vue 3 (Composition API, `<script setup>`)

## Design Tokens

- Primary palette: **blue + white**. Blue for primary actions, links, active states, and brand accents; white for surfaces and backgrounds. Keep accent colors minimal — semantic colors (success/warning/error) only where they carry meaning.
- Define color values as CSS variables in a single tokens file (e.g. `frontend/src/styles/tokens.css`) and reference them from components. Do not hardcode hex values in component styles.

## RAG Decisions

- **Embedding model**: `bge-m3` (BAAI, 1024-dim, served via Ollama). Multilingual; works well for Chinese including short single-token queries.
  - Originally chose `nomic-embed-text:latest`, but it returned a constant near-zero vector for short Chinese queries (e.g. `"奔驰"`, `"卡车"`), causing retrieval to return the same 4 chunks regardless of query content. The bug reproduced via both Ollama's `/api/embed` and `/api/embeddings` endpoints, and is a property of the model itself (English-trained, falls back to a default vector for unfamiliar short CJK tokens). Long Chinese sentences and English queries were unaffected.
  - The custom client at [backend/app/embeddings.py](backend/app/embeddings.py) uses Ollama's stable `/api/embeddings` endpoint directly (not `langchain-ollama`'s `/api/embed`) — keeps query and document vectors on the same code path.
- Treat the embedding model as load-bearing — changing it requires rebuilding the entire vector store. The Chroma collection name auto-versions via `config_hash` of `(model | chunk_size | chunk_overlap | splitter)`, so any change produces a new collection; run `uv run python -m scripts.ingest --rebuild` to populate it. Never mix vectors from different models in one collection.

## Project Structure

- `backend/` — FastAPI service, LangChain pipelines, Chroma + SQLite access. All server-side code lives here.
- `frontend/` — all UI / client pages.
- `docs/features/` — one markdown file per feature describing requirements, flow, API, data model, and edge cases. **Read the relevant file before implementing or modifying a feature.** Use `docs/features/TEMPLATE.md` as the starting point for new features.
- `Documents/` — knowledge-base source of truth. Drop `.pdf` / `.md` / `.txt` / `.html` files here (subdirectories allowed, scanned recursively). After any change, run `cd backend && uv run python -m scripts.ingest` to sync the vector store. The system has NO online upload UI.
- `LOG/` — structured JSON-lines business logs, one file per domain: `ingest.log` (what was chunked), `retrieval.log` (admin retrieval-test queries & results), `chat.log` (end-user queries & answers & citations). Rotating (10 MB × 10 backups).

Keep the boundary strict: backend code must not import from `frontend/` and vice versa. Shared contracts (e.g. API schemas) belong in `backend/` and are consumed by the frontend over HTTP.

## Conventions

- Pin to the versions above; do not silently upgrade LangChain across minor versions (1.1 → 1.2) — the API surface changes.
- Use the `langchain` 1.x package layout (`langchain_core`, `langchain_community`, provider-specific `langchain_*` packages). Avoid deprecated top-level imports.
- Async-first: prefer FastAPI `async def` endpoints and LangChain async APIs (`ainvoke`, `astream`) so the event loop isn't blocked by LLM/vector calls.
- Chroma: use a persistent client with an explicit `persist_directory`; do not rely on in-memory mode outside tests.
- SQLite: enable WAL mode and `foreign_keys=ON` on connection; treat it as single-writer.
