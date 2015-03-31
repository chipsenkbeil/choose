import Cocoa

class Window: NSWindow {
    
    override var canBecomeKeyWindow: Bool  { return true }
    override var canBecomeMainWindow: Bool { return true }
    
}

class WindowController: NSWindowController, NSWindowDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate {
    
    private var win: NSWindow { return window! }
    private var handlers = [AnyObject]()
    
    let queryField = NSTextField()
    let listTableView = TableView()
    
    func makeWindow() {
        println("loading window")
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1000, height: 1000),
            styleMask: NSFullSizeContentViewWindowMask | NSTitledWindowMask,
            backing: .Buffered,
            defer: false)
        
        win.delegate = self
        
        let (textRect, listRect, dividerRect) = buildFrames()
        
        setupBlurryBackground()
        setupQueryFeld(textRect)
        setupDivider(dividerRect)
        setupResultsTable(listRect)
        
        runQuery("")
        resizeWindow()
        
        win.center()
        
        app.mainMenu = NSMenu(title: "bla")
        app.mainMenu!.add
        
        println(app.mainMenu)
        
        setupKeyboardShortcuts()
    }
    
    func setupBlurryBackground() {
        win.titlebarAppearsTransparent = true
        let blur = NSVisualEffectView(frame: win.contentView.bounds)
        blur.autoresizingMask = .ViewWidthSizable | .ViewHeightSizable
        blur.material = .Light
        blur.state = .Active
        win.contentView.addSubview(blur)
    }
    
    func setupQueryFeld(var textRect: NSRect) {
        var iconRect = NSZeroRect, space = NSZeroRect
        
        NSDivideRect(textRect, &iconRect, &textRect, NSHeight(textRect) / 1.25, NSMinXEdge)
        NSDivideRect(textRect, &space, &textRect, 5.0, NSMinXEdge)
        
        let d = NSHeight(iconRect) * 0.10
        iconRect = NSInsetRect(iconRect, d, d)
        
        let icon = NSImageView(frame: iconRect)
        icon.autoresizingMask = .ViewMaxXMargin | .ViewMinYMargin
        icon.image = NSImage(named: NSImageNameRightFacingTriangleTemplate)
        icon.imageScaling = .ImageScaleProportionallyUpOrDown
        win.contentView.addSubview(icon)
        
        queryField.frame = textRect
        queryField.autoresizingMask = .ViewWidthSizable | .ViewMinYMargin
        queryField.delegate = self
        queryField.bezelStyle = .SquareBezel
        queryField.bordered = false
        queryField.drawsBackground = false
        queryField.focusRingType = .None
        queryField.font = queryFont
        queryField.editable = true
        queryField.target = self
        queryField.action = Selector("choose:")
        (queryField.cell() as NSTextFieldCell).sendsActionOnEndEditing = false
        win.contentView.addSubview(queryField)
    }
    
    func setupDivider(dividerRect: NSRect) {
        let border = NSBox(frame: dividerRect)
        border.autoresizingMask = .ViewWidthSizable | .ViewMinYMargin
        border.boxType = .Custom
        border.fillColor = NSColor.lightGrayColor()
        border.borderWidth = 0
        win.contentView.addSubview(border)
    }
    
    func setupResultsTable(listRect: NSRect) {
        let rowFont = NSFont(name: queryFont.fontName, size: queryFont.pointSize * 0.70)
        
        let col = NSTableColumn(identifier: "thing")
        col.editable = false
        col.width = 10000
        (col.dataCell as NSCell).font = rowFont
        
        let cell = col.dataCell as NSTextFieldCell
        cell.lineBreakMode = .ByCharWrapping
        
        listTableView.setDataSource(self)
        listTableView.setDelegate(self)
        
        listTableView.backgroundColor = NSColor.clearColor()
        listTableView.headerView = nil
        listTableView.allowsEmptySelection = false
        listTableView.allowsMultipleSelection = false
        listTableView.allowsTypeSelect = false
        listTableView.rowHeight = NSHeight(rowFont!.boundingRectForFont) * 1.20
        listTableView.addTableColumn(col)
        
        listTableView.target = self
        listTableView.doubleAction = Selector("chooseByDoubleClicking:")
        listTableView.selectionHighlightStyle = .None
        
        let listScrollView = NSScrollView(frame: listRect)
        listScrollView.verticalScrollElasticity = .None
        listScrollView.autoresizingMask = .ViewWidthSizable | .ViewHeightSizable
        listScrollView.documentView = listTableView
        listScrollView.drawsBackground = false
        win.contentView.addSubview(listScrollView)
    }
    
    func runQuery(query: String) {
        chooser.runQuery(query.lowercaseString)
        listTableView.reloadData()
        reflectChoice()
    }
    
    
    // selectors
    
    
    func chooseByDoubleClicking(sender: AnyObject!) {
        let row = listTableView.clickedRow
        if row == -1 { return }
        
        chooser.choice = row
        chooser.choose()
    }
    
    func choose(sender: AnyObject!) {
        chooser.choose()
    }
    
    
    // table view
    
    
    func reflectChoice() {
        listTableView.selectRowIndexes(NSIndexSet(index: chooser.choice), byExtendingSelection: false)
        listTableView.scrollRowToVisible(chooser.choice)
    }
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return chooser.filteredSortedChoices.count
    }
    
    func tableView(tableView: NSTableView, objectValueForTableColumn tableColumn: NSTableColumn?, row: Int) -> AnyObject? {
        let choice = chooser.filteredSortedChoices[row]
        return choice.displayString
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        chooser.choice = listTableView.selectedRow
    }
    
    func tableView(tableView: NSTableView, willDisplayCell cell: AnyObject, forTableColumn tableColumn: NSTableColumn?, row: Int) {
        let aCell = cell as NSTextFieldCell
        
        if tableView.selectedRowIndexes.containsIndex(row) {
            aCell.backgroundColor = NSColor.selectedControlColor().colorWithAlphaComponent(1.0)
        }
        else {
            aCell.backgroundColor = NSColor.clearColor()
        }
        aCell.drawsBackground = false
    }
    
    
    // search field
    
    
    func control(control: NSControl, textView: NSTextView, doCommandBySelector commandSelector: Selector) -> Bool {
        switch commandSelector {
        case "cancelOperation:":
            if countElements(queryField.stringValue) > 0 {
                textView.moveToBeginningOfDocument(nil)
                textView.deleteToEndOfParagraph(nil)
            }
            else {
                chooser.cancel()
            }
            return true
        case "moveUp:":
            chooser.choice = max(chooser.choice - 1, 0)
            reflectChoice()
            return true
        case "moveDown:":
            chooser.choice = min(chooser.choice + 1, chooser.filteredSortedChoices.count - 1)
            reflectChoice()
            return true
        case "deleteForward:":
            if countElements(queryField.stringValue) == 0 {
                chooser.cancel()
            }
            return true
        default:
            println(commandSelector)
            return false
        }
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        runQuery(queryField.stringValue)
    }
    
    override func selectAll(sender: AnyObject?) {
        let editor = win.fieldEditor(false, forObject: queryField) as NSTextView
        editor.selectAll(sender)
    }
    
    // uhh
    
    
    func resizeWindow() {
        let screenFrame = NSScreen.mainScreen()!.visibleFrame
        
        let rowHeight = listTableView.rowHeight
        let intercellHeight = listTableView.intercellSpacing.height
        let allRowsheight = (rowHeight + intercellHeight) * CGFloat(numRows)
        
        let windowHeight = NSHeight(win.contentView.bounds)
        let tableHeight = NSHeight(listTableView.superview!.frame)
        let finalHeight = (windowHeight - tableHeight) + allRowsheight
        
        var width: CGFloat
        
        if percentWidth != nil {
            width = NSWidth(screenFrame) * (CGFloat(percentWidth!) / 100.0)
        }
        else {
            width = NSWidth(screenFrame) * 0.50
            width = min(width, 800)
            width = max(width, 400)
        }
        
        let winRect = NSMakeRect(0, 0, width, finalHeight)
        win.setFrame(winRect, display: true)
    }
    
    func setupKeyboardShortcuts() {
//        addShortcut("1", mods: .CommandKeyMask) { chooser.pickIndex(0) }
//        addShortcut("2", mods: .CommandKeyMask) { chooser.pickIndex(1) }
//        addShortcut("3", mods: .CommandKeyMask) { chooser.pickIndex(2) }
//        addShortcut("4", mods: .CommandKeyMask) { chooser.pickIndex(3) }
//        addShortcut("5", mods: .CommandKeyMask) { chooser.pickIndex(4) }
//        addShortcut("6", mods: .CommandKeyMask) { chooser.pickIndex(5) }
//        addShortcut("7", mods: .CommandKeyMask) { chooser.pickIndex(6) }
//        addShortcut("8", mods: .CommandKeyMask) { chooser.pickIndex(7) }
//        addShortcut("9", mods: .CommandKeyMask) { chooser.pickIndex(8) }
//        addShortcut("q", mods: .CommandKeyMask) { chooser.cancel() }
//        addShortcut("a", mods: .CommandKeyMask) { self.selectAll(nil) }
//        addShortcut("c", mods: .ControlKeyMask) { chooser.cancel() }
//        addShortcut("g", mods: .ControlKeyMask) { chooser.cancel() }
    }
    
    func addShortcut(key: String, mods: NSEventModifierFlags, handler: () -> ()) {
        let eventHandler: AnyObject = NSEvent.addLocalMonitorForEventsMatchingMask(.KeyDownMask, handler: { event in
            let flags = event.modifierFlags & .DeviceIndependentModifierFlagsMask
            if flags == mods && event.charactersIgnoringModifiers == key {
                handler()
                return nil
            }
            return event
        })!
        handlers.append(eventHandler)
    }
    
    func buildFrames() -> (NSRect, NSRect, NSRect) {
        var textRect = NSZeroRect
        var listRect = NSZeroRect
        var dividerRect = NSZeroRect
        let contentViewRect = NSInsetRect(win.contentView.bounds, 10, 10)
        NSDivideRect(contentViewRect, &textRect, &listRect, NSHeight(queryFont.boundingRectForFont), NSMaxYEdge)
        NSDivideRect(listRect, &dividerRect, &listRect, 20.0, NSMaxYEdge)
        dividerRect.origin.y += NSHeight(dividerRect) / 2.0
        dividerRect.size.height = 1.0
        return (textRect, listRect, dividerRect)
    }
    
}
