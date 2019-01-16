/*
    ModelView.h

    Interface declaration of the ModelView class for the DataBuilder
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

#import <AppKit/NSView.h>

@class NSString,
       NSButton,
       NSNotification;

@class NSPropertyDescription,
       NSEntityDescription,
       NSManagedObjectModel;

@class EntityView, Connection;

extern const unsigned int ModelViewGridStep;

/**
 * This view displays a number of EntityView's. It can display in these
 * modes:
 *
 * - Relationship view: In this mode the view displays all entities in
 *      a configuration of a particular model. The user can re-arrange
 *      the entities in the view by dragging their titles. Clicking on
 *      an entity or an entity's property will select it and send an
 *      action to the target. Additionally, if the selected property is
 *      a relationship, an arrow pointing to the relationship's target
 *      will be drawn as well.
 *
 * - Inheritance view: This mode doesn't display anything until an entity
 *      is selected by the user in the browser of the document window.
 *      This view then builds an inheritance tree showing all ancestors
 *      and descendents of the selected entity. The user can click on any
 *      of the shown entities to display it's inheritance tree, and thus
 *      easily navigate an even large inheritance diagram.
 *        In this mode the user can't re-arrange the entities around the
 *      view, nor selecte any property.
 */
@interface ModelView : NSView
{
  id target;
  SEL action;

  NSManagedObjectModel * model;
  NSString * configuration;
  NSEntityDescription * selectedEntity;
  NSPropertyDescription * selectedProperty;

  // the connections being displayed
  NSArray * connections;

  /**
   * This dictionary is arranged like this:
   *
   * {
   *   ConfigurationName = (
   *     EntityView1, EntityView2, ...
   *   );
   * }
   *
   * It caches the views used to display entities so that when the user
   * re-arranges them, then switches to some other configuration, and
   * back to the original one, the entities stay on the positions where
   * the user placed them. The default configuration is keyed against
   * an NSNull.
   */
  NSMutableDictionary * cachedEntityViews;

  enum {
    RelationshipView,
    InheritanceView
  } displayMode;

  BOOL showsAConfiguration;
}

- initWithFrame: (NSRect) frame;

- (void) drawRect: (NSRect) r;

/**
 * Resizes the receiver to fit all views contained in it and fill
 * the entire scroll view that contains it.
 */
- (void) sizeToFit;

// refreshes the receiver's display to reflect the latest state of the model
- (void) refreshDisplay: sender;

- (void) setModel: (NSManagedObjectModel *) aModel;
- (NSManagedObjectModel *) model;

- (void) setShowsNoConfiguration;

- (void) setConfiguration: (NSString *) aConfiguration;
- (NSString *) configuration;

- (void) setSelectedEntity: (NSEntityDescription *) anEntity;
- (NSEntityDescription *) selectedEntity;

- (void) setSelectedProperty: (NSPropertyDescription *) aProperty;
- (NSPropertyDescription *) selectedProperty;

- (void) setTarget: target;
- target;

- (void) setAction: (SEL) action;
- (SEL) action;

- (NSView *) headerView;
- (NSView *) cornerView;

- (void) mouseDown: (NSEvent *) ev;

- (void) updateDisplayMode: sender;

// message sent when the list of configurations in the model changes
- (void) noteConfigurationsChanged: (NSNotification *) notif;
// message sent when the name of a configuration in the model changes
- (void) noteConfigurationNameChanged: (NSNotification *) notif;
// message sent when the list of entities in a configuration changes
- (void) noteEntitiesChanged: (NSNotification *) notif;
// message sent when the list of properties of a particular entity changed
- (void) notePropertiesChanged: (NSNotification *) notif;

// action sent by an entity view when it is selected (or one of it's
// properties is)
- (void) entityViewSelected: (EntityView *) sender;

@end
