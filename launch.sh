#!/bin/bash
# Launcher script for Now Playing app

cd "$(dirname "$0")"

# Kill any existing instances
pkill -f "NowPlaying.app" 2>/dev/null

# Launch the app directly
./NowPlaying.app/Contents/MacOS/NowPlaying &

echo "Now Playing app launched!"
echo "Check the menu bar for the status item."

