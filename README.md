# claude-code-warmer

Keeps your Claude Code session alive by sending a lightweight ping every 4 hours, preventing the 5-hour usage window from expiring.

## How it works

A `launchd` agent runs `claude --print --model claude-haiku-4-5-20251001 -p "hi"` every 4 hours in the background. The Haiku model is used to minimize token cost.

## Requirements

- macOS
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated

## Install

```bash
git clone https://github.com/fortuneli/claude-code-warmer.git
cd claude-code-warmer
./install.sh
```

The installer will:

1. Copy `claude-keep-alive.sh` to `~/.local/bin/`
2. Generate a `launchd` plist at `~/Library/LaunchAgents/com.user.claude.keepalive.plist`
3. Load the agent immediately (first ping fires right away via `RunAtLoad`)

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
launchctl unload ~/Library/LaunchAgents/com.user.claude.keepalive.plist
rm ~/Library/LaunchAgents/com.user.claude.keepalive.plist
```

## File layout

```
claude-code-warmer/
├── claude-keep-alive.sh   # Keep-alive script (called by launchd)
├── install.sh             # One-click macOS installer
└── README.md
```

## License

MIT
