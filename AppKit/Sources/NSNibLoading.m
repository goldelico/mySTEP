/* 
   NIBLoading.m - implements all NSBundle Additions

   Copyright (c) 2004 DSITRI.
 
   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: June 2004
   Date: Feb 2006  - reworked to read modern NSKeyCoded based NIB files

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/Foundation.h>

#import <AppKit/NSNib.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSHelpManager.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSSound.h>
#import <AppKit/NSResponder.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>
#import <AppKit/NSNibOutletConnector.h>
#import <AppKit/NSLayoutManager.h>

#import "NSAppKitPrivate.h"

NSString *NSNibOwner=@"NSOwner";
NSString *NSNibTopLevelObjects=@"NSNibTopLevelObjects";	// filled if someone provides and releases an array

#if 0
@implementation NSObject (NIB)

- (id) awakeAfterUsingCoder:(NSCoder *) coder;
{
	NSLog(@"awakeAfterUsingCoder:%@", coder);
	return self;
}

@end
#endif

@interface NSIBObjectData : NSObject <NSCoding>
{
	// not all are really used by a 10.4 NIB
	// and I have no idea how to get the list of all objects out of that
	id rootObject;							// the root object
	id _reserved;							// ?
	NSMapTable *classTable;					// class names (custom classes?)
	NSMutableArray *connections;			// a table of connections
	NSMapTable *objectTable;				// object table
	id fontManager;							// the NSFontManager object
	NSMapTable *instantiatedObjectTable;	// all objects
	NSMapTable *nameTable;					// table of all object names
	int nextOid;							// next object ID to be encoded
	NSResponder *firstResponder;			// the firstResponder
	NSMapTable *oidTable;					// object ID table
	id _document;
	NSString *targetFramework;
	NSMutableSet *visibleWindows;			// all unarchived windows to become visible on/after loading
	NSMutableArray *objects;
}

- (void) establishConnectionsWithExternalNameTable:(NSDictionary *) table;
// - (void) awakeObjectsFromNib;
- (void) orderFrontVisibleWindows;

@end

@interface NSCustomObject : NSObject <NSCoding>
{
	NSString *className;
	id object;
	id extension;
}
- (id) nibInstantiate;	// instantiates if neccessary and returns a non-retained reference
@end

@interface NSClassSwapper : NSObject <NSCoding>
{ // based on this description http://www.wodeveloper.com/omniLists/macosx-dev/2001/March/msg00690.html
	NSString *originalClassName;
    NSString *className;
	id realObject;
}
- (id) nibInstantiate;	// instantiates if neccessary and returns a non-retained reference
@end

@interface NSCustomView : NSView <NSCoding>
{
	NSString *className;
	id view;
	id extension;
	id nextResponder;
	NSView *superView;
	NSArray *subviews;
	int vFlags;
}
- (id) nibInstantiate;	// instantiates if neccessary and returns a non-retained reference
@end

@interface NSWindowTemplate : NSObject
{
	NSString *windowTitle;
	NSString *windowClass;
	NSView *windowView;
	NSWindow *realObject;
	NSString *autosaveName;
	id viewClass;
	id extension;
	NSRect windowRect;
	NSRect screenRect;
	NSSize minSize;
	NSSize maxSize;
	unsigned long _wtFlags;
	int windowStyleMask;
	int windowBacking;
}
- (id) nibInstantiate;	// instantiates if neccessary and returns a non-retained reference
@end

@interface NSCustomResource : NSObject	// NSImage?
{
	NSString *_className;
	NSString *_resourceName;
}
@end

@implementation NSIBObjectData

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"NSIBObjectData initWithCoder");
	NSLog(@"NSIBObjectData initWithCoder: %@", coder);
#endif
	if(![coder allowsKeyedCoding])
		return NIMP;
#if 0
	{
		NSString *key;
		key=@"NSAccessibilityConnectors", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSAccessibilityOidsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSAccessibilityOidsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSClassesKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSClassesValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSConnections", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSFontManager", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSFramework", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSNamesKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]); 
		key=@"NSNamesValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]); 
//		NSNextOid = 207; 
		key=@"NSObjectsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSObjectsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSOidsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSOidsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSRoot", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSVisibleWindows", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		}
#endif
	targetFramework=[[coder decodeObjectForKey:@"NSFramework"] retain];
	rootObject=[[coder decodeObjectForKey:@"NSRoot"] retain];
	// FIXME: there is also an objects table in NIB
	objects=[[coder decodeObjectForKey:@"NSObjectsValues"] retain];	// all objects from NIB that need to receive awakeFromNib
#if 0
	NSLog(@"objects 1=%@", objects);
#endif
	[coder decodeObjectForKey:@"NSObjectsKeys"];
	connections=[[coder decodeObjectForKey:@"NSConnections"] retain];
	visibleWindows=[[coder decodeObjectForKey:@"NSVisibleWindows"] retain];
	[coder decodeObjectForKey:@"NSClassesValues"];
	classTable=[[coder decodeObjectForKey:@"NSClassesKeys"] retain];	// all ClassSwapper objects
	[coder decodeObjectForKey:@"NSClassesKeys"];	// original class names
	objectTable=[[coder decodeObjectForKey:@"NSNamesValues"] retain];	// object table
	nameTable=[[coder decodeObjectForKey:@"NSNamesKeys"] retain];	// table of all object names
	nextOid=[coder decodeIntForKey:@"NSNextOid"];	// next object ID to be encoded
	oidTable=[[coder decodeObjectForKey:@"NSObjectsKeys"] retain];	// object ID table
	fontManager=[[coder decodeObjectForKey:@"NSFontManager"] retain];	// font manager
	// just reference others once
	[coder decodeObjectForKey:@"NSOidsValues"];
	[coder decodeObjectForKey:@"NSOidsKeys"];
	[coder decodeObjectForKey:@"NSAccessibilityConnectors"];
	[coder decodeObjectForKey:@"NSAccessibilityOidsKeys"];
	[coder decodeObjectForKey:@"NSAccessibilityOidsValues"];
	[coder decodeObjectForKey:@"NSClassesValues"];
#if 0
	NSLog(@"rootObject=%@", rootObject);
	NSLog(@"classTable=%@", classTable);
	NSLog(@"connections=%@", connections);
	NSLog(@"objectTable=%@", objectTable);
	NSLog(@"fontManager=%@", fontManager);
	NSLog(@"objects size=%d", [objects count]);
	NSLog(@"objects=%@", objects);
	NSLog(@"nameTable=%@", nameTable);
	NSLog(@"nextOid=%d", nextOid);
	NSLog(@"firstResponder=%@", firstResponder);
	NSLog(@"oidTable=%@", oidTable);
	NSLog(@"_document=%@", _document);
	NSLog(@"targetFramework=%@", targetFramework);
	NSLog(@"visibleWindows=%@", visibleWindows);
#endif
#if 0
	{
		NSString *key;
		key=@"NSAccessibilityConnectors", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSAccessibilityOidsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSAccessibilityOidsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSClassesKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSClassesValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSConnections", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSFontManager", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSFramework", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSNamesKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]); 
		key=@"NSNamesValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]); 
		//		NSNextOid = 207; 
		key=@"NSObjects", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSObjectsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSObjectsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSOidsKeys", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSOidsValues", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSRoot", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
		key=@"NSVisibleWindows", NSLog(@"%@=%@", key, [coder decodeObjectForKey:key]);
	}
#endif
	return self;
}

- (void) establishConnectionsWithExternalNameTable:(NSDictionary *) table;
{
	NSEnumerator *e=[connections objectEnumerator];
	NSNibConnector *c;
	id owner=[table objectForKey:NSNibOwner];
#if 0
	NSUInteger idx=[objects indexOfObject:rootObject];
	NSLog(@"loaded %ld connections", [connections count]);
	NSLog(@"rootObject=%@ idx=%u", rootObject, idx);
	NSLog(@"owner=%@", owner);
#endif
	while((c=[e nextObject]))
		{
		[c replaceObject:rootObject withObject:owner];	// don't connect to the instantiated root object but to the owner
		[c establishConnection];
		}
}

- (void) orderFrontVisibleWindows
{
	// only these should be added to the Windows menu
	// NOTE: it is random which one is finally the key window...
	[visibleWindows makeObjectsPerformSelector:@selector(makeKeyAndOrderFront:) withObject:nil];	// make these windows visible
}

- (id) rootObject; { return rootObject; }

- (void) dealloc;
{
#if 0
	NSLog(@"NSIBObjectData dealloc");
#endif
	[targetFramework release];
	[rootObject release];
	[objects release];
	[connections release];
	[visibleWindows release];
//	[classTable release];
//	[objectTable release];
//	[nameTable release];
//	[oidTable release];
	[fontManager release];
	[super dealloc];
}

@end

@implementation NSCustomObject

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder *) coder;
{
	id customObject;
#if 0
	NSLog(@"NSCustomObject initWithCoder %@", coder);
#endif
	if(![coder allowsKeyedCoding])
		return NIMP;
	className=[[coder decodeObjectForKey:@"NSClassName"] retain];
	object=[[coder decodeObjectForKey:@"NSObject"] retain];	// if defined...
	extension=[[coder decodeObjectForKey:@"NSExtension"] retain];
#if 0
	NSLog(@"className=%@", className);
	NSLog(@"object=%@", object);
	NSLog(@"extension=%@", extension);
#endif
	customObject=[[self nibInstantiate] retain];	// instantiate immediately
#if 0
	NSLog(@"custom object=%@", customObject);
	NSLog(@"custom object class=%@", NSStringFromClass([customObject class]));
	NSLog(@"custom object class class=%@", NSStringFromClass([[customObject class] class]));
	NSLog(@"custom object superclass=%@", NSStringFromClass([customObject superclass]));
#endif
	[self release];
	return customObject;
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSCustomObject dealloc (class=%@) object=%@", className, object);
#endif
	[className release];
	[object release];
	[extension release];
	[super dealloc];
}

- (id) nibInstantiate;
{ // return real object or instantiate fresh one
	Class class;
#if 0
	NSLog(@"custom object nibInstantiate (class=%@)", className);
#endif
	// FIXME: how can we easily/correctly decode/load singletons???
	// maybe only if their -init method also returns the singleton
	if([className isEqualToString:@"NSApplication"])
		return [NSApplication sharedApplication];
	if(object)
		return object;	// already instantiated
	class=NSClassFromString(className);
#if 0
	NSLog(@"nibInstantiate %@", NSStringFromClass(class));
#endif
	if(!class)
		{
		NSLog(@"class %@ not linked for Custom Object", className);
		class=[NSObject class];
		}
	return object=[[class alloc] init];	// retained until we dealloc
}

@end

@implementation NSClassSwapper

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) init;
{ // can't initialize normaly
	return NIMP;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: classname=%@ originalClassName=%@",
		NSStringFromClass([self class]), className, originalClassName];
}

- (id) initWithCoder:(NSCoder *) coder;
{
	Class class;
#if 0
	NSLog(@"NSClassSwapper initWithCoder:%@", coder);
#endif
	if(![coder allowsKeyedCoding])
		return NIMP;
	className=[[coder decodeObjectForKey:@"NSClassName"] retain];
	originalClassName=[[coder decodeObjectForKey:@"NSOriginalClassName"] retain];
#if 0
	NSLog(@"className=%@", className);
	NSLog(@"originalClassName=%@", originalClassName);
#endif
	class=NSClassFromString(className);
	if(!class)
		{
		NSLog(@"class %@ not linked for Class Swapper Object; substituting %@", className, originalClassName);
		class=NSClassFromString(originalClassName);
		}
	if(!class)
		return nil;	// FIXME: exception
	// NOTE: we can't postpone instantiation because otherwise we don't have access to the coder any more
	realObject=[class alloc];	// allocate
	if([class instancesRespondToSelector:_cmd])
		{ // has an implementation of initWithCoder:
#if 0
		NSLog(@"realObject (%@) responds to -%@", NSStringFromClass(class), NSStringFromSelector(_cmd));
#endif
		realObject=[realObject initWithCoder:coder];	// and decode
		}
	else
		{
#if 0
		NSLog(@"realObject (%@) does not respond to -%@", NSStringFromClass(class), NSStringFromSelector(_cmd));
#endif
		realObject=[realObject init];
		}
	return [[[self autorelease] nibInstantiate] retain];	// directly return the instance - but someone may still hold a reference to the NSClassSwapper object
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSClassSwapper %@ dealloc", className);
#endif
	[className release];
	[originalClassName release];
	[realObject release];
	[super dealloc];
}

- (id) nibInstantiate;
{
#if 0
	NSLog(@"NSClassSwapper %@ nibInstantiate -> %@", className, realObject);
#endif
	return realObject;
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) sel
{
	return [realObject methodSignatureForSelector:sel];
}

- (void) forwardInvocation:(NSInvocation *) i
{
	[i setTarget:realObject];
	[i invoke];
}

@end

@implementation NSCustomView

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder *) coder;
{ /* NOTE: our implementation does not call super initWithCoder: ! */
/*
 NSClassName = <NSCFType: 0x318ad0>; 
 NSExtension = <NSCFType: 0x318a80>; 
 NSFrame = <NSCFType: 0x318ab0>; 
 NSNextResponder = <NSCFType: 0x318a90>; 
 NSSuperview = <NSCFType: 0x318aa0>; 
*/
#if 0
	NSLog(@"NSCustomView initWithCoder %@", coder);
