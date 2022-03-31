#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>

#define NSApp [NSApplication sharedApplication]

/******************************************************************************/
/* User Options                                                               */
/******************************************************************************/

static NSColor* SDHighlightColor;
static NSColor* SDHighlightBackgroundColor;
static BOOL SDReturnsIndex;
static NSFont* SDQueryFont;
static int SDNumRows;
static int SDPercentWidth;
static BOOL SDUnderlineDisabled;
static BOOL SDReturnStringOnMismatch;

/******************************************************************************/
/* Boilerplate Subclasses                                                     */
/******************************************************************************/


@interface NSApplication (ShutErrorsUp)
@end
@implementation NSApplication (ShutErrorsUp)
- (void) setColorGridView:(id)view {}
- (void) setView:(id)view {}
@end


@interface SDTableView : NSTableView
@end
@implementation SDTableView

- (BOOL) acceptsFirstResponder { return NO; }
- (BOOL) becomeFirstResponder  { return NO; }
- (BOOL) canBecomeKeyView      { return NO; }

@end


@interface SDMainWindow : NSWindow
@end
@implementation SDMainWindow

- (BOOL) canBecomeKeyWindow  { return YES; }
- (BOOL) canBecomeMainWindow { return YES; }

@end

/******************************************************************************/
/* Choice                                                                     */
/******************************************************************************/

@interface SDChoice : NSObject

@property NSString* normalized;
@property NSString* raw;
@property NSMutableIndexSet* indexSet;
@property NSMutableAttributedString* displayString;

@property BOOL hasAllCharacters;
@property int score;

@end

@implementation SDChoice

- (id) initWithString:(NSString*)str {
    if (self = [super init]) {
        self.raw = str;
        self.normalized = [self.raw lowercaseString];
        self.indexSet = [NSMutableIndexSet indexSet];
        self.displayString = [[NSMutableAttributedString alloc] initWithString:self.raw attributes:nil];
    }
    return self;
}

- (void) render {

#ifdef DEBUG
    // for testing
    [self.displayString deleteCharactersInRange:NSMakeRange(0, [self.displayString length])];
    [[self.displayString mutableString] appendString:self.raw];
    [[self.displayString mutableString] appendFormat:@" [%d]", self.score];
#endif


    NSUInteger len = [self.normalized length];
    NSRange fullRange = NSMakeRange(0, len);

    [self.displayString removeAttribute:NSForegroundColorAttributeName range:fullRange];

    if (SDUnderlineDisabled) {
        [self.displayString removeAttribute:NSBackgroundColorAttributeName range:fullRange];
    }
    else {
        [self.displayString removeAttribute:NSUnderlineColorAttributeName range:fullRange];
        [self.displayString removeAttribute:NSUnderlineStyleAttributeName range:fullRange];
    }

    [self.indexSet enumerateIndexesUsingBlock:^(NSUInteger i, BOOL *stop) {
        if (SDUnderlineDisabled) {
            [self.displayString addAttribute:NSBackgroundColorAttributeName value:[SDHighlightColor colorWithAlphaComponent:0.8] range:NSMakeRange(i, 1)];
        }
        else {
            [self.displayString addAttribute:NSForegroundColorAttributeName value:SDHighlightColor range:NSMakeRange(i, 1)];
            [self.displayString addAttribute:NSUnderlineColorAttributeName value:SDHighlightColor range:NSMakeRange(i, 1)];
            [self.displayString addAttribute:NSUnderlineStyleAttributeName value:@1 range:NSMakeRange(i, 1)];
        }
    }];
}

- (void) analyze:(NSString*)query {

    // TODO: might not need this variable?
    self.hasAllCharacters = NO;

    [self.indexSet removeAllIndexes];

    NSUInteger itemLength = [self.normalized length];
    NSUInteger lastPos = 0;
    BOOL foundAll = YES;
    for (NSInteger i = 0; i < [query length]; i++) {
        unichar qc = [query characterAtIndex: i];
        BOOL found = NO;
        for (NSInteger ii = lastPos; ii < itemLength; ii++) {
            unichar rc = [self.normalized characterAtIndex: ii];
            
            if (qc == rc) {
                [self.indexSet addIndex: ii];
                lastPos = ii+1;
                found = YES;
                break;
            }
        }
        if (!found) {
            foundAll = NO;
            break;
        }
    }

    self.hasAllCharacters = foundAll;

    // skip the rest when it won't be used by the caller
    if (!self.hasAllCharacters)
        return;

    // update score

    self.score = 0;

    if ([self.indexSet count] == 0)
        return;

    __block int lengthScore = 0;
    __block int numRanges = 0;

    [self.indexSet enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        numRanges++;
        lengthScore += (range.length * 100);
    }];

    lengthScore /= numRanges;

    int percentScore = ((double)[self.indexSet count] / (double)[self.normalized length]) * 100.0;

    self.score = lengthScore + percentScore;
}

