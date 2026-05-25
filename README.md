# RAGUSKY

一个面向中文文档的轻量级 RAG(Retrieval-Augmented Generation)系统:把 `Documents/` 目录下的资料一键入库,然后通过聊天界面提问、得到带引用的流式回答。

后端 FastAPI + LangChain + Chroma + SQLite,前端 Vue 3 + Element Plus。

---

## 核心特性

- **离线摄入,在线问答**:文档以"放进 `Documents/` 文件夹 → 跑一次 `ingest` 脚本"的方式管理,**没有在线上传 UI**,运行时只做检索与生成。
- **多 splitter 路由**:`Documents/Normal/` 走字符切分(默认 `recursive`,可调),`Documents/Agentic/` 走 LLM 语义切分;两类切片**分别落到独立的 Chroma collection**,检索时再合并 top-k,互不污染。
- **流式问答 + 内联引用**:答案以 SSE 流式返回,LLM 在文本内用 `[chunk_id]` 标注来源,前端把它渲染为可点击的引用 chip,点开看原文片段,再点"打开原文"看完整文件。
- **JWT 鉴权 + 角色**:所有问答与管理 API 必须登录;`admin` 角色额外拥有用户管理、文档详情、召回测试、切分参数四个后台页面。
- **可观测**:所有摄入 / 检索 / 问答事件以 JSON Lines 形式写入 `LOG/`(`ingest.log` / `retrieval.log` / `chat.log`),便于追溯。
- **集合自动版本化**:`(embedding_model, chunk_size, chunk_overlap, splitter)` 任一变化都会产生新 collection(命名为 `kb_<model>_v<hash>`),老向量自动作废,避免不同切分参数的向量混在一起。

---

## 技术栈

| 层 | 技术 | 版本 |
|---|---|---|
| Python | CPython | 3.11 |
| Web 框架 | FastAPI | 0.116 |
| LLM 编排 | LangChain | 1.1 |
| 向量库 | Chroma(持久化模式) | — |
| 关系库 | SQLite(WAL 模式) | — |
| Embedding 模型 | **bge-m3**(BAAI,1024-dim,经 Ollama 部署) | — |
| 主 LLM | 任意 OpenAI 兼容接口(DeepSeek / Qwen / Moonshot / OpenAI / …) | — |
| 前端框架 | Vue 3 + `<script setup>` + TypeScript | — |
| UI 组件 | Element Plus | — |
| 构建 / 依赖 | Vite + pnpm(前端);uv(后端) | — |

> **为什么是 bge-m3 而不是 nomic-embed-text?** 原选型用 nomic,对短中文 query(`"奔驰"`、`"卡车"` 等)会返回常量近零向量,导致检索结果跟 query 完全无关。bge-m3 是多语言模型,这个问题不复现。详见 [CLAUDE.md](CLAUDE.md) 的 *RAG Decisions* 一节。

---

## 项目结构

```
RAGUSKY/
├── backend/                # FastAPI 服务、LangChain pipeline、Chroma + SQLite 访问
│   ├── app/
│   │   ├── main.py         # FastAPI 装配 + 启动时 bootstrap(创建 admin、默认 ingest_config)
│   │   ├── config.py       # pydantic-settings 读 .env
│   │   ├── embeddings.py   # 自定义 Ollama 客户端,固定走 /api/embeddings
│   │   ├── llm.py          # OpenAI 兼容 chat 模型(支持流式)
│   │   ├── vectorstore.py  # Chroma 客户端 + collection 命名 / 版本 hash
│   │   ├── rag/
│   │   │   ├── chunker.py  # recursive / markdown_aware / agentic 三种 splitter
│   │   │   ├── loaders.py  # 按 mime 分发解析(pdf / md / txt / html / docx)
│   │   │   ├── retriever.py# 同时查 default + agentic 两个 collection 并合并
│   │   │   └── prompt.py   # 渲染 RAG 提示词,把 chunk 拼成上下文块
│   │   ├── prompts/rag_answer.md  # 系统提示 + 引用规则模板
│   │   └── routers/        # auth / chat / sessions / documents + admin/{users,documents,retrieval_test,ingest_config}
│   └── scripts/ingest.py   # 离线摄入脚本,支持 --rebuild / --dry-run / --no-prune
├── frontend/               # Vue 3 + Element Plus
│   └── src/views/          # LoginView / ChatView / DocumentsView + admin/*
├── Documents/              # 知识库源(运维维护)
│   ├── Normal/             # 字符切分入库
│   └── Agentic/            # LLM 切分入库
├── LOG/                    # 业务日志(ingest.log / retrieval.log / chat.log),10MB × 10 滚动
├── docs/features/          # 每个功能一份 markdown,描述需求 / 流程 / API / 边界条件
├── chroma_data/            # Chroma 持久化目录(自动生成)
├── ragusky.db              # SQLite 文件(自动生成)
├── start.sh / stop.sh      # 一键启停后端 + 前端
├── CLAUDE.md               # 给 Claude Code 的项目约定(技术栈、设计 token、RAG 决策)
├── USERGUIDE.md            # 终端用户手册(中文)
└── OPERATION.md            # 运维 / 部署手册(中文)
```

---

## 快速开始

### 1. 前置条件

