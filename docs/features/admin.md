# 管理员后台

> 状态:草稿
> 负责人:待定
> 最后更新:2026-05-25

## 目标

为管理员(admin)提供独立的后台能力:管理普通用户账户、查看知识库中已收录的文档信息、对检索效果做召回测试。普通用户只能问答检索,无权访问任何管理员接口。

## 非目标

- 细粒度权限(v1 只有 user / admin 两种角色,不引入组、策略、ACL)。
- 在线上传或删除知识库文档 —— 仍由 [rag.md](rag.md) 中的离线脚本完成。
- 审计日志的合规级保留(v1 仅做基础操作日志,不做不可篡改归档)。
- 第三方 SSO / OAuth(v1 仅用户名 + 密码)。

## 用户流程

### 账户管理
1. admin 登录后进入"用户管理"页面。
2. 列出所有账户(用户名、角色、是否启用、创建时间、最后登录时间)。
3. admin 可执行:新建账户、修改角色、启用/禁用、重置密码、删除。
4. 不能删除或禁用最后一个启用状态的 admin(系统至少保留 1 个 admin)。

### 文档信息查看
1. admin 进入"知识库文档"页面。
2. 列出当前 Chroma + SQLite 中已收录的文档(文件名/相对路径、切片数、入库时间、`sha256`、文件大小、mime 类型)。
3. 提供搜索/过滤(按文件名、按入库时间)。
4. 只读 —— 增删仍走离线脚本。页面顶部明确提示"修改 `Documents/` 文件夹后请运行 `python backend/scripts/ingest.py`"。

### 召回测试
1. admin 进入"召回测试"页面。
2. 输入一个 query、设置 `top_k`(默认 4)、可选元数据过滤。
3. 后端**仅执行检索**(不调用生成 LLM),返回 top-k 切片、相似度分数、所属文档、切片原文。
4. 页面以表格形式展示,允许复制切片文本,便于评估检索是否命中预期。
5. 可选:导入/导出黄金 Q/A 集做批量召回评估(v1 可不做,留待 v2)。

### 切分参数配置
1. admin 进入"切分参数"页面。
2. 查看并修改全局生效的 `chunk_size` 与 `chunk_overlap`(默认 800 / 120),也可同时调整切分器类型(`recursive` / `markdown_aware`,待定见 [rag.md](rag.md))。
3. 修改保存后**仅写入配置表**,不立即生效;页面顶部明确提示:
   > 切分参数修改后,必须重新运行 `python backend/scripts/ingest.py --rebuild` 才会对存量文档生效,并会触发 Chroma collection 升版(如 `kb_nomic_v1` → `kb_nomic_v2`)。
4. 校验:`chunk_size` 取值 100–4000;`chunk_overlap` 必须 < `chunk_size` 且 ≥ 0;不满足返回 400。
5. 历史变更记录在 `ingest_config_history` 表中(谁、何时、改了什么),便于回溯。

## API

所有管理员端点统一前缀 `/api/v1/admin`,**必须**通过角色为 `admin` 的会话访问,否则返回 403。

### 认证
- `POST /api/v1/auth/login` —— 用户名 + 密码登录,签发 JWT(或 session cookie,二选一,见"待解决问题")。响应包含 `role`。
- `POST /api/v1/auth/logout`
- `GET /api/v1/auth/me` —— 当前用户信息。

### 用户管理
- `GET /api/v1/admin/users` —— 列出账户。
- `POST /api/v1/admin/users` —— 创建账户 `{ username, password, role }`。
- `PATCH /api/v1/admin/users/{user_id}` —— 修改 `role` / `is_active`。
- `POST /api/v1/admin/users/{user_id}/reset-password` —— 重置密码 `{ new_password }`。
- `DELETE /api/v1/admin/users/{user_id}` —— 删除账户(校验"至少保留 1 个启用 admin")。

### 文档信息
- `GET /api/v1/admin/documents` —— 列出 SQLite `documents` 表的全部内容,支持分页与按 `title`/`source` 模糊过滤。

### 召回测试
- `POST /api/v1/admin/retrieval-test`
  - 请求:`{ "query": "string", "top_k": 4, "filters": { ... } }`
  - 响应:`{ "chunks": [{ "chunk_id", "doc_id", "source", "score", "text" }] }`
  - 不调用生成 LLM,仅返回向量检索结果。

