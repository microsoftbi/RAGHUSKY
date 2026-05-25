# RAGUSKY 操作手册

适用版本:0.1.x(脚手架版本)
更新日期:2026-05-25

本文档面向部署/运维人员,覆盖三件事:
1. 启动服务
2. 终止服务
3. 把文档加载到向量库

终端使用者(普通用户 / 管理员)的功能说明见 [USERGUIDE.md](USERGUIDE.md)。

---

## 0. 前置条件(只做一次)

### 0.1 系统依赖

| 组件 | 用途 | 安装方式 |
| --- | --- | --- |
| Python 3.11 | 后端运行时 | `brew install python@3.11` |
| uv | Python 包管理与虚拟环境 | `brew install uv` 或 `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| Node.js ≥ 18 | 前端构建 | `brew install node` 或 nvm |
| pnpm | 前端包管理 | `npm i -g pnpm` |
| Ollama | 本地 embedding 模型服务 | https://ollama.com/download |

### 0.2 拉取 embedding 模型

embedding 模型固定为 `nomic-embed-text:latest`,**改模型等价于换知识库**,需重建 collection。

```bash
ollama serve &                       # 后台启动 Ollama(已在跑就跳过)
ollama pull nomic-embed-text:latest
```

验证:`curl http://localhost:11434/api/tags` 能看到 `nomic-embed-text` 即可。

### 0.3 配置 .env

```bash
cd backend
cp .env.example .env
```

打开 `backend/.env` 至少填好以下三项(其他默认即可):

| 变量 | 示例 | 说明 |
| --- | --- | --- |
| `OPENAI_API_KEY` | `sk-xxxx` | 生成模型 API key。火山引擎 Ark 也兼容,用对应 key。 |
| `OPENAI_BASE_URL` | `https://ark.cn-beijing.volces.com/api/v3` | OpenAI 兼容接口地址。 |
| `LLM_MODEL` | `deepseek-v3-...` | 模型 ID。 |
| `JWT_SECRET` | 32+ 字符随机串 | JWT 签名密钥,**生产环境必须改**。 |
| `INITIAL_ADMIN_PASSWORD` | 强密码 | 首次启动时创建 `admin` 用的密码。 |

生成强随机串可用:`python -c "import secrets; print(secrets.token_urlsafe(48))"`。

### 0.4 装依赖

```bash
# 后端:解析 pyproject.toml,创建 .venv,装包
cd backend && uv sync

# 前端:解析 package.json,创建 node_modules
cd ../frontend && pnpm install
```

`uv sync` 第一次会下载几百 MB(LangChain / Chroma / 模型客户端),后续增量更新很快。

---

## 1. 启动服务

### 1.1 一键启动(推荐)

在仓库根目录:

```bash
./start.sh
```

行为:
- 后端 → `uv run uvicorn app.main:app --host 0.0.0.0 --port 8000`,PID 写入 `.run/backend.pid`,日志 `.run/backend.log`。
- 前端 → `pnpm dev --host --port 5173`,PID 写入 `.run/frontend.pid`,日志 `.run/frontend.log`。
- 两个进程都以 `nohup` 后台运行,关闭终端不会停。

环境变量可覆盖端口:

```bash
BACKEND_PORT=8080 FRONTEND_PORT=3000 ./start.sh
```

### 1.2 验证启动成功

```bash
# 后端健康检查,期望 {"status":"ok"}
curl http://localhost:8000/healthz

# 前端,期望返回一段 HTML(里面有 <div id="app">)
curl -I http://localhost:5173
```

浏览器打开 `http://localhost:5173`,看到登录页 = OK。用 `admin` + `INITIAL_ADMIN_PASSWORD` 里的密码登录验证完整链路。

### 1.3 看实时日志

```bash
tail -f .run/backend.log .run/frontend.log
```

首次启动后端日志里应该看到:

```
Bootstrapped initial admin (username=admin)
Bootstrapped default ingest_config (chunk_size=800, chunk_overlap=120, splitter=recursive)
Application startup complete.
Uvicorn running on http://0.0.0.0:8000
```

第二次起就只剩最后两行——`admin` 和默认 `ingest_config` 都已存在。

### 1.4 手动启动(调试用)

如果想看后端实时栈/前端实时编译输出,可以两个终端窗口分别跑:

```bash
# Terminal 1
cd backend && uv run uvicorn app.main:app --reload --port 8000

# Terminal 2
cd frontend && pnpm dev
```