#endif
	if(![coder allowsKeyedCoding])
		return NIMP;
	className=[[coder decodeObjectForKey:@"NSClassName"] retain];
	extension=[[coder decodeObjectForKey:@"NSExtension"] retain];	// is a NSString
	vFlags=[coder decodeIntForKey:@"NSvFlags"];
#if 0
	NSLog(@"vflags for custom view=%x", vFlags);
#endif
	_frame=[coder decodeRectForKey:@"NSFrame"];	// defaults to NSZeroRect if undefined
	if([coder containsValueForKey:@"NSFrameSize"])
		_frame.size=[coder decodeSizeForKey:@"NSFrameSize"];
	nextResponder=[[coder decodeObjectForKey:@"NSNextResponder"] retain];
	superView=[[coder decodeObjectForKey:@"NSSuperview"] retain];
	view=[[coder decodeObjectForKey:@"NSView"] retain];
	subviews=[[coder decodeObjectForKey:@"NSSubviews"] retain];	// this will indirectly ask us to nibInstantiate for each superview link!
	[coder decodeObjectForKey:@"NSWindow"];
#if 0
	NSLog(@"className=%@", className);
	NSLog(@"view=%@", view);
	NSLog(@"superview=%@", superView);
	NSLog(@"subviews=%@", subviews);
	NSLog(@"extension=%@", extension);
	NSLog(@"extension's class=%@", NSStringFromClass([extension class]));
	NSLog(@"nextResponder=%@", nextResponder);
