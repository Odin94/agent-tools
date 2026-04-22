#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: gh_list_open_prs.sh [--limit N] [--format tsv|json]

List open pull requests for the GitHub repository associated with the current
folder.

Options:
  --limit N        Maximum number of PRs to fetch. Default: 100
  --format FORMAT  Output format: tsv or json. Default: tsv
  -h, --help       Show this help message
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

limit=100
format="tsv"

while (($# > 0)); do
  case "$1" in
    --limit)
      limit="${2:-}"
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
      echo "Error: unknown argument: $1" >&2
      usage >&2
      exit 1
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

require_command git
require_command gh

git rev-parse --is-inside-work-tree >/dev/null
repo="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"

fields='number,title,headRefName,baseRefName,author,updatedAt,url'

if [[ "$format" == "json" ]]; then
  gh pr list \
    --repo "$repo" \
    --state open \
    --limit "$limit" \
    --json "$fields"
  exit 0
fi

gh pr list \
  --repo "$repo" \
  --state open \
  --limit "$limit" \
  --json "$fields" \
  --jq '.[] | [
    (.number | tostring),
    .title,
    .headRefName,
    .baseRefName,
    (.author.login // ""),
    .updatedAt,
    .url
  ] | @tsv'
