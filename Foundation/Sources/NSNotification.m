/*
 NSNotification.m

 Implementation of NSNotification for mySTEP

 Copyright (C) 1996 Free Software Foundation, Inc.

 Author:	Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	March 1996

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSNotification.h>
#import <Foundation/NSString.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSCoder.h>
#import <Foundation/NSAutoreleasePool.h>

@implementation NSNotification

#if 0
+ (id) allocWithZone:(NSZone *)z
{
	extern NSAutoreleasePool *__currentAutoreleasePool(void);
	fprintf(stderr, "NSNotification alloc: current ARP %p\n", __currentAutoreleasePool());
	return [super allocWithZone:z];
}
#endif

+ (NSNotification *) notificationWithName:(NSString*)name
								   object:(id)object
								 userInfo:(NSDictionary*)info
{
	return [[[self alloc] initWithName: name
						  object: object
							  userInfo: info] autorelease];
}

+ (NSNotification *) notificationWithName:(NSString*)name object:object
{
	return [self notificationWithName:name object:object userInfo:nil];
}

- (id) initWithName:(NSString*)name object:(id)object userInfo:(NSDictionary*)info
{ // designated initializer (not official!)
	if((self=[super init]))
		{
		_name = [name copy];
		//		_object = [object retain];			// this causes problems with sending notificatins from within -dealloc
		_object = object;
		_info = [info retain];
		}
	return self;
}

- (NSString *) description; { return [NSString stringWithFormat:@"%@: %@ -> %@\ninfo = %@", NSStringFromClass([self class]), _name, _object, _info]; }

- (void) dealloc
{
	[_name release];
	//	[_object release];
	[_info release];
	[_queued release];

	[super dealloc];
}

- (NSString*) name						{ return _name; }
- (id) object							{ return _object; }
- (id) copyWithZone:(NSZone *) zone								{ return [self retain]; }
- (NSDictionary*) userInfo				{ return _info; }

- (void) encodeWithCoder:(NSCoder*)coder				// NSCoding protocol
{
	[coder encodeObject:_name];
	[coder encodeObject:_object];
	[coder encodeObject:_info];
}

- (id) initWithCoder:(NSCoder*)coder
{
	return [self initWithName:[coder decodeObject]
					   object:[coder decodeObject]
					 userInfo:[coder decodeObject]];
}

@end
