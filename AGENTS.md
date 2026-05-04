# 仓库说明

这个仓库用于打包一套可迁移的 Codex 用户级环境，让 Codex agent 在新机器上直接完成安装、同步和自检。

## 迁移任务

- 当用户要求“根据当前仓库完成 Codex 环境迁移”或表达同类意图时，直接执行 `./install.sh` 与 `./doctor.sh`，不要把文件复制、Hook 配置、Skill 安装或 PATH 调整甩给用户手动完成。
- 安装时默认覆盖用户级 `~/.codex/AGENTS.md`，但若发现已有不同内容，先由安装脚本自动备份，再写入本仓库模板。
- 安装完成后必须运行自检，并把结果分成“已完成”“警告”“后续可选项”三类说明。
- 如果唯一剩余问题是 `~/.codex/ntfy-notifier.env` 仍为占位配置，迁移仍视为完成；最终答复里说明“最终通知目前为 best-effort，待本机补齐有效 topic 后生效”即可。

## 仓库维护

- 修改用户级行为规则时，同时更新 `templates/user/AGENTS.md`、`README.md` 和相关脚本，不要只改其中一处。
- 修改 `ai-commit`、`ai-task` 或 git hook 时，必须同步更新 `bin/`、`git-hooks/` 和 `doctor` 自检逻辑。
- 修改仓库内随附的 skill 时，保持 `skills/` 下副本可直接同步到 `~/.codex/skills/`，不要依赖额外的在线 clone。
- 除非用户明确要求，否则不要把本机真实 env、topic、token、日志或账号态文件写入仓库。
