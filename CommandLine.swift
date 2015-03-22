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
            case let .Char(c): return "<char: \(c)>"
            case Gap: return "<gap>"
            }
        }
    }
    
    class func parse(#usage: String -> String, flags: [String:Flag], done: [String] -> ()) {
        let rawargs = (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
        let program = rawargs.first!
//        let args = Array(dropFirst(rawargs))
        let args = ["-if", "foo", "bar"]
        
        let charArrays = args.map{Array($0)}
        let tokenArrays: [[Token]] = charArrays.map{$0.map{.Char($0)}}
        
        var tokens = [.Gap].join(tokenArrays).generate()
        var state: State = .Anything
        
        Loop: while true {
            let c = tokens.next()
            
            switch state {
            case .Anything:
                switch c {
                case .None:
                    // we hit the end!
                    break Loop
                case .Some(.Char("-")):
                    state = .Flag
                case .Some(.Gap):
                    // ok, we're done; the rest are arguments
                    break
                default:
                    // ok, we're done; this begins the arguments
                    break
                }
            case .Flag:
                switch c {
                case .None:
                    // this is an error! i think?
                    break
                default:
                    break
                }
                
                // uhh
                break
            case .Arg:
                // uhh
                break
            }
        }
        
        /*
        if in "flag" state
        
        read one char.
        
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
