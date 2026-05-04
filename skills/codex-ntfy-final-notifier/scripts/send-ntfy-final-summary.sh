#!/usr/bin/env bash
set -u

LOG_FILE="/tmp/codex-ntfy-final-notifier.log"
ENV_FILE="${HOME}/.codex/ntfy-notifier.env"

log() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG_FILE"
}

redact_topic() {
  local value="$1"
  if [[ ${#value} -le 12 ]]; then
    printf '***'
  else
    printf '%s***%s' "${value:0:10}" "${value: -6}"
  fi
}

main() {
  local summary
  summary="$(cat)"

  if [[ -z "${summary//[[:space:]]/}" ]]; then
    log "ERROR: 摘要内容为空，已跳过发送。"
    printf 'NTFY_FINAL_NOTIFY_STATUS=skipped reason=empty_summary\n'
    return 0
  fi

  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi

  local server="${NTFY_SERVER:-https://ntfy.sh}"
  local topic="${NTFY_TOPIC:-}"
  local priority="${NTFY_PRIORITY:-default}"
  local title="${NTFY_TITLE:-Codex 任务完成}"
  local tags="${NTFY_TAGS:-white_check_mark}"

  if [[ -z "$topic" ]]; then
    log "ERROR: 未配置 NTFY_TOPIC。请在 ${ENV_FILE} 中写入 export NTFY_TOPIC=\"你的topic\"。"
    printf 'NTFY_FINAL_NOTIFY_STATUS=failed reason=missing_NTFY_TOPIC log=%s\n' "$LOG_FILE"
    return 0
  fi

  if ! command -v curl >/dev/null 2>&1; then
    log "ERROR: 未找到 curl 命令。"
    printf 'NTFY_FINAL_NOTIFY_STATUS=failed reason=curl_not_found log=%s\n' "$LOG_FILE"
    return 0
  fi

  local endpoint="${server%/}/${topic}"
  local response_file
  response_file="$(mktemp)"
  local http_code
  local curl_status=1
  local attempt

  for attempt in 1 2; do
    : > "$response_file"
    http_code="$(
      curl -sS \
        --connect-timeout 8 \
        --max-time 20 \
        -o "$response_file" \
        -w '%{http_code}' \
        -H "Title: ${title}" \
        -H "Priority: ${priority}" \
        -H "Tags: ${tags}" \
        --data-binary "$summary" \
        "$endpoint" 2>>"$LOG_FILE"
    )"
    curl_status=$?
    if [[ $curl_status -eq 0 && "$http_code" =~ ^2[0-9][0-9]$ ]]; then
      break
    fi
    sleep 1
  done

  {
    printf 'ntfy endpoint: %s/%s\n' "${server%/}" "$(redact_topic "$topic")"
    printf 'attempts: %s http_code: %s curl_status: %s\n' "$attempt" "$http_code" "$curl_status"
    printf 'response_bytes: %s\n' "$(wc -c < "$response_file" | tr -d ' ')"
  } >> "$LOG_FILE"
  rm -f "$response_file"

  if [[ $curl_status -eq 0 && "$http_code" =~ ^2[0-9][0-9]$ ]]; then
    log "INFO: ntfy 最终摘要发送成功。"
    printf 'NTFY_FINAL_NOTIFY_STATUS=sent log=%s\n' "$LOG_FILE"
  else
    log "ERROR: ntfy 最终摘要发送失败；主任务不阻塞，也不重试。"
    printf 'NTFY_FINAL_NOTIFY_STATUS=failed reason=ntfy_send_failed http_code=%s log=%s\n' "$http_code" "$LOG_FILE"
  fi

  return 0
}

main "$@"
