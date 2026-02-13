#!/bin/bash
# Claude Code daily token usage for zellij status bar
# Shows input/cache/output tokens with model breakdown

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
DATA=$(bunx better-ccusage daily --json --breakdown 2>/dev/null)

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
        inp = day.get('inputTokens', 0) + day.get('cacheCreationTokens', 0)
        cache = day.get('cacheReadTokens', 0)
        out = day.get('outputTokens', 0)
        cost = day.get('totalCost', 0)

        # Extract model breakdown (top 2 models by cost)
        models = []
        for m in sorted(day.get('modelBreakdowns', []), key=lambda x: x.get('cost', 0), reverse=True)[:2]:
            name = m['modelName'].split('-')[1][0].upper()  # 'opus' -> 'O', 'sonnet' -> 'S'
            mcost = m.get('cost', 0)
            models.append(f'{name}:\${mcost:.2f}')

        model_str = f' ({\" \".join(models)})' if models else ''
        print(f' {fmt(inp)}  {fmt(cache)}  {fmt(out)}  ${cost:.2f}{model_str}')
        sys.exit(0)
print('—')
" <<< "$DATA")

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
