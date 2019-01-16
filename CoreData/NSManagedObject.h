/* Interface of the NSManagedObject class for the GNUstep
   Core Data framework.
   Copyright (C) 2005 Free Software Foundation, Inc.

   Written by:  Saso Kiselkov <diablos@manga.sk>
   Date: August 2005

   This file is part of the GNUstep Core Data framework.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef _NSManagedObject_h_
#define _NSManagedObject_h_

#import <Foundation/NSObject.h>
#import <Foundation/NSArray.h>  // temporary workaround for
                                 // NSKeyValueObserving.h include bug
#import <Foundation/NSKeyValueObserving.h>

@class NSString, NSMutableDictionary, NSDictionary, NSSet, NSError;
@class NSManagedObjectContext, NSEntityDescription, NSManagedObjectID;

@interface NSManagedObject : NSObject
{
  // weak reference
  NSManagedObjectContext * _context;

  NSEntityDescription * _entity;
  NSManagedObjectID * _objectID;
  BOOL _isUpdated,
       _isDeleted,
       _isFault;

  NSMutableDictionary * _changedValues;

  // the actual data payload of a managed object
  NSMutableDictionary * _data;
}

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) aKey;

// The designated initializer.
- (id)            initWithEntity: (NSEntityDescription *) anEntity
  insertIntoManagedObjectContext: (NSManagedObjectContext *) aContext;

// Determining the object's identity.
- (NSManagedObjectContext *) managedObjectContext;
- (NSEntityDescription *) entity;
- (NSManagedObjectID *) objectID;

// State information
- (BOOL) isInserted;
- (BOOL) isUpdated;
- (BOOL) isDeleted;
- (BOOL) isFault;

// Life cycle and change management
- (void) awakeFromFetch;
- (void) awakeFromInsert;
- (NSDictionary *) changedValues;
- (NSDictionary *) commitedValuesForKeys: (NSArray *) someKeys;
- (void) didSave;
- (void) willSave;
- (void) didTurnIntoFault;

// Key-value coding
- (id) valueForKey: (NSString *) aKey;
- (void) setValue: (id) aValue forKey: (NSString *) aKey;
- (id) primitiveValueForKey: (NSString *) aKey;
- (void) setPrimitiveValue: (id) aPrimitiveValue forKey: (NSString *) aKey;

// Validation
- (BOOL) validateValue: (id *) value
                forKey: (NSString *) aKey
                 error: (NSError **) anErrorPointer;
- (BOOL) validateForDelete: (NSError **) anErrorPointer;
- (BOOL) validateForInsert: (NSError **) anErrorPointer;
- (BOOL) validateForUpdate: (NSError **) anErrorPointer;

// Key-value observing
- (void) didAccessValueForKey: (NSString *) aKey;
- (void) didChangeValueForKey: (NSString *) aKey;
- (void) didChangeValueForKey: (NSString *) aKey
              withSetMutation: (NSKeyValueSetMutationKind) aMutationKind
                 usingObjects: (NSSet *) someObjects;
- (void *) observationInfo;
- (void) setObservationInfo: (void *) someInfo;
- (void) willAccessValueForKey: (NSString *) aKey;
- (void) willChangeValueForKey: (NSString *) aKey;
- (void) willChangeValueForKey: (NSString *) aKey
               withSetMutation: (NSKeyValueSetMutationKind) aMutationKind
                  usingObjects: (NSSet *) someObjects;

@end

#endif // _NSManagedObject_h_