- macOS / Linux,Python 3.11,Node 20+
- [uv](https://github.com/astral-sh/uv)、[pnpm](https://pnpm.io/)、[Ollama](https://ollama.com/)
- 已拉取 bge-m3:`ollama pull bge-m3`
- 一个 OpenAI 兼容的 LLM API Key(DeepSeek / Qwen / Moonshot / OpenAI 任选)

### 2. 配置 .env

```bash
cp backend/.env.example backend/.env   # 如果有 example;否则参考下方写一个
```

最小 `.env` 示例:

```env
DATABASE_URL=sqlite:///./ragusky.db
CHROMA_PATH=./chroma_data

OLLAMA_BASE_URL=http://localhost:11434
EMBEDDING_MODEL=bge-m3

OPENAI_API_KEY=<your-key>
OPENAI_BASE_URL=https://api.deepseek.com   # 或你选用的提供商
LLM_MODEL=deepseek-chat
LLM_TEMPERATURE=0.2

JWT_SECRET=please-change-me
INITIAL_ADMIN_PASSWORD=admin

CORS_ORIGINS=http://localhost:5173
DOCUMENTS_DIR=../Documents
```

### 3. 装依赖

```bash
cd backend && uv sync
cd ../frontend && pnpm install
```

### 4. 放文档 → 入库

把要查的 `.md` / `.docx` / `.pdf` / `.txt` / `.html` 放到 `Documents/Normal/`(走字符切分),或 `Documents/Agentic/`(走 LLM 切分),然后:

```bash
cd backend && uv run python -m scripts.ingest
```

常用选项:

| 选项 | 说明 |
|---|---|
| `--dry-run` | 只扫描不写入,看会做什么 |
| `--rebuild` | 删空 SQLite 的 documents/chunks 表 + 删整个 Chroma collection,从头入库 |
| `--no-prune` | 不删除"`Documents/` 已不存在但库里还有"的记录 |

### 5. 启动服务

```bash
cd .. && bash start.sh
```

- 后端: <http://localhost:8000>
- 前端: <http://localhost:5173>
- 默认账号: `admin` / `<INITIAL_ADMIN_PASSWORD>`

停止:

```bash
bash stop.sh
```

---

## 两种切分模式

| 模式 | 触发条件 | 实现 | 适合什么文档 |
|---|---|---|---|
| **Normal**(字符切分) | 文件位于 `Documents/Normal/` 或非 `Agentic/` 子目录 | LangChain `RecursiveCharacterTextSplitter`,按 `chunk_size`/`chunk_overlap` 配置切 | 结构清晰、文字密度均匀的文档(手册、规章、技术博客) |
| **Agentic**(LLM 切分) | 文件位于 `Documents/Agentic/` | 把整篇文档交给 LLM,要求返回 JSON 数组(每个元素是一个语义完整的 chunk),**原文逐字保留** | 章节信息密集、单段主题集中的文档(公司 / 产品介绍、人物档案) |

两套切片落到独立的 Chroma collection(`kb_bge-m3_v<hash_recursive>` vs `kb_bge-m3_v<hash_agentic>`),检索时各取 top-k 再按 score 合并去重,最终仍只返回全局 top-k 给 LLM。

> 任何一份 Agentic 文档若 LLM 返回非法 JSON 或空数组,摄入会**直接报错并把该文件计入失败**(不自动降级),需要在 `LOG/ingest.log` 里看具体原因后再处理。

---

## 默认端口与账号

| 项 | 值 |
|---|---|
| 后端 API | `http://localhost:8000`,业务前缀 `/api/v1`,健康检查 `/healthz` |
| 前端 | `http://localhost:5173` |
| 默认管理员 | `admin` / 由 `.env` 中 `INITIAL_ADMIN_PASSWORD` 指定 |
| JWT 有效期 | 720 分钟(12 小时),通过 `JWT_TTL_MIN` 配置 |

---

## 主要页面

| 页面 | 路径 | 谁能访问 | 用途 |
|---|---|---|---|
| 登录 | `/login` | 所有人 | 拿 JWT |
| 问答 | `/` | 普通 + admin | 提问 → 流式回答 + 引用 chip + 打开原文 |
| 知识库文档 | `/documents` | 普通 + admin | 列出全部入库文档,按 Normal / Agentic / 其它分 tab,可查看每篇文档的切片 |
| 后台 - 用户 | `/admin/users` | admin | 用户 CRUD |
| 后台 - 文档详情 | `/admin/documents` | admin | 同上但有更多 admin 字段 |
| 后台 - 召回测试 | `/admin/retrieval` | admin | 只跑检索不调 LLM,验证切分 / 检索质量 |
| 后台 - 切分参数 | `/admin/ingest-config` | admin | 改 `chunk_size` / `chunk_overlap` / `splitter`,改后提示需要 `--rebuild` |

---

## 文档

- [CLAUDE.md](CLAUDE.md) — 给 Claude Code 看的项目约定(技术栈、设计 token、RAG 决策、约定)
- [USERGUIDE.md](USERGUIDE.md) — 终端用户使用手册
- [OPERATION.md](OPERATION.md) — 运维 / 部署手册(环境、启停、入库、排查)
- [docs/features/](docs/features/) — 每个功能一份 markdown,描述需求 / 流程 / API / 边界

---

## 已知限制 / 不在本阶段做的事

- 没有 reranker、没有混合检索、没有查询改写 —— 想做的话见 `CLAUDE.md` 后续规划
- 没有多轮对话记忆 —— 每一轮都是独立的 retrieve + generate,session 只用于持久化
- 没有评估集 / 自动化 RAG 指标
- 没有登录失败锁定 / 操作审计日志
- 没有 Docker / docker-compose —— 本地直接 `uvicorn` + `pnpm dev`
- `python-docx` 解析 docx 时会丢失图片、页眉页脚、文本框、批注 等内容
- 扫描版 PDF 暂不做 OCR
