/*
    ConfigurationEditor.m

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

#import "ConfigurationEditor.h"
#import "Document.h"

@implementation ConfigurationEditor

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(configuration);

  [super dealloc];
}

- (id) initWithModel: (NSManagedObjectModel *) aModel
       document: (Document *) aDocument
{
	if ((self = [super initWithModel: aModel document: aDocument]))
    {
      NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

      [NSBundle loadNibNamed: @"ConfigurationEditor" owner: self];

      [nc addObserver: self
             selector: @selector(noteConfigurationsChanged:)
                 name: ConfigurationsDidChangeNotification
               object: model];
      [nc addObserver: self
             selector: @selector(noteConfigurationNameChanged:)
                 name: ConfigurationNameDidChangeNotification
               object: model];

    }
	return self;
}

- (void) setupWithConfiguration: (NSString *) aConfiguration
{
  ASSIGN(configuration, aConfiguration);

  if (configuration != nil)
    {
      [name setStringValue: configuration];
      [name setEditable: YES];
    }
  else
    {
      [name setStringValue: nil];
      [name setEditable: NO];
    }
}

- (void) updateConfigurationName: (id)sender
{
  NSString * newName = [name stringValue];

  if ([newName length] == 0)
    {
      NSRunAlertPanel(_(@"Invalid name"),
        _(@"You must specify a name for the configuration."),
        nil, nil, nil);
      return;
    }

  if ([[[document model] configurations] containsObject: newName])
    {
      NSRunAlertPanel(_(@"Name already in use"),
        _(@"There already is a configuration named \"%@\"."),
        nil, nil, nil, newName);
      return;
    }

  [[document undoManager] setActionName: _(@"Rename Configuration")];
  [document setName: newName ofConfiguration: configuration];
}

- (void) noteConfigurationNameChanged: (NSNotification *) notif
{
  NSDictionary * userInfo = [notif userInfo];
  NSString * oldName = [userInfo objectForKey: @"OldName"],
           * newName = [userInfo objectForKey: @"NewName"];

  if ([oldName isEqualToString: configuration])
    {
      [self setupWithConfiguration: newName];
    }
}

- (void) noteConfigurationsChanged: (NSNotification *) notif
{
  if (configuration != nil && ![[[document model] configurations]
    containsObject: configuration])
    {
      [self setupWithConfiguration: nil];
    }
}

@end
