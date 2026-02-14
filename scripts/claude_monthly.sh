#!/bin/bash
# Claude Code monthly spend tracking for zellij status bar
# Shows current month's total spend

CACHE_FILE="/tmp/zellij_claude_monthly_cache"
CACHE_MAX_AGE=3600  # 1 hour (monthly changes slowly)

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
DATA=$(timeout 10s better-ccusage monthly --json 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DATA" ]; then
    echo "" > "$CACHE_FILE"
    exit 0
fi

RESULT=$(python3 -c "
import json, sys

try:
    data = json.loads(sys.stdin.read())
    months = data.get('monthly', [])

    if months:
        current = months[-1]  # Most recent month
        cost = current.get('totalCost', 0)
        print(f'\uf073 \${cost:.2f}/mo')
except Exception:
    pass
" <<< "$DATA")

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
