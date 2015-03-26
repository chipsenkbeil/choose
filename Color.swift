import Cocoa

extension Int {
    
    init(hex: Character) {
        switch hex {
        case "0": self = 0
        case "1": self = 1
        case "2": self = 2
        case "3": self = 3
        case "4": self = 4
        case "5": self = 5
        case "6": self = 6
        case "7": self = 7
        case "8": self = 8
        case "9": self = 9
        case "A": self = 10
        case "B": self = 11
        case "C": self = 12
        case "D": self = 13
        case "E": self = 14
        case "F": self = 15
        default: self = 0
        }
    }
    
    init(hex: String) {
        self = 0
        var base = 1
        
        for char in reverse(hex) {
            var x = Int(hex: char)
            self += (x * base)
            base *= 16
        }
    }
    
}

extension NSColor {
    
    convenience init(hex: String) {
        let chars = Array(hex)
        
        let r = Int(hex: String(chars[0...1]))
        let g = Int(hex: String(chars[2...3]))
        let b = Int(hex: String(chars[4...5]))
        
        self.init(
            red:   CGFloat(CGFloat(r) / 255.0),
            green: CGFloat(CGFloat(g) / 255.0),
            blue:  CGFloat(CGFloat(b) / 255.0),
            alpha: 1.0)
    }
    
}
