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
static NSString* PromptText;
static NSString* InitialQuery;
static NSString* Separator;
static int SDNumRows;
static int SDPercentWidth;
static BOOL SDUnderlineDisabled;
static BOOL SDReturnStringOnMismatch;
static BOOL VisualizeWhitespaceCharacters;
static BOOL AllowEmptyInput;
static BOOL MatchFromBeginning;
static BOOL ScoreFirstMatchedPosition;
static BOOL Password;

static NSString* LastQueryString;
static int LastCursorPos;
static NSString* ScriptAtInput;
static NSString* ScriptAtList;

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

        NSString* displayStringRaw = self.raw;
        if (VisualizeWhitespaceCharacters) {
            displayStringRaw = [[self.raw stringByReplacingOccurrencesOfString:@"\n" withString:@"⏎"] stringByReplacingOccurrencesOfString:@"\t" withString:@"⇥"];
        }
        self.displayString = [[NSMutableAttributedString alloc] initWithString:displayStringRaw attributes:nil];
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
    BOOL foundAll = YES;
    __block int firstOccurenceScore = 0;

    if (MatchFromBeginning) {
        NSUInteger firstPos = 0;
        for (NSInteger i = 0; i < [query length]; i++) {
            unichar qc = [query characterAtIndex: i];
            BOOL found = NO;
            for (NSInteger i = firstPos; i <= [self.normalized length] - 1; i++) {
                unichar rc = [self.normalized characterAtIndex: i];
                if (qc == rc) {
                    if (firstPos == 0) {
                        firstOccurenceScore = -i;
                    }
                    [self.indexSet addIndex: i];
                    firstPos = i+1;
                    found = YES;
                    break;
                }
            }
            if (!found) {
                foundAll = NO;
                break;
            }
        }
    } else {
        NSUInteger lastPos = [self.normalized length] - 1;

        for (NSInteger i = [query length] - 1; i >= 0; i--) {
            unichar qc = [query characterAtIndex: i];
            BOOL found = NO;
            for (NSInteger i = lastPos; i >= 0; i--) {
                unichar rc = [self.normalized characterAtIndex: i];
                if (qc == rc) {
                    if (lastPos == [self.normalized length] - 1) {
                        firstOccurenceScore = i - [self.normalized length] + 1;
                    }
                    [self.indexSet addIndex: i];
                    lastPos = i-1;
                    found = YES;
                    break;
                }
            }
            if (!found) {
                foundAll = NO;
                break;
            }
        }
    }

    if (!ScoreFirstMatchedPosition) {
        firstOccurenceScore = 0;
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

    self.score = lengthScore + percentScore + firstOccurenceScore;
}

@end

/******************************************************************************/
/* App Delegate                                                               */
/******************************************************************************/

@interface SDAppDelegate : NSObject <NSApplicationDelegate, NSWindowDelegate, NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate>

// internal

- (void)createMenu;
@property NSWindow* window;
@property NSArray* choices;
@property NSMutableArray* filteredSortedChoices;
@property SDTableView* listTableView;
@property NSTextField* queryField;
@property NSInteger choice;

@property NSString* lastScriptOutputAtInput;

@end

@implementation SDAppDelegate

/******************************************************************************/
/* Starting the app                                                           */
/******************************************************************************/

