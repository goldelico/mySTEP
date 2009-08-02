/* 
 NSApplication.m

 Application class

 Copyright (C) 1996 Free Software Foundation, Inc.

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/Foundation.h>
#import <Foundation/NSException.h>
#import <Foundation/NSObjCRuntime.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSColorPanel.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSWorkspace.h>
#import <AppKit/NSDocumentController.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSPageLayout.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"
#import "NSSystemServer.h"

#import "GSServices.h"

#include <signal.h>
#include <sys/types.h>
#include <unistd.h>

// Menu delegate classes instantiated by NIBLoading

@interface _NSWindowMenuUpdater : NSObject
- (void) menuNeedsUpdate:(NSMenu *) menu;
@end

@implementation _NSWindowMenuUpdater

- (void) menuNeedsUpdate:(NSMenu *) menu;
{
#if 0
	NSEnumerator *e=[[self windows] objectEnumerator];
	// clear all existing window items
	while((w=[e nextObject]))
		{
		if(![w isExcludedFromWindowsMenu])
			{ // build menu
			NSMenuItem *item=[[NSMenuItem alloc] initWithTitle:[w title]
														action:@selector(makeKeyAndOrderFront:)
												 keyEquivalent:@""];
			[item setTarget:w];
			[menu addItem:item];
			[item release];
			}
		}
#endif
	NSLog(@"update Windows menu");
}

@end

@interface NSServiceMaster : NSObject
@end

@implementation NSServiceMaster
- (void) menuNeedsUpdate:(NSMenu *) menu;
{
	NSLog(@"should update Services menu");
}
@end

#define NOTICE(notif_name) NSApplication##notif_name##Notification

//
// Types
//
struct _NSModalSession {
	NSWindow *window;			// the modal window
	NSModalSession previous;
	NSMutableArray *nonModalEventsQueue;		// we collect events that are blocked from other windows
	int runState;	// and return value
	int windowTag;	// window ID
	BOOL visible;	// window was (still) visible and now disappeared
};

// Class variables
id NSApp = nil;

NSString *NSApplicationDidChangeScreenParametersNotification=@"NSApplicationDidChangeScreenParametersNotification";

static NSString	*NSAbortModalException = @"NSAbortModalException";

// static NSMenu *__copyOfMainMenu = nil;
static Class __windowClass = Nil;
extern NSView *__toolTipOwnerView;

#if OLD

// GSListener is a proxy class used in communicating with other
// apps.  It implements some dangerous methods in a harmless 
// manner to reduce the chances of a malicious app messing with 
// us.  It forwards service requests and other communications.

@interface _NSApplicationRemoteAccess : NSObject <_NSApplicationRemoteControlProtocol>

+ (void) _connectionBecameInvalid:(NSNotification*)notification;

@end

@implementation _NSApplicationRemoteAccess

// + (GSListener *) listener
// {
// 	return __listener ? __listener : (__listener = (id)NSAllocateObject(self, 0, NSDefaultMallocZone()));
// }

- (id) init;
{
	if((self=[super init]))
		{
		}
	return self;
}

+ (void) _connectionBecameInvalid:(NSNotification *) notification
{
	NSLog(@"GSListener + connectionBecameInvalid: %@", notification);
	NSUnregisterServicesProvider(nil);	// it is our connection
}

// - (Class) class							{ return nil; }
- (void) dealloc						{ return; [super dealloc]; }
- (void) release						{ return; }
- (id) retain							{ return self; }
- (id) self								{ return self; }

#if OLD
	// this is called for all unimplemented methods

- (void) forwardInvocation:(NSInvocation *) i
{
	SEL aSel=[i selector];
	NSString *selName = NSStringFromSelector(aSel);
	id delegate;		// If the selector matches the correct form for a services 
						// request, send the message to the services provider - 
						// otherwise raise a method is not implemented exception.
	NSLog(@"GSListener checking request %@", selName);
	
#if 0
	if ([selName hasSuffix: @":userData:error:"])
		{
		// [i setTargeg:__servicesProvider];
		[i invokeWithTarget:__servicesProvider];
		return;
		}
	
	NSLog(@"GSListener NSApp delegate=%@", [NSApp delegate]);
	// If app delegate can handle the message forward it to it
	
	if([selName isEqualToString:@"_application:openURLs:withOptions:"])
		{
#if 1
		NSArray *urls;
		int options;
		[i getArgument:&urls atIndex:3];
		[i getArgument:&options atIndex:4];
		NSLog(@"NSApp is asked to open URLs %@ with options %d", urls, options);
#endif
		[i invokeWithTarget:NSApp];
		return;
		}
#endif
	
	// FIXME: this allows all applications to remotely access any private AppController method...
	
	if([(delegate = [NSApp delegate]) respondsToSelector: aSel] == YES)
		{
#if 1
		NSLog(@"%08x:%@ forwarding %@ to NSApp delegate (%@)", self, self, selName, delegate);
		// NSLog(@"aSel=%08x frame=%08x: %08x %08x %08x", aSel, frame, ((long *)frame)[0], ((long *)frame)[1], ((long *)frame)[2]);
		// [i setTargeg:__servicesProvider];
#endif
		[i invokeWithTarget:delegate];
		return;	// invocation has been modified as defined by delegate
		}
	NSLog(@"GSListener blocks request %@", selName);
	[NSException raise: NSGenericException
				format: @"method %@ not implemented", selName];
	return;
}

#endif

// FIXME: shouldn't this be oneway void so that a launching app can't be blocked too long by a launched app?

- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
{ // forward to the application which will dispatch the call
	NSLog(@"GSListener %@ _application:openURLs:withOptions:", NSApp);
	[NSApp _application:NSApp openURLs:urls withOptions:opts];
	NSLog(@"  opened...");
	return YES;
}

- (void) performService:(NSString*)name
		 withPasteboard:(NSPasteboard*)pb
			   userData:(NSString*)ud
				  error:(NSString**)e
{
	id obj = [[GSServices sharedManager] servicesProvider];
	SEL msgSel = NSSelectorFromString(name);
	IMP msgImp;
	
	if (obj != nil && [obj respondsToSelector: msgSel])
		{
		if ((msgImp = [obj methodForSelector: msgSel]) != 0)
			{
			(*msgImp)(obj, msgSel, pb, ud, e);
			return;
			}	}
	
	if ((obj = [NSApp delegate]) != nil && [obj respondsToSelector: msgSel])
		{
		if ((msgImp = [obj methodForSelector: msgSel]) != 0)
			{
			(*msgImp)(obj, msgSel, pb, ud, e);
			return;
			}
		}
	*e = @"No object available to provide service"; 
}

- (void) activate;
{ // show menu (+windows, i.e. everything)
	NSLog(@"requested to activate");
	[NSApp activateIgnoringOtherApps:NO];
}

- (void) deactivate;
{ // hide menu
	NSLog(@"requested to deactivate");
	[NSApp deactivate];
}

- (void) hide;
{ // hide windows (+menu, i.e. everything)
	NSLog(@"requested to hide");
	// FIXME: hide all windows
	[NSApp hide:nil];
}

- (void) unhide;
{ // show windows
	NSLog(@"requested to unhide");
	[NSApp unhide:nil];
}

- (void) echo;
{ // can be used to check if I am responding...
	NSLog(@"requested to echo");
}

@end /* GSListener */

#endif

//
// Class variables
//
static id __listener = nil;
static id __servicesProvider = nil;
static id __registeredName = nil;
static NSConnection	*__listenerConnection = nil;

void NSUnregisterServicesProvider(NSString *name)
{
#if 0
	NSLog(@"NSUnregisterServicesProvider: '%@'", name);
#endif
	if (__listenerConnection)		// Ensure there is no previous listener and 
		{							// nothing else using the given port name.
		if(name)
			[[NSPortNameServer systemDefaultPortNameServer] removePortForName: name];
//		[[NSNotificationCenter defaultCenter] removeObserver: [GSListener class]
//														name: NSConnectionDidDieNotification
//													  object: __listenerConnection];
		[__listenerConnection release];
		__listenerConnection = nil;
		}
	
	[__servicesProvider release];
	__servicesProvider = nil;
}

void NSRegisterServicesProvider(id provider, NSString *name)
{
	if(!name)
		name = [[NSBundle mainBundle] bundleIdentifier];
	
	if (name && provider)
		{
#if 0
		NSLog(@"NSRegisterServicesProvider: '%@'", name);
#endif
		NSUnregisterServicesProvider(name);	// if any
		
		if(!(__listenerConnection = [NSConnection new]))	// create new connection
			[NSException raise: NSGenericException format: @"unable to create connection for %@", name];
		[__listenerConnection setRootObject:provider];	// register object
		if(![__listenerConnection registerName:name])	// publish connection point
			[NSException raise: NSGenericException format: @"unable to register %@", name];
//		[[NSNotificationCenter defaultCenter] addObserver: [provider class]
//												 selector: @selector(_connectionBecameInvalid:)
//													 name: NSConnectionDidDieNotification
//												   object: __listenerConnection];	// observe this connection to automatically unregister the services provider
#if 0
		NSLog(@"registered __listenerConnection %@ for %@", __listenerConnection, name);
#endif
		}
	
	ASSIGN(__servicesProvider, provider);
	ASSIGN(__registeredName, name);
}


