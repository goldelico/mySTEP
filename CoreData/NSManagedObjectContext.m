/* Implementation of the NSManagedObjectContext class for the GNUstep
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

id NSErrorMergePolicy = nil,
   NSMergeByPropertyStoreTrumpMergePolicy = nil,
   NSMergeByPropertyObjectTrumpMergePolicy = nil,
   NSOverwriteMergePolicy = nil,
   NSRollbackMergePolicy = nil;


/**
 * Deregisters `observer' from all the managed objects in `objects'.
 * In more detail, this function traverses through all the objects
 * and all their properties and executes removeObserver:forKeyPath:
 * on every property name.
 */
static void
RemoveKVOSetupFromObjects(id observer, NSSet * objects)
{
  NSEnumerator * e = [objects objectEnumerator];
  NSManagedObject * object;

  while ((object = [e nextObject]) != nil)
    {
      NSEntityDescription * entity;

      // traverse the entity hierarchy correctly.
      for (entity = [object entity];
           entity != nil;
           entity = [entity superentity])
        {
          NSEnumerator * propertyEnum = [[entity properties]
            objectEnumerator];
          NSPropertyDescription * property;

          while ((property = [propertyEnum nextObject]) != nil)
            {
              [object removeObserver: observer
                          forKeyPath: [property name]];
            }
        }
    }
}

@interface GSMergePolicy : NSObject
@end

@implementation GSMergePolicy
@end

@interface NSManagedObjectContext (GSCoreDataInternal)

/**
 * Sets up the properties of `object' according to the fetched
 * representation of them in `propertyValues' (see
 * Documentation/GSPersistentStore.txt on details on how this
 * dictionary is structured). The `mergeChanges' argument behaves
 * like the same name argument described in -[NSManagedObjectContext
 * refreshObject:mergeChanges:].
 */
- (void) _setFetchedPropertyValues: (NSDictionary *) propertyValues
                          ofObject: (NSManagedObject *) object
                      mergeChanges: (BOOL) mergeChanges;

/**
 * Sets the relationship described by `relationship' in `object'
 * to `value'. What's important to note is that `value' isn't the
 * actual destination object or a collection of destination objects,
 * but is instead the representation fetched from the persistent store
 * i.e. the destination object's ID or a collection of IDs.
 */
- (void) _setRelationship: (NSRelationshipDescription *) relationship
             fetchedValue: (id) value
                 ofObject: (NSManagedObject *) object;

/**
 * Registers the provided objects with the receiver, manipulating
 * their retain count to correctly fit our retaining behavior set
 * by -setRetainsRegisteredObjects:.
 */
- (void) _registerObjects: (NSSet *) objects;

/**
 * Equivalent to -_registerObjects:, but operates on only one object.
 */
- (void) _registerObject: (NSManagedObject *) object;

/**
 * Unregisters the provided objects with the receiver, manipulating
 * their retain count to correctly fit our retaining behavior set
 * by -setRetainsRegisteredObjects:.
 */
- (void) _unregisterObjects: (NSSet *) objects;

/**
 * Equivalent to -_unregisterObjects:, but operates on only one object.
 */
- (void) _unregisterObject: (NSManagedObject *) object;

@end

/*
 * Implementation note:
 * Has anybody got any idea on why this class is supposed to conform to
 * NSCoding? Even if you've got one, then how to archive it when all of
 * it's instance variables don't support coding? Did somebody in Apple
 * sleep when designing this?
 */
@implementation NSManagedObjectContext

+ (void) initialize
{
  if (NSErrorMergePolicy == nil)
    {
/*
      NSErrorMergePolicy = [GSErrorMergePolicy new];
      NSMergeByPropertyStoreTrumpMergePolicy =
        [GSMergeByPropertyStoreTrumpMergePolicy new];
      NSMergeByPropertyObjectTrumpMergePolicy =
        [GSMergeByPropertyObjectTrumpMergePolicy new];
      NSRollbackMergePolicy = [GSRollbackMergePolicy new];
      NSOverwriteMergePolicy = [GSOverwriteMergePolicy new];
*/
    }
}

- (void) dealloc
{
  TEST_RELEASE(_lock);
  TEST_RELEASE(_storeCoordinator);

  TEST_RELEASE(_registeredObjects);
  TEST_RELEASE(_insertedObjects);
  TEST_RELEASE(_updatedObjects);
  TEST_RELEASE(_deletedObjects);

  TEST_RELEASE(_undoManager);
  TEST_RELEASE(_mergePolicy);

  [super dealloc];
}

