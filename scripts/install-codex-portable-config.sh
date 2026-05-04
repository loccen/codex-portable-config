#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
source "${SCRIPT_DIR}/lib/ntfy-env.sh"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BIN_HOME="${CODEX_BIN_HOME:-$HOME/.local/bin}"
HOOKS_HOME="${CODEX_GIT_HOOKS_HOME:-$HOME/.config/git/hooks}"
STATE_HOME="${CODEX_HOME}/portable-config"
AGENTS_TARGET="${CODEX_HOME}/AGENTS.md"
AGENTS_TEMPLATE="${REPO_ROOT}/templates/user/AGENTS.md"
NTFY_ENV_TARGET="${CODEX_HOME}/ntfy-notifier.env"
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

ensure_ntfy_env() {
  local topic
  local server
  local priority
  local title
  local tags

  topic="$(ntfy_extract_export_value "$NTFY_ENV_TARGET" "NTFY_TOPIC" || true)"
  if ntfy_is_valid_topic "$topic"; then
    log "保留现有 ntfy topic: ${topic}"
    return 0
  fi

  server="$(ntfy_extract_export_value "$NTFY_ENV_TARGET" "NTFY_SERVER" || true)"
  priority="$(ntfy_extract_export_value "$NTFY_ENV_TARGET" "NTFY_PRIORITY" || true)"
  title="$(ntfy_extract_export_value "$NTFY_ENV_TARGET" "NTFY_TITLE" || true)"
  tags="$(ntfy_extract_export_value "$NTFY_ENV_TARGET" "NTFY_TAGS" || true)"

  [[ -n "$server" ]] || server="$(ntfy_default_server)"
  [[ -n "$priority" ]] || priority="$(ntfy_default_priority)"
  [[ -n "$title" ]] || title="$(ntfy_default_title)"
  [[ -n "$tags" ]] || tags="$(ntfy_default_tags)"

  if [[ -f "$NTFY_ENV_TARGET" ]]; then
    cp "$NTFY_ENV_TARGET" "${NTFY_ENV_TARGET}.bak.${TIMESTAMP}"
    log "已备份 ${NTFY_ENV_TARGET} -> ${NTFY_ENV_TARGET}.bak.${TIMESTAMP}"
  fi

  topic="$(ntfy_generate_topic)"
  ntfy_write_env_file "$NTFY_ENV_TARGET" "$topic" "$server" "$priority" "$title" "$tags"
  log "已生成 ntfy topic: ${topic}"
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
ensure_ntfy_env

printf '%s\n' "$REPO_ROOT" > "${STATE_HOME}/source-repo.txt"
printf '%s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')" > "${STATE_HOME}/installed-at.txt"

log "安装完成"
