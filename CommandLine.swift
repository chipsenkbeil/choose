import Foundation

class CommandLine {
    
    private enum State {
        case Anything
        case Flag
        case Arg
    }
    
    private enum Token: Printable {
        case Char(Character)
        case Gap
        
        var description : String {
            switch self {
            case let .Char(c): return String(c)
            case Gap: return "(gap)"
            }
        }
    }
    
    class func parse(#usage: String -> String, flags: [String:Flag], done: [String] -> ()) {
        let rawargs = (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
        let program = rawargs.first!
//        let args = Array(dropFirst(rawargs))
        let args = ["-xi", "foo", "bar"]
        
        let charArrays = args.map{Array($0)}
        let tokenArrays: [[Token]] = charArrays.map{$0.map{.Char($0)}}
        let tokens = [.Gap].join(tokenArrays)
        
        println(tokens)
        
        let state: State = .Anything
        
        
        
        
        
        
        /*
        
        
        if in "anything" state:
        
        read one char.
        
        - when "-", move forward 1, put in "flag" state
        - when anything else, stop here, remainder are arguments
        
        if in "flag" state
        
        read one char.
        
        - if EOF, do error
        - if doesn't match existing flag, do error
        - if matches, run flag handler, and:
        
        - if needs arg, put in "arg" state
        - if not, put in "anything" state
        
        
        
        */
        
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
