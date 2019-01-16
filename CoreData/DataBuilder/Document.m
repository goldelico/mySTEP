/*
    Document.m

    Implementation of the Document class for the DataBuilder
    application.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import "Private.h"

#import "Document.h"

#import <CoreData/CoreData.h>

#import "DocumentWindowController.h"

#import "ConfigurationEditor.h"
#import "EntityEditor.h"
#import "AttributeEditor.h"
#import "FetchedPropertyEditor.h"
#import "RelationshipEditor.h"

NSString
  * const ConfigurationsDidChangeNotification =
    @"ConfigurationsDidChangeNotification",
  * const ConfigurationNameDidChangeNotification =
    @"ConfigurationNameDidChangeNotification",
  * const EntitiesDidChangeNotification = @"EntitiesDidChangeNotification",
  * const PropertiesDidChangeNotification = @"PropertiesDidChangeNotification";

NSString
  * const PropertyDidChangeNotification = @"PropertyDidChangeNotification",
  * const EntityDidChangeNotification = @"EntityDidChangeNotification";

@interface Document (Private)

- (void) addNewPropertyOfClass: (Class) aClass
                         named: (NSString *) propertyName
                      toEntity: (NSEntityDescription *) entity
               inConfiguration: (NSString *) configuration;

@end

@implementation Document (Private)

- (void) addNewPropertyOfClass: (Class) aClass
                         named: (NSString *) propertyName
                      toEntity: (NSEntityDescription *) entity
               inConfiguration: (NSString *) configuration
{
  NSPropertyDescription * property = [[aClass new] autorelease];
  NSArray * propertyNames = [[entity propertiesByName] allKeys];
  unsigned int i;

  [property setName: propertyName];

  for (i=1; [propertyNames containsObject: [property name]]; i++)
    {
      [property setName: [NSString stringWithFormat: @"%@ %d", propertyName,
        i]];
    }

  [self addProperty: property toEntity: entity inConfiguration: configuration];
}

@end

@implementation Document

- (void) dealloc
{
  NSDebugLog(@"%@: dealloc", [self className]);

  TEST_RELEASE(mainWindowController);
  TEST_RELEASE(model);

  TEST_RELEASE(attributeEditor);
  TEST_RELEASE(configurationEditor);
  TEST_RELEASE(entityEditor);
  TEST_RELEASE(relationshipEditor);

  [super dealloc];
}

- init
{
  if ([super init])
    {
      [self setHasUndoManager: YES];

      model = [NSManagedObjectModel new];

      return self;
    }
  else
    {
      return nil;
    }
}

- (BOOL) readFromFile: (NSString *) fileName ofType: (NSString *) type
{
  return [self readFromURL: [NSURL fileURLWithPath: fileName] ofType: type];
}

- (BOOL) readFromURL: (NSURL *) url ofType: (NSString *) type
{
  NSManagedObjectModel * m;

  m = [[[NSManagedObjectModel alloc] initWithContentsOfURL: url] autorelease];
  if (m == nil)
    {
      return NO;
    }
  else
    {
      ASSIGN(model, m);

      // this is false when the document is being opened and true
      // when it is being reverted - in that case this reset the
      // window controller's display to reflect the latest document state.
      if (mainWindowController != nil)
        {
          [mainWindowController setModel: model];
        }

      return YES;
    }
}

- (BOOL) writeToFile: (NSString *) fileName ofType: (NSString *) type
{
  return [self writeToURL: [NSURL fileURLWithPath: fileName] ofType: type];
}

- (BOOL) writeToURL: (NSURL *) url ofType: (NSString *) type
{
  return [[NSKeyedArchiver archivedDataWithRootObject: model]
    writeToURL: url atomically: YES];
}

- (void) makeWindowControllers
{
  mainWindowController = [[DocumentWindowController alloc]
    initWithWindowNibName: @"DocumentWindow"];

  [mainWindowController setModel: model];

  [self addWindowController: mainWindowController];
}

- (NSManagedObjectModel *) model
{
  return model;
}

- (ConfigurationEditor *) configurationEditor
{
  if (configurationEditor == nil)
    {
      configurationEditor = [[ConfigurationEditor alloc]
        initWithModel: model document: self];
    }

  return configurationEditor;
}

- (EntityEditor *) entityEditor
{
  if (entityEditor == nil)
    {
      entityEditor = [[EntityEditor alloc]
        initWithModel: model document: self];
    }

  return entityEditor;
}

- (AttributeEditor *) attributeEditor
{
  if (attributeEditor == nil)
    {
      attributeEditor = [[AttributeEditor alloc]
        initWithModel: model document: self];
    }

  return attributeEditor;
}

- (FetchedPropertyEditor *) fetchedPropertyEditor
{
  if (fetchedPropertyEditor == nil)
    {
      fetchedPropertyEditor = [[FetchedPropertyEditor alloc]
        initWithModel: model document: self];
    }

  return fetchedPropertyEditor;
}

- (RelationshipEditor *) relationshipEditor
{
  if (relationshipEditor == nil)
    {
      relationshipEditor = [[RelationshipEditor alloc]
        initWithModel: model document: self];
    }

  return relationshipEditor;
}

- (void) addNewConfiguration
{
  NSUndoManager * undoManager = [self undoManager];
  NSArray * configurations = [model configurations];
  NSString * name = _(@"New Configuration");
  unsigned int i;

  for (i=1; [configurations containsObject: name]; i++)
    {
      name = [NSString stringWithFormat: _(@"New Configuration %d"), i];
    }

  [undoManager setActionName: _(@"Add Configuration")];
  [self setEntities: [NSArray array] forConfiguration: name];
}

- (void) setEntities: (NSArray *) entities
    forConfiguration: (NSString *) configuration
{
  NSUndoManager * undoManager = [self undoManager];
  NSArray * oldEntities;
  NSDictionary * userInfo;

  if (configuration == nil)
    {
      oldEntities = [model entities];

      [[undoManager prepareWithInvocationTarget: self]
        setEntities: oldEntities forConfiguration: nil];

      [model setEntities: entities];
    }
  else
    {
      oldEntities = [model entitiesForConfiguration: configuration];

      [[undoManager prepareWithInvocationTarget: self]
             setEntities: oldEntities
        forConfiguration: configuration];

      [model setEntities: entities forConfiguration: configuration];
    }

  if (oldEntities == nil || entities == nil)
    {
      [[NSNotificationCenter defaultCenter]
        postNotificationName: ConfigurationsDidChangeNotification
                      object: model];
    }

  if (configuration != nil)
    {
      userInfo = [NSDictionary
        dictionaryWithObject: configuration forKey: @"Configuration"];
    }
  else
    {
      userInfo = nil;
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EntitiesDidChangeNotification
                  object: model
                userInfo: userInfo];
}

- (void) addNewEntityToConfiguration: (NSString *) configuration
{
  NSEntityDescription * entity = [[NSEntityDescription new] autorelease];
  NSArray * entityNames;
  unsigned int i;

  if (configuration == nil)
    {
      entityNames = [[model entitiesByName] allKeys];
    }
  else
    {
      entityNames = [[model entitiesByNameForConfiguration: configuration]
        allKeys];
    }

  [entity setName: _(@"New Entity")];
  for (i=1; [entityNames containsObject: [entity name]]; i++)
    {
      [entity setName: [NSString stringWithFormat: _(@"New Entity %d"), i]];
    }

  [[self undoManager] setActionName: _(@"Add Entity")];

  [self addEntity: entity toConfiguration: configuration];
}

- (void) addEntity: (NSEntityDescription *) entity
   toConfiguration: (NSString *) configuration
{
  NSMutableArray * entities;
  NSDictionary * userInfo;

  [[[self undoManager] prepareWithInvocationTarget: self]
    removeEntity: entity fromConfiguration: configuration];

  if (configuration == nil)
    {
      entities = [NSMutableArray arrayWithArray: [model entities]];
    }
  else
    {
      entities = [NSMutableArray arrayWithArray: [model
        entitiesForConfiguration: configuration]];
    }

  [entities addObject: entity];

  if (configuration == nil)
    {
      [model setEntities: entities];

      userInfo = nil;
    }
  else
    {
      [model setEntities: entities forConfiguration: configuration];

      userInfo = [NSDictionary dictionaryWithObject: configuration
                                             forKey: @"Configuration"];
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EntitiesDidChangeNotification
                  object: model
                userInfo: userInfo];
}

- (void) removeEntity: (NSEntityDescription *) entity
    fromConfiguration: (NSString *) configuration
{
  NSMutableArray * entities;
  NSDictionary * userInfo;

  [[[self undoManager] prepareWithInvocationTarget: self]
    addEntity: entity toConfiguration: configuration];

  if (configuration == nil)
    {
      entities = [[[model entities] mutableCopy] autorelease];
    }
  else
    {
      entities = [[[model entitiesForConfiguration: configuration]
        mutableCopy] autorelease];
    }

  [entities removeObject: entity];

  if (configuration == nil)
    {
      [model setEntities: entities];

      userInfo = nil;
    }
  else
    {
      [model setEntities: entities forConfiguration: configuration];

      userInfo = [NSDictionary dictionaryWithObject: configuration
                                             forKey: @"Configuration"];
    }

  [[NSNotificationCenter defaultCenter]
    postNotificationName: EntitiesDidChangeNotification
                  object: model
                userInfo: userInfo];
}

- (void) addNewAttributeToEntity: (NSEntityDescription *) entity
                 inConfiguration: (NSString *) configuration
{
  [[self undoManager] setActionName: _(@"Add Attribute")];

  [self addNewPropertyOfClass: [NSAttributeDescription class]
                        named: _(@"New Attribute")
                     toEntity: entity
              inConfiguration: configuration];
}

- (void) addNewFetchedPropertyToEntity: (NSEntityDescription *) entity
                       inConfiguration: (NSString *) configuration
{
  [[self undoManager] setActionName: _(@"Add Fetched Property")];

  [self addNewPropertyOfClass: [NSFetchedPropertyDescription class]
                        named: _(@"New Fetched Property")
                     toEntity: entity
              inConfiguration: configuration];
}

- (void) addNewRelationshipToEntity: (NSEntityDescription *) entity
                    inConfiguration: (NSString *) configuration
{
  [[self undoManager] setActionName: _(@"Add Relationship")];

  [self addNewPropertyOfClass: [NSRelationshipDescription class]
                        named: _(@"New Relationship")
                     toEntity: entity
              inConfiguration: configuration];
}

- (void) addProperty: (NSPropertyDescription *) property
            toEntity: (NSEntityDescription *) entity
     inConfiguration: (NSString *) configuration
{
  NSMutableArray * newProperties;
  NSDictionary * userInfo;

  [[[self undoManager] prepareWithInvocationTarget: self]
     removeProperty: property
         fromEntity: entity
    inConfiguration: configuration];

  newProperties = [NSMutableArray arrayWithArray: [entity properties]];
  [newProperties addObject: property];
  [entity setProperties: newProperties];

   // `configuration' must be last, as it may be `nil'.
  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    entity, @"Entity",
    configuration, @"Configuration",
    nil];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertiesDidChangeNotification
                  object: model
                userInfo: userInfo];
}

- (void) removeProperty: (NSPropertyDescription *) property
             fromEntity: (NSEntityDescription *) entity
        inConfiguration: (NSString *) configuration
{
  NSMutableArray * newProperties;
  NSDictionary * userInfo;

  [[[self undoManager] prepareWithInvocationTarget: self]
        addProperty: property
           toEntity: entity
    inConfiguration: configuration];

  newProperties = [NSMutableArray arrayWithArray: [entity properties]];
  [newProperties removeObject: property];
  [entity setProperties: newProperties];

   // `configuration' must be last, as it may be `nil'.
  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    entity, @"Entity",
    configuration, @"Configuration",
    nil];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertiesDidChangeNotification
                  object: model
                userInfo: userInfo];
}

- (void)  setName: (NSString *) newName
  ofConfiguration: (NSString *) oldName
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSArray * entities;
  NSDictionary * userInfo;

  NSAssert(newName != nil && oldName != nil, _(@"Nil argument."));

  [[[self undoManager] prepareWithInvocationTarget: self]
    setName: oldName ofConfiguration: newName];

  entities = [model entitiesForConfiguration: oldName];
  NSAssert(entities != nil, _(@"Tried to rename non-existant configuration."));
  [model setEntities: entities forConfiguration: newName];
  [model setEntities: nil forConfiguration: oldName];

  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    oldName, @"OldName",
    newName, @"NewName",
    nil];
  // send this first, so that objects watching for both notifications
  // will first rename their configuration - otherwise they would not
  // see their original configuration and display nothing
  [nc postNotificationName: ConfigurationNameDidChangeNotification
                    object: model
                  userInfo: userInfo];

  [nc postNotificationName: ConfigurationsDidChangeNotification
                    object: model];
}

- (void) setName: (NSString *) newName
      ofProperty: (NSPropertyDescription *) property
        inEntity: (NSEntityDescription *) entity
   configuration: (NSString *) configuration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSDictionary * userInfo;
  NSString * oldName = [property name];

  [[[self undoManager] prepareWithInvocationTarget: self]
          setName: oldName
       ofProperty: property
         inEntity: entity
    configuration: configuration];

  [property setName: newName];

  [nc postNotificationName: PropertyDidChangeNotification
                    object: property];

  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    entity, @"Entity",
    configuration, @"Configuration",
    nil];
  [nc postNotificationName: PropertiesDidChangeNotification
                    object: model
                  userInfo: userInfo];
}

- (void) setOptional: (BOOL) flag
          ofProperty: (NSPropertyDescription *) property
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setOptional: [property isOptional] ofProperty: property];

  [property setOptional: flag];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: property];
}

- (void) setTransient: (BOOL) flag
           ofProperty: (NSPropertyDescription *) property
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setTransient: [property isTransient] ofProperty: property];

  [property setTransient: flag];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: property];
}

- (void)  setName: (NSString *) newName
         ofEntity: (NSEntityDescription *) entity
  inConfiguration: (NSString *) configuration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSString * oldName = [entity name];
  NSDictionary * userInfo;

  [[[self undoManager] prepareWithInvocationTarget: self]
    setName: oldName ofEntity: entity inConfiguration: configuration];

  [entity setName: newName];
  [nc postNotificationName: EntityDidChangeNotification
                    object: entity];

  if (configuration != nil)
    {
      userInfo = [NSDictionary dictionaryWithObject: configuration
                                             forKey: @"Configuration"];
    }
  else
    {
      userInfo = nil;
    }

  [nc postNotificationName: EntitiesDidChangeNotification
                    object: model
                  userInfo: userInfo];
}

- (void) setAbstract: (BOOL) flag ofEntity: (NSEntityDescription *) entity
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setAbstract: [entity isAbstract] ofEntity: entity];
  [entity setAbstract: flag];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: EntityDidChangeNotification object: entity];
}

- (void) setSuperentity: (NSEntityDescription *) superentity
               ofEntity: (NSEntityDescription *) entity
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSEntityDescription * oldSuperentity;

  [[[self undoManager] prepareWithInvocationTarget: self]
    setSuperentity: [entity superentity] ofEntity: entity];

  oldSuperentity = [entity superentity];
  if (oldSuperentity != nil)
    {
      NSMutableArray * subentities;

      subentities = [[[oldSuperentity subentities] mutableCopy] autorelease];
      NSAssert(subentities != nil, _(@"Entity inheritance inconsistency."));
      [subentities removeObject: entity];
      [oldSuperentity setSubentities: subentities];

      [nc postNotificationName: EntityDidChangeNotification
                        object: oldSuperentity];
    }

/////   [entity setSuperentity: superentity];

  [nc postNotificationName: EntityDidChangeNotification
                    object: entity];

  if (superentity != nil)
    {
      NSMutableArray * subentities;

      subentities = [NSMutableArray arrayWithArray: [superentity subentities]];
      [subentities addObject: entity];
      [superentity setSubentities: subentities];

      [nc postNotificationName: EntityDidChangeNotification
                        object: superentity];
    }
}

- (void) setManagedObjectClassName: (NSString *) className
                          ofEntity: (NSEntityDescription *) entity
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setManagedObjectClassName: [entity managedObjectClassName]
                     ofEntity: entity];
  [entity setManagedObjectClassName: className];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: EntityDidChangeNotification object: entity];
}

- (void) setAttributeValueClassName: (NSString *) className
                        ofAttribute: (NSAttributeDescription *) attribute
{
  NSString * oldClassName = [attribute attributeValueClassName];

  [[[self undoManager] prepareWithInvocationTarget: self]
    setAttributeValueClassName: oldClassName ofAttribute: attribute];

  // FIXME: translate classname to attribute type!
/*  NSUndefinedAttributeType = 0,
	  NSInteger16AttributeType = 100,
	  NSInteger32AttributeType = 200,
	  NSInteger64AttributeType = 300,
	  NSDecimalAttributeType = 400,
	  NSDoubleAttributeType = 500,
	  NSFloatAttributeType = 600,
	  NSStringAttributeType = 700,
	  NSBooleanAttributeType = 800,
	  NSDateAttributeType = 900,
	  NSBinaryDataAttributeType = 1000
*/	  
 // [attribute setAttributeValueClassName: className];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: attribute];
}

