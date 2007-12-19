/*
    EntityEditor.m

    Implementation of the EntityEditor class for the DataBuilder application.

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

#import "EntityEditor.h"

#import "Document.h"
#import "DocumentWindowController.h"

@interface EntityEditor (Private)

- (void) setControlsEnabled: (BOOL) flag;

@end

@implementation EntityEditor (Private)

- (void) setControlsEnabled: (BOOL) flag
{
  [name setEditable: flag];
  [abstract setEnabled: flag];
  [objectClassName setEditable: flag];
  [superentity setEnabled: flag];
}

@end

@implementation EntityEditor

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(entity);
  TEST_RELEASE(configuration);

  [super dealloc];
}

- (id) initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
	if ((self = [super initWithModel: aModel document: aDocument]))
    {
      NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

      [NSBundle loadNibNamed: @"EntityEditor" owner: self];

      [nc addObserver: self
             selector: @selector(noteEntityListChanged:)
                 name: EntitiesDidChangeNotification
               object: model];

    }
	return self;
}

- (void) setupWithEntity: (NSEntityDescription *) anEntity
         inConfiguration: (NSString *) aConfiguration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  if (entity != nil)
    {
      [nc removeObserver: self
                    name: EntityDidChangeNotification
                  object: entity];
    }

  ASSIGN(entity, anEntity);
  ASSIGN(configuration, aConfiguration);

  if (entity != nil)
    {
      [nc addObserver: self
             selector: @selector(noteEntityChanged:)
                 name: EntityDidChangeNotification
               object: entity];

      [self setControlsEnabled: YES];
      [self refresh: nil];
    }
  else
    {
      [self setControlsEnabled: NO];
      [name setStringValue: nil];
      [abstract setState: NO];
      [objectClassName setStringValue: nil];
      [superentity removeAllItems];
    }
}

- (void) refresh: sender
{

  [name setStringValue: [entity name]];
  [abstract setState: [entity isAbstract]];
  [objectClassName setStringValue: [entity managedObjectClassName]];

  [self refreshSuperentityList: nil];
}

- (void) refreshSuperentityList: sender
{
  NSArray * entities;
  NSEnumerator * e;
  NSEntityDescription * otherEntity;
  NSMutableArray * entityNames;

  if (configuration == nil)
    {
      entities = [[document model] entities];
    }
  else
    {
      entities = [[document model] entitiesForConfiguration: configuration];
    }

  NSAssert(entities != nil, _(@"Configuration mismatch."));

  // don't put into the list of selectable super-entities our own entity
  // and any of it's subentities
  entityNames = [NSMutableArray arrayWithCapacity: [entities count]];
  e = [entities objectEnumerator];
  while ((otherEntity = [e nextObject]) != nil)
    {
	  NSEntityDescription *current = otherEntity;
	  while (current && current != entity && ![current isEqual: entity])
		  current = [current superentity];
	  if(!current)
        { // ok, otherEntity is not a subentity
          [entityNames addObject: [otherEntity name]];
        }
    }

  [entityNames sortUsingSelector: @selector(caseInsensitiveCompare:)];

  [superentity removeAllItems];
  [superentity addItemWithTitle: @""];
  [superentity addItemsWithTitles: entityNames];

  if ([entity superentity] != nil)
    {
      [superentity selectItemWithTitle: [[entity superentity] name]];
    }
  else
    {
      [superentity selectItemAtIndex: 0];
    }
}

- (void) updateEntityName: (id)sender
{
  NSString * newName = [name stringValue];
  NSArray * entityNames;

  if (configuration == nil)
    {
      entityNames = [[[document model] entitiesByName] allKeys];
    }
  else
    {
      entityNames = [[[document model] entitiesByNameForConfiguration:
        configuration] allKeys];
    }

  if ([newName length] == 0)
    {
      NSRunAlertPanel(_(@"Invalid name"),
        _(@"You must specify a name for the entity."),
        nil, nil, nil);
      return;
    }
  if ([entityNames containsObject: newName])
    {
      NSRunAlertPanel(_(@"Name already in use"),
        _(@"There already is an entity named %@ in this configuration."),
        nil, nil, nil, newName);
      return;
    }

  [[document undoManager] setActionName: _(@"Rename Entity")];
  [document setName: newName
           ofEntity: entity
    inConfiguration: configuration];
}


- (void) updateAbstract: (id)sender
{
  BOOL flag = [abstract state];

  [[document undoManager] setActionName: flag ? _(@"Set Abstract") :
    _(@"Unset Abstract")];
  [document setAbstract: flag ofEntity: entity];
}


- (void) updateObjectClassName: (id)sender
{
  if ([[objectClassName stringValue] length] > 0)
    {
      [[document undoManager] setActionName: _(@"Set Object Class Name")];
      [document setManagedObjectClassName: [objectClassName stringValue]
                                 ofEntity: entity];
    }
  else
    {
      [[document undoManager] setActionName: _(@"Unset Object Class Name")];
      [document setManagedObjectClassName: nil ofEntity: entity];
    }
}


- (void) updateSuperentity: (id)sender
{
  NSString * entityName = [superentity titleOfSelectedItem];
  NSDictionary * entitiesByName;

  [[document undoManager] setActionName: _(@"Set Superentity")];
  if (![entityName isEqualToString: @""])
    {
      NSEntityDescription * targetEntity;

      if (configuration == nil)
        {
          entitiesByName = [[document model] entitiesByName];
        }
      else
        {
          entitiesByName = [[document model]
            entitiesByNameForConfiguration: configuration];
        }

      targetEntity = [entitiesByName objectForKey: entityName];
      NSAssert(targetEntity != nil, _(@"Superentity not found."));

      [document setSuperentity: targetEntity ofEntity: entity];
    }
  else
    {
      [document setSuperentity: nil ofEntity: entity];
    }
}

- (void) noteEntityChanged: (NSNotification *) notif
{
  if ([notif object] == entity)
    {
      [self refresh: nil];
    }
}

- (void) noteEntityListChanged: (NSNotification *) notif
{
  NSString * aConfiguration = [[notif userInfo]
    objectForKey: @"Configuration"];

  if ((aConfiguration == nil && configuration == nil) ||
    ([aConfiguration isEqualToString: configuration]))
    {
      NSArray * entities;

      // make sure our entity has not been removed
      if (configuration == nil)
        {
          entities = [[document model] entities];
        }
      else
        {
          entities = [[document model] entitiesForConfiguration:
            configuration];
        }

      if ([entities containsObject: entity])
        {
          [self refreshSuperentityList: nil];
        }
      else
        {
          [self setupWithEntity: nil inConfiguration: nil];
        }
    }
}

@end
