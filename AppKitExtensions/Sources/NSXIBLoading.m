//
//  NSXIBLoading.m
//  AppKitExtensions
//
//  Created by H. Nikolaus Schaller on 09.03.21.
//
//

#import "NSXIBLoading.h"

@interface NSNib (NSNibInternal)
- (id) _initWithContentsOfURL:(NSURL *) url bundle:(NSBundle *) bundle;
@end

@interface NSXib : NSNib
{

}

@end

@implementation NSXib

- (id) _initWithContentsOfURL:(NSURL *) url bundle:(NSBundle *) bundle;
{
	NSError *error;
	NSXMLDocument *xml;
	NSXMLElement *root;
	id objects;
	xml=[[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
	if(!xml)
		{
		[self release];
		return nil;
		}
	/* example
		<document type="com.apple.InterfaceBuilder3.Cocoa.XIB" version="3.0" toolsVersion="11762" systemVersion="15G22010" targetRuntime="MacOSX.Cocoa" propertyAccessControl="none">
		<dependencies>
		<deployment version="1070" identifier="macosx"/>
		<plugIn identifier="com.apple.InterfaceBuilder.CocoaPlugin" version="11762"/>
		</dependencies>
		<objects>
		<customObject id="-2" userLabel="File's Owner" customClass="NSApplication">
		<connections>
		<outlet property="delegate" destination="449" id="450"/>
		</connections>
		</customObject>
		<customObject id="-1" userLabel="First Responder" customClass="FirstResponder"/>
		<customObject id="-3" userLabel="Application" customClass="NSObject"/>
		<menu title="AMainMenu" systemMenu="main" id="29" userLabel="MainMenu">
		<items>
		<menuItem title="ElectroniCAD" id="56">
		<menu key="submenu" title="ElectroniCAD" systemMenu="apple" id="57">
	 */
	root=[xml rootElement];	// <document>
	// process <dependencies>
	objects=[root elementsWithTag:@"objects"];
	// loop over objects
	//   <customObject>
	//   <menu>
	//   <window>
	// recursion for view hierarchy

	// Alternative: wenn mySTEP eine XIB direkt einlesen kann (als Funktion des NIBloaders)
	// dann braucht man nur die XIB lesen und als NIB schreiben bzw. umgekehrt
	// => Konvertierungslogik zu Teil von AppKit(Extensions) machen!
	// ibtool ist dann nur ein Command-Line-Wrapper
	return self;
}

- (void) dealloc;
{
	[super dealloc];
}

#if MATERIAL

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
	/*
	 * Here, we should run a first loop and call nibInstantiate for all custom objects
	 * We could then easily detect the rootObject and substitute the owner instead of instantiating a new copy
	 * The problem is what happens if some other objects decodes a reference to a custom object?
	 * It can not link to the real object unless we already return it by initWithCoder:
	 * Or we need a mechanism that pointers to decoded custom objects are collected...
	 * and updated as well
	 * But that is almost impossible, e.g. if the NSArray of the subviews is decodedit would embed
	 * the CustomViews and replacing them is a complex operation...
	 */
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

#endif

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
	;
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	return nil;
}

@end

@implementation NSNib (XIB)

- (id) initWithContentsOfURL:(NSURL *) url;
{
	if([[url path] hasSuffix:@".xib"])
		{ // do XIB loading
		[self release];
		self=[NSXib alloc];
		}
	return [self _initWithContentsOfURL:url bundle:nil];	// no bundle
}

@end
