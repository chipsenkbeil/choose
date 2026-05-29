#import <Cocoa/Cocoa.h>
#import <CommonCrypto/CommonDigest.h>
#include <getopt.h>

#define NSApp [NSApplication sharedApplication]

/******************************************************************************/
/* User Options                                                               */
/******************************************************************************/

static NSColor* SDBackgroundColor;
static NSColor* SDTextColor;
static NSColor* SDHighlightColor;
static NSColor* SDSelectedBackgroundColor;
static NSColor* SDQueryColor;
static NSColor* SDPlaceholderColor;
static NSColor* SDIconColor;
static NSColor* SDDividerColor;
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
static BOOL AutoSelectSingleChoice;
static BOOL MatchWords;
static BOOL SortMatches;
static BOOL Password;

static NSString* LastQueryString;
static int LastCursorPos;
static NSString* ScriptAtInput;
static NSString* ScriptAtList;

typedef NS_ENUM(NSInteger, CaseSpecification) {
    SENSITIVE,
    INSENSITIVE,
    SMART
};

static CaseSpecification SearchCase;

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

@property NSString* raw;
@property NSMutableIndexSet* indexSet;
@property NSMutableAttributedString* displayString;

@property BOOL isMatchForQuery;
@property int score;

@end

@implementation SDChoice

