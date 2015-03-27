import Cocoa

private func expectedEquals<T>(a: T, b: T) -> String { return "\n expected: \(a)\n      got: \(b)\n" }
infix operator ==> {}
private func ==> <T: Equatable>(a: T, b: T)     { assert(a == b, expectedEquals(a, b)) }
private func ==> <T: Equatable>(a: T?, b: T?)   { assert(a == b, expectedEquals(a, b)) }
private func ==> <T: Equatable>(a: [T], b: [T]) { assert(a == b, expectedEquals(a, b)) }

private func testAscii() {
    Int(ascii: "A") ==> 65
    Int(ascii: "a") ==> 97
    Int(ascii: " ") ==> 32
    Int(ascii: "z") ==> 122
    Int(ascii: "†") ==> nil
}

private func testHex() {
    Int(hex: "quux") ==> nil
    Int(hex: "z") ==> nil
    Int(hex: "100")! ==> 0x100
    Int(hex: "ff")! ==> 0xff
    Int(hex: "FF")! ==> 0xFF
    Int(hex: "FfF")! ==> 0xFfF
    Int(hex: "7c")! ==> 0x7c
    Int(hex: "deadbeef")! ==> 0xdeadbeef
    Int(hex: "23487fb")! ==> 0x23487fb
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
    testAscii()
    testHex()
    testColor()
    testCommandLine()
    assert(false, "bla")
}
