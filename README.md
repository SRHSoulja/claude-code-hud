# Claude Code HUD

A live operator HUD for Claude Code's terminal statusline.

Active model, session pressure, weekly quota, context window (with input/output token breakdown), and cost estimate — all visible in the terminal while the work is happening.

![Claude Code HUD](claude-code-hud-statusline.png)

```
opusplan(sonnet.4-6) | 5h:41%(3h16m) | 7d:4%(6d10h) | ctx:61% in:140k out:22k | $181.22
```

## What each field means

| Field | Meaning | Source |
|-------|---------|--------|
| `model` | Active model or configured alias. `opusplan(sonnet.4-6)` means opusplan mode is set, Sonnet is executing this turn. | Claude Code runtime + `~/.claude/settings.json` |
| `5h` | 5-hour rolling session window usage + time until reset | Anthropic plan limit (authoritative) |
| `7d` | 7-day weekly quota usage + time until reset | Anthropic plan limit (authoritative) |
| `ctx` | Context window usage (how full the conversation memory is) | Claude Code runtime (local) |
| `in` | Total input tokens sent this session | Claude Code runtime (local) |
| `out` | Total output tokens generated this session | Claude Code runtime (local) |
| `$` | Equivalent API cost estimate for this session (not an invoice) | Claude Code runtime (local) |

The countdown in parentheses (e.g. `3h16m`, `6d10h`) shows time until that usage window resets. It disappears if the reset time is unavailable or already passed.

**Notes:**
- `5h` and `7d` are Anthropic-authoritative plan-limit values fetched from Anthropic's usage API by Claude Code. These are real quota consumption numbers, not estimates. Only available on Pro/Max plans.
- `7d` may lag slightly behind the claude.ai app because Claude Code refreshes rate limit data periodically, not on every render. The countdown is computed locally from the last-received reset timestamp.
- `ctx`, `in`, `out`, and `$` are computed locally by Claude Code and update in real time on every turn. They are runtime values, not Anthropic-authoritative.
- `$` shows what the session would cost at API rates. If you are on a Pro or Max subscription, you are not billed this amount.
- `in`/`out` appear once the first real API turn completes. They help you understand whether context pressure is driven by large inputs (long conversation history, big file reads) or heavy generation (long outputs).
- On startup, `ctx` and `$` may not appear until the first real API turn. `5h` and `7d` may appear before them. This is normal.

## Install

### Quick install

```bash
mkdir -p ~/.claude
curl -fsSL https://raw.githubusercontent.com/SRHSoulja/claude-code-hud/master/claude-code-hud -o ~/.claude/claude-code-hud
chmod +x ~/.claude/claude-code-hud
```

Then add to `~/.claude/settings.json`:

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/claude-code-hud",
    "refreshInterval": 60
  }
}
```

Start a new Claude Code session. The `statusLine` config is read on session start, so the HUD appears once you open a new session. If you later edit the script itself, changes take effect immediately (no restart needed).

### Manual install

Clone this repo or copy the `claude-code-hud` script to any location on your machine. Make it executable with `chmod +x`. Then add the `statusLine` config above, replacing the command path with the absolute path to wherever you saved the script.

### Why `refreshInterval: 60`?

Without it, Claude Code calls the statusline script on every TUI render frame — potentially many times per second. On WSL or slower filesystems this can cause terminal flickering. `refreshInterval: 60` keeps the HUD event-driven (updates on every turn) but caps background polling at once per minute. The usage data doesn't change fast enough to need sub-second refresh.

If you want more frequent background updates, lower the value. If you want the HUD to only update when Claude responds (no background polling), omit `refreshInterval` entirely and accept the potential render overhead.

## Optional: JSON snapshot

The statusline is for humans. The snapshot is for scripts. It writes a machine-readable JSON file on every statusline update so your own tools can read current usage state without parsing terminal output.

Examples of what you could build on it:
- A script that warns you when `5h` crosses 80%
- A dashboard that tracks usage across sessions over time

Set the `CLAUDE_HUD_SNAPSHOT` environment variable:

```bash
export CLAUDE_HUD_SNAPSHOT=~/.claude/usage-snapshot.json
```

Or add it to your Claude Code env settings:

```json
{
  "env": {
    "CLAUDE_HUD_SNAPSHOT": "~/.claude/usage-snapshot.json"
  }
}
```

The snapshot looks like this:

```json
{
  "source": "claude-code-hud",
  "captured_at": "2026-03-27T16:00:31+00:00",
  "model": "claude-sonnet-4-6",
  "rate_limits": {
    "five_hour": { "used_percentage": 34, "resets_at": 1743123456 },
    "seven_day": { "used_percentage": 4, "resets_at": 1743654321 }
  },
  "context_window": {
    "used_percentage": 57,
    "total_input_tokens": 114000,
    "total_output_tokens": 18000
  },
  "cost": { "total_cost_usd": 160.16 }
}
```

## Tracking usage over time

The HUD gives you live awareness. The snapshot gives you data you can accumulate.

The repo does not include a historical analytics pipeline, but the snapshot provides the machine-readable state needed to build one. A few things you could do:

- **Log snapshots to JSONL** after each session to track how your 5h and 7d budgets change over time
- **Measure how much of your session window a specific workflow consumes** (e.g. "that refactor cost 12% of my 5h budget")
- **Track input vs output token ratio** to see whether your prompts or Claude's responses are driving context growth
- **Compare different setups or working styles** to see which ones burn through limits faster

The measured values in the snapshot are facts. What you conclude about why usage is high or low is interpretation. The data gives you the foundation for both.

## Troubleshooting

- **Nothing appears:** Verify the script path in `settings.json` is correct and the file is executable (`chmod +x`).
- **No `5h` or `7d`:** These only appear on Pro/Max subscription plans. `ctx`, `in`, `out`, and `$` work on any plan.
- **No model shown:** The model field appears after the first API turn. If you use a named alias like `opusplan`, the HUD reads `~/.claude/settings.json` to display it — make sure the file is readable.
- **`7d` seems stale:** Claude Code refreshes rate limit data periodically, not on every render. It may lag a few minutes behind the claude.ai app.
- **HUD does not appear after adding to settings.json:** Start a new Claude Code session. The `statusLine` config is read on session start.
- **Terminal flickering on WSL:** Add `"refreshInterval": 60` to the statusLine config and set `"tui": "fullscreen"` in your settings — the fullscreen renderer uses a flicker-free alt-screen mode.

## Windows setup

Claude Code runs statusline commands through bash on all platforms. On native Windows, use `python` directly with a bash-resolvable path:

**Install the script:**

```powershell
mkdir "$env:USERPROFILE\.claude\claude-code-hud" -Force
curl -fsSL https://raw.githubusercontent.com/SRHSoulja/claude-code-hud/master/claude-code-hud -o "$env:USERPROFILE\.claude\claude-code-hud\claude-code-hud"
```

**Add to `~/.claude/settings.json`:**

```json
{
  "statusLine": {
    "type": "command",
    "command": "python ~/.claude/claude-code-hud/claude-code-hud",
    "refreshInterval": 60
  }
}
```

Requires Python on PATH.

## Compatibility

- **Linux / macOS:** Works as shown in Quick install (verified on Linux; macOS expected to work the same).
- **WSL:** Same macOS/Linux instructions work if Claude Code runs inside WSL.
- **Native Windows:** Works. Requires Python on PATH and bash-style command (see Windows setup above).
- Python 3.6+ (no external dependencies).
- Claude Code v2.1+ (statusline support).

## License

MIT
