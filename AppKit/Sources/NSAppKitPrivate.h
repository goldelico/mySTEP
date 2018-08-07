//
//  NSAppKitPrivate.h
//  mySTEP
//
//  Private interfaces used internally in AppKit implementation only
//
//  Created by Dr. H. Nikolaus Schaller on Thu Jan 05 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSColorSpace.h>
#import <AppKit/NSComboBox.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSDocument.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSImageCell.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSNib.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSPrintOperation.h>
#import <AppKit/NSPrinter.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSSegmentedCell.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSStatusItem.h>
#import <AppKit/NSSplitView.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSText.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSToolbar.h>
#import <AppKit/NSToolbarItem.h>
#import <AppKit/NSView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSWindowController.h>
#import <AppKit/NSWorkspace.h>

#define DEPRECATED	NSLog(@"%@: %@ is deprecated", NSStringFromClass([self class]), NSStringFromSelector(_cmd))	// issue a warning

#ifdef __APPLE__	// Apple Foundation does not provide these macros
#define NS_TIME_START(A)
#define NS_TIME_END(A, ...)
#endif

typedef struct _NSGraphicsState
{ // generic graphics state - backends might define their own object structs
	NSInteger _gState;							// unique gState number
	NSGraphicsContext *_context;			// associated context
	struct _NSGraphicsState *_nextOnStack;	// stack pointer
	NSPoint _patternPhase;
#if NOT_PART_OF_GRAPHICS_STATE
	struct
		{
			unsigned _compositingOperation:3;
			unsigned _imageInterpolation:3;
			unsigned _shouldAntialias:1;
			unsigned _isFlipped:1;
		} _op;
#endif
} _NSGraphicsState;

@interface NSBezierPath (NSPrivate)

typedef struct _PathElement
	{
		NSBezierPathElement type;
		NSPoint points[3];
	} PathElement;

+ (NSBezierPath *) _bezierPathWithBoxBezelInRect:(NSRect) borderRect radius:(CGFloat) radius;		// box with rounded corners
+ (NSBezierPath *) _bezierPathWithRoundedBezelInRect:(NSRect) borderRect vertical:(BOOL) flag;	// box with halfcircular rounded ends

typedef enum _NSRoundedBezelSegments
{
	NSRoundedBezelMiddleSegment=0,
	NSRoundedBezelLeftSegment=1,
	NSRoundedBezelRightSegment=2,
	NSRoundedBezelBothSegment=NSRoundedBezelLeftSegment | NSRoundedBezelRightSegment
} NSRoundedBezelSegments;

+ (void) _drawRoundedBezel:(NSRoundedBezelSegments) border inFrame:(NSRect) frame enabled:(BOOL) enabled selected:(BOOL) selected highlighted:(BOOL) highlighted radius:(CGFloat) radius;

@end

@interface NSGraphicsContext (NSPrivate)
- (_NSGraphicsState *) _copyGraphicsState:(_NSGraphicsState *) state;	// allocate and copy (it not NULL)
- (NSInteger) _currentGState;
- (id) _initWithAttributes:(NSDictionary *) attributes;
@end

@interface NSCell (NSPrivate)
- (NSAttributedString *) _getFormattedStringIgnorePlaceholder:(BOOL) flag;
- (void) _setTextColor:(NSColor *) textColor;
- (NSColor *) _textColor;
@end

@interface NSApplication (NSPrivate)
- (IBAction) _orderOutCharacterPalette:(id)sender;
- (BOOL) _eventIsQueued:(NSEvent *) event;
- (NSEvent *) _eventMatchingMask:(NSUInteger) mask dequeue:(BOOL)dequeue;
- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
- (void) _setAppleMenu:(NSMenu *) menu;
- (void) _setMenuBarVisible:(BOOL) flag;
- (NSWindow *) _mainMenuWindow;
- (void) _setPendingWindow:(NSWindow *) win;
@end

