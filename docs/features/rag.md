# 通用 RAG 系统

> 状态:草稿
> 负责人:待定
> 最后更新:2026-05-25

## 目标

提供一个通用的检索增强生成(RAG)系统:运维人员把文档放入 `Documents/` 文件夹,运行一个离线脚本将其全部加载进向量知识库;**普通用户**通过聊天界面用自然语言提问,系统返回基于已导入内容的回答,并附带来源引用;**管理员用户**额外可以管理账户、查看知识库内文档信息、以及执行召回测试。

## 角色与权限

- **普通用户(user)**:对知识库执行检索/问答(`POST /chat`),查看自己的会话历史。
- **管理员(admin)**:在普通用户全部权限之上,可以:
  - 管理普通用户账户(增 / 改 / 禁用 / 删 / 重置密码)。
  - 查看知识库内文档清单及统计信息(文件名、切片数、入库时间、`sha256` 等)。
  - 执行**召回测试**(输入 query → 查看检索到的 top-k 切片、分数与来源,用于评估检索质量,不调用生成 LLM)。

管理员账户的具体设计、API 与界面在 [docs/features/admin.md](admin.md) 中描述。

## 非目标

- 在线上传文档(改为离线脚本批量摄入,见下文)。
- 多租户隔离(v1 仅支持单工作区,角色仅区分 user / admin)。
- 知识库的实时协同编辑。
- LLM 微调;只做检索 + 提示。
- 音视频处理 —— v1 只支持文本及可提取文本的文档(PDF、Markdown、纯文本、HTML)。

## 用户流程

**离线运维流程**
1. 运维把待入库的文档放入仓库根目录的 `Documents/` 文件夹(支持子目录,递归扫描)。
2. 运行 `python backend/scripts/ingest.py`,脚本扫描整个文件夹,对每个文件解析 → 切分 → 向量化 → 写入 Chroma,并把元数据写入 SQLite。
3. 控制台打印进度与每个文件的状态(新增 / 跳过 / 失败)。

**终端用户流程**
1. **提问**:用户在聊天界面输入问题。后端检索 top-k 相关切片,构造提示词,调用 LLM,以流式方式返回带行内引用的答案。
2. **查看**:用户可点击引用,查看对应原文切片及所属文档。
3. **浏览**:用户可在前端列出当前知识库中已收录的文档(只读)。

## API

所有端点统一前缀 `/api/v1`,除特别说明外均为 JSON。后端**不提供**文档上传或删除接口,知识库的变更只能通过离线脚本完成。

### `GET /documents`
列出当前知识库中已收录的文档(只读)。
- 响应:`[{ "doc_id", "title", "source", "chunk_count", "created_at" }]`

### `POST /chat` (SSE 流式)
提问。
- 请求:`{ "session_id": "uuid?", "query": "string", "top_k": 4, "filters": { ... } }`
- 响应(SSE 事件):
  - `retrieved`:`{ "chunks": [{ "chunk_id", "doc_id", "score", "snippet" }] }`
  - `token`:`{ "delta": "..." }`
  - `done`:`{ "answer": "...", "citations": [chunk_id, ...], "session_id" }`
- 错误:400 空问题;429 限流;500 LLM 调用失败。

### `GET /sessions/{session_id}`
获取某个会话的历史消息。

## 离线摄入脚本

路径:`backend/scripts/ingest.py`

行为:
- 扫描仓库根目录的 `Documents/`(递归,跟随子目录)。
- 跳过隐藏文件、临时文件,以及不支持的格式(只处理 `.pdf` / `.md` / `.txt` / `.html`)。
- 对每个文件计算 `sha256`:若 `documents` 表中已存在相同哈希,跳过并打印 `skip`;否则执行完整的解析 → 切分 → 向量化 → 写入流程,打印 `added`。
- 文件被删除或重命名时,通过对比"`Documents/` 实际文件列表"与 `documents` 表中的 `source` 字段,清理库内孤立的文档与对应 Chroma 向量(默认开启;可通过 `--no-prune` 关闭)。
- 入参:`--documents-dir`(默认 `./Documents`)、`--collection`(默认 `kb_nomic_v1`)、`--dry-run`、`--no-prune`。
- 退出码:0 全部成功;非 0 表示存在失败文件,具体清单打印到 stderr。

可以反复运行,具有幂等性。

## 数据模型

### SQLite