@end

/******************************************************************************/
/* App Delegate                                                               */
/******************************************************************************/

@interface SDAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

// internal
@property NSWindow* window;
@property NSArray* choices;
@property NSMutableArray* filteredSortedChoices;
@property NSMutableArray* filteredSortedChoicesFromFzf;
@property SDTableView* listTableView;
@property NSTextField* queryField;
@property NSInteger choice;

@end

@implementation SDAppDelegate

/******************************************************************************/
/* Starting the app                                                           */
/******************************************************************************/

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
    NSArray* inputItems = [self getInputItems];
//    NSLog(@"%ld", [inputItems count]);
//    NSLog(@"%@", inputItems);

    if ([inputItems count] < 1)
        [self cancel];

    [NSApp activateIgnoringOtherApps: YES];

    self.choices = [self choicesFromInputItems: inputItems];

    NSRect winRect, textRect, dividerRect, listRect;
    [self getFrameForWindow: &winRect queryField: &textRect divider: &dividerRect tableView: &listRect];

    [self setupWindow: winRect];
    [self setupQueryField: textRect];
    [self setupDivider: dividerRect];
    [self setupResultsTable: listRect];
    [self runQuery: @""];
    [self resizeWindow];
    [self.window center];
    [self.window makeKeyAndOrderFront: nil];

    // these even work inside NSAlert, so start them later
    [self setupKeyboardShortcuts];
}

/******************************************************************************/
/* Setting up GUI elements                                                    */
/******************************************************************************/

- (void) setupWindow:(NSRect)winRect {
    BOOL usingYosemite = (NSClassFromString(@"NSVisualEffectView") != nil);

    NSUInteger styleMask = usingYosemite ? (NSFullSizeContentViewWindowMask | NSTitledWindowMask) : NSBorderlessWindowMask;
    self.window = [[SDMainWindow alloc] initWithContentRect: winRect
                                                  styleMask: styleMask
                                                    backing: NSBackingStoreBuffered
                                                      defer: NO];

    [self.window setDelegate: self];

    if (usingYosemite) {
        self.window.titlebarAppearsTransparent = YES;
        NSVisualEffectView* blur = [[NSVisualEffectView alloc] initWithFrame: [[self.window contentView] bounds]];
        [blur setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable ];
        blur.material = NSVisualEffectMaterialMenu;
        blur.state = NSVisualEffectBlendingModeBehindWindow;
        [[self.window contentView] addSubview: blur];
    }
}

- (void) setupQueryField:(NSRect)textRect {
    NSRect iconRect, space;
    NSDivideRect(textRect, &iconRect, &textRect, NSHeight(textRect) / 1.25, NSMinXEdge);
    NSDivideRect(textRect, &space, &textRect, 5.0, NSMinXEdge);

    CGFloat d = NSHeight(iconRect) * 0.10;
    iconRect = NSInsetRect(iconRect, d, d);

    NSImageView* icon = [[NSImageView alloc] initWithFrame: iconRect];
    [icon setAutoresizingMask: NSViewMaxXMargin | NSViewMinYMargin ];
    [icon setImage: [NSImage imageNamed:  NSImageNameRightFacingTriangleTemplate]];
    [icon setImageScaling: NSImageScaleProportionallyDown];
//    [icon setImageFrameStyle: NSImageFrameButton];
    [[self.window contentView] addSubview: icon];

    self.queryField = [[NSTextField alloc] initWithFrame: textRect];
    [self.queryField setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin ];
    [self.queryField setDelegate: self];
    [self.queryField setBezelStyle: NSTextFieldSquareBezel];
    [self.queryField setBordered: NO];
    [self.queryField setDrawsBackground: NO];
    [self.queryField setFocusRingType: NSFocusRingTypeNone];
    [self.queryField setFont: SDQueryFont];
    [self.queryField setEditable: YES];
    [self.queryField setTarget: self];
    [self.queryField setAction: @selector(choose:)];
    [[self.queryField cell] setSendsActionOnEndEditing: NO];
    [[self.window contentView] addSubview: self.queryField];
}

