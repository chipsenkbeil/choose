import Cocoa


extension NSApplication {
    func setColorGridView(view: AnyObject!) {}
    func setView(view: AnyObject!) {}
}


class AppDelegate: NSObject, NSApplicationDelegate {
    
    var win: NSWindow?
    var choices = [Choice]()
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        let inputItems = getInputItems()
        if inputItems == nil {
            cancel()
        }
        
        app.activateIgnoringOtherApps(true)
        
        
        
        win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 100, height: 100),
            styleMask: NSTitledWindowMask,
            backing: .Buffered,
            defer: false)
        
        win?.makeKeyAndOrderFront(nil)
    }
    
    func choose() {
        
    }
    
    func cancel() {
        if useIndexes {
            writeOutput("-1")
        }
        
        exit(1)
    }
    
}
