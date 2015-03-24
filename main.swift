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

var fontName = "Menlo"
var fontSize = 26.0

CommandLine.parse(
    usage: { "usage: \($0) [-i] [-v] [-n rows=10] [-w widthpercent=auto] [-f fontname=Menlo] [-s fontsize=26] [-c highlight=0000FF]" },
    flags: [
        "i": .V({ useIndexes = true }),
        "f": .S({ fontName = $0 }),
        "c": .S({ highlightColor = colorFromHex($0) }),
        "s": .D({ fontSize = $0 }),
        "n": .I({ numRows = $0 }),
        "w": .D({ percentWidth = $0 }),
        "v": .V({ showVersion() }),
        "h": .Usage,
    ],
    done: { args in
        if let tryFont = NSFont(name: fontName, size: CGFloat(fontSize)) {
            queryFont = tryFont
        }
        
        app.setActivationPolicy(.Accessory)
        app.delegate = AppDelegate()
        NSApplicationMain(C_ARGC, C_ARGV)
    }
)
