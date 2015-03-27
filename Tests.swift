import Cocoa

infix operator ==> {}

private func ==><T: Equatable>(a: T, b: T) {
    assert(a == b, "\n expected: \(a)\n      got: \(b)\n")
}

private func ==><T: Equatable>(a: [T], b: [T]) {
    assert(a == b, "\n expected: \(a)\n      got: \(b)\n")
}

private func testHex() {
    Int(hex: "100") ==> 256
    Int(hex: "ff") ==> 255
    Int(hex: "FF") ==> 255
    Int(hex: "FfF") ==> 4095
    Int(hex: "7c") ==> 124
    Int(hex: "deadbeef") ==> 3735928559
    Int(hex: "deadbeef") ==> 3735928559
}

private func testColor() {
    NSColor(hex: "000000") ==> NSColor(red: 0, green: 0, blue: 0, alpha: 1)
    NSColor(hex: "ffffff") ==> NSColor(red: 1, green: 1, blue: 1, alpha: 1)
    NSColor(hex: "00") ==> NSColor(white: 0, alpha: 1)
    NSColor(hex: "ff") ==> NSColor(white: 1, alpha: 1)
    NSColor(hex: "33") ==> NSColor(white: 0.2, alpha: 1)
    NSColor(hex: "66") ==> NSColor(white: 0.4, alpha: 1)
    NSColor(hex: "99") ==> NSColor(white: 0.6, alpha: 1)
    NSColor(hex: "cc") ==> NSColor(white: 0.8, alpha: 1)
}

prefix operator ??? {}
private prefix func ???(fn: () -> ()) {
    fn()
}

private func testCommandLine() {
    ???{
        var done = [String]()
        CommandLine(usage: { prog in }, flags: ["h":.Usage], done: { done += $0 }, arguments: ["prog", "bla"]).parse()
        done ==> ["bla"]
    }
    
    ???{
        var usage = ""
        CommandLine(usage: {usage=$0}, flags: ["h":.Usage], done: { args in }, arguments: ["prog", "-h"]).parse()
        usage ==> "prog"
    }
}

func runTests() {
    testHex()
    testColor()
    testCommandLine()
    assert(false, "bla")
}