- `documents(doc_id PK, title, source, mime_type, sha256, chunk_count, created_at, updated_at)` —— `source` 存相对 `Documents/` 的相对路径,用作"文件 ↔ 库内记录"的唯一匹配键。
- `chunks(chunk_id PK, doc_id FK, ordinal, text, token_count, created_at)` —— 原文本一并保存,便于渲染引用时无需回查 Chroma。
- `sessions(session_id PK, created_at)`
- `messages(message_id PK, session_id FK, role, content, citations_json, created_at)`

启用 WAL 模式与 `foreign_keys=ON`。

### Chroma

- Collection 命名:`kb_nomic_v1`(格式 `kb_<embedding-model>_v<schema-version>`)。embedding 模型、切分策略或元数据 schema 一旦变动,必须升版本号。
- 向量来源:`nomic-embed-text:latest`。
- 切片元数据:`doc_id`、`chunk_id`、`ordinal`、`source`、`title`、`mime_type`、`created_at`,用于过滤与引用回链。

## RAG 流水线

### 摄入(由离线脚本调用)
1. 按 mime 类型解析(PDF → `pypdf` / `unstructured`;HTML → `readability` + `bs4`;Markdown/纯文本 → 原样)。
2. 规范化空白、剔除页眉页脚等样板内容。
3. 切分:递归字符切分器,**默认 `chunk_size=800`、`chunk_overlap=120`**(token 用字符数/4 近似);管理员可在后台修改这两个值(见 [admin.md](admin.md))。改后需重跑摄入脚本(`--rebuild`)并触发 Chroma collection 升版。
4. 通过 Ollama 调用 `nomic-embed-text:latest` 生成向量。
5. 写入 Chroma;同步写入 `chunks` 表;更新 `documents.chunk_count`。

### 检索(由后端调用)
- Collection:`kb_nomic_v1`。
- top-k:默认 **4**,可按请求覆盖。
- 可选元数据过滤(例如按 `doc_id` 限定单个文档)。
- 重排:v1 不引入;若精度不达标再评估。

### 生成
- 提示词模板位于 `backend/prompts/rag_answer.md`,包含:系统指令、检索到的切片(带 `[chunk_id]` 标记)、用户问题。要求模型在回答中以 chunk_id 形式标注引用。
- 模型:待定(在本地 Ollama 模型与托管 API 之间根据质量/延迟权衡)。
- 流式输出:启用(SSE)。从模型输出中解析引用,在最终 `done` 事件中返回。

## 目录约定

- `Documents/` —— 仓库根目录下的知识库源文件夹。所有要进入知识库的文件都放这里(可建子目录,脚本递归扫描)。该文件夹中的文件即"知识库的真实来源(source of truth)"。
- `backend/scripts/ingest.py` —— 摄入脚本入口。
- `backend/prompts/` —— 提示词模板集中存放。

## 依赖

- 本地或可访问的 Ollama,提供 `nomic-embed-text:latest` 与生成模型。
- LangChain 1.1 系列包:`langchain_core`、`langchain_community`、`langchain_chroma`、`langchain_ollama`。
- deepagents 0.5.1(仅在需要为 RAG 叠加工具调用 / Agent 能力时引入)。
- FastAPI + `sse-starlette`,用于流式响应。

## 边界与失败场景

- **检索为空**(无切片超过相关性阈值):回答"知识库中没有相关信息",禁止编造。
- **`Documents/` 文件夹缺失或为空**:脚本明确报错并以非 0 退出,不静默成功。
- **重复文件**(`sha256` 相同,无论文件名或路径是否相同):只入库一次,其余路径打印 `skip(duplicate)`。
- **不支持的格式**:跳过并打印 `skip(unsupported)`,不计入失败。
- **解析失败的单个文件**:记录错误后继续处理其余文件,脚本最终以非 0 退出并汇总失败清单。
- **向量服务不可用**:脚本快速失败并退出,禁止向 Chroma 半写入。
- **生成流中断**:已生成的部分需持久化到会话历史,该消息标记为 `partial`。
- **孤立数据清理**:`Documents/` 中已删除的文件,其在 SQLite 与 Chroma 中的对应记录需在下次运行脚本时一并清理(`--no-prune` 可关闭)。

## 待解决问题

- 生成模型选哪一款?(本地 Ollama vs 托管 API)
- 是否在 day 1 就引入重排器(如 bge-reranker),还是先观测再决定?
- 鉴权:v1 是否需要?要的话用简单 API key 即可?
- 摄入脚本是否需要并行处理(多进程/多线程)以加速大批量文档的向量化?
- 评估:在调参(chunk size、top-k)之前,先在 `backend/eval/` 准备小规模黄金 Q/A 集。
