import AppKit

class NowPlayingApp: NSObject, NSApplicationDelegate {
    private var mediaControl: MediaControl!
    private var menuController: MenuController!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create media control manager
        mediaControl = MediaControl()
        
        // Create menu controller
        menuController = MenuController(mediaControl: mediaControl)

        // MenuController's init is synchronous, so it's already fully set up here.
        mediaControl.startStreaming()
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