- (void) getFrameForWindow:(NSRect*)winRect queryField:(NSRect*)textRect divider:(NSRect*)dividerRect tableView:(NSRect*)listRect {
    *winRect = NSMakeRect(0, 0, 100, 100);
    NSRect contentViewRect = NSInsetRect(*winRect, 10, 10);
    NSDivideRect(contentViewRect, textRect, listRect, NSHeight([SDQueryFont boundingRectForFont]), NSMaxYEdge);
    NSDivideRect(*listRect, dividerRect, listRect, 20.0, NSMaxYEdge);
    dividerRect->origin.y += NSHeight(*dividerRect) / 2.0;
    dividerRect->size.height = 1.0;
}

- (void) setupDivider:(NSRect)dividerRect {
    NSBox* border = [[NSBox alloc] initWithFrame: dividerRect];
    [border setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin ];
    [border setBoxType: NSBoxCustom];
    [border setFillColor: [NSColor systemGrayColor]];
    [border setBorderWidth: 0.0];
    [[self.window contentView] addSubview: border];
}

- (void) setupResultsTable:(NSRect)listRect {
    NSFont* rowFont = [NSFont fontWithName:[SDQueryFont fontName] size: [SDQueryFont pointSize] * 0.70];

    NSTableColumn *col = [[NSTableColumn alloc] initWithIdentifier:@"thing"];
    [col setEditable: NO];
    [col setWidth: 10000];
    [[col dataCell] setFont: rowFont];

    NSTextFieldCell* cell = [col dataCell];
    [cell setLineBreakMode: NSLineBreakByCharWrapping];

    self.listTableView = [[SDTableView alloc] init];
    [self.listTableView setDataSource: self];
    [self.listTableView setDelegate: self];
    [self.listTableView setBackgroundColor: [NSColor clearColor]];
    [self.listTableView setHeaderView: nil];
    [self.listTableView setAllowsEmptySelection: NO];
    [self.listTableView setAllowsMultipleSelection: NO];
    [self.listTableView setAllowsTypeSelect: NO];
    [self.listTableView setRowHeight: NSHeight([rowFont boundingRectForFont]) * 1.2];
    [self.listTableView addTableColumn:col];
    [self.listTableView setTarget: self];
    [self.listTableView setDoubleAction: @selector(chooseByDoubleClicking:)];
    [self.listTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];

    NSScrollView* listScrollView = [[NSScrollView alloc] initWithFrame: listRect];
    [listScrollView setVerticalScrollElasticity: NSScrollElasticityNone];
    [listScrollView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable ];
    [listScrollView setDocumentView: self.listTableView];
    [listScrollView setDrawsBackground: NO];
    [[self.window contentView] addSubview: listScrollView];
}

- (NSArray*) choicesFromInputItems:(NSArray*)inputItems {
    NSMutableArray* choices = [NSMutableArray array];
    for (NSString* inputItem in inputItems) {
        if ([inputItem length] > 0) {
            [choices addObject: [[SDChoice alloc] initWithString: inputItem]];
        }
    }
    return [choices copy];
}

- (void) resizeWindow {
    NSRect screenFrame = [[NSScreen mainScreen] visibleFrame];

    CGFloat rowHeight = [self.listTableView rowHeight];
    CGFloat intercellHeight =[self.listTableView intercellSpacing].height;
    CGFloat allRowsHeight = (rowHeight + intercellHeight) * SDNumRows;

    CGFloat windowHeight = NSHeight([[self.window contentView] bounds]);
    CGFloat tableHeight = NSHeight([[self.listTableView superview] frame]);
    CGFloat finalHeight = (windowHeight - tableHeight) + allRowsHeight;

    CGFloat width;
    if (SDPercentWidth >= 0 && SDPercentWidth <= 100) {
        CGFloat percentWidth = (CGFloat)SDPercentWidth / 100.0;
        width = NSWidth(screenFrame) * percentWidth;
    }
    else {
        width = NSWidth(screenFrame) * 0.50;
        width = MIN(width, 800);
        width = MAX(width, 400);
    }

    NSRect winRect = NSMakeRect(0, 0, width, finalHeight);
    [self.window setFrame:winRect display:YES];
}

