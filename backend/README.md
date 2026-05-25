# RAGUSKY Backend

FastAPI + LangChain 1.1 + Chroma + SQLite。设计见 [../docs/features/rag.md](../docs/features/rag.md) 与 [../docs/features/admin.md](../docs/features/admin.md)。

## 启动

```bash
cp .env.example .env       # 修改 OPENAI_API_KEY、JWT_SECRET、INITIAL_ADMIN_PASSWORD
uv sync
uv run uvicorn app.main:app --reload --port 8000
```

首次启动会:
- 建表 + 启用 SQLite WAL / 外键
- 若 `users` 表为空,创建初始 admin(用户名 `admin`,密码 = `INITIAL_ADMIN_PASSWORD`)
- 若 `ingest_config` 表为空,写入默认 `chunk_size=800, chunk_overlap=120, splitter=recursive`

## 摄入文档

把 `.pdf` / `.md` / `.txt` / `.html` 放到仓库根目录的 `../Documents/`(可子目录),然后:

```bash
uv run python -m scripts.ingest               # 增量
uv run python -m scripts.ingest --dry-run     # 只看会做什么
uv run python -m scripts.ingest --rebuild     # 切分参数改了之后用
uv run python -m scripts.ingest --no-prune    # 不清理 Documents/ 已删除文件对应的记录
```

## 依赖

- Ollama:本地拉 `nomic-embed-text:latest`(`ollama pull nomic-embed-text`)。
- OpenAI 兼容的 LLM API key(DeepSeek / 通义 / Moonshot / OpenAI 任一)。
