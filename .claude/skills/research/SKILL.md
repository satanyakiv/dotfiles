---
name: research
description: Offload heavy research to NotebookLM and save grounded, cited results to the ClaudeBrain Obsidian vault. Activates on explicit "/research <topic>" or intent like "research X for me", "do a deep dive on Y", "compile everything about Z". Uses NotebookLM's free Gemini-powered RAG instead of burning Claude tokens.
---

# /research — Zero-Token Research Workflow

Offload document-heavy research to **NotebookLM** and save the results into the user's Obsidian vault at `~/Documents/ClaudeBrain/research/`. This preserves Claude tokens for orchestration and final editing only — the expensive analytical work runs on Google's free infrastructure.

## When to activate

**Explicit triggers:**
- User says `/research <topic>`
- User says "research X for me" / "do a deep dive on Y" / "compile findings about Z"
- User asks to analyze a set of documents, URLs, YouTube videos, or PDFs at once

**Do NOT activate for:**
- Quick Google-search-level questions (that's just `WebSearch`)
- Code-reading tasks (use `Read`/`Grep`)
- Questions answerable from the current conversation context

## Prerequisites

- `notebooklm` CLI must be authenticated: run `notebooklm status` first
- If unauthenticated: STOP and tell the user to run `notebooklm login` in their terminal (OAuth flow requires a browser)
- Vault must exist at `~/Documents/ClaudeBrain/research/` (it's created during initial setup)

## Workflow

### Step 1 — Clarify scope (one short exchange)

Before creating anything, confirm with the user in ONE message:
1. What's the research question (one sentence)?
2. Do they have sources to provide (URLs, PDFs, YouTube links, local files), or should NotebookLM do autonomous web research via `source add-research`?
3. Any deliverables beyond the written summary? (slide deck, podcast, mind map, flashcards)

If the user already gave all this in their original request, skip the clarification.

### Step 2 — Create the notebook

Use a descriptive, date-stamped slug:
```bash
notebooklm create "research-<slug>-$(date +%Y-%m-%d)" --json
```
Parse the `id` from JSON output. Use the full UUID, not a partial, for all subsequent commands (safer in parallel contexts).

### Step 3 — Add sources

**If the user provided sources:**
```bash
notebooklm source add "<url-or-file>" --notebook <id> --json
```
Add each one. Capture `source_id` from JSON.

**If no sources — use autonomous web research:**
```bash
# Fast mode (5-10 sources, seconds)
notebooklm source add-research "<query>" --mode fast --notebook <id>

# Deep mode (20+ sources, 2-5 min) — spawn background subagent
notebooklm source add-research "<query>" --mode deep --no-wait --notebook <id>
# Then spawn a Task agent to run: notebooklm research wait -n <id> --import-all --timeout 1800
```

### Step 4 — Wait for indexing

Sources must be `ready` before querying. Check with:
```bash
notebooklm source list --notebook <id> --json
```
For large batches (5+), spawn a background subagent running `source wait` for each.

### Step 5 — Query

Use `--json` to get references, and `--save-as-note` if the answer should be persisted inside the notebook itself:
```bash
notebooklm ask "<structured question>" --notebook <id> --json
```
Ask 2-4 follow-up questions as needed. Each question uses the same conversation context automatically — or pass `-c <conversation_id>` to pin it.

**Good question patterns:**
- "What are the 3-5 most important themes across all sources?"
- "Where do sources disagree? Quote the conflicting claims."
- "Compile a timeline of key events."
- "What is the strongest argument for X? For not-X?"

### Step 6 — Save results to the vault

Write a markdown file at `~/Documents/ClaudeBrain/research/<slug>.md` with this frontmatter:

```markdown
---
title: <Human-readable title>
date: YYYY-MM-DD
notebook_id: <full-uuid>
sources:
  - <source-1-title-or-url>
  - <source-2-title-or-url>
tags: [research, <topic-tag>]
---

# <Title>

## Question
<the original research question>

## Key findings
- <finding 1>
- <finding 2>

## Details
<synthesized answer with Obsidian-style [[cross-links]] to any related vault notes>

## Sources
<citations from NotebookLM's JSON `references` field>

## Raw NotebookLM output
<optional: the full ask --json response for future reference>
```

**Linking rule:** Wrap significant concepts, people, tools, or projects in `[[double brackets]]` so Obsidian's graph view connects them. Before linking, check if a note already exists at `~/Documents/ClaudeBrain/projects/` or `~/Documents/ClaudeBrain/research/` with that name — if yes, use the exact existing filename.

### Step 7 (optional) — Generate deliverables

Only if the user asked for them:
```bash
notebooklm generate slide-deck --notebook <id>          # PDF slide deck
notebooklm generate audio "<focus angle>" --notebook <id>  # podcast
notebooklm generate mind-map --notebook <id>             # JSON mind map
notebooklm generate flashcards --quantity more --notebook <id>  # study cards
notebooklm generate report --format briefing-doc --notebook <id>  # markdown report
```

These are long-running. Follow the subagent pattern from the official `notebooklm` skill: spawn a Task agent to `artifact wait` and download when ready. Download target: `~/Documents/ClaudeBrain/research/assets/<slug>-<type>.<ext>`.

### Step 8 — Report back

Tell the user:
1. Vault file path (so they can open it in Obsidian)
2. Notebook ID (so they can reference it later)
3. Number of sources used
4. Any pending artifact generation tasks (with artifact IDs)

## Error handling

| Error | Action |
|---|---|
| `notebooklm status` shows not authenticated | STOP. Tell user to run `notebooklm login` and return |
| `source add` fails for one URL | Log warning, continue with others, note the failure in the final vault file |
| Sources never reach `ready` after 10 min | Save partial result with a `status: incomplete` frontmatter field and alert user |
| `ask` returns empty answer | Check sources are indexed; try rephrasing question once; then escalate |
| Rate limit on generation | Note in vault file "Deliverable pending", save notebook ID, user retries later |

## Rules

- **Never delete a research notebook automatically.** Research notebooks are history. If the user wants to clean up, they delete manually.
- **Never commit `storage_state.json` or anything in `~/.notebooklm/`.**
- **Always write the vault file even if some steps partially failed.** Partial results with clear frontmatter are better than nothing.
- **Prefer `--json` output** everywhere — it's more reliable to parse than human text.
- **Use full notebook UUIDs**, not partial IDs, for reliability.
