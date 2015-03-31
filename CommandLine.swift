import Foundation

private struct BiDirectionalEnumerator<T> {
    
    let elements: [T]
    var index = 0
    
    init(_ e: [T]) {
        elements = e
    }
    
    mutating func move(by: Int = 1) {
        index += by
    }
    
    func get() -> T? {
        if index >= elements.endIndex {
            return nil
        }
        else {
            return elements[index]
        }
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
        
        static func strings(tokens: [Token]) -> [String] {
            let splits = split(tokens, { $0.isGap() })
            return splits.map{String($0.map{$0.asChar()!})}
        }
    }
    
    private let usage: String -> ()
    private let flags: [Character:Flag]
    private let done: [String] -> ()
    private let arguments: [String]
    
    init(usage: String -> (), flags: [Character:Flag], done: [String] -> (), arguments: [String]? = nil) {
        self.usage = usage
        self.flags = flags
        self.done = done
        self.arguments = arguments ?? (0..<Int(C_ARGC)).map{ String(UTF8String: C_ARGV[$0])! }
    }
    
    func parse() {
        done([])
        return;
        
        let program = arguments.first!
        let args = Array(dropFirst(arguments))
        
        let charArrays = args.map{Array($0)}
        let tokenArrays: [[Token]] = charArrays.map{$0.map{.Char($0)}}
        
        var state: State = .ReadyForFlagOrArgs
        var tokens = BiDirectionalEnumerator([.Gap].join(tokenArrays))
        
        var accumulatedValue = ""
        var lastHandler: Flag?
        
        func handle(flag: Flag, value: String) {
            switch flag {
            case let .V(fn): fn()
            case let .S(fn): fn(value)
            case let .I(fn): fn((value as NSString).integerValue)
            case let .D(fn): fn((value as NSString).doubleValue)
            case .Usage: usage(program)
            }
        }
        
        println([.Gap].join(tokenArrays))
        
        ParseLoop: while true {
            let c = tokens.get()
            
            switch state {
            case .ReadyForFlagOrArgs:
                switch c {
                case .Some(.Char("-")):
                    state = .ReadingFlagCharacter
                    continue
                default:
                    tokens.move(by: -1)
                    break ParseLoop
                }
            case .ReadingFlagCharacter:
                println("handing flag \(c)")
                switch c {
                case let .Some(.Char(c)):
                    if let flag = flags[c] {
                        if flag.needsArg() {
                            state = .InsideValue
                            lastHandler = flag
                            accumulatedValue = ""
                        }
                        else {
                            println("calling handler")
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
                assertionFailure("uhh, this should be impossible")
            }
            
//            switch state {
//            case .ReadyForFlagOrArgs:
//                switch c {
//                case .Some(.Char("-")):
//                    state = .ReadingFlagCharacter
//                    continue
//                default:
//                    tokens.move(by: -1)
//                    break ParseLoop
//                }
//            case .ReadingFlagCharacter:
//                println("handing flag \(c)")
//                switch c {
//                case let .Some(.Char(c)):
//                    if let flag = flags[c] {
//                        if flag.needsArg() {
//                            state = .InsideValue
//                            lastHandler = flag
//                            accumulatedValue = ""
//                        }
//                        else {
//                            println("calling handler")
//                            handle(flag, "")
//                            state = .JustFinishedValuelessFlag
//                        }
//                    }
//                    else {
//                        state = .Error
//                        break ParseLoop
//                    }
//                default:
//                    state = .Error
//                    break ParseLoop
//                }
//            case .JustFinishedValuelessFlag:
//                switch c {
//                case let .Some(.Char(c)):
//                    break
//                default:
//                    break
//                }
//            case .InsideValue:
//                switch c {
//                case let .Some(.Char(c)):
//                    accumulatedValue.append(c)
//                default:
//                    if let handler = lastHandler {
//                        handle(handler, accumulatedValue)
//                        lastHandler = nil
//                    }
//                }
//            case .Error:
//                assertionFailure("uhh, this should be impossible")
//            }
            
            tokens.move(by: 1)
        }
        
        println("done: \(Token.strings(tokens.remainder))")
        
        if state == .Error {
            assertionFailure("error parsing arguments somehow")
        }
        else {
            done(Token.strings(tokens.remainder))
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
