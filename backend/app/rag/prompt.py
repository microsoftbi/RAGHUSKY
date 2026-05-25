from pathlib import Path

from app.rag.retriever import RetrievedItem

_PROMPT_PATH = Path(__file__).resolve().parent.parent / "prompts" / "rag_answer.md"


def load_template() -> str:
    return _PROMPT_PATH.read_text(encoding="utf-8")


def render(query: str, chunks: list[RetrievedItem]) -> tuple[str, str]:
    template = load_template()
    if "{{context}}" not in template or "{{question}}" not in template:
        raise RuntimeError("rag_answer.md must contain {{context}} and {{question}} placeholders")

    if chunks:
        ctx_blocks = [
            f"[{c.chunk_id}] (source: {c.source})\n{c.text}".strip() for c in chunks
        ]
        context = "\n\n---\n\n".join(ctx_blocks)
    else:
        context = "(no relevant context retrieved)"

    filled = template.replace("{{context}}", context).replace("{{question}}", query)
    parts = filled.split("---USER---", 1)
    if len(parts) == 2:
        return parts[0].strip(), parts[1].strip()
    return filled.strip(), query
