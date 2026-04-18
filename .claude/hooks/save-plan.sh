#!/bin/bash
# Hook: PostToolUse → ExitPlanMode
# Copies accepted plan to ~/.claude/plans/<project>/<relevant-name>.md
# Input: TOOL_INPUT (empty for ExitPlanMode), SESSION_ID, PROJECT_DIR

# Find the most recently modified plan file in ~/.claude/plans/
PLANS_DIR="$HOME/.claude/plans"
PLAN_FILE=$(ls -t "$PLANS_DIR"/*.md 2>/dev/null | head -1)

if [ -z "$PLAN_FILE" ] || [ ! -f "$PLAN_FILE" ]; then
  exit 0
fi

# Derive project name from PROJECT_DIR (last path component, lowercased)
if [ -n "$PROJECT_DIR" ]; then
  PROJECT_NAME=$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]')
else
  PROJECT_NAME="misc"
fi

# Extract first heading as summary (strip # prefix, "Plan:" prefix, trim whitespace)
SUMMARY=$(grep -m1 '^#' "$PLAN_FILE" \
  | sed -E 's/^#+[[:space:]]*//' \
  | sed -E 's/^[Pp]lan:[[:space:]]*//' \
  | sed 's/[^a-zA-Zа-яА-ЯіІїЇєЄґҐ0-9 _-]//g' \
  | tr '[:upper:]' '[:lower:]' \
  | tr ' ' '-' \
  | sed -E 's/-+/-/g' \
  | sed 's/^-//;s/-$//' \
  | cut -c1-60)

if [ -z "$SUMMARY" ]; then
  SUMMARY="plan"
fi

DATE=$(date +%d-%m-%Y)
TARGET_DIR="$PLANS_DIR/$PROJECT_NAME"
mkdir -p "$TARGET_DIR"

FILENAME="${DATE}-${SUMMARY}.md"
TARGET="$TARGET_DIR/$FILENAME"

# Avoid overwriting — append counter if exists
if [ -f "$TARGET" ]; then
  i=2
  while [ -f "$TARGET_DIR/${DATE}-${SUMMARY}-${i}.md" ]; do
    i=$((i + 1))
  done
  TARGET="$TARGET_DIR/${DATE}-${SUMMARY}-${i}.md"
fi

cp "$PLAN_FILE" "$TARGET"
echo "Plan saved: ~/.claude/plans/$PROJECT_NAME/$(basename "$TARGET")"
