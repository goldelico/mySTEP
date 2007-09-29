/* 
   NSApplication.h

   Application class interface

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

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
	id _keyWindow;
	id _mainWindow;
	id _listener;
	NSPanel *_mainMenuWindow;					// the main menu window
	NSMenuView *_mainMenuView;				// the main menu view; the main menu is the menu iVar of NSResponder
//	NSMenuItem *_windowsMenuItem;		// the "Windows" item in the main menu
	NSMenu *_windowsMenu;							// the windows menu
	int _windowItems;									// counter for explicitly added/removed menu items
	NSImage *_appIcon;
	NSWindow *_appIconWindow;
	NSWindow *_pendingWindow;
	id _delegate;
	IBOutlet NSPanel *_aboutPanel;
	IBOutlet NSTextField *_credits;
	IBOutlet NSTextField *_applicationName;
	IBOutlet NSImageView *_applicationImage;
	IBOutlet NSTextField *_version;
	IBOutlet NSTextField *_copyright;
	IBOutlet NSTextField *_applicationVersion;
			
    struct __appFlags {
		unsigned int isRunning:1;
        unsigned int isActive:1;
        unsigned int isHidden:1;
		unsigned int windowsNeedUpdate:1;
		unsigned int disableServices:1;
		unsigned int isDeallocating:1;
		unsigned int reserved:2;
    } _app;
}

+ (void) detachDrawingThread:(SEL) selector toTarget:(id) target withObject:(id) argument;
+ (NSApplication *) sharedApplication;

- (void) abortModal;										// Event loop
- (void) activateContextHelpMode:(id)sender;
- (void) activateIgnoringOtherApps:(BOOL)flag;				// activate app
- (void) addWindowsItem:(NSWindow *) aWindow								// Windows menu
				  title:(NSString *) aString
			   filename:(BOOL) isFilename;
- (NSImage *) applicationIconImage;
- (void) arrangeInFront:(id) sender;
- (NSModalSession) beginModalSessionForWindow:(NSWindow *) aWindow;
- (NSModalSession) beginModalSessionForWindow:(NSWindow *) aWindow
							 relativeToWindow:(NSWindow *) docWindow;
- (void) beginSheet:(NSWindow *) sheet
	 modalForWindow:(NSWindow *) doc
	  modalDelegate:(id) delegate
	 didEndSelector:(SEL) selector
		contextInfo:(void *) context;
- (void) cancelUserAttentionRequest:(int) request;
- (void) changeWindowsItem:(NSWindow *) aWindow
					 title:(NSString *) aString
				  filename:(BOOL) isFilename;
- (NSGraphicsContext *) context;										// Display context
- (NSEvent*) currentEvent;									// Events
- (void) deactivate;
- (id) delegate;
- (void) discardEventsMatchingMask:(unsigned int) mask
					   beforeEvent:(NSEvent *) lastEvent;
- (void) endModalSession:(NSModalSession) aSession;
- (void) endSheet:(NSWindow *) sheet;
- (void) endSheet:(NSWindow *) sheet returnCode:(int) code;
- (void) finishLaunching;
- (void) hide:(id) sender;										// Hiding windows
- (void) hideOtherApplications:(id) sender;
- (BOOL) isActive;
- (BOOL) isHidden;
- (BOOL) isRunning;
- (NSWindow *) keyWindow;									// Managing windows
- (NSMenu *) mainMenu;										// Main menu
- (NSWindow *) mainWindow;
- (NSWindow *) makeWindowsPerform:(SEL) aSelector
						  inOrder:(BOOL) flag;
- (void) miniaturizeAll:(id) sender;
- (NSWindow *) modalWindow;
- (NSEvent *) nextEventMatchingMask:(unsigned int) mask
						 untilDate:(NSDate *) expiration
							inMode:(NSString *) mode
						   dequeue:(BOOL) flag;
- (NSArray *) orderedDocuments;
- (NSArray *) orderedWindows;
- (void) orderFrontCharacterPalette:(id) sender;					// Show std Panels
- (void) orderFrontColorPanel:(id) sender;						// Show std Panels
- (void) orderFrontStandardAboutPanel:(id) sender;
- (void) orderFrontStandardAboutPanelWithOptions:(NSDictionary *)optionsDictionary;
- (void) postEvent:(NSEvent *) event atStart:(BOOL) flag;
- (void) preventWindowOrdering;
- (void) registerServicesMenuSendTypes:(NSArray *) sendTypes
						   returnTypes:(NSArray *) returnTypes;
- (void) removeWindowsItem:(NSWindow *) aWindow;
- (void) replyToApplicationShouldTerminate:(BOOL) shouldTerminate;	// call if delegate returned NSTerminateLater
- (void) replyToOpenOrPrint:(NSApplicationDelegateReply) reply;
- (void) reportException:(NSException *) anException;		// Report exception
- (int) requestUserAttention:(NSRequestUserAttentionType) requestType;
- (void) run;
- (int) runModalForWindow:(NSWindow *) aWindow;
// - (int) runModalForWindow:(NSWindow *) aWindow relativeToWindow:(NSWindow *) docWindow;	// deprecated
- (int) runModalSession:(NSModalSession) aSession;
- (void) runPageLayout:(id) sender;
- (BOOL) sendAction:(SEL) aSelector to:(id) aTarget from:(id) sender;
- (void) sendEvent:(NSEvent *)event;
- (NSMenu *) servicesMenu;									// Service menu
- (id) servicesProvider;
// - (void) setAppleMenu:(NSMenu *)aMenu;						// set first entry of the mainMenu
- (void) setApplicationIconImage:(NSImage *) anImage;		// app's icon
- (void) setDelegate:(id) anObject;
- (void) setMainMenu:(NSMenu *) aMenu;
- (void) setServicesMenu:(NSMenu *) aMenu;
- (void) setServicesProvider:(id) anObject;
- (void) setWindowsMenu:(NSMenu *) aMenu;
- (void) setWindowsNeedUpdate:(BOOL) flag;
- (void) showHelp:(id) sender;
- (void) stop:(id) sender;
- (void) stopModal;
- (void) stopModalWithCode:(int) returnCode;
- (id) targetForAction:(SEL) aSelector;						// target / action
- (id) targetForAction:(SEL) aSelector
					to:(id) aTarget
				  from:(id) sender;
- (void) terminate:(id) sender;									// Terminate app
- (BOOL) tryToPerform:(SEL)aSelector with:(id) anObject;
- (void) unhide:(id) sender;
- (void) unhideAllApplications:(id) sender;
- (void) unhideWithoutActivation;
- (void) updateWindows;
- (void) updateWindowsItem:(NSWindow *) aWindow;
- (id) validRequestorForSendType:(NSString *) sendType
					  returnType:(NSString *) returnType;
- (NSArray *) windows;
- (NSMenu*) windowsMenu;
- (NSWindow *) windowWithWindowNumber:(int) windowNum;

@end

@interface NSObject (NSApplicationDelegate)					// Implemented by
															// the delegate
- (BOOL) application:(NSApplication *)app openFile:(NSString *)filename;
- (void) application:(NSApplication *)app openFiles:(NSArray *)filenames;
- (BOOL) application:(NSApplication *)app openFileWithoutUI:(NSString *)filename;
- (BOOL) application:(NSApplication *)app openTempFile:(NSString *)filename;
- (BOOL) applicationOpenUntitledFile:(NSApplication *)app;
- (BOOL) applicationShouldOpenUntitledFile:(NSApplication *)app;
- (BOOL) applicationShouldHandleReopen:(NSApplication *) app hasVisibleWindows:(BOOL)flag;

- (BOOL) application:(NSApplication *)app printFile:(NSString *)filename;
- (void) application:(NSApplication *)app printFiles:(NSArray *)filenames;
- (NSApplicationPrintReply) application:(NSApplication *) app printFiles:(NSArray *) files withSettings:(NSDictionary *) settings showPrintPanels:(BOOL) flag;

- (NSMenu *) applicationDockMenu:(NSApplication *) sender;

- (void) applicationDidChangeScreenParameters:(NSNotification *)aNotification;

- (void) applicationDidBecomeActive:(NSNotification *)aNotification;
- (void) applicationDidFinishLaunching:(NSNotification *)aNotification;
- (void) applicationDidHide:(NSNotification *)aNotification;
- (void) applicationDidResignActive:(NSNotification *)aNotification;
- (void) applicationDidUnhide:(NSNotification *)aNotification;
- (void) applicationDidUpdate:(NSNotification *)aNotification;
- (void) applicationWillBecomeActive:(NSNotification *)aNotification;
- (void) applicationWillFinishLaunching:(NSNotification *)aNotification;
- (void) applicationWillHide:(NSNotification *)aNotification;
- (void) applicationWillResignActive:(NSNotification *)aNotification;
- (void) applicationWillUnhide:(NSNotification *)aNotification;
- (void) applicationWillUpdate:(NSNotification *)aNotification;

- (NSApplicationTerminateReply) applicationShouldTerminate:(NSApplication *)sender;
- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender;
- (void) applicationWillTerminate:(NSNotification *)notification;

- (NSError *) application:(NSApplication *) app willPresentError:(NSError *) error;

@end


@interface NSObject (NSServicesRequests)					// Pasteboard

- (BOOL) readSelectionFromPasteboard:(NSPasteboard *)pboard;
- (BOOL) writeSelectionToPasteboard:(NSPasteboard *)pboard
                              types:(NSArray *)types;
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
