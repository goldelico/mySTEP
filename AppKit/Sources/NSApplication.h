/* 
   NSApplication.h

   Application class interface

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	16. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. November 2007 - aligned with 10.5

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSApplication
#define _mySTEP_H_NSApplication

#import <Foundation/Foundation.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSWorkspace.h>

@class NSApplication;
@class NSPasteboard;
@class NSMenu;
@class NSMenuItem;
@class NSMenuView;
@class NSImage;
@class NSImageView;
@class NSPanel;
@class NSWindow;
@class NSTextField;
@class NSDocumentController;
@class NSGraphicsContext;

typedef struct _NSModalSession *NSModalSession;

enum {
	NSRunStoppedResponse = -1000,
	NSRunAbortedResponse = -1001,
	NSRunContinuesResponse = -1002
};

enum {
	NSUpdateWindowsRunLoopOrdering = 500000
};

typedef enum _NSApplicationDelegateReply
{
	NSApplicationDelegateReplySuccess	=0,
	NSApplicationDelegateReplyCancel	=1,
	NSApplicationDelegateReplyFailure	=2
} NSApplicationDelegateReply;

typedef enum _NSApplicationTerminateReply
{
	NSTerminateCancel = NO,
	NSTerminateNow = YES,
	NSTerminateLater
} NSApplicationTerminateReply;

typedef enum _NSApplicationPrintReply
{
	NSPrintingCancelled = NO,
	NSPrintingSuccess = YES,
	NSPrintingFailure,
	NSPrintingReplyLater
} NSApplicationPrintReply;

typedef enum _NSRequestUserAttentionType
{
	NSCriticalRequest,
	NSInformationalRequest=10
} NSRequestUserAttentionType;

extern NSString *NSModalPanelRunLoopMode;
extern NSString *NSEventTrackingRunLoopMode;

extern NSString *NSApplicationIcon;	// App Icon key into NSBundle
extern id NSApp;					// NSApp global var

@interface NSApplication : NSResponder  <NSCoding>
{
	NSMutableArray *_eventQueue;
	NSEvent *_currentEvent;
	NSModalSession _session;
	NSWindow *_keyWindow;
	NSWindow *_mainWindow;
	NSPanel *_mainMenuWindow;			// the main menu window
	NSMenuView *_mainMenuView;			// the main menu view; the main menu is the menu iVar of NSResponder
	NSMenu *_windowsMenu;				// the windows menu
	NSImage *_appIcon;
	NSWindow *_appIconWindow;
	NSWindow *_pendingWindow;
	NSMutableArray *_hiddenWindows;	// list of hidden windows during deactivate
	
	id _listener;
	id _delegate;

	IBOutlet NSPanel *_aboutPanel;
	IBOutlet NSTextField *_credits;
	IBOutlet NSTextField *_applicationName;
	IBOutlet NSImageView *_applicationImage;
	IBOutlet NSTextField *_version;
	IBOutlet NSTextField *_copyright;
	IBOutlet NSTextField *_applicationVersion;
			
	NSInteger _windowItems;					// counter for explicitly added/removed menu items

	struct __appFlags {
		unsigned int isRunning:1;
		unsigned int isHidden:1;
		unsigned int windowsNeedUpdate:1;
		unsigned int disableServices:1;
		unsigned int isDeallocating:1;
		unsigned int reserved:3;
	} _app;
}

+ (void) detachDrawingThread:(SEL) sel toTarget:(id) target withObject:(id) arg;
+ (NSApplication *) sharedApplication;

- (void) abortModal;										// Event loop
- (void) activateContextHelpMode:(id) sender;
- (void) activateIgnoringOtherApps:(BOOL) flag;				// activate app
- (void) addWindowsItem:(NSWindow *) window	title:(NSString *) title filename:(BOOL) isFile;
- (NSImage *) applicationIconImage;
- (void) arrangeInFront:(id) sender;
- (NSModalSession) beginModalSessionForWindow:(NSWindow *) window;
- (NSModalSession) beginModalSessionForWindow:(NSWindow *) window relativeToWindow:(NSWindow *) documentWindow; /* DEPRECATED */
- (void) beginSheet:(NSWindow *) window modalForWindow:(NSWindow *) doc modalDelegate:(id) delegate didEndSelector:(SEL) selector contextInfo:(void *) context;
- (void) cancelUserAttentionRequest:(NSInteger) req;
- (void) changeWindowsItem:(NSWindow *) window title:(NSString *) string filename:(BOOL) isFile;
- (NSGraphicsContext *) context;										// Display context
- (NSEvent*) currentEvent;									// Events
- (void) deactivate;
- (id) delegate;
- (void) discardEventsMatchingMask:(NSUInteger) matchingMask beforeEvent:(NSEvent *) event;
- (void) endModalSession:(NSModalSession) aSession;
- (void) endSheet:(NSWindow *) aSheet;
- (void) endSheet:(NSWindow *) aSheet returnCode:(int) ret;
- (void) finishLaunching;
- (void) hide:(id) sender;										// Hiding windows
- (void) hideOtherApplications:(id) sender;
- (BOOL) isActive;
- (BOOL) isHidden;
- (BOOL) isRunning;
- (NSWindow *) keyWindow;									// Managing windows
- (NSMenu *) mainMenu;										// Main menu
- (NSWindow *) mainWindow;
- (NSWindow *) makeWindowsPerform:(SEL) sel inOrder:(BOOL) flag;
- (void) miniaturizeAll:(id) sender;
- (NSWindow *) modalWindow;
- (NSEvent *) nextEventMatchingMask:(NSUInteger) matchingMask untilDate:(NSDate *) expirationDate inMode:(NSString *) mode dequeue:(BOOL) flag;
- (NSArray *) orderedDocuments;
- (NSArray *) orderedWindows;
- (void) orderFrontCharacterPalette:(id) sender;					// Show std Panels
- (void) orderFrontColorPanel:(id) sender;						// Show std Panels
- (void) orderFrontStandardAboutPanel:(id) sender;
- (void) orderFrontStandardAboutPanelWithOptions:(NSDictionary *) options;
- (void) postEvent:(NSEvent *) event atStart:(BOOL) flag;
- (void) preventWindowOrdering;
- (void) registerServicesMenuSendTypes:(NSArray *) send returnTypes:(NSArray *) ret;
- (void) removeWindowsItem:(NSWindow *) window;
- (void) replyToApplicationShouldTerminate:(BOOL) flag;	// call if delegate returned NSTerminateLater
- (void) replyToOpenOrPrint:(NSApplicationDelegateReply) rep;
- (void) reportException:(NSException *) exception;		// Report exception
- (int) requestUserAttention:(NSRequestUserAttentionType) request;
- (void) run;
- (NSInteger) runModalForWindow:(NSWindow *) window;
- (NSInteger) runModalForWindow:(NSWindow *) aWindow relativeToWindow:(NSWindow *) docWindow;	/* DEPRECATED */
- (NSInteger) runModalSession:(NSModalSession) session;
- (void) runPageLayout:(id) sender;
- (BOOL) sendAction:(SEL) sel to:(id) target from:(id) sender;
- (void) sendEvent:(NSEvent *)event;
- (NSMenu *) servicesMenu;									// Service menu
- (id) servicesProvider;
// - (void) setAppleMenu:(NSMenu *)aMenu;						// set first entry of the mainMenu
- (void) setApplicationIconImage:(NSImage *) image;		// app's icon
- (void) setDelegate:(id) delegate;
- (void) setMainMenu:(NSMenu *) menu;
- (void) setServicesMenu:(NSMenu *) menu;
- (void) setServicesProvider:(id) provider;
- (void) setWindowsMenu:(NSMenu *) menu;
- (void) setWindowsNeedUpdate:(BOOL) flag;
- (void) showHelp:(id) sender;
- (void) stop:(id) sender;
- (void) stopModal;
- (void) stopModalWithCode:(NSInteger) ret;
- (id) targetForAction:(SEL) selector;						// target / action
- (id) targetForAction:(SEL) selector to:(id) target from:(id) sender;
- (void) terminate:(id) sender;									// Terminate app
- (BOOL) tryToPerform:(SEL)selector with:(id) object;
- (void) unhide:(id) sender;
- (void) unhideAllApplications:(id) sender;
- (void) unhideWithoutActivation;
- (void) updateWindows;
- (void) updateWindowsItem:(NSWindow *) window;
- (id) validRequestorForSendType:(NSString *) send returnType:(NSString *) ret;
- (NSArray *) windows;
- (NSMenu*) windowsMenu;
- (NSWindow *) windowWithWindowNumber:(NSInteger) num;