#endif
	self=[[[self autorelease] nibInstantiate] retain];	// directly return the instance
#if 0
	NSLog(@"self=%@", self);
#endif
	return self;
}

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc %@", self);
#endif
	[view release];
	[nextResponder release];
	[superView release];
	[subviews release];
	[className release];
	[extension release];
	[super dealloc];
}

- (id) nibInstantiate;
{
	Class class;
	NSView *v;
	NSEnumerator *e;
#if 0
	NSLog(@"NSCutomView nibInstantiate %@", className);
	NSLog(@"view=%@", view);
	NSLog(@"extension=%@", extension);
	NSLog(@"frame=%@", NSStringFromRect(frame));
	NSLog(@"subviews=%@", subviews);
#endif
	if(!view)
		{ // allocate fresh one
		// FIXME: class translation should already be done during decoding
//		class=[(NSKeyedUnarchiver *) coder classForClassName:className];
//		if(!class)
			class=[NSKeyedUnarchiver classForClassName:className];
		if(!class)	// no substitution
			class=NSClassFromString(className);
		if(!class)
			{
			NSLog(@"class %@ not linked for Custom View", className);
			class=[NSView class];
			}
#if 0
		NSLog(@"class=%@", NSStringFromClass(class));
#endif
		view=[class alloc];
#if 0
		NSLog(@"  alloced=%@", view);
#endif
		view=[view initWithFrame:_frame];
#if 0
		NSLog(@"  inited with frame=%@", view);
#endif
		}
	if(nextResponder)
		[view setNextResponder:nextResponder], [nextResponder release], nextResponder=nil;
	if(superView)
		[superView addSubview:view], [superView release], superView=nil;
	if(subviews)
		{
		e=[subviews objectEnumerator];
		while((v=[e nextObject]))
			[view addSubview:v];	// attach subviews
		[subviews release];
		subviews=nil;
		}
#if 0
	NSLog(@"set custom view vFlags=%x", vFlags);
#endif
#define RESIZINGMASK ((vFlags>>0)&0x3f)	// 6 bit
	[view setAutoresizingMask:RESIZINGMASK];
//#define RESIZESUBVIEWS (((vFlags>>8)&1) != 0)
#define RESIZESUBVIEWS (RESIZINGMASK != 0)	// it appears that a custom view has no special bit for this case
	[view setAutoresizesSubviews:RESIZESUBVIEWS];
#define HIDDEN (((vFlags>>31)&1)!=0)
	[view setHidden:HIDDEN];
	return view;
}