//*****************************************************************************
//
// 		NSApplication 
//
//*****************************************************************************

@implementation NSApplication

+ (NSApplication *) sharedApplication
{
	Class class;
#if 0
	NSLog(@"+sharedApplication");
#endif
	if(!NSApp)
		{
			NSAutoreleasePool *arp=[NSAutoreleasePool new];
		if(!(class = [[NSBundle mainBundle] principalClass]))
			{
			NSLog(@"Main bundle does not define an existing principal class: %@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSPrincipalClass"]);
//			exit(1);
			class=self;
			}
#if 0
		NSLog(@"class = %@", NSStringFromClass(class));
#endif
		if(![class isSubclassOfClass:[self class]])
		   NSLog(@"principal class (%@) of main bundle is not subclass of NSApplication", NSStringFromClass(class));
		[class new];	// create instance -init will set NSApp
		[arp release];
		}
#if 0
	NSLog(@"NSApp = %@", NSApp);
#endif
	return NSApp;
}

- (void) _screenParametersNotification:(NSNotification *) notification;
{
#if 1
	NSLog(@"%@ _screenParametersNotification: %@", NSStringFromClass([self class]), notification);
#endif
	[_mainMenuWindow setFrame:[[_mainMenuWindow screen] _menuBarFrame] display:YES animate:YES];	// move menu bar (if screen rotates)
}

- (id) _remoteControlRootProxy;
{ // this allows overwriting in a category
	return self;
}

- (NSConnection *) _setupRemoteControl;
{
//	NSNotificationCenter *n=[NSNotificationCenter defaultCenter];
	NSMessagePort *port = [[[NSMessagePort alloc] init] autorelease];	// create new message port
	NSConnection *connection = [[NSConnection connectionWithReceivePort:port sendPort:nil] retain];	// uses same port to send and receive
	NSString *name=[[NSBundle mainBundle] bundleIdentifier];
	
	if(![[NSMessagePortNameServer sharedInstance] registerPort:port name:name])	// register as named message port
		NSLog(@"Could not publish message port %@ as %@", port, name);
	else
		{
#if 1
		NSLog(@"MessagePort published %@", port);
#endif
		[connection setRootObject:[self _remoteControlRootProxy]];	// should be proteced by a NSProtocolChecker
#if 1
		NSLog(@"Root object %@", [connection rootObject]);
#endif
#if OLD
		[n addObserver: [remote class]
												 selector: @selector(_connectionBecameInvalid:)
													 name: NSConnectionDidDieNotification
												   object: remote];
#endif
		}
#if 1
	NSLog(@"Remote Access connection %@", connection);
#endif
	return connection;
}

- (id) init
{
#if 1
	NSLog(@"Begin of %@ init", self);
#endif
	if(NSApp != nil && NSApp != self)
		{
		// this will be called to initWithCoder the dummy object if NSApp is the file owner of a NIB file
		NSLog(@"Warning: NSApp has already been initialized to %@: %@", NSApp, self);
		return [NSApp retain];	// there is already one
		}
	if((self=[super init]))
		{
		NSNotificationCenter *n=[NSNotificationCenter defaultCenter];

		NSApp=self;

		__windowClass = [NSWindow class];
		_eventQueue = [[NSMutableArray alloc] initWithCapacity:9];

		[self _setupRemoteControl];
#if 0
		// CHECKME: which NSPorts do we create here???
		[[NSConnection defaultConnection] addRequestMode:NSModalPanelRunLoopMode];
		[[NSConnection defaultConnection] addRequestMode:NSEventTrackingRunLoopMode];		// process incoming DO requests also while in these modes
		
		_listener = [GSServices sharedManager];				// register for default DO access through App bundle identifier
#endif
		[self setNextResponder:nil];						// NSApp is the end of
															// the responder chain
		_app.windowsNeedUpdate = YES;						// default to first update

		[n addObserver:self selector:@selector(windowWillClose:) name:NSWindowWillCloseNotification object:nil];	// observe all windows
		[n addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:nil];
		[n addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:nil];
		[n addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:nil];
		[n addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:nil];
		
#if 0
		NSLog(@"End of %@ init", self);
#endif
		}
	return self;
}

- (void) _processCommandLineArguments:(NSArray *) args;
{ // open all files we have been passed as arguments
  // NOTE: this must match the way NSWorkspace and NSTask pass arguments down to launched apps
	NSEnumerator *e=[args objectEnumerator];
	NSString *arg;
	NSMutableArray *urls=[NSMutableArray arrayWithCapacity:[args count]];
	NSWorkspaceLaunchOptions opts=0;
	NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];	// read from ArgumentsDomain
#if 1
	NSLog(@"_processCommandLineArguments: %@", args);
#endif
	arg=[e nextObject]; // skip application executable path
	while((arg=[e nextObject]))
		{ // process all arguments and convert to URL
		NSURL *url;
		if([arg hasPrefix:@"-"])
			continue;	// skip options
		url=nil;
#if 0
		NSLog(@"%@ %@", arg, NSStringFromRange([arg rangeOfString:@":"]));
#endif
		if([arg rangeOfString:@":"].location != NSNotFound)
			url=[NSURL URLWithString:arg];		// assume that it is a URL
		if(!url)
			{
			if(![arg isAbsolutePath])
				arg=[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingFormat:@"/%@", arg];	// prefix with current directory
			url=[NSURL fileURLWithPath:arg];	// assume that it is a file path
			}
		[urls addObject:url];
		}
	if([ud stringForKey:@"NSPrint"])	// -NSPrint (any value)
		opts |= NSWorkspaceLaunchAndPrint;
	if([ud stringForKey:@"NSNew"])
		opts |= NSWorkspaceLaunchNewInstance;
	if([ud stringForKey:@"NSTemp"])
		opts |= NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchNewInstance;
	if([ud stringForKey:@"NSNoUI"])
		opts |= NSWorkspaceLaunchWithoutAddingToRecents;
	[self _application:self openURLs:urls withOptions:opts];
}

- (void) finishLaunching
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
	NSString *mainModelFile = [infoDict objectForKey:@"NSMainNibFile"];
	NSString *ident=[[NSBundle mainBundle] bundleIdentifier];
	NSString *error;
	NSDictionary *plist;
#if 1
	NSLog(@"finishLaunching - mainmodel=%@ ident=%@", mainModelFile, ident);
#endif
	ASSIGN(_appIcon, [NSImage imageNamed:NSApplicationIcon]);	// try to load
#if 0
	NSLog(@"App Icon = %@", _appIcon);
#endif
#if 1
		NSLog(@"writing to %@", [NSWorkspace _activeApplicationPath:nil]);
#endif
	[[NSFileManager defaultManager] createDirectoryAtPath:[NSWorkspace _activeApplicationPath:nil] attributes:nil];
#if 1
	NSLog(@"writing %@", [NSWorkspace _activeApplicationPath:ident], ident);
#endif
	plist=[NSDictionary dictionaryWithObjectsAndKeys:
				 [[NSBundle mainBundle] bundlePath], @"NSApplicationPath",
				 [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"], @"NSApplicationName",
				 ident, @"NSApplicationBundleIdentifier",
				 [NSNumber numberWithInt:getpid()], @"NSApplicationProcessIdentifier",
				 [NSNumber numberWithInt:time(NULL)], @"NSApplicationProcessSerialNumberHigh",
				 [NSNumber numberWithInt:getpid()], @"NSApplicationProcessSerialNumberLow",
				 nil];
	if(![[NSFileManager defaultManager] createFileAtPath:[NSWorkspace _activeApplicationPath:ident]
																					contents:[NSPropertyListSerialization dataFromPropertyList:plist
																																															format:NSPropertyListXMLFormat_v1_0
																																										errorDescription:&error]
																				attributes:nil])	// let the world know that I am launching
		NSLog(@"could not create %@", [NSWorkspace _activeApplicationPath:ident]);
#if 1
	NSLog(@"willFinishLaunching");
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillFinishLaunching) object:self];
	if(!_app.disableServices)						// register services handler before any awakeFromNib calls
		[_listener registerAsServiceProvider];
	
	// FIXME: according to Tiger docu we should already show the menu bar here - if [NSMenu menuBarVisible] is YES
	
	if([[infoDict objectForKey:@"LSGetAppDiedEvents"] boolValue])
		{ // convert SIGCHLD
		// find a mechanism to handle kAEApplicationDied
		}
	else
		signal(SIGCHLD, SIG_IGN);	// ignore
#if 1
	NSLog(@"NSMainNibFile = %@", mainModelFile);
#endif
	if([mainModelFile length] > 0)
		{ // is defined
		NSNib *nib=[[[NSNib alloc] initWithNibNamed:mainModelFile bundle:[NSBundle mainBundle]] autorelease];	// search in mainBundle
		if(![nib instantiateNibWithOwner:NSApp topLevelObjects:NULL])
			NSLog(@"Cannot load the main model file '%@'", mainModelFile);
		}
#if 1
	NSLog(@"did load nib");
#endif
	if(![self mainMenu])
		[self setMainMenu:[[NSMenu alloc] initWithTitle:@"Default"]];	// could not load from a NIB, replace a default menu
	else
		[[NSDocumentController sharedDocumentController] _updateOpenRecentMenu];	// create/add/update Open Recent submenu
	[self _processCommandLineArguments:[[NSProcessInfo processInfo] arguments]];	// process command line and -application:openFile:
	// FIXME - how does that interwork with cursor-rects?
	[[NSCursor arrowCursor] push];	// push the arrow as the default cursor
	[self activateIgnoringOtherApps:NO];
