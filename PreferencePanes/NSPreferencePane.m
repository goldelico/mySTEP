//
//  PreferencePane.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

NSString *NSPreferencePaneDoUnselectNotification=@"NSPreferencePaneDoUnselectNotification";
NSString *NSPreferencePaneCancelUnselectNotification=@"NSPreferencePaneCancelUnselectNotification";

@implementation NSPreferencePane

- (NSView *) assignMainView;
{ // take window connected to _window and extract the views; then release the window
	if(!_window)
		return _mainView;	// already assigned
	[self setMainView:[_window contentView]];
	[_window setReleasedWhenClosed:YES];	// ...and release
	[_window close];	// close
	_window=nil;
	// set keyboard focus views
	return _mainView;
}

- (BOOL) autoSaveTextFields; { return YES; } // can override in subclass

- (NSBundle *) bundle; { return _bundle; }

- (void) dealloc;
{
	[_bundle release];
	[super dealloc];
}

- (void) didSelect; { } // should overrride in subclass
- (void) didUnselect; { } // should overrride in subclass

- (NSView *) firstKeyView; { return _firstKeyView; }
- (NSView *) initialKeyView; { return _initialKeyView; }

- (id) initWithBundle:(NSBundle *) bundle;
{
	self=[super init];
	if(self)
		{
		_bundle=bundle;
		}
	return self;
}

- (BOOL) isSelected; { return [_mainView window] != nil; }  // is visible

- (NSView *) lastKeyView; { return _lastKeyView; }

- (NSView *) loadMainView;
{ // this is the main entry point called from the system settings application
	if(![_bundle loadNibFile:[self mainNibName]
			     externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:self, @"NSOwner", nil]
				 withZone:NSDefaultMallocZone()])
		return nil;	// could not load
	[self assignMainView];	// extract mainView from the _window outlet
	[self mainViewDidLoad];
	return _mainView;
}

- (NSString *) mainNibName;
{
	NSString *nib=[_bundle objectForInfoDictionaryKey:@"NSMainNibFile"];
	if(!nib)
		return @"Main";
	return nib;
}

- (NSView *) mainView; { return _mainView; }

- (void) mainViewDidLoad; { } // may override in subclass

- (void) replyToShouldUnselect:(BOOL) shouldUnselect;
{
	if(shouldUnselect)
		[[NSNotificationCenter defaultCenter] postNotificationName:NSPreferencePaneDoUnselectNotification object:self];
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:NSPreferencePaneCancelUnselectNotification object:self];
}

- (void) setFirstKeyView:(NSView *) view
{
	_firstKeyView=view;
}

- (void) setInitialKeyView:(NSView *) view
{
	_initialKeyView=view;
}

- (void) setLastKeyView:(NSView *) view
{
	_lastKeyView=view;
}

- (void) setMainView:(NSView *) view
{
	[_mainView autorelease];
	_mainView=[view retain];
}

- (NSPreferencePaneUnselectReply) shouldUnselect { return NSUnselectNow; } // override in subclass

- (void) updateHelpMenuWithArray:(NSArray *) arrayOfMenuItems;
{
	NSLog(@"updateHelpMenuWithArray not implemented");
}

- (void) willSelect; { } 	// may override in subclass
- (void) willUnselect; { }	// may override in subclass

@end

@implementation NSApplication (PreferencePanes)

// could this be called several times in parallel creating multiple windows????

- (void) orderFrontPreferencePane:(NSString *) name;
{ // look up in Resources
	NSString *path=name;
	NSBundle *b=[NSBundle bundleWithPath:path]; // look up in application resources
	static NSWindow *settingsWindow;
	static NSMutableDictionary *panes;  // cached panes - indexed by path
	NSPreferencePane *current;
	Class class;
	NSPreferencePaneUnselectReply reply;
	NSString *key;
	// should use caching algorithm (i.e. shared window)
#if 0
	NSLog(@"open %@", [b bundlePath]);
#endif
	if(!(current=[panes objectForKey:path]))
		{ // not found in cache
		if(!panes)
			panes=[[NSMutableDictionary dictionaryWithCapacity:2] retain];
		class=[b principalClass];
		current=[[[class alloc] initWithBundle:b] retain];   // try to create
		if(!current)
			return; // failed to load
		[panes setObject:current forKey:path];  // store in cache
		[current loadMainView]; // load view
		}
	[current willSelect];
	if(!settingsWindow)
		{
		settingsWindow=[[NSWindow alloc] init];
		}
	[settingsWindow setContentSize:[[current mainView] frame].size];	// resize the Window to fit
	[settingsWindow setContentView:[current mainView]]; // make it the content
	[settingsWindow makeKeyAndOrderFront:self];
	key=[b objectForInfoDictionaryKey:@"NSPrefPanelLabel"];
	if(!key)
		key=[b objectForInfoDictionaryKey:@"CFBundleName"];
	if(key)
		[settingsWindow setTitle:key];   // set title label from bundle
	[current didSelect];
	while(YES)
		{
		// Runloop here
		reply=[current shouldUnselect];
		if(reply == NSUnselectLater)
			{
			// how to handle that? NSNotification?
			}
		if(reply != NSUnselectCancel)
			break;
		}
	[current willUnselect];
	[settingsWindow orderOut:self]; // done - make invisible
	[current didUnselect];
}

- (void) orderFrontStandardPreferencePane:(id)sender;   // could connect Preferences... button or menu item
{
	[self orderFrontPreferencePane:@"myApp.prefPane"];	// ? use main bundle identifier ?
}

@end
