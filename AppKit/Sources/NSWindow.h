/* 

 NSWindow.h
 
 Window class
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:	Scott Christley <scottc@net-community.com>
 Date:		1996
 
 Modified:  Felipe A. Rodriguez <far@ix.netcom.com>
 Date:		June 1998
 
 Modified:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:		1998,1999
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		Feb 2006 - aligned with 10.4
 
 Author:    Fabian Spillner <fabian.spillner@gmail.com>
 Date:      20. December 2007 - aligned with 10.5

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.

*/ 

#ifndef _mySTEP_H_NSWindow
#define _mySTEP_H_NSWindow

#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSResponder.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSData;
@class NSDictionary;
@class NSNotification;
@class NSDate;
@class NSCachedImageRep;
@class NSDockTile; 
@class NSButton;
@class NSButtonCell;
@class NSColor;
@class NSImage;
@class NSScreen;
@class NSEvent;
@class NSGraphicsContext;
@class NSPasteboard;
@class NSMenu;
@class NSView;
@class NSText;
@class NSScreen;
@class NSToolbar;
@class NSWindowController;
@class NSAffineTransform;
@class NSUndoManager;
@class NSShadow;

enum
{
	NSNormalWindowLevel	  = 4,
	NSFloatingWindowLevel = 5,
	NSSubmenuWindowLevel  = 6,
	NSTornOffMenuWindowLevel = NSSubmenuWindowLevel,
	NSDockWindowLevel	  = 7,		// disappeared in 10.4
	NSMainMenuWindowLevel = 8,
	NSStatusWindowLevel   = 9,
	NSModalPanelWindowLevel = 10,
	NSPopUpMenuWindowLevel = 11,
	NSScreenSaverWindowLevel = 13
};

enum
{
	NSBorderlessWindowMask				= 0,
	NSTitledWindowMask					= 1,
	NSClosableWindowMask				= 2,
	NSMiniaturizableWindowMask			= 4,
	NSResizableWindowMask				= 8,
	GSAllWindowMask						= 15,						// OR'd combo of others 
	NSTexturedBackgroundWindowMask		= 256,
	NSUnscaledWindowMask				= 2048,
	NSUnifiedTitleAndToolbarWindowMask	= 4096
};

typedef enum _NSWindowOrderingMode
{ // Window ordering
	NSWindowBelow = -1,
	NSWindowOut,
	NSWindowAbove
} NSWindowOrderingMode;

typedef enum _NSWindowButton
{
	NSWindowCloseButton=0,			// red circle
	NSWindowMiniaturizeButton,		// yellow circle
	NSWindowZoomButton,				// green circle
	NSWindowToolbarButton,			// white oval
	NSWindowDocumentIconButton		// image button
} NSWindowButton;

typedef enum _NSSelectionDirection
{
	NSDirectSelection=0,
	NSSelectingNext,
	NSSelectingPrevious
} NSSelectionDirection;

enum {
	NSDisplayWindowRunLoopOrdering,
	NSResetCursorRectsRunLoopOrdering
};

typedef struct NSWindowAuxiliary NSWindowAuxiliaryOpaque;

enum {
	NSWindowSharingNone = 0,
	NSWindowSharingReadOnly = 1,
	NSWindowSharingReadWrite = 2
};
typedef NSUInteger NSWindowSharingType;

enum {
	NSWindowBackingLocationDefault = 0,
	NSWindowBackingLocationVideoMemory = 1,
	NSWindowBackingLocationMainMemory = 2
};
typedef NSUInteger NSWindowBackingLocation;

enum {
	NSWindowCollectionBehaviorDefault = 0,
	NSWindowCollectionBehaviorCanJoinAllSpaces = 1 << 0,
	NSWindowCollectionBehaviorMoveToActiveSpace = 1 << 1
};
typedef NSUInteger NSWindowCollectionBehavior;