#if 1
	NSLog(@"didFinishLaunching");
#endif
	// this should be posted from the runloop!!!
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidFinishLaunching) object:self]; // notify that launch has finally finished
	// we should also send a distributed notification
	[arp release];
}

- (void) dealloc
{
	NSDebugLog(@"dealloc NSApplication\n");
													// Let ourselves know we 
	_app.isDeallocating = YES;						// are within dealloc
	
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidChangeScreenParametersNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignMainNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	
	[_listener release];
	[_eventQueue release];
	[_currentEvent release];

	while (_session != 0)							// We may need to tidy up 
		{											// nested modal session 
		NSModalSession tmp = _session;				// structures.
		_session = tmp->previous;
		objc_free(tmp);
		}
	[super dealloc];
}

- (void) run
{ // Run the main event loop
#if 0
	NSLog(@"NSApplication -run\n");
#endif
	[self finishLaunching];
	_app.isRunning = YES;
	do { // embrace with private autorelease pool and exception handler
		NSEvent *e;
		NSAutoreleasePool *arp=[NSAutoreleasePool new];
		NS_DURING // protect against exceptions
		int windowitemsbefore=_windowItems;
			e=[self nextEventMatchingMask:NSAnyEventMask
								untilDate:[NSDate distantFuture]
								   inMode:NSDefaultRunLoopMode
								  dequeue:YES];
			[self sendEvent:e];	// this can set isRunning=NO as a side effect to break the loop
			if(windowitemsbefore > 0 && _windowItems == 0)
					{ // no window items (left over) after processing last event
#if 1
						NSLog(@"windowitems %d -> 0", windowitemsbefore);
#endif
						if(!_delegate && ![NSApp mainMenu])
								{	// we are a menu-less daemon and have no delegate - default to terminate after initialization
#if 1
									NSLog(@"terminating pure daemon without menu and windows");
#endif
									_app.isRunning=NO;
								}
						else if(_delegate && [_delegate respondsToSelector:@selector(applicationShouldTerminateAfterLastWindowClosed:)] &&
										[_delegate applicationShouldTerminateAfterLastWindowClosed:self])
								{ // delegate allows us to end
#if 1
									NSLog(@"last windows item removed - terminate");
#endif
									_app.isRunning=NO;
								}
					}
		NS_HANDLER
			NSLog(@"Exception %@ - %@", [localException name], [localException reason]);
		NS_ENDHANDLER
		[arp release];
		}
	while(_app.isRunning);
	NSDebugLog(@"NSApplication end of run loop\n");	
	[self terminate:self];
}

- (int) runModalForWindow:(NSWindow*)aWindow
{
	NSModalSession s = 0;
	int r;	// Run a modal event loop

	NS_DURING
		{
		s = [self beginModalSessionForWindow:aWindow];
		while((r = [self runModalSession: s]) == NSRunContinuesResponse)
			{
			NSAutoreleasePool *arp=[NSAutoreleasePool new];
			[self nextEventMatchingMask:NSAnyEventMask
							  untilDate:[NSDate distantFuture]
								 inMode:NSModalPanelRunLoopMode
								dequeue:NO];	// wait for but don't process events
			[arp release];
			}
		[self endModalSession: s];
		}
	NS_HANDLER
		{
		if (s)
			[self endModalSession: s];
		if ([[localException name] isEqualToString: NSAbortModalException] == NO)
			[localException raise];
		r = NSRunAbortedResponse;
		}
	NS_ENDHANDLER
	return r;
}

- (void) beginSheet:(NSWindow *) sheet
		 modalForWindow:(NSWindow *) doc
			modalDelegate:(id) delegate
		 didEndSelector:(SEL) selector
				contextInfo:(void *) context;
{
	int r;
	NSModalSession s = 0;
	void (*didend)(id, SEL, NSWindow *, int, void *);
	didend = (void (*)(id, SEL, NSWindow *, int, void *))[delegate methodForSelector:selector];
	// make the sheet a child window of the doc window
	// animate sheet to show up as a sliding 'sheet'
	// run modal session
	
	NS_DURING
		{
			s = [self beginModalSessionForWindow:sheet];
			while((r = [self runModalSession: s]) == NSRunContinuesResponse)
					{
						NSAutoreleasePool *arp=[NSAutoreleasePool new];
						[self nextEventMatchingMask:NSAnyEventMask
															untilDate:[NSDate distantFuture]
																 inMode:NSModalPanelRunLoopMode
																dequeue:NO];	// wait for but don't process events
						[arp release];
					}
			[self endModalSession: s];
		}
	NS_HANDLER
		{
			if (s)
				[self endModalSession: s];
			if ([[localException name] isEqualToString: NSAbortModalException] == NO)
				[localException raise];
			r = NSRunAbortedResponse;
		}
	NS_ENDHANDLER
	if(didend)
		didend(delegate, selector, sheet, r, context);	// send result to modal delegate
}

- (int) runModalSession:(NSModalSession)as
{
	NSEvent *e;
	if (as != _session)
		[NSException raise: NSInvalidArgumentException format: @"runModalSession: with wrong session"];
//	[as->window displayIfNeeded];
	[as->window makeKeyAndOrderFront: self];
	as->windowTag = [as->window windowNumber];	// should be assigned now
#if 0
		NSLog(@"new session: as->window %@", as->window);
		NSLog(@"						 as->windowTag %d", as->windowTag);
#endif
		
	while((e = [self _eventMatchingMask:NSAnyEventMask dequeue:YES])
		 && (as->runState == NSRunContinuesResponse))
		{
		if([e window] == as->window)
				{ // the modal window
				NSWindow *w = [NSApp windowWithWindowNumber:as->windowTag];	// check if the server still knows us by tag
				BOOL was = as->visible;
				if(w == nil || (!(as->visible = [w isVisible]) && was))
					{
#if 0
					NSLog(@"window was visible: event window %d %@", [[e window] windowNumber], [e window]);
					NSLog(@"                    as->window %@", as->window);
					NSLog(@"                    as->windowTag %d -> %@", as->windowTag, w);
#endif
					[self stopModal];			// if window was visible but has now gone away: end the session
					}
				else
					[self sendEvent:e];	// dispatch to the event window (which is the modal window)
				}
		else if([[e window] worksWhenModal])
			{
#if 0
			NSLog(@"worksWhenModal: %@", [e window]);
#endif
			[self sendEvent:e];	// the window has explicity opted to receive events
			}
		// FIXME: check if we click into the title bar to always allow moving windows which is done in NSThemeFrame
		else
			{ // queue events for all other windows for processing by endModalSession
			NSEventType t = [e type];
			if (t == NSLeftMouseDown || (t == NSRightMouseDown))
				NSBeep();
			else
				{
				if (!as->nonModalEventsQueue)
					as->nonModalEventsQueue = [NSMutableArray new];				
				[as->nonModalEventsQueue addObject: e];
				}
			}
		}
	
	if (_app.windowsNeedUpdate && (as->runState == NSRunContinuesResponse))
			{
			[as->window displayIfNeeded];		// update first
			[as->window flushWindowIfNeeded];
			[self updateWindows];				// update other visible windows
			[as->window makeKeyAndOrderFront: self];	// stay in front
			}

	NSAssert(_session == as, @"Session was changed while running");
#if 0
	NSLog(@"runModalSession: %d", as->runState);
#endif

	return as->runState;
}

- (void) abortModal
{
	if (_session == 0)
		[NSException raise: NSAbortModalException
					 format:@"abortModal called while not in a modal session"];

	[NSException raise: NSAbortModalException format: @"abortModal"];
}

- (IBAction) stop:(id)sender	
{
	if (_session)
		[self stopModal];
	else
		_app.isRunning = NO;
}

- (void) stopModal			
{ 
	[self stopModalWithCode: NSRunStoppedResponse]; 
}

- (void) stopModalWithCode:(int)returnCode
{
#if 0
	NSLog(@"stopModalWithCode: %d", returnCode);
	abort();
#endif
	if (_session == 0)
		[NSException raise: NSInvalidArgumentException
					 format:@"stopModalWithCode: when not in a modal session"];

	if (returnCode == NSRunContinuesResponse)
		[NSException raise: NSInvalidArgumentException
					 format: @"stopModalWithCode: NSRunContinuesResponse ?"];
 
	_session->runState = returnCode;
}

- (NSModalSession) beginModalSessionForWindow:(NSWindow*)aWindow
{
	NSModalSession s;
	s = (NSModalSession) objc_calloc(1, sizeof(struct _NSModalSession));
	if(s != NULL)
		{
		s->runState = NSRunContinuesResponse;
		s->window = aWindow; 
		s->previous = _session;
		_session = s;
		}
	return s;
}

- (NSModalSession) beginModalSessionForWindow:(NSWindow *)aWindow relativeToWindow:(NSWindow *) other
{
	NSModalSession s;
	DEPRECATED;
	s = (NSModalSession) objc_calloc(1, sizeof(struct _NSModalSession));
	if(s != NULL)
		{
		s->runState = NSRunContinuesResponse;
		s->window = aWindow; 
		s->previous = _session;
		_session = s;
		}
	return s;
}