- (id) init
{
	if ((self = [super init]))
    {
      _lock = [NSRecursiveLock new];
      _undoManager = [NSUndoManager new];

      _registeredObjects = [NSMutableSet new];
      _insertedObjects = [NSMutableSet new];
      _updatedObjects = [NSMutableSet new];
      _deletedObjects = [NSMutableSet new];
      ASSIGN(_mergePolicy, NSErrorMergePolicy);

    }
	return self;
}

/**
 * Returns the persistent store coordinator associated with the receiver.
 */
- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
  return _storeCoordinator;
}

/**
 * Sets the persistent store coordinator of the receiver. A managed
 * object context isn't fully functional until it is connected to
 * a persistent store coordinator.
 *
 * @param coordinator The persistent store coordinator to use.
 */
- (void) setPersistentStoreCoordinator: (NSPersistentStoreCoordinator *)
  coordinator
{
  ASSIGN(_storeCoordinator, coordinator);
}

/**
 * Returns the current undo manager of the receiver.
 */
- (NSUndoManager *) undoManager
{
  return _undoManager;
}

/**
 * Sets a new undo manager in the receiver.
 *
 * @param aManager The undo manager to use.
 */
- (void) setUndoManager: (NSUndoManager *) aManager
{
  ASSIGN(_undoManager, aManager);
}

/**
 * Sends `-undo' to the receiver's undo manager.
 */
- (void) undo
{
  [_undoManager undo];
}

/**
 * Sends `-redo' to the receiver's undo manager.
 */
- (void) redo
{
  [_undoManager redo];
}

// TODO
- (void) rollback
{
  NSEnumerator * e;
  NSManagedObject * object;

  // clear all actions from the undo manager
  [_undoManager removeAllActions];

  // remove any inserted or deleted objects
  RemoveKVOSetupFromObjects(self, _insertedObjects);
  [_insertedObjects removeAllObjects];
  RemoveKVOSetupFromObjects(self, _deletedObjects);
  [_deletedObjects removeAllObjects];

  // and restore the state of all objects to their commited values
  e = [_registeredObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      if ([object isFault] == NO)
        {
          NSDictionary * commitedValues = [object commitedValuesForKeys: nil];
          NSEnumerator * commitedValuesEnumerator = [[commitedValues allKeys]
            objectEnumerator];
          NSString * key;

          while ((key = [commitedValuesEnumerator nextObject]) != nil)
            {
              [object setPrimitiveValue: [commitedValues objectForKey: key]
                                 forKey: key];
            }
        }
    }
}

/**
 * Resets the receiver. This in particular means:
 *
 * - all objects registered with the receiver are unregistered and released.
 *
 * - all actions recorded in the undo manager are removed.
 */
- (void) reset
{
  /* From what I (Saso) understood, this method works as a shorthand.
   * To achieve the same effect, we could just as well recreate the
   * context anew and replace the old one, but this way we won't have
   * to swap them and aby additional settings (e.g. merge policy,
   * staleness interval, persistent store coordinator) will remain
   * untouched. */

  // remove all objects
  [self _unregisterObjects: _registeredObjects];

  [_insertedObjects removeAllObjects];
  [_updatedObjects removeAllObjects];
  [_deletedObjects removeAllObjects];

  // reset the undo manager
  [_undoManager removeAllActions];
}

/**
 * Saves all changed objects in the receiver to the persistent store.
 *
 * The save is carried out by first consulting the receiver's
 * merge policy to resolve potential conflicts between the version of
 * the objects in the receiver and the versions in the persistent store.
 *
 * @param errorPtr A pointer to a location which will be set to point to
 *  an error object in case an error arises during saving.
 *
 * @return YES in case saving succeeds, NO if the operation fails.
 */
