/* 
   NSNotificationCenter.m

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#import <Foundation/NSNotification.h>
#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSException.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSDistributedNotificationCenter.h>

#define DEFAULT_CAPACITY 1023

NSString *NSLocalNotificationCenterType = @"NSLocalNotificationCenterType";

// Class variables	
static NSNotificationCenter *_defaultCenter = nil;
static NSDistributedNotificationCenter *_defaultDistributedCenter = nil;


@interface GSNoteObserver : NSObject
{
@public
    id observer;						// observer that will receive selector
    SEL selector;						// in a postNotification:
}

- (BOOL) isEqual:other;
- (unsigned) hash;
- (void) postNotification:(NSNotification*)notification;

@end

@implementation GSNoteObserver

- (BOOL) isEqual:(id)other
{
    if (![other isKindOfClass:[GSNoteObserver class]])
    	return NO;

	return (observer == ((GSNoteObserver *)other)->observer) 
			&& SEL_EQ(selector, ((GSNoteObserver *)other)->selector);
}

- (unsigned) hash
{
	return ((long)observer >> 4)+ __NSHashCString(NULL,sel_get_name(selector));
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: -> %@", NSStringFromClass(isa), observer];
}

- (void) postNotification:(NSNotification*)notification
{
#if 0
	NSLog(@"postNotification %@", notification, observer);
	NSLog(@"  observer=%p", observer);
	NSLog(@"  observer=%@", observer);
#endif
    [observer performSelector:selector withObject:notification];
#if 0
	NSLog(@"posted");
#endif
}

@end /* GSNoteObserver */


@interface GSNoteObjectObservers : NSObject				// Register for objects
{														// to observer mapping
    NSHashTable *observerItems;
}

- (id) init;
- (unsigned int) count;
- (void) addObjectsToList:(NSMutableArray*)list;
- (void) addObserver:(id)observer selector:(SEL)selector;
- (void) removeObserver:(id)observer;

@end

@implementation GSNoteObjectObservers

- (id) init
{
    observerItems = NSCreateHashTable(NSObjectHashCallBacks, DEFAULT_CAPACITY);
    return self;
}

- (void) dealloc
{
    NSFreeHashTable(observerItems);
    [super dealloc];
}

- (unsigned int) count				{ return NSCountHashTable(observerItems); }

- (void) addObjectsToList:(NSMutableArray*)list
{
	NSHashEnumerator items = NSEnumerateHashTable(observerItems);
	id reg;

    while((reg = (id)NSNextHashEnumeratorItem(&items)))
		[list addObject:reg];
}

- (void) addObserver:(id)observer selector:(SEL)selector
{
	GSNoteObserver *reg = [[GSNoteObserver alloc] autorelease];

	reg->observer = observer;
	reg->selector = selector;
    NSHashInsertIfAbsent(observerItems, reg);
}

- (void) removeObserver:(id)observer
{
	GSNoteObserver *reg;
	int i, count = NSCountHashTable(observerItems);
	NSMutableArray *list = [[NSMutableArray alloc] initWithCapacity:count];
	NSHashEnumerator itemsEnum = NSEnumerateHashTable(observerItems);

	[list autorelease];
    
    while((reg = (id)NSNextHashEnumeratorItem(&itemsEnum)))
		if (reg->observer == observer)
			[list addObject:reg];
    
    for (i = [list count]-1; i >= 0; i--)
		NSHashRemove(observerItems, [list objectAtIndex:i]);
}

@end /* GSNoteObjectObservers */


@interface GSNoteDictionary : NSObject					// Register for objects 
{														// to observer mapping
    NSMapTable *objectObservers;
    GSNoteObjectObservers *nilObjectObservers;
}

- (id) init;
- (id) listToNotifyForObject:object;
- (void) addObserver:(id)observer selector:(SEL)selector object:(id)object;
- (void) removeObserver:(id)observer object:(id)object;
- (void) removeObserver:(id)observer;

@end

@implementation GSNoteDictionary

- (id) init
{
    objectObservers = NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, 
								NSObjectMapValueCallBacks, DEFAULT_CAPACITY);
    nilObjectObservers = [GSNoteObjectObservers new];

    return self;
}

- (void) dealloc
{
    NSFreeMapTable(objectObservers);
    [nilObjectObservers release];
    [super dealloc];
}

- (id) listToNotifyForObject:(id)object
{
id reg = nil;
int count;
id list;
    
    if (object)
		reg = (id)NSMapGet(objectObservers, object);
    count = [reg count] + [nilObjectObservers count];
    list = [[[NSMutableArray alloc] initWithCapacity:count] autorelease];
    [reg addObjectsToList:list];
    [nilObjectObservers addObjectsToList:list];
    
    return list;
}

- (void) addObserver:(id)observer selector:(SEL)selector object:(id)object
{
	GSNoteObjectObservers *reg;
    
    if (object) 
		{
		if (!(reg = (id)NSMapGet(objectObservers, object))) 
			{
			reg = [[GSNoteObjectObservers new] autorelease];
			NSMapInsert(objectObservers, object, reg);
		}	}
    else
		reg = nilObjectObservers;
    
    [reg addObserver:observer selector:selector];
}

- (void) removeObserver:(id)observer object:(id)object
{
GSNoteObjectObservers *reg;

	reg = (object) ? NSMapGet(objectObservers, object) : nilObjectObservers;
    [reg removeObserver:observer];
}

