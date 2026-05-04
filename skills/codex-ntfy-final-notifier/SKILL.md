---
name: codex-ntfy-final-notifier
description: 在 Codex 主代理任务最终完成并准备回复用户前，通过 ntfy 向手机通知栏发送本轮执行摘要。
---

# Codex ntfy Final Notifier

用于在 Codex 主代理任务最终完成时，通过 ntfy 发送手机通知栏摘要。

## 调用边界

- 只允许主代理在最终收口阶段调用。
- 子代理、并行代理、临时调研代理、阶段性任务不得调用。
- 只有在准备给用户最终答复前才调用。
- 如果任务失败、部分完成或受限，也要发送摘要。
- 如果用户明确说“本轮不要手机通知”，则跳过。
- 发送失败不得阻塞主任务。
- 发送失败不得重复刷屏。
- 摘要不得包含密钥、token、cookie、完整日志、大段 diff、隐私内容。

## 使用方式

在最终答复前，主代理整理 300-800 字中文摘要，并通过脚本从 stdin 传入：

```bash
~/.codex/skills/codex-ntfy-final-notifier/scripts/send-ntfy-final-summary.sh <<'SUMMARY'
✅ Codex 任务完成

任务：一句话说明本轮用户要求
结果：完成 / 部分完成 / 失败

主要处理：
1. ...
2. ...
3. ...

验证情况：
- 已执行：...
- 结果：...

注意事项：
- ...

下一步：
- ...
SUMMARY
```

执行后必须查看脚本输出：

- `NTFY_FINAL_NOTIFY_STATUS=sent` 表示 ntfy HTTP 请求成功。
- `NTFY_FINAL_NOTIFY_STATUS=failed` 表示发送失败；最终答复中说明通知失败和日志路径。
- `NTFY_FINAL_NOTIFY_STATUS=skipped` 表示未发送；最终答复中说明跳过原因。

脚本读取 `~/.codex/ntfy-notifier.env`，也支持通过环境变量覆盖 `NTFY_SERVER`、`NTFY_TOPIC`、`NTFY_PRIORITY`。