@interface NSDocument (NSPrivate)
- (NSWindow *) _window;
- (void) _removeWindowController:(NSWindowController *)windowController;
- (void) _changeWasDone:(NSNotification *)notification;
- (void) _changeWasUndone:(NSNotification *)notification;
- (void) _changeWasRedone:(NSNotification *)notification;
@end

@interface NSDocumentController (NSPrivate)
- (NSArray *) _editorAndViewerTypesForClass: (Class)documentClass;
- (NSArray *) _editorTypesForClass: (Class)documentClass;
- (NSArray *) _exportableTypesForClass: (Class)documentClass;
- (BOOL) _isDocumentBased;
- (void) _setOpenRecentMenu:(NSMenu *) menu;
- (void) _updateOpenRecentMenu;
- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
- (BOOL) _applicationShouldTerminate:(NSApplication *) sender;
@end

@interface NSWindowController (NSPrivate)
- (void) _windowDidLoad;
- (void) _windowWillClose:(NSNotification *)notification;	// we are not the delegate of the window but will observe the same notification
@end

@interface NSWorkspace (NSPrivate)

+ (NSArray *) _knownApplications;   // names of known applications
- (NSDictionary *) _applicationList;	// database of known applications
- (NSDictionary *) _fileTypeList;		// database of known file types
+ (NSDictionary *) _standardAboutOptions;   // standard about options of current application ??? move to NSApplication ???
+ (NSString *) _activeApplicationPath:(NSString *) path;	// get access to the active applications data base

@end

@interface NSPrinter (NSPrivate)
- (id) _initWithName:(NSString *) name host:(NSString *) host type:(NSString *) type note:(NSString *) note;
@end

@interface NSPrintOperation (NSPrivate)
- (void) _notify:(NSPrintOperation *) po success:(BOOL) success context:(void *) contextInfo;
- (id) _initWithView:(NSView *)aView
		  insideRect:(NSRect)rect
			  toData:(NSMutableData *)data
			  toPath:(NSString *)path
		   printInfo:(NSPrintInfo *)aPrintInfo;
@end

#define BACKEND  [self _backendResponsibility:_cmd];
@interface NSObject (Backend)
- (id) _backendResponsibility:(SEL) selector;	// implemented in NSGraphicsContext.m
@end

@interface NSWindow (NSPrivate)
+ (CGFloat) _titleBarHeightForStyleMask:(NSUInteger) mask /* forScreen:(NSScreen *) screen */;
- (NSAffineTransform *) _base2screen;
- (void) _screenParametersNotification:(NSNotification *) notification;
- (void) _setIsVisible:(BOOL) flag;
+ (void) _didExpose:(NSNotification *) n;	// rect of some became visible and needs to be redrawn
- (void) _didExpose:(NSNotification *) n;	// rect of this window became visible and needs to be redrawn
- (void) _setTexturedBackground:(BOOL) flag;
- (NSView *) _themeFrame;
- (void) _attachSheet:(NSWindow *) sheet;
- (void) _becomeSheet;
- (void) _allocateGraphicsContext;
@end

@interface NSFontPanel (NSPrivate)
- (void) _setPanelAttributes:(NSDictionary *) attributes isMultiple:(BOOL) multiple;
@end

@interface NSView (NSPrivate)
- (NSString *) _subtreeDescription;
- (NSAffineTransform *) _bounds2frame;
- (NSAffineTransform *) _bounds2base;
- (void) _invalidateCTM;
- (BOOL) _addRectNeedingDisplay:(NSRect) rect;
- (void) _removeRectNeedingDisplay:(NSRect) rect;
- (void) _setSuperview:(NSView *)superview;	
- (void) _drawRect:(NSRect) rect;
- (void) _setWindow:(NSWindow *) window;
- (void) layout;	// NSThemeFrame
@end

@interface NSControl (Delegation)	// although we implement this for all subclasses in NSControl, it is not an official interface
- (id) delegate;
- (void) setDelegate:(id)anObject;
@end

@interface NSButtonCell (NSPrivate)
- (NSImage *) _mixedImage;
- (void) _setMixedImage:(NSImage *)anImage;
@end

