import Foundation

class CommandLine {
    
    class func parse(#usage: String -> String, flags: [String:Flag], done: () -> ()) {
        let rawargs = (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
        let program = rawargs.first!
        let args = Array(dropFirst(rawargs))
        
        
        
    }
    
    enum Flag {
        case V(Void -> Void)
        case S(String -> Void)
        case I(Int -> Void)
        case D(Double -> Void)
        case Usage
        
        func handle(value: String) {
            switch self {
            case let .V(fn): fn()
            case let .S(fn): fn(value)
            case let .I(fn): fn((value as NSString).integerValue)
            case let .D(fn): fn((value as NSString).doubleValue)
            case .Usage: break
            }
        }
        
        func isUsage() -> Bool {
            switch self {
            case .Usage: return true
            default: return false
            }
        }
        
        func needsArg() -> Bool {
            switch self {
            case let .S, .I, .D: return true
            default: return false
            }
        }
    }
    
}