@interface NSWindow : NSResponder  <NSCoding>
{
	NSRect _frame;		// window frame rect in NSScreen coordinates
	NSRect _oldFrame;	// when zoom was applied
	NSSize _minSize;
	NSSize _maxSize;
	NSSize _resizeIncrements;
	id _delegate;
	id _fieldEditor;
	NSView *_themeFrame;	// start of view hierarchy
	NSResponder *_firstResponder;
	NSView *_initialFirstResponder;
	NSString *_representedFilename;
    NSString *_frameSaveName;
	NSString *_windowTitle;
	NSString *_miniWindowTitle;
	NSImage *_miniWindowImage;
	NSScreen *_screen;
	NSGraphicsContext *_context;	// our context
	NSMutableArray *_trackRects;
	NSMutableArray *_cursorRects;
	NSWindowController * _windowController;
	NSButtonCell *_defaultButtonCell;
	NSShadow *_shadow;
	NSCachedImageRep *_cachedRep;
	NSMutableArray *_childWindows;
	NSWindow *_parentWindow;
	NSWindow *_attachedSheet;
	NSNotification *autoDisplayNotification;

	CGFloat _userSpaceScaleFactor;

	int _disableFlushWindow;
	int _level;
	int _gState;
	
    struct __WindowFlags {
		UIBITFIELD(unsigned int, isOneShot, 1);
		UIBITFIELD(unsigned int, viewsNeedDisplay, 1);
		UIBITFIELD(unsigned int, autodisplay, 1);
		UIBITFIELD(unsigned int, optimizeDrawing, 1);
		UIBITFIELD(unsigned int, dynamicDepthLimit, 1);
		UIBITFIELD(unsigned int, cursorRectsEnabled, 1);
		UIBITFIELD(unsigned int, cursorRectsValid, 1);
		UIBITFIELD(unsigned int, visible, 1);
		UIBITFIELD(unsigned int, isKey, 1);
		UIBITFIELD(unsigned int, isMain, 1);
		UIBITFIELD(unsigned int, isEdited, 1);
		UIBITFIELD(unsigned int, releasedWhenClosed, 1);
		UIBITFIELD(unsigned int, miniaturized, 1);
		UIBITFIELD(unsigned int, menuExclude, 1);
		UIBITFIELD(unsigned int, hidesOnDeactivate, 1);
		UIBITFIELD(unsigned int, acceptsMouseMoved, 1);
		UIBITFIELD(unsigned int, appIcon, 1);
		TYPEDBITFIELD(NSBackingStoreType, backingType, 2);
		UIBITFIELD(unsigned int, depthLimit, 4);
		UIBITFIELD(unsigned int, styleMask, 4);
		UIBITFIELD(unsigned int, isZoomed, 1);
		UIBITFIELD(unsigned int, ignoresMouseEvents, 1);
		UIBITFIELD(unsigned int, hasShadow, 1);
		UIBITFIELD(unsigned int, canHide, 1);
		UIBITFIELD(unsigned int, isOpaque, 1);
		UIBITFIELD(unsigned int, isSheet, 1);
	} _w;
}

+ (NSRect) contentRectForFrameRect:(NSRect) aRect
						 styleMask:(NSUInteger) aStyle;
+ (NSWindowDepth) defaultDepthLimit;
+ (NSRect) frameRectForContentRect:(NSRect) aRect
						 styleMask:(NSUInteger) aStyle;
+ (void) menuChanged:(NSMenu *) menu;
+ (CGFloat) minFrameWidthWithTitle:(NSString *) aTitle
						styleMask:(NSUInteger) aStyle;
+ (void) removeFrameUsingName:(NSString *) name;
+ (NSButton *) standardWindowButton:(NSWindowButton) button forStyleMask:(NSUInteger) mask;

