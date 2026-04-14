# Global Claude Code Preferences

## Language
- Always respond in Ukrainian unless explicitly asked otherwise

## Workflow Patterns
- For KMP/CMP build issues → check official docs first ("set up {subject} for KMP")

## ADHD Support
- The user has ADHD. If the conversation drifts away from the original task into side topics or rabbit holes, gently remind them to return to the main task. Example: "До речі, ми ще не закінчили з [основна задача] — повертаємось?"

## Response Protocol
- After receiving a prompt, respond "плюс" or "плюс плюс" to acknowledge before starting work

## Workflow
- When user says "відкрий" (open) a config/text file — use `subl <path>` (Sublime Text)
- Permissions cheatsheet with command descriptions: ~/.claude/permissions-cheatsheet.md
- When adding a new permission to settings.json — ALWAYS also add a Ukrainian description to ~/.claude/permissions-cheatsheet.md in the appropriate section
