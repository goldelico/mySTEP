/*
    AttributeEditor.m

    Implementation of the AttributeEditor class for the DataBuilder
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

#import "AttributeEditor.h"

#import "Document.h"

@interface AttributeEditor (Private)

- (void) setControlsEnabled: (BOOL) flag;

@end

@implementation AttributeEditor (Private)

- (void) setControlsEnabled: (BOOL) flag
{
  [type setEnabled: flag];
  [valueClassName setEditable: flag];
  [name setEditable: flag];
  [transient setEnabled: flag];
  [optional setEnabled: flag];
}

@end

@implementation AttributeEditor

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(attribute);
  TEST_RELEASE(entity);
  TEST_RELEASE(configuration);

  [super dealloc];
}

- (id) initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
  if ((self = [super initWithModel: aModel document: aDocument]))
    {
      [NSBundle loadNibNamed: @"AttributeEditor" owner: self];

      // watch for changes in the entity's property list - in case
      // the attribute we're editing is removed, reset our display
      [[NSNotificationCenter defaultCenter]
        addObserver: self
           selector: @selector(notePropertiesChanged:)
               name: PropertiesDidChangeNotification
             object: model];

    }
	return self;
}

- (void) setupWithAttribute: (NSAttributeDescription *) anAttribute
                   inEntity: (NSEntityDescription *) anEntity
              configuration: (NSString *) aConfiguration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  if (attribute != nil)
    {
      [nc removeObserver: self
                    name: PropertyDidChangeNotification
                  object: attribute];
    }

  ASSIGN(attribute, anAttribute);
  ASSIGN(entity, anEntity);
  ASSIGN(configuration, aConfiguration);

  [self refresh: nil];

  if (attribute != nil)
    {
      [nc addObserver: self
             selector: @selector(noteAttributeChanged:)
                 name: PropertyDidChangeNotification
               object: attribute];

      [self setControlsEnabled: YES];
    }
  else
    {
      [self setControlsEnabled: NO];
    }
}

- (void) refresh: sender
{
  switch ([attribute attributeType])
    {
    case NSUndefinedAttributeType:
      [type selectItemAtIndex: 0];
      break;
    case NSInteger16AttributeType:
      [type selectItemAtIndex: 1];
      break;
    case NSInteger32AttributeType:
      [type selectItemAtIndex: 2];
      break;
    case NSInteger64AttributeType:
      [type selectItemAtIndex: 3];
      break;
    case NSDecimalAttributeType:
      [type selectItemAtIndex: 4];
      break;
    case NSDoubleAttributeType:
      [type selectItemAtIndex: 5];
      break;
    case NSFloatAttributeType:
      [type selectItemAtIndex: 6];
      break;
    case NSStringAttributeType:
      [type selectItemAtIndex: 7];
      break;
    case NSBooleanAttributeType:
      [type selectItemAtIndex: 8];
      break;
    case NSDateAttributeType:
      [type selectItemAtIndex: 9];
      break;
    case NSBinaryDataAttributeType:
      [type selectItemAtIndex: 10];
      break;
    }

  [name setStringValue: [attribute name]];
  [valueClassName setStringValue: [attribute attributeValueClassName]];

  [transient setState: [attribute isTransient]];
  [optional setState: [attribute isOptional]];
}

- (void) updateValueClassName: (id)sender
{
  [[document undoManager] setActionName: _(@"Set Attribute Value Class Name")];
  [document setAttributeValueClassName: [valueClassName stringValue]
                           ofAttribute: attribute];
}


- (void) updateType: (id)sender
{
  [[document undoManager] setActionName: _(@"Set Attribute Type")];

  switch ([type indexOfSelectedItem])
    {
    case 0:
      [document setAttributeType: NSUndefinedAttributeType
                     ofAttribute: attribute];
      break;
    case 1:
      [document setAttributeType: NSInteger16AttributeType
                     ofAttribute: attribute];
      break;
    case 2:
      [document setAttributeType: NSInteger32AttributeType
                     ofAttribute: attribute];
      break;
    case 3:
      [document setAttributeType: NSInteger64AttributeType
                     ofAttribute: attribute];
      break;
    case 4:
      [document setAttributeType: NSDecimalAttributeType
                     ofAttribute: attribute];
      break;
    case 5:
      [document setAttributeType: NSDoubleAttributeType
                     ofAttribute: attribute];
      break;
    case 6:
      [document setAttributeType: NSFloatAttributeType
                     ofAttribute: attribute];
      break;
    case 7:
      [document setAttributeType: NSStringAttributeType
                     ofAttribute: attribute];
      break;
    case 8:
      [document setAttributeType: NSBooleanAttributeType
                     ofAttribute: attribute];
      break;
    case 9:
      [document setAttributeType: NSDateAttributeType
                     ofAttribute: attribute];
      break;
    case 10:
      [document setAttributeType: NSBinaryDataAttributeType
                     ofAttribute: attribute];
      break;
    }
}


- (void) updateTransient: (id)sender
{
  [[document undoManager] setActionName: [transient state] ?
    _(@"Set Transient") : _(@"Unset Transient")];
  [document setTransient: [transient state] ofProperty: attribute];
}


- (void) updateName: (id)sender
{
  NSString * newName = [name stringValue];

  if ([newName length] == 0)
    {
      NSRunAlertPanel(_(@"Invalid name"),
        _(@"You must specify a name for the attribute."),
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

  [[document undoManager] setActionName: _(@"Rename attribute")];
  [document setName: newName
         ofProperty: attribute
           inEntity: entity
      configuration: configuration];
}


- (void) updateOptional: (id)sender
{
  [[document undoManager] setActionName: [optional state] ?
    _(@"Set Optional") : _(@"Unset Optional")];
  [document setOptional: [optional state] ofProperty: attribute];
}

- (void) noteAttributeChanged: (NSNotification *) notif
{
  if (attribute == [notif object])
    {
      [self refresh: nil];
    }
}

- (void) notePropertiesChanged: (NSNotification *) notif
{
  // reset our display if the attribute we've been editing has been removed
  if (![[entity properties] containsObject: attribute])
    {
      [self setupWithAttribute: nil
                      inEntity: nil
                 configuration: nil];
    }
}

@end
