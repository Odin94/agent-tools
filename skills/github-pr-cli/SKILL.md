---
name: github-pr-cli
description: Use when working with GitHub pull requests from the current repository via git and gh CLI, especially to list open PRs, create a PR from the current branch, or map commit hashes and commit-message matches back to PRs.
---

# GitHub PR CLI

Use the bundled bash scripts in this skill when the task is about pull requests for the repository in the current folder.

## Scripts

- `scripts/gh_list_open_prs.sh`
  Use to list open PRs for the current repo.
- `scripts/gh_open_pr_from_current_branch.sh`
  Use to create a PR from the current branch, or detect that one already exists.
- `scripts/gh_find_prs_by_commit.sh`
  Use to map one or more commit hashes to PRs in the current repo.

## Workflow

1. Confirm you are in the intended repository.
2. Prefer these scripts over reimplementing `gh` command sequences inline.
3. If a user asks for PRs tied to commits with a message like `feat: do thing`, first use local git history to find candidate hashes, then pass those hashes to `scripts/gh_find_prs_by_commit.sh`.
4. Resolve script paths relative to this skill directory so the skill still works after installation into `~/.codex/skills`.

## Commands

List open PRs:

```bash
scripts/gh_list_open_prs.sh
scripts/gh_list_open_prs.sh --limit 200 --format json
```

Create or open a PR from the current branch:

```bash
scripts/gh_open_pr_from_current_branch.sh
scripts/gh_open_pr_from_current_branch.sh --draft --fill
scripts/gh_open_pr_from_current_branch.sh --base main --title "feat: do thing" --body "Summary..."
```

Find PRs from commit hashes:

```bash
scripts/gh_find_prs_by_commit.sh a1b2c3d
scripts/gh_find_prs_by_commit.sh --since 2026-01-01 --until 2026-03-31 a1b2c3d e4f5g6h
git log --all --format=%H --grep 'feat: do thing' | scripts/gh_find_prs_by_commit.sh --stdin
```

## Commit-Message Search

When the user asks for PRs containing commits whose message matches some text:

1. Use `git log`, not GitHub search, to find local commits first.
2. Include a time bound when the request implies one, or when the result set could be large.
3. Pass the resulting hashes into `scripts/gh_find_prs_by_commit.sh`.

Examples:

```bash
git log --all --since='2026-01-01' --until='2026-03-31' --format=%H --grep 'feat: do thing' \
  | scripts/gh_find_prs_by_commit.sh --stdin

git log --all --since='2 weeks ago' --format='%H%x09%s%x09%ci' --grep 'fix:' 
```

Use `--date-field created`, `--date-field updated`, or `--date-field merged` on `scripts/gh_find_prs_by_commit.sh` when the user wants the PR lookup filtered to a particular PR time window.
