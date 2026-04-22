# agent-tools

Small bash scripts and Codex-style skills for coding agents.

This repo is a lightweight toolbox for agent workflows that build on familiar CLI tools instead of custom services. The first set of helpers focuses on GitHub pull requests through `git` and `gh`.

## What is here

- `scripts/gh_list_open_prs.sh`
  Lists open pull requests for the GitHub repository tied to the current folder.
- `scripts/gh_open_pr_from_current_branch.sh`
  Opens a pull request from the current branch, or reports the existing PR if one already exists.
- `scripts/gh_find_prs_by_commit.sh`
  Maps one or more commit hashes back to pull requests, with optional time filtering.
- `skills/github-pr-cli/SKILL.md`
  Teaches agents when to use these scripts, including how to find PRs from commit-message matches by combining local `git log` with the commit-to-PR lookup script.

## Requirements

- `git`
- `gh`
- A local checkout of a GitHub repository
- `gh auth login` completed if the repo is private or your API access requires authentication

## Quick Start

```bash
./scripts/gh_list_open_prs.sh
./scripts/gh_open_pr_from_current_branch.sh --draft --fill
git log --all --format=%H --grep 'feat: do thing' | ./scripts/gh_find_prs_by_commit.sh --stdin
```

## Goal

Keep agent tooling simple, inspectable, and easy to compose from shell scripts plus small skills.
