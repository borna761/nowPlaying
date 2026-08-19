import AppKit

let app = NSApplication.shared
let delegate = NowPlayingApp()
app.delegate = delegate
app.run()