- (BOOL) save: (NSError **) errorPtr
{
  /*
   * FIXME: why does Apple spec say that this method should abort
   * immediately in case of an error only when NULL is specified as
   * the `error' argument? (If non-NULL is passed, it should continue
   * and aggregate further errors inside the error object.) Should
   * a potentially destructive operation (and saving *is* a destructive
   * operation - it permanently overwrites data) not be aborted as soon
   * as a problem is detected? It is no problem extending this method
   * to just continue in case of an error and then return all errors as
   * an aggregate error, but that's very likely not something we want.
   */

  NSEnumerator * e;
  NSManagedObject * object;
  NSMutableSet * objectsToSave;
  NSError * error = nil;

  if (_storeCoordinator == nil)
    {
      [NSException raise: NSInternalInconsistencyException
                  format:
        _(@"-[NSManagedObjectContext save:]: Cannot save a managed "
          @"object context which isn't connected to a persistent store "
          @"coordinator.")];
    }

  // assign unassigned objects to a persistent store
  e = [_insertedObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      if ([[object objectID] isTemporaryID])
        {
          GSPersistentStore * store = [_storeCoordinator
            persistentStoreContainingEntity: [object entity]];

          if (store != nil)
            {
              [self assignObject: object toPersistentStore: store];
            }
          else
            // no store contains the specified entity - cannot save object
            {
              NSDictionary * userInfo = [NSDictionary
                dictionaryWithObject: object
                              forKey: NSAffectedObjectsErrorKey];
              SetNonNullError(errorPtr, [NSError
                    errorWithDomain: NSCoreDataErrorDomain
                               code: NSPersistentStoreIncompatibleSchemaError
                           userInfo: userInfo]);

              return NO;
            }
        }
    }

  // first, put in all changed objects
  objectsToSave = [[_updatedObjects mutableCopy] autorelease];

  // then all objects which have newly been inserted (which may be
  // a subset of the previous ones)
  [objectsToSave unionSet: _insertedObjects];

  // remove any objects from the list which are scheduled for deletion
  [objectsToSave minusSet: _deletedObjects];

  // first delete the objects scheduled for deletion
  e = [_deletedObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      [_storeCoordinator deleteObjectWithID: [object objectID]];
    }

  // and finally merge the objects to be saved with the persistent
  // store coordinator
  e = [objectsToSave objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      if (![_mergePolicy mergeObject: object
                withStoreCoordinator: _storeCoordinator
                               error: &error])
        {
          SetNonNullError(errorPtr, error);

          return NO;
        }
    }

  if (![_storeCoordinator commitChangesError: &error])
    {
      SetNonNullError(errorPtr, error);

      return NO;
    }

  // sync our internal state sets
  [self _unregisterObjects: _deletedObjects];

  [_insertedObjects removeAllObjects];
  [_updatedObjects removeAllObjects];
  [_deletedObjects removeAllObjects];

  return YES;
}

/**
 * Queries whether the receiver has some unsaved changes. Changes are
 * objects being changed, inserted or removed.
 *
 * @return YES if the receiver does have unsaved changes, NO otherwise.
 */
- (BOOL) hasChanges
{
  return ([_updatedObjects count] > 0) ||
         ([_insertedObjects count] > 0) ||
         ([_deletedObjects count] > 0);
}

/**
 * Returns the object registered in the receiver with object ID `objectID',
 * or `nil' if an object of the specified ID isn't registered in the
 * receiver.
 */
- (NSManagedObject *) objectRegisteredForID: (NSManagedObjectID *) objectID
{
  NSEnumerator * e;
  NSManagedObject * object;

  e = [_registeredObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      if ([[object objectID] _isEqualToManagedObjectID: objectID] == YES)
        {
          return object;
        }
    }

  return nil;
}

/**
 * Attempts to locate an object registered in the receiver with
 * an object ID of `objectID'. If the object exists, it is returned.
 * If it doesn't, it is created as a fault and returned. The object
 * is assumed to exist in the associated persistent store. If it
 * doesn't, the time the fault is fired, an
 * NSInternalInconsistencyException is raised.
 */
- (NSManagedObject *) objectWithID: (NSManagedObjectID *) objectID
{
  NSManagedObject * object;

  object = [self objectRegisteredForID: objectID];

  // create the object as a fault if necessary
  if (object == nil)
    {
      NSManagedObject * object;

      object = [[[NSManagedObject alloc]
        _initAsFaultWithObjectID: objectID ownedByContext: self]
        autorelease];
      [self _registerObject: object];
    }

  return object;
}

