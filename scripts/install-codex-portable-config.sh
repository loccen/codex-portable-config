#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BIN_HOME="${CODEX_BIN_HOME:-$HOME/.local/bin}"
HOOKS_HOME="${CODEX_GIT_HOOKS_HOME:-$HOME/.config/git/hooks}"
STATE_HOME="${CODEX_HOME}/portable-config"
AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"
AGENTS_TEMPLATE="${REPO_ROOT}/templates/user/AGENTS.md"
NTFY_ENV_TARGET="${CODEX_HOME}/ntfy-notifier.env"
NTFY_ENV_TEMPLATE="${REPO_ROOT}/env/ntfy-notifier.env.example"
TIMESTAMP="$(date '+%Y%m%d%H%M%S')"

MANAGED_SKILLS=(
  "codex-ntfy-final-notifier"
  "prototype-to-ui-spec"
  "requirements-to-ui-frontend"
)

log() {
  printf '[install] %s\n' "$*"
}

ensure_dir() {
  mkdir -p "$1"
}

backup_if_needed() {
  local target="$1"
  local source="$2"

  if [[ -f "$target" ]] && ! cmp -s "$source" "$target"; then
    cp "$target" "${target}.bak.${TIMESTAMP}"
    log "已备份 ${target} -> ${target}.bak.${TIMESTAMP}"
  fi
}

ensure_path_line() {
  local file="$1"
  local line='export PATH="$HOME/.local/bin:$PATH"'

  touch "$file"
  if ! grep -Fqx "$line" "$file"; then
    printf '\n%s\n' "$line" >> "$file"
    log "已更新 ${file}"
  fi
}

sync_skill() {
  local name="$1"
  local source_dir="${REPO_ROOT}/skills/${name}"
  local target_dir="${CODEX_HOME}/skills/${name}"

  rm -rf "$target_dir"
  cp -R "$source_dir" "$target_dir"
}

ensure_dir "$CODEX_HOME"
ensure_dir "${CODEX_HOME}/skills"
ensure_dir "$BIN_HOME"
ensure_dir "$HOOKS_HOME"
ensure_dir "$STATE_HOME"

backup_if_needed "$AGENTS_TARGET" "$AGENTS_TEMPLATE"
install -m 0644 "$AGENTS_TEMPLATE" "$AGENTS_TARGET"
log "已安装用户级 AGENTS.md"

install -m 0755 "${REPO_ROOT}/bin/ai-commit" "${BIN_HOME}/ai-commit"
install -m 0755 "${REPO_ROOT}/bin/ai-task" "${BIN_HOME}/ai-task"
install -m 0755 "${REPO_ROOT}/git-hooks/commit-msg" "${HOOKS_HOME}/commit-msg"
log "已安装 ai-commit、ai-task 和 commit-msg hook"

git config --global core.hooksPath "$HOOKS_HOME"
git config --global alias.ai-log "log --date=short --format=%h%x20%ad%x20%an%x20%s%n%(trailers:only,unfold=true)"
log "已写入 Git 全局 hooksPath 与 ai-log alias"

ensure_path_line "${HOME}/.bashrc"
ensure_path_line "${HOME}/.zshrc"

for skill_name in "${MANAGED_SKILLS[@]}"; do
  sync_skill "$skill_name"
  log "已同步 skill: ${skill_name}"
done

chmod +x "${CODEX_HOME}/skills/codex-ntfy-final-notifier/scripts/send-ntfy-final-summary.sh"

if [[ ! -f "$NTFY_ENV_TARGET" ]]; then
  install -m 0600 "$NTFY_ENV_TEMPLATE" "$NTFY_ENV_TARGET"
  log "已写入 ntfy 占位配置模板"
fi

printf '%s\n' "$REPO_ROOT" > "${STATE_HOME}/source-repo.txt"
printf '%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" > "${STATE_HOME}/installed-at.txt"

log "安装完成"
