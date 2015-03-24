import Foundation

let chooser = Chooser()

class Chooser {
    
    var choices = [Choice]()
    
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
    
}
