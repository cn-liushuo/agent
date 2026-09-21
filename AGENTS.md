# agent 仓库

本仓库是 agent 自动化资产的集散地。`main` 分支的每次 push 都会由
`.github/workflows/sync.yml` 镜像推送到 GitHub / Gitee / GitCode 三个远端，
因此任何提交都会同时落到三个平台，对仓库体积要敏感。

## 项目规则以 `rules/` 为准

本仓库的项目规则统一存放在 `rules/` 目录：

- `rules/agent-repo.mdc` —— 仓库用途、目录布局、提交红线、路径陷阱
- `rules/headroom-mcp.mdc` —— headroom MCP 服务的调用方式与运维要点

**在本仓库开展非平凡工作前，先读取 `rules/` 下与任务相关的 `.mdc` 文件。**

Cursor 经由 `.cursor/rules` → `rules` 的目录联接读取同一批文件；本 CLI 不解析
`.cursor/rules/`，所以在 AGENTS.md 中显式指明，避免规则被跳过。

该联接是本机兼容用的，未纳入版本库。换机器克隆后如需要 Cursor 读规则，
重建即可（无需管理员权限）：

```powershell
New-Item -ItemType Junction -Path "<repo>\.cursor\rules" -Target "<repo>\rules"
```

## 速记

- 禁止提交 `mcp/headroom/.venv/`（约 617 MB），已在 `.gitignore` 中忽略。
- `C:\Users\DLHJ-LS\.agents\skills` 是指向本仓库 `skills/` 的目录联接，
  技能根路径硬编码无法配置，删除该联接会导致技能全部失效。
