//
//  NSKeyValueCoding.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Jun 05 2006.
//  Copyright (c) 2006 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import <Foundation/NSKeyValueObserving.h>
#import <Foundation/Foundation.h>
#import "NSPrivate.h"

static NSMapTable *_observationInfo;

NSString *NSKeyValueChangeKindKey=@"NSKeyValueChangeKindKey";
NSString *NSKeyValueChangeNewKey=@"NSKeyValueChangeNewKey";
NSString *NSKeyValueChangeOldKey=@"NSKeyValueChangeOldKey";
NSString *NSKeyValueChangeIndexesKey=@"NSKeyValueChangeIndexesKey";

@interface _NSObjectObserver	// root class object that does not recognize any method
{
	NSObject *_realobject;
}
@end

@implementation _NSObjectObserver

- (retval_t) forward:(SEL)aSel :(arglist_t)argFrame
{ // state changes result from calling a method. Therefore, we intercept all method calls, record state and issue notifications
	retval_t r;
	NSInvocation *inv;
#if 1
	NSLog(@"forward:@selector(%@) :... through %@", NSStringFromSelector(aSel), self);
#endif
	if(aSel == 0)
		[NSException raise:NSInvalidArgumentException
					format:@"_NSObjectObserver forward:: %@ NULL selector", NSStringFromSelector(_cmd)];
	inv=[[NSInvocation alloc] _initWithMethodSignature:[_realobject methodSignatureForSelector:aSel] andArgFrame:argFrame];
	if(!inv)
		{ // unknown to system
		[NSException raise:NSInvalidArgumentException
					format:@"NSProxy forward:: [%@ -%@]: selector not recognized", 
			NSStringFromClass([self class]), 
			NSStringFromSelector(aSel)];
		return nil;
		}
	// save object state
	[_realobject forwardInvocation:inv];
	// compare object state
	// send all notifications we need
#if 0
	NSLog(@"invocation forwarded. Returning result");
#endif
	r=[inv _returnValue];
	[inv release];
#if 0
	NSLog(@"returnFrame=%08x", r);
#endif
	return r;
}

- (void) dealloc;
{ // do differently
	NSMapRemove(_observationInfo, (void *) _realobject);
	[_realobject dealloc];
	// NSObjectDealloc(self);
}

@end

@implementation NSObject (NSKeyValueObserving)

#pragma mark implementation

- (void *) observationInfo;
{
	// lock
	if(!_observationInfo)
		return NULL;
	return NSMapGet(_observationInfo, (void *) self);
	// unlock
}

- (void) setObservationInfo:(void *) observationInfo;
{
	// lock
	if(!_observationInfo)
		_observationInfo=NSCreateMapTable(NSNonOwnedPointerMapKeyCallBacks, NSNonOwnedPointerMapValueCallBacks, 20);	// not retained in any way
	if(observationInfo)
		NSMapInsert(_observationInfo, (void *) self, observationInfo);	// store
	else
		NSMapRemove(_observationInfo, (void *) self);
	// unlock
}

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *) key;
{
	return YES;
}

+ (void) setKeys:(NSArray *) keys triggerChangeNotificationsForDependentKey:(NSString *) dependentKey;
{
	// can be stored in the observerInfo of the class record
	// which should simply be a NSMapTable from each key -> dependenKey
	// NOTE: a key may have multiple dependents!
	NIMP;
	return;
}

#pragma mark registration

- (void) addObserver:(id) obj
		  forKeyPath:(NSString *) str
			 options:(NSKeyValueObservingOptions) opts
			 context:(void *) context;
{
	// create observation record
	// store current isa pointer
	// replace by [_NSObjectObserver class]
#if 0	// GNUstep
 GSKVOInfo             *info;
 GSKVOReplacement      *r;
 NSKeyValueObservationForwarder *forwarder;
 NSRange               dot;
 
 setup();
 [kvoLock lock];
 
 // Use the original class
 r = replacementForClass([self class]);
 
 /*
  * Get the existing observation information, creating it (and changing
														   * the receiver to start key-value-observing by switching its class)
  * if necessary.
  */
 info = (GSKVOInfo*)[self observationInfo];
 if (info == nil)
 {
	 info = [[GSKVOInfo alloc] initWithInstance: self];
	 [self setObservationInfo: info];
	 isa = [r replacement];
 }
 
 /*
  * Now add the observer.
  */
 dot = [aPath rangeOfString:@"."];
 if (dot.location != NSNotFound)
 {
	 forwarder = [NSKeyValueObservationForwarder
        forwarderWithKeyPath: aPath
                    ofObject: self
                  withTarget: anObserver
                     context: aContext];
	 [info addObserver: anObserver
			forKeyPath: aPath
			   options: options
			   context: forwarder];
 }
 else
 {
	 [r overrideSetterFor: aPath];
	 [info addObserver: anObserver
			forKeyPath: aPath
			   options: options
			   context: aContext];
 }
 
 [kvoLock unlock];
#endif
}

