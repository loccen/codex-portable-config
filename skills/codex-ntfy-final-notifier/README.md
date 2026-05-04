# codex-ntfy-final-notifier

Codex 主代理最终收口通知 skill：在准备最终答复用户前，通过 ntfy 发送本轮任务摘要到手机通知栏。

## 安装

```bash
./install.sh
```

如果这个目录是作为 `codex-portable-config` 的随仓库 skill 分发，直接运行根目录 `./install.sh` 即可同步到 `~/.codex/skills/codex-ntfy-final-notifier`。

## 本地配置

在本机创建 `~/.codex/ntfy-notifier.env`：

```bash
export NTFY_SERVER="https://ntfy.sh"
export NTFY_TOPIC="your-topic"
export NTFY_PRIORITY="default"
```

不要把本地 env、topic、日志或任何密钥提交到仓库。

## 使用

按 `SKILL.md` 的调用边界使用。主代理只应在最终答复前调用：

```bash
~/.codex/skills/codex-ntfy-final-notifier/scripts/send-ntfy-final-summary.sh <<'SUMMARY'
任务：...
结果：...
SUMMARY
```
