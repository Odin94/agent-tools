#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: gh_find_prs_by_commit.sh [options] <commit> [<commit> ...]
       gh_find_prs_by_commit.sh [options] --stdin

Find pull requests associated with one or more commit hashes in the GitHub
repository for the current folder.

Options:
  --stdin               Read commit hashes from stdin, one per line.
  --since WHEN          Inclusive lower time bound. Accepts YYYY-MM-DD or ISO8601.
  --until WHEN          Inclusive upper time bound. Accepts YYYY-MM-DD or ISO8601.
  --date-field FIELD    Field used for time filtering: created, updated, merged.
                        Default: merged
  --format FORMAT       Output format: tsv or json. Default: tsv
  -h, --help            Show this help message
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

normalize_since() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    printf '%sT00:00:00Z' "$value"
  else
    printf '%s' "$value"
  fi
}

normalize_until() {
  local value="$1"
  if [[ "$value" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    printf '%sT23:59:59Z' "$value"
  else
    printf '%s' "$value"
  fi
}

ts_for_field() {
  local created="$1"
  local updated="$2"
  local merged="$3"
  local field="$4"

  case "$field" in
    created) printf '%s' "$created" ;;
    updated) printf '%s' "$updated" ;;
    merged) printf '%s' "$merged" ;;
    *)
      echo "Error: unsupported date field: $field" >&2
      exit 1
      ;;
  esac
}

since=""
until=""
date_field="merged"
format="tsv"
use_stdin=0
declare -a commits=()

while (($# > 0)); do
  case "$1" in
    --stdin)
      use_stdin=1
      shift
      ;;
    --since)
      since="$(normalize_since "${2:-}")"
      shift 2
      ;;
    --until)
      until="$(normalize_until "${2:-}")"
      shift 2
      ;;
    --date-field)
      date_field="${2:-}"
      shift 2
      ;;
    --format)
      format="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      commits+=("$1")
      shift
      ;;
  esac
done

case "$format" in
  tsv|json) ;;
  *)
    echo "Error: unsupported format: $format" >&2
    exit 1
    ;;
esac

case "$date_field" in
  created|updated|merged) ;;
  *)
    echo "Error: unsupported date field: $date_field" >&2
    exit 1
    ;;
esac

require_command git
require_command gh

git rev-parse --is-inside-work-tree >/dev/null
repo="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"

if [[ "$use_stdin" -eq 1 ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    commits+=("${line%%[[:space:]]*}")
  done
fi

if [[ "${#commits[@]}" -eq 0 ]]; then
  echo "Error: provide at least one commit hash or use --stdin" >&2
  exit 1
fi

declare -A seen=()
declare -a rows=()
declare -a json_rows=()

for commit in "${commits[@]}"; do
  while IFS=$'\t' read -r number title state created updated merged url; do
    [[ -z "$number" ]] && continue

    timestamp="$(ts_for_field "$created" "$updated" "$merged" "$date_field")"

    if [[ -n "$since" && ( -z "$timestamp" || "$timestamp" < "$since" ) ]]; then
      continue
    fi

    if [[ -n "$until" && ( -z "$timestamp" || "$timestamp" > "$until" ) ]]; then
      continue
    fi

    key="${number}:${commit}"
    if [[ -n "${seen[$key]:-}" ]]; then
      continue
    fi
    seen["$key"]=1

    rows+=("$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s' \
      "$commit" "$number" "$state" "$title" "$created" "$updated" "$merged" "$url")")
    json_rows+=("{\"commit\":\"$commit\",\"number\":$number,\"state\":\"$state\",\"title\":\"${title//\"/\\\"}\",\"createdAt\":\"$created\",\"updatedAt\":\"$updated\",\"mergedAt\":\"$merged\",\"url\":\"$url\"}")
  done < <(
    gh api \
      -H "Accept: application/vnd.github+json" \
      "repos/$repo/commits/$commit/pulls" \
      --jq '.[] | [
        (.number | tostring),
        .title,
        .state,
        (.created_at // ""),
        (.updated_at // ""),
        (.merged_at // ""),
        .html_url
      ] | @tsv'
  )
done

if [[ "$format" == "json" ]]; then
  printf '[%s]\n' "$(IFS=,; echo "${json_rows[*]-}")"
  exit 0
fi

printf '%s\n' "${rows[@]}"
