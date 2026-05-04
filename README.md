# codex-portable-config

用于把一套可复用的 Codex 用户级环境打包成 Git 仓库，便于在新机器上由 Codex agent 直接完成迁移。

## 目标

- 用户只需要给 Codex 一句话，让它基于这个仓库完成迁移。
- 迁移过程不要求用户手动复制文件、改 PATH、装 Hook、同步 Skill。
- 敏感本地状态不进仓库，安装脚本只落地模板和可公开的规则。

## 仓库内容

- `templates/user/AGENTS.md`
  用户级 `~/.codex/AGENTS.md` 模板。
- `bin/ai-commit`
  AI 提交包装器。
- `bin/ai-task`
  任务摘要包装器。
- `git-hooks/commit-msg`
  只校验 AI 提交 trailer 的全局 hook。
- `skills/`
  随仓库分发的用户级 skill 副本。
- `env/ntfy-notifier.env.example`
  本地通知配置模板。
- `install.sh`
  入口安装脚本。
- `doctor.sh`
  自检脚本。

## 迁移入口

对 Codex 直接说：

```text
根据当前仓库，完成 Codex 环境迁移，并自行执行安装与自检。
```

在这个仓库内，agent 应直接运行：

```bash
./install.sh
./doctor.sh
```

## 安装结果

安装脚本会完成这些事情：

1. 安装用户级 `AGENTS.md` 到 `~/.codex/AGENTS.md`。
2. 安装 `ai-commit`、`ai-task` 到 `~/.local/bin`。
3. 安装全局 `commit-msg` hook 到 `~/.config/git/hooks`，并写入 `git config --global core.hooksPath`。
4. 同步仓库内的 skill 到 `~/.codex/skills/`。
5. 若 `~/.codex/ntfy-notifier.env` 不存在，则写入占位模板。
6. 给 `~/.bashrc` 与 `~/.zshrc` 追加 `~/.local/bin` PATH。

## 敏感信息策略

- 不提交真实 `NTFY_TOPIC`、token、cookie、日志或账号态。
- `env/` 里只放 example。
- 新机器若还没有有效 `NTFY_TOPIC`，迁移允许先完成；最终通知链路以 best-effort 方式运行。
