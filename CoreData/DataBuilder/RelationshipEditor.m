/*
    RelationshipEditor.m

    Implementation of the RelationshipEditor class for the DataBuilder
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

#import "RelationshipEditor.h"
#import "Document.h"
#import "DocumentWindowController.h"

@interface RelationshipEditor (Private)

- (void) setControlsEnabled: (BOOL) flag;

/**
 * Validates whether the inverse relationship button should be
 * enabled and sets it up.
 */
- (void) updateEnablingOfInverseRelationshipSwitch;

@end

@implementation RelationshipEditor (Private)

- (void) setControlsEnabled: (BOOL) flag
{
  [name setEditable: flag];
  [transient setEnabled: flag];
  [optional setEnabled: flag];
  [destinationEntity setEnabled: flag];

  [maxCount setEditable: flag];
  [minCount setEditable: flag];
  [toMany setEnabled: flag];
}

- (void) updateEnablingOfInverseRelationshipSwitch
{
  NSEntityDescription * destEntity;

  [inverseRelationship removeAllItems];

  destEntity = [relationship destinationEntity];
  if (destEntity != nil)
    {
      [inverseRelationship setEnabled: YES];

      [inverseRelationship addItemWithTitle: @""];
      [inverseRelationship addItemsWithTitles: [[[destEntity
        relationshipsByName] allKeys]
        sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]];

      [inverseRelationship selectItemWithTitle: [[relationship
        inverseRelationship] name]];
    }
  else
    {
      [inverseRelationship setEnabled: NO];
    }
}

@end

@implementation RelationshipEditor

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(relationship);
  TEST_RELEASE(entity);
  TEST_RELEASE(configuration);

  [super dealloc];
}

- (id) initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
	if ((self = [super initWithModel: aModel document: aDocument]))
    {
      [NSBundle loadNibNamed: @"RelationshipEditor" owner: self];

      // watch for changes in the entity's property list - in case
      // the relationship we're editing is removed, reset our display.
      [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(notePropertiesChanged:)
               name: PropertiesDidChangeNotification
             object: model];

    }
	return self;
}


- (void) setupWithRelationship: (NSRelationshipDescription *) aRelationship
                      inEntity: (NSEntityDescription *) anEntity
                 configuration: (NSString *) aConfiguration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  if (relationship != nil)
    {
      [nc removeObserver: self];
    }

  ASSIGN(relationship, aRelationship);
  ASSIGN(entity, anEntity);
  ASSIGN(configuration, aConfiguration);

  if (relationship != nil)
    {
      [nc addObserver: self
             selector: @selector(noteRelationshipChanged:)
                 name: PropertyDidChangeNotification
               object: relationship];
      [self setControlsEnabled: YES];
    }
  else
    {
      [self setControlsEnabled: NO];
    }

  [self refresh: nil];
}

- (void) refresh: sender
{
  NSArray * entityNames;

  if (configuration == nil)
    {
      entityNames = [[[model entitiesByName] allKeys]
        sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    }
  else
    {
      entityNames = [[[model entitiesByNameForConfiguration: configuration]
        allKeys] sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)];
    }

  [name setStringValue: [relationship name]];
  [transient setState: [relationship isTransient]];
  [optional setState: [relationship isOptional]];

  [maxCount setIntValue: [relationship maxCount]];
  [minCount setIntValue: [relationship minCount]];
  [toMany setState: [relationship isToMany]];
  [deleteRule selectItemAtIndex: [relationship deleteRule]];

  [destinationEntity removeAllItems];
  [destinationEntity addItemWithTitle: @""];
  [destinationEntity addItemsWithTitles: entityNames];
  [destinationEntity selectItemWithTitle: [[relationship
    destinationEntity] name]];

  [self updateEnablingOfInverseRelationshipSwitch];
}

- (void) updateTransient: (id)sender
{
  [[document undoManager] setActionName: [transient state] ?
    _(@"Set Transient") : _(@"Unset Transient")];
  [document setTransient: [transient state] ofProperty: relationship];
}


