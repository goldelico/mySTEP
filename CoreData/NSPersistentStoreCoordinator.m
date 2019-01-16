/* Implementation of the NSPersistentStoreCoordinator class for the GNUstep
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
#import "GSSQLitePersistentStore.h"

NSString
  * const NSSQLiteStoreType = @"NSSQLiteStoreType",
  * const NSXMLStoreType = @"NSXMLStoreType",
  * const NSBinaryStoreType = @"NSBinaryStoreType",
  * const NSInMemoryStoreType = @"NSInMemoryStoreType";

NSString
  * const NSReadOnlyPersistentStoreOption = @"NSReadOnlyPersistentStoreOption",
  * const NSValidateXMLStoreOption = @"NSValidateXMLStoreOption";

NSString
  * const NSStoreTypeKey = @"NSStoreTypeKey",
  * const NSStoreUUIDKey = @"NSStoreUUIDKey";

@implementation NSPersistentStoreCoordinator

/**
 * This maps store type strings to classes that implement
 * the specific store types. All must conform to the
 * GSPersistentStore protocol. This dictionary is mutable
 * in order to allow further addition of store types into
 * it at run time.
 */
static NSMutableDictionary * persistentStoreTypes = nil;

// Add the basic store types to our knowledge base.
+ (void) initialize
{
  if (persistentStoreTypes == nil)
    {
      persistentStoreTypes = [[NSMutableDictionary alloc]
        initWithObjectsAndKeys:
        NSSQLiteStoreType, [GSSQLitePersistentStore class],
/*
		NSXMLStoreType, [GSXMLPersistentStore class],
        NSBinaryStoreType, [GSBinaryPersistentStore class],
        NSInMemoryStoreType, [GSInMemoryPersistentStore class],*/
        nil];
    }
}

+ (void) addPersistentStoreType: (NSString *) type
                 handledByClass: (Class) newClass
{
  Class oldClass;

  if ([newClass isKindOfClass: [GSPersistentStore class]] == NO)
    {
      [NSException raise: NSInvalidArgumentException
                  format: _(@"When adding a new store type, you must "
                            @"do so by subclassing GSPersistentStore "
                            @"and implementing it's abstract methods."),
                            [newClass className]];
    }

  // warn about redefinition of already defined store types.
  oldClass = [persistentStoreTypes objectForKey: type];
  if (oldClass != nil && oldClass != newClass)
    {
      NSLog(_(@"WARNING: Replacing persistent store type %@, "
            @"originally handled by class %@, with class %@."),
        type, [oldClass className], [newClass className]);
    }

  [persistentStoreTypes setObject: newClass forKey: type];
}

+ (NSArray *) supportedPersistentStoreTypes
{
  return [persistentStoreTypes allKeys];
}

- (void) dealloc
{
  if (_acquiredModel)
    {
      [_model _decrementUseCount];
    }
  TEST_RELEASE(_model);

  TEST_RELEASE(_persistentStores);
  TEST_RELEASE(_lock);

  [super dealloc];
}

- (id) initWithManagedObjectModel: (NSManagedObjectModel *) model
{
	if ((self = [self init]))
    {
      ASSIGN(_model, model);

      _persistentStores = [NSMutableDictionary new];
      _lock = [NSRecursiveLock new];

    }
	return self;
}

- (NSManagedObjectModel *) managedObjectModel
{
  return _model;
}

- (id) addPersistentStoreWithType: (NSString *) storeType
                    configuration: (NSString *) configuration
                              URL: (NSURL *) aURL
                          options: (NSDictionary *) options
                            error: (NSError **) error
{
  GSPersistentStore * store;
  Class storeClass;

  storeClass = [persistentStoreTypes objectForKey: storeType];
  if (storeClass == Nil)
    {
      SetNonNullError(error, [NSError
        errorWithDomain: NSCoreDataErrorDomain
                   code: NSPersistentStoreInvalidTypeError
               userInfo: nil]);

      return nil;
    }

  // define what configurations are allowed
  if (_configurationSet == NO)
    {
      _multipleConfigurationsAllowed = (configuration != nil);
      _configurationSet = YES;
    }
  else if (_multipleConfigurationsAllowed == NO && configuration != nil)
    {
      SetNonNullError(error, [NSError
        errorWithDomain: NSCoreDataErrorDomain
                   code: NSPersistentStoreIncompatibleSchemaError
               userInfo: nil]);

      return nil;
    }

  store = [[[storeClass alloc]
           initWithURL: aURL
    managedObjectModel: _model
         configuration: configuration
               options: options]
    autorelease];
  if (store == nil)
    {
      SetNonNullError(error, [NSError
        errorWithDomain: NSCoreDataErrorDomain
                   code: NSPersistentStoreInitializationError
               userInfo: nil]);

      return nil;
    }

  [_persistentStores setObject: store forKey: aURL];

  return store;
}

- (BOOL) removePersistentStore: (id) persistentStore
                         error: (NSError **) error
{
  GSPersistentStore * store = persistentStore;

  // FIXME: what errors could occur here?
  [_persistentStores removeObjectForKey: [store URL]];

  return YES;
}

- (NSArray *) persistentStores
{
  return [_persistentStores allValues];
}

- (id) persistentStoreForURL: (NSURL *) aURL
{
  return [_persistentStores objectForKey: aURL];
}

- (NSURL *) URLForPersistentStore: (id) persistentStore
{
  return [persistentStore URL];
}

- (void) lock
{
  [_lock lock];
}

- (BOOL) tryLock
{
  return [_lock tryLock];
}

- (void) unlock
{
  [_lock unlock];
}

- (NSDictionary *) metadataForPersistentStore: (id) store
{
  return [store metadata];
}

- (NSManagedObjectID *) managedObjectIDForURIRepresentation: (NSURL *) uri
{
  GSPersistentStore * store;
  NSString * UUID;
  unsigned long long uuid, idValue;
  NSString * entityName;
  NSEntityDescription * entity;
  NSEnumerator * e;
  NSArray * pathComponents;

  pathComponents = [[uri path] pathComponents];
  if ([pathComponents count] != 3)
    {
      return nil;
    }

  // find the persistent store with the ID's UUID
  UUID = [pathComponents objectAtIndex: 0];
  e = [[_persistentStores allValues] objectEnumerator];
  while ((store = [e nextObject]) != nil)
    {
      if ([[[store metadata] objectForKey: NSStoreUUIDKey] isEqual: UUID])
        {
          break;
        }
    }
  if (store == nil)
    {
      // store not found
      return nil;
    }

  // find the ID's entity
  entityName = [pathComponents objectAtIndex: 1];
  if ([store configuration] == nil)
    {
      entity = [[_model entitiesByName] objectForKey: entityName];
    }
  else
    {
      entity = [[_model _entitiesByNameForConfiguration: [store configuration]]
        objectForKey: entityName];
    }

  if (entity == nil)
    {
      // entity not found
      return nil;
    }

  if (sscanf([[pathComponents objectAtIndex: 2] cString], "%llX",
    &idValue) != 1)
    {
      // malformed or no id value
      return nil;
    }

  return [[[NSManagedObjectID alloc]
    _initWithEntity: entity
    persistentStore: store
              value: idValue]
    autorelease];
}

@end