- (NSWindow *) modalWindow;
{ // current modal window (if any)
	if(_session)
		return _session->window;
	return nil;
}

- (void) endModalSession:(NSModalSession)aSession
{
	NSModalSession tmp = _session;

	if (aSession == 0)
		[NSException raise: NSInvalidArgumentException
					 format: @"null pointer passed to endModalSession:"];

	if (aSession->nonModalEventsQueue)
		{ // add events to regular queue
		[_eventQueue addObjectsFromArray: aSession->nonModalEventsQueue];
		[aSession->nonModalEventsQueue release];
		}

	while (tmp && tmp != aSession)					// Remove this session from
		tmp = tmp->previous;						// linked list of sessions

	if (tmp == 0)
		[NSException raise: NSInvalidArgumentException
					 format: @"unknown session passed to endModalSession:"];

	while (_session != aSession)
		{
		tmp = _session;
		_session = tmp->previous;
		free(tmp);
		}
	_session = _session->previous;
	free(aSession);
}

- (void) endSheet:(NSWindow *) sheet returnCode:(int) code
{
	// animate sheet to disappear
	[self stopModalWithCode:code];
}

- (void) endSheet:(NSWindow *) sheet
{
	[self endSheet:sheet returnCode:NSRunStoppedResponse];
}

// internal communication with the NSWindows - although we are not the window delegate, we observe these notifications

- (void) windowWillClose:(NSNotification *)aNotification 
{
	NSArray *_windowList=[self windows];
	int i = [_windowList count];				// find a replacement
#if 1
	NSLog(@"NSApp: windowWillClose - %d open windows", i);
#endif
	if(!_app.isHidden && [aNotification object] == _keyWindow && [self isActive])
		{ // the key window is being closed
		NSWindow *oldKey = _keyWindow;
		NSWindow *w;
		_keyWindow = nil;								// assumes resignMain was sent first
		if (oldKey != _mainWindow && _mainWindow && [_mainWindow canBecomeKeyWindow])
			{	// I am not the main window, but it can become the key window
			[_mainWindow becomeKeyWindow];
			return;
			}
		// if window was key & main try to skip myself
		while(i-- > 0)
			{
			if(((w = [_windowList objectAtIndex: i]) != oldKey) && [w isVisible] && [w canBecomeKeyWindow])	
				{
				[w orderFront:self];
				[w becomeKeyWindow];
				[w makeMainWindow];
				break;
				}
			}
		}
}

- (void) windowDidResignKey:(NSNotification *)aNotification
{
#if 1
	NSLog(@"%@%@ %@", self, NSStringFromSelector(_cmd), aNotification);
#endif
	if (!_app.isHidden && [aNotification object] == _keyWindow)
		_keyWindow = nil;
}

- (void) windowDidResignMain:(NSNotification *)aNotification
{
#if 1
	NSLog(@"%@%@ %@", self, NSStringFromSelector(_cmd), aNotification);
#endif
	if (!_app.isHidden && [aNotification object] == _mainWindow)
		_mainWindow = nil;
}

- (void) windowDidBecomeKey:(NSNotification *)aNotification
{
#if 0
	NSLog(@"%@ %@", self, aNotification);
#endif
	_keyWindow = [aNotification object];
}