/**
 * Retrieves all objects from the receiver and it's associated stores which
 * match the provided fetch request. N.B. objects are first looked for in
 * the receiver and only after that will the stores be consulted. That
 * means that any objects which were already brought into memory, even
 * those that have changed since then or have been altered in the persistent
 * store by another context, will be retrieved before any object from a
 * persistent store. Please also keep in mind the fact that the staleness
 * interval is again consulted by the store coordinator upon issuing a new
 * fetch to determine whether it can use cached data or has whether it has
 * to make a full round-trip to the persistent store(s).
 *
 * @param request The fetch request which to execute.
 * @param error A pointer to an error object where errors during fetching
 *  of objects will be aggreggated.
 *
 * @return An array of objects which matched the fetch request's criteria.
 *  If no objects matched, an empty array is returned. In case of an error,
 *  `nil' is returned and the `error' argument is filled with a description
 *  of the error which occured.
 */
- (NSArray *) executeFetchRequest: (NSFetchRequest *) request
                            error: (NSError **) error
{
  NSEntityDescription * entity = [request entity];
  NSPredicate * predicate = [request predicate];

  NSMutableArray * fetchedObjects;
  NSEnumerator * e;
  NSManagedObject * object;

  NSMutableSet * fetchedObjectsIDs;
  NSArray * storedObjects;

  fetchedObjects = [NSMutableArray array];

  // fetch all matching objects from the context first
  e = [_registeredObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      // ignore deleted objects
      if (ObjectMatchedByFetchRequest(object, request) &&
          [_deletedObjects containsObject: object] == NO)
        {
          [fetchedObjects addObject: object];
        }
    }

  // record the object IDs of already present objects
  fetchedObjectsIDs = [NSMutableSet setWithCapacity: [fetchedObjects
    count]];
  e = [fetchedObjects objectEnumerator];
  while ((object = [e nextObject]) != nil)
    {
      [fetchedObjectsIDs addObject: [object objectID]];
    }

  // and tell the store to execute the fetch request, ignoring
  // already fetched object IDs
  storedObjects = [_storeCoordinator _executeFetchRequest: request
                                                ignoreIDs: fetchedObjectsIDs
                                        stalenessInterval: _stalenessInterval
                                                    error: error];
  if (storedObjects != nil)
    {
      [fetchedObjects addObjectsFromArray: storedObjects];
    }
  // store error
  else
    {
      return nil;
    }

  // now, apply any sorting descriptors
  [fetchedObjects sortUsingDescriptors: [request sortDescriptors]];

  return [[fetchedObjects copy] autorelease];
}

/**
 * Inserts the `object' into the receiver. The next time the receiver
 * is saved it will be written into the persistent store. Upon inserting
 * the object, an NSManagedObjectContextObjectsDidChangeNotification
 * is posted to the default notification center with the
 * NSInsertedObjectsKey bound to a set containing the inserted object
 * in the user info dictionary.
 */
- (void) insertObject: (NSManagedObject *) object
{
  NSDictionary * userInfo;

  // re-inserting a deleted object brings it in again
  if ([_deletedObjects containsObject: object] == YES)
    {
      [_deletedObjects removeObject: object];
    }
  // otherwise if it isn't registered yet schedule it for addition
  else if ([_registeredObjects containsObject: object] == NO)
    {
      [self _registerObject: object];

      [_insertedObjects addObject: object];
    }
  else
    {
      return;
    }

  [object _insertedIntoContext: self];
  [object _setDeleted: NO];

  [_undoManager registerUndoWithTarget: self
                              selector: @selector(deleteObject:)
                                object: object];

  userInfo = [NSDictionary dictionaryWithObject: [NSSet setWithObject: object]
                                         forKey: NSInsertedObjectsKey];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: NSManagedObjectContextObjectsDidChangeNotification
                  object: self
                userInfo: userInfo];
}

/**
 * Schedules the `object' for deletion from the persistent store of the
 * receiver. The next time the receiver is saved, the object will be
 * permanently removed from the persistent store.
 */
- (void) deleteObject: (NSManagedObject *) object
{
  if ([_registeredObjects containsObject: object] == YES)
    {
      NSDictionary * userInfo;

      // we must do this first to make sure that removing the object
      // from our internal tables doesn't deallocate it
      [_undoManager registerUndoWithTarget: self
                                  selector: @selector(insertObject:)
                                    object: object];

      // an unsaved object is removed immediately
      if ([_insertedObjects containsObject: object])
        {
          [self _unregisterObject: object];
          [_insertedObjects removeObject: object];
        }
      // otherwise it is scheduled for deletion
      else
        {
          [_deletedObjects addObject: object];
        }

      userInfo = [NSDictionary
        dictionaryWithObject: [NSSet setWithObject: object]
                      forKey: NSDeletedObjectsKey];
      [[NSNotificationCenter defaultCenter]
        postNotificationName: NSManagedObjectContextObjectsDidChangeNotification
                      object: self
                    userInfo: userInfo];
    }
}