@end

@implementation NSWindowTemplate

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder*) coder
{
	Class class;
	if(![coder allowsKeyedCoding])
		return NIMP;
	// FIXME: we don't need to decode that all?
	maxSize=[coder decodeSizeForKey:@"NSMaxSize"];
	minSize=[coder decodeSizeForKey:@"NSMinSize"];
	screenRect=[coder decodeRectForKey:@"NSScreenRect"];	// visibleFrame of the screen when we were archived
	viewClass=[coder decodeObjectForKey:@"NSViewClass"];
	_wtFlags=[coder decodeIntForKey:@"NSWTFlags"];
	windowBacking=[coder decodeIntForKey:@"NSWindowBacking"];
	windowClass=[coder decodeObjectForKey:@"NSWindowClass"];
	windowRect=[coder decodeRectForKey:@"NSWindowRect"];
	windowStyleMask=[coder decodeIntForKey:@"NSWindowStyleMask"];
	windowTitle=[coder decodeObjectForKey:@"NSWindowTitle"];
	windowView=[coder decodeObjectForKey:@"NSWindowView"];
	autosaveName=[coder decodeObjectForKey:@"NSFrameAutosaveName"];
	// more settings from later NIB files
	[coder decodeObjectForKey:@"NSWindowContentMinSize"];
	[coder decodeObjectForKey:@"NSWindowContentMaxSize"];
	[coder decodeObjectForKey:@"NSMaxFullScreenContentSize"];
	[coder decodeObjectForKey:@"NSUserInterfaceItemIdentifier"];
	[coder decodeObjectForKey:@"NSMinFullScreenContentSize"];
	[coder decodeObjectForKey:@"NSWindowIsRestorable"];
#if 0
	NSLog (@"  screenRect = %@", NSStringFromRect(screenRect));
	NSLog (@"  windowRect = %@", NSStringFromRect(windowRect));
	NSLog (@"  windowStyleMask = %d", windowStyleMask);
	NSLog (@"  windowBacking = %d", windowBacking);
	NSLog (@"  windowTitle = %@", windowTitle);
	NSLog (@"  viewClass = %@", viewClass);
	NSLog (@"  windowClass = %@", windowClass);
	NSLog (@"  windowView = %@", [windowView _subtreeDescription]);
	NSLog (@"  realObject = %@", realObject);
	NSLog (@"  extension = %@", extension);
	NSLog (@"  minSize = %@", NSStringFromSize(minSize));
	NSLog (@"  maxSize = %@", NSStringFromSize(maxSize));
#endif
#if 0
	NSLog (@"  _wtFlags = %08x", _wtFlags);
#endif
	class=[(NSKeyedUnarchiver *) coder classForClassName:windowClass];
	if(!class)
		class=[NSKeyedUnarchiver classForClassName:windowClass];
	if(!class)	// no substitution
		class=NSClassFromString(windowClass);	// this allows to load a subclass
	if(!class)
		{
		NSLog(@"class %@ not linked or substituted for Custom Window", windowClass);
		class=[NSWindow class];
		}
	realObject=[[class alloc] initWithContentRect:windowRect
								  styleMask:windowStyleMask
									backing:windowBacking
									  defer:YES];
	[realObject setTitle:windowTitle];
	[realObject setContentView:windowView];
	[realObject setMinSize:minSize];
	[realObject setMaxSize:maxSize];
	if(!autosaveName) autosaveName=@"";
	[realObject setFrameAutosaveName:autosaveName];
#if 0	// FIXME: do something reasonable with these values
	if((_wtFlags>>19)&0x01)
		{ // right spring
		NSLog(@"right spring");
		}
	if((_wtFlags>>19)&0x02)
		{ // left spring
		NSLog(@"left spring");
		}
	if((_wtFlags>>19)&0x04)
		{ // top spring
		NSLog(@"top spring");
		}
	if((_wtFlags>>19)&0x08)
		{ // bottom spring
		NSLog(@"bottom spring");
		}
#endif
	return [[[self autorelease] nibInstantiate] retain];
}

