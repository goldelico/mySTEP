/* Implementation of the NSManagedObjectModel class for the GNUstep
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

/**
 * Runs through all the passed entities and ensures that they
 * all have names and that the names are unique (in the scope
 * of the passed array). If any of these conditions isn't met,
 * an NSInvalidArgumentException is raised.
 */
static void EnsureEntitiesHaveProperNames(NSArray * entities)
{
  NSMutableSet * knownNames;
  NSEnumerator * e;
  NSEntityDescription * entity;

  knownNames = [NSMutableSet setWithCapacity: [entities count]];
  e = [entities objectEnumerator];
  while ((entity = [e nextObject]) != nil)
    {
      NSString * entityName = [entity name];

      if (entityName == nil)
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Tried to add an entity without a name "
            @"to a managed object model.")];
        }
      if ([knownNames containsObject: entityName])
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Tried to add several entities with the "
            @"same name to a managed object model.")];
        }
      [knownNames addObject: entityName];
    }
}

@interface NSManagedObjectModel (GSCoreDataInternal)

/**
 * Sets the back-reference from the provided array's entities
 * to point to the receiver.
 */
- (void) _grabEntities: (NSArray *) entities;

/// Does the opposite of -[NSManagedObjectModel _grabEntities:].
- (void) _ungrabEntities: (NSArray *) entities;

/**
 * Raises an exception if the receiver isn't editable. ``reason'' is
 * the reason to set in the exception. Before being passed to the
 * exception, the ``reason'' argument is automatically localized.
 */
- (void) _ensureEditableWithReason: (NSString *) reason;

@end

@implementation NSManagedObjectModel (GSCoreDataInternal)

- (void) _grabEntities: (NSArray *) entities
{
  NSEnumerator * e;
  NSEntityDescription * ent;

  e = [entities objectEnumerator];
  while ((ent = [e nextObject]) != nil)
    {
      if ([ent managedObjectModel] != nil && [ent managedObjectModel] != self)
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Passed an entity to an object model already "
                                @"in use by some other model")];
        }
      [ent _addReferenceToManagedObjectModel: self];
    }
}

- (void) _ungrabEntities: (NSArray *) entities
{
  NSEnumerator * e;
  NSEntityDescription * ent;

  e = [entities objectEnumerator];
  while ((ent = [e nextObject]) != nil)
    {
      [ent _removeReferenceToManagedObjectModel: self];
    }
}

- (void) _ensureEditableWithReason: (NSString *) reason
{
  if (_usedByPersistentStoreCoordinators)
    {
      // which exception to raise??
      [NSException raise: NSGenericException format: _(reason)];
    }
}

@end

@implementation NSManagedObjectModel

- (void) dealloc
{
  NSEnumerator * e;
  NSArray * entities;

  // ungrab the entities before we disappear
  [self _ungrabEntities: _entities];
  TEST_RELEASE(_entities);

  e = [_configurations objectEnumerator];
  while ((entities = [e nextObject]) != nil)
    {
      [self _ungrabEntities: entities];
    }
  TEST_RELEASE(_configurations);

  TEST_RELEASE(_fetchRequests);

  [super dealloc];
}

+ (NSManagedObjectModel *) modelByMergingModels: (NSArray *) models
{
  NSManagedObjectModel * newModel;

  NSMutableArray * entities;
  NSMutableDictionary * confs;
  NSMutableDictionary * fetchRequests;

  NSEnumerator * e;
  NSManagedObjectModel * model;

  NSString * confName;
  NSString * fetchRequestName;

  newModel = [[NSManagedObjectModel new] autorelease];

  entities = [NSMutableArray array];
  confs = [NSMutableDictionary dictionary];
  fetchRequests = [NSMutableDictionary dictionary];

  // copy and merge all the contents from all models
  e = [models objectEnumerator];
  while ((model = [e nextObject]) != nil)
    {
      [entities addObjectsFromArray: [[[NSArray alloc]
        initWithArray: [model entities] copyItems: YES] autorelease]];

      [confs addEntriesFromDictionary: [[[NSDictionary alloc]
        initWithDictionary: [model _configurationsByName] copyItems: YES]
        autorelease]];

      // fetch requests can be shared
      [fetchRequests addEntriesFromDictionary:  [model fetchRequestsByName]];
    }

  // and set the merged contents into the new model
  [newModel setEntities: entities];

  e = [[confs allKeys] objectEnumerator];
  while ((confName = [e nextObject]) != nil)
    {
      [newModel setEntities: [confs objectForKey: confName]
           forConfiguration: confName];
    }

  e = [[fetchRequests allKeys] objectEnumerator];
  while ((fetchRequestName = [e nextObject]) != nil)
    {
      [newModel setFetchRequestTemplate: [fetchRequests objectForKey:
        fetchRequestName]
                                forName: fetchRequestName];
    }

  return newModel;
}