- (BOOL) acceptsMouseMovedEvents;
- (void) addChildWindow:(NSWindow *) child ordered:(NSWindowOrderingMode) place;
- (BOOL) allowsToolTipsWhenApplicationIsInactive;
- (CGFloat) alphaValue;
- (NSTimeInterval) animationResizeTime:(NSRect) frame;
- (BOOL) areCursorRectsEnabled;	
- (NSSize) aspectRatio;
- (NSWindow *) attachedSheet;
- (BOOL) autorecalculatesContentBorderThicknessForEdge:(NSRectEdge) rectEdge; 
- (BOOL) autorecalculatesKeyViewLoop;
- (NSColor *) backgroundColor;
- (NSWindowBackingLocation) backingLocation; 
- (NSBackingStoreType) backingType;
- (void) becomeKeyWindow;
- (void) becomeMainWindow;
- (void) cacheImageInRect:(NSRect) rect;
- (BOOL) canBecomeKeyWindow;
- (BOOL) canBecomeMainWindow;
- (BOOL) canBecomeVisibleWithoutLogin; 
- (BOOL) canHide;
- (BOOL) canStoreColor;
- (NSPoint) cascadeTopLeftFromPoint:(NSPoint) topLeftPoint;
- (void) center;
- (NSArray *) childWindows;
- (void) close;
- (NSWindowCollectionBehavior) collectionBehavior;
- (NSRect) constrainFrameRect:(NSRect) frame toScreen:(NSScreen *) screen;
- (NSSize) contentAspectRatio;
- (CGFloat) contentBorderThicknessForEdge:(NSRectEdge) edge; 
- (NSSize) contentMaxSize;
- (NSSize) contentMinSize;
- (NSRect) contentRectForFrameRect:(NSRect) frameRect;
- (NSSize) contentResizeIncrements;
- (id) contentView;
- (NSPoint) convertBaseToScreen:(NSPoint) aPoint;
- (NSPoint) convertScreenToBase:(NSPoint) aPoint;
- (NSEvent *) currentEvent;
- (NSData *) dataWithEPSInsideRect:(NSRect) rect;
- (NSData *) dataWithPDFInsideRect:(NSRect) rect;
- (NSScreen *) deepestScreen;
- (NSButtonCell *) defaultButtonCell;
- (id) delegate;
- (void) deminiaturize:(id) sender;
- (NSWindowDepth) depthLimit;
- (NSDictionary *) deviceDescription;
- (void) disableCursorRects;
- (void) disableFlushWindow;
- (void) disableKeyEquivalentForDefaultButtonCell;
- (void) disableScreenUpdatesUntilFlush;
- (void) discardCachedImage;
- (void) discardCursorRects;
- (void) discardEventsMatchingMask:(NSUInteger) mask beforeEvent:(NSEvent *) lastEvent;
- (void) display;
- (void) displayIfNeeded;
- (BOOL) displaysWhenScreenProfileChanges;
- (NSDockTile *) dockTile; 
- (void) dragImage:(NSImage *) anImage
				at:(NSPoint) baseLocation 
			offset:(NSSize) initialOffset
			 event:(NSEvent *) event
		pasteboard:(NSPasteboard *) pboard
			source:(id) sourceObject
		 slideBack:(BOOL) slideFlag;
- (NSArray *) drawers;
- (void) enableCursorRects;
- (void) enableFlushWindow;
- (void) enableKeyEquivalentForDefaultButtonCell;
- (void) endEditingFor:(id) anObject;
- (NSText *) fieldEditor:(BOOL) create forObject:(id) anObject;
- (NSResponder *) firstResponder;
- (void) flushWindow;
- (void) flushWindowIfNeeded;
- (NSRect) frame;
- (NSString *) frameAutosaveName;
- (NSRect) frameRectForContentRect:(NSRect) contentRect;
- (NSGraphicsContext *) graphicsContext;
- (NSInteger) gState;
- (BOOL) hasDynamicDepthLimit;
- (BOOL) hasShadow;
- (BOOL) hidesOnDeactivate;
- (BOOL) ignoresMouseEvents;
- (NSView *) initialFirstResponder;
- (id) initWithContentRect:(NSRect)contentRect
				 styleMask:(NSUInteger) aStyle
				   backing:(NSBackingStoreType) bufferingType
					 defer:(BOOL) flag;