- (void) windowDidBecomeMain:(NSNotification *)aNotification
{
#if 0
	NSLog(@"%@ %@", self, aNotification);
#endif
	_mainWindow = [aNotification object];
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent;
{ // permit ink-anywhere
	return [[theEvent window] shouldBeTreatedAsInkEvent:theEvent];
}

- (BOOL) _eventIsQueued:(NSEvent *) event; { return [_eventQueue indexOfObjectIdenticalTo:event] != NSNotFound; }

- (NSEvent*) _eventMatchingMask:(unsigned int)mask dequeue:(BOOL)dequeue
{
	int i, cnt;
#if 0
	NSLog(@"_eventMatchingMask");
#endif
	if(_app.windowsNeedUpdate)		// needs to send an update message to all visible windows
		[self updateWindows];	// FIXME: should not be called during NSEventTrackingRunLoopMode!
	if(!mask)
		return nil;	// no event will match
	cnt=[_eventQueue count];
	for (i = 0; i < cnt; i++)							// return next event
		{												// in the queue which
		NSEvent *e = [_eventQueue objectAtIndex:i];		// matches mask
		if((mask == NSAnyEventMask) || mask & NSEventMaskFromType([e type])) 
			{
			[e retain];	// save across removeObjectAtIndex
			if(dequeue)
				[_eventQueue removeObjectAtIndex:i];
#if 0
			NSLog(@"_eventMatchingMask found");
#endif
			return [e autorelease];		// return an event from the queue which matches the mask
			}
		}
#if 0
	NSLog(@"_eventMatchingMask no event found");
#endif
	return nil;		// no event in the queue matches mask
}

- (void) doCommandBySelector:(SEL) sel;
{
	if([self respondsToSelector:sel])
		[self performSelector:sel withObject:nil];
	else if(_nextResponder)
		[_nextResponder doCommandBySelector:sel];	// pass down
	else if(_delegate && [self respondsToSelector:_cmd])
		[_delegate doCommandBySelector:sel];		// pass down
	else
		[self noResponderFor:sel];	// Beep
}

- (void) _handleGestureEvent:(NSEvent *) event
{
	[[event window] sendEvent:event];
}

- (void) sendEvent:(NSEvent *)event					// pass event to the window
{
#if 0
	NSLog(@"NSApp sendEvent: %@", event);
#endif
	switch([event type])							// determine the event type					
		{
		case NSPeriodic:							// NSApp traps periodic
			break;									// events
		case NSLeftMouseDown:
			{
				if([self shouldBeTreatedAsInkEvent:event])
					{ // this should be an inking event
					NS_DURING
						{ // try to handle by server which can pass back recognized characters to -sendEvent or even better postEvent:
							id <_NSLoginWindowProtocol> dws=[NSWorkspace _loginWindowServer];
							if(dws)
								{ // ok
								NSPoint point=[[event window] convertBaseToScreen:[event locationInWindow]];
								[dws startInkingForApplication:self atScreenPosition:point];
								NS_VOIDRETURN;
								}
						}
					NS_HANDLER
						NSLog(@"could not send startInking message due to %@", [localException reason]);
					NS_ENDHANDLER
					}
				// FIXME: how does this interwork with the NSApplicationActivatedEvent?
				if(([event window] != _appIconWindow))
					{ // activated when clicking into window
					if([[event window] styleMask] & NSNonactivatingPanelMask)
						{ // only grab the keyboard focus without activating
						[_keyWindow becomeKeyWindow];
						}
					else
						[NSApp activateIgnoringOtherApps:YES];
					}
			}
		case NSLeftMouseUp:
		case NSRightMouseDown:
		case NSRightMouseUp:
		case NSOtherMouseDown:
		case NSOtherMouseUp:
		case NSMouseMoved:
		case NSLeftMouseDragged:
		case NSRightMouseDragged:
		case NSOtherMouseDragged:
		case NSMouseEntered:
		case NSMouseExited:
		case NSScrollWheel:
		case NSTabletPoint:
		case NSTabletProximity:
			{ // send all mouse related events to the window specified in the event (i.e. key window)
				// CHECKME: what if app has NOT windows? Which window?
				[[event window] sendEvent:event];
				break;
			}
		case NSKeyDown:
		case NSKeyUp:
		case NSFlagsChanged:
		case NSCursorUpdate:
		case NSApplicationDefined:
			{ // send to key window only
#if 0
					NSLog(@"NSEvent: %@ to keyWindow %@", event, _keyWindow);
#endif
				[_keyWindow sendEvent:event];
				break;
			}
		case NSSystemDefined:
		case NSAppKitDefined:
			{
				[[event window] sendEvent:event];
				break;
			}
		case NSRotate:
		case NSBeginGesture:
		case NSEndGesture:
		case NSMagnify:
		case NSSwipe:
			[self _handleGestureEvent:event];
		}
}

- (void) keyDown:(NSEvent *)event
{
#if 1
	NSLog(@"%@ keyDown: %@", NSStringFromClass(isa), event);
#endif
	if([[event characters] length] > 0)
			{ // event is providing characters - i.e. not just a meta-key
				NSEnumerator *e;
				NSWindow *w;
				if([_keyWindow performKeyEquivalent:event])
					return;	// has been processed
				if([_mainWindow performKeyEquivalent:event])
					return;	// has been processed
				e = [[self windows] objectEnumerator];	// all windows incl. menu windows
				while((w = [e nextObject]))
						{ // Try all other windows
							if(w == _keyWindow || w == _mainWindow)
								continue;	// already tried
							if([w performKeyEquivalent:event])
								return;	// has been processed by window
						}
				// FIXME: also try open popup and contextual menus!
				// FIXME: do we really need this? A Menu window is also an "other" window...
				//					if([[self mainMenu] performKeyEquivalent:event])	// finally try main menu (not menu window)
				//						return;
			}
	[super keyDown:event];	// we may have our own next responder (i.e. the App delegate)
}

- (void) discardEventsMatchingMask:(unsigned int)mask
					   beforeEvent:(NSEvent *)lastEvent
{
	int i = 0, loop;
	int count = [_eventQueue count];
	NSEvent *event;
#if 0
	NSLog(@"discardEventsMatchingMask %x", mask);
	NSLog(@"before %u", [_eventQueue count]);
#endif
	for (loop = 0; loop < count; loop++) 
		{											
		event = [_eventQueue objectAtIndex:i];
			if(event == lastEvent)
				break;	// all before lastEvent (which may be nil)
#if 0
			NSLog(@"event %x", NSEventMaskFromType([event type]));
#endif
		if ((mask & NSEventMaskFromType([event type]))) // remove event from the queue if it matches the mask
			[_eventQueue removeObjectAtIndex:i];
		else
			i++;	// inc queue cntr only if not a match else we will run off the end of the queue
		}	
#if 0
	NSLog(@"after %u", [_eventQueue count]);
#endif
}

- (NSEvent *) nextEventMatchingMask:(unsigned int)mask
						  untilDate:(NSDate *)expiration
							 inMode:(NSString *)mode
							dequeue:(BOOL)fl
{
	NSRunLoop *currentLoop=[NSRunLoop currentRunLoop];
	NSAutoreleasePool *pool=[NSAutoreleasePool new];
	NSDate *limit;
#if 0
	NSLog(@"nextEventMatchingMask:%08x untilDate:%@ inMode:%@", mask, expiration, mode);
#endif
	if(!expiration)
		expiration=[NSDate distantPast];	// fall through immediately
	for(;;)
		{ // If there are matching events in the queue, wait for next events to arrive
		limit=[currentLoop limitDateForMode:mode];	// limit by any pending timers - this will already poll the input sources (at least on MacOS!)
		if((_currentEvent = [self _eventMatchingMask:mask dequeue:fl]))	// check if we (now) have a matching event
			break;	// found one
#if 0
		NSLog(@"limitDateForMode:%@ = %@ - exp = %@", mode, [currentLoop limitDateForMode:mode], expiration);
#endif
		limit=[limit earlierDate:expiration];	// limit to given expiration
#if 0
		NSLog(@"earlier: %@", limit);
#endif
		if(![currentLoop runMode:mode beforeDate:limit])		// blocks until (more) input arrives or the next scheduled timeout occurs
			{
			NSLog(@"no input sources for mode: %@", mode);
			break;
			}
#if 0
		NSLog(@"after runloop: %@", limit);
#endif
		if([expiration timeIntervalSinceNow] < 0)
			break;	// untilDate has expired
#if 0
		NSLog(@"ARP release");
#endif
		[pool release];					// release current
#if 0
		NSLog(@"ARP released");
#endif
		pool=[NSAutoreleasePool new];	// and create a new pool
 		}
#if 0
	NSLog(@"ARP release with event: %@", _currentEvent);
#endif
	[_currentEvent retain];
	[pool release];
	return [_currentEvent autorelease];
}

- (void) postEvent:(NSEvent *)event atStart:(BOOL)flag
{
#if 0
	if(flag)
		NSLog(@"postEvent:atStart:YES %@", event);
	else
		NSLog(@"postEvent:atStart:NO %@", event);
#endif
	if(!flag)
		[_eventQueue addObject: event];
	else
		[_eventQueue insertObject:event atIndex:0];
}

// Send action messages

- (BOOL) sendAction:(SEL)aSelector to:(id) aTarget from:(id) sender
{
	id target=[self targetForAction:aSelector to:aTarget from:sender];
	if(!target)
		return NO;
	NS_DURING
		[target performSelector:aSelector withObject:sender];
	NS_HANDLER
		NSLog(@"could not send action %@ from %@ to %@: %@", NSStringFromSelector(aSelector), sender, aTarget, [localException reason]);
	NS_ENDHANDLER
	return YES;
}												

- (id) targetForAction:(SEL)aSelector to:(id)aTarget from:(id)sender
{
	if(!aSelector)
		return nil;
	if(aTarget)
		return aTarget; // responds...
	return [self targetForAction:aSelector];	// look up in responder chain
}
	
- (id) targetForAction:(SEL)aSelector
{ // look up in responder chain
	id responder;
	NSDocumentController *docController;
	if(!aSelector)
		return nil;
	// check key window first
	responder = [_keyWindow firstResponder];
	while(responder)
		{ // traverse first responder chain
		if ([responder respondsToSelector: aSelector])
			return responder;
		responder = [responder nextResponder];
		}
	if([_keyWindow respondsToSelector: aSelector])
		return _keyWindow;
	responder = [_keyWindow delegate];
	if(responder != nil && [responder respondsToSelector: aSelector])
		return responder;
	// check main window - if different
	if(_keyWindow != _mainWindow)
		{ // and traverse main window as well
		responder = [_mainWindow firstResponder];
		while(responder)
			{
			if([responder respondsToSelector: aSelector])
				return responder;
			responder = [responder nextResponder];
			}
		if([_mainWindow respondsToSelector: aSelector])
			return _mainWindow;
		responder = [_mainWindow delegate];
		if(responder != nil && [responder respondsToSelector: aSelector])
			return responder;
		}
	// check application
	if([self respondsToSelector: aSelector])
		return self;
	// check application delegate
	if(_delegate != nil && [_delegate respondsToSelector: aSelector])
		return _delegate;
	// check document controller (if it exists)
	docController=[NSDocumentController sharedDocumentController];
	if(docController && [docController respondsToSelector: aSelector])
		return docController;
	return nil; // no responder available
}

- (BOOL) tryToPerform:(SEL)aSelector with:anObject
{
	if ([super tryToPerform: aSelector with: anObject] == YES)
		return YES;
	if (_delegate != nil && [_delegate respondsToSelector: aSelector])
		{
		[_delegate performSelector: aSelector withObject: anObject];
		return YES;
		}
	return NO;
}

- (void) setApplicationIconImage:(NSImage*)img	{ BACKEND; }
- (NSImage *) applicationIconImage				{ return _appIcon; }
- (NSEvent *) currentEvent						{ return _currentEvent; }
- (NSWindow*) appIcon							{ return _appIconWindow; }
- (NSWindow*) keyWindow							{ return _keyWindow; }
- (NSWindow*) mainWindow						{ return _mainWindow; }

- (NSWindow*) windowWithWindowNumber:(int)num	{ return BACKEND; }

// FIXME: should we exclude menu windows???

- (NSArray *) windows							{ return BACKEND; }

- (NSArray *) orderedWindows;
{ // should include only scriptable windows, i.e. exclude panels
	return [self windows];
}

- (BOOL) isRunning							{ return _app.isRunning; }
- (BOOL) isHidden								{ return _app.isHidden; }

- (void) _setWindowsHidden:(BOOL) flag;
{ // used for hide on deactivate
#if 1
	NSLog(@"_setWindowsHidden: %d", flag);
#endif
	if(flag)
			{ // hide windows
				NSArray *_windowList = [self windows];
				int i, count = [_windowList count];
				for(i = 0; i < count; i++)
						{
							NSWindow *w = [_windowList objectAtIndex:i];
							if([w hidesOnDeactivate] && [w isVisible])
									{ // NOTE: this appears to be different from OSX where the isVisible flag remains active while window is hidden
									[w orderOut:nil];	// hide
									if(!_hiddenWindows)
										_hiddenWindows=[[NSMutableArray alloc] initWithCapacity:10];
									[_hiddenWindows addObject:w];	// add to list of hidden windows
									}
						}
			}
	else
			{ // unhide all currently hidden windows
				[_hiddenWindows makeObjectsPerformSelector:@selector(orderFront:) withObject:self];
				[_hiddenWindows release];
				_hiddenWindows=nil;
			}
#if 1
	NSLog(@"hiddenWindows: %@", _hiddenWindows);
#endif
}

- (BOOL) isActive
{ // if active application is defined and is our pid
	NSDictionary *app=[[NSWorkspace sharedWorkspace] activeApplication];
#if 0
	NSLog(@"active app=%@", app);
#endif
	return [[app objectForKey:@"NSApplicationProcessIdentifier"] intValue] == getpid();
}

- (void) activateIgnoringOtherApps:(BOOL)flag
{
#if 1
	NSLog(@"activateIgnoringOtherApps:%@", flag?@"YES":@"NO");
#endif
	if (flag || ![self isActive])
		{ // make application known to the public
			NSString *active=[NSWorkspace _activeApplicationPath:@"active"];
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillBecomeActive) object: self];	 // menu's should listen for note so that they are up when app active
			if(![[NSFileManager defaultManager] removeFileAtPath:active handler:nil])	// reove as active application
				NSLog(@"remove error for activate");
		[[NSFileManager defaultManager] createSymbolicLinkAtPath:active pathContent:[[NSBundle mainBundle] bundleIdentifier]];	// link to identifier
			[self _setWindowsHidden:NO];		// unhide our windows
		if(flag)
			{
			if(_mainWindow)
				[_mainWindow becomeMainWindow];
			if(_keyWindow)
				[_keyWindow becomeKeyWindow];
			}
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidBecomeActive) object: self];
		}
	if(flag)
		[_mainMenuWindow orderFront:self];	// order front our application menu
}

- (void) deactivate
{
	if([self isActive])				// in order to make themselves invisible 
		{	// when the application is not active.
			NSString *active=[NSWorkspace _activeApplicationPath:@"active"];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillResignActive) object:self];