`--reload` 会在 Python 文件变化时自动重启,适合开发期;**生产环境不要加 `--reload`**。

---

## 2. 终止服务

### 2.1 一键终止

```bash
./stop.sh
```

行为:
- 读 `.run/backend.pid` 和 `.run/frontend.pid`。
- 优先 `kill -- -PID`(杀整个进程组,带走 pnpm 拉起的子进程 vite),失败回退 `kill PID`。
- 删 pid 文件。

输出示例:

```
[stop] frontend pid 10410
[stop] backend pid 10408
```

### 2.2 确认进程已退出

```bash
lsof -i :8000   # 应该没有输出
lsof -i :5173   # 应该没有输出
```

或者直接看名字:

```bash
ps -ef | grep -E "uvicorn|vite|pnpm" | grep -v grep
```

### 2.3 端口被占 / pid 文件丢失

如果 `stop.sh` 报 `no pid file`,但端口仍被占用,手动杀:

```bash
lsof -ti :8000 | xargs kill   # 后端
lsof -ti :5173 | xargs kill   # 前端
```

仍然杀不掉就 `kill -9`,最后清理 `.run/`:

```bash
rm -f .run/*.pid
```

---

## 3. 把文档加载到向量库

### 3.1 总体流程

```
Documents/ 放/改/删文件
        ↓
cd backend && uv run python -m scripts.ingest
        ↓
sha256 去重 → 解析 → 规范化 → 切分 → embed → 写 Chroma + SQLite
        ↓
LOG/ingest.log 记录每一步
```

知识库的**唯一真实来源**是 `Documents/`,系统**没有在线上传 UI**。任何对文件的增删改都必须重跑摄入脚本才会反映到向量库。

### 3.2 支持的文件类型

| 扩展名 | 解析器 | 备注 |
| --- | --- | --- |
| `.pdf` | pypdf | 扫描版 PDF(纯图片)抽不出文字,需先做 OCR |
| `.docx` | python-docx | 抽段落+表格,**丢弃**图片、文本框、页眉页脚、批注 |
| `.md` / `.markdown` | 直接读 | 推荐格式,结构最干净 |
| `.txt` | 直接读 | 假定 UTF-8,非 UTF-8 文件会乱码 |
| `.html` / `.htm` | BeautifulSoup+lxml | 自动剥 `<script>` / `<style>` |

**老的 `.doc`(Word 97-2003 二进制格式)、`.xlsx`、`.pptx`、`.csv` 暂不支持**。需要的话先转成 PDF 或 Markdown。

### 3.3 第一次摄入

```bash
cd backend
uv run python -m scripts.ingest
```

控制台会逐文件打印:

```
Target collection: kb_nomic_embed_text_va1b2c3d4 (config_hash=a1b2c3d4)
added 01-项目简介.md (3 chunks)
added 02-摄入脚本使用说明.md (4 chunks)
...
Summary: {'added': 6, 'failed': 0, 'skip_duplicate': 0}
```

退出码:
- `0` 全部成功
- `1` 部分失败(失败清单打到 stderr,成功的已入库)
- `2` `Documents/` 不存在或不是目录

完成后到前端管理员后台 → **文档信息**,确认 `chunk_count` 与控制台输出一致。

### 3.4 增量更新

直接再跑一次:

```bash
uv run python -m scripts.ingest
```

行为:
- 文件内容没变(sha256 一致)→ `skip(unchanged)`
- 同样内容换了路径 → `skip(duplicate-content)`
- 新增文件 → `added`
- `Documents/` 里被删的文件 → `pruned`(库内文档与向量一并清理)

想跳过 prune 用 `--no-prune`。

### 3.5 干跑(只看不做)

不确定操作影响时,先用 `--dry-run`:

```bash
uv run python -m scripts.ingest --dry-run
```

只打印 `would add` / `would prune`,**不写数据库、不调 embedding、不动 Chroma**。验证清单符合预期再去掉 `--dry-run` 实跑。

### 3.6 重建整个库

**只在以下场景需要**:

- 在后台 → **切分参数** 改了 `chunk_size` / `chunk_overlap` / `splitter`,且看到了"requires_rebuild"提示。
- 升级了 embedding 模型(强烈不建议,等价于换知识库)。

操作:

```bash
uv run python -m scripts.ingest --rebuild
```

