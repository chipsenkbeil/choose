import Cocoa


extension NSApplication {
    func setColorGridView(view: AnyObject!) {}
    func setView(view: AnyObject!) {}
}

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    
    let windowController = WindowController()
    
    func applicationDidFinishLaunching(notification: NSNotification) {
        chooser.ensureHasItems()
        app.activateIgnoringOtherApps(true)
        
        // ...
        
        windowController.showWindow(nil)
    }
    
    func choose() {
        
    }
    
}
