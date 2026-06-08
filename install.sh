#!/usr/bin/env bash
# install.sh — One-click installer for claude-code-warmer on macOS.
#
# What it does:
#   1. Copies claude-keep-alive.sh to ~/.local/bin/
#   2. Generates a launchd .plist (interval: 14400 s = 4 h)
#   3. Loads the agent via launchctl so it starts immediately

set -euo pipefail

# ── Logging helpers ────────────────────────────────────────────────────────────
ts()  { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*"; }
err() { echo "[$(ts)] ERROR: $*" >&2; }
die() { err "$*"; exit 1; }

# ── Platform guard ─────────────────────────────────────────────────────────────
[[ "$(uname -s)" == "Darwin" ]] || die "This installer only supports macOS."

# ── Paths ──────────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_SCRIPT="$SCRIPT_DIR/claude-keep-alive.sh"

BIN_DIR="$HOME/.local/bin"
DEST_SCRIPT="$BIN_DIR/claude-keep-alive.sh"

PLIST_LABEL="com.user.claude.keepalive"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$LAUNCH_AGENTS_DIR/${PLIST_LABEL}.plist"

LOG_DIR="$HOME/Library/Logs/claude-code-warmer"
STDOUT_LOG="$LOG_DIR/stdout.log"
STDERR_LOG="$LOG_DIR/stderr.log"

INTERVAL=14400   # 4 hours in seconds

# ── Preflight checks ───────────────────────────────────────────────────────────
[[ -f "$SRC_SCRIPT" ]] || die "Source script not found: $SRC_SCRIPT"

# ── Step 1: Install the keep-alive script ─────────────────────────────────────
log "Creating bin directory: $BIN_DIR"
mkdir -p "$BIN_DIR"

log "Installing keep-alive script to: $DEST_SCRIPT"
cp "$SRC_SCRIPT" "$DEST_SCRIPT"
chmod 755 "$DEST_SCRIPT"

# ── Step 2: Create log directory ──────────────────────────────────────────────
log "Creating log directory: $LOG_DIR"
mkdir -p "$LOG_DIR"

# ── Step 3: Create LaunchAgents directory if missing ──────────────────────────
mkdir -p "$LAUNCH_AGENTS_DIR"

# ── Step 4: Unload any previously loaded version ──────────────────────────────
if launchctl list | grep -q "$PLIST_LABEL" 2>/dev/null; then
    log "Unloading existing launchd job: $PLIST_LABEL"
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# ── Step 5: Generate the .plist ───────────────────────────────────────────────
log "Generating plist: $PLIST_PATH"
cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
    "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${DEST_SCRIPT}</string>
    </array>

    <!-- Run every ${INTERVAL} seconds ($(( INTERVAL / 3600 )) hours) -->
    <key>StartInterval</key>
    <integer>${INTERVAL}</integer>

    <!-- Also run once shortly after the agent is loaded -->
    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${STDOUT_LOG}</string>

    <key>StandardErrorPath</key>
    <string>${STDERR_LOG}</string>

    <!-- Restart automatically if the script exits non-zero -->
    <key>KeepAlive</key>
    <dict>
        <key>SuccessfulExit</key>
        <false/>
    </dict>

    <key>ThrottleInterval</key>
    <integer>300</integer>
</dict>
</plist>
PLIST

chmod 644 "$PLIST_PATH"

# ── Step 6: Load the launchd agent ────────────────────────────────────────────
log "Loading launchd agent..."
if launchctl load "$PLIST_PATH"; then
    log "Agent loaded successfully."
else
    die "launchctl load failed. Check $PLIST_PATH for errors."
fi

# ── Done ───────────────────────────────────────────────────────────────────────
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
log "Installation complete!"
log ""
log "  Script   : $DEST_SCRIPT"
log "  Plist    : $PLIST_PATH"
log "  Interval : every $(( INTERVAL / 3600 )) hours"
log "  Stdout   : $STDOUT_LOG"
log "  Stderr   : $STDERR_LOG"
log ""
log "Useful commands:"
log "  Check status : launchctl list | grep $PLIST_LABEL"
log "  View logs    : tail -f $STDOUT_LOG"
log "  Uninstall    : launchctl unload $PLIST_PATH && rm $PLIST_PATH"
log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
