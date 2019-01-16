/*
    FetchedPropertyEditor.m

    Implementation of the FetchedPropertyEditor class for the DataBuilder
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

#import "FetchedPropertyEditor.h"

#import "Document.h"

@interface FetchedPropertyEditor (Private)

- (void) setControlsEnabled: (BOOL) flag;

@end

@implementation FetchedPropertyEditor (Private)

- (void) setControlsEnabled: (BOOL) flag
{
  [name setEditable: flag];
  [transient setEnabled: flag];
  [optional setEnabled: flag];
}

@end

@implementation FetchedPropertyEditor

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(fetchedProperty);
  TEST_RELEASE(entity);
  TEST_RELEASE(configuration);

  [super dealloc];
}

- (id) initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
	if ((self = [super initWithModel: aModel document: aDocument]))
    {
      [NSBundle loadNibNamed: @"FetchedPropertyEditor" owner: self];

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

- (void) setupWithFetchedProperty: (NSFetchedPropertyDescription *)
  aFetchedProperty
                         inEntity: (NSEntityDescription *) anEntity
                    configuration: (NSString *) aConfiguration
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  if (fetchedProperty != nil)
    {
      [nc removeObserver: self
                    name: PropertyDidChangeNotification
                  object: fetchedProperty];
    }

  ASSIGN(fetchedProperty, aFetchedProperty);
  ASSIGN(entity, anEntity);
  ASSIGN(configuration, aConfiguration);

  [self refresh: nil];

  if (fetchedProperty != nil)
    {
      [nc addObserver: self
             selector: @selector(notePropertyChanged:)
                 name: PropertyDidChangeNotification
               object: fetchedProperty];

      [self setControlsEnabled: YES];
    }
  else
    {
      [self setControlsEnabled: NO];
    }
}

- (void) refresh: sender
{
  [name setStringValue: [fetchedProperty name]];

  [transient setState: [fetchedProperty isTransient]];
  [optional setState: [fetchedProperty isOptional]];
}

- (void) updateTransient: (id)sender
{
  [[document undoManager] setActionName: [transient state] ?
    _(@"Set Transient") : _(@"Unset Transient")];
  [document setTransient: [transient state] ofProperty: fetchedProperty];
}


- (void) updateName: (id)sender
{
  NSString * newName = [name stringValue];

  if ([newName length] == 0)
    {
      NSRunAlertPanel(_(@"Invalid name"),
        _(@"You must specify a name for the fetched property."),
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


  [[document undoManager] setActionName: _(@"Rename Fetched Property")];
  [document setName: newName
         ofProperty: fetchedProperty
           inEntity: entity
      configuration: configuration];
}


- (void) updateOptional: (id)sender
{
  [[document undoManager] setActionName: [optional state] ?
    _(@"Set Optional") : _(@"Unset Optional")];
  [document setOptional: [optional state] ofProperty: fetchedProperty];
}

- (void) notePropertyChanged: (NSNotification *) notif
{
  if (fetchedProperty == [notif object])
    {
      [self refresh: nil];
    }
}

- (void) notePropertiesChanged: (NSNotification *) notif
{
  // reset our display if the attribute we've been editing has been removed
  if (![[entity properties] containsObject: fetchedProperty])
    {
      [self setupWithFetchedProperty: nil
                            inEntity: nil
                       configuration: nil];
    }
}

@end
