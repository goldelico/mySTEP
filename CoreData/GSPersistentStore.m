/* Implementation of the GSPersistentStore class for the GNUstep
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

#include <stdlib.h>
#include <time.h>

#ifdef HAVE_NATIVE_OBJC_EXCEPTIONS
# define SUBCLASS_OVERRIDE_ERROR \
   @throw [NSException exceptionWithName: NSInternalInconsistencyException \
                                  reason: [NSString stringWithFormat: \
     _(@"Subclass %@ didn't override `%@'."), [self className], \
     NSStringFromSelector(_cmd)] \
                                userInfo: nil]
#else
# define SUBCLASS_OVERRIDE_ERROR \
   [NSException raise: NSInternalInconsistencyException \
               format: _(@"Subclass %@ didn't override `%@'."), \
     [self className], NSStringFromSelector(_cmd)]
#endif

// the lock with which we protect access to the randomizer's
// state setup.
static NSRecursiveLock * randomizerLock = nil;
static struct drand48_data randomizerSetup;

// store UUIDs are 256-bits long
#define STORE_UUID_SIZE   (256 / 8) /* bits */

/**
 * Generates a new random store UUID. Store UUIDs are strings containing
 * a very large (up to 256-bit) unsigned integer written in hexa.
 *
 * @return The new random UUID.
 */
static NSString *
GenerateNewRandomUUID (void)
{
  NSString * hexaValue = @"";
  unsigned int i;

  [randomizerLock lock];

  // Generate a random number which may be up to 256-bits (i.e. up to
  // 64 hexa-digits) long.
  for (i = 0; i < (STORE_UUID_SIZE / sizeof(long int)); i++)
    {
      long int result;
      lrand48_r (&randomizerSetup, &result);
      hexaValue = [NSString stringWithFormat: @"%@%X", hexaValue, result];
    }

  [randomizerLock unlock];

  return hexaValue;
}

/**
   Nn abstract superclass from which concrete implementations of
   various persistent store types are subclassed.

   Implementation Notes On Merging

   Efficient merging works with the help of so-called object version
   numbers. A version number is an abstract sequential number kept
   separately for every object in it's managed object context and in the
   persistent store. Every time an object is saved, it's storage number
   is incremented in both the managed object context and then in the
   persistent store.

   The trick is that the managed object context first checks that it's
   storage numbers are equal to those of the persistent store - that
   meaning that no other change to the objects has happened in the mean
   time. If, however, they are lower, there have been changes to objects
   by some other context working with the same persistent store. In that
   case the context's merge policy is consulted on how to deal with the
   conflicting objects:

   - a merge-error policy simply causes the save operation to fail.

   - an overwrite policy passes the conflicting objects on to the store
     to be saved and raises the context's storage numbers for the
     conflicting objects to the store's values (signaling that they are
     now "up-to-date").

   - a rollback policy re-reads the object's state from the store and
     changes the conflicting objects to have this state and again raises
     the context's storage numbers to match the store's.

   (NB. There is no difference between a rollback and
    merge-by-property-store-trump (and overwrite and
    merge-by-property-object-trump) policy, or at least none that
    I have been able to make out: both policies cause the in-memory
    object to adjust to the state in the store (or vice versa),
    and no perfomance difference occurs, since their evaluation
    is based on a property-by-property basis. Could somebody please
    clarify this issue?)
 */

@implementation GSPersistentStore

+ (void) initialize
{
  if (randomizerLock == nil)
    {
      // initialize the randomizerSetup protection lock
      randomizerLock = [NSRecursiveLock new];

      // setup the randomizer
      srand48_r(time(NULL), &randomizerSetup);
    }
}

- (void) dealloc
{
  TEST_RELEASE(_URL);
  TEST_RELEASE(_model);
  TEST_RELEASE(_configuration);
  TEST_RELEASE(_metadata);
  TEST_RELEASE(_versionNumbers);

  [super dealloc];
}

/**
 * The designated initializer.
 *
 * Subclasses should override this method to implement their own necessary
 * initialization (such as open a connection to the provided URL), but
 * only after having invoked the superclass' implementation in order to
 * assure that this abstract superclass is properly initialized.
 */