- (void) removeObserver:(id) obj forKeyPath:(NSString *) str;
{
	// if last observer, restore isa pointer
#if 0	// GNUstep
	GSKVOInfo	*info;
	id forwarder;
	
	setup();
	[kvoLock lock];
	/*
	 * Get the observation information and remove this observation.
	 */
	info = (GSKVOInfo*)[self observationInfo];
	forwarder = [info contextForObserver: anObserver ofKeyPath: aPath];
	[info removeObserver: anObserver forKeyPath: aPath];
	if ([info isUnobserved] == YES)
		{
		/*
		 * The instance is no longer bing observed ... so we can
		 * turn off key-value-observing for it.
		 */
		isa = [self class];
		AUTORELEASE(info);
		[self setObservationInfo: nil];
		}
	[kvoLock unlock];
	if ([aPath rangeOfString:@"."].location != NSNotFound)
		[forwarder finalize];
#endif
	return;
}

#pragma mark notification

- (void) observeValueForKeyPath:(NSString *) path
					   ofObject:(id) object
						 change:(NSDictionary *) dict
						context:(void *) context;
{ // default implementation
	[NSException raise: NSInvalidArgumentException
				format: @"-%@ should be implemented by %@", NSStringFromSelector(_cmd), NSStringFromClass(isa)];
	return;
}

#pragma mark post

// FIXME: go through all observers of this key
// send them the observeValueForKeyPath
// handle dependent keys

// NOTE: implementations must bracket updates with a willChange...
// and didChange...

#if 0 // GNUstep

- (void) _willChangeValueForDependentsOfKey: (NSString *)aKey
{
	NSMapTable keys = NSMapGet(dependentKeyTable, [self class]);
	if (keys)
		{
		NSHashTable dependents = NSMapGet(keys, aKey);
		NSString *dependentKey;
		NSHashEnumerator dependentKeyEnum;
		
		if (!dependents) return;
		dependentKeyEnum = NSEnumerateHashTable(dependents);
		while ((dependentKey = NSNextHashEnumeratorItem(&dependentKeyEnum)))
			{
			[self willChangeValueForKey:dependentKey];
			}
		NSEndHashTableEnumeration(&dependentKeyEnum);
		}
}

- (void) _didChangeValueForDependentsOfKey: (NSString *)aKey
{
	NSMapTable keys = NSMapGet(dependentKeyTable, [self class]);
	if (keys)
		{
		NSHashTable dependents = NSMapGet(keys, aKey);
		NSString *dependentKey;
		NSHashEnumerator dependentKeyEnum;
		
		if (!dependents) return;
		dependentKeyEnum = NSEnumerateHashTable(dependents);
		while ((dependentKey = NSNextHashEnumeratorItem(&dependentKeyEnum)))
			{
			[self didChangeValueForKey:dependentKey];
			}
		NSEndHashTableEnumeration(&dependentKeyEnum);
		}
}
#endif

- (void) didChange:(NSKeyValueChange) changeKind
   valuesAtIndexes:(NSIndexSet *) indexes
			forKey:(NSString *) aKey;
{
	_NSObjectObserver     *info;
	NSMutableDictionary   *change;
	NSMutableArray        *array;
	
	info = (_NSObjectObserver *)[self observationInfo];
	change = (NSMutableDictionary *)[info changeForKey: aKey];
	array = [self valueForKey: aKey];
	
	[change setValue: [NSNumber numberWithInt: changeKind] forKey:
		NSKeyValueChangeKindKey];
	[change setValue: indexes forKey: NSKeyValueChangeIndexesKey];
	
	if (changeKind == NSKeyValueChangeInsertion
		|| changeKind == NSKeyValueChangeReplacement)
		{
		[change setValue: [array objectsAtIndexes: indexes]
				  forKey: NSKeyValueChangeNewKey];
		}
	
	[info notifyForKey: aKey ofChange: change];
	[info setChange:nil forKey: aKey];
	[self didChangeValueForDependentsOfKey: aKey];
}

- (void) didChangeValueForKey:(NSString *) aKey;
{
	_NSObjectObserver		*info;
	NSMutableDictionary   *change;
	
	info = (_NSObjectObserver *)[self observationInfo];
	change = (NSMutableDictionary *)[info changeForKey: aKey];
	[change setValue: [self valueForKey: aKey]
			  forKey: NSKeyValueChangeNewKey];
	[change setValue: [NSNumber numberWithInt: NSKeyValueChangeSetting]
			  forKey: NSKeyValueChangeKindKey];
	
	[info notifyForKey: aKey ofChange: change];
	[info setChange:nil forKey: aKey];
	[self didChangeValueForDependentsOfKey: aKey];
}