- (void) setAttributeType: (NSAttributeType) type
              ofAttribute: (NSAttributeDescription *) attribute
{
  NSAttributeType oldType = [attribute attributeType];

  [[[self undoManager] prepareWithInvocationTarget: self]
    setAttributeType: oldType ofAttribute: attribute];

  [attribute setAttributeType: type];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: attribute];
}

- (void) setDestinationEntity: (NSEntityDescription *) entity
               ofRelationship: (NSRelationshipDescription *) relationship
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setDestinationEntity: [relationship destinationEntity]
          ofRelationship: relationship];

  [relationship setDestinationEntity: entity];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification object: relationship];
}

- (void) setInverseRelationship: (NSRelationshipDescription *) invRelationship
                 ofRelationship: (NSRelationshipDescription *) relationship
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSRelationshipDescription * oldInvRelationship;

  [[[self undoManager] prepareWithInvocationTarget: self]
    setInverseRelationship: [relationship inverseRelationship]
            ofRelationship: relationship];

  // set up the proper inter-relationships

  // break the old inverse relationship of `relationship'
  oldInvRelationship = [relationship inverseRelationship];
  if (oldInvRelationship != nil)
    {
      [oldInvRelationship setInverseRelationship: nil];
      [nc postNotificationName: PropertyDidChangeNotification
                        object: oldInvRelationship];
    }
  // and set it up point to `invRelationship'
  [relationship setInverseRelationship: invRelationship];
  [nc postNotificationName: PropertyDidChangeNotification
                    object: relationship];

  // break the invRelationship's old inverse relationship
  oldInvRelationship = [invRelationship inverseRelationship];
  if (oldInvRelationship != nil)
    {
      [oldInvRelationship setInverseRelationship: nil];
      [nc postNotificationName: PropertyDidChangeNotification
                        object: oldInvRelationship];
    }

  // and set it up to point to `relationship'
  [invRelationship setDestinationEntity: [relationship entity]];
  [invRelationship setInverseRelationship: relationship];
  [nc postNotificationName: PropertyDidChangeNotification
                    object: invRelationship];
}

- (void) setMaxCount: (int) newCount
      ofRelationship: (NSRelationshipDescription *) relationship
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setMaxCount: [relationship maxCount] ofRelationship: relationship];

  [relationship setMaxCount: newCount];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: relationship];
}

- (void) setMinCount: (int) newCount
      ofRelationship: (NSRelationshipDescription *) relationship
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setMinCount: [relationship minCount] ofRelationship: relationship];

  [relationship setMinCount: newCount];
  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: relationship];
}

- (void) setDeleteRule: (NSDeleteRule) aRule
        ofRelationship: (NSRelationshipDescription *) relationship
{
  [[[self undoManager] prepareWithInvocationTarget: self]
    setDeleteRule: [relationship deleteRule] ofRelationship: relationship];

  [relationship setDeleteRule: aRule];

  [[NSNotificationCenter defaultCenter]
    postNotificationName: PropertyDidChangeNotification
                  object: relationship];
}

@end
