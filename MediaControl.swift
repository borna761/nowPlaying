import Foundation
import Combine
import AppKit

class MediaControl: ObservableObject {
    @Published var title: String = "Not playing"
    @Published var artist: String = ""
    @Published var album: String = ""
    @Published var isPlaying: Bool = false
    @Published var elapsedTime: Double = 0
    @Published var duration: Double = 0
    @Published var artworkImage: NSImage? = nil
    @Published var playbackRate: Double = 1.0
    @Published var bundleIdentifier: String = ""
    
    private var process: Process?
    private var pipe: Pipe?
    private var fileHandle: FileHandle?
    private let queue = DispatchQueue(label: "com.nowplaying.mediacontrol", qos: .userInitiated)
    private var buffer = Data()
    
    // Cache artwork to prevent flickering when artwork temporarily disappears
    private var cachedArtwork: NSImage? = nil
    
    private var mediaControlPath: String {
        // Try common Homebrew locations
        let possiblePaths = [
            "/opt/homebrew/bin/media-control",  // Apple Silicon Homebrew
            "/usr/local/bin/media-control"      // Intel Homebrew
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        // Fallback: use which to find it in PATH
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["media-control"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !path.isEmpty, FileManager.default.fileExists(atPath: path) {
                return path
            }
        } catch {
            // Ignore
        }
        
        // Default fallback (will show error if not found)
        return "/opt/homebrew/bin/media-control"
    }
    
    func startStreaming() {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            // Stop any existing process
            self.stopStreaming()
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["stream"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = Pipe() // Discard stderr
            
            self.process = process
            self.pipe = pipe
            self.fileHandle = pipe.fileHandleForReading
            
            guard let fileHandle = self.fileHandle else {
                return
            }
            
            // Set up notification for new data
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(self.handleDataAvailable),
                name: FileHandle.readCompletionNotification,
                object: fileHandle
            )
            
            do {
                try process.run()
                
                // Small delay to ensure process is fully started, then start reading
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    guard let self = self, let fileHandle = self.fileHandle else {
                        return
                    }
                    
                    // Start reading data asynchronously
                    fileHandle.readInBackgroundAndNotify()
                }
                
            } catch {
                DispatchQueue.main.async { [weak self] in
                    self?.title = "Error: Unable to start"
                    self?.artist = "Check media-control installation"
                }
            }
        }
    }
    
    func stopStreaming() {
        process?.terminate()
        process?.waitUntilExit()
        
        fileHandle?.closeFile()
        fileHandle = nil
        process = nil
        pipe = nil
        buffer = Data()
        
        NotificationCenter.default.removeObserver(self, name: FileHandle.readCompletionNotification, object: nil)
    }
    
    @objc private func handleDataAvailable(notification: Notification) {
        guard let fileHandle = notification.object as? FileHandle,
              let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
            return
        }
        
        if data.isEmpty {
            fileHandle.readInBackgroundAndNotify()
            return
        }
        
        // Continue reading
        fileHandle.readInBackgroundAndNotify()
        
        // Append to buffer
        buffer.append(data)
        
        // Process complete lines (each JSON object is on its own line)
        let newlineData = "\n".data(using: .utf8)!
        while let newlineRange = buffer.range(of: newlineData) {
            let lineData = buffer.subdata(in: 0..<newlineRange.lowerBound)
            buffer.removeSubrange(0..<newlineRange.upperBound)
            
            if let lineString = String(data: lineData, encoding: .utf8), !lineString.isEmpty {
                parseJSONLine(lineString)
            }
        }
    }
    
    private func parseJSONLine(_ line: String) {
        guard !line.isEmpty else { return }
        
        guard let data = line.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String,
              type == "data",
              let payload = json["payload"] as? [String: Any] else {
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Update track info
            if payload.isEmpty {
                self.title = "Not playing"
                self.artist = ""
                self.album = ""
                self.isPlaying = false
                self.artworkImage = nil
                self.cachedArtwork = nil
                return
            }
            
            // Update fields only if they exist in payload
            let newTitle = payload["title"] as? String ?? ""
            let newArtist = payload["artist"] as? String ?? ""
            
            // Check if track actually changed by comparing current published values with new values
            let trackChanged = !newTitle.isEmpty && newTitle != self.title
            
            if !newTitle.isEmpty {
                self.title = newTitle
            }
            
            if !newArtist.isEmpty {
                self.artist = newArtist
            }
            
            if let album = payload["album"] as? String {
                self.album = album
            }
            
            if let playing = payload["playing"] as? Bool {
                self.isPlaying = playing
            }
            
            if let elapsed = payload["elapsedTime"] as? Double {
                self.elapsedTime = elapsed
            }
            
            if let duration = payload["duration"] as? Double {
                self.duration = duration
            }
            
            if let rate = payload["playbackRate"] as? Double {
                self.playbackRate = rate
            }
            
            if let bundleId = payload["bundleIdentifier"] as? String {
                self.bundleIdentifier = bundleId
            }
            
            // Parse artwork if available
            if let artworkDataStr = payload["artworkData"] as? String,
               !artworkDataStr.isEmpty,
               let artworkData = Data(base64Encoded: artworkDataStr, options: .ignoreUnknownCharacters),
               let image = NSImage(data: artworkData) {
                // Store new artwork - only update cache when we actually get artwork
                self.artworkImage = image
                self.cachedArtwork = image
            } else {
                // Artwork data missing - check if track changed
                if trackChanged {
                    // Track changed, clear artwork
                    self.artworkImage = nil
                    self.cachedArtwork = nil
                } else if let cached = self.cachedArtwork {
                    // Same track, artwork temporarily missing - reuse cached version
                    self.artworkImage = cached
                } else {
                    // No cached artwork available
                    self.artworkImage = nil
                }
            }
        }
    }
    
    // Playback control methods
    func togglePlayPause() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["toggle-play-pause"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to toggle play/pause: \(error)")
            }
        }
    }
    
    func play() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["play"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to play: \(error)")
            }
        }
    }
    
    func pause() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["pause"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to pause: \(error)")
            }
        }
    }
    
    func previous() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["previous"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to go to previous track: \(error)")
            }
        }
    }
    
    func next() {
        queue.async { [weak self] in
            guard let self = self else { return }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: self.mediaControlPath)
            process.arguments = ["next"]
            
            do {
                try process.run()
                process.waitUntilExit()
            } catch {
                print("Failed to go to next track: \(error)")
            }
        }
    }
    
    deinit {
        stopStreaming()
    }
}