- (void) setupKeyboardShortcuts {
    __weak id _self = self;
    [self addShortcut:@"1" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 0]; }];
    [self addShortcut:@"2" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 1]; }];
    [self addShortcut:@"3" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 2]; }];
    [self addShortcut:@"4" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 3]; }];
    [self addShortcut:@"5" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 4]; }];
    [self addShortcut:@"6" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 5]; }];
    [self addShortcut:@"7" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 6]; }];
    [self addShortcut:@"8" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 7]; }];
    [self addShortcut:@"9" mods:NSCommandKeyMask handler:^{ [_self pickIndex: 8]; }];
    [self addShortcut:@"q" mods:NSCommandKeyMask handler:^{ [_self cancel]; }];
    [self addShortcut:@"a" mods:NSCommandKeyMask handler:^{ [_self selectAll: nil]; }];
    [self addShortcut:@"c" mods:NSControlKeyMask handler:^{ [_self cancel]; }];
    [self addShortcut:@"g" mods:NSControlKeyMask handler:^{ [_self cancel]; }];
}

/******************************************************************************/
/* Table view                                                                 */
/******************************************************************************/

- (void) reflectChoice {
    [self.listTableView selectRowIndexes:[NSIndexSet indexSetWithIndex: self.choice] byExtendingSelection:NO];
    [self.listTableView scrollRowToVisible: self.choice];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.filteredSortedChoices count];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    SDChoice* choice = [self.filteredSortedChoices objectAtIndex: row];
    return choice.displayString;
}

- (void) tableViewSelectionDidChange:(NSNotification *)notification {
    self.choice = [self.listTableView selectedRow];
}

- (void) tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
    if ([[aTableView selectedRowIndexes] containsIndex:rowIndex])
        [aCell setBackgroundColor: [SDHighlightBackgroundColor colorWithAlphaComponent: 0.5]];
    else
        [aCell setBackgroundColor: [NSColor clearColor]];

    [aCell setDrawsBackground:YES];
}

/******************************************************************************/
/* Filtering!                                                                 */
/******************************************************************************/

- (void) runQuery:(NSString*)query {
    query = [query lowercaseString];

    self.filteredSortedChoices = [self.choices mutableCopy];
    
    NSMutableArray *mapped = [NSMutableArray arrayWithCapacity:[self.filteredSortedChoices count]];
    [self.filteredSortedChoices enumerateObjectsUsingBlock:^(SDChoice *obj, NSUInteger idx, BOOL *stop) {
        [mapped addObject:obj.raw];
    }];
    NSString * combinedStuff = [mapped componentsJoinedByString:@"\n"];
    
    self.filteredSortedChoicesFromFzf = [self executeFzfOnOptions: combinedStuff fzfQuery:query];
    
    for (SDChoice* choice in [self.filteredSortedChoices copy]) {
        BOOL identicalStringFound = NO;
        for (NSString *someString in self.filteredSortedChoicesFromFzf) {
            if ([someString isEqualToString:choice.raw]) {
                identicalStringFound = YES;
                break;
            }
        }
        if (!identicalStringFound)
            [self.filteredSortedChoices removeObject: choice];
    }

    // analyze (cache)
    for (SDChoice* choice in self.filteredSortedChoices)
        [choice analyze: query];

    // render remainder
    for (SDChoice* choice in self.filteredSortedChoices)
        [choice render];

    // show!
    [self.listTableView reloadData];

    // push choice back to start
    self.choice = 0;
    [self reflectChoice];
}

- (NSMutableArray *)executeFzfOnOptions:(NSString *)options fzfQuery:(NSString *)query
{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/bin/zsh"];
    
    NSArray *arguments = [NSArray arrayWithObjects: @"-c",
                          [NSString stringWithFormat:@"echo \"%@\" | fzf --reverse --exact --filter \"%@\"", options, query], nil];

    NSLog(@"run command: %@", options);
    [task setArguments:arguments];

    NSPipe *pipe = [NSPipe pipe];
    [task setStandardOutput:pipe];
    
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];

    NSFileHandle *file = [pipe fileHandleForReading];
    NSFileHandle *errorFile = [errorPipe fileHandleForReading];

    [task launch];

    NSData *data = [file readDataToEndOfFile];
    NSData *errorData = [errorFile readDataToEndOfFile];

    NSString *output = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSString *errorOutput = [[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding];
    NSLog(@"output of command: %@", output);
    NSLog(@"error output of command: %@", errorOutput);
    
    NSCharacterSet *separator = [NSCharacterSet newlineCharacterSet];
    return [[output componentsSeparatedByCharactersInSet:separator] copy];
}

