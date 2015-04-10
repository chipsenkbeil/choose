import Cocoa

class Shortcut: NSMenuItem {
    
    let fn: () -> ()
    
    enum Mod {
        case Command
        case Control
        case Option
        case Shift
        
        func toUInt() -> NSEventModifierFlags {
            switch self {
            case .Command: return NSEventModifierFlags.CommandKeyMask
            case .Control: return NSEventModifierFlags.ControlKeyMask
            case .Option:  return NSEventModifierFlags.AlternateKeyMask
            case .Shift:   return NSEventModifierFlags.ShiftKeyMask
            }
        }
    }
    
    init(key: String, mods: [Mod], fn: () -> ()) {
        self.fn = fn
        super.init(title: "", action: "", keyEquivalent: "")
        target = self
        action = "callFn:"
        keyEquivalent = key
        keyEquivalentModifierMask = mods.map{ Int($0.toUInt().rawValue) }.reduce(0, combine: |)
    }
    
    func callFn(sender: AnyObject!) {
        fn()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
