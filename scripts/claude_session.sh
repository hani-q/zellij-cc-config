#!/bin/bash
# Claude Code session info for zellij status bar
# Shows session slug and duration (e.g., "playful-stargazing-hare 2h34m")

CACHE_FILE="/tmp/zellij_claude_session_cache"
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

# Convert current directory to project folder format
# /Users/q/work/code/project → -Users-q-work-code-project
PROJECT_FOLDER=$(echo "$PWD" | sed 's/\//-/g')
PROJECTS_DIR="$HOME/.claude/projects"
PROJECT_DIR="$PROJECTS_DIR/$PROJECT_FOLDER"

# Find the most recent JSONL file in the project directory
if [ ! -d "$PROJECT_DIR" ]; then
    echo "" > "$CACHE_FILE"
    exit 0
fi

JSONL_FILE=$(ls -t "$PROJECT_DIR"/*.jsonl 2>/dev/null | head -n1)

if [ -z "$JSONL_FILE" ] || [ ! -f "$JSONL_FILE" ]; then
    echo "" > "$CACHE_FILE"
    exit 0
fi

# Extract slug and calculate duration using Python
RESULT=$(python3 -c "
import json, sys
from datetime import datetime

slug = None
start_time = None

try:
    with open('$JSONL_FILE', 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)

                # Extract slug from first occurrence
                if slug is None and 'slug' in msg:
                    slug = msg['slug']

                # Extract first timestamp
                if start_time is None and 'timestamp' in msg:
                    start_time = datetime.fromisoformat(msg['timestamp'].replace('Z', '+00:00'))

                # Exit early if we have both
                if slug and start_time:
                    break
            except (json.JSONDecodeError, ValueError):
                continue

    # If we don't have both slug and start time, exit
    if not slug or not start_time:
        sys.exit(0)

    # Calculate duration
    elapsed_seconds = (datetime.now(start_time.tzinfo) - start_time).total_seconds()

    # Format duration
    if elapsed_seconds < 3600:  # < 1 hour
        duration = f\"{int(elapsed_seconds // 60)}m\"
    elif elapsed_seconds < 86400:  # < 1 day
        hours = int(elapsed_seconds // 3600)
        mins = int((elapsed_seconds % 3600) // 60)
        duration = f\"{hours}h{mins}m\"
    else:  # >= 1 day
        days = int(elapsed_seconds // 86400)
        hours = int((elapsed_seconds % 86400) // 3600)
        duration = f\"{days}d{hours}h\"

    print(f\" {slug} {duration} │\")
except Exception:
    pass
" 2>/dev/null)

echo "$RESULT" > "$CACHE_FILE"
echo "$RESULT"