/******************************************************************************/
/* Ending the app                                                             */
/******************************************************************************/

- (void) choose {
    if ([self.filteredSortedChoices count] == 0) {
        if (SDReturnStringOnMismatch) {
            [self writeOutput: [self.queryField stringValue]];
            exit(0);
        }
        exit(1);
    }

    if (SDReturnsIndex) {
        SDChoice* choice = [self.filteredSortedChoices objectAtIndex: self.choice];
        NSUInteger realIndex = [self.choices indexOfObject: choice];
        [self writeOutput: [NSString stringWithFormat:@"%ld", realIndex]];
    }
    else {
        SDChoice* choice = [self.filteredSortedChoices objectAtIndex: self.choice];
        [self writeOutput: choice.raw];
    }

    exit(0);
}

- (void) cancel {
    if (SDReturnsIndex) {
        [self writeOutput: [NSString stringWithFormat:@"%d", -1]];
    }

    exit(1);
}

- (void) applicationDidResignActive:(NSNotification *)notification {
    [self cancel];
}

- (void) pickIndex:(NSUInteger)idx {
    if (idx >= [self.filteredSortedChoices count])
        return;

    self.choice = idx;
    [self choose];
}

- (IBAction) choose:(id)sender {
    [self choose];
}

- (IBAction) chooseByDoubleClicking:(id)sender {
    NSInteger row = [self.listTableView clickedRow];
    if (row == -1)
        return;

    self.choice = row;
    [self choose];
}

/******************************************************************************/
/* Search field callbacks                                                     */
/******************************************************************************/

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector {
    if (commandSelector == @selector(cancelOperation:)) {
        if ([[self.queryField stringValue] length] > 0) {
            [textView moveToBeginningOfDocument: nil];
            [textView deleteToEndOfParagraph: nil];
        }
        else {
            [self cancel];
        }
        return YES;
    }
    else if (commandSelector == @selector(moveUp:)) {
        if (self.choice <= 0) {
            self.choice = [self.filteredSortedChoices count] - 1;
        } else {
            self.choice -= 1;
        }
        
        [self reflectChoice];
        return YES;
    }
    else if (commandSelector == @selector(moveDown:)) {
        if (self.choice >= [self.filteredSortedChoices count] - 1) {
            self.choice = 0;
        } else {
            self.choice += 1;
        }
        
        [self reflectChoice];
        return YES;
    }
    else if (commandSelector == @selector(insertTab:)) {
        [self.queryField setStringValue: [[self.filteredSortedChoices objectAtIndex: self.choice] raw]];
        [[self.queryField currentEditor] setSelectedRange: NSMakeRange(self.queryField.stringValue.length, 0)];
        return YES;
    }
    else if (commandSelector == @selector(deleteForward:)) {
        if ([[self.queryField stringValue] length] == 0)
            [self cancel];
    }

//    NSLog(@"[%@]", NSStringFromSelector(commandSelector));
    return NO;
}

- (void) controlTextDidChange:(NSNotification *)obj {
    [self runQuery: [self.queryField stringValue]];
}

- (IBAction) selectAll:(id)sender {
    NSTextView* editor = (NSTextView*)[self.window fieldEditor:NO forObject:self.queryField];
    [editor selectAll: sender];
}

/******************************************************************************/
/* Helpers                                                                    */
/******************************************************************************/

- (void) addShortcut:(NSString*)key mods:(NSEventModifierFlags)mods handler:(dispatch_block_t)action {
    static NSMutableArray* handlers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handlers = [NSMutableArray array];
    });

    id x = [NSEvent addLocalMonitorForEventsMatchingMask:NSKeyDownMask handler:^ NSEvent*(NSEvent* event) {
        NSEventModifierFlags flags = ([event modifierFlags] & NSDeviceIndependentModifierFlagsMask);
        if (flags == mods && [[event charactersIgnoringModifiers] isEqualToString: key]) {
            action();
            return nil;
        }
        return event;
    }];
    [handlers addObject: x];
}

- (void) writeOutput:(NSString*)str {
    NSFileHandle* stdoutHandle = [NSFileHandle fileHandleWithStandardOutput];
    [stdoutHandle writeData: [str dataUsingEncoding:NSUTF8StringEncoding]];
}

