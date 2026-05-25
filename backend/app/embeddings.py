from functools import lru_cache

import httpx

from app.config import get_settings


class OllamaLegacyEmbeddings:
    """Minimal client for Ollama's stable /api/embeddings endpoint.

    We deliberately avoid the newer /api/embed batch endpoint because some
    Ollama builds return a constant near-zero vector for short CJK inputs there,
    which silently breaks retrieval. /api/embeddings is single-input and slower
    but consistent across the inputs we throw at it.
    """

    def __init__(self, model: str, base_url: str, timeout: float = 60.0):
        self.model = model
        self.base_url = base_url.rstrip("/")
        self._client = httpx.Client(timeout=timeout)

    def _embed_one(self, text: str) -> list[float]:
        resp = self._client.post(
            f"{self.base_url}/api/embeddings",
            json={"model": self.model, "prompt": text},
        )
        resp.raise_for_status()
        data = resp.json()
        vec = data.get("embedding")
        if not isinstance(vec, list) or not vec:
            raise RuntimeError(f"Ollama returned no embedding for input: {text[:40]!r}")
        return vec

    def embed_query(self, text: str) -> list[float]:
        return self._embed_one(text)

    def embed_documents(self, texts: list[str]) -> list[list[float]]:
        return [self._embed_one(t) for t in texts]


@lru_cache(maxsize=1)
def get_embeddings() -> OllamaLegacyEmbeddings:
    settings = get_settings()
    return OllamaLegacyEmbeddings(
        model=settings.embedding_model,
        base_url=settings.ollama_base_url,
    )
