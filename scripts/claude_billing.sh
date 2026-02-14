#!/bin/bash
# Claude Code billing block progress for zellij status bar
# Shows cost and time remaining in current 5-hour billing block

CACHE_FILE="/tmp/zellij_claude_billing_cache"
CACHE_MAX_AGE=300  # 5 minutes

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
DATA=$(timeout 10s better-ccusage blocks --json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DATA" ]; then
    echo "" > "$CACHE_FILE"
    exit 0
fi

RESULT=$(python3 -c "
import json, sys
from datetime import datetime

try:
    data = json.loads(sys.stdin.read())
    blocks = data.get('blocks', [])

    if blocks:
        current = blocks[-1]  # Most recent block
        cost = current.get('totalCost', 0)
        end_time_str = current.get('endTime')

        if end_time_str:
            end_time = datetime.fromisoformat(end_time_str.replace('Z', '+00:00'))
            time_left = end_time - datetime.now(end_time.tzinfo)

            if time_left.total_seconds() > 0:
                hours = int(time_left.total_seconds() // 3600)
                mins = int((time_left.total_seconds() % 3600) // 60)
                print(f'\uf017 \${cost:.2f} ({hours}h{mins}m left)')
            else:
                print(f'\uf017 \${cost:.2f} (new block)')
        else:
            print(f'\uf017 \${cost:.2f}')
except Exception:
    pass
" <<< "$DATA")

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
