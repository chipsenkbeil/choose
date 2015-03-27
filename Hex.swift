import Foundation

extension Int {
    
    init?(hex: Character) {
        switch hex {
        case "0"..."9": self = Int(ascii: hex)! - Int(ascii: "0")!
        case "a"..."f": self = Int(ascii: hex)! - Int(ascii: "a")! + 10
        case "A"..."F": self = Int(ascii: hex)! - Int(ascii: "A")! + 10
        default: return nil
        }
    }
    
    init?(hex: String) {
        self = 0
        var base = 1
        
        for char in reverse(hex) {
            if let x = Int(hex: char) {
                self += (x * base)
                base *= 16
            }
            else {
                return nil
            }
        }
    }
    
}
