# claude-statusline

Aurora-gradient statusline for [Claude Code](https://claude.com/claude-code) with an effort-level badge.

- Single line, single bash script.
- Per-character truecolor gradient on the main info row (pink → purple → cyan → mint).
- Trailing effort badge: `LOW` · `MID` · `HIGH` · `X-HIGH` · `MAX` · `✦ ULTRA ✦`.
- Ultracode is detected from the transcript (since the JSON reports it as `xhigh`).

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/liberty-app-xiaolong-fan/claude-statusline/main/install.sh | bash
```

Or from a local clone:

```bash
git clone https://github.com/liberty-app-xiaolong-fan/claude-statusline.git
cd claude-statusline
./install.sh
```

The installer:

1. Backs up `~/.claude/statusline.sh` and `~/.claude/settings.json` if they exist.
2. Copies `statusline.sh` to `~/.claude/statusline.sh` and `chmod +x` it.
3. Sets `.statusLine` in `~/.claude/settings.json` to point at it.

Restart Claude Code (or start a new session) to see the new statusline.

## Requirements

`bash`, `jq`, `python3`, `perl`, `curl`. All ship by default on macOS and most Linux distros.

## Effort badge rendering

| Level     | Label       | Style                                                                 |
|-----------|-------------|-----------------------------------------------------------------------|
| low       | `LOW`       | solid `#94A3B8`                                                       |
| medium    | `MID`       | solid `#38BDF8`                                                       |
| high      | `HIGH`      | `#A78BFA` + bold                                                      |
| xhigh     | ` X-HIGH `  | inverse badge, bg `#E879F9` fg white, bold                            |
| max       | ` MAX `     | inverse badge, bg `#EF4444` fg white, bold                            |
| ultracode | ` ✦ ULTRA ✦ ` | 11-char gradient `#60A5FA → #A78BFA → #E879F9 → #F472B6`, white, bold |

Ultracode shares `xhigh` in the JSON payload, so the script tail-greps the transcript jsonl for the most recent `Set effort level to <level>` and prefers that.

## Uninstall

```bash
./uninstall.sh
```

Removes `~/.claude/statusline.sh` and unsets `.statusLine` in `settings.json`. Backups stay.

## Customizing

The installer respects:

- `CLAUDE_DIR` — defaults to `~/.claude`.
- `CLAUDE_STATUSLINE_REPO` — defaults to `liberty-app-xiaolong-fan/claude-statusline`.
- `CLAUDE_STATUSLINE_BRANCH` — defaults to `main`.

If you fork the repo, point the curl install at your fork:

```bash
CLAUDE_STATUSLINE_REPO=your-name/claude-statusline \
  curl -fsSL https://raw.githubusercontent.com/your-name/claude-statusline/main/install.sh | bash
```

## License

MIT.
