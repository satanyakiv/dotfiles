# Documentation Style Guide

Rules for writing docs in `docs/` directory. Extracted from existing docs (TESTING.md, CI.md, PERFORMANCE.md).

## Location & Language

- All docs live in `docs/` directory
- Language: **English** (not Ukrainian — unlike Claude responses)
- Filename: `SCREAMING_CASE.md` (e.g., `TESTING.md`, `CI.md`, `PERFORMANCE.md`)

## Document Structure

Every doc follows this skeleton in order:

````
# Title                           — short, 1-2 words
## Opening paragraph(s)           — what this covers, high-level approach (2-5 lines)
## Stack / Tools table            — | Tool | Version | Purpose |
## How It Works / Architecture    — ASCII diagram or table
## File / Module Structure        — ``` tree block with — descriptions
## Running / Commands             — ```bash blocks with # comments
## <Topic-specific sections>      — tables, code examples, explanations
## Not Covered (and Why)          — bulleted list: **Bold term** — reason
## Related                        — bullet links to other docs/plans
````

## Research-doc skeleton

For `*_RESEARCH.md` files (backend/API integration research, vendor-surface audits) use this stricter skeleton. The skeleton is the contract — agents generating new research from Postman / OpenAPI / vendor docs copy this block and fill in values. Sections may be omitted when not applicable; section order is fixed.

```markdown
# <Feature> Research

One-liner about scope. Source of data: <Postman collection name / vendor dev-guide URL / NotebookLM notebook id>.

## Known constants

- Hardcoded values, each tagged with "hardcoded server-side" or "env-specific".

## Headline finding

One bold statement: who owns what, what's in scope for v1, the single most important gate.

## Coverage matrix

| Internal endpoint | Vendor / other source | Owner | Notes |
| ----------------- | --------------------- | ----- | ----- |

## <Per-flow sections>

Tables, nesting, JSON shapes only from verified sources. No walls of code, no pseudo-code, no hypothetical snippets.

## PII / data-retention notes

Only if applicable.

## Implementation backlog

| # | Work item | Notes |
| - | --------- | ----- |

## Not Covered (and why)

**<Bold term>** — reason why excluded.

## Related

- 3–5 links max.
```

## PDFs

Do not commit `.pdf` files to `docs/` if they duplicate an existing `.md`. Markdown is the source — render PDFs on demand. Exceptions (external artifacts with no MD equivalent: design exports, signed contracts) go in `docs/attachments/`.

## Raw research inputs

Folders like `docs/toast-api/postman/`, `docs/openapi/`, etc. hold raw input for research agents (Postman collections, OpenAPI dumps, vendor specs). Rules:

- Git-track only when the collection is stable and needed for reproducibility. Otherwise `.gitignore` or keep outside the repo.
- Do not reference raw-input filenames from inside committed research docs as "source of truth" — the research doc is the source of truth; the raw input is just how the agent got there.

## Formatting Conventions

**Tables** — pipe-separated, left-aligned, dashes separator:

```
| Column A | Column B | Column C |
| -------- | -------- | -------- |
| value    | value    | value    |
```

**ASCII diagrams** — two styles:

- **Vertical flow**: `│`, `├─`, `└─`, `▼` for data/control flow
- **Horizontal pipeline**: `┌──┐`, `└──┘`, `────▶` for sequential pipelines
- **Box diagrams**: `┌───┐ │ │ └─┬─┘` for parallel paths

**Code blocks** — language-tagged:

- ` ```bash ` for commands
- ` ```kotlin ` for code examples
- ` ```toml ` for version catalog
- ` ``` ` (plain) for file trees and ASCII diagrams

**File trees** — 2-space indent, em dash for descriptions:

```
module/
  file.kt                          — description aligned with spaces
  subdir/
    another.kt                     — another description
```

**Emphasis:**

- **Bold** for key terms, important concepts, tool names in prose
- `backtick` for code references (classes, commands, paths, flags)
- `>` blockquotes for important warnings/notes
- Em dash (`—`) not hyphen for explanations after terms

## Style Rules

- **Tone:** factual, concise — "X does Y" not "X is designed to do Y"
- **Length:** ~150-170 lines per doc
- **Tense:** present for what exists, "planned" / "not yet implemented" for future
- **No emojis**
- **"Not Covered" section is mandatory** — each item: `**Bold name** — reason why excluded`
- **"Related" section is mandatory** — links to other `docs/` files and relevant `.claude/features/` plans
- **Versions from source of truth** — always read `gradle/libs.versions.toml`, never hardcode from memory
- **Commands use full Gradle paths** — `:module:task` not just `task`
- **Code examples reference real project code** — not hypothetical/generic

## Source of Truth Principle

Before writing ANY doc:

1. Read the actual source files being documented (build configs, Kotlin code, workflows)
2. Read `gradle/libs.versions.toml` for versions
3. Read existing docs (`docs/TESTING.md`, `docs/CI.md`, `docs/PERFORMANCE.md`) for style reference
4. Never assume — verify commands, file paths, class names from code

## Planned / Future Work Pattern

When documenting features that don't exist yet:

- Mark with `**Status:** NOT STARTED — tracked in <plan reference>`
- Use subsections: "What will change", "Dependencies to add", "Verification (when implemented)"
- Clearly separate from implemented content
