import Cocoa

class WindowController: NSWindowController, NSWindowDelegate {
    
    private var win: NSWindow { return window! }
    
    override func loadWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 1000),
            styleMask: NSFullSizeContentViewWindowMask | NSTitledWindowMask,
            backing: .Buffered,
            defer: false)
        
        win.delegate = self
        
        win.titlebarAppearsTransparent = true
        let blur = NSVisualEffectView(frame: win.contentView.bounds)
        blur.autoresizingMask = .ViewWidthSizable | .ViewHeightSizable
        blur.material = .Light
        blur.state = .Active
        win.contentView.addSubview(blur)
    }
    
//    func buildFrames() -> (NSRect, NSRect, NSRect, NSRect, NSRect) {
//        var textRect = NSZeroRect
//        var listRect = NSZeroRect
//        var dividerRect = NSZeroRect
//        let winRect = NSRect(x: 0, y: 0, width: 100, height: 100)
//        let contentViewRect = NSInsetRect(winRect, 10, 10)
//        NSDivideRect(contentViewRect, &textRect, &listRect, NSHeight(queryFont.boundingRectForFont), NSMaxYEdge)
//        NSDivideRect(listRect, &dividerRect, &listRect, 20.0, NSMaxYEdge)
//        dividerRect.origin.y += NSHeight(dividerRect) / 2.0
//        dividerRect.size.height = 1.0
//        return (textRect, listRect, dividerRect, winRect, contentViewRect)
//    }
    
}
