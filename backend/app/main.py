import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.db import Base, SessionLocal, engine
from app.logging_setup import setup_logging
from app.models import IngestConfig, User
from app.routers import auth, chat, documents, sessions
from app.routers.admin import chunk_test as admin_chunk_test
from app.routers.admin import documents as admin_documents
from app.routers.admin import ingest_config as admin_ingest_config
from app.routers.admin import retrieval_test as admin_retrieval_test
from app.routers.admin import users as admin_users
from app.security import hash_password

log = logging.getLogger("ragusky")
logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s %(message)s")


def _bootstrap() -> None:
    settings = get_settings()
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()
    try:
        if db.query(User).count() == 0:
            admin = User(
                username="admin",
                password_hash=hash_password(settings.initial_admin_password),
                role="admin",
                is_active=True,
            )
            db.add(admin)
            log.info("Bootstrapped initial admin (username=admin)")
        if db.get(IngestConfig, 1) is None:
            db.add(
                IngestConfig(
                    id=1,
                    chunk_size=settings.default_chunk_size,
                    chunk_overlap=settings.default_chunk_overlap,
                    splitter=settings.default_splitter,
                )
            )
            log.info(
                "Bootstrapped default ingest_config (chunk_size=%d, chunk_overlap=%d, splitter=%s)",
                settings.default_chunk_size,
                settings.default_chunk_overlap,
                settings.default_splitter,
            )
        db.commit()
    finally:
        db.close()


@asynccontextmanager
async def lifespan(_: FastAPI):
    setup_logging()
    _bootstrap()
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="RAGUSKY API", version="0.1.0", lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    api_prefix = "/api/v1"
    app.include_router(auth.router, prefix=api_prefix)
    app.include_router(chat.router, prefix=api_prefix)
    app.include_router(sessions.router, prefix=api_prefix)
    app.include_router(documents.router, prefix=api_prefix)
    app.include_router(admin_users.router, prefix=api_prefix)
    app.include_router(admin_documents.router, prefix=api_prefix)
    app.include_router(admin_retrieval_test.router, prefix=api_prefix)
    app.include_router(admin_ingest_config.router, prefix=api_prefix)
    app.include_router(admin_chunk_test.router, prefix=api_prefix)

    @app.get("/healthz")
    def healthz() -> dict:
        return {"status": "ok"}

    return app


app = create_app()
