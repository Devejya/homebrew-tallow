# claude-tallow

A status line for [Claude Code](https://claude.ai/code) that displays model, context usage, cache hit rate, and session cost.

```
Opus 4.6 | [████████░░░░░░░░░░░░] 40% | 80k/200k tokens | Cache: 72% | $0.42
```

## Features

- **Model name** — shows the active model (Opus, Sonnet, Haiku)
- **Context usage** — progress bar with percentage and token count
- **Color-coded warnings** — yellow at 50%, red at 70%, bold red at 90%
- **Cache hit rate** — shows prompt cache efficiency
- **Session cost** — actual cost from the API
- **70% warning** — reminds you to start a new session before context runs out

## Install

```bash
brew tap Devejya/tallow
brew install claude-tallow
claude-tallow install
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

Claude Code pipes JSON with session data (model, tokens, cache, cost) to the script on each refresh. The script formats it into a single-line status bar below the input field.

## Uninstall

```bash
claude-tallow uninstall
brew uninstall claude-tallow
brew untap Devejya/tallow
```

## License

MIT