- (void) updateName: (id)sender
{
  NSString * newName = [name stringValue];

  if ([newName length] == 0)
    {
      NSRunAlertPanel(_(@"Invalid name"),
        _(@"You must specify a name for the relationship."),
        nil, nil, nil);
      return;
    }

  if ([[[entity propertiesByName] allKeys] containsObject: newName])
    {
      NSRunAlertPanel(_(@"Name already in use"),
        _(@"The name you have entered is already in use."),
        nil, nil, nil);
      return;
    }

  [[document undoManager] setActionName: _(@"Rename Relationship")];
  [document setName: newName
         ofProperty: relationship
           inEntity: entity
      configuration: configuration];
}


- (void) updateOptional: (id)sender
{
  [[document undoManager] setActionName: [optional state] ?
    _(@"Set Optional") : _(@"Unset Optional")];
  [document setOptional: [optional state] ofProperty: relationship];
}

- (void) noteRelationshipChanged: (NSNotification *) notif
{
  if (relationship == [notif object])
    {
      [self refresh: nil];
    }
}

- (void) updateDestinationEntity: sender
{
  NSDictionary * entitiesByName;

  if (configuration == nil)
    {
      entitiesByName = [model entitiesByName];
    }
  else
    {
      entitiesByName = [model entitiesByNameForConfiguration: configuration];
    }

  [[document undoManager] setActionName: _(@"Set Destination Entity")];
  [document setDestinationEntity: [entitiesByName objectForKey:
    [destinationEntity titleOfSelectedItem]]
                  ofRelationship: relationship];

  [self updateEnablingOfInverseRelationshipSwitch];
}

- (void) updateInverseRelationship: sender
{
  if ([inverseRelationship indexOfSelectedItem] > 0)
    {
      NSEntityDescription * destEntity;
      NSRelationshipDescription * invRelationship;

      destEntity = [relationship destinationEntity];
      NSAssert(destEntity != nil, _(@"Destination entity not found."));

      invRelationship = [[destEntity relationshipsByName] objectForKey:
        [inverseRelationship titleOfSelectedItem]];
      NSAssert(invRelationship != nil, _(@"Inverse relationship not found."));

      [[document undoManager] setActionName: _(@"Set Inverse Relationship")];
      [document setInverseRelationship: invRelationship
                        ofRelationship: relationship];
    }
  else
    {
      [[document undoManager] setActionName: _(@"Unset Inverse Relationship")];
      [document setInverseRelationship: nil ofRelationship: relationship];
    }
}

- (void) updateMaxCount: sender
{
  int value = [maxCount intValue];

  if (value >= [relationship minCount])
    {
      [[document undoManager] setActionName: _(@"Set Maximum Count")];
      [document setMaxCount: value ofRelationship: relationship];

      [toMany setState: [relationship isToMany]];
    }
  else
    {
      NSRunAlertPanel(_(@"Invalid value"),
        _(@"You must specify an integer greater than or equal to "
          @"the minumum count."), nil, nil, nil);
    }
}

- (void) updateMinCount: sender
{
  int value = [minCount intValue];

  if (value <= [relationship maxCount])
    {
      [[document undoManager] setActionName: _(@"Set Minimum Count")];
      [document setMinCount: value ofRelationship: relationship];
    }
  else
    {
      NSRunAlertPanel(_(@"Invalid value"),
        _(@"You must specify an integer lower than or equal to "
          @"the maximum count."), nil, nil, nil);
    }
}

- (void) updateToMany: sender
{
  if ([toMany state] == YES)
    {
      [[document undoManager] setActionName: _(@"Set To Many")];
      [document setMaxCount: 2 ofRelationship: relationship];
    }
  else
    {
      [[document undoManager] setActionName: _(@"Unset To Many")];
       // this may need to be set lower too
      if ([relationship minCount] > 1)
        {
          [document setMinCount: 1 ofRelationship: relationship];
        }
      [document setMaxCount: 1 ofRelationship: relationship];
    }
}

- (void) updateDeleteRule: sender
{
  [[document undoManager] setActionName: _(@"Set Delete Rule")];
  [document setDeleteRule: [deleteRule indexOfSelectedItem]
           ofRelationship: relationship];
}

- (void) notePropertiesChanged: (NSNotification *) notif
{
  // reset our display if the relationship we've been editing has been removed
  if (![[entity properties] containsObject: relationship])
    {
      [self setupWithRelationship: nil
                         inEntity: nil
                    configuration: nil];
    }
}

@end