- (id) initWithContentRect:(NSRect) contentRect
				 styleMask:(NSUInteger) aStyle
				   backing:(NSBackingStoreType) bufferingType
					 defer:(BOOL) flag
					screen:(NSScreen *) aScreen;
- (NSWindow *) initWithWindowRef:(void *) windowRef;
- (void) invalidateCursorRectsForView:(NSView *) aView;
- (void) invalidateShadow;
- (BOOL) isAutodisplay;
- (BOOL) isDocumentEdited;
- (BOOL) isExcludedFromWindowsMenu;
- (BOOL) isFlushWindowDisabled;
- (BOOL) isKeyWindow;
- (BOOL) isMainWindow;
- (BOOL) isMiniaturized;
- (BOOL) isMovableByWindowBackground;
- (BOOL) isOneShot;
- (BOOL) isOpaque;
- (BOOL) isReleasedWhenClosed;
- (BOOL) isSheet;
- (BOOL) isVisible;
- (BOOL) isZoomed;
- (void) keyDown:(NSEvent *) event;
- (NSSelectionDirection) keyViewSelectionDirection;
- (NSInteger) level;
- (BOOL) makeFirstResponder:(NSResponder *) aResponder;
- (void) makeKeyAndOrderFront:(id) sender;
- (void) makeKeyWindow;
- (void) makeMainWindow;
- (NSSize) maxSize;
- (void) miniaturize:(id) sender;
- (NSImage *) miniwindowImage;								// Miniwindow
- (NSString *) miniwindowTitle;
- (NSSize) minSize;
- (NSPoint) mouseLocationOutsideOfEventStream;
- (NSEvent *) nextEventMatchingMask:(NSUInteger) mask;
- (NSEvent *) nextEventMatchingMask:(NSUInteger) mask
						  untilDate:(NSDate *) expiration
							 inMode:(NSString *) mode
							dequeue:(BOOL) deqFlag;
