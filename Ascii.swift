import Foundation

extension Int {
    
    init?(ascii: Character) {
        var s = String(ascii).unicodeScalars.generate()
        let u = s.next()!
        if u.isASCII() {
            self = Int(u.value)
        }
        else {
            return nil
        }
    }
    
}
