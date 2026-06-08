# claude-session-saver

<!-- keywords: claude code session expired, claude code 5 hour limit, claude pro plan quota reset, claude max plan quota reset, claude max 5x quota, claude max 20x quota, keep claude code alive, prevent claude session timeout, claude code background agent, launchd claude, claude code mac automation -->

[![Platform](https://img.shields.io/badge/platform-macOS-lightgrey?logo=apple)](https://www.apple.com/macos/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-green?logo=gnubash)](claude-keep-alive.sh)
[![launchd](https://img.shields.io/badge/scheduler-launchd-orange)](https://developer.apple.com/library/archive/documentation/MacOSX/Conceptual/BPSystemStartup/Chapters/CreatingLaunchdJobs.html)

**Never lose your Claude Code session again.** Sends a lightweight ping every 4 hours to prevent the 5-hour usage window from expiring — automatically, in the background, with zero configuration after install.

## Why?

Claude Code resets its usage quota on a rolling 5-hour window — this affects all paid plans: Pro, Max, Max 5x, and Max 20x. If no activity occurs within that window, the session expires and you lose whatever quota remained. This is especially painful mid-task or overnight.

`claude-session-saver` prevents that by pinging Claude every 4 hours via a macOS `launchd` agent. Set it and forget it.

## How it works

A `launchd` agent runs the following command every 4 hours:

```
claude --print --model haiku -p "hi"
```

Haiku is the fastest and cheapest Claude model — each ping costs a fraction of a cent and completes in under 3 seconds. The `haiku` alias always resolves to the latest Haiku version, so no version suffix is needed.

## Requirements

- macOS
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

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

**Does this cost anything?**
Each ping uses the Haiku model (`claude --model haiku`), which is Anthropic's cheapest tier. Estimated cost: ~$0.001 per ping, ~$0.18/month.

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