-(void)createMenu {
    /* create invisible menubar so that (copy paste cut undo redo) all work */
    NSMenu *menubar = [[NSMenu alloc]init];
    [NSApp setMainMenu:menubar];

    NSMenuItem *menuBarItem = [[NSMenuItem alloc] init];
    [menubar addItem:menuBarItem];
    NSMenu *myMenu = [[NSMenu alloc]init];

    // just FYI: some of those are prone to being renamed by the system
    // see https://github.com/tauri-apps/tauri/issues/7828#issuecomment-1723489849
    // and https://github.com/electron/electron/blob/706653d5e4d06922f75aa5621533a16fc34d3a77/shell/browser/ui/cocoa/electron_menu_controller.mm#L62
    NSMenuItem* copyItem = [[NSMenuItem alloc] initWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
    NSMenuItem* pasteItem = [[NSMenuItem alloc] initWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
    NSMenuItem* cutItem = [[NSMenuItem alloc] initWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
    NSMenuItem* undoItem = [[NSMenuItem alloc] initWithTitle:@"Undo" action:@selector(undo:) keyEquivalent:@"z"];
    NSMenuItem* redoItem = [[NSMenuItem alloc] initWithTitle:@"Redo" action:@selector(redo:) keyEquivalent:@"z"];
    [redoItem setKeyEquivalentModifierMask: NSShiftKeyMask | NSCommandKeyMask];

    [myMenu addItem:copyItem];
    [myMenu addItem:pasteItem];
    [myMenu addItem:cutItem];
    [myMenu addItem:undoItem];
    [myMenu addItem:redoItem];
    [menuBarItem setSubmenu:myMenu];   
 }

- (void) applicationDidFinishLaunching:(NSNotification *)notification {
    [self createMenu];
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
    [self runQuery: self.queryField.stringValue];
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

    self.queryField = Password ? [[NSSecureTextField alloc] initWithFrame: textRect] : [[NSTextField alloc] initWithFrame: textRect];
    [self.queryField setAutoresizingMask: NSViewWidthSizable | NSViewMinYMargin ];
    [self.queryField setDelegate: self];
    [self.queryField setStringValue: InitialQuery];
    [self.queryField setBezelStyle: NSTextFieldSquareBezel];
    [self.queryField setBordered: NO];
    [self.queryField setDrawsBackground: NO];
    [self.queryField setFocusRingType: NSFocusRingTypeNone];
    [self.queryField setFont: SDQueryFont];
    [self.queryField setEditable: YES];
    [self.queryField setPlaceholderString: PromptText];
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

- (void) runScriptAtList:(NSString*) query {
    if([ScriptAtList length] > 0){
	NSArray *rows = [Script(ScriptAtList,query, @"list") componentsSeparatedByString:@"\n"];
        int i;
	for (i=[rows count]-1; i>=0; i--){
            if ([rows[i] length] > 0){
                SDChoice* newChoice = [[SDChoice alloc] initWithString:rows[i]];
                [self.filteredSortedChoices insertObject:newChoice atIndex:0];
            }
	}
    }
}

- (void) runScriptAtInput:(NSString*) query {
    if([ScriptAtInput length] > 0){
	self.lastScriptOutputAtInput = Script(ScriptAtInput,query, @"input");

        if([[self.queryField stringValue] length] > [LastQueryString length]){
            LastQueryString = [self.queryField stringValue];
            NSString* queryWithOutput = [NSString stringWithFormat:@"%@%@", [self.queryField stringValue], self.lastScriptOutputAtInput];
            [self.queryField setStringValue: queryWithOutput];

            NSText* fieldEditor = [self.queryField currentEditor];
            if([self.lastScriptOutputAtInput length] > 0){
                [fieldEditor setSelectedRange: NSMakeRange([queryWithOutput length]-[self.lastScriptOutputAtInput length],[queryWithOutput length])];
            }
        } else if ([[self.queryField stringValue] length] < [LastQueryString length]) {
            LastQueryString = [self.queryField stringValue];
        }
    }
}

- (void) clearScriptOutputAtInput {
    NSRange range = [[[self.queryField window] fieldEditor:YES forObject:self.queryField] selectedRange];
    if([self.lastScriptOutputAtInput length] > 0 && [[[self.queryField stringValue] substringWithRange:range] isEqualToString: self.lastScriptOutputAtInput]){
        [[[self.queryField window] fieldEditor:YES forObject:self.queryField] setSelectedRange:NSMakeRange(LastCursorPos,0)];
        [self.queryField setStringValue: [[self.queryField stringValue] substringWithRange:NSMakeRange(0,range.location)]];
        self.lastScriptOutputAtInput = @"";
    }
}

/******************************************************************************/
/* Filtering!                                                                 */
/******************************************************************************/

- (void) doQuery:(NSString*)query {
    query = [query lowercaseString];

    self.filteredSortedChoices = [self.choices mutableCopy];

    // analyze (cache)
    for (SDChoice* choice in self.filteredSortedChoices)
        [choice analyze: query];

    if ([query length] >= 1) {

        // filter out non-matches
        for (SDChoice* choice in [self.filteredSortedChoices copy]) {
            if (!choice.hasAllCharacters)
                [self.filteredSortedChoices removeObject: choice];
        }

        // sort remainder
        [self.filteredSortedChoices sortUsingComparator:^NSComparisonResult(SDChoice* a, SDChoice* b) {
            if (a.score > b.score) return NSOrderedAscending;
            if (a.score < b.score) return NSOrderedDescending;
            return NSOrderedSame;
        }];

    }
}


- (void) runQuery:(NSString*)query {
    [self doQuery: query];

    // render remainder
    for (SDChoice* choice in self.filteredSortedChoices)
        [choice render];

    // running scripts on input, if available
    LastCursorPos = (int) [[[self.queryField window] fieldEditor:YES forObject:self.queryField] selectedRange].location;
    [self runScriptAtInput: query];
    [self runScriptAtList: query];

    // show!
    [self.listTableView reloadData];

    // push choice back to start
    self.choice = 0;
    [self reflectChoice];
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
    [self clearScriptOutputAtInput];
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
    [self clearScriptOutputAtInput];
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

static NSString* Script(NSString* pathToScript, NSString* queryInput, NSString* where) {
    int pid = [[NSProcessInfo processInfo] processIdentifier];
    NSPipe *pipe = [NSPipe pipe];
    NSPipe *pipeErr = [NSPipe pipe];
    NSFileHandle *file = pipe.fileHandleForReading;

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = pathToScript;
    task.arguments = @[queryInput, where];
    task.standardOutput = pipe;
    task.standardError = pipeErr;

    [task launch];
    
    NSData *data = [file readDataToEndOfFile];
    [file closeFile];
    
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];

    return output;
}


/******************************************************************************/
/* Getting input list                                                         */
/******************************************************************************/

- (NSArray*) getInputItems {

#ifdef DEBUG

    #include "fakedata.h"

#else

    NSFileHandle* stdinHandle = [NSFileHandle fileHandleWithStandardInput];
    NSData* inputData = Password ? nil : [stdinHandle readDataToEndOfFile];
    NSString* inputStrings = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if ([inputStrings length] == 0 && !AllowEmptyInput)
        return nil;

    return [inputStrings componentsSeparatedByString: Separator];

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
    printf(" -p           defines a prompt to be displayed when query field is empty\n");
    printf(" -P           conceals keyboard input / password mode (implies -m, -e and -n 0)\n");
    printf(" -q           defines initial query to start with (empty by default)\n");
    printf(" -r           path to a script to run when typing. Output appended to input field. Two args provided upon run:\n");
    printf("               - the query text from input field\n");
    printf("               - where output will be placed (\"input\" for -r or \"list\" for -t). \n");
    printf(" -t           same as -r, but outputs are in the form of extra list options (supports multiline outputs)\n");
    printf(" -x           defines separator string, a single newline (\\n) by default\n");
    printf("              beware of escaping:\n");
    printf("                  passing -x \\n\\n will work\n");
    printf("                  passing -x '\\n\\n' will not work\n");
    printf(" -y           show newline and tab as symbols (⏎ ⇥)\n");
    printf(" -e           allow empty input (choose will show up even if there are no items to select)\n");
    printf(" -o           given a query, outputs results to standard output\n");
    printf(" -z           search matches symbols from beginning (instead of from end by weird default)\n");
    printf(" -a           rank early matches higher\n");
    exit(0);
}

static void queryStdout(SDAppDelegate* delegate, const char* query) {
    delegate.choices = [delegate choicesFromInputItems: [delegate getInputItems]];
    [delegate doQuery: [NSString stringWithUTF8String: query]];

    for (SDChoice* choice in delegate.filteredSortedChoices) 
        printf("%s\n", [choice.raw UTF8String]);

    exit(0);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        [NSApp setActivationPolicy: NSApplicationActivationPolicyAccessory];

        VisualizeWhitespaceCharacters = NO;
        AllowEmptyInput = NO;
        MatchFromBeginning = NO;
        ScoreFirstMatchedPosition = NO;
        SDReturnsIndex = NO;
        SDUnderlineDisabled = NO;
        const char* hexColor = HexFromSDColor(NSColor.systemBlueColor);
        const char* hexBackgroundColor = HexFromSDColor(NSColor.systemGrayColor);
        const char* queryFontName = "Menlo";
        const char* queryPromptString = "";
        InitialQuery = [NSString stringWithUTF8String: ""];
        Separator = [NSString stringWithUTF8String: "\n"];
        CGFloat queryFontSize = 26.0;
        SDNumRows = 10;
        SDReturnStringOnMismatch = NO;
        SDPercentWidth = -1;
        Password = NO;

        static SDAppDelegate* delegate;
        delegate = [[SDAppDelegate alloc] init];
        [NSApp setDelegate: delegate];

        int ch;
        while ((ch = getopt(argc, (char**)argv, "lvyezaf:s:r:c:b:n:w:p:q:r:t:x:o:Phium")) != -1) {
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
                case 'p': queryPromptString = optarg; break;
                case 'P': Password = YES; AllowEmptyInput = YES; SDReturnStringOnMismatch = YES; SDNumRows = 0; break;
                case 'q': InitialQuery = [NSString stringWithUTF8String: optarg]; break;
                case 'r': ScriptAtInput = [NSString stringWithUTF8String: optarg]; break;
                case 't': ScriptAtList = [NSString stringWithUTF8String: optarg]; break;
                case 'x': Separator = [NSString stringWithUTF8String: optarg]; break;
                case 'y': VisualizeWhitespaceCharacters = YES; break;
                case 'e': AllowEmptyInput = YES; break;
                case 'z': MatchFromBeginning = YES; break;
                case 'a': ScoreFirstMatchedPosition = YES; break;
                case 'o': queryStdout(delegate, optarg); break;
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
        PromptText = [NSString stringWithUTF8String: queryPromptString];

        if ([ScriptAtInput length] > 0 && ![[NSFileManager defaultManager] fileExistsAtPath:ScriptAtInput]){
            printf("No such file or directory for the script at input: %s\n", [ScriptAtInput UTF8String]);
            exit(1);
        }
        if ([ScriptAtList length] > 0 && ![[NSFileManager defaultManager] fileExistsAtPath:ScriptAtList]){
            printf("No such file or directory for the script at list: %s\n", [ScriptAtList UTF8String]);
            exit(1);
        }

        NSApplicationMain(argc, argv);
    }
    return 0;
}
