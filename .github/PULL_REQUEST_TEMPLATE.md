---
name: Pull Request Template
description: Pull Request format for contributing changes
title: "feat: [short description]"
labels: ["pull request"]
assignees: ["atsushifx"]
---

## Overview

**Summary**
(Brief, imperative one-line summary of the change)

**Background / Motivation**
Briefly explain why this change is needed and any relevant context.

> Example Summary: Adds Vale-based spelling validation to enforce repository terminology.

## Review Order

## Changes

### Core Changes

### Test Updates

### Removed

### Documentation

## Change Type (optional)

Select all that apply:

- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Test
- [ ] Documentation
- [ ] Configuration
- [ ] CI/CD
- [ ] Other

## Related Issues

Link any issues this PR closes or relates to:

> Closes #123
> Related to #456

or No Issue found:

> N/A

## Testing

Please confirm the following (if applicable):

- [ ] Formatting and lint checks pass (e.g. `dprint check`, `pnpm lint`)
- [ ] Tests pass (if test suite exists)
- [ ] Documentation updated (for user-facing changes)
- [ ] PR title follows [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] Shared types and utilities are imported from common modules, not inlined in implementation files

### Manual Verification

If you performed manual verification, write `Steps:` and list the steps you ran:

> Steps:
>
> 1. Ran `runners/run-textlint.sh` without a global config
> 2. Confirmed it exited with code 1

or No manual verification:

> N/A

## Breaking Change

## Additional Notes

*Optional: add screenshots, design notes, or concerns for reviewers.*
