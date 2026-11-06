# Claude sync notice

A tiny VS Code extension that tells you when to reload a window after the Claude Code binary was updated underneath it.

## Why

A separate script (`sync-vscode-claude.ps1`, run hourly by a scheduled task) copies the auto-updated `~/.local/bin/claude.exe` over the binary bundled in the Claude Code VS Code extension. Windows that were already open keep running the old binary until they reload. This extension notices and offers **Reload Window**.

## How it decides

1. When a window starts, it reads the newest version in the sync log. That is the version the window just loaded: its **baseline**.
2. Every 60 seconds it checks the log again. If the newest version is **newer than the baseline**, it shows the notice once.
3. After a reload the baseline is the new version, so the notice does not come back.

No clocks or timestamps are compared.

## Log contract

The extension reads `~/.claude/scripts/sync-vscode-claude.log`. Each line starts with an ISO timestamp, and the version is taken from either form:

```
2026-11-06T04:00:06 ok: <path>\claude.exe is 2.1.318 (PATH 2.1.318)
2026-11-06T05:00:08 UPDATED: <path>\claude.exe 2.1.318 -> 2.1.319
```

No log at startup means no baseline, and the extension stays silent.

## Install

```
npx @vscode/vsce package
code --install-extension claude-sync-notice-1.1.0.vsix
```

Or download the `.vsix` from the latest release.

## License

MIT