/**
 * Assigns an newly inserted object to be stored in a particular
 * persistent store.
 *
 * @param anObject The object to be assigned to the persitent store.
 * It must be an NSManagedObject which has been newly inserted into
 * the receiver - reassigning already saved objects isn't possible.
 *
 * @param aPersistentStore The persistent store to which to assign
 * the object. It must be a persistent store from the persistent
 * stores of the persistent store coordinator associated with the
 * receiver, otherwise an NSInvalidArgumentException is raised.
 */
- (void) assignObject: (id) anObject toPersistentStore: (id) aPersistentStore
{
  // Why doesn't this method declare that `obj' must be a managed object??
  NSManagedObject * object = anObject;
  GSPersistentStore * store = aPersistentStore;
  NSManagedObjectID * oldObjectID, * newObjectID;

  if (![object isKindOfClass: [NSManagedObject class]])
    {
      [NSException raise: NSInvalidArgumentException
                  format:
        _(@"-[NSManagedObjectContext assignObject:toPersistentStore:]: "
          @"Non-managed-object passed.")];
    }

  if (_storeCoordinator == nil)
    {
      [NSException raise: NSInternalInconsistencyException
                  format:
        _(@"-[NSManagedObjectContext assignObject:toPersistentStore:]: "
          @"Cannot assign an object to a store in a context that isn't "
          @"connected to a persistent store coordinator.")];
    }

  if (![[_storeCoordinator persistentStores] containsObject: store])
    {
      [NSException raise: NSInvalidArgumentException
                  format:
        _(@"-[NSManagedObjectContext assignObject:toPersistentStore:]: "
          @"Cannot assign an object to a store which isn't in the "
          @"persistent store with which the context in which the object "
          @"lives is associated.")];
    }

  /*
   * NB. We don't check whether the object has a temporary or a permanent
   * object ID, only whether it has already been commited to a persistent
   * store. Thus a newly inserted object can be reassigned several times
   * to different persistent stores before it is actually saved. The save
   * will commit it to the latest of the specified stores. After that,
   * however, one cannot change it's location anymore.
   */
  if ([_insertedObjects containsObject: object] == NO)
    {
      [NSException raise: NSInvalidArgumentException
                  format:
        _(@"-[NSManagedObjectContext assignObject:toPersistentStore:]: "
          @"Cannot assign an object to a persistent store which hasn't "
          @"been inserted.")];
    }

  oldObjectID = [object objectID];

  // construct a new object ID in which we will explicitly denote the
  // persistent store to which the object belongs
  newObjectID = [[[NSManagedObjectID alloc]
    _initWithEntity: [oldObjectID entity]
    persistentStore: store
              value: [store nextFreeIDValue]]
    autorelease];

  [object _setObjectID: newObjectID];
}

/**
 * Refreshes an object's persistent properties with data from the
 * persistent store, possibly overwriting changed values. In case
 * the object's data don't exist in the persistent store, an
 * NSInvalidArgumentException is raised. In case the persistent store
 * coordinator has cached data for this object (and the staleness)
 * interval hasn't been exceeded, no new fetch will be issued.
 *
 * @param object The object to be refreshed.
 *
 * @param mergeChanges If this argument is YES, then after all persistent
 * properties of the object have been sync'ed with the values in the
 * persistent store, any previously changed values of the object are
 * re-applied over the refreshed object. Also, any transient properties
 * are left untouched. If this argument is NO, then any changes made 
 * to the object aren't re-applied and transient properties are released.
 */
- (void) refreshObject: (NSManagedObject *) object
          mergeChanges: (BOOL) mergeChanges
{
  NSManagedObjectID * objectID = [object objectID];
  NSDictionary * propertyValues;

  propertyValues = [_storeCoordinator fetchObjectWithID: [object objectID]
                                        fetchProperties: nil
                                 cacheStalenessInterval: _stalenessInterval];

  if (propertyValues == nil)
    {
      [NSException raise: NSInvalidArgumentException
                  format:
        _(@"-[NSManagedObjectContext refreshObject:mergeChanges:]: "
          @"Cannot refresh object - data for object doesn't exist in "
          @"the persistent store.")];
    }

  [self _setFetchedPropertyValues: propertyValues
                         ofObject: object
                     mergeChanges: mergeChanges];
}

