import Foundation

func getInputItems() -> [String]? {
    let stdinHandle = NSFileHandle.fileHandleWithStandardInput()
    let inputData = stdinHandle.readDataToEndOfFile()
    
    let inputString = NSString(data: inputData, encoding: NSUTF8StringEncoding)
    if inputString == nil { return nil }
    
    let trimmedInput = inputString!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
    if countElements(trimmedInput) == 0 { return nil }
    
    return trimmedInput.componentsSeparatedByString("\n")
}

func writeOutput(str: String) {
    if let data = (str as NSString).dataUsingEncoding(NSUTF8StringEncoding) {
        NSFileHandle.fileHandleWithStandardOutput().writeData(data)
    }
}
