import Cocoa

class Choice {
    
    let normalized: String
    let raw: String
    let indexSet = NSMutableIndexSet()
    let displayString: NSMutableAttributedString
    
    var hasAllCharacters = false
    let score = 0
    
    init(str: String) {
        raw = str
        normalized = str.lowercaseString
        displayString = NSMutableAttributedString(string: raw)
    }
    
    func render() {
        let len = countElements(normalized)
        let fullRange = NSRange(location: 0, length: len)
        
        displayString.removeAttribute(NSForegroundColorAttributeName, range: fullRange)
        displayString.removeAttribute(NSUnderlineColorAttributeName, range: fullRange)
        displayString.removeAttribute(NSUnderlineStyleAttributeName, range: fullRange)
        
        indexSet.enumerateIndexesUsingBlock { i, stop in
            let r = NSRange(location: i, length: 1)
            self.displayString.addAttribute(NSForegroundColorAttributeName, value: highlightColor, range: r)
            self.displayString.addAttribute(NSUnderlineColorAttributeName, value: highlightColor, range: r)
            self.displayString.addAttribute(NSUnderlineStyleAttributeName, value: 1, range: r)
        }
    }
    
    func analyze(query: String) {
        
        hasAllCharacters = false
        
        indexSet.removeAllIndexes()
        
        var lastPos = countElements(normalized) - 1
        
        var foundAll = true
        
        for var i = countElements(query) - 1; i >= 0; i-- {
            
            let qc = query[i]
            
        }
        
        
        // TODO
    }
    
}
