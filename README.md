# claude-tallow

A status line for [Claude Code](https://claude.ai/code) that displays model, context usage, cache hit rate, session cost, working directory, and git branch.

```
Sonnet 4.6 | [████░░░░░░] 38% | 42.1k/200k
~/Documents/code/my-project (main)
Cache: 76% | $0.18
```

At high context usage:

```
Opus 4.6 | [████████░░] 75% | 149.8k/200k
~/Documents/code/my-project (feature/auth)
Cache: 84% | $1.43
⚠ Context 75% full — consider summarizing and starting a new session.
```

## Features

- **Model name** — shows the active model (Opus, Sonnet, Haiku)
- **Context usage** — gradient progress bar with percentage and exact token count
- **Working directory** — current session path, shortened with `~`
- **Git branch** — shows branch name when inside a git repo
- **Cache hit rate** — color-coded prompt cache efficiency (green ≥80%, yellow ≥30%, red <30%)
- **Session cost** — color-coded actual cost from the API (green <$3, yellow <$5, red ≥$5)
- **Context warnings** — reminder at 70%, urgent at 90%

## Install

```bash
brew tap Devejya/tallow
brew install claude-tallow
claude-tallow install
```

Or in one command:

```bash
brew install Devejya/tallow/claude-tallow && claude-tallow install
```

Open a new Claude Code session to see the status line.

## Commands

| Command | Description |
|---|---|
| `claude-tallow install` | Install and configure the status line |
| `claude-tallow uninstall` | Remove the status line |
| `claude-tallow update` | Update the script to the latest version |
| `claude-tallow status` | Show installation status |
| `claude-tallow help` | Show help |

## Requirements

- macOS or Linux
- [Claude Code](https://claude.ai/code)
- [jq](https://jqlang.github.io/jq/) (installed automatically by Homebrew)

## How it works

`claude-tallow install` does two things:

1. Copies a status line script to `~/.claude/statusline-command.sh`
2. Adds a `statusLine` entry to `~/.claude/settings.json` (merges safely with existing settings)

Claude Code pipes JSON with session data (model, tokens, cache, cost, cwd) to the script on each refresh. Token count is computed as the exact sum of `input + cache_creation + cache_read + output` tokens from `current_usage`, giving a more accurate count than back-calculating from the context percentage.

## Uninstall

```bash
claude-tallow uninstall
brew uninstall claude-tallow
brew untap Devejya/tallow
```

## License

MIT
