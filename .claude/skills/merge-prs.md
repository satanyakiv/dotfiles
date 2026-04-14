---
name: merge-prs
description: "Merge open PRs sequentially from oldest to newest. Updates branches with main, resolves merge conflicts, fixes CI failures, monitors runs. Use when user says 'merge PRs', 'merge pull requests', 'update and merge', or after finishing a task with pending PRs. Also triggers on `/merge-prs`."
disable-model-invocation: true
---

# merge-prs

Merge open pull requests into main, one by one, oldest-first.

## Usage

```
/merge-prs              — merge all open PRs (oldest first)
/merge-prs <number>     — merge specific PR by number
```

## Prompt

$ARGUMENTS

## Process

### 1. Discover

Detect repo from current git remote, then list PRs:

```bash
gh pr list --json number,title,headRefName,createdAt \
  --jq 'sort_by(.createdAt) | .[] | "\(.number) [\(.headRefName)] \(.title)"'
```

If no open PRs — report and stop.

### 2. For each PR (oldest first)

#### a. Update branch

```bash
git fetch origin main
git checkout <branch>
git merge origin/main --no-edit
```

#### b. Resolve conflicts

- `.gitignore` — prefer main for security-related entries (secret files, keystores)
- Build config (`settings.gradle.kts`, `Package.swift`, etc.) — verify every module/package reference has matching files on disk
- Other files — resolve semantically, preserving both sides' intent

#### c. Verify no unrelated changes

```bash
git diff origin/main..HEAD --name-only
```

If files appear that don't belong to this PR's scope:

```bash
git checkout origin/main -- <unrelated-file>
```

Common issue: changes from other feature branches bleed in via merge — build configs, DI modules, unrelated source files.

#### d. Commit, push, monitor CI

```bash
git add -A && git commit --no-edit
git push
# wait for CI run to appear, then monitor
gh run watch <run-id> --exit-status
```

#### e. If CI fails — diagnose

Run through the **Pitfalls Checklist** below. Fix, push, re-monitor.

#### f. Merge when green

```bash
gh pr merge <number> --squash
```

#### g. Prepare for next PR

```bash
git fetch origin main
```

Repeat from step 2 for the next PR.

## Pitfalls Checklist

Check these on EVERY PR — they are the most common failure causes:

### CI / GitHub Actions
- **Environment secrets**: jobs using `${{ secrets.* }}` MUST have `environment: <name>` matching where secrets are stored. Without it, secrets resolve to empty strings — the #1 cause of "malformed config" errors
- **JSON/config injection**: use `printf '%s\n' "$VAR"` never `echo "$VAR"` — echo interprets escape sequences (`\n`, `\t`) and corrupts JSON/XML content
- **Signing keys**: if keystores/certificates are removed from repo for security, CI needs a generation or decode step (e.g. `keytool -genkeypair` for Android debug, base64 decode for release)

### Build system
- **Module/package references**: build config includes (Gradle `include()`, SPM targets, etc.) must match existing directories on disk. After merge, modules from other branches can appear without their source files → build failure
- **Platform-specific configs**: Firebase `google-services.json` / `GoogleService-Info.plist`, app configs with build-type-specific identifiers (e.g. `.debug` suffix) need matching entries for each variant
- **Dependency references**: `implementation(project(":module"))` or equivalent in build files referencing modules that don't exist on this branch

### Merge conflicts
- `.gitignore` — always take main's security-related entries (secret files, config files, keystores)
- Version catalogs / dependency files — merge both additions, watch for duplicate keys
- DI/wiring files — both sides may register to the same list, keep both if their modules exist on the branch

## Rules

- Always oldest PR first — reduces conflict cascading
- Always squash merge — keeps main history clean
- Never merge without green CI — always `gh run watch`
- Never force push during this workflow
- If a PR has unresolvable conflicts or deep issues — skip it, report to user, continue with next
- After all PRs merged, verify no open PRs remain: `gh pr list`