- (id) nibInstantiate;
{
	return realObject;
}

- (void) dealloc;
{
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif	
	[realObject release];
	[super dealloc];
}

@end

@implementation NSCustomResource

#if 0
- (NSSize) size;
{
	NSLog(@"!!! someone is asking for -size of %@", self); // this happens if we simply take it as an NSImage...
	abort();
	return NSMakeSize(10.0, 10.0);
}
#endif

- (NSString *) className; { return _className; }
- (NSString *) name; { return _resourceName; }

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: classname=%@ resourcename=%@", NSStringFromClass([self class]), _className, _resourceName];
}
   
- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder *) coder
{
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#endif
	if(![coder allowsKeyedCoding])
		{
		return NIMP;
		}
	else
		{
		_className = [[coder decodeObjectForKey:@"NSClassName"] retain];
		_resourceName = [[coder decodeObjectForKey:@"NSResourceName"] retain];
#if 0
		NSLog(@"delegate: %@", [(NSKeyedUnarchiver *) coder delegate]);
		NSLog(@"bundle: %@", [[(NSKeyedUnarchiver *) coder delegate] _bundle]);
#endif
		if([_className isEqualToString:@"NSImage"])
			{
			NSImage *img;
			[self autorelease];
#if 0
			NSLog(@"NSCustomResource replaced by NSImage: %@", _resourceName);
#endif
			if([_resourceName isEqualToString:NSApplicationIcon])
				{ // try to load application icon
				NSString *subst=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleIconFile"];	// replace from Info.plist
				if([subst length] > 0)
					ASSIGN(_resourceName, subst);			// try to load that one
				}
			img=[[NSImage _imageNamed:_resourceName inBundle:[(NSNib *)[(NSKeyedUnarchiver *) coder delegate] _bundle]] retain];
			if(!img)
				NSLog(@"NSCustomResource did not find NSImage: %@", _resourceName);
			return (NSCustomResource *) img;
			}
#if 0
		NSLog(@"NSCustomResource initializedWithCoder: %@", self);
#endif
		}
	// we might look-up the object from a table and return a reference instead
#if 0
	NSLog(@"NSCustomResource initializedWithCoder: %@", self);
#endif
	[self autorelease];
	return [[NSClassFromString(_className) alloc] init];
}

@end

@implementation NSButtonImageSource

- (void) encodeWithCoder:(NSCoder*) coder		{ NIMP; }		// NSCoding Protocol

- (id) initWithCoder:(NSCoder *) coder
{
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#endif
	if(![coder allowsKeyedCoding])
		return NIMP;
	_name=[[coder decodeObjectForKey:@"NSImageName"] retain];	// NSRadioButton etc.
	return self;
}

- (id) initWithName:(NSString *) name;
{
	if((self=[super init]))
		{
		_name=[name retain];
		// we could already load images here
		}
	return self;
}

