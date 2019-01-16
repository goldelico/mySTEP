/*
    DocumentWindowController.h

    Interface declaration of the DocumentWindowController class for
    the DataBuilder application.

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

#import <AppKit/NSWindowController.h>
#import <AppKit/NSMenu.h>
#import <CoreData/CoreData.h>

@class NSString, NSNotification;
@class NSBrowser, NSBox, NSScrollView;
@class NSMatrix;

@class ModelView, ModelEditor;

/**
 * Main document window controller.
 */

@interface DocumentWindowController : NSWindowController
{
  IBOutlet NSBrowser * browser;
  IBOutlet ModelView * modelView;
  IBOutlet NSBox * box;
  IBOutlet NSScrollView * scrollView;

  BOOL editorViewSet;
}

- (void)      browser: (NSBrowser *) sender
  createRowsForColumn: (int) column
             inMatrix: (NSMatrix *) matrix;
- (NSString *) browser: (NSBrowser *)sender titleOfColumn: (int)column;

- (void) setModel: (NSManagedObjectModel *) aModel;

// menu actions
- (void) addConfiguration: sender;
- (void) addEntity: sender;
- (void) addAttribute: sender;
- (void) addFetchedProperty: sender;
- (void) addRelationship: sender;
- (void) delete: sender;

/**
 * Action invoked by the browser and model view when selection changes.
 */
- (void) updateSelectionDisplay: sender;

- (BOOL) validateMenuItem: (id <NSMenuItem>) menuItem;

- (void) noteConfigurationsChanged: (NSNotification *) notif;
- (void) noteEntitiesChanged: (NSNotification *) notif;
- (void) notePropertiesChanged: (NSNotification *) notif;

- (void) createRootBrowserColumnInMatrix: (NSMatrix *) matrix;
- (void) createConfigurationListInMatrix: (NSMatrix *) matrix;
- (void) createEntityListInMatrix: (NSMatrix *) matrix;
- (void) createPropertyListInMatrix: (NSMatrix *) matrix;

- (NSString *) selectedConfiguration;
- (NSEntityDescription *) selectedEntityFromConfiguration:
	(NSString *) configuration;
- (NSPropertyDescription *) selectedPropertyFromEntity:
	(NSEntityDescription *) entity;

- (BOOL) configurationsBranchSelected;
- (BOOL) aConfigurationIsSelected;
- (BOOL) anEntityIsSelected;

@end

