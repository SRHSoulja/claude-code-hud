# Claude Code HUD

A live operator HUD for Claude Code's terminal statusline.

Session pressure, weekly quota, context window, and cost estimate, all visible in the terminal while the work is happening.

![Claude Code HUD](claude-code-hud-statusline.png)

```
5h:34% | 7d:4% | ctx:57% | $160.16
```

## What each field means

| Field | Meaning | Source |
|-------|---------|--------|
| `5h` | 5-hour rolling session window usage | Anthropic plan limit (authoritative) |
| `7d` | 7-day weekly quota usage | Anthropic plan limit (authoritative) |
| `ctx` | Context window usage (how full the conversation memory is) | Claude Code runtime (local) |
| `$` | Equivalent API cost estimate for this session (not an invoice) | Claude Code runtime (local) |

**Notes:**
- `5h` and `7d` are Anthropic-authoritative plan-limit values fetched from Anthropic's usage API by Claude Code. These are real quota consumption numbers, not estimates. Only available on Pro/Max plans.
- `7d` may lag slightly behind the claude.ai app because Claude Code refreshes rate limit data periodically, not on every render.
- `ctx` and `$` are computed locally by Claude Code and update in real time on every turn. They are runtime values, not Anthropic-authoritative.
- `$` shows what the session would cost at API rates. If you are on a Pro or Max subscription, you are not billed this amount.

## Setup

### 1. Save the script

Clone this repo or copy the `claude-code-hud` script to any location on your machine:

```bash
chmod +x claude-code-hud
```

### 2. Configure Claude Code

Add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "/absolute/path/to/claude-code-hud"
  }
}
```

Replace `/absolute/path/to/claude-code-hud` with the real absolute path where the script lives on your machine.

### 3. Restart Claude Code

The statusline activates on the next session start.

## Optional: JSON snapshot

The HUD can write a JSON snapshot of usage data to disk on every update, so other scripts or tools can read it.

Set the `CLAUDE_HUD_SNAPSHOT` environment variable:

```bash
export CLAUDE_HUD_SNAPSHOT=~/.claude/usage-snapshot.json
```

Or add it to your Claude Code env settings:

```json
{
  "env": {
    "CLAUDE_HUD_SNAPSHOT": "/absolute/path/to/usage-snapshot.json"
  }
}
```

The snapshot contains the same rate limit values shown by `/usage`, plus context window state and session cost.

## Requirements

- Claude Code v2.1+ (statusline support)
- Python 3.6+
- Claude Pro or Max plan (for `5h` and `7d` fields; `ctx` and `$` work on any plan)

## License

MIT