#if 1
		NSLog(@"NSApp deactivate");
#endif
		[_keyWindow resignKeyWindow];
			if(![[NSFileManager defaultManager] removeFileAtPath:active handler:nil])	// reove as active application
				NSLog(@"remove error for deactivate");
			[self _setWindowsHidden:YES];		// hide
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidResignActive) object:self];
		}
}

- (IBAction) hide:(id)sender
{
	if (!_app.isHidden)								
		{
		NSEnumerator *e = [[self windows] reverseObjectEnumerator];	// incl. menus
		NSWindow *w;

		_app.isHidden = YES;						// notify that we will hide
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillHide) object:self];
													
		[self deactivate];	// this will already hide some windows

		while((w = [e nextObject]))					// Tell the windows to hide
			{
			if([w isVisible] && [w canHide])
				[w orderOut:sender];
			}
													// notify that we did hide
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidHide) object:self];
		}					
}

- (IBAction) unhide:(id)sender
{
	[self unhideWithoutActivation];
	[self activateIgnoringOtherApps:YES];
}

- (IBAction) unhideAllApplications:(id)sender;
{
	NSDictionary *a;
	NSEnumerator *e=[[[NSWorkspace sharedWorkspace] launchedApplications] objectEnumerator];
	while((a=[e nextObject]))
		{
			// connect through DO
		if([a objectForKey:@"NSApplicationNSApp"] == NSApp)
			continue;	// compare to self - ????? does this work through object NSPortEncoding?
		NS_DURING
			NSLog(@"unhideWithoutActivation %@", a);
			[[a objectForKey:@"NSApplicationNSApp"] unhideWithoutActivation];	// try to unhide
		NS_HANDLER
			NSLog(@"could not send unhideWithoutActivation message due to %@", [localException reason]);
		NS_ENDHANDLER
		}
}

- (int) requestUserAttention:(NSRequestUserAttentionType) requestType;
{
	NS_DURING
		NS_VALUERETURN([[NSWorkspace _loginWindowServer] requestUserAttention:requestType forApplication:self], int);
	NS_HANDLER
		NSLog(@"could not requestUserAttention due to %@", [localException reason]);
	NS_ENDHANDLER
	return 0;
}

- (void) cancelUserAttentionRequest:(int) request;
{
	if(request != 0)
		{
		NS_DURING
			[[NSWorkspace _loginWindowServer] cancelUserAttentionRequest:request];
		NS_HANDLER
			NSLog(@"could not requestUserAttention due to %@", [localException reason]);
		NS_ENDHANDLER
		}
}

- (IBAction) hideOtherApplications:(id)sender; { [[NSWorkspace sharedWorkspace] hideOtherApplications]; }

- (void) unhideWithoutActivation
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillUnhide) object:self];
	[self arrangeInFront: self];
	_app.isHidden = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidUnhide) object:self];
}

- (IBAction) arrangeInFront:(id)sender						
{
	if (_windowsMenu)
		{
		NSEnumerator *e = [[_windowsMenu itemArray] objectEnumerator];
		NSPoint topLeft={ 0.0, 512.0 };
		NSMenuItem *item;

		while((item = [e nextObject]))
			{ // bring to front all windows int the menu
			NSWindow *w = [item target];
			if ((w != _keyWindow) && (w != _mainWindow) && ![w isExcludedFromWindowsMenu])
				{
				[w orderFront: sender];
				topLeft=[w cascadeTopLeftFromPoint:topLeft];
				}
			}
		if(_mainWindow && (_keyWindow != _mainWindow))
			{ // if main and key window are different
			[_mainWindow orderFront: sender];
			topLeft=[_mainWindow cascadeTopLeftFromPoint:topLeft];
			}
		if(_keyWindow)
			{
			[_keyWindow orderFront: sender];
			topLeft=[_keyWindow cascadeTopLeftFromPoint:topLeft];
			}
		}
}

- (NSWindow *) makeWindowsPerform:(SEL)aSelector inOrder:(BOOL)flag
{
NSEnumerator *e;
NSWindow *w;

	if (flag)
		e = [[self windows] objectEnumerator];
	else
		e = [[self windows] reverseObjectEnumerator];

	while((w = [e nextObject]))
		if ([w performSelector: aSelector] != nil)
			return w;

	return nil;
}

- (IBAction) miniaturizeAll:(id)sender
{
	NSEnumerator *e = [[self windows] objectEnumerator];
	NSWindow *w;
	while((w = [e nextObject]))
		[w miniaturize:sender];
}

- (void) setWindowsNeedUpdate:(BOOL)flag
{
	_app.windowsNeedUpdate = flag;
}

- (void) _setPendingWindow:(NSWindow *) win;
{ // register window to be ordered front on next updateWindows event (i.e. after the current mouseDown has been processed)
	_pendingWindow=win;
}

- (void) preventWindowOrdering;
{ // cancel delayed window ordering
	_pendingWindow=nil;
}

- (void) updateWindows
{ // send an update message to all visible windows
#if 0
	NSLog(@"updateWindows");
#endif
	{
	NSArray *_windowList = [self windows];
	int i, count = [_windowList count];
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillUpdate) object: self];
	if(_pendingWindow)
		{
			[_pendingWindow makeKeyAndOrderFront:self];
			_pendingWindow=nil;
		}
	_app.windowsNeedUpdate=NO;	// reset - so that an update call can set it for the next loop
#if 1
	if(count == 0)
		NSLog(@"no windows to update?");
#endif
	for(i = 0; i < count; i++)
		{
		NSWindow *w = [_windowList objectAtIndex:i];
		if([w isVisible])
			{ // send to visible windows only
			[w update];	// update this window
			_app.windowsNeedUpdate |= [w viewsNeedDisplay];	// might still or again need update!
			}
		[w flushWindow];	// might have pending mapping and other events
		}
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(DidUpdate) object:self];	// notify that update did occur
	}
#if 0
	NSLog(@"updateWindows done");
#endif
	}

- (IBAction) orderFrontColorPanel:(id)sender			// Standard Panels
{
	NSLog(@"orderFrontColorPanel");
	[[NSColorPanel sharedColorPanel] orderFront:sender];
}

- (IBAction) orderFrontCharacterPalette:(id)sender
{
	NSLog(@"orderFrontCharacterPalette");
	[[NSWorkspace _loginWindowServer] enableVKBD:YES];
}

- (IBAction) _orderOutCharacterPalette:(id)sender
{
	NSLog(@"orderFrontCharacterPalette");
	[[NSWorkspace _loginWindowServer] enableVKBD:NO];
}

#if OLD
- (IBAction) orderFrontHelpPanel:(id)sender
{
//	NIMP;
}
#endif

- (IBAction) orderFrontStandardAboutPanel:sender; { [self orderFrontStandardAboutPanelWithOptions:nil]; }

- (void) orderFrontStandardAboutPanelWithOptions:(NSDictionary *)optionsDictionary;
{
	if(!optionsDictionary)
		optionsDictionary=[NSWorkspace _standardAboutOptions];	// use default
	if(!_aboutPanel)
		{ // try to load from NIB
		if(![NSBundle loadNibNamed:@"AboutPanel" owner:self])	// being the owner allows to connect to views in the panel
			[NSException raise: NSInternalInconsistencyException format: @"Unable to open about panel model file."];
		}
#if 1
	NSLog(@"options %@", optionsDictionary);
#endif
	[_credits setStringValue:[optionsDictionary objectForKey:@"Credits"]];
	[_applicationName setStringValue:[optionsDictionary objectForKey:@"ApplicationName"]];
	[_applicationImage setImage:[optionsDictionary objectForKey:@"ApplicationIcon"]];
	[_version setStringValue:[optionsDictionary objectForKey:@"Version"]];
	[_copyright setStringValue:[optionsDictionary objectForKey:@"Copyright"]];
	[_applicationVersion setStringValue:[optionsDictionary objectForKey:@"ApplicationVersion"]];
	[_aboutPanel orderFront:self];
}

- (IBAction) runPageLayout:(id)sender
{
	[[NSPageLayout pageLayout] runModal];
}

- (IBAction) showHelp:(id)sender
{
	// check registration of helpbook
	NSLog(@"open help viewer...");
	return;	// NIMP
}

- (void) setMenu:(NSMenu *)aMenu
{
	[self setMainMenu:aMenu];
}	// override NSResponder's implementation

- (NSWindow *) _mainMenuWindow; { return _mainMenuWindow; }

