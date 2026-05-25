import json
import re

from langchain_core.messages import HumanMessage, SystemMessage
from langchain_text_splitters import MarkdownHeaderTextSplitter, RecursiveCharacterTextSplitter

from app.llm import get_chat_model


def make_splitter(splitter: str, chunk_size: int, chunk_overlap: int):
    if splitter == "agentic":
        return _AgenticSplitter()
    if splitter == "markdown_aware":
        headers = [("#", "h1"), ("##", "h2"), ("###", "h3")]
        return _MarkdownThenRecursive(headers, chunk_size, chunk_overlap)
    return RecursiveCharacterTextSplitter(
        chunk_size=chunk_size,
        chunk_overlap=chunk_overlap,
        separators=["\n\n", "\n", "。", "！", "？", ". ", "? ", "! ", " ", ""],
    )


class _MarkdownThenRecursive:
    def __init__(self, headers, chunk_size, chunk_overlap):
        self.head = MarkdownHeaderTextSplitter(headers_to_split_on=headers)
        self.tail = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size, chunk_overlap=chunk_overlap
        )

    def split_text(self, text: str) -> list[str]:
        docs = self.head.split_text(text)
        out: list[str] = []
        for d in docs:
            out.extend(self.tail.split_text(d.page_content))
        return out


class AgenticChunkingError(RuntimeError):
    pass


_AGENTIC_SYSTEM = (
    "You are a document chunker for a RAG system. "
    "Given the full text of a document, split it into semantically coherent chunks. "
    "Each chunk should cover one focused topic and read as self-contained as possible. "
    "Preserve the original wording verbatim — do NOT paraphrase, translate, summarize, or fix typos. "
    "Concatenating all chunks in order may omit minor whitespace/headings but must not invent or alter content. "
    "Return ONLY a JSON array of strings, no prose, no markdown fences. "
    "Example output: [\"chunk one text...\", \"chunk two text...\"]"
)

_AGENTIC_USER_TMPL = (
    "Document follows between <<<DOC>>> markers. Split it into chunks per the rules.\n\n"
    "<<<DOC>>>\n{text}\n<<<DOC>>>"
)


class _AgenticSplitter:
    """LLM-driven chunker. Sends the whole document to the chat model and
    expects a JSON list of strings back. No fallback — caller treats failures
    as hard errors (matches the explicit design choice for the Agentic/ path).
    """

    def split_text(self, text: str) -> list[str]:
        model = get_chat_model()
        messages = [
            SystemMessage(content=_AGENTIC_SYSTEM),
            HumanMessage(content=_AGENTIC_USER_TMPL.format(text=text)),
        ]
        resp = model.invoke(messages)
        raw = (getattr(resp, "content", "") or "").strip()
        if not raw:
            raise AgenticChunkingError("LLM returned empty content")

        parsed = _parse_json_list(raw)
        chunks = [c.strip() for c in parsed if isinstance(c, str) and c.strip()]
        if not chunks:
            raise AgenticChunkingError("LLM returned no non-empty chunks")
        return chunks


_FENCE_RE = re.compile(r"^```(?:json)?\s*|\s*```$", re.IGNORECASE)


def _parse_json_list(raw: str) -> list:
    cleaned = _FENCE_RE.sub("", raw.strip()).strip()
    try:
        data = json.loads(cleaned)
    except json.JSONDecodeError as e:
        start = cleaned.find("[")
        end = cleaned.rfind("]")
        if start == -1 or end == -1 or end <= start:
            raise AgenticChunkingError(f"LLM output is not valid JSON: {e}; head={cleaned[:200]!r}")
        try:
            data = json.loads(cleaned[start : end + 1])
        except json.JSONDecodeError as e2:
            raise AgenticChunkingError(f"LLM output is not valid JSON: {e2}; head={cleaned[:200]!r}")
    if not isinstance(data, list):
        raise AgenticChunkingError(f"LLM output is not a JSON array: type={type(data).__name__}")
    return data