- (void) orderBack:(id) sender;
- (void) orderFront:(id) sender;
- (void) orderFrontRegardless;
- (void) orderOut:(id) sender;
- (void) orderWindow:(NSWindowOrderingMode) place relativeTo:(NSInteger) otherWin;
- (NSWindow *) parentWindow;
- (void) performClose:(id) sender;
- (void) performMiniaturize:(id) sender;
- (void) performZoom:(id) sender;
- (void) postEvent:(NSEvent *) event atStart:(BOOL) flag;
- (NSWindowBackingLocation) preferredBackingLocation; 
- (BOOL) preservesContentDuringLiveResize;
- (void) print:(id) sender;
- (void) recalculateKeyViewLoop;
- (void) registerForDraggedTypes:(NSArray *) newTypes;
- (void) removeChildWindow:(NSWindow *) child;
- (NSString *) representedFilename;
- (NSURL *)representedURL; 
- (void) resetCursorRects;
- (void) resignKeyWindow;
- (void) resignMainWindow;
- (int) resizeFlags;
- (NSSize) resizeIncrements;
- (void) restoreCachedImage;
- (void) runToolbarCustomizationPalette:(id) sender;
- (void) saveFrameUsingName:(NSString *) name;
- (NSScreen *) screen;
- (void) selectKeyViewFollowingView:(NSView *) view;
- (void) selectKeyViewPrecedingView:(NSView *) view;
- (void) selectNextKeyView:(id) sender;
- (void) selectPreviousKeyView:(id) sender;
- (void) sendEvent:(NSEvent *) event;
- (void) setAcceptsMouseMovedEvents:(BOOL) flag;
- (void) setAllowsToolTipsWhenApplicationIsInactive:(BOOL) flag;
- (void) setAlphaValue:(CGFloat) alpha;
- (void) setAspectRatio:(NSSize) ratio;
- (void) setAutodisplay:(BOOL) flag;
- (void) setAutorecalculatesContentBorderThickness:(BOOL) thickness forEdge:(NSRectEdge) edge; 
- (void) setAutorecalculatesKeyViewLoop:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBackingType:(NSBackingStoreType) type;
- (void) setCanBecomeVisibleWithoutLogin:(BOOL) flag; 
- (void) setCanHide:(BOOL) flag;
- (void) setCollectionBehavior:(NSWindowCollectionBehavior) behavior;
- (void) setContentAspectRatio:(NSSize) ratio;
- (void) setContentBorderThickness:(CGFloat) thickness forEdge:(NSRectEdge) edge; 
- (void) setContentMaxSize:(NSSize) size;
- (void) setContentMinSize:(NSSize) size;
- (void) setContentResizeIncrements:(NSSize) increments;
- (void) setContentSize:(NSSize) size;
- (void) setContentView:(NSView *) view;
- (void) setDefaultButtonCell:(NSButtonCell *) cell;	// default responder for \r
- (void) setDelegate:(id) anObject;
- (void) setDepthLimit:(NSWindowDepth) limit;
- (void) setDisplaysWhenScreenProfileChanges:(BOOL) flag;
- (void) setDocumentEdited:(BOOL) flag;
- (void) setDynamicDepthLimit:(BOOL) flag;
- (void) setExcludedFromWindowsMenu:(BOOL) flag;
- (void) setFrame:(NSRect) frame display:(BOOL) flag;
- (void) setFrame:(NSRect) frame display:(BOOL) flag animate:(BOOL) animate;
- (BOOL) setFrameAutosaveName:(NSString *) name;
- (void) setFrameFromString:(NSString *) string;
- (void) setFrameOrigin:(NSPoint) aPoint;
- (void) setFrameTopLeftPoint:(NSPoint) aPoint;
- (BOOL) setFrameUsingName:(NSString *) name;
- (BOOL) setFrameUsingName:(NSString *) name force:(BOOL) flag;
- (void) setHasShadow:(BOOL) flag;
- (void) setHidesOnDeactivate:(BOOL) flag;
- (void) setIgnoresMouseEvents:(BOOL) flag;
- (void) setInitialFirstResponder:(NSView *) view;
- (void) setLevel:(NSInteger) newLevel;
- (void) setMaxSize:(NSSize) aSize;
- (void) setMiniwindowImage:(NSImage *) image;
- (void) setMiniwindowTitle:(NSString *) title;
- (void) setMinSize:(NSSize) aSize;
- (void) setMovableByWindowBackground:(BOOL) flag;
- (void) setOneShot:(BOOL) flag;
- (void) setOpaque:(BOOL) flag;
- (void) setParentWindow:(NSWindow *) window;
- (void) setPreferredBackingLocation:(NSWindowBackingLocation) backLoc; 
- (void) setPreservesContentDuringLiveResize:(BOOL) flag;
- (void) setReleasedWhenClosed:(BOOL) flag;
- (void) setRepresentedFilename:(NSString *) aString;
- (void) setRepresentedURL:(NSURL *) url; 
- (void) setResizeIncrements:(NSSize) aSize;
- (void) setSharingType:(NSWindowSharingType) type; 
- (void) setShowsResizeIndicator:(BOOL) flag;
- (void) setShowsToolbarButton:(BOOL) flag;
- (void) setTitle:(NSString *) aString;
- (void) setTitleWithRepresentedFilename:(NSString *) aString;
- (void) setToolbar:(NSToolbar *) toolbar;
- (void) setViewsNeedDisplay:(BOOL) flag;
- (void) setWindowController:(NSWindowController *) windowController;
- (NSWindowSharingType) sharingType; 
- (BOOL) showsResizeIndicator;
- (BOOL) showsToolbarButton;
- (NSButton *) standardWindowButton:(NSWindowButton) button;
- (NSString *) stringWithSavedFrame;
- (NSUInteger) styleMask;
- (NSString *) title;
- (void) toggleToolbarShown:(id) sender;
- (NSToolbar *) toolbar;
- (BOOL) tryToPerform:(SEL) anAction with:(id) anObject;
- (void) unregisterDraggedTypes;
- (void) update;
- (void) useOptimizedDrawing:(BOOL) flag;
- (CGFloat) userSpaceScaleFactor;
- (id) validRequestorForSendType:(NSString *) sendType
					  returnType:(NSString *) returnType;
