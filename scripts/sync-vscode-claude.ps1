# Copies the auto-updated PATH Claude (~\.local\bin\claude.exe) over the Claude binary bundled in each
# installed Claude Code VS Code extension, when the PATH copy is newer. Run hourly + at logon by the
# scheduled task "Claude VS Code binary sync". Log: ~\.claude\scripts\sync-vscode-claude.log
# Undo: reinstall/update the extension (it brings its own binary), or rename claude.exe.replaced-* back.
$ErrorActionPreference = 'Stop'
# Fixed location: the claude-sync-notice extension reads it here, wherever this script lives.
$log = Join-Path $env:USERPROFILE '.claude\scripts\sync-vscode-claude.log'
function Log($msg) { $line = "$(Get-Date -Format s) $msg"; Add-Content $log $line; Write-Host $line }

function Get-ClaudeVersion($exe) {
  # "2.1.292 (Claude Code)" -> [version]2.1.292; $null when it cannot be read (unknown, never "older").
  try { $out = & $exe --version 2>$null | Select-Object -First 1 } catch { return $null }
  if ($out -match '^(\d+\.\d+\.\d+)') { return [version]$Matches[1] }
  return $null
}

$src = Join-Path $env:USERPROFILE '.local\bin\claude.exe'
$srcVer = Get-ClaudeVersion $src
if (-not $srcVer) { Log "UNKNOWN: cannot read version of $src; nothing changed"; exit 1 }

$targets = @(Get-ChildItem (Join-Path $env:USERPROFILE '.vscode\extensions') -Directory -Filter 'anthropic.claude-code-*' -ErrorAction SilentlyContinue |
  ForEach-Object { Join-Path $_.FullName 'resources\native-binary\claude.exe' } | Where-Object { Test-Path $_ })
if ($targets.Count -eq 0) { Log "UNKNOWN: no extension binary found under ~\.vscode\extensions; nothing changed"; exit 1 }

$failed = 0
foreach ($dst in $targets) {
  $dir = Split-Path $dst
  # Old copies renamed on earlier runs are deletable once no session runs them.
  Get-ChildItem $dir -Filter 'claude.exe.replaced-*' -ErrorAction SilentlyContinue |
    ForEach-Object { try { Remove-Item $_.FullName -Force } catch {} }

  $dstVer = Get-ClaudeVersion $dst
  if (-not $dstVer) { Log "UNKNOWN: cannot read version of $dst; skipped"; $failed++; continue }
  if ($dstVer -ge $srcVer) { Log "ok: $dst is $dstVer (PATH $srcVer)"; continue }

  # A running exe cannot be overwritten but can be renamed; running sessions keep the old file.
  $old = "$dst.replaced-$dstVer-$(Get-Date -Format yyyyMMddHHmmss)"
  try {
    Rename-Item $dst (Split-Path $old -Leaf)
    Copy-Item $src $dst
    $newVer = Get-ClaudeVersion $dst
    if ($newVer -ne $srcVer) { throw "copied file reports '$newVer', expected $srcVer" }
    Log "UPDATED: $dst $dstVer -> $newVer"
  } catch {
    Log "FAILED: $dst ($_)"; $failed++
    if (Test-Path $old) {
      try { if (Test-Path $dst) { Remove-Item $dst -Force }; Rename-Item $old (Split-Path $dst -Leaf); Log "restored original $dst" }
      catch { Log "RESTORE FAILED: original is at $old ($_)" }
    }
  }
}
exit $failed
