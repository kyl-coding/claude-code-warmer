# claude-session-saver

<!-- keywords: claude code 5 hour window, claude code token limit, maximize claude subscription, claude pro max tokens per day, claude code quota reset, claude max 5x 20x token window, get more tokens claude code, claude code usage window hack, launchd claude mac -->

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green?logo=gnubash)](claude-keep-alive.sh)
[![launchd](https://img.shields.io/badge/scheduler-launchd-orange)](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

**Get the most out of your Claude Code subscription.** Automatically activates each new 5-hour token window the moment it opens — so you always have fresh tokens ready, without thinking about it.

## Why?

Claude Code (Pro, Max, Max 5x, Max 20x) allocates tokens in rolling **5-hour windows**. Once you exhaust a window, you wait for the next one to open before you get more tokens.

The catch: a new window only opens after 5 hours have passed **since your last usage**. If you're not actively using Claude, that clock isn't ticking — meaning you could be sitting idle between windows longer than necessary.

`claude-session-saver` pings Claude every 4 hours in the background, ensuring each new token window is activated as soon as it's available. More windows per day = more tokens = more value from your subscription.

```
Without claude-session-saver          With claude-session-saver
─────────────────────────────         ─────────────────────────────
 9:00  Use Claude (window opens)       9:00  Use Claude (window opens)
 9:45  Tokens exhausted                9:45  Tokens exhausted
       ... waiting ...                13:00  ✓ Auto-ping (new window opens)
15:00  Remember to check Claude        13:00  Fresh tokens available ✓
15:00  New window opens (finally)      17:00  ✓ Auto-ping (new window opens)
       5+ hours wasted                        Maximum windows used
```

## How it works

A `launchd` agent runs the following command every 4 hours:

```
claude --print --model haiku -p "hi"
```

Haiku is the fastest and cheapest Claude model — each ping completes in under 3 seconds. The `haiku` alias always resolves to the latest Haiku version automatically.

## Requirements

- macOS
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated (Pro, Max, Max 5x, or Max 20x plan)

## Install

```bash
git clone https://github.com/kyl-coding/claude-session-saver.git
cd claude-session-saver
./install.sh
```

The installer will:

1. Verify that `claude` is installed and reachable
2. Copy `claude-keep-alive.sh` to `~/.local/bin/`
3. Generate a `launchd` plist at `~/Library/LaunchAgents/com.user.claude.keepalive.plist`
4. Load the agent immediately (first ping fires right away via `RunAtLoad`)

**Example output:**

```
[2026-06-08 18:16:01] Checking for claude binary...
[2026-06-08 18:16:01] ✓ Found claude at: /usr/local/bin/claude
[2026-06-08 18:16:01] Installing keep-alive script...
[2026-06-08 18:16:01] ✓ Script installed to /Users/you/.local/bin/claude-keep-alive.sh
[2026-06-08 18:16:01] ✓ Plist written to ~/Library/LaunchAgents/com.user.claude.keepalive.plist
[2026-06-08 18:16:01] ✓ Agent loaded and running.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  claude-session-saver installed successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Interval  every 4 hours
  Script    /Users/you/.local/bin/claude-keep-alive.sh
  Logs      /Users/you/Library/Logs/claude-session-saver/
```

## Logs

```bash
# Live stdout
tail -f ~/Library/Logs/claude-session-saver/stdout.log

# Live stderr
tail -f ~/Library/Logs/claude-session-saver/stderr.log
```

## Status & management

```bash
# Check agent is running
launchctl list | grep com.user.claude.keepalive

# Uninstall
./uninstall.sh
```

## Uninstall

```bash
./uninstall.sh
```

The uninstaller stops the agent, removes the plist and script, and optionally deletes the logs.

## File layout

```
claude-session-saver/
├── claude-keep-alive.sh   # Keep-alive script (called by launchd)
├── install.sh             # One-click macOS installer
├── uninstall.sh           # Cleaner removal
├── LICENSE
└── README.md
```

## FAQ

**Does this cost extra money?**
No. The ping uses your existing Claude subscription. Each ping consumes a negligible amount of tokens (a single "hi" on Haiku).

**Will it work after my Mac sleeps?**
Yes. `launchd` reschedules missed jobs automatically when the Mac wakes up.

**Does it interfere with my active Claude Code sessions?**
No. The ping runs as a completely separate background process.

**How do I know it's working?**
```bash
tail -f ~/Library/Logs/claude-session-saver/stdout.log
```
You should see a `Keep-alive ping succeeded` line every 4 hours.

## License

MIT
