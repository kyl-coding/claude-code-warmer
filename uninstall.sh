#!/usr/bin/env bash
# uninstall.sh — Remove claude-code-warmer from macOS.

set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; RESET='\033[0m'
else
    GREEN=''; YELLOW=''; RED=''; BOLD=''; RESET=''
fi

ok()  { echo -e "${GREEN}✓${RESET} $*"; }
warn(){ echo -e "${YELLOW}⚠${RESET}  $*"; }
err() { echo -e "${RED}✗${RESET} $*" >&2; }

PLIST_LABEL="com.user.claude.keepalive"
PLIST_PATH="$HOME/Library/LaunchAgents/${PLIST_LABEL}.plist"
DEST_SCRIPT="$HOME/.local/bin/claude-keep-alive.sh"
LOG_DIR="$HOME/Library/Logs/claude-code-warmer"

echo ""
echo -e "${BOLD}Uninstalling claude-code-warmer...${RESET}"
echo ""

# Unload launchd agent
if launchctl list | grep -q "$PLIST_LABEL" 2>/dev/null; then
    launchctl unload "$PLIST_PATH" 2>/dev/null && ok "Agent unloaded." || err "Failed to unload agent."
else
    warn "Agent was not running."
fi

# Remove plist
if [[ -f "$PLIST_PATH" ]]; then
    rm "$PLIST_PATH" && ok "Removed $PLIST_PATH"
else
    warn "Plist not found: $PLIST_PATH"
fi

# Remove script
if [[ -f "$DEST_SCRIPT" ]]; then
    rm "$DEST_SCRIPT" && ok "Removed $DEST_SCRIPT"
else
    warn "Script not found: $DEST_SCRIPT"
fi

# Offer to remove logs
if [[ -d "$LOG_DIR" ]]; then
    echo ""
    read -r -p "Remove logs at $LOG_DIR? [y/N] " answer
    if [[ "${answer,,}" == "y" ]]; then
        rm -rf "$LOG_DIR" && ok "Removed $LOG_DIR"
    else
        warn "Logs kept at $LOG_DIR"
    fi
fi

echo ""
echo -e "${GREEN}${BOLD}Done. claude-code-warmer has been removed.${RESET}"
echo ""
