---
name: wrap-up
description: End-of-session ritual that extracts learnings from the current conversation, saves them to the ClaudeBrain vault, and uploads a copy to the "Claude Master Brain" NotebookLM notebook for persistent cross-session memory. Activates on "/wrap-up", "end session", "save what we learned", or before closing Claude Code.
---

# /wrap-up — Persistent Cross-Session Memory

End-of-session ritual that makes Claude Code's memory survive across sessions. Extracts what matters from the current conversation, writes it to the Obsidian vault, and uploads the same file to a dedicated "Claude Master Brain" notebook on NotebookLM. Future sessions query the Master Brain via the vault's `CLAUDE.md` operating manual and retrieve relevant context without burning tokens to re-explain everything.

## When to activate

**Explicit triggers:**
- User says `/wrap-up`, "end session", "save what we learned", "do a wrap-up"
- User says "I'm going to sleep" / "closing for today" / similar end-of-session cues

**Automatic triggers (soft):**
- Natural pause at the end of a productive multi-hour session — ASK the user if they want to wrap up, don't do it unilaterally

## Prerequisites

- `notebooklm` CLI authenticated (`notebooklm status` must succeed)
- Vault exists at `~/Documents/ClaudeBrain/sessions/`
- Master Brain notebook ID recorded at `~/.notebooklm/master-brain-id` (plain text file with just the UUID)
- If Master Brain ID file is missing: the bridge isn't fully set up yet — STOP and tell the user to run the initial setup

## Workflow

### Step 1 — Analyze the conversation

Re-read the current conversation and extract 4 categories. Be specific and quote when useful.

**Category 1: Corrections**
Times the user corrected Claude's behavior, preferences, or understanding. These are the highest-value memories — they prevent Claude from repeating the same mistake next session.

**Category 2: Successful patterns**
Approaches, commands, file structures, or workflows that worked well. These can be referenced and reused. Record *why* they worked, not just *what* they were.

**Category 3: Key decisions**
Architectural choices, trade-offs, scope decisions. Include the reasoning — future sessions need the "why" to make consistent follow-up decisions.

**Category 4: Unresolved issues / follow-ups**
Things discussed but not finished, bugs noticed but not fixed, feature requests, TODOs.

### Step 2 — Pick a slug

Generate a short, filesystem-safe slug describing the session's main topic. Format: `YYYY-MM-DD-<slug>`. Examples:
- `2026-04-12-notebooklm-bridge-setup`
- `2026-04-12-auth-middleware-refactor`
- `2026-04-12-landing-page-wire-up`

### Step 3 — Write the vault session file

Save to `~/Documents/ClaudeBrain/sessions/<slug>.md`:

```markdown
---
title: <Short title>
date: YYYY-MM-DD
project: <project name or directory>
tags: [session, wrap-up, <topic-tag>]
---

# Session: <Title>

**Date:** YYYY-MM-DD
**Working directory:** <path>
**Duration:** <rough estimate if known>

## One-sentence summary
<What this session accomplished in one sentence.>

## Corrections
- <correction 1 — what Claude did wrong, what the user wanted instead, and why>
- <correction 2 — ...>

## Successful patterns
- <pattern 1 — what worked and why>
- <pattern 2 — ...>

## Key decisions
- **<decision>** — <reasoning and trade-offs>

## Unresolved / follow-ups
- [ ] <TODO 1>
- [ ] <TODO 2>

## Files touched
- `<path>` — <brief note>

## Related
- [[<related note in vault>]]
- [[<another related note>]]
```

**Linking:** Scan `~/Documents/ClaudeBrain/` for existing notes with related names and add `[[links]]` in the "Related" section. Do NOT invent notes that don't exist.

### Step 4 — Upload to Master Brain

```bash
MASTER_BRAIN_ID=$(cat ~/.notebooklm/master-brain-id)
notebooklm source add ~/Documents/ClaudeBrain/sessions/<slug>.md --notebook $MASTER_BRAIN_ID --json
```

Capture `source_id` from JSON. If upload fails (auth, rate limit, network):
- Save the file to the vault anyway
- Write a placeholder line at the top of the vault file: `<!-- upload-pending: YYYY-MM-DD -->`
- Tell the user so they can retry later

### Step 5 — Confirm with user

Tell the user:
1. Vault path: `~/Documents/ClaudeBrain/sessions/<slug>.md`
2. Uploaded to Master Brain: yes/no
3. One-line summary of what was saved
4. Count of corrections/patterns/decisions/TODOs extracted

## How Claude uses this memory in future sessions

This skill writes the memory. The **reading** happens automatically at session start via the vault's `CLAUDE.md` operating manual, which lives at `~/Documents/ClaudeBrain/CLAUDE.md` and contains an instruction like:

> "Before answering questions about project architecture, historical decisions, or user preferences, query the Master Brain notebook using `notebooklm ask` (notebook ID in `~/.notebooklm/master-brain-id`)."

When the user asks something like "what did we decide about X last week?", Claude reads `CLAUDE.md`, runs `notebooklm ask` against the Master Brain, and retrieves the relevant session summaries without loading them all into context.

## Rules

- **Never wrap up silently.** Always confirm with the user before writing — they may want to adjust what's extracted.
- **Quality over quantity.** Three surprising corrections beat thirty generic bullets. Skip the obvious ("we used Python", "we wrote tests") unless the obvious *is* surprising.
- **Never include secrets.** If the session touched API keys, passwords, or personal data, do NOT copy them into the session file. Write `<redacted>` instead.
- **Be honest about partial sessions.** If the session was aborted mid-task, say so in the one-sentence summary.
- **Don't duplicate.** If a similar session file already exists for today, ask whether to update or create a new one.
- **Write to the vault even if Master Brain upload fails.** Vault is the source of truth; Master Brain is the retrieval index.
