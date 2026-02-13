#!/bin/bash
# Claude Code current session token usage for zellij status bar
# Shows tokens and cost for ONLY the current session

CACHE_FILE="/tmp/zellij_claude_session_tokens_cache"
CACHE_MAX_AGE=300  # 5 minutes

# Only show when in Claude Code session
if [ "$CLAUDECODE" != "1" ]; then
    exit 0
fi

# Check if cache is fresh enough
if [ -f "$CACHE_FILE" ]; then
    cache_age=$(( $(date +%s) - $(stat -f %m "$CACHE_FILE") ))
    if [ "$cache_age" -lt "$CACHE_MAX_AGE" ]; then
        cat "$CACHE_FILE"
        exit 0
    fi
fi

# Fetch fresh data
export PATH="/opt/homebrew/bin:/usr/local/bin:$HOME/.bun/bin:$PATH"
DATA=$(bunx better-ccusage session --json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DATA" ]; then
    echo "" > "$CACHE_FILE"
    exit 0
fi

RESULT=$(python3 -c "
import json, sys

try:
    data = json.loads(sys.stdin.read())

    def fmt(n):
        if n >= 1000000:
            return f'{n/1000000:.1f}M'
        elif n >= 1000:
            return f'{n/1000:.0f}K'
        return str(n)

    # Get current session data (most recent)
    sessions = data.get('sessions', [])
    if sessions:
        current = sessions[0]  # Most recent session
        inp = current.get('inputTokens', 0) + current.get('cacheCreationTokens', 0)
        cache = current.get('cacheReadTokens', 0)
        out = current.get('outputTokens', 0)
        cost = current.get('totalCost', 0)
        print(f'📊 {fmt(inp)} {fmt(cache)} {fmt(out)} \${cost:.2f} │')
except Exception:
    pass
" <<< "$DATA")

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