-       initWithURL: (NSURL *) URL
 managedObjectModel: (NSManagedObjectModel *) model
      configuration: (NSString *) configuration
            options: (NSDictionary *) options
{
  if ([self init])
    {
      ASSIGN(_URL, URL);
      ASSIGN(_model, model);
      ASSIGN(_configuration, configuration);

      _metadata = [[NSDictionary alloc]
        initWithObjectsAndKeys:
        GenerateNewRandomUUID(), NSStoreUUIDKey,
        [self storeType], NSStoreTypeKey,
        nil];

      _versionNumbers = [NSMutableDictionary new];

      return self;
    }
  else
    {
      return nil;
    }
}

/**
 * Getting the store's URL.
 *
 * @return The receiver's URL.
 */
- (NSURL *) URL
{
  return _URL;
}

/**
 * Getting the store's configuration.
 *
 * @return The receiver's configuration.
 */
- (NSString *) configuration
{
  return _configuration;
}

/**
 * Sets the UUID of the receiver. Subclasses should invoke this
 * method when the UUID is read from the store. External code should
 * NOT invoke it - this could mess up the store UUID machinery.
 */
- (void) setUUID: (NSString *) UUID
{
  NSMutableDictionary * metadata;

  metadata = [[_metadata mutableCopy] autorelease];
  [metadata setObject: UUID
               forKey: NSStoreUUIDKey];
  ASSIGN(_metadata, [[metadata copy] autorelease]);
}

/**
 * Sets the store's metadata dictionary. The NSStoreUUIDKey and
 * NSStoreTypeKey are automatically added. If they are already
 * defined in the passed argument they will be overwritten in
 * order to avoid interferrence from external code with the type
 * and store UUID machinery, internal to Core Data.
 */
- (void) setMetadata: (NSDictionary *) metadata
{
  NSMutableDictionary * newMetadata = [[metadata mutableCopy] autorelease];

  // copy the old values
  [newMetadata setObject: [_metadata objectForKey: NSStoreUUIDKey]
                  forKey: NSStoreUUIDKey];
  [newMetadata setObject: [self storeType] forKey: NSStoreTypeKey];

  ASSIGN(_metadata, [[newMetadata copy] autorelease]);
}

/**
 * Returns the store's metadata. For further information please see
 * -[GSPersistentStore setMetadata:].
 *
 * @return The receiver's metadata.
 */
- (NSDictionary *) metadata
{
  return _metadata;
}

- (BOOL) saveObjects: (NSSet *) objects
               error: (NSError **) error
{
  NSEnumerator * e = [objects objectEnumerator];
  NSManagedObject * managedObject;

  // increment the storage number for non-fault objects
  while ((managedObject = [e nextObject]) != nil)
    {
      if (![managedObject isFault])
        {
          unsigned long long version;
          NSManagedObjectID * objectID = [managedObject objectID];

          NSAssert([objectID persistentStore] == self, _(@"Tried to store "
            @"a managed object in a different persistent store than where "
            @"it belongs."));

          version = [[_versionNumbers objectForKey: objectID]
            unsignedLongLongValue];
          version++;
          [_versionNumbers
            setObject: [NSNumber numberWithUnsignedLongLong: version]
               forKey: objectID];
        }
    }

  // and write the objects
//  return [self writeWithObjects: objects error: error];
  return NO;
}

- (unsigned long long) storageNumberForObjectID: (NSManagedObjectID *) objectID
{
  return [[_versionNumbers objectForKey: objectID] unsignedLongLongValue];
}

/**
 * Subclasses must override this to return the store's type as a string.
 * This information is automatically added by GSPersistentStore to the
 * store's meta-data dictionary as necessary.
 *
 * @return The store type as a string.
 */
- (NSString *) storeType
{
  SUBCLASS_OVERRIDE_ERROR;

  return nil;
}