- (NSString *) name; { return _name; }	// same as -[NSImage name]

- (NSString *) description; { return [NSString stringWithFormat:@"NSButtonImageSource: %@", _name]; }

- (void) dealloc;
{
	[_name release];
	[super dealloc];
}

- (NSImage *) buttonImageForCell:(NSButtonCell *) cell;
{
	NSInteger state=[cell state];
	NSImage *img=nil;
#if 0
	NSLog(@"%@ buttonImageForCell:%@", self, cell);
#endif
	if([_name isEqualToString:@"NSRadioButton"])
		{
		switch(state)
			{
			default:
			case NSOffState:
				img=[NSImage imageNamed:@"NSRadioButton"];
				break;
			case NSMixedState:
			case NSOnState:
				img=[NSImage imageNamed:@"NSHighlightedRadioButton"];
				break;
			}
		}
	else if([_name isEqualToString:@"NSSwitch"])
		{
		switch(state)
			{
			default:
			case NSOffState:
				img=[NSImage imageNamed:@"NSSwitch"];
				break;
			case NSMixedState:
				img=[NSImage imageNamed:@"NSMultiStateSwitch"];
				break;
			case NSOnState:
				img=[NSImage imageNamed:@"NSHighlightedSwitch"];
				break;
			}
		}
	else if([_name isEqualToString:@"NSDisclose"])
		{
		if([cell isHighlighted])
			img=[NSImage imageNamed:@"GSDiscloseH"];
		else switch(state)
			{
			case NSOffState:
				img=[NSImage imageNamed:@"GSDiscloseOff"];
				break;
			case NSMixedState:
				img=[NSImage imageNamed:@"GSDiscloseHalf"];
				break;
			case NSOnState:
				img=[NSImage imageNamed:@"GSDiscloseOn"];
				break;
			}
		}
#if 0
	NSLog(@"image=%@", img);
#endif
	return img;
}

@end

@implementation NSNib

- (Class) unarchiver:(NSKeyedUnarchiver *)unarchiver cannotDecodeObjectOfClassName:(NSString *)name originalClasses:(NSArray *)classNames
{
	NSLog(@"unarchiver:%@ cannotDecodeObjectOfClassName:%@ originalClasses:%@", unarchiver, name, classNames);
	return [NSNull class];	// substitute dummy
}

- (id) unarchiver:(NSKeyedUnarchiver *)unarchiver didDecodeObject:(id)object
{
#if 0
	NS_DURING
		NSLog(@"unarchiver:%@ didDecodeObject:%@", unarchiver, object);
	NS_HANDLER
		NSLog(@"unarchiver:%@ didDecodeObject:%@ exception = %@", unarchiver, NSStringFromClass([object class]), localException);
	NS_ENDHANDLER
#endif
	if([decodedObjects containsObject:object])
		{
			NSLog(@"duplicate - already unarchived: %@", object);
			return object;
		}
	[decodedObjects addObject:object];
	return object;
}

#if 0
- (void) unarchiver:(NSKeyedUnarchiver *)unarchiver willReplaceObject:(id)object withObject:(id)newObject
{
	NSLog(@"unarchiver:%@ willReplaceObject:%@ withObject:%@", unarchiver, object, newObject);
}

- (void) unarchiverDidFinish:(NSKeyedUnarchiver *)unarchiver
{
	NSLog(@"unarchiverDidFinish:%@", unarchiver);
}

- (void) unarchiverWillFinish:(NSKeyedUnarchiver *)unarchiver
{
	NSLog(@"unarchiverWillFinish:%@", unarchiver);
}
#endif

- (NSBundle *) _bundle; { return _bundle; }	// the bundle we load the nib file from (required to locate Custom Resources)
- (void) _setBundle:(NSBundle *) b { ASSIGN(_bundle, b); }

- (id) initWithNibNamed:(NSString *) name bundle:(NSBundle *) referencingBundle;
{
	NSString *path;
	if(!referencingBundle) referencingBundle=[NSBundle mainBundle];
#if 0
	NSLog(@"NSNib initWithNibNamed:%@ bundle:%@", name, [referencingBundle bundlePath]);
#endif
	if([name hasSuffix:@".nib"]) name=[name stringByDeletingPathExtension];
#if 0
	NSLog(@"name: %@", name);
#endif
	if(!(path=[referencingBundle pathForResource:name ofType:@"nib" inDirectory:nil]))
		{
#if 0
			NSLog(@"not found in referencing bundle: %@", name);
#endif
			[self release]; return nil;
		}
#if 0
	NSLog(@"bundle=%@", referencingBundle);
	NSLog(@"bundlePath=%@", [referencingBundle bundlePath]);
	NSLog(@"path=%@", path);
	if(![path isAbsolutePath])
		NSLog(@"??? NOT ABSOLUTE ???");
#endif
	return [self _initWithContentsOfURL:[NSURL fileURLWithPath:path] bundle:referencingBundle];
}