/**
 * Returns a set of object which will be inserted into the persistent store
 * at the next save operation.
 */
- (NSSet *) insertedObjects
{
  return [[_insertedObjects copy] autorelease];
}

/**
 * Returns a set of object which have changed since the last successful
 * save operation.
 */
- (NSSet *) updatedObjects
{
  return [[_updatedObjects copy] autorelease];
}

/**
 * Returns a set of object which will be removed from the persistent store
 * at the next save operation.
 */
- (NSSet *) deletedObjects
{
  return [[_deletedObjects copy] autorelease];
}

/**
 * Returns a set containing all objects registered with the receiver.
 */
- (NSSet *) registeredObjects
{
  return [[_registeredObjects copy] autorelease];
}

/**
 * Attempts to lock the receiver, blocking if the lock is already taken.
 *
 * @see [NSManagedObjectContext unlock]
 * @see [NSManagedOBjectContext tryLock]
 */
- (void) lock
{
  [_lock lock];
}

/**
 * Unlocks the receiver.
 *
 * @see [NSManagedObjectContext lock]
 * @see [NSManagedOBjectContext tryLock]
 */
- (void) unlock
{
  [_lock unlock];
}

/**
 * Attempts to acquire the lock, but never blocks, even if the lock is
 * already taken.
 *
 * @return YES if the lock succeeds and NO if the lock is already taken
 * and locking it fails.
 *
 * @see [NSManagedObjectContext lock]
 * @see [NSManagedOBjectContext unlock]
 */
- (BOOL) tryLock
{
  return [_lock tryLock];
}

/**
 * Returns whether the receiver retains objects which are registered with it.
 *
 * @return YES if the receiver retains registered objects, NO otherwise.
 *
 * By default a managed object context <em>does not</em> retain it's
 * registered objects.
 */
- (BOOL) retainsRegisteredObjects
{
  return _retainsRegisteredObjects;
}

/**
 * Sets whether the receiver retains objects which are registered with it
 * or not. By default, a managed object context <em>does not</em> retain
 * it's registered objects.
 *
 * Object's scheduled for addition, deletion or have changed are always
 * retained.
 */
- (void) setRetainsRegisteredObjects: (BOOL) flag
{
  if (_retainsRegisteredObjects != flag)
    {
      _retainsRegisteredObjects = flag;

      // retain them
      if (_retainsRegisteredObjects == YES)
        {
          [_registeredObjects makeObjectsPerformSelector: @selector(retain)];
        }
      // release them
      else
        {
          [_registeredObjects makeObjectsPerformSelector: @selector(release)];
        }
    }
}

/**
 * Returns the staleness interval of the receiver.
 *
 * @see [NSManagedObjectContext setStalenessInterval:]
 */
- (NSTimeInterval) stalenessInterval
{
  return _stalenessInterval;
}

/**
 * Sets the staleness interval of the receiver. The staleness interval
 * determines when fetches are being done whether any cached data is
 * reused or a new fetch is issued.
 *
 * @param timeInterval The new staleness interval. Passing zero means
 * infinite staleness interval.
 */
- (void) setStalenessInterval: (NSTimeInterval) timeInterval
{
  _stalenessInterval = timeInterval;
}

/**
 * Returns the merge policy of the receiver.
 *
 * @see [NSManagedObjectContext setMergePolicy:]
 */
- (id) mergePolicy
{
  return _mergePolicy;
}

/**
 * Sets the merge policy of the receiver. The merge policy defines how
 * conflicts during save operations are handled. The default policy of
 * newly created managed object contexts is NSErrorMergePolicy.
 *
 * @param policy Identifies the merge policy to use. The value must be
 * one of:
 *
 * - NSErrorMergePolicy
 * - NSMergeByPropertyStoreTrumpMergePolicy
 * - NSMergeByPropertyObjectTrumpMergePolicy
 * - NSOverwriteMergePolicy
 * - NSRollbackMergePolicy
 *.
 * As an extension, GNUstep Core Data allows you to pass even your custom
 * subclass of GSMergePolicy, since all merge policies are implemented
 * as subclasses of it.
 */
