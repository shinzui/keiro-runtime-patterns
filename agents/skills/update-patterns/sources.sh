#!/usr/bin/env bash
#
# Upstream watermark helper for the update-patterns skill.
#
#   sources.sh status [--project NAME] [--files]   report drift since the recorded commit
#   sources.sh record <project> [commit]           move a watermark forward (default: branch head)
#   sources.sh path <project>                      print the mori-resolved checkout path
#
# State lives in sources.json next to this script.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
state_file="$script_dir/sources.json"

for required_command in git jq mori; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'error: required command not found: %s\n' "$required_command" >&2
    exit 1
  fi
done

usage() {
  sed -n '3,10p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

resolve_path() {
  local uri="$1" path
  path="$(mori path "$uri" 2>/dev/null | tail -1)"
  if [[ -z "$path" || ! -d "$path/.git" ]]; then
    return 1
  fi
  printf '%s\n' "$path"
}

source_field() {
  jq -r --arg project "$1" --arg field "$2" \
    '.sources[] | select(.project == $project or (.project | split("/") | last) == $project) | .[$field]' \
    "$state_file"
}

cmd_status() {
  local filter="" show_files=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --project) filter="${2:-}"; shift 2 ;;
      --files) show_files=1; shift ;;
      *) printf 'error: unknown argument: %s\n' "$1" >&2; usage; exit 2 ;;
    esac
  done

  local drift=0
  while IFS=$'\t' read -r project uri branch subjects last_commit; do
    if [[ -n "$filter" && "$project" != "$filter" && "${project##*/}" != "$filter" ]]; then
      continue
    fi

    printf '\n=== %s  [subjects: %s]\n' "$project" "$subjects"

    local repo_path
    if ! repo_path="$(resolve_path "$uri")"; then
      printf '  unresolved: %s has no local checkout; run `mori registry list` and register it\n' "$uri"
      continue
    fi
    printf '  path:     %s\n' "$repo_path"

    local ref="$branch"
    if ! git -C "$repo_path" rev-parse --verify --quiet "${ref}^{commit}" >/dev/null; then
      ref="HEAD"
      printf '  warning:  branch %s not found; comparing against HEAD\n' "$branch"
    fi

    if ! git -C "$repo_path" rev-parse --verify --quiet "${last_commit}^{commit}" >/dev/null; then
      printf '  unknown watermark %s; fetch the repository, then rerun\n' "${last_commit:0:12}"
      drift=1
      continue
    fi

    local head count
    head="$(git -C "$repo_path" rev-parse "$ref")"
    count="$(git -C "$repo_path" rev-list --count "${last_commit}..${ref}")"
    printf '  recorded: %s\n  %-9s %s (%s)\n  commits:  %s\n' \
      "${last_commit:0:12}" "$ref:" "${head:0:12}" "$ref" "$count"

    if [[ "$count" == "0" ]]; then
      continue
    fi
    drift=1

    # `head` closes the pipe early on a long range; without this guard the
    # resulting SIGPIPE would abort the whole loop under `set -o pipefail`.
    { git -C "$repo_path" log --no-merges --format='    %h %s' "${last_commit}..${ref}" || true; } | head -40
    if [[ "$count" -gt 40 ]]; then
      printf '    ... and %s earlier commits\n' "$((count - 40))"
    fi
    if [[ "$show_files" == "1" ]]; then
      printf '  changed files:\n'
      git -C "$repo_path" diff --stat "${last_commit}..${ref}" | sed 's/^/    /'
    fi
  done < <(jq -r '.sources[] | [.project, .uri, .branch, (.subjects | join(",")), .last_checked_commit] | @tsv' "$state_file")

  printf '\n'
  if [[ "$drift" == "1" ]]; then
    printf 'upstream drift detected\n'
  else
    printf 'no upstream drift since the recorded watermarks\n'
  fi
}

cmd_record() {
  local project="${1:-}" commit="${2:-}"
  if [[ -z "$project" ]]; then
    usage
    exit 2
  fi

  local uri branch
  uri="$(source_field "$project" uri)"
  branch="$(source_field "$project" branch)"
  if [[ -z "$uri" ]]; then
    printf 'error: no source named %s in %s\n' "$project" "$state_file" >&2
    exit 1
  fi

  local repo_path
  if ! repo_path="$(resolve_path "$uri")"; then
    printf 'error: no local checkout for %s\n' "$uri" >&2
    exit 1
  fi

  if [[ -z "$commit" ]]; then
    commit="$branch"
  fi
  local resolved
  resolved="$(git -C "$repo_path" rev-parse --verify "${commit}^{commit}")"

  local now tmp
  now="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  tmp="$(mktemp)"
  jq --arg project "$project" --arg commit "$resolved" --arg now "$now" '
      .sources |= map(
        if (.project == $project or (.project | split("/") | last) == $project)
        then .last_checked_commit = $commit | .last_checked_at = $now
        else . end)
    ' "$state_file" >"$tmp"
  mv "$tmp" "$state_file"
  printf 'recorded %s at %s (%s)\n' "$project" "${resolved:0:12}" "$now"
}

cmd_path() {
  local project="${1:-}"
  if [[ -z "$project" ]]; then
    usage
    exit 2
  fi
  local uri
  uri="$(source_field "$project" uri)"
  if [[ -z "$uri" ]]; then
    printf 'error: no source named %s in %s\n' "$project" "$state_file" >&2
    exit 1
  fi
  resolve_path "$uri"
}

case "${1:-status}" in
  status) shift || true; cmd_status "$@" ;;
  record) shift; cmd_record "$@" ;;
  path) shift; cmd_path "$@" ;;
  -h|--help|help) usage ;;
  *) printf 'error: unknown command: %s\n' "$1" >&2; usage; exit 2 ;;
esac