/**
 * Does a lookup in the store for an object that has `entity' set and
 * matches the provided predicate. Subclasses must override this
 * method in order to implement their type-specific store interaction.
 *
 * @return A dictionary where keys are managed object IDs and values
 * are dictionaries containing key-value pairs for the corresponding
 * properties of the managed object (the key being the key of the
 * corresponding managed object's persistent property name and the
 * value being the property's value). Relationships store the target
 * object's managedObjectID - this is to allow serialization of
 * object graphs. The context then uses this information and
 * reconstructs the object graph to represent the data in the store
 * (and handles faulting as adequate).
 *
 * The following example demonstrates the format:
 *
 * {
 *   <ManagedObjectID-1> = {
 *     "AttributeName" = <attribute-value>;
 *     "ToOneRelationshipName" = <ManagedObjectID-2>;
 *   };
 *   <ManagedObjectID-2> = {
 *     "ToManyRelationshipName" = ({
 *        <ManagedObjectID-1>,
 *        <ManagedObjectID-2>,
 *         ...
 *        <ManagedObjectID-n>
 *     });
 *   };
 *   ...
 *   <ManagedObjectID-n> = {
 *     ...
 *   };
 * }
 *
 * Here "{}" delimit an NSDictionary and "({})" delimit an NSSet, as in
 * the usual property-list syntax.
 *
 * If no object matches the provided search criteria, an empty array
 * should be returned. Passing entity=nil and predicate=nil should
 * return all the objects in the store. On error, this method should
 * return `nil' and set `error' accordingly.
 */
- (NSDictionary *) fetchObjectsWithEntity: (NSEntityDescription *) entity
                                predicate: (NSPredicate *) predicate
                                    error: (NSError **) error
{
  SUBCLASS_OVERRIDE_ERROR;

  return nil;
}

/**
 * Subclasses must override this method. This method does a lookup
 * in the store for an object with `objectID' and if such an object
 * exists, values of properties contained `properties' should be
 * returned. If `properties' is nil, all properties values should be
 * returned instead.
 *
 * @return A dictionary containing key-value pairs for the property
 *     names and values of the stored object. See
 *     "-fetchObjects:withEntity:predicate:error:" for details on
 *     how to structure the dictionary's internals. If the objectID
 *     isn't found in the store, `nil' should be returned and the
 *     error argument should be left untouched. If an error occured,
 *     nil should be returned and `error' set to the error's reason.
 */
- (NSDictionary *) fetchObjectWithID: (NSManagedObjectID *) objectID
                     fetchProperties: (NSSet *) properties
                               error: (NSError **) error
{
  SUBCLASS_OVERRIDE_ERROR;

  return nil;
}

/**
 * Subclass must override this method. It should write the persistent
 * store to it's URL location. In detail, this method must perform this:
 *
 * -  Write it's metadata dictionary contents (the UUID is the only
 *    mandatory field). The UUID may need to be written only when the
 *    store is created - it is left to the store implementation whether
 *    it wants to overwrite it every time it is saved. The fate of the
 *    rest of the metadata is left entirely up to the store's decision.
 *
 * -  Write the highest ID value.
 *
 * -  Write the objects in `objectsToWrite', adding them to the store,
 *    or overwriting the versions already in the store. Only persistent
 *    properties of the objects should be stored. Attributes should store
 *    the direct value of the attribute, whereas relationships should store
 *    the object ID of the target object(s).
 *
 *    It is good practice to somehow 'key' the stored objects in the
 *    store against their object IDs (`object' here refers not to an
 *    instance of NSManagedObject, but instead to the stored aggregation
 *    of persistent properties) - this makes later access to objects
 *    easier.
 *
 * -  Remove from the persistent store objects who's object IDs are in
 *    objectIDsToDelete.
 *
 * If the write is successful this method should return YES, or, in case
 * an error occured, return NO and indicate the reason for it in `error'.
 */
- (BOOL) writeSavingObjects: (NSSet *) objectsToWrite
            deletingObjects: (NSSet *) objectIDsToDelete
                      error: (NSError **) error
{
  SUBCLASS_OVERRIDE_ERROR;

  return NO;
}

@end
