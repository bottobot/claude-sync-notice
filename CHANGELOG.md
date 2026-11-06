# Changelog

## 1.1.0
- Fix: the notice reappeared on every reload. The window start time came from `process.uptime()`, which survived reloads. The baseline is now the newest logged version at startup.

## 1.0.0
- First version.