+ (NSManagedObjectModel *) mergedModelFromBundles: (NSArray *) bundles
{
  NSArray * modelPaths;
  NSMutableArray * models;

  NSEnumerator * e;
  NSString * modelPath;

  // find the involved .gsdatamodel files
  if (bundles != nil)
   // search specified bundles
    {
      NSEnumerator * e;
      NSBundle * bundle;
      NSMutableArray * array;

      array = [NSMutableArray array];

      e = [bundles objectEnumerator];
      while ((bundle = [e nextObject]) != nil)
        {
          [array addObjectsFromArray:
            [bundle pathsForResourcesOfType: @"gsdatamodel" inDirectory: nil]];
        }

      modelPaths = array;
    }
  else
   // search the main bundle
    {
      modelPaths = [[NSBundle mainBundle]
        pathsForResourcesOfType: @"gsdatamodel" inDirectory: nil];
    }


  // initialize the models from them
  models = [NSMutableArray arrayWithCapacity: [modelPaths count]];
  e = [modelPaths objectEnumerator];
  while ((modelPath = [e nextObject]) != nil)
    {
      [models addObject: [[[NSManagedObjectModel alloc]
        initWithContentsOfFile: modelPath]
        autorelease]];
    }

  // and return the merged result
  return [self modelByMergingModels: models];
}

- (id) initWithContentsOfURL: (NSURL *) url
{
  NSData * data;

  // release the old instance - we'll return a new one
  [self release];

  if ((data = [NSData dataWithContentsOfURL: url]) == nil)
    {
      NSLog(_(@"Failed to access managed object model archive at: %@"),
        [url description]);

      return nil;
    }

  return [NSKeyedUnarchiver unarchiveObjectWithData: data];
}

- (id) _initWithContentsOfFile: (NSString *) file
{
  return [self initWithContentsOfURL: [NSURL fileURLWithPath: file]];
}

- (id) init
{
	if ((self = [super init]))
    {
      _configurations = [NSMutableDictionary new];
      _fetchRequests = [NSMutableDictionary new];
	}
      return self;
}

- (NSArray *) entities
{
  return _entities;
}

- (NSDictionary *) entitiesByName
{
  NSMutableDictionary * dict = [NSMutableDictionary
    dictionaryWithCapacity: [_entities count]];
  NSEnumerator * e = [_entities objectEnumerator];
  NSEntityDescription * entity;

  while ((entity = [e nextObject]) != nil)
    {
      [dict setObject: entity forKey: [entity name]];
    }

  return [[dict copy] autorelease];
}

- (void) setEntities: (NSArray *) someEntities
{
  [self _ensureEditableWithReason: @"Tried to set entities of a "
    @"managed object model already in use by an object graph manager."];
  EnsureEntitiesHaveProperNames(someEntities);

  if (_entities != nil)
    {
      [self _ungrabEntities: _entities];
      DESTROY(_entities);
    }
  if (someEntities != nil)
    {
      _entities = [someEntities copy];
      [self _grabEntities: _entities];
    }
}

- (NSArray *) configurations
{
  return [_configurations allKeys];
}

- (NSArray *) entitiesForConfiguration: (NSString *) conf
{
  return [_configurations objectForKey: conf];
}

- (void) setEntities: (NSArray *) entities
    forConfiguration: (NSString *) conf
{
  NSArray * oldEntities;

  [self _ensureEditableWithReason: @"Tried to set entities "
    @"for a configuration of a managed object model already in use "
    @"by an object graph manager."];
  EnsureEntitiesHaveProperNames(entities);

  oldEntities = [_configurations objectForKey: conf];
  if (oldEntities != nil)
    {
      [self _ungrabEntities: oldEntities];
      [_configurations removeObjectForKey: conf];
    }
  if (entities != nil)
    {
      [_configurations setObject: [[entities copy] autorelease]
                          forKey: conf];
      [self _grabEntities: entities];
    }
}

- (NSDictionary *) _configurationsByName
{
  return [[_configurations copy] autorelease];
}

- (NSFetchRequest *) fetchRequestTemplateForName: (NSString *) aName
{
  return [_fetchRequests objectForKey: aName];
}