- (id) initWithString:(NSString*)str {
    if (self = [super init]) {
        self.raw = str;
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


    NSUInteger len = [self.raw length];
    NSRange fullRange = NSMakeRange(0, len);

    [self.displayString addAttribute:NSForegroundColorAttributeName value:SDTextColor range:fullRange];

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

- (void) matchAgainstQuery: (NSArray*) queryTokens
                            isCaseSensitive: (BOOL) isCaseSensitive
{
    // given a query split into queryTokens (either characters or words
    // depending on user options), find if this choice matches the query and
    // update self.isMatchForQuery and self.indexSet accordingly.

    NSString* text = self.raw;
    int len = [text length];

    NSStringCompareOptions options = 0;
    if ( ! MatchFromBeginning ) {
        options |= NSBackwardsSearch;
    }
    if ( isCaseSensitive ) {
        options |= NSLiteralSearch;
    } else {
        options |= NSCaseInsensitiveSearch;
    }

    int nextIdx = MatchFromBeginning ? 0 : (len - 1);
    self.isMatchForQuery = YES;
    [self.indexSet removeAllIndexes];
    for (NSString* token in queryTokens) {
        if ( (nextIdx < 0) || (nextIdx >= len) ) {
            self.isMatchForQuery = NO;
            break;
        }
        NSRange searchRange;
        if ( MatchFromBeginning ) {
            searchRange = NSMakeRange(nextIdx, len - nextIdx);
        } else {
            searchRange = NSMakeRange(0, nextIdx + 1);
        }
        NSRange foundRange = [ text rangeOfString:token options:options 
                               range:searchRange ];
        if (foundRange.location == NSNotFound) {
            self.isMatchForQuery = NO;
            break;
        }
        [self.indexSet addIndexesInRange:foundRange];
        if ( MatchFromBeginning ) {
            nextIdx = NSMaxRange(foundRange);
        } else {
            nextIdx = foundRange.location - 1;
        }
    }
}

- (void) scoreMatch {

    if (    ( ! self.isMatchForQuery ) 
         || ( ! SortMatches )
         || ( [self.indexSet count] == 0 ) ) {
        self.score = 0;
        return;
    }

    int firstOccurenceScore = 0;
    if ( ScoreFirstMatchedPosition ) {
        if (MatchFromBeginning)
            firstOccurenceScore = -self.indexSet.firstIndex;
        else
            firstOccurenceScore =   self.indexSet.lastIndex 
                                  - [self.raw length] + 1;
    }

    __block int lengthScore = 0;
    __block int numRanges = 0;

    [self.indexSet enumerateRangesUsingBlock:^(NSRange range, BOOL *stop) {
        numRanges++;
        lengthScore += (range.length * 100);
    }];

    lengthScore /= numRanges;

    int percentScore = ( (double)[self.indexSet count] / 
                         (double)[self.raw length] ) * 100.0;

    self.score = lengthScore + percentScore + firstOccurenceScore;
}

- (void) analyze: (NSArray*) queryTokens
                  isCaseSensitive: (BOOL) isCaseSensitive {
    [ self matchAgainstQuery: queryTokens isCaseSensitive: isCaseSensitive ];
    [ self scoreMatch ];
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
        if (SDBackgroundColor != nil) {
            self.window.backgroundColor = SDBackgroundColor;
        } else {
            NSVisualEffectView* blur = [[NSVisualEffectView alloc] initWithFrame: [[self.window contentView] bounds]];
            [blur setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable ];
            blur.material = NSVisualEffectMaterialMenu;
            blur.state = NSVisualEffectBlendingModeBehindWindow;
            [[self.window contentView] addSubview: blur];
        }
    }
}


- (void) setCursorAtEndOfQueryField {
    [[self.queryField currentEditor] setSelectedRange: NSMakeRange(self.queryField.stringValue.length, 0)];
}

- (void) setupQueryField:(NSRect)textRect {
    NSRect iconRect, space;
    NSDivideRect(textRect, &iconRect, &textRect, NSHeight(textRect) / 1.25, NSMinXEdge);
    NSDivideRect(textRect, &space, &textRect, 5.0, NSMinXEdge);

    CGFloat d = NSHeight(iconRect) * 0.10;
    iconRect = NSInsetRect(iconRect, d, d);

    NSImageView* icon = [[NSImageView alloc] initWithFrame: iconRect];
    if (@available(macOS 10.14, *)) icon.contentTintColor = SDIconColor;
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
    [self.queryField setTextColor: SDQueryColor];
    NSDictionary* placeholderAttributes = @{ NSFontAttributeName: self.queryField.font, NSForegroundColorAttributeName: SDPlaceholderColor };
    NSAttributedString* placeholderAttrString = [[NSAttributedString alloc] initWithString:PromptText
                                                                                attributes:placeholderAttributes];
    [self.queryField setPlaceholderAttributedString: placeholderAttrString];
    [self.queryField setTarget: self];
    [self.queryField setAction: @selector(choose:)];
    [[self.queryField cell] setSendsActionOnEndEditing: NO];
    [[self.window contentView] addSubview: self.queryField];

    // schedule to set cursor position after a delay, after the main run loop
    // has completed its initial cycle
    [self performSelector:@selector(setCursorAtEndOfQueryField) withObject:nil afterDelay:0.0];
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
    [border setFillColor: SDDividerColor];
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

- (void) moveSelectionUp {
    if (self.choice <= 0) {
        self.choice = [self.filteredSortedChoices count] - 1;
    } else {
        self.choice -= 1;
    }
    [self reflectChoice];
}

- (void) moveSelectionDown {
    if (self.choice >= [self.filteredSortedChoices count] - 1) {
        self.choice = 0;
    } else {
        self.choice += 1;
    }
    [self reflectChoice];
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
    // Vim-style navigation: Ctrl+j (down), Ctrl+k (up)
    [self addShortcut:@"j" mods:NSControlKeyMask handler:^{ [_self moveSelectionDown]; }];
    [self addShortcut:@"k" mods:NSControlKeyMask handler:^{ [_self moveSelectionUp]; }];
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
        [aCell setBackgroundColor: [SDSelectedBackgroundColor colorWithAlphaComponent:0.5]];
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

- (NSArray*) tokenizeQuery: (NSString*) query {

    NSMutableArray* mtokens = [NSMutableArray array];

    int len = [query length];
    int nextIdx = MatchFromBeginning ? 0 : (len - 1);
    while ( (nextIdx >= 0) && (nextIdx < len) ) {

        // get the next token if one exists
            // if it exists, append it to mtokens
        // update nextIdx

        NSString* nextToken;

        if ( ! MatchWords ) {
            // next token = just the current character
            nextToken = [query substringWithRange: NSMakeRange(nextIdx, 1)];
            [mtokens addObject:nextToken];
            nextIdx += MatchFromBeginning ? 1 : -1;
            continue;
        }
        
        // next token = next word that starts at the current character
            // if there is one!

        NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
        NSCharacterSet *nonWhitespace = [whitespace invertedSet];
    
        // starting from nextIdx and going in the right direction, look for a 
        // non-whitespace character to begin our word

        NSStringCompareOptions options;
        NSRange nonWSSearchRange;
        if ( MatchFromBeginning ) {
            options = 0;
            nonWSSearchRange = NSMakeRange(nextIdx, len - nextIdx);
        } else {
            options = NSBackwardsSearch;
            nonWSSearchRange = NSMakeRange(0, nextIdx + 1);
        }

        NSRange nonWSFoundRange = [ 
            query rangeOfCharacterFromSet:nonWhitespace options:options 
            range:nonWSSearchRange ];

        if (nonWSFoundRange.location == NSNotFound) {
            // there's no next token; we're done!
            break;
        }
        
        // there is a next token; it starts at the non-whitespace character we
        // just found

        int nonWSIdx = nonWSFoundRange.location;
        
        // now start at the character that immediately follows this 
        // non-whitespace character. Look for a subsequent whitespace 
        // character; if found, this will mark the end of our word. If not, our
        // word continues until the end of the query.

        NSRange wsSearchRange;
        if ( MatchFromBeginning ) {
            wsSearchRange = NSMakeRange(nonWSIdx + 1, len - nonWSIdx - 1);
        } else {
            wsSearchRange = NSMakeRange(0, nonWSIdx);
        }

        NSRange wsFoundRange = [ 
            query rangeOfCharacterFromSet:whitespace options:options 
            range:wsSearchRange ];

        int wsIdx;
        if (wsFoundRange.location == NSNotFound) {
            wsIdx = MatchFromBeginning ? len : -1;
        } else {
            wsIdx = wsFoundRange.location;
        }

        int nextTokenStartIdx = nonWSIdx;
        int nextTokenEndIdx = wsIdx - (MatchFromBeginning ? 1 : -1);
        if ( ! MatchFromBeginning ) {
            int temp = nextTokenStartIdx;
            nextTokenStartIdx = nextTokenEndIdx;
            nextTokenEndIdx = temp;
        }

        int nextTokenLength = nextTokenEndIdx - nextTokenStartIdx + 1;
        nextToken = [ query substringWithRange: NSMakeRange(
                          nextTokenStartIdx, nextTokenLength) ];

        [mtokens addObject:nextToken];
        if (MatchFromBeginning) {
            nextIdx = nextTokenEndIdx + 1;
        } else {
            nextIdx = nextTokenStartIdx - 1;
        }

    }

    return [mtokens copy];
}

- (BOOL) getIsCaseSensitive: (NSString*) query {
    if ( SearchCase == INSENSITIVE ) {
        return NO;
    } else if (SearchCase == SENSITIVE) {
        return YES;
    } else {
        // Smart case
        NSRange uppercaseRange = [ query rangeOfCharacterFromSet:
                [NSCharacterSet uppercaseLetterCharacterSet] ];
        if (uppercaseRange.location == NSNotFound) {
            // query is all lowercase, so we perform case-insensitive search
            return NO;
        } else {
            // query contains uppercase letters, so we perform case-sensitive 
            // search.
            return YES;
        }
    }
}

- (void) doQuery:(NSString*)query {

    NSArray* queryTokens = [ self tokenizeQuery: query ];
    BOOL isCaseSensitive = [ self getIsCaseSensitive: query ];

    self.filteredSortedChoices = [self.choices mutableCopy];

    // analyze (cache)
    for (SDChoice* choice in self.filteredSortedChoices)
        [ choice analyze:queryTokens isCaseSensitive:isCaseSensitive ];

    if ([query length] >= 1) {

        // filter out non-matches
        for (SDChoice* choice in [self.filteredSortedChoices copy]) {
            if (!choice.isMatchForQuery)
                [self.filteredSortedChoices removeObject: choice];
        }

        // sort remainder
        if (SortMatches) {
            [self.filteredSortedChoices sortUsingComparator:^NSComparisonResult(SDChoice* a, SDChoice* b) {
                if (a.score > b.score) return NSOrderedAscending;
                if (a.score < b.score) return NSOrderedDescending;
                return NSOrderedSame;
            }];
        }

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

    // if there's only one choice, and AutoSelectSingleChoice is enabled, pick
    // this choice and exit the app
    if (AutoSelectSingleChoice && [self.filteredSortedChoices count] == 1) {
        self.choice = 0;
        [self choose];
    }
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
    NSString* upperHex = [hex uppercaseString];
    NSScanner* scanner = [NSScanner scannerWithString: upperHex];
    unsigned colorCode = 0;
    [scanner scanHexInt: &colorCode];

    // if alpha is not provided, assume it's 0xff
    BOOL has0x = [upperHex hasPrefix: @"0X"];
    if ((has0x && upperHex.length <= 8) || (!has0x && upperHex.length <= 6)) {
        colorCode |= 0xff000000;
    }

    return [NSColor colorWithCalibratedRed:(CGFloat)(unsigned char)(colorCode >> 16) / 0xff
                                     green:(CGFloat)(unsigned char)(colorCode >> 8) / 0xff
                                      blue:(CGFloat)(unsigned char)(colorCode) / 0xff
                                     alpha:(CGFloat)(unsigned char)(colorCode >> 24) / 0xff];
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
    NSString* inputStrings = [[[NSString alloc] initWithData:inputData encoding:NSUTF8StringEncoding] stringByTrimmingCharactersInSet: [NSCharacterSet newlineCharacterSet]];

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
    printf(" --highlight-color, -c   [0xAA]RRGGBB   highlight color for matched string\n");
    printf(" --selected-bg-color, -b [0xAA]RRGGBB   background color of selected element\n");
    printf(" --text-color            [0xAA]RRGGBB   list text color\n");
    printf(" --query-color           [0xAA]RRGGBB   text color of query input\n");
    printf(" --placeholder-color     [0xAA]RRGGBB   placeholder text color (see -p)\n");
    printf(" --icon-color            [0xAA]RRGGBB   prompt icon color\n");
    printf(" --divider-color         [0xAA]RRGGBB   color for divider between prompt and list\n");
    printf(" --background-color      [0xAA]RRGGBB   window background color\n");
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
    printf(" -1           if there's only one element, select it automatically\n");
    printf(" -W           match words (rather than characters) from the query field\n");
    printf(" -S           do not sort matches (ie, present them in the same order they appeared in the input)\n");
    printf(" -C [i]       i = case-insensitive, I = case-sensitive, s = smart (case-sensitive if query contains uppercase characters, case-insensitive otherwise)\n");
    exit(0);
}

static void queryStdout(SDAppDelegate* delegate, const char* query) {
    delegate.choices = [delegate choicesFromInputItems: [delegate getInputItems]];
    [delegate doQuery: [NSString stringWithUTF8String: query]];

    for (SDChoice* choice in delegate.filteredSortedChoices) 
        printf("%s\n", [choice.raw UTF8String]);

    exit(0);
}

static CaseSpecification getSearchCase(const char *optarg, const char *name) {

    if (strlen(optarg) != 1) {
        usage(name);
    }
    
    switch (*optarg) {
        case 'i':
            return INSENSITIVE;
        case 'I':
            return SENSITIVE;
        case 's':
            return SMART;
        default:
            usage(name);
    }

    return INSENSITIVE;
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
        SDTextColor = NSColor.controlTextColor;
        SDHighlightColor = NSColor.systemBlueColor;
        SDSelectedBackgroundColor = NSColor.systemGrayColor;
        SDQueryColor = NSColor.controlTextColor;
        SDPlaceholderColor = NSColor.placeholderTextColor;
        SDIconColor = NSColor.systemGrayColor;
        SDDividerColor = NSColor.systemGrayColor;
        const char* queryFontName = "Menlo";
        const char* queryPromptString = "";
        InitialQuery = [NSString stringWithUTF8String: ""];
        Separator = [NSString stringWithUTF8String: "\n"];
        CGFloat queryFontSize = 26.0;
        SDNumRows = 10;
        SDReturnStringOnMismatch = NO;
        SDPercentWidth = -1;
        AutoSelectSingleChoice = NO;
        MatchWords = NO;
        SortMatches = YES;
        SearchCase = INSENSITIVE;
        Password = NO;

        static SDAppDelegate* delegate;
        delegate = [[SDAppDelegate alloc] init];
        [NSApp setDelegate: delegate];

        enum {
            OPT_HIGHLIGHT_COLOR = 'c',
            OPT_SELECTED_BG_COLOR = 'b',
            OPT_TEXT_COLOR = 1000,
            OPT_QUERY_COLOR,
            OPT_PLACEHOLDER_COLOR,
            OPT_ICON_COLOR,
            OPT_DIVIDER_COLOR,
            OPT_BACKGROUND_COLOR,
        };

        static struct option longopts[] = {
            {"text-color",        required_argument, 0, OPT_TEXT_COLOR},
            {"highlight-color",   required_argument, 0, OPT_HIGHLIGHT_COLOR},
            {"selected-bg-color", required_argument, 0, OPT_SELECTED_BG_COLOR},
            {"query-color",       required_argument, 0, OPT_QUERY_COLOR},
            {"placeholder-color", required_argument, 0, OPT_PLACEHOLDER_COLOR},
            {"icon-color",        required_argument, 0, OPT_ICON_COLOR},
            {"divider-color",     required_argument, 0, OPT_DIVIDER_COLOR},
            {"background-color",  required_argument, 0, OPT_BACKGROUND_COLOR},
            {0, 0, 0, 0}
        };

        int ch;
        while ((ch = getopt_long(argc, (char**)argv, "lvyezaf:s:r:c:b:n:w:p:q:r:t:x:o:Phium1WSC:", longopts, NULL)) != -1) {
            switch (ch) {
                case 'i': SDReturnsIndex = YES; break;
                case 'f': queryFontName = optarg; break;
                case OPT_BACKGROUND_COLOR: SDBackgroundColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_TEXT_COLOR: SDTextColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_HIGHLIGHT_COLOR: SDHighlightColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_SELECTED_BG_COLOR: SDSelectedBackgroundColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_QUERY_COLOR: SDQueryColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_PLACEHOLDER_COLOR: SDPlaceholderColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_ICON_COLOR: SDIconColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
                case OPT_DIVIDER_COLOR: SDDividerColor = SDColorFromHex([NSString stringWithUTF8String: optarg]); break;
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
                case '1': AutoSelectSingleChoice = YES; break;
                case 'W': MatchWords = YES; break;
                case 'S': SortMatches = NO; break;
                case 'C': SearchCase = getSearchCase(optarg, argv[0]); break;
                case '?':
                case 'h':
                default:
                    usage(argv[0]);
            }
        }
        argc -= optind;
        argv += optind;

        SDQueryFont = [NSFont fontWithName:[NSString stringWithUTF8String: queryFontName] size:queryFontSize];
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