- (id) initWithContentsOfURL:(NSURL *) url;
{
	return [self _initWithContentsOfURL:url bundle:nil];	// no bundle
}

- (id) _initWithContentsOfURL:(NSURL *) url bundle:(NSBundle *) bundle;
	{
	NSData *data;
	NSKeyedUnarchiver *unarchiver;
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSString *path=[url path];
	NSString *nib;
		BOOL isDir;
#if 0
	NSLog(@"NSNib initWithContentsOfURL:%@", url);
#endif
	if(![url isFileURL])
		{
		NSLog(@"Invalid URL for NIB: %@", url);
		NSLog(@"description: %@", [url description]);
		NSLog(@"absoluteString: %@", [url absoluteString]);
		NSLog(@"absoluteURL: %@", [url absoluteURL]);
		NSLog(@"baseURL: %@", [url baseURL]);
		NSLog(@"fragment: %@", [url fragment]);
		NSLog(@"host: %@", [url host]);
		NSLog(@"isFile: %@", [url isFileURL]?@"YES":@"NO");
		NSLog(@"parameterString: %@", [url parameterString]);
		NSLog(@"password: %@", [url password]);
		NSLog(@"path: %@", [url path]);
		NSLog(@"port: %@", [url port]);
		NSLog(@"query: %@", [url query]);
		NSLog(@"relativePath: %@", [url relativePath]);
		NSLog(@"relativeString: %@", [url relativeString]);
		NSLog(@"resourceSpecifier: %@", [url resourceSpecifier]);
		NSLog(@"scheme: %@", [url scheme]);
		NSLog(@"standardizedURL: %@", [url standardizedURL]);
		NSLog(@"user: %@", [url user]);
		[arp release]; [self release]; return nil;
		}
	if(![path hasSuffix:@".nib"])
		path=[path stringByAppendingPathExtension:@"nib"];
	if([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir] && isDir)	// file.nib is itself a bundle (IB 1.x - 2.x)
		nib=[path stringByAppendingPathComponent:@"keyedobjects.nib"];
	else
		nib=path;	// it should be the keyed archive itself (compiled by IB 3.x from XIB)
#if 0
	NSLog(@"loading model file %@", nib);
#endif
	data=[[NSData alloc] initWithContentsOfMappedFile:nib];
	if(!data) { [arp release]; [self release]; return nil; }
#if 0
	NSLog(@"file mapped %@", path);
#endif
	decodedObjects=[[NSMutableSet alloc] initWithCapacity:100];	// will store all objects
#if 0
	NSLog(@"initialize unarchiver %@", path);
#endif
	unarchiver=[[NSKeyedUnarchiver alloc] initForReadingWithData:data];
	[data release];	// clean up no longer needed unless archiver does
	if(!unarchiver)
		NSLog(@"can't open with keyed unarchiver");
	[unarchiver setDelegate:(id)self];
	_bundle=[bundle retain];
#if 0
	NSLog(@"unarchiver decode IB.objectdata %@", path);
#endif
	decoded=[unarchiver decodeObjectForKey:@"IB.objectdata"];
#if 0
	NSLog(@"unarchiver did decode IB.objectdata %@", path);
#endif
	if(!decoded)
		NSLog(@"can't decode IB.objectdata");
	[unarchiver finishDecoding];
	[unarchiver release];	// no longer needed
	if(!decoded)
		decoded=[NSUnarchiver unarchiveObjectWithFile:[path stringByAppendingPathComponent:@"objects.nib"]];	// try again by unarchiving
#if 0
	NSLog(@"decoded NSIBObjectData: %@", decoded);
#endif
	if(!decoded)
		{
		NSLog(@"Not able to decode model file %@ (maybe, old NIB format)", path);
		[arp release]; 
		[self release];
		return nil;
		}
	[decoded retain];	// keep decoded object
#if 0 && defined(__mySTEP__)
	free(malloc(8192));
#endif	
	[arp release]; 
	return self;
}

- (void) dealloc;
{
	[_bundle release];
	[decodedObjects release];
	[decoded release];
	[super dealloc];
}

