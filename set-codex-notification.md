# Codex CLI 提示音配置

本项目现已包含一个面向 macOS 的 Codex CLI 提示音脚本：`hooks/codex-notify.sh`。

## 安装

```bash
mkdir -p ~/.codex
install -m 755 hooks/codex-notify.sh ~/.codex/notify.sh
```

在 `~/.codex/config.toml` 中加入：

```toml
notify = ["/Users/johnson/.codex/notify.sh"]

[tui]
notifications = ["agent-turn-complete", "approval-requested"]
notification_condition = "always"
notification_method = "auto"
```

## 默认声音

- `Glass.aiff`：任务完成
- `Funk.aiff`：需要审批、确认或额外处理

## 说明

- `notify` 是 Codex 官方支持的外部通知命令入口，会收到 Codex 传入的 JSON 负载。
- `tui.notifications` 会让终端侧继续对 `agent-turn-complete` 和 `approval-requested` 生效。
- 由于外部 `notify` 对审批事件是否稳定透传，取决于当前 Codex 行为版本，脚本做了兼容性关键词兜底。
