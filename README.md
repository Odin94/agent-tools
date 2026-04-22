# agent-tools

Small Codex-style skills and helper scripts for coding agents.

This repo is a lightweight toolbox for agent workflows that build on familiar CLI tools instead of custom services. The current focus is an installable Codex skill for GitHub pull request workflows through `git` and `gh`.

## What is here

- `skills/github-pr-cli/SKILL.md`
  Teaches agents when to use the bundled PR helper scripts, including how to find PRs from commit-message matches by combining local `git log` with the commit-to-PR lookup script.
- `skills/github-pr-cli/agents/openai.yaml`
  Makes the skill installable and discoverable in Codex skill lists.
- `skills/github-pr-cli/scripts/`
  Bundled helper scripts for listing open PRs, opening a PR from the current branch, and mapping commits back to PRs.

## Requirements

- `git`
- `gh`
- A local checkout of a GitHub repository
- `gh auth login` completed if the repo is private or your API access requires authentication

## Quick Start

```bash
skills/github-pr-cli/scripts/gh_list_open_prs.sh
skills/github-pr-cli/scripts/gh_open_pr_from_current_branch.sh --draft --fill
git log --all --format=%H --grep 'feat: do thing' | skills/github-pr-cli/scripts/gh_find_prs_by_commit.sh --stdin
```

## Install The Skill In Codex

For local development, symlink `skills/github-pr-cli` into `~/.codex/skills/`. That way, changes in this repo are immediately reflected in the installed skill without needing to recopy files. After that, Codex can use it as `$github-pr-cli`.

Recommended setup:

```bash
mkdir -p ~/.codex/skills
ln -sfn /Users/odin/repos/agent-tools/skills/github-pr-cli ~/.codex/skills/github-pr-cli
```

If you want a fixed snapshot instead of a live development link, copy the folder into `~/.codex/skills/` instead.

## Goal

Keep agent tooling simple, inspectable, and easy to compose from shell scripts plus small skills.
