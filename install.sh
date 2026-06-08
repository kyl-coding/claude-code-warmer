#!/usr/bin/env bash
# install.sh — One-click installer for claude-session-saver on macOS.
#
# What it does:
#   1. Verifies claude is installed
#   2. Copies claude-keep-alive.sh to ~/.local/bin/
#   3. Generates a launchd .plist (interval: 14400 s = 4 h)
#   4. Loads the agent via launchctl so it starts immediately

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; BOLD=''; RESET=''
fi

# ── Logging helpers ────────────────────────────────────────────────────────────
ts()   { date '+%Y-%m-%d %H:%M:%S'; }
log()  { echo -e "[$(ts)] $*"; }
ok()   { echo -e "[$(ts)] ${GREEN}✓${RESET} $*"; }
warn() { echo -e "[$(ts)] ${YELLOW}⚠${RESET}  $*"; }
err()  { echo -e "[$(ts)] ${RED}✗ ERROR:${RESET} $*" >&2; }
die()  { err "$*"; exit 1; }

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

LOG_DIR="$HOME/Library/Logs/claude-session-saver"
STDOUT_LOG="$LOG_DIR/stdout.log"
STDERR_LOG="$LOG_DIR/stderr.log"

INTERVAL=14400   # 4 hours in seconds

# ── Preflight checks ───────────────────────────────────────────────────────────
[[ -f "$SRC_SCRIPT" ]] || die "Source script not found: $SRC_SCRIPT"

log "Checking for claude binary..."
CLAUDE_BIN=""
if command -v claude >/dev/null 2>&1; then
    CLAUDE_BIN="$(command -v claude)"
else
    for candidate in \
        "$HOME/.local/bin/claude" \
        "$HOME/.npm-global/bin/claude" \
        "/usr/local/bin/claude" \
        "/opt/homebrew/bin/claude" \
        "/usr/bin/claude"
    do
        if [[ -x "$candidate" ]]; then
            CLAUDE_BIN="$candidate"
            break
        fi
    done
fi

if [[ -z "$CLAUDE_BIN" ]]; then
    die "claude binary not found. Install Claude Code first:\n       npm install -g @anthropic-ai/claude-code"
fi
ok "Found claude at: $CLAUDE_BIN"

# ── Step 1: Install the keep-alive script ─────────────────────────────────────
log "Installing keep-alive script..."
mkdir -p "$BIN_DIR" "$LAUNCH_AGENTS_DIR" "$LOG_DIR"
cp "$SRC_SCRIPT" "$DEST_SCRIPT"
chmod 755 "$DEST_SCRIPT"
ok "Script installed to $DEST_SCRIPT"

# ── Step 2: Unload any previously loaded version ──────────────────────────────
if launchctl list | grep -q "$PLIST_LABEL" 2>/dev/null; then
    warn "Existing agent found — reloading..."
    launchctl unload "$PLIST_PATH" 2>/dev/null || true
fi

# ── Step 3: Generate the .plist ───────────────────────────────────────────────
log "Generating launchd plist..."
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

    <key>StartInterval</key>
    <integer>${INTERVAL}</integer>

    <key>RunAtLoad</key>
    <true/>

    <key>StandardOutPath</key>
    <string>${STDOUT_LOG}</string>

    <key>StandardErrorPath</key>
    <string>${STDERR_LOG}</string>

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
ok "Plist written to $PLIST_PATH"

# ── Step 4: Load the launchd agent ────────────────────────────────────────────
log "Loading launchd agent..."
if launchctl load "$PLIST_PATH"; then
    ok "Agent loaded and running."
else
    die "launchctl load failed. Check $PLIST_PATH for errors."
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}${BOLD}  claude-session-saver installed successfully!${RESET}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo ""
echo -e "  ${BOLD}Interval${RESET}  every $(( INTERVAL / 3600 )) hours"
echo -e "  ${BOLD}Script${RESET}    $DEST_SCRIPT"
echo -e "  ${BOLD}Logs${RESET}      $LOG_DIR/"
echo ""
echo -e "  ${BOLD}Useful commands:${RESET}"
echo -e "  ${YELLOW}Check status${RESET}  launchctl list | grep $PLIST_LABEL"
echo -e "  ${YELLOW}View logs${RESET}     tail -f $STDOUT_LOG"
echo -e "  ${YELLOW}Uninstall${RESET}     ./uninstall.sh"
echo ""