会先删掉**当前** collection 的全部向量、清空 SQLite 的 `documents` / `chunks` 表,再按新参数全量摄入。

**注意**:`--rebuild` 只删当前 collection,旧参数对应的 collection 仍残留在 `backend/chroma_data/` 里。确认不再需要的话手动 `rm -rf` 对应目录即可。

### 3.7 临时换源目录

```bash
uv run python -m scripts.ingest --documents-dir /path/to/other/docs
```

不会改 `.env`,只对本次生效。适合临时试一批文档,确认效果后再决定要不要正式入库。

### 3.8 查日志

```bash
tail -n 50 LOG/ingest.log
```

事件类型:
- `run_start` — 这次摄入的参数(collection、config_hash、chunk_size...)
- `added` — 每个成功入库的文件(source、doc_id、sha256、chunk_count)
- `failed` — 失败文件 + 错误原因
- `pruned` — 被清理的旧文档
- `run_end` — 汇总 stats

JSON-lines 格式,可以直接 `jq` 过滤:

```bash
# 看哪些文件失败了
grep '"event": "failed"' LOG/ingest.log | jq '{source, error}'

# 看本次新增了几个文档
tail -n 100 LOG/ingest.log | grep '"event": "added"' | wc -l
```

---

## 4. 数据与日志位置

| 路径 | 内容 | 删除影响 |
| --- | --- | --- |
| `backend/ragusky.db` | SQLite 元数据(用户、文档、切片、会话、消息、切分参数) | **删 = 重置整个系统**,需要重新创建管理员并重跑摄入 |
| `backend/chroma_data/` | Chroma 持久化向量 | 删 = 所有向量丢失,需要 `--rebuild` 重做 embedding |
| `LOG/ingest.log` | 摄入事件 | 可删,自动滚动(10MB × 10 backups) |
| `LOG/retrieval.log` | 管理员召回测试事件 | 同上 |
| `LOG/chat.log` | 用户问答事件(含完整 query/answer) | 同上,**含敏感内容,定期清理** |
| `.run/*.log` | uvicorn / vite 的 stdout/stderr | 可删 |
| `.run/*.pid` | 启动脚本写入的 PID | 删 = `stop.sh` 找不到进程,需手动 kill |

---

## 5. 常见故障速查

| 现象 | 检查 |
| --- | --- |
| `ModuleNotFoundError: No module named 'xxx'` 跑摄入脚本时 | 在 `backend/` 跑 `uv sync` 重新装依赖;或确认是用 `uv run` 而不是裸 `python` |
| 摄入时 `httpx.ConnectError: Connection refused` 11434 | Ollama 没启动 → `ollama serve` |
| 摄入时调 OpenAI/Ark 报 401 | `.env` 的 `OPENAI_API_KEY` 或 `OPENAI_BASE_URL` 写错 |
| 启动后登录页可以打开,但登录 401 | `INITIAL_ADMIN_PASSWORD` 改过但 SQLite 已存在旧 admin → 在管理员后台改密码,或删 `backend/ragusky.db` 重置 |
| 聊天回答完整生成了,但前端界面不显示 token | 浏览器 DevTools → Network 看 `POST /api/v1/chat` 是不是 200;检查 [frontend/src/api/chat.ts](frontend/src/api/chat.ts) 的 SSE 解析(已知 `\r\n` 与 `\n` 分隔符差异,已修复) |
| 改完 chunk_size 后聊天答不出内容 | 没跑 `--rebuild`,新 collection 是空的 |
| `stop.sh` 报 no pid file 但端口被占 | `lsof -ti :8000 \| xargs kill` 手动杀 |

---

## 6. 升级与备份

### 6.1 升级代码

```bash
git pull
cd backend && uv sync         # 重新解析依赖
cd ../frontend && pnpm install
./stop.sh && ./start.sh
```

如果 `pyproject.toml` 加了新依赖(比如 python-docx),`uv sync` 会自动装上;前端同理。

### 6.2 备份

定期备份这两个目录就够了,可以原样恢复整个系统状态:

```bash
tar czf ragusky-backup-$(date +%F).tar.gz \
  backend/ragusky.db backend/chroma_data Documents/
```

恢复时解压回原路径,启动服务即可。**不要**只备份 `Documents/` 而不备份 `chroma_data/` —— 否则恢复后需要重新跑一次摄入才能用。
