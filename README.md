# claude-code-warmer

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green?logo=gnubash)](claude-keep-alive.sh)
[![launchd](https://img.shields.io/badge/scheduler-launchd-orange)](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

Keeps your Claude Code session alive by sending a lightweight ping every 4 hours, preventing the 5-hour usage window from expiring.

## Why?

Claude Code's Max subscription resets available usage on a rolling 5-hour window. If no activity occurs within that window, the session expires and you lose any remaining quota. This tool pings Claude every 4 hours in the background so the window never closes on you.

## How it works

A `launchd` agent runs the following command every 4 hours:

```
claude --print --model claude-haiku-4-5-20251001 -p "hi"
```

Haiku is the fastest and cheapest Claude model — each ping costs a fraction of a cent and completes in under 3 seconds.

## Requirements

- macOS
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Install

```bash
git clone https://github.com/kyl-coding/claude-code-warmer.git
cd claude-code-warmer
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
  claude-code-warmer installed successfully!
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Interval  every 4 hours
  Script    /Users/you/.local/bin/claude-keep-alive.sh
  Logs      /Users/you/Library/Logs/claude-code-warmer/
```

## Logs

```bash
# Live stdout
tail -f ~/Library/Logs/claude-code-warmer/stdout.log

# Live stderr
tail -f ~/Library/Logs/claude-code-warmer/stderr.log
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
claude-code-warmer/
├── claude-keep-alive.sh   # Keep-alive script (called by launchd)
├── install.sh             # One-click macOS installer
├── uninstall.sh           # Cleaner removal
├── LICENSE
└── README.md
```

## License

MIT
