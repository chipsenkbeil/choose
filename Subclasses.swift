import Cocoa

class Window: NSWindow {
    
    override var canBecomeKeyWindow: Bool  { return true }
    override var canBecomeMainWindow: Bool { return true }
    
}

class TableView: NSTableView {
    
    override var acceptsFirstResponder: Bool     { return false }
    override func becomeFirstResponder() -> Bool { return false }
    override var canBecomeKeyView: Bool          { return false }
    
}
