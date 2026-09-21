# Headroom 本地 MCP 说明

安装目录：`D:\code\agent\mcp\headroom`（Python venv）

> 2026-09-21 由 `D:\app\mcp\headroom` 迁移至此。venv 迁移后
> `.venv\Scripts\headroom.exe` 启动器内嵌的旧绝对路径已失效，改用
> `.venv\Scripts\headroom.cmd`（转调 `python.exe -m headroom.cli`）。

## 已配置

| 宿主 | 配置文件 | 启动命令 |
|------|----------|----------|
| Codex CLI | `C:\Users\DLHJ-LS\.codex\config.toml` → `mcp_servers.headroom` | `python.exe -m headroom.cli mcp serve` |
| Cursor | `C:\Users\DLHJ-LS\.cursor\mcp.json` | `python.exe -m headroom.cli mcp serve` |
| Claude Code | `C:\Users\DLHJ-LS\.claude.json` → `mcpServers.headroom` | 未配置 |

两端均指向本目录 `.venv`，无需把 `headroom` 加入系统 PATH。

## 可用工具

- `headroom_compress`：按需压缩大段文本
- `headroom_retrieve`：按 hash 取回原文
- `headroom_stats`：会话压缩统计

当前为 **MCP-only**（不启 proxy）。stdio 由 Cursor / Claude 按需拉起，无需常驻进程。

## 验证

```powershell
& "D:\code\agent\mcp\headroom\.venv\Scripts\headroom.cmd" mcp status
```

- Cursor：重启或刷新 MCP 面板，确认 `headroom` 已连接
- Claude Code：重启后执行 `/mcp`，应看到上述 3 个工具

## 升级

```powershell
& "D:\code\agent\mcp\headroom\.venv\Scripts\python.exe" -m pip install -U "headroom-ai[mcp]"
```

## 可选：启用 Proxy

仅在需要「自动压缩全部流量」时：

```powershell
& "D:\code\agent\mcp\headroom\.venv\Scripts\headroom.cmd" proxy
```

或直接用后台启动脚本：`C:\Users\DLHJ-LS\.headroom\start-proxy.cmd`
（无窗口启动，日志写入 `%USERPROFILE%\.headroom\proxy.out.log`）。

代理依赖 `headroom-ai[proxy]` 已安装；Kompress 压缩模型缓存在
`C:\Users\DLHJ-LS\.cache\huggingface\hub\models--chopratejas--kompress-v2-base`（约 274MB）。

然后把客户端的 `ANTHROPIC_BASE_URL` 指到 `http://127.0.0.1:8787`（会改变现有 API 路由，请谨慎操作）。
