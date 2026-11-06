// Shows a reload prompt when sync-vscode-claude.ps1 has installed a newer Claude than the one this
// window loaded. Baseline = newest version in the log when the window starts (that is the binary
// this window loaded). No clocks involved, so a reload always clears the notice.
const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const os = require('os');

const LOG = path.join(os.homedir(), '.claude', 'scripts', 'sync-vscode-claude.log');
// "ok: <path> is 2.1.318 (PATH ...)" or "UPDATED: <path> 2.1.318 -> 2.1.319"
const VERSION = /(?: is |-> )(\d+\.\d+\.\d+)/;

function newestVersion() {
  let text;
  try { text = fs.readFileSync(LOG, 'utf8'); } catch { return null; }
  const lines = text.split(/\r?\n/);
  for (let i = lines.length - 1; i >= 0; i--) {
    const m = VERSION.exec(lines[i]);
    if (m) return m[1];
  }
  return null;
}

function newer(a, b) {
  const pa = a.split('.').map(Number), pb = b.split('.').map(Number);
  for (let i = 0; i < 3; i++) if (pa[i] !== pb[i]) return pa[i] > pb[i];
  return false;
}

function activate(context) {
  const baseline = newestVersion();
  let shownFor = null;

  const check = () => {
    const current = newestVersion();
    if (!current || current === shownFor) return;
    if (baseline && !newer(current, baseline)) return;
    if (!baseline) return; // no log at startup: nothing to compare against
    shownFor = current;
    vscode.window.showWarningMessage(
      `Claude Code was updated to ${current}. Reload this window so its Claude chats use the new version.`,
      'Reload Window', 'Later'
    ).then((choice) => {
      if (choice === 'Reload Window') vscode.commands.executeCommand('workbench.action.reloadWindow');
    });
  };

  fs.watchFile(LOG, { interval: 60000 }, check);
  context.subscriptions.push({ dispose: () => fs.unwatchFile(LOG, check) });
}

function deactivate() {}

module.exports = { activate, deactivate };
