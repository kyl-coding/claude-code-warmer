#!/usr/bin/env bash
# claude-keep-alive.sh — Periodically invoke Claude Code to prevent 5-hour session expiry.

set -euo pipefail

# ── Logging helpers ────────────────────────────────────────────────────────────
ts()  { date '+%Y-%m-%d %H:%M:%S'; }
log() { echo "[$(ts)] $*"; }
err() { echo "[$(ts)] ERROR: $*" >&2; }

# ── Locate the claude binary ───────────────────────────────────────────────────
CLAUDE_BIN=""

if command -v claude >/dev/null 2>&1; then
    CLAUDE_BIN="$(command -v claude)"
fi

# Fallback: check common installation paths
if [[ -z "$CLAUDE_BIN" ]]; then
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
    err "claude binary not found. Make sure Claude Code is installed and available in PATH."
    err "Install via: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

log "Found claude at: $CLAUDE_BIN"

# ── Execute keep-alive ping ────────────────────────────────────────────────────
log "Sending keep-alive ping..."

if "$CLAUDE_BIN" --print --model claude-haiku-4-5-20251001 -p "hi" >/dev/null 2>&1; then
    log "Keep-alive ping succeeded."
    exit 0
else
    EXIT_CODE=$?
    err "Keep-alive ping failed (exit code: $EXIT_CODE)."
    exit "$EXIT_CODE"
fi