- (void) setMainMenu:(NSMenu *)aMenu
{
	NSScreen *menuScreen=[[NSScreen screens] objectAtIndex:0];
#if 0
	NSLog(@"NSApplication setMainMenu=%@", [aMenu _longDescription]);
#endif
	if([aMenu numberOfItems] == 0)
		[aMenu addItemWithTitle:@"" action:NULL keyEquivalent:@""];	// create at least one entry in main menu
	// FIXME: should we always substitute?
	// and should we setAttributedTitle?
	if([[[aMenu itemAtIndex:0] title] length] == 0)
		{ // application menu title is empty - substitute from bundle
		NSString *applicationName=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
		if(!applicationName)
			applicationName=[[NSProcessInfo processInfo] processName];	// replacement
		if(applicationName)
			[[aMenu itemAtIndex:0] setTitle:applicationName];	// insert application name
		}
	[super setMenu:aMenu];	// store through NSResponder's setter
#if 0
	NSLog(@"setMainMenu - infoDict: %@", [[NSBundle mainBundle] infoDictionary]);
#endif
	if(!_mainMenuWindow && [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"LSUIElement"] intValue] == 0)
		{ // no window for main menu assigned yet and UI not disabled - create a fresh one
#if 0
		NSLog(@"create application menu bar %@", NSStringFromRect([[menuScreen menuBarFrame]));
#endif
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_screenParametersNotification:) name:NSApplicationDidChangeScreenParametersNotification object:nil];	// track all further screen changes
		_mainMenuWindow=[[NSPanel alloc] initWithContentRect:[menuScreen _menuBarFrame]
												   styleMask:NSBorderlessWindowMask
													 backing:NSBackingStoreBuffered
													   defer:YES];	// will be released on close
		[_mainMenuWindow setWorksWhenModal:YES];
		[_mainMenuWindow setLevel:NSMainMenuWindowLevel];
		[_mainMenuWindow setTitle:@"Main Menu Window"];
		_mainMenuView=[[NSMenuView alloc] initWithFrame:[[_mainMenuWindow contentView] bounds]];	// make new NSMenuView
		[_mainMenuWindow setContentView:_mainMenuView];		// make content view
		if(0 && [menuScreen _menuBarFrame].origin.x != 0.0)
			{ // Smartphone menu layout
#if 0
			NSLog(@"Smartphone layout");
#endif
			[_mainMenuView _setHorizontalResize:NO]; // keep full width of enclosing window
			[_mainMenuView setHorizontal:YES];		// make horizontal
			[_mainMenuView _setStatusBar:YES];		// i.e. flush right
			}
		else
			{ // PDA layout
#if 0
			NSLog(@"PDA layout");
#endif
			if([self interfaceStyle] != NSMacintoshInterfaceStyle)
				[_mainMenuView _setHorizontalResize:NO]; // keep full width of enclosing window if bottom menubar
			else
				[_mainMenuView _setHorizontalResize:YES]; // resize as needed if menu in top menubar
			[_mainMenuView setHorizontal:YES];		// make horizontal
			[_mainMenuView _setStatusBar:NO];		// not status bar
			}
		}
	if(0 && [menuScreen _menuBarFrame].origin.x != 0.0)
		{ // Smartphone menu (a single item holding the application menu)
		NSString *title=[[aMenu itemAtIndex:0] title]; // should be the application name
		NSMenu *m=[[[NSMenu alloc] initWithTitle:title] autorelease];
		[[m addItemWithTitle:title action:NULL keyEquivalent:@"F2"] setSubmenu:aMenu]; // create single entry and make it a submenu
		// [[mi objectAtIndex:0] setTitle:@"Application"]; // convert into an 'Application' submenu
		[_mainMenuView setMenu:m]; // attach the new menu
		}
	else
		{ // PDA menu
		[_mainMenuView setMenu:aMenu];			// attach the new menu
		}
#if 0
	NSLog(@"_mainMenuWindow = %@", _mainMenuWindow);
	NSLog(@"_mainMenuView = %@", _mainMenuView);
#endif
	if([NSMenu menuBarVisible])
		[_mainMenuWindow orderFront:nil];			// and finally show
#if 0
	NSLog(@"Main Menu now set to %@", [_menu _longDescription]);
#endif
	[[NSDocumentController sharedDocumentController] _updateOpenRecentMenu];	// create/add/update Open Recent submenu
}

- (void) _setMenuBarVisible:(BOOL) flag;
{
	if(flag)
		[_mainMenuWindow orderFront:nil];		// show
	else
		[_mainMenuWindow orderOut:nil];			// hide
}

- (void) _setAppleMenu:(NSMenu *)aMenu
{ // set first item
	// what if the mainMenu is not yet defined?
	[[[self mainMenu] itemAtIndex:0] setSubmenu:aMenu];
#if 0
	NSLog(@"Apple Menu set to %@", [[[self mainMenu] itemAtIndex:0] submenu]);
#endif
}

- (NSMenu *) mainMenu					{ return [super menu]; } // remove Window Close menu item
- (NSMenu *) windowsMenu				{ return _windowsMenu; }

// FIXME: we should observe the windowDidBecome(In)visible notifications and handle the menu

- (void) addWindowsItem:(NSWindow *)aWindow								// Windows submenu
				 title:(NSString *)aString
				 filename:(BOOL)isFilename
{
	[self changeWindowsItem:aWindow title:aString filename:isFilename];
	
	if(!_mainWindow) 
		{ // if the window is being added to the app's window menu it can become main so ask it to be main if no other win is.
		_mainWindow = aWindow;
		[aWindow becomeMainWindow];
		}
}

- (void) changeWindowsItem:(NSWindow *)aWindow 
					 title:(NSString *)aString 
					 filename:(BOOL)isFilename
{
	NSArray *itemArray;
	int idx;
	SEL winaction;
	if (![aWindow isKindOfClass: __windowClass])
		[NSException raise: NSInvalidArgumentException
					 format: @"Object of bad type passed as window"];
													// Can't permit an untitled 
													// window in the win menu.
	if (aString == nil || [aString isEqualToString: @""])
		return;

	if (!_windowsMenu)
		return;	// there is no windows menu
	winaction=@selector(makeKeyAndOrderFront:);
	idx = [_windowsMenu indexOfItemWithTarget:aWindow andAction:winaction];
#if 0
	NSLog(@"NSApp changeWindowsItem idx=%d", idx);
#endif
	if(idx >= 0)
		{ // If the menu exists and the window already has an item, remove it
		[_windowsMenu removeItemAtIndex:idx]; 
		_windowItems--;	// one removed
		}

	// insert by searching from the end of the menu
	// if we reach a separator or an item which is not connected to makeKeyAndOrderFront: insert a separator and then add us
	itemArray=[_windowsMenu itemArray];
	idx = [itemArray count]-1;	// last item
	while(idx >= 0)
		{
		NSMenuItem *item = [itemArray objectAtIndex: idx];
		if ([item isSeparatorItem])
			{
			idx++;	// append behind separator
			break;
			}
		if (!SEL_EQ([item action], winaction))
			{ // different action found, i.e. start of list - append separator and item
			[_windowsMenu addItem:[NSMenuItem separatorItem]];
			idx+=2;	// insert first behind separator
			break;
			}
		if ([[item title] compare: aString] == NSOrderedAscending)
			{ // we have found the position, insert before
			idx++;
			break;
			}
		idx--;
		}

	[[_windowsMenu insertItemWithTitle: aString
						 action: @selector(makeKeyAndOrderFront:)
						 keyEquivalent: @""
						 atIndex: idx] setTarget: aWindow];
	_windowItems++;	// one added
//	[_windowsMenu sizeToFit];
//	[_windowsMenu update];
}

- (void) removeWindowsItem:(NSWindow*)aWindow
{
#if 1
	NSLog(@"NSApp: removeWindowsItem (total=%d) - %@", _windowItems, aWindow);
#endif
	if(_app.isDeallocating)		// If we are within our dealloc then don't remove the window. Most likely dealloc is removing windows from our window list and subsequently NSWindow is calling us to remove itself.
		return;
	if(_windowsMenu)
		{
		int idx=[_windowsMenu indexOfItemWithTarget:aWindow andAction:@selector(makeKeyAndOrderFront:)];
		if(idx >= 0)
			{ // remove from menu
			[_windowsMenu removeItemAtIndex:idx];
			_windowItems--;	// one removed
#if 0
			NSLog(@"window items after remove=%d", _windowItems);
#endif
			if(_windowItems <= 0)
				{ // we have removed the last window
				NSMenuItem *last=[[_windowsMenu itemArray] lastObject];
				if([last isSeparatorItem])
					[_windowsMenu removeItem:last];	// remove the separator if present
				_windowItems=0;
				}
			}
		}
}

- (void) setWindowsMenu:(NSMenu *) aMenu
{
	ASSIGN(_windowsMenu, aMenu);
#if 0
	NSLog(@"Windows Menu set to %@", aMenu);
#endif
}

- (void) updateWindowsItem:(NSWindow *) aWindow
{ // update the status of the menu item
	if (_windowsMenu)
		{
		NSArray *itemArray = [_windowsMenu itemArray];
		unsigned i, count = [itemArray count];

		for (i = 0; i < count; i++)
			{
			id item = [itemArray objectAtIndex: i];
	
			if ([item target] == aWindow)
				{
				NSCellImagePosition	oldPos = [item imagePosition];
				NSImage *oldImage = [item image];
				BOOL changed = NO;
		
				if ([aWindow representedFilename] == nil)
					{
					if (oldPos != NSNoImage)
						{
						[item setImagePosition: NSNoImage];
						changed = YES;
					}	}
				else
					{
					NSImage	*newImage = oldImage;
		
					if (oldPos != NSImageLeft)
						{
						[item setImagePosition: NSImageLeft];
						changed = YES;
						}

					if ([aWindow isDocumentEdited])
						newImage = [NSImage imageNamed: @"GSCloseBroken"];
					else
						newImage = [NSImage imageNamed: @"GSClose"];

					if (newImage != oldImage)
						{
						[item setImage: newImage];
						changed = YES;
					}	}

				if (changed)
					{
					[(NSControl*)[item controlView] sizeToFit];
					[_windowsMenu sizeToFit];
					[_windowsMenu update];
					}

				break;
		}	}	}
}
															// Services menu
