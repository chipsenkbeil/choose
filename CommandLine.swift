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
    
    mutating func ohWaitGoBackOne() {
        index--
    }
    
    var remainder: [T] {
        return Array(elements[index..<elements.count])
    }
    
}

class CommandLine {
    
    private enum State {
        case ReadyForFlagOrArgs
        case ReadingFlagCharacter
        case JustFinishedValuelessFlag
        case InsideValue
        case Error
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
        
        func asChar() -> Character? {
            switch self {
            case let Char(c): return c
            default: return nil
            }
        }
        
        func isGap() -> Bool {
            switch self {
            case Gap: return true
            default: return false
            }
        }
    }
    
    class func parse(#usage: String -> String, flags: [Character:Flag], done: [String] -> ()) {
        let rawargs = (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
        let program = rawargs.first!
//        let args = Array(dropFirst(rawargs))
        let args = ["-if", "foo", "bar", "quux arg with spaces"]
        
        let charArrays = args.map{Array($0)}
        let tokenArrays: [[Token]] = charArrays.map{$0.map{.Char($0)}}
        
        var state: State = .ReadyForFlagOrArgs
        var tokens = FlexGenerator([.Gap].join(tokenArrays))
        
        var accumulatedValue = ""
        var lastHandler: Flag?
        
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
        
        ParseLoop: while true {
            let c = tokens.next()
            
            switch state {
            case .ReadyForFlagOrArgs:
                switch c {
                case .Some(.Char("-")):
                    state = .ReadingFlagCharacter
                default:
                    break ParseLoop
                }
            case .ReadingFlagCharacter:
                switch c {
                case let .Some(.Char(c)):
                    if let flag = flags[c] {
                        if flag.needsArg() {
                            state = .InsideValue
                            lastHandler = flag
                            accumulatedValue = ""
                        }
                        else {
                            handle(flag, "")
                            state = .JustFinishedValuelessFlag
                        }
                    }
                    else {
                        state = .Error
                        break ParseLoop
                    }
                default:
                    state = .Error
                    break ParseLoop
                }
            case .JustFinishedValuelessFlag:
                switch c {
                case let .Some(.Char(c)):
                    break
                default:
                    break
                }
            case .InsideValue:
                switch c {
                case let .Some(.Char(c)):
                    accumulatedValue.append(c)
                default:
                    if let handler = lastHandler {
                        handle(handler, accumulatedValue)
                        lastHandler = nil
                    }
                }
            case .Error:
                break // should be impossible
            }
        }
        
        if state == .Error {
            return
        }
        
        // we can be sure remainder are args now!
        
        let splits = split(tokens.remainder, { $0.isGap() })
        let strs = splits.map{$0.map{map($0.asChar(), {$0!})}}
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
