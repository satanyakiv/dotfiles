#!/bin/bash
# Auto-stage files after Claude writes or edits them.
# Receives tool input JSON on stdin from Claude Code PostToolUse hook.

FILE_PATH=$(python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('file_path', ''))
except Exception:
    print('')
" 2>/dev/null)

if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    git add "$FILE_PATH" 2>/dev/null || true
fi