- (NSFetchRequest *) fetchRequestFromTemplateWithName: (NSString *) name
                                substitutionVariables: (NSDictionary *) vars
{
  NSFetchRequest * req, * template;

  template = [_fetchRequests objectForKey: name];
  if (template == nil)
    {
      return nil;
    }

  req = [[template copy] autorelease];
  if ([req predicate] != nil)
    {
      [req setPredicate: [[req predicate]
        predicateWithSubstitutionVariables: vars]];
    }

  return req;
}

- (void) setFetchRequestTemplate: (NSFetchRequest *) request
                         forName: (NSString *) name
{
  if (_usedByPersistentStoreCoordinators)
    {
      [NSException raise: NSGenericException
                  format: _(@"Tried to set a fetch request template "
                             @"for a managed object model already in use "
                             @"by an object graph manager.")];
    }

  // N.B. is this the way it should behave?
  if (request != nil)
    {
      [_fetchRequests setObject: request forKey: name];
    }
  else
    {
      [_fetchRequests removeObjectForKey: name];
    }
}

- (void) _removeFetchRequestTemplateForName: (NSString *) name
{
  if (_usedByPersistentStoreCoordinators)
    {
      [NSException raise: NSGenericException
                  format: _(@"Tried to remove a fetch request template "
                            @"from a managed object model already in use "
                            @"by an object graph manager.")];
    }

  [_fetchRequests removeObjectForKey: name];
}

- (NSDictionary *) fetchRequestsByName
{
  return [[_fetchRequests copy] autorelease];
}

- (NSDictionary *) localizationDictionary
{
  // FIXME: what is this supposed to do ???

  return nil;
}

- (void) setLocalizationDictionary: (NSDictionary *) dict
{
  // FIXME: what is this supposed to do ???
}

- (BOOL) _isEditable
{
  return (_usedByPersistentStoreCoordinators == 0);
}

// NSCoding

- (id) initWithCoder: (NSCoder *) coder
{
	if ((self = [super init]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_entities, [coder decodeObjectForKey: @"Entities"]);
          ASSIGN(_configurations, [coder decodeObjectForKey:
            @"Configurations"]);
          ASSIGN(_fetchRequests, [coder decodeObjectForKey: @"FetchRequests"]);
        }
      else
        {
          ASSIGN(_entities, [coder decodeObject]);
          ASSIGN(_configurations, [coder decodeObject]);
          ASSIGN(_fetchRequests, [coder decodeObject]);
        }
	}
      return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _entities forKey: @"Entities"];
      [coder encodeObject: _configurations forKey: @"Configurations"];
      [coder encodeObject: _fetchRequests forKey: @"FetchRequests"];
    }
  else
    {
      [coder encodeObject: _entities];
      [coder encodeObject: _configurations];
      [coder encodeObject: _fetchRequests];
    }
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  NSManagedObjectModel * model;

  NSEnumerator * e;
  NSString * conf;
  NSString * fetchRequestName;

  model = [[NSManagedObjectModel allocWithZone: zone] init];

   // We must copy entities and configurations themselves too - they are
   // not shareable between several models. (FIXME: is this true? Apple
   // spec doesn't say a word about this - I just *guessed* it)
  [model setEntities: [[[NSArray alloc]
    initWithArray: _entities copyItems: YES]
    autorelease]];

  e = [[_configurations allKeys] objectEnumerator];
  while ((conf = [e nextObject]) != nil)
    {
      [model setEntities: [[[NSArray alloc]
        initWithArray: [_configurations objectForKey: conf]
            copyItems: YES]
        autorelease]
        forConfiguration: conf];
    }

   // fetch requests appear to be shareable, so just set them
  e = [[_fetchRequests allKeys] objectEnumerator];
  while ((fetchRequestName = [e nextObject]) != nil)
    {
      [model setFetchRequestTemplate: [_fetchRequests objectForKey:
        fetchRequestName]
                             forName: fetchRequestName];
    }

  return model;
}

/**
 * Sent by a persistent store coordinator which is associated with the
 * receiver in the moment the first data fetch is done.
 */
- (void) _incrementUseCount
{
  _usedByPersistentStoreCoordinators++;
}

/**
 * Sent by a persistent store coordinator which is associated with the
 * receiver when the store coordinator is dealloc'ed (only if it did
 * a data fetch in the mean time).
 */
- (void) _decrementUseCount
{
  NSAssert(_usedByPersistentStoreCoordinators > 0,
    _(@"Tried to underflow managed object model use count."));

  _usedByPersistentStoreCoordinators--;
}

@end