### 切分参数配置
- `GET /api/v1/admin/ingest-config` —— 返回当前生效的 `{ chunk_size, chunk_overlap, splitter, updated_at, updated_by }`。
- `PUT /api/v1/admin/ingest-config` —— 更新参数 `{ chunk_size, chunk_overlap, splitter }`,校验范围后写入 `ingest_config` 单行表,并向 `ingest_config_history` 追加一条记录。响应中明确返回 `requires_rebuild: true`,提醒前端展示重建提示。
- `GET /api/v1/admin/ingest-config/history` —— 列出变更历史,分页。

## 数据模型(SQLite 扩展)

在 [rag.md](rag.md) 既有表之上新增:

- `users(user_id PK, username UNIQUE, password_hash, role, is_active, created_at, last_login_at)` —— `role` 取值 `user` / `admin`;`password_hash` 使用 `argon2id` 或 `bcrypt`,**严禁明文存储**。
- 现有 `sessions` 表增加 `user_id FK NULL`(NULL 表示匿名会话,v1 可选是否允许匿名,见"待解决问题")。
- `ingest_config(id PK CHECK(id=1), chunk_size, chunk_overlap, splitter, updated_at, updated_by FK users.user_id)` —— 单行配置表(用 `CHECK(id=1)` 保证全局唯一)。摄入脚本启动时读取此表;若表为空使用代码内默认值(800 / 120 / `recursive`)并写入。
- `ingest_config_history(history_id PK, chunk_size, chunk_overlap, splitter, changed_at, changed_by FK users.user_id)` —— 每次变更追加一条,便于回溯。

迁移注意:首次启动若 `users` 表为空,自动创建一个初始 admin(用户名 `admin`,初始密码从环境变量 `INITIAL_ADMIN_PASSWORD` 读取,缺失则启动失败并打印明确错误)。

## 前端

- 路由分组:`/admin/*`,前端路由守卫拦截非 admin 访问并跳转登录页或 403 页。
- 三个主要页面:用户管理、文档信息、召回测试,沿用 [CLAUDE.md](../../CLAUDE.md) 中的蓝白配色与 design tokens。

## 依赖

- 后端:`passlib[argon2]` 或 `passlib[bcrypt]` 做密码哈希;`python-jose` 或 `fastapi-users` 做认证(二选一,见"待解决问题")。
- 前端:沿用 Vue 3,无额外特殊依赖。

## 边界与失败场景

- **删除/禁用最后一个 admin**:API 直接返回 400,前端按钮置灰并提示。
- **修改自己角色为 user**:同样拒绝,避免管理员意外把自己降级失去后台访问。
- **密码强度**:至少 8 位,包含字母与数字;不达标返回 400。
- **登录暴力破解**:同一用户名连续失败 ≥ 5 次,锁定账户 15 分钟(锁定状态写入 `users` 表或 Redis,见"待解决问题")。
- **召回测试调用失败**(Chroma 不可用):返回 503,前端提示后端检索服务不可用。
- **会话与用户解耦**:删除用户时,该用户历史 `sessions` 保留但 `user_id` 置为 NULL 或标记为 `deleted_user`,避免外键级联清空历史聊天记录。
- **切分参数与存量数据不一致**:UI 修改 `chunk_size` / `chunk_overlap` 后,若 admin 忘记重跑摄入脚本,存量切片仍按旧参数生成。前端必须在"切分参数"和"文档信息"两个页面顶部持续提示;脚本启动时若发现"当前配置 hash 与 collection 元数据中记录的 hash 不一致",打印 `WARN` 并建议加 `--rebuild`。

## 待解决问题

- 认证方案:JWT(无状态、易扩展)vs server-side session + cookie(易吊销、CSRF 需处理)?v1 哪种?
- 是否允许匿名用户使用 `/chat`?如允许,如何限流?
- 锁定状态存哪儿:SQLite 字段 vs Redis?v1 若不上 Redis,SQLite 已够用。
- 召回测试是否需要持久化历史(便于回归对比),还是一次性查询?
- 是否需要"操作日志"(谁在何时改了谁的角色 / 密码)?v1 是否实现?
