import Cocoa

extension NSApplication {
    func setColorGridView(view: AnyObject!) {}
    func setView(view: AnyObject!) {}
}

let app = NSApplication.sharedApplication()

var useIndexes = false
var highlightColor = NSColor(hex: "0000FF")
var numRows = 10
var percentWidth: Double? = nil
var queryFont = NSFont(name: "Menlo", size: 26.0)!

func showVersion() {
    println(NSBundle.mainBundle().infoDictionary!["CFBundleVersion"])
    exit(0)
}

func chooseFont(name: String = queryFont.fontName, size: Double = Double(queryFont.pointSize)) {
    queryFont = NSFont(name: name, size: CGFloat(size)) ?? queryFont
}

CommandLine.parse(
    usage: { "usage: \($0) [-i] [-v] [-n rows=10] [-w widthpercent=auto] [-f fontname=Menlo] [-s fontsize=26] [-c highlight=0000FF]" },
    flags: [
        "i": .V({ useIndexes = true }),
        "f": .S({ chooseFont(name: $0) }),
        "c": .S({ highlightColor = NSColor(hex: $0) }),
        "s": .D({ chooseFont(size: $0) }),
        "n": .I({ numRows = $0 }),
        "w": .D({ percentWidth = $0 }),
        "v": .V({ showVersion() }),
        "h": .Usage,
    ],
    done: { args in
        chooser.ensureHasItems()
        
        app.setActivationPolicy(.Accessory)
        app.delegate = AppDelegate()
        NSApplicationMain(C_ARGC, C_ARGV)
    }
)
