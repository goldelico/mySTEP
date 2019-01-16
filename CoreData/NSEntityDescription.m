/* Implementation of the NSEntityDescription class for the GNUstep
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

// Ensures the entity can be edited. Raises an NSGenericException
// if the passed model is not nil and is not editable, with a reason
// set to `reason'.
static inline void EnsureEntityEditable(NSManagedObjectModel * model,
                                        NSString * reason)
{
  if (model != nil && [model _isEditable] == NO)
    {
      [NSException raise: NSGenericException format: reason];
    }
}


@implementation NSEntityDescription


- (NSDictionary *) _filteredPropertiesOfClass: (Class) aClass
{
  NSMutableDictionary * dict;
  NSEnumerator * e;
  NSPropertyDescription * property;

  dict = [NSMutableDictionary dictionaryWithCapacity: [_properties count]];
  e = [_properties objectEnumerator];
  while ((property = [e nextObject]) != nil)
    {
      if (aClass == Nil || [property isKindOfClass: aClass])
        {
          [dict setObject: property forKey: [property name]];
        }
    }

  return [[dict copy] autorelease];
}

- (NSDictionary *) _fetchedPropertiesByName
{
	return [self _filteredPropertiesOfClass: [NSFetchedPropertyDescription
		class]];
}

+ (NSEntityDescription *) entityForName: (NSString *) entityName
                 inManagedObjectContext: (NSManagedObjectContext *) ctxt
{
  return [[[[ctxt persistentStoreCoordinator] managedObjectModel]
    entitiesByName] objectForKey: entityName];
}

+ (id) insertNewObjectForEntityForName: (NSString *) anEntityName
                inManagedObjectContext: (NSManagedObjectContext *) aContext
{
  NSEntityDescription * entity;
  Class entityClass;
  NSManagedObjectModel * model;

  model = [[aContext persistentStoreCoordinator] managedObjectModel];
  entity = [[model entitiesByName] objectForKey: anEntityName];

  entityClass = NSClassFromString([entity managedObjectClassName]);

  return [[[entityClass alloc]
    initWithEntity: entity insertIntoManagedObjectContext: aContext]
    autorelease];
}

- (void) dealloc
{
  TEST_RELEASE(_name);

  // let go of our properties
  [_properties makeObjectsPerformSelector: @selector(_setEntity:)
                               withObject: nil];
  TEST_RELEASE(_properties);

  TEST_RELEASE(_userInfo);
  TEST_RELEASE(_managedObjectClassName);

  [_subentities makeObjectsPerformSelector: @selector(setSuperentity:)
                                withObject: nil];

  TEST_RELEASE(_subentities);

  [super dealloc];
}



- (NSString *) name
{
  return _name;
}

- (void) setName: (NSString *) aName
{
  EnsureEntityEditable(_model, _(@"Tried to set the name of an "
                                 @"entity alredy in use."));
  ASSIGN(_name, aName);
}



- (NSManagedObjectModel *) managedObjectModel
{
  return _model;
}



- (NSString *) managedObjectClassName
{
  return _managedObjectClassName;
}

- (void) setManagedObjectClassName: (NSString *) aName
{
  EnsureEntityEditable(_model, _(@"Tried to set the managed object "
                                 @"class name of an entity already in use"));
  ASSIGN(_managedObjectClassName, aName);
}



- (BOOL) isAbstract
{
  return _abstract;
}

- (void) setAbstract: (BOOL) flag
{
  EnsureEntityEditable(_model, _(@"Tried to set abstractness "
                                 @"of an entity already in use"));
  _abstract = flag;
}

/**
 * Returns YES if the receiver is a subentity (inclusively) of
 * `otherEntity', and NO otherwise.
 */
- (BOOL) _isSubentityOfEntity: (NSEntityDescription *) otherEntity
{
  NSEntityDescription * entity;

  for (entity = self; entity != nil; entity = [entity superentity])
    {
      if ([entity isEqual: otherEntity])
        {
          return YES;
        }
    }

  return NO;
}

- (NSDictionary *) subentitiesByName
{
  NSMutableDictionary * dict;
  NSEnumerator * e;
  NSEntityDescription * subentity;

  dict = [NSMutableDictionary dictionaryWithCapacity: [_subentities count]];
  e = [_subentities objectEnumerator];
  while ((subentity = [e nextObject]) != nil)
    {
      [dict setObject: subentity forKey: [subentity name]];
    }

  return [[dict copy] autorelease];
}

- (NSArray *) subentities
{
  return _subentities;
}

- (void) setSubentities: (NSArray *) someEntities
{
  EnsureEntityEditable(_model, _(@"Tried to set sub-entities of an entity "
                                 @"already in use"));
  ASSIGN(_subentities, [[someEntities copy] autorelease]);
}


- (NSEntityDescription *) superentity
{
  return _superentity;
}

- (void) _setSuperentity: (NSEntityDescription *) entity
{
  EnsureEntityEditable(_model, _(@"Tried to set super-entity of an entity "
                                 @"already in use"));
  _superentity = entity;
}



- (NSDictionary *) propertiesByName
{
  return [self filteredPropertiesOfClass: Nil];
}

- (NSArray *) properties
{
  return _properties;
}

- (void) setProperties: (NSArray *) someProperties
{
  EnsureEntityEditable(_model, _(@"Tried to set properties "
                                 @"of an entity already in use"));
  ASSIGN(_properties, [[someProperties copy] autorelease]);
  [_properties makeObjectsPerformSelector: @selector(_setEntity:)
                               withObject: self];
}

- (NSDictionary *) userInfo
{
  return _userInfo;
}