- (BOOL) instantiateNibWithExternalNameTable:(NSDictionary *) table;
{
	NSMutableArray *t;
	NSEnumerator *e;
	id o;
	id owner;
	id rootObject;
#if 0
	NSLog(@"instantiateNibWithExternalNameTable=%@", table);
#endif
	if(![decoded isKindOfClass:[NSIBObjectData class]])
		return NO;
	owner=[table objectForKey:NSNibOwner];
	rootObject=[decoded rootObject];
#if 0
	NSLog(@"establishConnections");
#endif
	[decoded establishConnectionsWithExternalNameTable:table];
#if 0
	NSLog(@"awakeFromNib %d objects", [decodedObjects count]);
#endif
#if 0
	NSLog(@"objects 2=%@", decodedObjects);
#endif
	e=[decodedObjects objectEnumerator];	// make objects awake from nib (in no specific order)
	t=[table objectForKey:NSNibTopLevelObjects];
#if 0
	NSLog(@"toplevel = %@", t);
#endif
	if(!t)
		t=[NSMutableArray arrayWithCapacity:[decodedObjects count]];
	while((o=[e nextObject]))
		{
#if 0
		NSLog(@"try awakeFromNib: %@", NSStringFromClass([o class]));
#endif
		if(o == rootObject)
			o=owner;	// replace
		if([t indexOfObjectIdenticalTo:o] != NSNotFound)
			{
			NSLog(@"instantiateNibWithExternalNameTable: duplicate object: %@", o);
			continue;
			}
		[t addObject:o];
		if([o respondsToSelector:@selector(awakeFromNib)])
			{
#if 0
			NSLog(@"awakeFromNib: %@", o);
#endif
			[o awakeFromNib];							// Send awakeFromNib
			}
		}
	[decodedObjects release];
	decodedObjects=nil;
#if 0
	NSLog(@"orderFrontVisibleWindows");
#endif
	[decoded orderFrontVisibleWindows];
	[decoded release];
	decoded=nil;
	return YES;
}

- (BOOL) instantiateNibWithOwner:(id) owner topLevelObjects:(NSArray **) o;
{
	NSDictionary *table;
#if 0
	NSLog(@"instantiateNibWithOwner:%@ topLevelObjects:%@", owner, o);
#endif
	if(o)
		{
		*o=[NSMutableArray arrayWithCapacity:10];	// get top level objects
		table=[NSDictionary dictionaryWithObjectsAndKeys:owner, NSNibOwner, *o, NSNibTopLevelObjects, nil];
		}
	else
		table=[NSDictionary dictionaryWithObject:owner forKey:NSNibOwner];
	return [self instantiateNibWithExternalNameTable:table];
}

- (void) encodeWithCoder:(NSCoder *) aCoder						// NSCoding protocol
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	NIMP;
	return self;
}

@end

@implementation NSBundle (NSNibLoading)

- (BOOL) loadNibFile:(NSString *) name externalNameTable:(NSDictionary *) context withZone:(NSZone *) zone
{ // look up (relative) name in specified bundle
	return [[[[NSNib allocWithZone:zone] initWithNibNamed:name bundle:self] autorelease] instantiateNibWithExternalNameTable:context];
}

+ (BOOL) loadNibFile:(NSString *) path externalNameTable:(NSDictionary *) context withZone:(NSZone *) zone
{ // requires absolute name!
	NSNib *nib=[[[NSNib allocWithZone:zone] initWithContentsOfURL:[NSURL fileURLWithPath:path]] autorelease];
	return [nib instantiateNibWithExternalNameTable:context];
}

+ (BOOL) loadNibNamed:(NSString*) name owner:(id) owner
{
	NSBundle *b=[NSBundle bundleForClass:[owner class]];
	if(!b) b=[NSBundle mainBundle];
	return [b loadNibFile:name externalNameTable:[NSDictionary dictionaryWithObjectsAndKeys:owner, NSNibOwner, nil] withZone:[owner zone]];
}

@end /* NSBundle (NibLoading) */


@implementation NSBundle (NSHelpManagerAdditions)

- (NSAttributedString *) contextHelpForKey:(NSString *) key;
{
	return nil;
}

@end /* NSBundle (NSHelpManager) */


@implementation NSBundle (NSImageAdditions)

- (NSString *) pathForImageResource:(NSString *) name;
{
	NSString *p;
	NSEnumerator *e=[[NSImage imageUnfilteredFileTypes] objectEnumerator];
	NSString *ftype;
	NSString *ext=[name pathExtension];
	if([ext length] > 0)
		{ // qualified by explicit extension
		if(![[e allObjects] containsObject:ext])
			return nil;	// is not in list of file types
		return [self pathForResource:[name stringByDeletingPathExtension] ofType:ext];
		}
	while((ftype=[e nextObject]))
		{ // try all file types
		p=[self pathForResource:name ofType:ftype];
		if(p)
			return p;	// found
		}
	return nil;	// not found
}

@end /* NSBundle (NSImage) */


@implementation NSBundle (NSSoundAdditions)

- (NSString *) pathForSoundResource:(NSString *) name;
{
	NSString *p;
	NSEnumerator *e=[[NSSound soundUnfilteredFileTypes] objectEnumerator];
	NSString *ftype;
	NSString *ext=[name pathExtension];
	if([ext length] > 0)
		{ // qualified by explicit extension
		if(![[e allObjects] containsObject:ext])
			return nil;	// is not in list of file types
		return [self pathForResource:[name stringByDeletingPathExtension] ofType:ext];
		}
	while((ftype=[e nextObject]))
		{ // try all file types
		p=[self pathForResource:name ofType:ftype];
		if(p)
			return p;	// found
		}
	return nil;	// not found
}

@end /* NSBundle (NSSound) */