- (void) setMergePolicy: (id) policy
{
  if (![policy isKindOfClass: [GSMergePolicy class]])
    {
      [NSException raise: NSInvalidArgumentException
                  format: _(@"-[NSManagedObjectContext setMergePolicy:]: "
                            @"Invalid merge policy (%@) specified."), policy];
    }

  ASSIGN(_mergePolicy, policy);
}

@end

/**
 * Private methods of GNUstep Core Data for NSManagedObjectContext.
 * Do <em>NOT</em> invoke these from external code!
 */
@implementation NSManagedObjectContext (GSCoreDataPrivate)

/**
 * Invoked by a managed object registered with the receiver when an
 * attribute or to-one relationship changes. This method records the
 * change with the receiver's undo manager.
 *
 * @param object The object in which the change occured.
 * @param key The key of which the value changed.
 * @param oldValue The old value of the key.
 * @param newValue The new value of the key.
 */
- (void)          _object: (NSManagedObject *) object
 changedValueForSingleKey: (NSString *) key
                 oldValue: (id) oldValue
                 newValue: (id) newValue
{
  [[_undoManager prepareWithInvocationTarget: object]
    setValue: oldValue forKey: key];
}

/**
 * Invoked by a managed object registered with the receiver when an
 * a to-many relationship changes. This method records the change
 * with the receiver's undo manager.
 *
 * @param object The object in which the change occured.
 * @param key The key of which the value changed.
 * @param oldValue The old contents of the to-many relationship as a set.
 * @param mutationKind The kind of change on the to-many relationship.
 * @param objects The objects with which the change has been performed.
 */
- (void)         _object: (NSManagedObject *) object
 changedValueForMultiKey: (NSString *) key
                oldValue: (NSSet *) oldValue
             setMutation: (NSKeyValueSetMutationKind) mutationKind
            usingObjects: (NSSet *) objects
{
  NSMutableSet * newValue = [object mutableSetValueForKey: key];

  id um = [_undoManager prepareWithInvocationTarget: newValue];

  switch (mutationKind)
	  {
	  case NSKeyValueUnionSetMutation:
		  {
			  // FIXED by hns to make it compile - but not checked!!!
			  NSMutableSet *ms = [[objects mutableCopy] autorelease];
			  [ms minusSet: oldValue];
			  [um minusSet: ms];
			  break;
		  }
	  case NSKeyValueMinusSetMutation:
		  {
			  // FIXED by hns to make it compile - but not checked!!!
			  NSMutableSet *ms = [[objects mutableCopy] autorelease];
			  [ms intersectSet: oldValue];
			  [um unionSet: ms];
			  break;
		  }
	  case NSKeyValueIntersectSetMutation:
		  [um unionSet: oldValue];
		  break;
	  case NSKeyValueSetSetMutation:
		  [um setSet: oldValue];
		  break;
	  }
}

@end

/**
 * Internal methods methods of GNUstep Core Data for NSManagedObjectContext.
 * Do <em>NOT</em> invoke these from external code!
 */
@implementation NSManagedObjectContext (GSCoreDataInternal)

- (void) _setFetchedPropertyValues: (NSDictionary *) newPropertyValues
                          ofObject: (NSManagedObject *) object
                      mergeChanges: (BOOL) mergeChanges
{
  Class relationshipClass = [NSRelationshipDescription class];
  NSEntityDescription * entity;
  NSDictionary * changedValues;
  NSEnumerator * e;
  NSString * key;

  if (mergeChanges == YES)
    {
      changedValues = [object changedValues];
    }

  // process all properties, traversing the entity inheritance hierarchy
  for (entity = [object entity]; entity != nil; entity = [entity superentity])
    {
      NSEnumerator * e = [[entity properties] objectEnumerator];
      NSPropertyDescription * property;

      while ((property = [e nextObject]) != nil)
        {
          NSString * key = [property name];
          id newValue = [newPropertyValues objectForKey: key];

          if ([property isTransient])
            {
              if (mergeChanges == NO)
                {
                  // flush transient values if merging isn't requested
                  [object setValue: nil forKey: key];
                }
            }
          else
            {
              if (newValue == nil)
                {
                  [object setValue: nil forKey: key];
                }
              else if ([property isKindOfClass: relationshipClass])
                {
                  [self _setRelationship: (NSRelationshipDescription*) property
                            fetchedValue: newValue
                                ofObject: object];
                }
              else
                {
                  [object setValue: newValue forKey: key];
                }
            }
        }
    }

  [object _flushChangedValues];

  if (mergeChanges == YES)
    {
      // now set back all properties which have changed
      e = [[changedValues allKeys] objectEnumerator];
      while ((key = [e nextObject]) != nil)
        {
          [object setValue: [changedValues objectForKey: key] forKey: key];
        }
    }
}

