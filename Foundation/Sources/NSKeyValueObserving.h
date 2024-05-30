/*
    NSKeyValueObserving.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
    Copyright (c) 2004 DSITRI.

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
    Defines only methods that are not deprecated or announced to be deprecated
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSKEYVALUEObserving_H
#define mySTEP_NSKEYVALUEObserving_H

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>

@class NSDictionary;
@class NSSet;
@class NSIndexSet;
@class NSString;

enum
{
	NSKeyValueChangeSetting = 1,
	NSKeyValueChangeInsertion,
	NSKeyValueChangeRemoval,
	NSKeyValueChangeReplacement
};

typedef NSUInteger NSKeyValueChange;

enum
{ // bit mask
	NSKeyValueObservingOptionNew = 1 << 0,
	NSKeyValueObservingOptionOld = 1 << 1,
	NSKeyValueObservingOptionInitial = 1 << 2,
	NSKeyValueObservingOptionPrior = 1 << 3
};

typedef NSUInteger NSKeyValueObservingOptions;

enum
{
	NSKeyValueUnionSetMutation = 1,
	NSKeyValueMinusSetMutation,
	NSKeyValueIntersectSetMutation,
	NSKeyValueSetSetMutation
};

typedef NSUInteger NSKeyValueSetMutationKind;

extern NSString *NSKeyValueChangeKindKey;
extern NSString *NSKeyValueChangeNewKey;
extern NSString *NSKeyValueChangeOldKey;
extern NSString *NSKeyValueChangeIndexesKey;

@interface NSObject (NSKeyValueObserving)

// class NSMutableDictionary *_dependentKeys;
+ (BOOL) automaticallyNotifiesObserversForKey:(NSString *) key;
+ (void) setKeys:(NSArray *) keys triggerChangeNotificationsForDependentKey:(NSString *) dependentKey; // deprecated
+ (NSSet *) keyPathsForValuesAffectingValueForKey:(NSString *) key;

- (void) addObserver:(id) obj
		  forKeyPath:(NSString *) str
			 options:(NSKeyValueObservingOptions) opts
			 context:(void *) context;
- (void) didChange:(NSKeyValueChange) change
   valuesAtIndexes:(NSIndexSet *) idx
			forKey:(NSString *) key;
- (void) didChangeValueForKey:(NSString *) key;
- (void) didChangeValueForKey:(NSString *) key
			  withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				 usingObjects:(NSSet *) objects;
- (void *) observationInfo;
- (void) observeValueForKeyPath:(NSString *) path
					   ofObject:(id) object
						 change:(NSDictionary *) dict
						context:(void *) context;
- (void) removeObserver:(id) obj forKeyPath:(NSString *) str;
- (void) setObservationInfo:(void *) observationInfo;
- (void) willChange:(NSKeyValueChange) change
	valuesAtIndexes:(NSIndexSet *) idx
			 forKey:(NSString *) key;
- (void) willChangeValueForKey:(NSString *) key;
- (void) willChangeValueForKey:(NSString *) key
			   withSetMutation:(NSKeyValueSetMutationKind) mutationKind
				  usingObjects:(NSSet *) objects;

@end

@interface NSArray (NSKeyValueObserving)

- (void) addObserver:(NSObject *)anObserver
  toObjectsAtIndexes:(NSIndexSet *)indexes
		  forKeyPath:(NSString *)keyPath
			 options:(NSKeyValueObservingOptions)options
			 context:(void *)context;
- (void) removeObserver:(NSObject *)anObserver
   fromObjectsAtIndexes:(NSIndexSet *)indexes
			 forKeyPath:(NSString *)keyPath;

@end

#endif // mySTEP_NSKEYVALUEObserving_H