@end

@protocol NSApplicationDelegate	// did appear in 10.6

- (void) applicationWillFinishLaunching:(NSNotification *) notification;
- (void) applicationDidFinishLaunching:(NSNotification *) notification;

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) app;
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app;
- (void) applicationWillTerminate:(NSNotification *) notification;

- (void) applicationWillBecomeActive:(NSNotification *) notification;
- (void) applicationWillResignActive:(NSNotification *) notification;
- (void) applicationDidResignActive:(NSNotification *) notification;

- (void) applicationWillHide:(NSNotification *) notification;
- (void) applicationDidHide:(NSNotification *) notification;
- (void) applicationWillUnhide:(NSNotification *) notification;
- (void) applicationDidUnhide:(NSNotification *) notification;

- (void) applicationWillUpdate:(NSNotification *) notification;
- (void) applicationDidUpdate:(NSNotification *) notification;
- (BOOL) applicationShouldHandleReopen:(NSApplication *) app hasVisibleWindows:(BOOL) flag;

- (NSMenu *) applicationDockMenu:(NSApplication *) sender;

- (NSError *) application:(NSApplication *) app willPresentError:(NSError *) error;

- (void) applicationDidChangeScreenParameters:(NSNotification *) notification;

- (BOOL) application:(NSApplication *) app openFile:(NSString *) file;
- (void) application:(NSApplication *) app openFiles:(NSArray *) files;
- (BOOL) application:(NSApplication *) app openFileWithoutUI:(NSString *) file;
- (BOOL) application:(NSApplication *) app openTempFile:(NSString *) file;
- (BOOL) applicationOpenUntitledFile:(NSApplication *) app;
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) app;

