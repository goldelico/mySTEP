/* Implementation of the NSManagedObjectID class for the GNUstep
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

#import "CoreDataHeaders.h"
#import "GSPersistentStore.h"

@interface NSManagedObjectID (GSCoreDataInternal)

+ (void) willBecomeMultiThreaded: (NSNotification *) notif;

@end

/**
 * For implementation notes see "Documentation/NSManagedObjectID.txt"
 * in the source distribution of the GNUstep Core Data framework.
 */
@implementation NSManagedObjectID

+ (void) initialize
{
  if (self == [NSManagedObjectID class])
    {
      [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(willBecomeMultiThreaded:)
               name: NSWillBecomeMultiThreadedNotification
             object: nil];
    }
}

- (void) dealloc
{
  TEST_RELEASE(_persistentStore);
  TEST_RELEASE(_entity);

  [super dealloc];
}

/**
 * Returns the receiver's entity (that is, the entity of the object
 * to which this managed object ID belongs).
 */
- (NSEntityDescription *) entity
{
  return _entity;
}

/**
 * Returns NO if the receiver is a permanent ID (that is, it has
 * been already saved to or fetched from a persistent store), and
 * YES otherwise.
 */
- (BOOL) isTemporaryID
{
  return (_persistentStore == nil);
}

/**
 * Returns the persistent store from which the receiver has been
 * fetched or to which it has been stored, and `nil' otherwise.
 */
- (id) persistentStore
{
  return _persistentStore;
}

/**
 * Returns an archivable URI representation of the receiver. URI
 * representations are only available for permanent managed object
 * IDs - temporary IDs simply return `nil'.
 */
- (NSURL *) URIRepresentation
{
  if (_persistentStore == nil)
    {
      return nil;
    }
  else
    {
      NSString * UUID = [[_persistentStore metadata]
        objectForKey: NSStoreUUIDKey];

      return [NSURL URLWithString: [NSString stringWithFormat:
        @"%@/%@/%llX", UUID, [_entity name], _value]];
    }
}

/**
 * Compares the receiver against another managed object ID.
 *
 * @arg otherID The object ID which to compare the receiver against.
 *
 * @return YES if the receiver is equal to the other object ID, NO otherwise.
 */
- (BOOL) _isEqualToManagedObjectID: (NSManagedObjectID *) otherID
{
  if ([_entity isEqual: [otherID entity]] == NO)
    {
      return NO;
    }

  if ([self isTemporaryID] != [otherID isTemporaryID])
    {
      return NO;
    }

  if (_persistentStore != [otherID persistentStore])
    {
      return NO;
    }

  return YES;
}

/**
 * Overridden method to make use of -isEqualToManagedObjectID: when possible.
 */
- (BOOL) isEqual: (id) otherObject
{
  if ([otherObject isKindOfClass: [NSManagedObjectID class]])
    {
      return [self isEqualToManagedObjectID: otherObject];
    }
  else
    {
      return NO;
    }
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  return [[NSManagedObjectID allocWithZone: zone]
    _initWithEntity: _entity
    persistentStore: _persistentStore
              value: _value];
}

@end

@implementation NSManagedObjectID (GSCoreDataPrivate)

/**
 * This is the pool from which new temporary object IDs are assigned
 * their value. After that this number is incremented so that new
 * IDs will be unique. Since it is a 64-bit integer we should never
 * actually run out of IDs.
 */
static unsigned long long nextTemporaryID = 0;

/**
 * A lock used to protect the unique ID number pool in multi-threaded apps.
 */
static NSRecursiveLock * lock = nil;

- (id) _initWithEntity: (NSEntityDescription *) entity
{
	if ((self = [super init]))
    {
      ASSIGN(_entity, entity);

      // make sure new temporary object IDs are generated uniquely
      if (lock != nil)
        {
          [lock lock];

          _value = nextTemporaryID;
          nextTemporaryID++;

          [lock unlock];
        }
      else
        {
          _value = nextTemporaryID;
          nextTemporaryID++;
        }
	}
      return self;
}

- (id) _initWithEntity: (NSEntityDescription *) entity
       persistentStore: (GSPersistentStore *) persistentStore
                 value: (unsigned long long) value
{
	if ((self = [super init]))
    {
      ASSIGN(_entity, entity);
      ASSIGN(_persistentStore, persistentStore);
      _value = value;

	}
	return self;
}

- (unsigned long long) _value
{
  return _value;
}

@end

@implementation NSManagedObjectID (GSCoreDataInternal)

/**
 * Method invoked when the app becomes multi-threaded. We create
 * a lock here in order to assure that unique IDs are generated
 * correctly in multi-threaded apps.
 */
+ (void) willBecomeMultiThreaded: (NSNotification *) notif
{
  lock = [NSRecursiveLock new];

  [[NSNotificationCenter defaultCenter] removeObserver: self];
}

@end
