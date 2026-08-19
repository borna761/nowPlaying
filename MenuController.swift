import AppKit
import Combine

class MenuController {
    private let statusItem: NSStatusItem
    private let mediaControl: MediaControl
    private var menu: NSMenu
    private var cancellables = Set<AnyCancellable>()
    
    init(mediaControl: MediaControl) {
        self.mediaControl = mediaControl
        
        // Create status item with explicit length
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        // Create menu
        menu = NSMenu()
        menu.autoenablesItems = false
        
        // Configure status item
        guard let button = statusItem.button else {
            print("NowPlaying: statusItem.button was nil; menu bar item will not be functional")
            return
        }
        
        // Set initial title and configure button
        button.title = "Not playing"
        button.font = NSFont.systemFont(ofSize: 13)
        button.appearsDisabled = false
        button.isEnabled = true
        button.isHidden = false
        
        // Build menu first
        buildMenu()
        
        // Set menu - this makes the button visible
        statusItem.menu = menu
        
        // Ensure visibility
        statusItem.autosaveName = "NowPlayingStatusItem"
        statusItem.isVisible = true
        
        // Force update
        button.needsDisplay = true
        
        // Observe media control changes. title/artworkImage/isPlaying are typically
        // updated together for a single stream payload; merge and debounce them so
        // that produces one menu rebuild instead of one per field.
        Publishers.Merge3(
            mediaControl.$title.map { _ in () },
            mediaControl.$artworkImage.map { _ in () },
            mediaControl.$isPlaying.map { _ in () }
        )
        .debounce(for: .milliseconds(10), scheduler: DispatchQueue.main)
        .sink { [weak self] in
            guard let self = self else { return }
            self.updateTitle(self.mediaControl.title)
        }
        .store(in: &cancellables)
    }
    
    private func buildMenu() {
        menu.removeAllItems()
        
        // Track info section
        let trackInfoItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        updateTrackInfoItem(trackInfoItem)
        menu.addItem(trackInfoItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Playback controls
        let playPauseItem = NSMenuItem(
            title: mediaControl.isPlaying ? "Pause" : "Play",
            action: #selector(togglePlayPause),
            keyEquivalent: ""
        )
        playPauseItem.target = self
        menu.addItem(playPauseItem)
        
        let previousItem = NSMenuItem(
            title: "Previous",
            action: #selector(previousTrack),
            keyEquivalent: ""
        )
        previousItem.target = self
        menu.addItem(previousItem)
        
        let nextItem = NSMenuItem(
            title: "Next",
            action: #selector(nextTrack),
            keyEquivalent: ""
        )
        nextItem.target = self
        menu.addItem(nextItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit item
        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    private func updateTrackInfoItem(_ item: NSMenuItem) {
        var infoText = ""
        
        if !mediaControl.title.isEmpty && mediaControl.title != "Not playing" {
            infoText = mediaControl.title
            
            if !mediaControl.artist.isEmpty {
                infoText += "\n\(mediaControl.artist)"
            }
            
            if !mediaControl.album.isEmpty {
                infoText += "\n\(mediaControl.album)"
            }
        } else {
            infoText = "Not playing"
        }
        
        item.title = infoText
        item.isEnabled = false
        
        // Add artwork if available
        if let artwork = mediaControl.artworkImage {
            // Resize artwork to menu item size
            let size = NSSize(width: 64, height: 64)
            let resizedImage = NSImage(size: size)
            resizedImage.lockFocus()
            artwork.draw(in: NSRect(origin: .zero, size: size),
                        from: NSRect(origin: .zero, size: artwork.size),
                        operation: .sourceOver,
                        fraction: 1.0)
            resizedImage.unlockFocus()
            item.image = resizedImage
        } else {
            item.image = nil
        }
    }
    
    private func updateTitle(_ title: String) {
        guard let button = statusItem.button else {
            return
        }
        
        // Show artwork if available, and also show title
        if let artwork = mediaControl.artworkImage {
            // Resize artwork for menu bar (typically 18-22px height)
            let menuBarSize = NSSize(width: 18, height: 18)
            let resizedArtwork = NSImage(size: menuBarSize)
            resizedArtwork.lockFocus()
            artwork.draw(in: NSRect(origin: .zero, size: menuBarSize),
                        from: NSRect(origin: .zero, size: artwork.size),
                        operation: .sourceOver,
                        fraction: 1.0)
            resizedArtwork.unlockFocus()
            button.image = resizedArtwork
            button.image?.isTemplate = false // Keep original colors
            
            // Also show title text alongside artwork
            let maxLength = 40 // Shorter since we have artwork
            let displayTitle: String
            if title.count > maxLength {
                displayTitle = String(title.prefix(maxLength - 3)) + "..."
            } else {
                displayTitle = title
            }
            button.title = " \(displayTitle)" // Add space between icon and text
        } else {
            // No artwork - show title text only
            button.image = nil
            // Truncate title if too long
            let maxLength = 50
            let displayTitle: String
            if title.count > maxLength {
                displayTitle = String(title.prefix(maxLength - 3)) + "..."
            } else {
                displayTitle = title
            }
            button.title = displayTitle
        }
        
        button.isHidden = false
        
        // Rebuild menu to update play/pause state and track info
        buildMenu()
    }
    
    @objc private func togglePlayPause() {
        mediaControl.togglePlayPause()
        // Menu rebuilds once mediaControl.isPlaying reflects the real state.
    }
    
    @objc private func previousTrack() {
        mediaControl.previous()
    }
    
    @objc private func nextTrack() {
        mediaControl.next()
    }
    
    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
