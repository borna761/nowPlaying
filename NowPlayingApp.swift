import AppKit

class NowPlayingApp: NSObject, NSApplicationDelegate {
    private var mediaControl: MediaControl!
    private var menuController: MenuController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create media control manager
        mediaControl = MediaControl()
        
        // Create menu controller
        menuController = MenuController(mediaControl: mediaControl)
        
        // Start streaming media updates after a short delay to ensure UI is ready
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.mediaControl.startStreaming()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        mediaControl?.stopStreaming()
    }
    
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
