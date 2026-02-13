#!/bin/bash
# Claude Code token usage for zellij status bar
# Shows input/output tokens and cost

CACHE_FILE="/tmp/zellij_claude_tokens_cache"
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
DATA=$(bunx ccusage -j 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$DATA" ]; then
    echo "—"
    exit 0
fi

TODAY=$(date +%Y-%m-%d)

RESULT=$(python3 -c "
import json, sys
data = json.loads(sys.stdin.read())
today = '$TODAY'
def fmt(n):
    if n >= 1000000:
        return f'{n/1000000:.1f}M'
    elif n >= 1000:
        return f'{n/1000:.0f}K'
    return str(n)

for day in data.get('daily', []):
    if day.get('date') == today:
        inp = day.get('inputTokens', 0) + day.get('cacheCreationTokens', 0) + day.get('cacheReadTokens', 0)
        out = day.get('outputTokens', 0)
        cost = day.get('totalCost', 0)
        print(f'{fmt(inp)}in {fmt(out)}out \${cost:.2f}')
        sys.exit(0)
print('0')
" <<< "$DATA")

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