- (void) registerServicesMenuSendTypes:(NSArray *)sendTypes returnTypes:(NSArray *)returnTypes
{
	if(!_app.disableServices)
		[_listener registerSendTypes:sendTypes returnTypes:returnTypes];
}

- (NSMenu *) servicesMenu			{ return [_listener servicesMenu]; }
- (id) servicesProvider				{ return [_listener servicesProvider]; }

- (void) setServicesMenu:(NSMenu *)aMenu
{
	[_listener setServicesMenu: aMenu];
}

- (void) setServicesProvider:(id)anObject
{
	if ([_listener servicesProvider] != anObject)
		NSRegisterServicesProvider(anObject, nil);
}

- (id) validRequestorForSendType:(NSString *)sendType returnType:(NSString *)returnType
{
	return nil;
}

- (void) reportException:(NSException *)anException
{ // Report exception
	if (anException)
		NSLog(@"reported exception - %@", anException);
}

- (IBAction) terminate:(id) sender
{ // App termination
	NSDocumentController *d=[NSDocumentController sharedDocumentController];
#if 0
	NSLog(@"terminate:");
#endif
	if(d && ![d _applicationShouldTerminate:self])	// ask for termination
		return;	// cancelled
	if([_delegate respondsToSelector:@selector(applicationShouldTerminate:)])
		if([_delegate applicationShouldTerminate:self] != NSTerminateNow)
			return;	// not now, i.e. NSTerminateCancel or NSTerminateLater
	[self replyToApplicationShouldTerminate:YES];	// NSTerminateNow
}							

- (void) replyToApplicationShouldTerminate:(BOOL) shouldTerminate;
{ // call if delegate returned NSTerminateLater
	if(shouldTerminate)
		{
#if 0
		NSLog(@"replyToApplicationShouldTerminate:YES");
#endif
			[self deactivate];	// if we are active, remove as active application
			[[NSFileManager defaultManager] removeFileAtPath:[NSWorkspace _activeApplicationPath:[[NSBundle mainBundle] bundleIdentifier]] handler:nil];	// remove from launched applications list
			[[NSUserDefaults standardUserDefaults] synchronize]; // write all unwritten changes
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTICE(WillTerminate) object: self];	// last chance to clean-up
		[[NSGraphicsContext currentContext] release];			// clean up connection to X server
		exit(0);	
		}
}

- (void) replyToOpenOrPrint:(NSApplicationDelegateReply) reply;
{
#if 1
	NSLog(@"replyToOpenOrPrint:%d", reply);
#endif
	// should somehow send back to caller!
}

- (BOOL) _application:(in NSApplication *) app openURLs:(in bycopy NSArray *) urls withOptions:(in bycopy NSWorkspaceLaunchOptions) opts;	// handle open
{ // generic application open handler
	unsigned int i, uc=[urls count];
	NSDocumentController *d=[NSDocumentController sharedDocumentController];
	NSMutableArray *files;
	NSEnumerator *e;
	NSURL *url;
#if 1
	NSLog(@"_application: %@ openURLs: %@ opts: %d", app, urls, opts); 
#endif
	if(_delegate && [_delegate respondsToSelector:_cmd] && [_delegate _application:app openURLs:urls withOptions:opts])
		return YES;	// allow to implement in delegate
	else if(d && [d _application:app openURLs:urls withOptions:opts])
		return YES;	// catched in document controller
	if([urls count] == 0)
		return YES;	// nothing to open...
	files=[NSMutableArray arrayWithCapacity:uc];
	e=[urls objectEnumerator];
	while((url=[e nextObject]))
		{ // accept file names only
		if(![url isFileURL])
			{
			NSLog(@"can't open %@ as file", url);
			return NO;
			}
		[files addObject:[url path]];
		}
	if(_delegate)
		{
		if(opts&NSWorkspaceLaunchAndPrint)
			{ // print
#if 1
			NSLog(@"  print by delegate");
#endif
			if([_delegate respondsToSelector:@selector(application:printFiles:withSettings:showPrintPanels:)])
				[_delegate application:app printFiles:files withSettings:nil showPrintPanels:NO];
			else if((uc > 1 || ![_delegate respondsToSelector:@selector(application:printFile:)]) && [_delegate respondsToSelector:@selector(application:printFiles:)])
				[_delegate application:app printFiles:files];
			else if([_delegate respondsToSelector:@selector(application:printFile:)])
				{ // print them individually
				for(i=0; i<uc; i++)
					[_delegate application:app printFile:[files objectAtIndex:i]];
				}
			else
				return NO;	// can't print
#if 1
			NSLog(@"  has been printed by delegate");
#endif
			return YES;
			}
		if(uc == 1 && (opts&NSWorkspaceLaunchWithoutAddingToRecents) && !(opts&NSWorkspaceLaunchNewInstance) && [_delegate respondsToSelector:@selector(application:openFileWithoutUI:)])
			[_delegate application:app openFileWithoutUI:[files objectAtIndex:0]];
		else if(uc == 1 && (opts&NSWorkspaceLaunchWithoutAddingToRecents) && (opts&NSWorkspaceLaunchNewInstance) && [_delegate respondsToSelector:@selector(application:openTempFile:)])
			[_delegate application:app openTempFile:[files objectAtIndex:0]];
		else if(uc == 0 && (opts&NSWorkspaceLaunchNewInstance) && [_delegate respondsToSelector:@selector(applicationOpenUntitledFile:)])
			{ // new file
			if([_delegate respondsToSelector:@selector(applicationShouldOpenUntitledFile:)] && ![_delegate applicationShouldOpenUntitledFile:app])
				return NO;	// denied
			[_delegate applicationOpenUntitledFile:app];	// open untitled
			}
		else if((uc > 1 || ![_delegate respondsToSelector:@selector(application:openFile:)]) && [_delegate respondsToSelector:@selector(application:openFiles:)])
			[_delegate application:app openFiles:files];
		else if([_delegate respondsToSelector:@selector(application:openFile:)])
			{ // open files individually
			for(i=0; i<uc; i++)
				[_delegate application:app openFile:[files objectAtIndex:i]];
			}
		else
			return NO;
#if 1
		NSLog(@"  opened by delegate");
#endif
		return YES;
		}
	return NO;
}
	
// drawing context

- (NSGraphicsContext *) context			{ return [NSGraphicsContext currentContext]; }
- (id) delegate							{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;

	if(_delegate == anObject)
		return;

#define IGNORE_(notif_name) [n removeObserver:_delegate \
								name:NSApplication##notif_name##Notification \
								object:self]

	n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(DidBecomeActive);
		IGNORE_(DidFinishLaunching);
		IGNORE_(DidHide);
		IGNORE_(DidResignActive);
		IGNORE_(DidUnhide);
		IGNORE_(DidUpdate);
		IGNORE_(WillBecomeActive);
		IGNORE_(WillFinishLaunching);
		IGNORE_(WillHide);
		IGNORE_(WillResignActive);
		IGNORE_(WillUnhide);
		IGNORE_(WillUpdate);
		IGNORE_(WillTerminate);
		}

	ASSIGN(_delegate, anObject);
	if(!anObject)
		return;

#define OBSERVE_(notif_name) \
	if ([_delegate respondsToSelector:@selector(application##notif_name:)]) \
		[n addObserver:_delegate \
		 selector:@selector(application##notif_name:) \
		 name:NSApplication##notif_name##Notification \
		 object:self]

	OBSERVE_(DidBecomeActive);
	OBSERVE_(DidFinishLaunching);
	OBSERVE_(DidHide);
	OBSERVE_(DidResignActive);
	OBSERVE_(DidUnhide);
	OBSERVE_(DidUpdate);
	OBSERVE_(WillBecomeActive);
	OBSERVE_(WillFinishLaunching);
	OBSERVE_(WillHide);
	OBSERVE_(WillResignActive);
	OBSERVE_(WillUnhide);
	OBSERVE_(WillUpdate);
	OBSERVE_(WillTerminate);
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	
//	[aCoder encodeObject: [NSApplication _windowList]];
	[aCoder encodeConditionalObject:_keyWindow];
	[aCoder encodeConditionalObject:_mainWindow];
	[aCoder encodeConditionalObject:_delegate];
	[aCoder encodeConditionalObject:_windowsMenu];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		return NIMP;
		}
	_keyWindow = [aDecoder decodeObject];
	_mainWindow = [aDecoder decodeObject];
	_delegate = [aDecoder decodeObject];
	_windowsMenu = [aDecoder decodeObject];

	return self;
}

+ (void) detachDrawingThread:(SEL) selector toTarget:(id) target withObject:(id) argument;
{
	NSLog(@"*** -detachDrawingThread: drawing is not (yet) thread safe! ***");
	[NSThread detachNewThreadSelector:selector toTarget:target withObject:argument];
}

/*
-orderedWindows' not found 
-orderedDocuments' not found -> ask document controller for docbased
*/

/*
 
-activateContextHelpMode:' not found
  1. change cursor to a ?
  2. run a mouse tracking loop while mouse is not clicked and just moved
  3. display tooltips of the elements we are over

	*/

@end /* NSApplication */