- (void) _setRelationship: (NSRelationshipDescription *) relationship
             fetchedValue: (id) value
                 ofObject: (NSManagedObject *) object
{
  NSString * key = [relationship name];
  NSManagedObjectID * destinationID;
  NSManagedObject * destinationObject;

  // If a relationship is a to-many relationship, the value will be a
  // collection containing a set of managed object IDs of the destination
  // objects. Extract them, get the objects and set them as the value
  // of the key.
  if ([relationship isToMany])
    {
      NSMutableSet * newRelationshipValue;
      NSEnumerator * e;

      NSAssert1([value isKindOfClass: [NSSet class]] ||
                [value isKindOfClass: [NSArray class]],
        _(@"Encountered non-collection value (%@) from store when setting "
          @"a to-many relationship."), value);

      newRelationshipValue = [NSMutableSet setWithCapacity: [value count]];

      e = [value objectEnumerator];
      while ((destinationID = [e nextObject]) != nil)
        {
          destinationObject = [self objectWithID: destinationID];
          [newRelationshipValue addObject: destinationObject];
        }

      [object setValue: newRelationshipValue forKey: key];
    }
  // Otherwise the value is a single managed object ID the destination
  // object. Get the object and set it.
  else
    {
      NSAssert1([value isKindOfClass: [NSManagedObjectID class]],
        _(@"Encountered non-object-ID value (%@) from store when setting "
          @"a relationship."), value);

      destinationID = value;
      destinationObject = [self objectWithID: destinationID];

      [object setValue: destinationObject forKey: key];
    }
}

- (void) _registerObjects: (NSSet *) objects
{
  if (_retainsRegisteredObjects == NO)
    {
      NSMutableSet * tmp;

      tmp = [[objects mutableCopy] autorelease];

      // cut out only the objects which aren't registered yet
      [tmp minusSet: _registeredObjects];

      // first put them in the set, then release
      [_registeredObjects unionSet: objects];
      [tmp makeObjectsPerformSelector: @selector(release)];
    }
  else
    {
      [_registeredObjects unionSet: objects];
    }
}

- (void) _registerObject: (NSManagedObject *) object
{
  if (_retainsRegisteredObjects == NO)
    {
      // we need to check whether it's already registered to not
      // confuse the retain/release machinery by releasing it more
      // times
      if ([_registeredObjects containsObject: object] == NO)
        {
          [_registeredObjects addObject: object];
          [object release];
        }
    }
  else
    {
      [_registeredObjects addObject: object];
    }
}

- (void) _unregisterObjects: (NSSet *) objects
{
  if (_retainsRegisteredObjects == NO)
    {
      NSMutableSet * tmp;

      tmp = [[objects mutableCopy] autorelease];
      // cut out only registered objects
      [tmp intersectSet: _registeredObjects];

      // first retain, then remove from set
      [tmp makeObjectsPerformSelector: @selector(retain)];
      [_registeredObjects minusSet: tmp];
    }
  else
    {
      [_registeredObjects unionSet: objects];
    }
}

- (void) _unregisterObject: (NSManagedObject *) object
{
  if (_retainsRegisteredObjects)
    {
      if ([_registeredObjects containsObject: object] == YES)
        {
          // first retain, then remove from set
          [object retain];
          [_registeredObjects removeObject: object];
        }
    }
  else
    {
      [_registeredObjects removeObject: object];
    }
}

@end

NSString * const NSManagedObjectContextObjectsDidChangeNotification =
  @"NSManagedObjectContextObjectsDidChangeNotification";
NSString * const NSManagedObjectContextDidSaveNotification =
  @"NSManagedObjectContextDidSaveNotification";

NSString * const NSInsertedObjectsKey = @"NSInsertedObjectsKey";
NSString * const NSUpdatedObjectsKey = @"NSUpdatedObjectsKey";
NSString * const NSDeletedObjectsKey = @"NSDeletedObjectsKey";