- (BOOL) application:(NSApplication *) app printFile:(NSString *) file;
- (NSApplicationPrintReply) application:(NSApplication *) app printFiles:(NSArray *) files withSettings:(NSDictionary *) settings showPrintPanels:(BOOL) flag;

@end

// FIXME: can we simply reference the protocol in the category?

@interface NSObject (NSApplicationDelegate)					// Implemented by
															// the delegate

- (BOOL) application:(NSApplication *) sender delegateHandlesKey:(NSString *) value;
- (BOOL) application:(NSApplication *) app openFile:(NSString *) file;
- (void) application:(NSApplication *) app openFiles:(NSArray *) files;
- (BOOL) application:(NSApplication *) app openFileWithoutUI:(NSString *) file;
- (BOOL) application:(NSApplication *) app openTempFile:(NSString *) file;
- (BOOL) applicationOpenUntitledFile:(NSApplication *) app;
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *) app;
- (BOOL) applicationShouldHandleReopen:(NSApplication *) app hasVisibleWindows:(BOOL) flag;

- (BOOL) application:(NSApplication *) app printFile:(NSString *) file;
- (void) application:(NSApplication *) app printFiles:(NSArray *) files;
- (NSApplicationPrintReply) application:(NSApplication *) app printFiles:(NSArray *) files withSettings:(NSDictionary *) settings showPrintPanels:(BOOL) flag;

- (NSMenu *) applicationDockMenu:(NSApplication *) sender;

- (void) applicationDidChangeScreenParameters:(NSNotification *) notification;

- (void) applicationDidBecomeActive:(NSNotification *) notification;
- (void) applicationDidFinishLaunching:(NSNotification *) notification;
- (void) applicationDidHide:(NSNotification *) notification;
- (void) applicationDidResignActive:(NSNotification *) notification;
- (void) applicationDidUnhide:(NSNotification *) notification;
- (void) applicationDidUpdate:(NSNotification *) notification;
- (void) applicationWillBecomeActive:(NSNotification *) notification;
- (void) applicationWillFinishLaunching:(NSNotification *) notification;
- (void) applicationWillHide:(NSNotification *) notification;
- (void) applicationWillResignActive:(NSNotification *) notification;
- (void) applicationWillUnhide:(NSNotification *) notification;
- (void) applicationWillUpdate:(NSNotification *) notification;

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *) app;
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *) app;
- (void) applicationWillTerminate:(NSNotification *) notification;

- (NSError *) application:(NSApplication *) app willPresentError:(NSError *) error;

@end


@interface NSObject (NSServicesRequests)					// Pasteboard

- (BOOL) readSelectionFromPasteboard:(NSPasteboard *) pboard;
- (BOOL) writeSelectionToPasteboard:(NSPasteboard *) pboard
                              types:(NSArray *) types;
@end


extern NSString *NSApplicationDidBecomeActiveNotification;
extern NSString *NSApplicationDidChangeScreenParametersNotification;
extern NSString *NSApplicationDidFinishLaunchingNotification;
extern NSString *NSApplicationDidHideNotification;
extern NSString *NSApplicationDidResignActiveNotification;
extern NSString *NSApplicationDidUnhideNotification;
extern NSString *NSApplicationDidUpdateNotification;
extern NSString *NSApplicationWillBecomeActiveNotification;
extern NSString *NSApplicationWillFinishLaunchingNotification;
extern NSString *NSApplicationWillTerminateNotification;
extern NSString *NSApplicationWillHideNotification;
extern NSString *NSApplicationWillResignActiveNotification;
extern NSString *NSApplicationWillTerminateNotification;
extern NSString *NSApplicationWillUnhideNotification;
extern NSString *NSApplicationWillUpdateNotification;

//
// Enable / Disable Services Menu Items
//

int NSSetShowsServicesMenuItem(NSString *item, BOOL showService);
BOOL NSShowsServicesMenuItem(NSString *item);
BOOL NSPerformService(NSString *item, NSPasteboard *pboard);
void NSUpdateDynamicServices(void);
void NSRegisterServicesProvider(id provider, NSString *name);
void NSUnregisterServicesProvider(NSString *name);

int NSApplicationMain(int argc, const char *argv[]);

#endif /* _mySTEP_H_NSApplication */
