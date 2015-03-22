import Cocoa

private func floatFromHex(c: Character) -> Double {
    switch c {
    case "0": return 0
    case "1": return 1
    case "2": return 2
    case "3": return 3
    case "4": return 4
    case "5": return 5
    case "6": return 6
    case "7": return 7
    case "8": return 8
    case "9": return 9
    case "A": return 10
    case "B": return 11
    case "C": return 12
    case "D": return 13
    case "E": return 14
    case "F": return 15
    default: return 0.0
    }
}

private func colorFromHexChars(first: Character, second: Character) -> Double {
    let a = floatFromHex(first) * 16
    let b = floatFromHex(second)
    return (a + b) / 255
}

func colorFromHex(hex: String) -> NSColor {
    let chars = Array(hex)
    return NSColor(
        red:   CGFloat(colorFromHexChars(chars[0], chars[1])),
        green: CGFloat(colorFromHexChars(chars[2], chars[3])),
        blue:  CGFloat(colorFromHexChars(chars[4], chars[5])),
        alpha: 1.0)
}