static NSColor* SDColorFromHex(NSString* hex) {
    NSScanner* scanner = [NSScanner scannerWithString: [hex uppercaseString]];
    unsigned colorCode = 0;
    [scanner scanHexInt: &colorCode];
    return [NSColor colorWithCalibratedRed:(CGFloat)(unsigned char)(colorCode >> 16) / 0xff
                                     green:(CGFloat)(unsigned char)(colorCode >> 8) / 0xff
                                      blue:(CGFloat)(unsigned char)(colorCode) / 0xff
                                     alpha: 1.0];
}

static char* HexFromSDColor(NSColor* color) {
    size_t bufferSize = 7;
    char* buffer = (char*) malloc(bufferSize * sizeof(char));
    NSColor* c = [color colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    snprintf(buffer, bufferSize, "%2X%2X%2X",
            (unsigned int) ([c redComponent] * 255.99999),
            (unsigned int) ([c greenComponent] * 255.99999),
            (unsigned int) ([c blueComponent] * 255.99999));
    return buffer;
}

/******************************************************************************/
/* Getting input list                                                         */
/******************************************************************************/

- (NSArray*) getInputItems {

#ifdef DEBUG

    #include "fakedata.h"

#else

    NSFileHandle* stdinHandle = [NSFileHandle fileHandleWithStandardInput];
    NSData* inputData = [stdinHandle readDataToEndOfFile];
    NSString* inputStrings = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([inputStrings length] == 0)
        return nil;

    return [inputStrings componentsSeparatedByString:@"\n"];

#endif

}

@end

/******************************************************************************/
/* Command line interface                                                     */
/******************************************************************************/

static NSString* SDAppVersionString(void) {
    return [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
}

static void SDShowVersion(const char* name) {
    printf("%s %s\n", name, [SDAppVersionString() UTF8String]);
    exit(0);
}

static void usage(const char* name) {
    printf("usage: %s\n", name);
    printf(" -i           return index of selected element\n");
    printf(" -v           show choose version\n");
    printf(" -n [10]      set number of rows\n");
    printf(" -w [50]      set width of choose window\n");
    printf(" -f [Menlo]   set font used by choose\n");
    printf(" -s [26]      set font size used by choose\n");
    printf(" -c [0000FF]  highlight color for matched string\n");
    printf(" -b [222222]  background color of selected element\n");
    printf(" -u           disable underline and use background for matched string\n");
    printf(" -m           return the query string in case it doesn't match any item\n");
    exit(0);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];

        SDReturnsIndex = NO;
        SDUnderlineDisabled = NO;
        const char* hexColor = HexFromSDColor(NSColor.systemBlueColor);
        const char* hexBackgroundColor = HexFromSDColor(NSColor.systemGrayColor);
        const char* queryFontName = "Menlo";
        CGFloat queryFontSize = 26.0;
        SDNumRows = 10;
        SDReturnStringOnMismatch = NO;
        SDPercentWidth = -1;

        static SDAppDelegate* delegate;
        delegate = [[SDAppDelegate alloc] init];
        [NSApp setDelegate: delegate];

        int ch;
        while ((ch = getopt(argc, (char**)argv, "lvf:s:r:c:b:n:w:hium")) != -1) {
            switch (ch) {
                case 'i': SDReturnsIndex = YES; break;
                case 'f': queryFontName = optarg; break;
                case 'c': hexColor = optarg; break;
                case 'b': hexBackgroundColor = optarg; break;
                case 's': queryFontSize = atoi(optarg); break;
                case 'n': SDNumRows = atoi(optarg); break;
                case 'w': SDPercentWidth = atoi(optarg); break;
                case 'v': SDShowVersion(argv[0]); break;
                case 'u': SDUnderlineDisabled = YES; break;
                case 'm': SDReturnStringOnMismatch = YES; break;
                case '?':
                case 'h':
                default:
                    usage(argv[0]);
            }
        }
        argc -= optind;
        argv += optind;

        SDQueryFont = [NSFont fontWithName:[NSString stringWithUTF8String: queryFontName] size:queryFontSize];
        SDHighlightColor = SDColorFromHex([NSString stringWithUTF8String: hexColor]);
        SDHighlightBackgroundColor = SDColorFromHex([NSString stringWithUTF8String: hexBackgroundColor]);

        NSApplicationMain(argc, argv);
    }
    return 0;
}
