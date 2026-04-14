---
name: interpreting-voice-input
description: Use when interpreting Ukrainian or Russian user messages with technical content, Cyrillic transliterations of English terms ("котлін" → Kotlin, "компоуз" → Compose, "плагін" → plugin), or any signs of speech-to-text artifacts. The user frequently dictates, so transcripts mangle tech terms, confuse homophones, drop punctuation, and merge words. Before acting on literal text, reconstruct intent using project context (CLAUDE.md, conversation, active files). Trigger on ALL Ukrainian/Russian messages that look dictated — even when the user doesn't say so, and even when most of the message looks fine but one term seems off.
---

# Interpreting Voice Input

User dictates often. Voice transcribers mangle English tech terms into Cyrillic ("Kotlin"→"котлін", "plugin"→"плагін"), confuse homophones ("код"/"кот"), drop punctuation, merge words. Don't act on the literal text — reconstruct intent using project context as the decoder key.

## Protocol

**1. Scan for STT signals** — Cyrillic phonetic spellings of English tech terms, words that don't fit the technical context, missing punctuation that changes meaning, ambiguous references ("той плагін", "цей тест").

**2. Reconstruct from context** — recent conversation first, then CLAUDE.md/active files, then the user's typical vocabulary. The project is usually the strongest signal.

**3. Act on reconstructed meaning.** If confident, proceed. Acknowledge only when it materially changes what you're about to do: "Зрозумів — запускаю KMP build".

**4. On genuine ambiguity, ask one sharp question** distinguishing likely candidates: "ресет чого саме — git, бази чи стану додатка?"

## Hard rules

- **Destructive operations** (`rm -rf`, `git reset --hard`, force push, `DROP TABLE`, deleting files/branches): always confirm interpretation before acting, even at 95% confidence.
- **Don't "correct" the user's vocabulary.** If they said "котлін", just proceed — no lectures about "Kotlin".
- **Don't narrate reasoning.** One short acknowledgment max, no interpretation essays.
- **Don't ask on every message.** Context-resolve first; ask only when stuck.

## Examples

**Clear transliteration:** "запусти кмп білд на андроід" → "Run the KMP build for Android" → execute.

**Context-resolved reference:** "полагодь той плагін команд лайн" + recent session about CLI plugin → fix the CLI plugin discussed earlier.

**Genuinely ambiguous, must ask:** "зроби ресет" → git? DB? app state? password? → ask.

## Principle

The user is a senior engineer on a noisy channel. You are the signal-reconstruction layer. Steel-man intent, stay quiet unless the reconstruction matters, ask only when truly stuck.