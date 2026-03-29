#!/usr/bin/env bats
# Tests for share/statusline-command.sh
# Install bats-core: brew install bats-core
# Run: bats test/statusline.bats

SCRIPT="$BATS_TEST_DIRNAME/../share/statusline-command.sh"

# Strip ANSI color codes from captured bats output
plain() {
  echo "$output" | sed 's/\x1b\[[0-9;]*m//g'
}

# ── Exit codes ────────────────────────────────────────────────────────────────

@test "exits 0 with full data" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Sonnet"},"context_window":{"used_percentage":10,"context_window_size":200000,"current_usage":{"cache_read_input_tokens":5000,"cache_creation_input_tokens":1000,"input_tokens":1000,"output_tokens":500}},"cost":{"total_cost_usd":0.05}}'
  [ "$status" -eq 0 ]
}

@test "exits 0 with empty JSON object" {
  run bash "$SCRIPT" <<< '{}'
  [ "$status" -eq 0 ]
}

@test "exits 0 with missing context window" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Sonnet"}}'
  [ "$status" -eq 0 ]
}

# ── Model name ────────────────────────────────────────────────────────────────

@test "shows model display name" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"Claude Sonnet 4.6"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"Claude Sonnet 4.6"* ]]
}

@test "falls back to 'Claude' when model name missing" {
  run bash "$SCRIPT" <<< '{"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"Claude"* ]]
}

# ── Context bar ───────────────────────────────────────────────────────────────

@test "shows percentage label" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":45,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"45%"* ]]
}

@test "shows /200k tokens label by default" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"/200k tokens"* ]]
}

@test "shows dynamic context window size" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"context_window_size":128000,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"/128k tokens"* ]]
}

@test "shows empty bar when context window missing" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"}}'
  [[ "$(plain)" == *"[░░░░░░░░░░░░░░░░░░░░]"* ]]
}

# ── Token formatting (Method 2: current_usage sum) ───────────────────────────

@test "computes tokens from current_usage fields" {
  # input=1000 + cache_creation=2000 + cache_read=5000 + output=500 = 8500 = 8.5k
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":4,"current_usage":{"cache_read_input_tokens":5000,"cache_creation_input_tokens":2000,"input_tokens":1000,"output_tokens":500}}}'
  [[ "$(plain)" == *"8.5k/200k tokens"* ]]
}

@test "includes output tokens in count" {
  # input=100 + cache_creation=0 + cache_read=0 + output=700 = 800
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":1,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":700}}}'
  [[ "$(plain)" == *"800/200k tokens"* ]]
}

@test "formats whole-number thousands with k (42k)" {
  # 40000 + 1000 + 500 + 500 = 42000 = 42k
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":21,"current_usage":{"cache_read_input_tokens":40000,"cache_creation_input_tokens":1000,"input_tokens":500,"output_tokens":500}}}'
  [[ "$(plain)" == *"42k/200k tokens"* ]]
}

@test "formats fractional thousands with one decimal (1.5k)" {
  # 1000 + 200 + 100 + 200 = 1500 = 1.5k
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":1,"current_usage":{"cache_read_input_tokens":1000,"cache_creation_input_tokens":200,"input_tokens":100,"output_tokens":200}}}'
  [[ "$(plain)" == *"1.5k/200k tokens"* ]]
}

@test "formats tokens under 1000 without k suffix" {
  # 300 + 200 + 100 + 200 = 800
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":1,"current_usage":{"cache_read_input_tokens":300,"cache_creation_input_tokens":200,"input_tokens":100,"output_tokens":200}}}'
  [[ "$(plain)" == *"800/200k tokens"* ]]
}

@test "defaults output_tokens to 0 when missing" {
  # input=500 + cache_creation=300 + cache_read=200 + output=0 = 1000 = 1k
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":1,"current_usage":{"cache_read_input_tokens":200,"cache_creation_input_tokens":300,"input_tokens":500}}}'
  [[ "$(plain)" == *"1k/200k tokens"* ]]
}

# ── Cache hit rate ────────────────────────────────────────────────────────────

@test "shows cache hit rate when tokens present" {
  # cache_read=8000, cache_creation=1000, input=1000 → total=10000 → 80%
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":8000,"cache_creation_input_tokens":1000,"input_tokens":1000,"output_tokens":0}}}'
  [[ "$(plain)" == *"Cache: 80%"* ]]
}

@test "omits cache line when all token counts are zero" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":0,"output_tokens":0}}}'
  [[ "$(plain)" != *"Cache:"* ]]
}

@test "cache 0% when no cache reads (only input tokens)" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":5000,"output_tokens":0}}}'
  [[ "$(plain)" == *"Cache: 0%"* ]]
}

# ── Cost ──────────────────────────────────────────────────────────────────────

@test "shows cost formatted to 2 decimal places" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}},"cost":{"total_cost_usd":1.2}}'
  [[ "$(plain)" == *'$1.20'* ]]
}

@test "omits cost when field missing" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":10,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" != *'$'* ]]
}

# ── Warning tiers ─────────────────────────────────────────────────────────────

@test "no warning below 70%" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":65,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" != *"consider summarizing"* ]]
  [[ "$(plain)" != *"start a new session"* ]]
}

@test "shows summarize warning at 70%" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":70,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"consider summarizing"* ]]
}

@test "shows summarize warning between 70-89%" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":80,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"consider summarizing"* ]]
}

@test "shows critical warning at 90%" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":90,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"start a new session now"* ]]
}

@test "shows critical warning above 90%" {
  run bash "$SCRIPT" <<< '{"model":{"display_name":"M"},"context_window":{"used_percentage":95,"current_usage":{"cache_read_input_tokens":0,"cache_creation_input_tokens":0,"input_tokens":100,"output_tokens":0}}}'
  [[ "$(plain)" == *"start a new session now"* ]]
}
