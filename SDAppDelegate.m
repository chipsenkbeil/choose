// Add near top of file, after imports and global declarations
NSScreen *RequestedScreen = nil;

NSScreen *findScreen(NSString *monitorArg) {
    // Try index
    NSInteger idx = [monitorArg integerValue];
    NSArray<NSScreen *> *screens = [NSScreen screens];
    if ([monitorArg isEqualToString:[NSString stringWithFormat:"%ld", idx]] && idx >= 0 && idx < (NSInteger)[screens count]) {
        return screens[idx];
    }
    // Try by display ID
    for (NSScreen *screen in screens) {
        NSDictionary *desc = [screen deviceDescription];
        NSNumber *displayIDKey = [desc objectForKey:@"NSScreenNumber"]; 
        if (displayIDKey && [monitorArg isEqualToString:[displayIDKey stringValue]]) {
            return screen;
        }
    }
    // Try by localized name, if available (macOS 10.15+)
    for (NSScreen *screen in screens) {
        if ([screen respondsToSelector:@selector(localizedName)]) {
            NSString *name = [screen performSelector:@selector(localizedName)];
            if ([monitorArg isEqualToString:name]) {
                return screen;
            }
        }
    }
    // fallback: nil means default
    return nil;
}

// In main() argument parsing:
int ch;
NSString *monitorArg = nil;
// "-M:" added to getopt options string
while ((ch = getopt(argc, (char**)argv, "lvyezaf:s:r:c:b:n:w:p:q:r:t:x:o:M:Phium1WSC:")) != -1) {
    switch (ch) {
        // ... other cases ...
        case 'M':
            monitorArg = [NSString stringWithUTF8String:optarg];
            break;
        // ... other cases ...
    }
}
if (monitorArg) {
    RequestedScreen = findScreen(monitorArg);
}

// When setting up the window/display:
NSScreen *targetScreen = RequestedScreen ? RequestedScreen : [NSScreen mainScreen];
NSRect winRect = [targetScreen frame];
[self setupWindow: winRect];
// ... continue as before ...