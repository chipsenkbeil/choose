import Foundation

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
        case "a", "A": self = 10
        case "b", "B": self = 11
        case "c", "C": self = 12
        case "d", "D": self = 13
        case "e", "E": self = 14
        case "f", "F": self = 15
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
