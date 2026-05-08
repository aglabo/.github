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

## Changes

### Core Changes

### Test Updates

### Removed

## Change Type (optional)

Select all that apply:

- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
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


## Checklist

Please confirm the following (if applicable):

- [ ] Formatting and lint checks pass (e.g. `dprint check`, `pnpm lint`)
- [ ] Tests pass (if test suite exists)
- [ ] Documentation updated (for user-facing changes)
- [ ] PR title follows [Conventional Commits](https://www.conventionalcommits.org/)
- [ ] Shared types and utilities are imported from common modules, not inlined in implementation files

## Additional Notes

*Optional: add screenshots, design notes, or concerns for reviewers.*
