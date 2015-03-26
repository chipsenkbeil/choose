import Foundation

let chooser = Chooser()

class Chooser {
    
    var choices = [Choice]()
    var filteredSortedChoices = [Choice]()
    var choice = 0
    
    func ensureHasItems() {
        let inputItems = getStdinLines()
        if inputItems == nil { cancel() }
        
        choices = inputItems!.map{Choice($0)}
    }
    
    func cancel() {
        if useIndexes {
            writeOutput("-1")
        }
        
        exit(1)
    }
    
    func pickIndex(index: Int) {
        if index >= filteredSortedChoices.count { return }
        
        choice = index
        choose()
    }
    
    func choose() {
        if filteredSortedChoices.count == 0 { cancel() }
        
        let chosen = filteredSortedChoices[choice]
        let outputString = useIndexes ? "\(find(choices, chosen)!)" : chosen.raw
        writeOutput(outputString)
        exit(0)
    }
    
    func runQuery(query: String) {
        
        // analyze (cache)
        for choice in choices {
            choice.analyze(query)
        }
        
        // filter and sort matches
        if countElements(query) > 0 {
            filteredSortedChoices = choices
                .filter{ $0.hasAllCharacters }
                .sorted{ a, b in a.score < b.score }
        }
        
        // render remainder
        for choice in filteredSortedChoices {
            choice.render()
        }
        
        // push choice back to start
        choice = 0
    }
    
    func getStdinLines() -> [String]? {
        #if DEBUG
            return ["foo", "bar", "baz", "quux"]
            #else
            let stdinHandle = NSFileHandle.fileHandleWithStandardInput()
            let inputData = stdinHandle.readDataToEndOfFile()
            
            let inputString = NSString(data: inputData, encoding: NSUTF8StringEncoding)
            if inputString == nil { return nil }
            
            let trimmedInput = inputString!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            if countElements(trimmedInput) == 0 { return nil }
            
            return trimmedInput.componentsSeparatedByString("\n")
        #endif
    }
    
    func writeOutput(str: String) {
        if let data = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
            NSFileHandle.fileHandleWithStandardOutput().writeData(data)
        }
    }
    
}