@interface NSButtonImageSource : NSObject <NSCoding>
{
	NSString *_name;
}
- (id) initWithName:(NSString *) name;
- (NSImage *) buttonImageForCell:(NSButtonCell *) cell;
@end

@interface NSMenu (NSPrivate)
- (NSString *) _longDescription;
@end

@interface NSMenuView (NSPrivate)

+ (NSMenuView *) _currentlyOpenMenuView;			// if any
+ (void) _deactivate;								// close any active menu

- (BOOL) _isResizingHorizontally;
- (void) _setHorizontalResize:(BOOL) flag;			// resize - must be changed to NO before any sizeToFit is called (indirectly)
- (BOOL) _isStatusBar;
- (void) _setStatusBar:(BOOL) flag;					// order elements from right to left and flush right
- (void) _setAttachedMenuView:(NSMenuView *) view;	// if we use setAttachedMenuView:self this menu closes after mouse-up
@end

@interface NSTabViewItem (NSPrivate)
- (void) _setTabView:(NSTabView *)tabView;
- (void) _setTabState:(NSTabState)tabState;
- (void) _setTabRect:(NSRect) rect;	
- (NSRect) _tabRect;		
@end

@interface NSTabView (NSPrivate)
- (void) _drawItem:(NSTabViewItem *) anItem;
@end

@interface NSImage (NSPrivate)
+ (id) _imageNamed:(NSString*)aName inBundle:(NSBundle *) bundle;
- (NSCachedImageRep *) _cachedImageRep;
@end

@interface NSImageCell (NSPrivate)
- (BOOL) _animates;
- (void) _setAnimates:(BOOL)flag;
@end

@interface NSComboBoxCell (NSPrivate)
- (void) _popUpCellFrame:(NSRect) cellFrame controlView:(NSView *) view;
- (void) _popDown;
@end

@interface NSScreen (NSPrivate)
#define WindowDepth(BpS, BpPx, Planar, ColorSpaceModel) ((BpS)|((BpPx)<<6)|(((Planar)!=0)<<10)|((ColorSpaceModel)<<11))
- (NSRect) _menuBarFrame;		// the application main menu bar (accessed by NSApp setMainMenu)
- (NSRect) _statusBarFrame;		// the system status menu bar (accessed by NSStatusBar)
- (NSRect) _systemMenuBarFrame;	// the system menu bar (not accessible directly by applications)
@end

@interface NSMenuItem (NSPrivate)
- (void) _changed;
@end

@interface NSStatusBar (NSPrivate)
- (NSMenuView *) _menuView;
- (id) _initWithMenuView:(NSMenuView *) v;
- (NSMenu *) _statusMenu;
@end

@interface NSStatusItem (NSPrivate)
- (NSMenuItem *) _menuItem;
- (id) _initForStatusBar:(NSStatusBar *) bar andMenuItem:(NSMenuItem *) item withLength:(CGFloat) len;
@end

#define BUTTON_EDGES_NORMAL  \
((NSRectEdge[]){ NSMaxXEdge, NSMinYEdge, NSMinXEdge,\
	NSMaxYEdge, NSMaxXEdge, NSMinYEdge })
#define BUTTON_EDGES_FLIPPED  \
((NSRectEdge[]){ NSMaxXEdge, NSMaxYEdge, NSMinXEdge,\
	NSMinYEdge, NSMaxXEdge, NSMaxYEdge })
#define BEZEL_EDGES_NORMAL  \
((NSRectEdge[]){ NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge,\
	NSMaxXEdge, NSMinYEdge, NSMinXEdge, NSMaxYEdge })
#define BEZEL_EDGES_FLIPPED  \
((NSRectEdge[]){ NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge,\
	NSMaxXEdge, NSMaxYEdge, NSMinXEdge, NSMinYEdge })

extern void GSConvertHSBtoRGB(struct HSB_Color hsb, struct RGB_Color *rgb);
extern void GSConvertRGBtoHSB(struct RGB_Color rgb, struct HSB_Color *hsb);

@interface NSCursor (NSPrivate)
+ (NSCursor *) _copyCursor;								// mySTEP extensions
+ (NSCursor *) _linkCursor;
@end

