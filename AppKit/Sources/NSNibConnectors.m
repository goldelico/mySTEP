//
//  NSNibConnectors.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <AppKit/NSNibControlConnector.h>
#import <AppKit/NSNibOutletConnector.h>
#import <AppKit/NSKeyValueBinding.h>
#import <AppKit/NSCell.h>
#import "NSAppKitPrivate.h"

@implementation NSNibConnector

- (id) destination; { return _destination; }
- (void) establishConnection; { SUBCLASS; }
- (NSString *) label; { return _label; }

- (void) dealloc;
{
	[_destination release];
	[_source release];
	[_label release];
	[super dealloc];
}

- (void) replaceObject:(id) old withObject:(id) new;
{
	if(_source == old) ASSIGN(_source, new);
	if(_destination == old) ASSIGN(_destination, new);
}

- (void) setDestination:(id) dest; { ASSIGN(_destination, dest); }
- (void) setLabel:(NSString *) label; { ASSIGN(_label, label); }
- (void) setSource:(id) source; { ASSIGN(_source, source); }
- (id) source; { return _source; }

- (NSString *) description;
{
	if(!_destination)
		return [NSString stringWithFormat:@"%@: label=%@ source=%@ First Responder/File Owner", NSStringFromClass([self class]), _label, _source];
	return [NSString stringWithFormat:@"%@: label=%@ source=%@ destination=%@", NSStringFromClass([self class]), _label, _source, _destination];
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	//  [super encodeWithCoder:aCoder];
	[aCoder encodeObject:_label];
	[aCoder encodeObject:_source];
	[aCoder encodeObject:_destination];
}

- (id) initWithCoder:(NSCoder *) coder
{
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#endif
	if(![coder allowsKeyedCoding])
		{
		_label = [[coder decodeObject] retain];
		_source = [[coder decodeObject] retain];
		_destination = [[coder decodeObject] retain];
		}
	else
		{
		_label = [[coder decodeObjectForKey:@"NSLabel"] retain];
		_source = [[coder decodeObjectForKey:@"NSSource"] retain];
		_destination = [[coder decodeObjectForKey:@"NSDestination"] retain];
		}
#if 0
	NSLog(@"initializedWithCoder: %@", self);
#endif
	return self;
}

@end

@implementation NSNibControlConnector

- (void) establishConnection;
{
#if 0
	NSLog(@"establishConnection %@", self);
#endif
	[(NSCell *) _source setTarget:_destination];
	if(![_label hasSuffix:@":"])
		[(NSCell *) _source setAction:NSSelectorFromString([_label stringByAppendingString:@":"])];	// incomplete action method label
	else
		[(NSCell *) _source setAction:NSSelectorFromString(_label)];
}

@end

@implementation NSNibOutletConnector

- (void) establishConnection;
{
#if 0
	NSLog(@"establishConnection %@", self);
#endif
	// FIXME: protect against exceptions?
	NS_DURING
		[_source setValue:_destination forKey:_label];	// call setter or set instance variable through KVC informal protocol
	NS_HANDLER
		NSLog(@"*** While connecting NSNibOutletConnector: %@", localException);
	NS_ENDHANDLER
}

@end

@interface NSNibBindingConnector : NSNibConnector
{
	NSString *_binding;
	NSString *_keypath;
	NSDictionary *_options;
}

- (void) establishConnection;

@end

@implementation NSNibBindingConnector

- (void) establishConnection;
{
#if 0
	NSLog(@"establishConnection %@", self);
#endif
	[_destination bind:_binding toObject:_source withKeyPath:_keypath options:_options];
}

- (id) initWithCoder:(NSCoder *) coder
{
	self=[super initWithCoder:coder];
	if(![coder allowsKeyedCoding])
		{ [self release]; return nil; }
	_binding = [[coder decodeObjectForKey:@"NSBinding"] retain];
	_keypath = [[coder decodeObjectForKey:@"NSKeyPath"] retain];
	_options = [[coder decodeObjectForKey:@"NSOptions"] retain];
	if([coder decodeIntForKey:@"NSNibBindingConnectorVersion"] != 2)
		{ [self release]; return nil; }
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#endif
	return self;
}

- (void) dealloc;
{
	[_binding release];
	[_keypath release];
	[_options release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ binding=%@ keypath=%@ options=%@", [super description], _binding, _keypath, _options];
}

@end

@interface NSIBHelpConnector : NSObject <NSCoding>
{
	id _destination;
	id _file;
	id _marker;
}

@end

@implementation NSIBHelpConnector

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: file=%@ marker=%@ destination=%@", NSStringFromClass([self class]), _file, _marker, _destination];
}

- (void) dealloc;
{
	[_destination release];
	[_file release];
	[_marker release];
	[super dealloc];
}

- (void) replaceObject:(id) old withObject:(id) new;
{
	if(_destination == old) ASSIGN(_destination, new);
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder
{
	if(![coder allowsKeyedCoding])
		{ [self release]; return nil; }
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), coder);
#endif
	_destination = [[coder decodeObjectForKey:@"NSDestination"] retain];
	_file = [[coder decodeObjectForKey:@"NSFile"] retain];
	_marker = [[coder decodeObjectForKey:@"NSMarker"] retain];
#if 0
	NSLog(@"decoded: %@", self);
#endif
	return self;
}

- (void) establishConnection;
{
#if 0
	NSLog(@"establishConnection %@", self);
#endif
	if([_marker isEqualToString:@"NSToolTipHelpKey"])
		[_destination setToolTip:_marker];	// verbatim string
}

@end

@implementation NSIBUserDefinedRuntimeAttributesConnector

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder
{
	if(![coder allowsKeyedCoding])
		{ [self release]; return nil; }
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), coder);
#endif
	_destination = [[coder decodeObjectForKey:@"NSObject"] retain];
//	_pairs = [NSDictionary alloc] initWithObjects:[coder decodeObjectForKey:@"NSValues"] forKeys:[coder decodeObjectForKey:@"NSKeyPaths"]];
	_keyPaths = [[coder decodeObjectForKey:@"NSKeyPaths"] retain];
	_values = [[coder decodeObjectForKey:@"NSValues"] retain];
#if 0
	NSLog(@"decoded: %@", self);
#endif
	return self;
}

- (void) dealloc
{
	[_destination release];
	[_keyPaths release];
	[_values release];
	[super dealloc];
}

- (void) establishConnection;
{
#if 0
	NSLog(@"establishConnection %@", self);
#endif
//	[_destination setValuesForKeysWithDictionary:_pairs];
}

- (void) replaceObject:(id) old withObject:(id) new
{
	NSLog(@"someone wants me to replaceObject: %@ withObject: %@", old, new);
	if(_destination == old) ASSIGN(_destination, new);
}

@end


