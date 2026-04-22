#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: gh_open_pr_from_current_branch.sh [options]

Create a pull request for the current branch. If a PR already exists for the
branch, the script prints the existing PR and exits successfully.

Options:
  --base BRANCH     Base branch. Defaults to the repository default branch.
  --title TITLE     PR title. Defaults to the current commit subject.
  --body BODY       PR body.
  --draft           Create a draft PR.
  --web             Open the PR creation flow in the browser.
  --dry-run         Show the gh command that would run without creating a PR.
  --fill            Ask gh to fill title/body from commits.
  -h, --help        Show this help message
EOF
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Error: required command not found: $1" >&2
    exit 1
  fi
}

base_branch=""
title=""
body=""
use_fill=0
use_draft=0
use_web=0
dry_run=0

while (($# > 0)); do
  case "$1" in
    --base)
      base_branch="${2:-}"
      shift 2
      ;;
    --title)
      title="${2:-}"
      shift 2
      ;;
    --body)
      body="${2:-}"
      shift 2
      ;;
    --draft)
      use_draft=1
      shift
      ;;
    --web)
      use_web=1
      shift
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --fill)
      use_fill=1
      shift
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

require_command git
require_command gh

git rev-parse --is-inside-work-tree >/dev/null

repo="$(gh repo view --json nameWithOwner -q '.nameWithOwner')"
current_branch="$(git rev-parse --abbrev-ref HEAD)"

if [[ "$current_branch" == "HEAD" ]]; then
  echo "Error: detached HEAD; switch to a branch before creating a PR" >&2
  exit 1
fi

if [[ -z "$base_branch" ]]; then
  base_branch="$(gh repo view --json defaultBranchRef -q '.defaultBranchRef.name')"
fi

if [[ "$current_branch" == "$base_branch" ]]; then
  echo "Error: current branch matches base branch ($base_branch)" >&2
  exit 1
fi

existing_pr="$(
  gh pr list \
    --repo "$repo" \
    --head "$current_branch" \
    --state all \
    --json number,state,url,title \
    --jq '.[0] | select(.) | [
      (.number | tostring),
      .state,
      .title,
      .url
    ] | @tsv'
)"

if [[ -n "$existing_pr" ]]; then
  printf '%s\n' "$existing_pr"
  exit 0
fi

if [[ -z "$title" && "$use_fill" -eq 0 ]]; then
  title="$(git log -1 --pretty=%s)"
fi

cmd=(
  gh pr create
  --repo "$repo"
  --base "$base_branch"
  --head "$current_branch"
)

if [[ "$use_draft" -eq 1 ]]; then
  cmd+=(--draft)
fi

if [[ "$use_web" -eq 1 ]]; then
  cmd+=(--web)
fi

if [[ "$use_fill" -eq 1 ]]; then
  cmd+=(--fill)
else
  cmd+=(--title "$title")
  if [[ -n "$body" ]]; then
    cmd+=(--body "$body")
  fi
fi

if [[ "$dry_run" -eq 1 ]]; then
  printf '%q ' "${cmd[@]}"
  printf '\n'
  exit 0
fi

"${cmd[@]}"