- (BOOL) viewsNeedDisplay;
- (id) windowController;
- (NSInteger) windowNumber;
- (void *) windowRef;
- (BOOL) worksWhenModal;
- (void) zoom:(id) sender;

@end


@interface NSObject (NSWindowDelegate)

- (BOOL) window:(NSWindow *) sender shouldDragDocumentWithEvent:(NSEvent *) evt from:(NSPoint) pt withPasteboard:(NSPasteboard *) pboard; 
- (BOOL) window:(NSWindow *) sender shouldPopUpDocumentPathMenu:(NSMenu *) menu; 
- (NSRect) window:(NSWindow *) sender willPositionSheet:(NSWindow *) sheet usingRect:(NSRect) rect;
- (BOOL) windowShouldClose:(id) sender;
- (BOOL) windowShouldZoom:(NSWindow *) sender toFrame:(NSRect) frame;
- (NSSize) windowWillResize:(NSWindow *) sender toSize:(NSSize) size;
- (id) windowWillReturnFieldEditor:(NSWindow *) sender toObject:(id) object;
- (NSUndoManager *) windowWillReturnUndoManager:(NSWindow *) sender;
- (NSRect) windowWillUseStandardFrame:(NSWindow *) sender defaultFrame:(NSRect) frame;

@end


@interface NSObject (NSWindowNotifications)

- (void) windowDidBecomeKey:(NSNotification *) aNotification;
- (void) windowDidBecomeMain:(NSNotification *) aNotification;
- (void) windowDidChangeScreen:(NSNotification *) aNotification;
- (void) windowDidChangeScreenProfile:(NSNotification *) aNotification;
- (void) windowDidDeminiaturize:(NSNotification *) aNotification;
- (void) windowDidEndSheet:(NSNotification *) aNotification;
- (void) windowDidExpose:(NSNotification *) aNotification;
- (void) windowDidMiniaturize:(NSNotification *) aNotification;
- (void) windowDidMove:(NSNotification *) aNotification;
- (void) windowDidResignKey:(NSNotification *) aNotification;
- (void) windowDidResignMain:(NSNotification *) aNotification;
- (void) windowDidResize:(NSNotification *) aNotification;
- (void) windowDidUpdate:(NSNotification *) aNotification;
- (void) windowWillBeginSheet:(NSNotification *) aNotification;
- (void) windowWillClose:(NSNotification *) aNotification;
- (void) windowWillMiniaturize:(NSNotification *) aNotification;
- (void) windowWillMove:(NSNotification *) aNotification;

@end

extern NSString *NSWindowManagerException;

extern NSString *NSWindowDidBecomeKeyNotification;			// Notifications
extern NSString *NSWindowDidBecomeMainNotification;
extern NSString *NSWindowDidChangeScreenNotification;
extern NSString *NSWindowDidChangeScreenProfileNotification;
extern NSString *NSWindowDidDeminiaturizeNotification;
extern NSString *NSWindowDidEndSheetNotification;
extern NSString *NSWindowDidExposeNotification;
extern NSString *NSWindowDidMiniaturizeNotification;
extern NSString *NSWindowDidMoveNotification;
extern NSString *NSWindowDidResignKeyNotification;
extern NSString *NSWindowDidResignMainNotification;
extern NSString *NSWindowDidResizeNotification;
extern NSString *NSWindowDidUpdateNotification;
extern NSString *NSWindowWillbeginSheetNotification;
extern NSString *NSWindowWillCloseNotification;
extern NSString *NSWindowWillMiniaturizeNotification;
extern NSString *NSWindowWillMoveNotification;

#endif /* _mySTEP_H_NSWindow */
