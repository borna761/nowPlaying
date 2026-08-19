#!/bin/bash
# Script to install/uninstall the Launch Agent for automatic startup

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$SCRIPT_DIR"
PLIST_NAME="com.nowplaying.app.plist"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
PLIST_SOURCE="$APP_DIR/$PLIST_NAME"
PLIST_DEST="$LAUNCH_AGENTS_DIR/$PLIST_NAME"

# Update the plist with the correct app path
APP_EXECUTABLE="$APP_DIR/NowPlaying.app/Contents/MacOS/NowPlaying"

if [ "$1" == "uninstall" ] || [ "$1" == "remove" ]; then
    echo "Uninstalling Launch Agent..."
    
    # Unload if already loaded
    if launchctl list | grep -q "com.nowplaying.app"; then
        launchctl unload "$PLIST_DEST" 2>/dev/null || true
    fi
    
    # Remove the plist file
    if [ -f "$PLIST_DEST" ]; then
        rm "$PLIST_DEST"
        echo "✓ Launch Agent uninstalled"
    else
        echo "Launch Agent was not installed"
    fi
    exit 0
fi

echo "Installing Launch Agent for automatic startup..."

# Create LaunchAgents directory if it doesn't exist
mkdir -p "$LAUNCH_AGENTS_DIR"

# Check if app exists
if [ ! -f "$APP_EXECUTABLE" ]; then
    echo "Error: App executable not found at $APP_EXECUTABLE"
    echo "Please build the app first using ./build.sh"
    exit 1
fi

# Create/update plist with correct path
cat > "$PLIST_SOURCE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.nowplaying.app</string>
    <key>ProgramArguments</key>
    <array>
        <string>$APP_EXECUTABLE</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <false/>
    <key>StandardOutPath</key>
    <string>/dev/null</string>
    <key>StandardErrorPath</key>
    <string>/dev/null</string>
</dict>
</plist>
EOF

# Copy to LaunchAgents directory
cp "$PLIST_SOURCE" "$PLIST_DEST"

# Load the Launch Agent
launchctl load "$PLIST_DEST" 2>/dev/null || launchctl bootstrap gui/$(id -u) "$PLIST_DEST" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✓ Launch Agent installed successfully!"
    echo "The app will now start automatically when you log in."
    echo ""
    echo "To uninstall, run: ./install-launch-agent.sh uninstall"
else
    echo "Warning: Launch Agent plist copied but failed to load."
    echo "You may need to log out and log back in, or restart your Mac."
fi

