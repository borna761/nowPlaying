# Now Playing - macOS Menu Bar App

A simple macOS menu bar application that displays the currently playing track and provides playback controls.

## Features

- Displays track title in the menu bar
- Real-time updates as the track changes
- Playback controls via menu (Play/Pause, Previous, Next)
- Shows track information (title, artist, album) in the menu

## Requirements

- macOS 11.0 or later
- `media-control` CLI tool installed via Homebrew:
  ```bash
  brew tap ungive/media-control
  brew install media-control
  ```

## Building

You can build this app without Xcode using the provided build script or Swift Package Manager.

### Using the Build Script (Recommended)

Simply run:

```bash
./build.sh
```

This will create a `NowPlaying.app` bundle that you can run directly:

```bash
open NowPlaying.app
```

Or execute directly:

```bash
./NowPlaying.app/Contents/MacOS/NowPlaying
```

### Using Swift Package Manager

Build with:

```bash
swift build -c release
```

Then create the app bundle manually:

```bash
mkdir -p NowPlaying.app/Contents/MacOS
cp .build/release/NowPlaying NowPlaying.app/Contents/MacOS/
cp Info.plist NowPlaying.app/Contents/
```

### Using Xcode (Optional)

If you prefer Xcode:

1. Open Xcode
2. Create a new macOS App project
3. Replace the default files with the Swift files from this project:
   - `NowPlayingApp.swift`
   - `MediaControl.swift`
   - `MenuController.swift`
4. Add `Info.plist` to your project
5. Build and run

## Usage

### Launching

**Option 1: Use the launcher script (easiest)**
```bash
./launch.sh
```

**Option 2: Launch directly**
```bash
./NowPlaying.app/Contents/MacOS/NowPlaying &
```

**Option 3: From Finder**
Navigate to the app folder and double-click `NowPlaying.app`

### Automatic Startup

To make the app start automatically when you log in, install the Launch Agent:

```bash
./install-launch-agent.sh
```

This will:
- Create a Launch Agent plist file
- Install it to `~/Library/LaunchAgents/`
- Enable automatic startup on login

To remove automatic startup:
```bash
./install-launch-agent.sh uninstall
```

### Using the App

1. The current track title will appear in the menu bar
2. Click the menu bar icon to access playback controls:
   - Track information (title, artist, album)
   - Play/Pause toggle
   - Previous track
   - Next track
   - Quit
3. The title updates automatically as the track changes

## How It Works

The app uses the `media-control stream` command to get real-time updates about what's currently playing. It parses the JSON output and updates the menu bar display accordingly.

Playback controls are sent to the `media-control` CLI tool, which communicates with the system's MediaRemote framework.

## Project Structure

- `NowPlayingApp.swift` - Main application entry point and delegate
- `MediaControl.swift` - Interface to `media-control` CLI tool and state management
- `MenuController.swift` - Menu bar UI and menu management
- `Info.plist` - Application configuration and metadata

## License

This project is provided as-is for personal use.