- (void) setUserInfo: (NSDictionary *) userInfo
{
  EnsureEntityEditable(_model, _(@"Tried to set properties "
                                 @"of an entity already in use"));
  ASSIGN(_userInfo, [[userInfo copy] autorelease]);
}



- (NSDictionary *) attributesByName
{
  return [self _filteredPropertiesOfClass: [NSAttributeDescription class]];
}

- (NSDictionary *) relationshipsByName
{
  return [self _filteredPropertiesOfClass: [NSRelationshipDescription class]];
}

- (NSArray *) relationshipsWithDestinationEntity:
  (NSEntityDescription *) destEntity
{
  NSMutableArray * array;
  NSEnumerator * e;
  NSRelationshipDescription * relationship;
  Class relationshipClass;

  array = [NSMutableArray arrayWithCapacity: [_properties count]];
  relationshipClass = [NSRelationshipDescription class];

  e = [_properties objectEnumerator];
  while ((relationship = [e nextObject]) != nil)
    {
      if ([relationship isKindOfClass: relationshipClass] &&
          [relationship destinationEntity] == destEntity)
        {
          [array addObject: relationship];
        }
    }

  return [[array copy] autorelease];
}

// NSCopying

- (id) copyWithZone: (NSZone *) aZone
{
  NSEntityDescription * entity;

  entity = [[NSEntityDescription allocWithZone: aZone] init];

  [entity setName: _name];
  [entity setManagedObjectClassName: _managedObjectClassName];
  [entity setAbstract: _abstract];
  [entity setSubentities: _subentities];
  [entity _setSuperentity: _superentity];

  return entity;
}

// NSCoding

- (id) initWithCoder: (NSCoder *) coder
{
  if ((self = [self init]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_name, [coder decodeObjectForKey: @"Name"]);
          _abstract = [coder decodeBoolForKey: @"Abstract"];
          ASSIGN(_managedObjectClassName,
            [coder decodeObjectForKey: @"ManagedObjectClassName"]);
          ASSIGN(_properties, [coder decodeObjectForKey: @"Properties"]);
          ASSIGN(_userInfo, [coder decodeObjectForKey: @"UserInfo"]);
          ASSIGN(_subentities, [coder decodeObjectForKey: @"SubEntities"]);
          _superentity = [coder decodeObjectForKey: @"SuperEntity"];
          _model = [coder decodeObjectForKey: @"ManagedObjectModel"];
          _modelRefCount = [coder decodeIntForKey: @"ModelReferenceCount"];
        }
      else
        {
          ASSIGN(_name, [coder decodeObject]);
          [coder decodeValueOfObjCType: @encode(BOOL) at: &_abstract];
          ASSIGN(_managedObjectClassName, [coder decodeObject]);
          ASSIGN(_properties, [coder decodeObject]);
          ASSIGN(_userInfo, [coder decodeObject]);
          ASSIGN(_subentities, [coder decodeObject]);
          _superentity = [coder decodeObject];
          _model = [coder decodeObject];
          [coder decodeValueOfObjCType: @encode(unsigned int)
                                    at: &_modelRefCount];
        }

    }
	return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _name forKey: @"Name"];
      [coder encodeBool: _abstract forKey: @"Abstract"];
      [coder encodeObject: _managedObjectClassName
                   forKey: @"ManagedObjectClassName"];
      [coder encodeObject: _properties forKey: @"Properties"];
      [coder encodeObject: _userInfo forKey: @"UserInfo"];
      [coder encodeObject: _subentities forKey: @"SubEntities"];
      [coder encodeObject: _superentity forKey: @"SuperEntity"];
      [coder encodeObject: _model forKey: @"ManagedObjectModel"];
      [coder encodeInt: _modelRefCount forKey: @"ModelReferenceCount"];
    }
  else
    {
      [coder encodeObject: _name];
      [coder encodeValueOfObjCType: @encode(BOOL) at: &_abstract];
      [coder encodeObject: _managedObjectClassName];
      [coder encodeObject: _properties];
      [coder encodeObject: _userInfo];
      [coder encodeObject: _subentities];
      [coder encodeObject: _superentity];
      [coder encodeObject: _model];
      [coder encodeValueOfObjCType: @encode(unsigned int)
                                at: &_modelRefCount];
    }
}

/**
 * This makes the receiver refer to the passed model as it's managed
 * object model. Sending it repeatedly will increment the reference count
 * to the model. This happens when the entity is, for example, put into
 * several configurations inside the same model.
 *
 * Under no circumstances can another managed object model try to grab the
 * entity this way - an assertion failure would arise should another model
 * try to increment the count. This way we ensure that an entity can only
 * be contained in a single model.
 *
 * To again "release" the entity from the managed object model, that model
 * must send "-removeReferenceToManagedObjectModel:" as many times as it
 * sent this message.
 */
- (void) _addReferenceToManagedObjectModel: (NSManagedObjectModel *) aModel
{
  // don't allow re-setting the owner like this
  NSAssert(aModel != nil && (_model == nil || _model == aModel),
    _(@"Attempted to forcefully change the reference from an entity "
      @"to it's managed object model owner or ``nil'' model argument "
      @"passed."));

  _model = aModel;
  _modelRefCount++;
}

- (void) _removeReferenceToManagedObjectModel: (NSManagedObjectModel *) aModel
{
  NSAssert(_model == aModel, _(@"Attempted to forcefully remove the "
    @"reference from an entity to it's managed object model by some other, "
    @"unrelated model."));
  NSAssert(_modelRefCount > 0, _(@"Attempted to underflow the "
    @"reference count from an entity to it's managed object model."));

  _modelRefCount--;
  if (_modelRefCount == 0)
    {
      _model = nil;
    }
}

@end
