#!/usr/bin/env bash
# Install the planner on this Mac (SPEC RUN-3):
# - the bot runs whenever you are logged in and is restarted if it stops; it does the schedule every minute;
# - `planner run` also runs at login and every 30 minutes, as a backup if the bot is down.
# A lock makes sure only one of them sends at a time. Usage: deploy/install_launchd.sh [--uninstall]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PLANNER="$ROOT/.venv/bin/planner"
RUN_LABEL="com.studyplanner.run"
BOT_LABEL="com.studyplanner.bot"
AGENTS="$HOME/Library/LaunchAgents"

if [[ "${1:-}" == "--uninstall" ]]; then
  for l in "$RUN_LABEL" "$BOT_LABEL"; do
    launchctl bootout "gui/$(id -u)/$l" 2>/dev/null || true
    rm -f "$AGENTS/$l.plist"
  done
  echo "Removed the planner schedule and bot."
  exit 0
fi

[[ -x "$PLANNER" ]] || { echo "missing $PLANNER - run: python3 -m venv .venv && .venv/bin/pip install -e ." >&2; exit 1; }
"$PLANNER" check >/dev/null || { echo "planner check failed - run .venv/bin/planner check" >&2; exit 1; }
mkdir -p "$ROOT/data/logs" "$AGENTS"

plist() {  # label, keepalive(true|false), args...
  local label="$1" keep="$2"; shift 2
  local args="" a
  for a in "$@"; do args+="<string>$a</string>"; done
  local extra='<key>StartInterval</key><integer>1800</integer>'
  [[ "$keep" == "true" ]] && extra='<key>KeepAlive</key><true/><key>ThrottleInterval</key><integer>30</integer>'
  cat > "$AGENTS/$label.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key><string>$label</string>
  <key>ProgramArguments</key><array><string>$PLANNER</string>$args</array>
  <key>WorkingDirectory</key><string>$ROOT</string>
  <key>RunAtLoad</key><true/>
  $extra
  <key>ProcessType</key><string>Background</string>
  <key>StandardOutPath</key><string>$ROOT/data/logs/$label.out.log</string>
  <key>StandardErrorPath</key><string>$ROOT/data/logs/$label.err.log</string>
  <key>EnvironmentVariables</key>
  <dict><key>PATH</key><string>/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin</string></dict>
</dict>
</plist>
PLIST
  plutil -lint "$AGENTS/$label.plist" >/dev/null
  launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$AGENTS/$label.plist"
}

plist "$BOT_LABEL" true bot
plist "$RUN_LABEL" false run
echo "Installed. The daily message goes out at the time in config/planner.toml (send_at),"
echo "or as soon as this Mac is awake after that. Logs: $ROOT/data/logs/"
