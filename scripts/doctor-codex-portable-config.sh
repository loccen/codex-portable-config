#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
BIN_HOME="${CODEX_BIN_HOME:-$HOME/.local/bin}"
HOOKS_HOME="${CODEX_GIT_HOOKS_HOME:-$HOME/.config/git/hooks}"
NTFY_ENV_TARGET="${CODEX_HOME}/ntfy-notifier.env"

PATH="${BIN_HOME}:$PATH"

WARNINGS=0
ERRORS=0

pass() {
  printf '[pass] %s\n' "$*"
}

warn() {
  WARNINGS=$((WARNINGS + 1))
  printf '[warn] %s\n' "$*"
}

fail() {
  ERRORS=$((ERRORS + 1))
  printf '[fail] %s\n' "$*"
}

check_file() {
  local file="$1"
  local label="$2"

  if [[ -f "$file" ]]; then
    pass "${label}: ${file}"
  else
    fail "${label} 缺失: ${file}"
  fi
}

check_executable() {
  local file="$1"
  local label="$2"

  if [[ -x "$file" ]]; then
    pass "${label}: ${file}"
  else
    fail "${label} 不可执行: ${file}"
  fi
}

check_file "${CODEX_HOME}/AGENTS.md" "用户级 AGENTS"
check_executable "${BIN_HOME}/ai-commit" "ai-commit"
check_executable "${BIN_HOME}/ai-task" "ai-task"
check_executable "${HOOKS_HOME}/commit-msg" "commit-msg hook"
check_file "${CODEX_HOME}/skills/codex-ntfy-final-notifier/SKILL.md" "ntfy skill"
check_file "${CODEX_HOME}/skills/prototype-to-ui-spec/SKILL.md" "prototype-to-ui-spec skill"
check_file "${CODEX_HOME}/skills/requirements-to-ui-frontend/SKILL.md" "requirements-to-ui-frontend skill"

if [[ "$(git config --global --get core.hooksPath || true)" == "$HOOKS_HOME" ]]; then
  pass "Git hooksPath 已指向 ${HOOKS_HOME}"
else
  fail "Git hooksPath 未指向 ${HOOKS_HOME}"
fi

if [[ -f "$NTFY_ENV_TARGET" ]]; then
  if grep -Eq '^export NTFY_TOPIC="__FILL_ME__"$' "$NTFY_ENV_TARGET"; then
    warn "ntfy 仍为占位配置；最终通知将以 best-effort 方式跳过或失败"
  elif grep -Eq '^export NTFY_TOPIC=".+\"$' "$NTFY_ENV_TARGET"; then
    pass "ntfy 配置文件已存在"
  else
    warn "ntfy 配置文件存在，但未检测到有效的 NTFY_TOPIC"
  fi
else
  warn "缺少 ntfy 配置文件；最终通知将以 best-effort 方式跳过"
fi

if bash -n "${CODEX_HOME}/skills/codex-ntfy-final-notifier/scripts/send-ntfy-final-summary.sh"; then
  pass "ntfy 通知脚本语法检查通过"
else
  fail "ntfy 通知脚本语法检查失败"
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TEST_REPO="${TMP_DIR}/portable-config-doctor"
mkdir -p "$TEST_REPO"
git init "$TEST_REPO" >/dev/null 2>&1

(
  cd "$TEST_REPO"
  git config user.name "Codex Portable Doctor"
  git config user.email "codex-portable-doctor@example.com"

  printf 'doctor\n' > README.md
  git add README.md

  if ai-task set "目标：验证 portable config 安装链路。约束：仅在临时仓库执行。" >/dev/null 2>&1; then
    pass "临时仓库 ai-task set 成功"
  else
    fail "临时仓库 ai-task set 失败"
  fi

  if ai-task show | grep -q 'portable config 安装链路'; then
    pass "临时仓库 ai-task show 成功"
  else
    fail "临时仓库 ai-task show 未返回预期内容"
  fi

  if ai-commit human -m "验证 portable config" --summary "验证 ai-commit、ai-task 与 commit-msg hook 的基础安装链路。" >/dev/null 2>&1; then
    pass "临时仓库 ai-commit 成功"
  else
    fail "临时仓库 ai-commit 失败"
  fi

  commit_body="$(git log -1 --format=%B)"
  for trailer_key in AI-Agent AI-Model AI-Tool AI-Role Review-Status Prompt-Summary; do
    if printf '%s\n' "$commit_body" | grep -Eq "^${trailer_key}:"; then
      pass "检测到 trailer: ${trailer_key}"
    else
      fail "缺少 trailer: ${trailer_key}"
    fi
  done
)

printf '[summary] warnings=%s errors=%s\n' "$WARNINGS" "$ERRORS"

if [[ "$ERRORS" -gt 0 ]]; then
  exit 1
fi
