import Cocoa

var win: NSWindow?

extension NSApplication {
    func setColorGridView(view: AnyObject!) {}
    func setView(view: AnyObject!) {}
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: NSTitledWindowMask,
            backing: .Buffered,
            defer: false)
        
        win?.makeKeyAndOrderFront(nil)
    }
    
}
