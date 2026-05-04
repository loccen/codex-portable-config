# codex-ntfy-final-notifier

Codex 主代理最终收口通知 skill：在准备最终答复用户前，通过 ntfy 发送本轮任务摘要到手机通知栏。

## 安装

```bash
./install.sh
```

如果这个目录是作为 `codex-portable-config` 的随仓库 skill 分发，直接运行根目录 `./install.sh` 即可同步到 `~/.codex/skills/codex-ntfy-final-notifier`。

## 本地配置

优先直接运行仓库根目录 `./install.sh`。安装脚本会自动创建或修复 `~/.codex/ntfy-notifier.env`，为当前机器生成可用 topic；随后运行 `./doctor.sh` 可直接看到应订阅的完整 topic。

如果不是通过 portable config 安装，而是手工创建 env，使用下面的格式，并把 `NTFY_TOPIC` 替换成你自己的值：

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
