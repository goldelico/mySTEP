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

@implementation NSObject (NSKeyValueObserving)

+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *) key;
{
	return NO;
}

+ (void) setKeys:(NSArray *) keys triggerChangeNotificationsForDependentKey:(NSString *) dependentKey;
{
	return;
}

- (void) addObserver:(id) obj
		  forKeyPath:(NSString *) str
			 options:(NSKeyValueObservingOptions) opts
			 context:(void *) context;
{
	return;
}

- (void) didChange:(NSKeyValueChange) change
   valuesAtIndexes:(NSIndexSet *) idx
			forKey:(NSString *) key;
{
	return;
}

- (void) didChangeValueForKey:(NSString *) key;
{
	NSLog(@"%@ didChangeValueForKey:%@", self, key);
	return;
}

- (void) didChangeValueForKey:(NSString *) key
			  withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				 usingObjects:(NSSet *) objects;
{
	return;
}

- (void *) observationInfo;
{
	return NULL;
}

- (void) observeValueForKeyPath:(NSString *) path
					   ofObject:(id) object
						 change:(NSDictionary *) dict
						context:(void *) context;
{
	return;
}

- (void) removeObserver:(id) obj forKeyPath:(NSString *) str;
{
	return;
}

- (void) setObservationInfo:(void *) observationInfo;
{
	return;
}

- (void) willChange:(NSKeyValueChange) change
	valuesAtIndexes:(NSIndexSet *) idx
			 forKey:(NSString *) key;
{
	return;
}

- (void) willChangeValueForKey:(NSString *) key;
{
	return;
}

- (void) willChangeValueForKey:(NSString *) key
			   withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				  usingObjects:(NSSet *) objects;
{
	return;
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
