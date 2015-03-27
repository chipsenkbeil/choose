import Cocoa

extension NSColor {
    
    convenience init(hex: String) {
        let chars = Array(hex)
        
        switch chars.count {
        case 2:
            let w = Int(hex: String(chars[0...1]))!
            
            self.init(
                white: CGFloat(CGFloat(w) / 255.0),
                alpha: 1)
        case 6:
            let r = Int(hex: String(chars[0...1]))!
            let g = Int(hex: String(chars[2...3]))!
            let b = Int(hex: String(chars[4...5]))!
            
            self.init(
                red:   CGFloat(CGFloat(r) / 255.0),
                green: CGFloat(CGFloat(g) / 255.0),
                blue:  CGFloat(CGFloat(b) / 255.0),
                alpha: 1)
        default:
            self.init(white: 0, alpha: 1)
        }
    }
    
}