- (void) removeObserver:(id)observer
{
id obj, reg;
NSMapEnumerator regEnum = NSEnumerateMapTable(objectObservers);

    while (NSNextMapEnumeratorPair(&regEnum, (void*)&obj, (void*)&reg))
		[reg removeObserver:observer];

    [nilObjectObservers removeObserver:observer];
}

@end /* GSNoteDictionary */

//*****************************************************************************
//
// 		NSNotificationCenter 
//
//*****************************************************************************

@implementation NSNotificationCenter 

+ (void) initialize
{
    if (_defaultCenter == nil) 
		_defaultCenter = [self new];
}

+ (id) defaultCenter			{ return _defaultCenter; }

- (id) init
{
	if((self=[super init]))
		{
		_nameToObjects = [NSMutableDictionary new];	// this requires that NSDictionary overwrites allocWithZone and not only alloc
		_nullNameToObjects = [GSNoteDictionary new];
		}
    return self;
}

- (void) dealloc
{
    [_nameToObjects release];
    [_nullNameToObjects release];

    [super dealloc];
}

- (void) addObserver:(id)observer 
			selector:(SEL)selector 
			name:(NSString*)notificationName 
			object:(id)object
{
	GSNoteDictionary *reg;
    if (notificationName == nil)
		reg = _nullNameToObjects;
    else 
		{
		if (!(reg = [_nameToObjects objectForKey:notificationName])) 
			{
			reg = [[GSNoteDictionary new] autorelease];
			[_nameToObjects setObject:reg forKey:notificationName];
		}	}

    [reg addObserver:observer selector:selector object:object];
}

- (void) removeObserver:(id)observer 
				   name:(NSString*)notificationName 
				   object:(id)object
{
GSNoteDictionary *reg;

    if (notificationName == nil)
		reg = _nullNameToObjects;
    else
		reg = [_nameToObjects objectForKey:notificationName];
    [reg removeObserver:observer object:object];
}

- (void) removeObserver:observer
{
	NSString *name;
	NSEnumerator *enumerator = [_nameToObjects keyEnumerator];

    while ((name = [enumerator nextObject]))
		[[_nameToObjects objectForKey:name] removeObserver:observer];

    [_nullNameToObjects removeObserver:observer];
}

- (void) postNotificationName:(NSString*)notificationName object:object
{
	NSNotification *notice = [[NSNotification alloc] initWithName:notificationName object:object userInfo:nil];
    [self postNotification: notice];
    [notice release];
}

- (void) postNotificationName:(NSString*)notificationName 
					   object:object
					   userInfo:(NSDictionary*)userInfo;
{
	NSNotification *notice = [[NSNotification alloc] initWithName:notificationName object:object userInfo:userInfo];
	[self postNotification: notice];
    [notice release];
}

- (void) postNotification:(NSNotification*)notice
{
	NSArray *name, *noname;								// post notification to all
	GSNoteDictionary *reg;								// registered observers
	NSString *notificationName = [notice name];
	id object = [notice object];
												
    if (notificationName == nil)
		[NSException raise:NSInvalidArgumentException
					 format:@"NSNotification: notification name is nil"];
												// get objects to notify with
 												// registered notification name
    reg = [_nameToObjects objectForKey:notificationName];	
    name = [reg listToNotifyForObject:object];
												// get objects to notify with 
												// no notification name
    noname = [_nullNameToObjects listToNotifyForObject:object];

												// send notifications
#if 0
	NSLog(@"post notification %@", notice);
	NSLog(@"  name %@", name);
	NSLog(@"  noname %@", noname);
#endif
	NS_DURING
		[name makeObjectsPerformSelector:@selector(postNotification:) withObject:notice];
		[noname makeObjectsPerformSelector:@selector(postNotification:) withObject:notice];
	NS_HANDLER
		NSLog(@"Exception during postNotification %@: %@", notice, [localException reason]);
	NS_ENDHANDLER
}

@end /* NSNotificationCenter */

@implementation NSDistributedNotificationCenter

+ (void) initialize
{
    if (_defaultDistributedCenter == nil) 
		_defaultDistributedCenter = [[self notificationCenterForType:NSLocalNotificationCenterType] retain];
}

+ (id) defaultCenter			{ return _defaultDistributedCenter; }

+ (NSNotificationCenter *) notificationCenterForType:(NSString *) type;
{
	if([type isEqualToString:NSLocalNotificationCenterType])
		return [[self new] autorelease];
	return nil;
}

- (id) init
{
	if((self=[super init]))
		{
		
		}
	return self;
}

- (void) addObserver:(id) anObserver
			selector:(SEL) aSelector
				name:(NSString *) notificationName
			  object:(NSString *) anObject
  suspensionBehavior:(NSNotificationSuspensionBehavior) suspensionBehavior;
{
	
}

- (void) postNotificationName:(NSString *) notificationName
					   object:(NSString *) anObject
					 userInfo:(NSDictionary *) userInfo
		   deliverImmediately:(BOOL) deliverImmediately;
{
	[self postNotificationName:notificationName object:anObject userInfo:userInfo options:deliverImmediately?NSNotificationDeliverImmediately:0];
}

- (void) postNotificationName:(NSString *) name
					   object:(NSString *) anObject
					 userInfo:(NSDictionary *) userInfo
					  options:(NSUInteger) options;
{
	
}

- (void) setSuspended:(BOOL) flag;
{
	_suspended=flag;
}

- (BOOL) suspended;
{
	return _suspended;
}

@end

