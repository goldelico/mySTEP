/*
    EntityView.h

    Interface declaration of the EntityView class for the DataBuilder
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
#import <Foundation/Foundation.h>

@class NSManagedObjectModel, NSEntityDescription, NSPropertyDescription;
@class NSDictionary;
@class NSTextFieldCell;
@class NSNotification;

/**
 * This view represents an entity. It shows the entity's name and a list
 * of all it's attributes (with type information) and relationships.
 * The user drag the entity view around with the mouse and select
 * the entity's properties from the displayd list.
 *
 * When the view and/or one of the properties of the entity is selected,
 * it sends an action message to it's target.
 */
@interface EntityView : NSView
{
  NSTextFieldCell * titleCell;

  // NSCells keyed to the respective property name
  NSDictionary * attributeCells,
               * fetchedPropertyCells,
               * relationshipCells;

  NSEntityDescription * entity;
  NSPropertyDescription * selectedProperty;

  // properties of the entity with which we have registered notifications
  NSMutableArray * knownProperties;

  BOOL isSelected;
  BOOL allowsDragging;
  BOOL allowsPropertySelection;

  id target;
  SEL action;
}

/**
 * Designated initializer.
 */
- initWithEntity: (NSEntityDescription *) entity
         inModel: (NSManagedObjectModel *) model;

/**
 * Returns the entity the receiver represents.
 */
- (NSEntityDescription *) entity;

/**
 * Sets the selected property in the receiver.
 */
- (void) setSelectedProperty: (NSPropertyDescription *) aProperty;

/**
 * Returns the currently selected property in the receiver or `nil'
 * if no property is selected. See also -[EntityView setSelectedProperty:].
 */
- (NSPropertyDescription *) selectedProperty;

/**
 * Sets whether the user can drag the receiver around with the mouse.
 */
- (void) setAllowsDragging: (BOOL) flag;

/**
 * Returns YES if the user can drag the receiver around with the mouse,
 * NO otherwise. See also -[EntityView setAllowsDragging:].
 */
- (BOOL) allowsDragging;

/// Sets whether the user can select properties in the view with the mouse.
- (void) setAllowsPropertySelection: (BOOL) flag;

/**
 * Returns YES if the user can selected properties in the receiver, NO
 * otherwise. See also -[EntityView setAllowsPropertySelection:].
 */
- (BOOL) allowsPropertySelection;

/**
 * Forces the receiver to refresh it's display to reflect the latest state
 * of the entity and all it's properties.
 */
- (void) refresh: sender;

// notifications
- (void) noteEntityChanged: (NSNotification *) notif;
- (void) noteEntityPropertiesChanged: (NSNotification *) notif;

/**
 * Sets whether the receiver draws itself in a selected or deselected state.
 */
- (void) setSelected: (BOOL) flag;

/**
 * Returns YES if the receiver is selected, NO otherwise. See also
 * -[EntityView setSelected:].
 */
- (BOOL) isSelected;

/// An action that will select the receiver.
- (void) select: sender;

/// An action that will deselect the receiver.
- (void) deselect: sender;

/**
 * Sets the target of the receiver.
 */
- (void) setTarget: aTarget;

/**
 * Returns the target of the receiver. See also -[EntityView setTarget:].
 */
- target;

/**
 * Sets the action message to send to the receiver's target when the receiver
 * and/or one of the entity's properties is selected.
 */
- (void) setAction: (SEL) anAction;

/// Returns the action of the receiver. See also -[EntityView setAction:].
- (SEL) action;

@end
