import Foundation

private struct FlexGenerator<T> {
    
    let elements: [T]
    var index = 0
    
    init(_ e: [T]) {
        elements = e
    }
    
    mutating func next() -> T? {
        if index == elements.endIndex {
            return nil
        }
        else {
            return elements[index++]
        }
    }
    
    mutating func ohWaitGoBack() {
        index--
    }
    
}

class CommandLine {
    
    private enum State {
        case Ready
        case Flag
        case Arg
        case FinishedSoleFlag
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
    
    class func parse(#usage: String -> String, flags: [Character:Flag], done: [String] -> ()) {
        let rawargs = (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
        let program = rawargs.first!
//        let args = Array(dropFirst(rawargs))
        let args = ["-if", "foo", "bar"]
        
        let charArrays = args.map{Array($0)}
        let tokenArrays: [[Token]] = charArrays.map{$0.map{.Char($0)}}
        
        var tokens = FlexGenerator([.Gap].join(tokenArrays))
        var state: State = .Ready
        
        let showUsage: () -> () = {
            println(usage(program))
            exit(0)
        }
        
        func handle(flag: Flag, value: String) {
            switch flag {
            case let .V(fn): fn()
            case let .S(fn): fn(value)
            case let .I(fn): fn((value as NSString).integerValue)
            case let .D(fn): fn((value as NSString).doubleValue)
            case .Usage: showUsage()
            }
        }
        
        Loop: while true {
            let c = tokens.next()
            
            switch state {
            case .Ready:
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
                case let .Some(.Char(x)):
                    if let flag = flags[x] {
                        if flag.needsArg() {
                            state = .Arg
                            // needs arg; store handler and call it later when you have one.
                        }
                        else {
                            handle(flag, "")
                            state = .FinishedSoleFlag
                            // doesn't need arg; call immediately and be done with this flag
                        }
                    }
                    else {
                        // error: didn't find match!
                        showUsage()
                    }
                default:
                    break
                }
                
                // uhh
                break
            case .Arg:
                // uhh
                break
            case .FinishedSoleFlag:
                switch c {
                case let .Some(.Char(x)):
                    if let flag = flags[x] {
                        // it's another flag!!! handle it!
                    }
                    else {
                        tokens.ohWaitGoBack()
                    }
                    break
                default:
                    // uhh
                    break
                }
            }
        }
    }
    
    enum Flag {
        case V(Void -> Void)
        case S(String -> Void)
        case I(Int -> Void)
        case D(Double -> Void)
        case Usage
        
        func needsArg() -> Bool {
            switch self {
            case let .S, .I, .D: return true
            default: return false
            }
        }
    }
    
}
