import Cocoa

let app = NSApplication.sharedApplication()

var useIndexes = false
var highlightColor = colorFromHex("0000FF")
var numRows = 10
var percentWidth: Double? = nil
var queryFont: NSFont

func showVersion() {
    println(NSBundle.mainBundle().infoDictionary!["CFBundleVersion"]);
    exit(0)
}

let defaultQueryFont = NSFont(name: "Menlo", size: 26.0)!
var fontName = defaultQueryFont.fontName
var fontSize = defaultQueryFont.pointSize

CommandLine.parse(
    usage: { "usage: \($0) [-i] [-v] [-n rows=10] [-w widthpercent=auto] [-f fontname=Menlo] [-s fontsize=26] [-c highlight=0000FF]" },
    flags: [
        "i": .V({ useIndexes = true }),
        "f": .S({ fontName = $0 }),
        "c": .S({ highlightColor = colorFromHex($0) }),
        "s": .D({ fontSize = CGFloat($0) }),
        "n": .I({ numRows = $0 }),
        "w": .D({ percentWidth = $0 }),
        "v": .V({ showVersion() }),
        "h": .Usage,
    ],
    done: { args in
        queryFont = NSFont(name: fontName, size: fontSize) ?? defaultQueryFont
        
        chooser.ensureHasItems()
        
        app.setActivationPolicy(.Accessory)
        app.delegate = AppDelegate()
        NSApplicationMain(C_ARGC, C_ARGV)
    }
)
