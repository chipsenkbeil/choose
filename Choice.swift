import Cocoa

class Choice {
    
    let normalized: String
    let raw: String
    let indexSet = NSMutableIndexSet()
    let displayString: NSMutableAttributedString
    
    var hasAllCharacters = false
    var score = 0
    
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
        score = 0
        hasAllCharacters = false
        indexSet.removeAllIndexes()
        
        var queryChars = reverse(query).generate()
        var queryChar = queryChars.next() // let's assume it's non-nil to start with
        for (i, choiceChar) in reverse(Array(enumerate(normalized))) {
            if choiceChar == queryChar {
                indexSet.addIndex(i)
                queryChar = queryChars.next()
                if queryChar == nil {
                    // good! we're done here; let's go.
                    break
                }
            }
        }
        
        hasAllCharacters = queryChar != nil // i.e., the full query string wasn't matched
        
        if !hasAllCharacters || indexSet.count == 0 {
            return
        }
        
        var numRanges: Int = 0
        var lengthScore: Int = 0
        
        // to be honest, this is probably the stupidest scoring algorithm ever invented.
        // maybe someone who knows what they're doing should rewrite it ;)
        
        indexSet.enumerateRangesUsingBlock { range, stop in
            numRanges++
            lengthScore += range.length * 100
        }
        
        lengthScore /= numRanges
        
        let percentScore = Double(indexSet.count / countElements(normalized)) * 100.0
        
        score = lengthScore + Int(percentScore)
    }
    
}
