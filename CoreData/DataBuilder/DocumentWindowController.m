/*
    DocumentWindowController.m

    Implementation of the DocumentWindowController class for the DataBuilder
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

#import "DocumentWindowController.h"

#import <CoreData/CoreData.h>

#import "Document.h"
#import "AttributeEditor.h"
#import "EntityEditor.h"
#import "ConfigurationEditor.h"
#import "FetchedPropertyEditor.h"
#import "RelationshipEditor.h"

#import "NSFontAdditions.h"

#import "ModelView.h"

// the browser column meanings
#define ROOT_COLUMN                     0

#define CONFIGS_AND_FETCHES_COLUMN      1

#define ENTITIES_COLUMN                 2

#define PROPERTIES_COLUMN               3

// configurations are in row 0, fetch requests in row 1
#define CONFIGURATIONS_ROW              0
#define FETCH_REQUESTS_ROW              1

@implementation DocumentWindowController

- (void) createRootBrowserColumnInMatrix: (NSMatrix *) matrix
{
  NSBrowserCell * cell;
  NSFont * boldFont = [NSFont boldSystemFontOfSize: 0];

  [matrix addRow];
  cell = [matrix cellAtRow: 0 column: 0];
  [cell setTitle: _(@"Configurations")];
  [cell setFont: boldFont];
  [cell setLeaf: NO];

  [matrix addRow];
  cell = [matrix cellAtRow: 1 column: 0];
  [cell setTitle: _(@"Fetch Requests")];
  [cell setFont: boldFont];
  [cell setLeaf: NO];
}

- (void) createConfigurationListInMatrix: (NSMatrix *) matrix
{
  NSBrowserCell * cell;
  NSEnumerator * e;
  NSString * configName;
  unsigned int i;

  [matrix addRow];
  cell = [matrix cellAtRow: 0 column: 0];
  [cell setTitle: _(@"Default")];
  [cell setFont: [NSFont italicSystemFontOfSize: 0]];
  [cell setLeaf: NO];

  e = [[[[(Document *) [self document] model] configurations] 
    sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
    objectEnumerator];
  for (i=1; (configName = [e nextObject]) != nil; i++)
    {
      [matrix addRow];
      cell = [matrix cellAtRow: i column: 0];
      [cell setTitle: configName];
      [cell setLeaf: NO];
    }
}

- (void) createFetchRequestListInMatrix: (NSMatrix *) matrix
{
  // TODO
}

- (void) createEntityListInMatrix: (NSMatrix *) matrix
{
  NSString * configuration = [self selectedConfiguration];
  NSManagedObjectModel * model = [(Document *) [self document] model];
  NSEnumerator * e;
  NSString * entityName;
  unsigned int i;

  if (configuration == nil)
    {
      e = [[[[model entitiesByName] allKeys] sortedArrayUsingSelector:
        @selector(caseInsensitiveCompare:)] objectEnumerator];
    }
  else
    {
      e = [[[[model entitiesByNameForConfiguration: configuration] allKeys]
        sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
        objectEnumerator];
    }

  for (i=0; (entityName = [e nextObject]) != nil; i++)
    {
      NSBrowserCell * cell;

      [matrix addRow];
      cell = [matrix cellAtRow: i column: 0];
      [cell setTitle: entityName];
      [cell setLeaf: NO];
    }
}

- (void) createPropertyListInMatrix: (NSMatrix *) matrix
{
  NSEntityDescription * entity = [self selectedEntityFromConfiguration:
    [self selectedConfiguration]];
  NSDictionary * propertiesByName = [entity propertiesByName];
  NSEnumerator * e = [[[propertiesByName allKeys] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)] objectEnumerator];
  NSString * propertyName;
  unsigned int i;
  Class attributeClass = [NSAttributeDescription class],
        fetchedPropertyClass = [NSFetchedPropertyDescription class];
  NSFont * boldFont = [NSFont boldSystemFontOfSize: 0],
         * italicFont = [NSFont italicSystemFontOfSize: 0];

  for (i=0; (propertyName = [e nextObject]) != nil; i++)
    {
      NSBrowserCell * cell;
      NSPropertyDescription * property = [propertiesByName objectForKey:
        propertyName];

      [matrix addRow];
      cell = [matrix cellAtRow: i column: 0];
      [cell setTitle: [property name]];
      [cell setLeaf: YES];
      if ([property isKindOfClass: attributeClass])
        {
          [cell setFont: boldFont];
        }
      else if ([property isKindOfClass: fetchedPropertyClass])
        {
          [cell setFont: italicFont];
        }
    }
}

- (NSString *) selectedConfiguration
{
  int row = [browser selectedRowInColumn: CONFIGS_AND_FETCHES_COLUMN];

  if (row == 0)
    {
      return nil;
    }
  else
    {
      return [[[browser matrixInColumn: CONFIGS_AND_FETCHES_COLUMN]
        cellAtRow: row column: 0] title];
    }
}

- (NSEntityDescription *) selectedEntityFromConfiguration:
  (NSString *) configuration
{
  NSString * entityName = [[[browser matrixInColumn: ENTITIES_COLUMN]
    cellAtRow: [browser selectedRowInColumn: ENTITIES_COLUMN] column: 0]
    title];

  if (configuration == nil)
    {
      return [[[(Document *) [self document] model]
        entitiesByName] objectForKey: entityName];
    }
  else
    {
      return [[[(Document *) [self document] model]
        entitiesByNameForConfiguration: configuration]
        objectForKey: entityName];
    }
}

- (NSPropertyDescription *) selectedPropertyFromEntity:
  (NSEntityDescription *) entity
{
  return [[entity propertiesByName] objectForKey: [[[browser
    matrixInColumn: PROPERTIES_COLUMN] cellAtRow: [browser
    selectedRowInColumn: PROPERTIES_COLUMN] column: 0]
    title]];
}

- (BOOL) configurationsBranchSelected
{
  return ([browser selectedRowInColumn: ROOT_COLUMN] == CONFIGURATIONS_ROW);
}

- (BOOL) aConfigurationIsSelected
{
  return ([browser selectedRowInColumn: CONFIGS_AND_FETCHES_COLUMN] >= 0);
}

- (BOOL) anEntityIsSelected
{
  return ([browser selectedRowInColumn: ENTITIES_COLUMN] >= 0);
}

- (void) dealloc
{
  NSDebugLog(@"%@: dealloc", [self className]);

  [[NSNotificationCenter defaultCenter] removeObserver: self];

  [super dealloc];
}

- (void) awakeFromNib
{
  [browser setMaxVisibleColumns: 5];
  [browser setTitled: YES];
  [modelView setModel: [(Document *) [self document] model]];
}

- (void)      browser: (NSBrowser *) sender
  createRowsForColumn: (int) column
             inMatrix: (NSMatrix *) matrix
{
  switch (column)
    {
    case ROOT_COLUMN:
      [self createRootBrowserColumnInMatrix: matrix];
      break;

    case CONFIGS_AND_FETCHES_COLUMN:
      if ([self configurationsBranchSelected])
        {
          [self createConfigurationListInMatrix: matrix];
        }
      else
        {
          [self createFetchRequestListInMatrix: matrix];
        }
      break;

    case ENTITIES_COLUMN:
      [self createEntityListInMatrix: matrix];
      break;

    case PROPERTIES_COLUMN:
      [self createPropertyListInMatrix: matrix];
      break;
    }
}

- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column
{
  switch (column)
    {
    case ROOT_COLUMN:
      return _(@"Data Model");
    default:
      if ([self configurationsBranchSelected])
        {
          switch (column)
            {
            case CONFIGS_AND_FETCHES_COLUMN:
              return _(@"Configurations");
            case ENTITIES_COLUMN:
              return _(@"Entities");
            case PROPERTIES_COLUMN:
              return _(@"Properties");
            default:
              return nil;
            }
        }
      else
        {
          return _(@"Fetch Requests");
        }
    }
}

- (void) setModel: (NSManagedObjectModel *) model
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  [modelView setModel: model];
  [browser setPath: @"/"];
  [self updateSelectionDisplay: browser];

  [nc removeObserver: self];

  [nc addObserver: self
         selector: @selector(noteConfigurationsChanged:)
             name: ConfigurationsDidChangeNotification
           object: model];

  [nc addObserver: self
         selector: @selector(noteEntitiesChanged:)
             name: EntitiesDidChangeNotification
           object: model];

  [nc addObserver: self
         selector: @selector(notePropertiesChanged:)
             name: PropertiesDidChangeNotification
           object: model];
}

- (void) addConfiguration: sender
{
  [(Document *) [self document] addNewConfiguration];
}

- (void) addEntity: sender
{
  [(Document *) [self document] addNewEntityToConfiguration: [self
    selectedConfiguration]];
}

- (void) addAttribute: sender
{
  NSString * configuration = [self selectedConfiguration];

  [(Document *) [self document]
    addNewAttributeToEntity: [self selectedEntityFromConfiguration:
    configuration]
            inConfiguration: configuration];
}

- (void) addFetchedProperty: sender
{
  NSString * configuration = [self selectedConfiguration];

  [(Document *) [self document]
    addNewFetchedPropertyToEntity: [self selectedEntityFromConfiguration:
    configuration]
                  inConfiguration: configuration];
}

- (void) addRelationship: sender
{
  NSString * configuration = [self selectedConfiguration];

  [(Document *) [self document]
    addNewRelationshipToEntity: [self selectedEntityFromConfiguration:
    configuration]
            inConfiguration: configuration];
}

- (void) updateSelectionDisplay: sender
{
  ModelEditor * modelEditor;

  if (sender == browser)
    {
      if ([self configurationsBranchSelected] &&
        [self aConfigurationIsSelected])
        {
          NSString * configuration = [self selectedConfiguration];
          NSEntityDescription * entity = [self
            selectedEntityFromConfiguration: configuration];
          NSPropertyDescription * property = [self
            selectedPropertyFromEntity: entity];

          if (property != nil)
            {
              if ([property isKindOfClass: [NSAttributeDescription class]])
                {
                  modelEditor = [(Document *) [self document] attributeEditor];
                  [[(Document *) [self document] attributeEditor]
                    setupWithAttribute: (NSAttributeDescription *) property
                              inEntity: entity
                         configuration: configuration];
                }
              else if ([property isKindOfClass: [NSFetchedPropertyDescription
                class]])
                {
                  modelEditor = [(Document *) [self document]
                    fetchedPropertyEditor];
                  [(FetchedPropertyEditor *) modelEditor
                    setupWithFetchedProperty: (NSFetchedPropertyDescription *)
                    property
                                    inEntity: entity
                               configuration: configuration];
                }
              else if ([property isKindOfClass: [NSRelationshipDescription
                class]])
                {
                  modelEditor = [(Document *) [self document]
                    relationshipEditor];
                  [[(Document *) [self document] relationshipEditor]
                    setupWithRelationship: (NSRelationshipDescription *) property
                                 inEntity: entity
                            configuration: configuration];
                }
              else
                {
                  // unsupported property type
                  modelEditor = nil;
                  NSLog(_(@"Unknown/unsupported property type %@ "
                          @"encountered."), [property className]);
                }
            }
          else if (entity != nil)
            {
              modelEditor = [(Document *) [self document] entityEditor];
              [[(Document *) [self document] entityEditor]
                setupWithEntity: entity inConfiguration: configuration];
            }
          else if (configuration != nil)
            {
              modelEditor = [(Document *) [self document] configurationEditor];
              [[(Document *) [self document] configurationEditor]
                setupWithConfiguration: configuration];
            }
          else
            {
              modelEditor = nil;
            }

          [modelView setConfiguration: configuration];
          [modelView setSelectedEntity: entity];
          [modelView setSelectedProperty: property];
        }
      else
        {
          modelEditor = nil;
        }
    }
  else if (sender == modelView)
    {
      NSString * configuration = [modelView configuration];
      NSString * configurationBrowserName;
      NSEntityDescription * entity;
      NSPropertyDescription * property;

      if (configuration == nil)
        configurationBrowserName = _(@"Default");
      else
        configurationBrowserName = configuration;

      entity = [modelView selectedEntity];
      property = [modelView selectedProperty];
      if (property != nil)
        {
          NSAssert(entity != nil, _(@"Unknown entity selected."));

          [browser setPath: [NSString stringWithFormat: @"/%@/%@/%@/%@",
            _(@"Configurations"), configurationBrowserName, [entity name],
            [property name]]];

          if ([property isKindOfClass: [NSAttributeDescription class]])
            {
              modelEditor = [(Document *) [self document] attributeEditor];
              [(AttributeEditor *) modelEditor
                setupWithAttribute: (NSAttributeDescription *) property
                          inEntity: entity
                     configuration: configuration];
            }
          else if ([property isKindOfClass: [NSFetchedPropertyDescription
            class]])
            {
              modelEditor = [(Document *) [self document]
                fetchedPropertyEditor];
              [(FetchedPropertyEditor *) modelEditor
                setupWithFetchedProperty: (NSFetchedPropertyDescription *)
                property
                                inEntity: entity
                           configuration: configuration];
            }
          else if ([property isKindOfClass: [NSRelationshipDescription class]])
            {
              modelEditor = [(Document *) [self document] relationshipEditor];
              [(RelationshipEditor *) modelEditor
                setupWithRelationship: (NSRelationshipDescription *) property
                             inEntity: entity
                        configuration: configuration];
            }
          else
            {
              // unsupported property type
              modelEditor = nil;
              NSLog(_(@"Unknown/unsupported property type %@ encountered."),
                [property className]);
            }
        }
      else if (entity != nil)
        {
          [browser setPath: [NSString stringWithFormat: @"/%@/%@/%@",
            _(@"Configurations"), configurationBrowserName, [entity name]]];

          modelEditor = [(Document *) [self document] entityEditor];
          [(EntityEditor *) modelEditor
            setupWithEntity: entity
            inConfiguration: [modelView configuration]];
        }
      else
        {
          [browser setPath: [NSString stringWithFormat: @"/%@/%@",
            _(@"Configurations"), configurationBrowserName]];

          if ([modelView configuration] != nil)
            {
              modelEditor = [(Document *) [self document] configurationEditor];
              [(ConfigurationEditor *) modelEditor setupWithConfiguration:
                [modelView configuration]];
            }
          else
            {
              modelEditor = nil;
            }
        }
    }
  else
    {
      [NSException raise: NSInternalInconsistencyException
                  format: _(@"%@ invoked by unknown sender."),
        NSStringFromSelector(_cmd)];

      return;
    }

  if (modelEditor != nil)
    {
      if ([box contentView] != [modelEditor view])
        {
          [box setContentView: [modelEditor view]];
          editorViewSet = YES;
        }
    }
  else if (editorViewSet)
    {
      [box setContentView: [[NSView new] autorelease]];
      editorViewSet = NO;
    }
}

- (void) delete: sender
{
  if ([self configurationsBranchSelected] && [self aConfigurationIsSelected])
    {
      NSString * configuration = [self selectedConfiguration];
      NSEntityDescription * entity = [self selectedEntityFromConfiguration:
        configuration];
      NSPropertyDescription * property = [self selectedPropertyFromEntity:
        entity];
      NSUndoManager * undoManager = [[self document] undoManager];

      if (property != nil)
        {
          if ([property isKindOfClass: [NSAttributeDescription class]])
            {
              [undoManager setActionName: _(@"Delete Attribute")];
            }
          else
            {
              [undoManager setActionName: _(@"Delete Relationship")];
            }
          [(Document *) [self document] removeProperty: property
                                            fromEntity: entity
                                       inConfiguration: configuration];
        }
      else if (entity != nil)
        {
          [undoManager setActionName: _(@"Delete Entity")];
          [(Document *) [self document] removeEntity: entity
                                   fromConfiguration: configuration];
        }
      else
        {
          NSAssert(configuration != nil, _(@"Tried to remove default "
            @"configuration."));

          [undoManager setActionName: _(@"Delete Configuration")];
          [(Document *) [self document] setEntities: nil
                                   forConfiguration: configuration];
        }
    }

  [self updateSelectionDisplay: browser];
}

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem
{
  SEL action = [menuItem action];

  if (sel_eq(action, @selector(addConfiguration:)))
    {
      if ([self configurationsBranchSelected])
        {
          return YES;
        }
      else
        {
          return NO;
        }
    }
  else if (sel_eq(action, @selector(addEntity:)))
    {
      if ([self configurationsBranchSelected] &&
        [self aConfigurationIsSelected])
        {
          return YES;
        }
      else
        {
          return NO;
        }
    }
  else if (sel_eq(action, @selector(addAttribute:)) ||
           sel_eq(action, @selector(addFetchedProperty:)) ||
           sel_eq(action, @selector(addRelationship:)))
    {
      if ([self configurationsBranchSelected] &&
        [self anEntityIsSelected])
        {
          return YES;
        }
      else
        {
          return NO;
        }
    }
  else if (sel_eq(action, @selector(delete:)))
    {
      if ([self configurationsBranchSelected] &&
        [self aConfigurationIsSelected])
        {
          NSString * configuration = [self selectedConfiguration];

          if (configuration != nil || [self selectedEntityFromConfiguration:
            configuration] != nil)
            {
              return YES;
            }
          else
            {
              return NO;
            }
        }
      else
        {
          return NO;
        }
    }
  else
    {
	  return NO;
//      return [super validateMenuItem: (NSMenuItem *) menuItem];
    }
}

- (void) noteConfigurationsChanged: (NSNotification *) notif
{
  if ([self configurationsBranchSelected])
    {
      [browser reloadColumn: CONFIGS_AND_FETCHES_COLUMN];
    }
}

- (void) noteEntitiesChanged: (NSNotification *) notif
{
  if ([self configurationsBranchSelected])
    {
      NSString * configuration = [[notif userInfo] objectForKey:
        @"Configuration"];
      NSString * selectedConfiguration = [self selectedConfiguration];

      if ((configuration == nil && selectedConfiguration == nil) ||
        [configuration isEqualToString: selectedConfiguration])
        {
          [browser reloadColumn: ENTITIES_COLUMN];
        }
    }
}

- (void) notePropertiesChanged: (NSNotification *) notif
{
  if ([self configurationsBranchSelected])
    {
      NSDictionary * userInfo = [notif userInfo];
      NSString * configuration = [userInfo objectForKey: @"Configuration"];
      NSString * selectedConfiguration = [self selectedConfiguration];

      if ((configuration == nil && selectedConfiguration == nil) ||
        [configuration isEqualToString: selectedConfiguration])
        {
          NSEntityDescription * entity = [userInfo objectForKey: @"Entity"];

          if ([entity isEqual: [self selectedEntityFromConfiguration:
            selectedConfiguration]])
            {
              [browser reloadColumn: PROPERTIES_COLUMN];
            }
        }
    }
}

@end

@implementation NSManagedObjectModel (Private)

- (NSDictionary *) entitiesByNameForConfiguration: (NSString *) configuration
{
	NSArray * entities = [self entitiesForConfiguration: configuration];
	NSMutableDictionary * entitiesByName = [NSMutableDictionary
    dictionaryWithCapacity: [entities count]];
	NSEnumerator * e = [entities objectEnumerator];
	NSEntityDescription * entity;
	
	while ((entity = [e nextObject]) != nil)
		{
		[entitiesByName setObject: entity forKey: [entity name]];
		}
	
	return [[entitiesByName copy] autorelease];
}

@end

