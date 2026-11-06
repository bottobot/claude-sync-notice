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

## The sync script

`scripts/sync-vscode-claude.ps1` (Windows, PowerShell) is the script that writes the log. It copies `~/.local/bin/claude.exe` over each installed Claude Code extension's bundled `claude.exe` when the PATH copy is newer. A running exe can't be overwritten, so it renames the old one first. It checks the copied file's version and puts the original back if something fails.

Set it up:

1. Keep it anywhere (for example, run it straight from a clone of this repo). It always writes its log to `~/.claude/scripts/sync-vscode-claude.log`, which is where the extension reads it.
2. Run it hourly and at logon, for example with a scheduled task:

```
$a = New-ScheduledTaskAction -Execute pwsh.exe -Argument "-NoProfile -File `"<path to clone>\scripts\sync-vscode-claude.ps1`""
$t = @(New-ScheduledTaskTrigger -AtLogOn; New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionInterval (New-TimeSpan -Hours 1))
Register-ScheduledTask -TaskName "Claude VS Code binary sync" -Action $a -Trigger $t
```

To undo, reinstall or update the Claude Code extension (it brings its own binary).
## Install

```
npx @vscode/vsce package
code --install-extension claude-sync-notice-1.1.0.vsix
```

Or download the `.vsix` from the latest release.

## License

MIT
