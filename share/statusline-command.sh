#!/usr/bin/env bash
# Claude Code status line script
# Format: Model | [████░░░░] X% | X/200k tokens | Cache: X% | $X.XX

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name // "Claude"')
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
context_window_size=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
session_cwd=$(echo "$input" | jq -r '.cwd // empty')

# Cache fields
cache_read=$(echo "$input" | jq -r '.context_window.current_usage.cache_read_input_tokens // 0')
cache_creation=$(echo "$input" | jq -r '.context_window.current_usage.cache_creation_input_tokens // 0')
input_tokens=$(echo "$input" | jq -r '.context_window.current_usage.input_tokens // 0')
output_tokens=$(echo "$input" | jq -r '.context_window.current_usage.output_tokens // 0')

# Cost
total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')

# ── Color codes (using $'...' for proper escape interpretation) ─────────────
RESET=$'\033[0m'
YELLOW=$'\033[33m'
RED=$'\033[31m'
BRIGHT_RED=$'\033[1;31m'
DIM=$'\033[2m'

# ── Determine color tier ─────────────────────────────────────────────────────
if [ -z "$used_pct" ]; then
  bar_color=""
  tier="none"
else
  pct_int=$(printf '%.0f' "$used_pct")
  if [ "$pct_int" -ge 90 ]; then
    bar_color="$BRIGHT_RED"
    tier="critical"
  elif [ "$pct_int" -ge 70 ]; then
    bar_color="$RED"
    tier="warning"
  elif [ "$pct_int" -ge 50 ]; then
    bar_color="$YELLOW"
    tier="caution"
  else
    bar_color=""
    tier="ok"
  fi
fi

# ── Cache hit rate ──────────────────────────────────────────────────────────
cache_total=$((cache_read + cache_creation + input_tokens))
if [ "$cache_total" -gt 0 ]; then
  cache_pct=$(awk "BEGIN {printf \"%.0f\", ($cache_read / $cache_total) * 100}")
  cache_part=" | Cache: ${cache_pct}%"
else
  cache_part=""
fi

# ── Cost ────────────────────────────────────────────────────────────────────
if [ -n "$total_cost" ]; then
  cost_part=" | \$$(printf '%.2f' "$total_cost")"
else
  cost_part=""
fi

# ── Build progress bar (width = 20 chars) ────────────────────────────────────
BAR_WIDTH=20
if [ -n "$used_pct" ]; then
  filled=$(echo "$used_pct $BAR_WIDTH" | awk '{printf "%d", ($1/100)*$2 + 0.5}')
  [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
  [ "$filled" -lt 0 ] && filled=0
  empty=$((BAR_WIDTH - filled))

  bar_filled=""
  for ((i=0; i<filled; i++)); do bar_filled+="█"; done
  bar_empty=""
  for ((i=0; i<empty; i++)); do bar_empty+="░"; done

  # Calculate used tokens from current_usage (Method 2: exact sum)
  used_tokens=$((input_tokens + cache_creation + cache_read + output_tokens))
  # Format token count (e.g., 42000 -> 42k, 1500 -> 1.5k, 200000 -> 200k)
  if [ "$used_tokens" -ge 1000 ]; then
    token_display=$(awk "BEGIN {v=$used_tokens/1000; if (v==int(v)) printf \"%dk\", v; else printf \"%.1fk\", v}")
  else
    token_display="${used_tokens}"
  fi

  # Format context window size for display (e.g., 200000 -> 200k)
  if [ "$context_window_size" -ge 1000 ]; then
    window_display=$(awk "BEGIN {v=$context_window_size/1000; if (v==int(v)) printf \"%dk\", v; else printf \"%.1fk\", v}")
  else
    window_display="${context_window_size}"
  fi

  pct_label=$(printf '%.0f%%' "$used_pct")

  # Line 1: Model | [bar] X% | X/200k tokens
  printf "${bar_color}%s${RESET} | ${bar_color}[%s${DIM}%s${RESET}${bar_color}]${RESET} ${bar_color}%s${RESET} | ${bar_color}%s/%s tokens${RESET}\n" \
    "$model" "$bar_filled" "$bar_empty" "$pct_label" "$token_display" "$window_display"
else
  # Format context window size for empty state too
  if [ "$context_window_size" -ge 1000 ]; then
    window_display=$(awk "BEGIN {v=$context_window_size/1000; if (v==int(v)) printf \"%dk\", v; else printf \"%.1fk\", v}")
  else
    window_display="${context_window_size}"
  fi
  printf "%s | ${DIM}[░░░░░░░░░░░░░░░░░░░░] 0%% | 0/%s tokens${RESET}\n" "$model" "$window_display"
fi

# ── Line 2: Cache + Cost ───────────────────────────────────────────────────
if [ -n "$cache_part" ] || [ -n "$cost_part" ]; then
  # Strip leading " | " from first part
  line2="${cache_part# | }${cost_part}"
  printf "${DIM}%s${RESET}\n" "$line2"
fi

# ── Line 3: cwd + git branch ────────────────────────────────────────────────
if [ -n "$session_cwd" ]; then
  # Shorten home prefix to ~
  display_cwd="${session_cwd/#$HOME/~}"
  # Get git branch if cwd is a git repo
  git_branch=$(git -C "$session_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -n "$git_branch" ]; then
    printf "${DIM}%s [%s]${RESET}\n" "$display_cwd" "$git_branch"
  else
    printf "${DIM}%s${RESET}\n" "$display_cwd"
  fi
fi

# ── Line 4: warning (only when >= 70%) ──────────────────────────────────────
if [ "$tier" = "warning" ]; then
  printf "${RED}⚠ Context %d%% full — consider summarizing and starting a new session.${RESET}\n" "$pct_int"
elif [ "$tier" = "critical" ]; then
  printf "${BRIGHT_RED}⚠ Context %d%% full — start a new session now to avoid truncation.${RESET}\n" "$pct_int"
fi
