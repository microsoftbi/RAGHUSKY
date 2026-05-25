# Chunk Test

> Status: shipped
> Owner: admin tooling
> Last updated: 2026-05-26

## Goal

Give admins a quick way to paste arbitrary text, pick a splitter (recursive or
agentic), and see exactly how it gets chunked — without ingesting a file. Useful
for tuning `chunk_size` / `chunk_overlap` and for evaluating whether the
agentic LLM splitter is worth its latency on a given corpus.

## Non-Goals

- Does not write to the vector store or the SQLite `documents` table.
- Does not persist test inputs or results.
- Does not expose the `markdown_aware` splitter — that's an ingest-only option
  that depends on real markdown headers; admins who want to validate it should
  use the召回测试 page after a rebuild.

## User Flow

1. Admin opens **Chunking 测试** in the top nav (admin-only).
2. Left pane: a large textarea for the input.
3. Top toolbar: pick `Recursive` or `Agentic`. For recursive, edit
   `chunk_size` and `chunk_overlap` inline. For agentic, those fields are
   hidden (the LLM decides boundaries).
4. Click **切分**. Right pane fills with one card per chunk, each labelled with
   its 1-based index and character count.
5. **清空** wipes both panes.

## API

### `POST /api/v1/admin/chunk-test`

Admin-only. Reuses `app.rag.chunker.make_splitter`.

Request:

```json
{
  "text": "string (1 .. 200_000 chars)",
  "splitter": "recursive | agentic",
  "chunk_size": 800,        // recursive only; ignored by agentic
  "chunk_overlap": 120      // recursive only; ignored by agentic
}
```

Response:

```json
{
  "splitter": "recursive",
  "chunk_count": 12,
  "chunks": [
    { "ordinal": 0, "text": "...", "char_count": 742 }
  ]
}
```

Errors:

- `400` — `chunk_overlap >= chunk_size`.
- `401 / 403` — not authenticated / not admin.
- `502` — agentic splitter raised `AgenticChunkingError` (empty LLM output,
  non-JSON, etc.). No fallback by design.

## Data Model

None. The endpoint is pure: no DB writes, no Chroma writes, no business log
entry (it's an interactive dev tool, not part of the ingest audit trail).

## RAG Pipeline (if applicable)

Not part of retrieval/generation. Only touches the chunker. The agentic path
calls `get_chat_model()` exactly like the ingest pipeline does, so latency and
JSON-shape failures look identical to a real ingest run.

## Dependencies

- `app.rag.chunker.make_splitter` — single source of truth for splitter
  construction; this feature must not duplicate splitter logic.
- `require_admin` dependency.

## Edge Cases & Failure Modes

- Empty / whitespace-only input → frontend blocks with a warning before sending.
- `chunk_overlap >= chunk_size` → server returns 400; frontend also pre-checks.
- Agentic LLM is slow → request can take tens of seconds; the button shows a
  loading state and the right pane shows the el-loading mask. No client-side
  timeout is enforced; users can navigate away to cancel.
- Agentic LLM returns malformed JSON → 502 with the parser's error message.
- Very large input (close to the 200k char cap) → recursive is fine; agentic
  will likely exceed the model's context — that's expected and surfaces as a
  502 from the LLM call.

## Open Questions

- Should we add `markdown_aware` once admins ask for it? Currently omitted to
  keep the UI focused on the two splitters that differ most visibly.