- (void) didChangeValueForKey:(NSString *) aKey
			  withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				 usingObjects:(NSSet *) objects;
{
	_NSObjectObserver	  *info;
	NSMutableDictionary   *change;
	NSMutableSet          *oldSet;
	NSMutableSet          *set;
	
	info = (_NSObjectObserver *)[self observationInfo];
	change = (NSMutableDictionary *)[info changeForKey: aKey];
	oldSet = [change valueForKey: @"oldSet"];
	set = [self valueForKey: aKey];
	
	[change setValue: nil forKey: @"oldSet"];
	
	if (mutationKind == NSKeyValueUnionSetMutation)
		{
		set = [[set mutableCopy] autorelease];
		[set minusSet: oldSet];
		[change setValue: [NSNumber numberWithInt: NSKeyValueChangeInsertion]
				  forKey: NSKeyValueChangeKindKey];
		[change setValue: set forKey: NSKeyValueChangeNewKey];
		}
	else if (mutationKind == NSKeyValueMinusSetMutation
			 || mutationKind == NSKeyValueIntersectSetMutation)
		{
		[oldSet minusSet: set];
		[change setValue: [NSNumber numberWithInt: NSKeyValueChangeRemoval]
				  forKey: NSKeyValueChangeKindKey];
		[change setValue: oldSet forKey: NSKeyValueChangeOldKey];
		}
	else if (mutationKind == NSKeyValueSetSetMutation)
		{
		NSMutableSet      *old;
		NSMutableSet      *new;
		
		old = [[oldSet mutableCopy] autorelease];
		[old minusSet: set];
		new = [[set mutableCopy] autorelease];
		[new minusSet: oldSet];
		[change setValue: [NSNumber numberWithInt: NSKeyValueChangeReplacement]
				  forKey: NSKeyValueChangeKindKey];
		[change setValue: old forKey: NSKeyValueChangeOldKey];
		[change setValue: new forKey: NSKeyValueChangeNewKey];
		}
	[info notifyForKey: aKey ofChange: change];
	[info setChange:nil forKey: aKey];
	[self didChangeValueForDependentsOfKey: aKey];
}

- (void) willChange:(NSKeyValueChange) changeKind
	valuesAtIndexes:(NSIndexSet *) indexes
			 forKey:(NSString *) aKey;
{
	_NSObjectObserver	  *info;
	NSDictionary          *change;
	NSMutableArray        *array;
	
	info = (_NSObjectObserver *)[self observationInfo];
	change = [NSMutableDictionary dictionary];
	array = [self valueForKey: aKey];
	
	if (changeKind == NSKeyValueChangeRemoval
		|| changeKind == NSKeyValueChangeReplacement)
		{
		[change setValue: [array objectsAtIndexes: indexes]
				  forKey: NSKeyValueChangeOldKey];
		}
	
	[info setChange: change forKey: aKey];
	[self willChangeValueForDependentsOfKey: aKey];
}

- (void) willChangeValueForKey:(NSString *) aKey;
{
	id old = [self valueForKey: aKey];
	NSDictionary * change;
	if (old != nil)
		change = [NSMutableDictionary
    dictionaryWithObject: [self valueForKey: aKey]
                  forKey: NSKeyValueChangeOldKey];
	else
		change = [NSMutableDictionary dictionary];
	[(_NSObjectObserver *)[self observationInfo] setChange: change forKey: aKey];
	[self willChangeValueForDependentsOfKey: aKey];
}

- (void) willChangeValueForKey:(NSString *) aKey
			   withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				  usingObjects:(NSSet *) objects;
{
	_NSObjectObserver	*info;
	NSDictionary  *change;
	NSMutableSet  *set;
	
	info = (_NSObjectObserver *)[self observationInfo];
	change = [NSMutableDictionary dictionary];
	set = [self valueForKey: aKey];
	
	[change setValue: [[set mutableCopy] autorelease] forKey: @"oldSet"];
	[info setChange: change forKey: aKey];
	[self willChangeValueForDependentsOfKey: aKey];
}

@end

@implementation NSArray (NSKeyValueObserving)

- (void) addObserver:(NSObject *)anObserver
  toObjectsAtIndexes:(NSIndexSet *)indexes
		  forKeyPath:(NSString *)keyPath
			 options:(NSKeyValueObservingOptions)options
			 context:(void *)context;
{
	return;
}

- (void) removeObserver:(NSObject *)anObserver
   fromObjectsAtIndexes:(NSIndexSet *)indexes
			 forKeyPath:(NSString *)keyPath;
{
	return;
}

@end
