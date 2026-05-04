#!/usr/bin/env bash

ntfy_default_server() {
  printf '%s\n' "https://ntfy.sh"
}

ntfy_default_priority() {
  printf '%s\n' "default"
}

ntfy_default_title() {
  printf '%s\n' "Codex 任务完成"
}

ntfy_default_tags() {
  printf '%s\n' "white_check_mark"
}

ntfy_extract_export_value() {
  local file="$1"
  local key="$2"
  local line
  local value

  [[ -f "$file" ]] || return 1
  line="$(grep -E "^export ${key}=" "$file" | tail -n 1 || true)"
  [[ -n "$line" ]] || return 1

  value="${line#*=}"
  case "$value" in
    \"*\") value="${value#\"}"; value="${value%\"}" ;;
    \'*\') value="${value#\'}"; value="${value%\'}" ;;
  esac

  printf '%s\n' "$value"
}

ntfy_is_valid_topic() {
  local topic="$1"

  [[ -n "$topic" ]] || return 1
  [[ "$topic" != "__FILL_ME__" ]] || return 1
  [[ "$topic" != "__AUTO_GENERATED_BY_INSTALL__" ]] || return 1
  [[ "$topic" =~ ^[A-Za-z0-9][A-Za-z0-9._-]{2,127}$ ]]
}

ntfy_sanitize_host_fragment() {
  local raw_host="$1"
  local sanitized

  sanitized="$(printf '%s' "$raw_host" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-')"
  sanitized="${sanitized#-}"
  sanitized="${sanitized%-}"

  if [[ -z "$sanitized" ]]; then
    sanitized="device"
  fi

  printf '%.16s\n' "$sanitized"
}

ntfy_device_fragment() {
  local raw_host="$1"
  local sanitized
  local checksum

  sanitized="$(ntfy_sanitize_host_fragment "$raw_host")"
  checksum="$(printf '%s' "$sanitized" | cksum | awk '{print $1}')"
  checksum="${checksum:0:6}"

  if [[ -z "$checksum" ]]; then
    checksum="000000"
  fi

  printf 'device%s\n' "$checksum"
}

ntfy_random_suffix() {
  local random_part

  random_part="$(LC_ALL=C od -An -N4 -tx1 /dev/urandom | tr -d ' \n')"
  if [[ -z "$random_part" ]]; then
    random_part="$(date '+%s')"
  fi

  printf '%s\n' "$random_part"
}

ntfy_generate_topic() {
  local host_name
  local device_fragment
  local timestamp
  local random_part

  host_name="$(scutil --get LocalHostName 2>/dev/null || hostname -s 2>/dev/null || hostname 2>/dev/null || printf '%s' "device")"
  device_fragment="$(ntfy_device_fragment "$host_name")"
  timestamp="$(date '+%Y%m%d%H%M%S')"
  random_part="$(ntfy_random_suffix)"

  printf 'codex-%s-%s-%s\n' "$device_fragment" "$timestamp" "$random_part"
}

ntfy_write_env_file() {
  local target="$1"
  local topic="$2"
  local server="$3"
  local priority="$4"
  local title="$5"
  local tags="$6"
  local target_dir
  local tmp_file

  target_dir="$(dirname "$target")"
  mkdir -p "$target_dir"
  tmp_file="$(mktemp "${target_dir}/ntfy-notifier.env.XXXXXX")"

  cat > "$tmp_file" <<EOF
export NTFY_SERVER="${server}"
export NTFY_TOPIC="${topic}"
export NTFY_PRIORITY="${priority}"
export NTFY_TITLE="${title}"
export NTFY_TAGS="${tags}"
EOF

  chmod 0600 "$tmp_file"
  mv "$tmp_file" "$target"
}
