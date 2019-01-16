/* Interface of the NSManagedObjectContext class for the GNUstep
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

#ifndef _NSManagedObjectContext_h_
#define _NSManagedObjectContext_h_

#import <Foundation/NSObject.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSDate.h>

@class NSArray, NSString, NSError, NSSet, NSMutableSet;
@class NSUndoManager;
@class NSFetchRequest, NSManagedObject, NSManagedObjectID,
  NSPersistentStoreCoordinator;

extern id NSErrorMergePolicy;
extern id NSMergeByPropertyStoreTrumpMergePolicy;
extern id NSMergeByPropertyObjectTrumpMergePolicy;
extern id NSOverwriteMergePolicy;
extern id NSRollbackMergePolicy;

@interface NSManagedObjectContext : NSObject <NSCoding, NSLocking>
{
  NSRecursiveLock * _lock;

  NSPersistentStoreCoordinator * _storeCoordinator;

  // objects that are registered with the context
  NSMutableSet * _registeredObjects;

  // objects inserted into the context since the last save
  NSMutableSet * _insertedObjects;
  // objects updated since the last save
  NSMutableSet * _updatedObjects;
  // objects deleted since the last save
  NSMutableSet * _deletedObjects;

  BOOL _propagesDeletesAtEventEnd;
  BOOL _retainsRegisteredObjects;

  NSUndoManager * _undoManager;
  id _mergePolicy;

  NSTimeInterval _stalenessInterval;
}

// Getting and setting the persistent store coordinator.
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator;
- (void) setPersistentStoreCoordinator:
  (NSPersistentStoreCoordinator *) aCoordinator;

// Undo/redo control.
- (NSUndoManager *) undoManager;
- (void) setUndoManager: (NSUndoManager *) aManager;
- (void) undo;
- (void) redo;
- (void) reset;
- (void) rollback;
- (BOOL) save: (NSError **) anErrorPointer;
- (BOOL) hasChanges;

// Registering and fetching objects.
- (NSManagedObject *) objectRegisteredForID: (NSManagedObjectID *) anObjectID;
- (NSManagedObject *) objectWithID: (NSManagedObjectID *) anObjectID;
- (NSArray *) executeFetchRequest: (NSFetchRequest *) aRequest
                            error: (NSError **) anErrorPointer;

// Managed object management.
- (void) insertObject: (NSManagedObject *) anObject;
- (void) deleteObject: (NSManagedObject *) anObject;
- (void) assignObject: (id) anObject toPersistentStore: (id) aStore;
- (void) detectConflictsForObject: (NSManagedObject *) anObject;
- (void) refreshObject: (NSManagedObject *) anObject
          mergeChanges: (BOOL) mergeChanges;
- (void) processPendingChanges;
- (NSSet *) insertedObjects;
- (NSSet *) updatedObjects;
- (NSSet *) deletedObjects;
- (NSSet *) registeredObjects;

// Locking (NSLocking protocol).
- (void) lock;
- (void) unlock;
- (BOOL) tryLock;

// Controlling delete propagation.
- (BOOL) propagatesDeletesAtEndOfEvent;
- (void) setPropagatesDeletesAtEndOfEvent: (BOOL) flag;

// Controlling whether registered objects are retained.
- (BOOL) retainsRegisteredObjects;
- (void) setRetainsRegisteredObjects: (BOOL) flag;

// Controlling the staleness interval.
- (NSTimeInterval) stalenessInterval;
- (void) setStalenessInterval: (NSTimeInterval) aTimeInterval;

// Controlling the merge policy.
- (id) mergePolicy;
- (void) setMergePolicy: (id) aPolicy;

@end

// Notifications.
extern NSString * const NSManagedObjectContextObjectsDidChangeNotification;
extern NSString * const NSManagedObjectContextDidSaveNotification;

extern NSString * const NSInsertedObjectsKey;
extern NSString * const NSUpdatedObjectsKey;
extern NSString * const NSDeletedObjectsKey;

#endif // _NSManagedObjectContext_h_