@interface NSColorSpace (NSPrivate)
+ (NSColorSpace *) _colorSpaceWithName:(NSString *) name;
- (id) _initWithColorSpaceModel:(NSColorSpaceModel) model;
@end

// extensions of functions and methods implemented in Foundation

@interface NSAffineTransform (NSPrivate)
- (NSRect) _transformRect:(NSRect) box;
@end

@interface NSRunLoop (NSPrivate)
- (void) _addInputStream:(NSInputStream *) stream forMode:(NSString *) mode;
- (void) _removeInputStream:(NSInputStream *) stream forMode:(NSString *) mode;
- (void) _addOutputStream:(NSOutputStream *) stream forMode:(NSString *) mode;
- (void) _removeOutputStream:(NSOutputStream *) stream forMode:(NSString *) mode;
@end

@interface NSText (NSPrivate)

- (NSTextStorage *) _textStorage;	// the private text storage
- (BOOL) _isSecure;
- (void) _setSecure:(BOOL)flag;

@end

@interface NSTextView (NSPrivate)

- (void) _updateTypingAttributes;

@end

@interface NSScroller (NSPrivate)

- (void) _scrollWheel:(NSEvent *) event;	// internal scrollWheel event - don't rename

@end

@interface NSScrollView (NSPrivate)

- (void) _doScroller:(NSScroller *) scroller;	// this action might be decoded from a NIB file so don't rename!

@end

@interface NSFont (NSPrivate)

- (id) _initWithDescriptor:(NSFontDescriptor *) desc;	// look up in system
- (id) _initWithName:(NSString *) postscriptName size:(CGFloat) size useDefault:(NSString *) defaultFont;

@end

@interface NSFontDescriptor (NSPrivate)

+ (NSDictionary *) _fonts;		// all known fonts (cached)
+ (void) _addDescriptor:(NSDictionary *) record;	// add font descriptor to cache
+ (void) _findFonts;			// find fonts (either in cache or by searching font directories)

@end

@interface NSSavePanel (NSPrivate)

- (BOOL) _isAllowedFile:(NSString *) path;
- (void) _setFilename:(NSString*) name;
- (BOOL) _includeNewFolderButton;					// internal methods before MacOS X 10.3
- (void) _setIncludeNewFolderButton:(BOOL) flag;

	// private action methods

- (IBAction) _home:(id)sender;
- (IBAction) _mount:(id)sender;
- (IBAction) _unmount:(id)sender;
- (IBAction) _newFolder:(id)sender;
- (IBAction) _search:(id)sender;
- (IBAction) _click:(id)sender;
- (IBAction) _doubleClick:(id)sender;

@end

@interface NSNib (NSPrivate)

- (NSBundle *) _bundle;
- (void) _setBundle:(NSBundle *) bundle;
- (id) _initWithContentsOfURL:(NSURL *) url bundle:(NSBundle *) bundle;

@end

@interface NSSplitView (NSPrivate)

- (void) setDividerThickNess: (CGFloat)newWidth;
- (float) draggedBarWidth;
- (void) setDraggedBarWidth: (CGFloat)newWidth;
- (void) setDimpleImage:(NSImage *)anImage resetDividerThickness: (BOOL)flag;
- (NSImage *) dimpleImage;
- (NSColor *) backgroundColor;
- (void) setBackgroundColor:(NSColor *)aColor;
- (NSColor *) dividerColor;
- (void) setDividerColor:(NSColor *)aColor;

@end

@interface NSToolbarItem (NSPrivate)
- (void) _setToolbar:(NSToolbar *) toolbar;
@end

@class NSToolbarView;

@interface NSToolbar (NSPrivate)
- (void) _setToolbarView:(NSToolbarView *) view;
- (NSToolbarView *) _toolbarView;
- (NSArray *) _activeItems;
@end

@interface NSEvent (NSPrivate)
- (void) _setLocation:(NSPoint) location modifierFlags:(NSUInteger) flags eventTime:(NSTimeInterval) timestamp number:(int) xnumber;
@end
