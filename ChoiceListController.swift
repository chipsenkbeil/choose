import Cocoa

class TableView: NSTableView {
    
    override var acceptsFirstResponder: Bool     { return false }
    override func becomeFirstResponder() -> Bool { return false }
    override var canBecomeKeyView: Bool          { return false }
    
}
