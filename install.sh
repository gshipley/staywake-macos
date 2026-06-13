#!/bin/zsh

set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)
APP_NAME=StayAwakeBar
APP_SOURCE="$ROOT_DIR/dist/$APP_NAME.app"
APP_TARGET="$HOME/Applications/$APP_NAME.app"
LAUNCH_AGENT="$HOME/Library/LaunchAgents/com.gshipley.$APP_NAME.plist"

"$ROOT_DIR/stayawakebar/build.sh" >/dev/null

mkdir -p "$HOME/Applications" "$HOME/Library/LaunchAgents"
rm -rf "$APP_TARGET"
cp -R "$APP_SOURCE" "$APP_TARGET"

cat >"$LAUNCH_AGENT" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Label</key>
	<string>com.gshipley.StayAwakeBar</string>
	<key>LimitLoadToSessionType</key>
	<array>
		<string>Aqua</string>
	</array>
	<key>ProcessType</key>
	<string>Interactive</string>
	<key>ProgramArguments</key>
	<array>
		<string>$APP_TARGET/Contents/MacOS/StayAwakeBar</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
</dict>
</plist>
EOF

plutil -lint "$LAUNCH_AGENT" >/dev/null
launchctl bootout "gui/$(id -u)" "$LAUNCH_AGENT" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$LAUNCH_AGENT"
launchctl kickstart -k "gui/$(id -u)/com.gshipley.StayAwakeBar"

echo "Installed to $APP_TARGET"
