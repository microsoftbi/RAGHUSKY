from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8", extra="ignore")

    database_url: str = "sqlite:///./ragusky.db"
    chroma_path: str = "./chroma_data"

    ollama_base_url: str = "http://localhost:11434"
    embedding_model: str = "nomic-embed-text:latest"

    openai_api_key: str = ""
    openai_base_url: str = "https://api.openai.com/v1"
    llm_model: str = "gpt-4o-mini"
    llm_temperature: float = 0.2

    jwt_secret: str = "change-me"
    jwt_ttl_min: int = 720
    initial_admin_password: str = "changeme"

    cors_origins: str = "http://localhost:5173"

    default_chunk_size: int = 800
    default_chunk_overlap: int = 120
    default_splitter: str = "recursive"

    documents_dir: str = "../Documents"

    @property
    def documents_path(self) -> Path:
        return Path(self.documents_dir).resolve()

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
