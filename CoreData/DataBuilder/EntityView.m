/*
    EntityView.m

    Implementation of the EntityView class for the DataBuilder
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

#import "EntityView.h"

#import <Foundation/NSNotification.h>
#import <Foundation/NSArray.h>

// #import <AppKit/PSOperators.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSFont.h>

#import <CoreData/CoreData.h>

#import "NSAttributeDescriptionUtilities.h"

#import "Document.h"
#import "ModelView.h"
#import "NSGeometryAdditions.h"

static NSRect MinimalFrame;

// entity view portion dimensions
static const float
  TitleHeight = 17,
  PropertyEntryHeight = 17,
  BottomHeight = 12,
  SideBorder = 7,
  SeparatorHeight = 10;

// the images used to draw the entity's portions
static NSImage
  * entityTop = nil,
  * entityMiddle = nil,
  * entityBottom = nil,
  * entityRelationshipSeparator = nil,
  * entityAttributeSeparator = nil,
  * entityFetchedPropertySeparator = nil,

  * entityTopSelected = nil,
  * entityMiddleSelected = nil,
  * entityBottomSelected = nil,
  * entityAttributeSeparatorSelected = nil,
  * entityFetchedPropertySeparatorSelected = nil,
  * entityRelationshipSeparatorSelected = nil;

/**
 * Draws an array of cells in the provided view. The cells are tiled above
 * each other, starting at startOffset. Before the cell is drawn, `background'
 * is composited below it. The vertical skip between two cells is determined
 * by the vertical size of `background'. Drawing is clipped to `clipRect'.
 *
 * @param cells An array of NSCell objects which to draw.
 * @param view The view in which to draw the cells.
 * @param background The background image which composite below each cell.
 * @param startOffset The start offset at which to start drawing the cells.
 *              The array of cells should contain them in top-to-bottom order.
 *              This function will draw them in reversed order automatically.
 * @param clipView The view to which to clip drawing. Cells which don't
 *              intersect with this rect won't be drawn.
 */
static void
DrawCells(NSDictionary * cells, NSView * view, NSImage * background,
          NSPoint startOffset, NSRect clipRect)
{
  NSSize backgroundSize = [background size];
  NSRect r;
  NSString * cellName;
  NSEnumerator * e = [[[cells allKeys] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)] reverseObjectEnumerator];

  for (r = NSMakeRect(startOffset.x, startOffset.y,
                      backgroundSize.width, backgroundSize.height);
       (cellName = [e nextObject]) != nil;
       r.origin.y += r.size.height)
    {
      NSCell * cell = [cells objectForKey: cellName];

      if (!NSIsEmptyRect(NSIntersectionRect(r, clipRect)))
        {
          NSRect cellFrame;

          [background compositeToPoint: r.origin
                             operation: NSCompositeSourceOver];
          cellFrame = r;
          cellFrame.origin.x += SideBorder;
          cellFrame.size.width -= 2*SideBorder;
          [cell drawWithFrame: cellFrame inView: view];
        }
    }
}

/**
 * Composites `separator' to `point' iff it's drawing area intersects
 * with `clipRect'.
 */
static inline void
DrawSeparator (NSImage * separator, NSPoint point, NSRect clipRect)
{
  NSSize size = [separator size];

  if (!NSIsEmptyRect(NSIntersectionRect(NSMakeRect(point.x, point.y,
    size.width, size.height), clipRect)))
    {
      [separator compositeToPoint: point operation: NSCompositeSourceOver];
    }
}

/**
 * Loads the images with which we draw the background of an entity view
 * if they haven't been already loaded.
 */
static inline void
LoadImagesIfNecessary(void)
{
  if (entityTop == nil)
    {
      entityTop = [NSImage imageNamed: @"EntityUpper"];
      entityMiddle = [NSImage imageNamed: @"EntityMiddle"];
      entityBottom = [NSImage imageNamed: @"EntityLower"];
      entityAttributeSeparator = [NSImage imageNamed: @"EntityAttrSeparator"];
      entityFetchedPropertySeparator = [NSImage
        imageNamed: @"EntityFetchedPropSeparator"];
      entityRelationshipSeparator = [NSImage imageNamed: @"EntityRelSeparator"];
    }
}

/**
 * Same as `LoadImagesIfNecessary', but loads the images to draw the
 * selected state of an EntityView.
 */
static inline void
LoadSelectedImagesIfNecessary(void)
{
  if (entityTopSelected == nil)
    {
      entityTopSelected = [NSImage imageNamed: @"EntityUpper_sel"];
      entityMiddleSelected = [NSImage imageNamed: @"EntityMiddle_sel"];
      entityBottomSelected = [NSImage imageNamed: @"EntityLower_sel"];
      entityAttributeSeparatorSelected = [NSImage
        imageNamed: @"EntityAttrSeparator_sel"];
      entityFetchedPropertySeparatorSelected = [NSImage
        imageNamed: @"EntityFetchedPropSeparator_sel"];
      entityRelationshipSeparatorSelected = [NSImage
        imageNamed: @"EntityRelSeparator_sel"];
    }
}

@interface NSEntityDescription (Private)

- (NSDictionary *) fetchedPropertiesByName;

@end

@implementation NSEntityDescription (Private)

- (NSDictionary *) fetchedPropertiesByName
{
	Class aClass = [NSFetchedPropertyDescription class];
	NSMutableDictionary * dict;
	NSEnumerator * e;
	NSPropertyDescription * property;
	NSArray * properties = [self properties];
	
	dict = [NSMutableDictionary dictionaryWithCapacity: [properties count]];
	e = [properties objectEnumerator];
	while ((property = [e nextObject]) != nil)
		{
		if (aClass == Nil || [property isKindOfClass: aClass])
			{
			[dict setObject: property forKey: [property name]];
			}
		}
	
	return [[dict copy] autorelease];
}

@end

@interface EntityView (Private)

/**
 * Sets up the notifications for our properties to notify us of
 * a change in them.
 */
- (void) resetupPropertyNotifications;

/**
 * If `highlightFlag' is YES, then the NSCell with which the receiver
 * draws `aProperty' will be highlighted, otherwise unhighlighted.
 */
- (void) changeCellDescribingProperty: (NSPropertyDescription *) aProperty
                        toHighlighted: (BOOL) highlightFlag;

/**
 * Does a test to see if any property cell is hit by point `p'.
 *
 * @return The property description of the hit cell, or `nil' if no
 *         property was hit.
 */
- (NSPropertyDescription *) propertyHitByPoint: (NSPoint) p;

@end

@implementation EntityView (Private)

- (void) resetupPropertyNotifications
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
  NSArray * entityProperties = [entity properties];
  NSEnumerator * e;
  NSPropertyDescription * property;
  unsigned int i, n;

  // deregister any any properties from knownProperties which are not in
  // entityProperties anymore
  for (i=0, n = [knownProperties count]; i<n; i++)
    {
      property = [knownProperties objectAtIndex: i];

      if (![entityProperties containsObject: property])
        {
          [nc removeObserver: self
                        name: PropertyDidChangeNotification
                      object: property];
          [knownProperties removeObjectAtIndex: i];
          i--;
          n--;
        }
    }

  // now enumerate through the entityProperties and register
  // notifications with newly added ones properties
  e = [entityProperties objectEnumerator];
  while ((property = [e nextObject]) != nil)
    {
      if (![knownProperties containsObject: property])
        {
          [nc addObserver: self
                 selector: @selector(refresh:)
                     name: PropertyDidChangeNotification
                   object: property];
          [knownProperties addObject: property];
        }
    }
}

- (void) changeCellDescribingProperty: (NSPropertyDescription *) aProperty
                        toHighlighted: (BOOL) highlightFlag
{
  NSTextFieldCell * cell;

  if ([aProperty isKindOfClass: [NSAttributeDescription class]])
    {
      cell = [attributeCells objectForKey: [aProperty name]];
    }
  else if ([aProperty isKindOfClass: [NSFetchedPropertyDescription class]])
    {
      cell = [fetchedPropertyCells objectForKey: [aProperty name]];
    }
  else if ([aProperty isKindOfClass: [NSRelationshipDescription class]])
    {
      cell = [relationshipCells objectForKey: [aProperty name]];
    }
  else
    return; // unknown property type

  if (highlightFlag)
    {
      [cell setTextColor: [NSColor whiteColor]];
    }
  else
    {
      [cell setTextColor: [NSColor blackColor]];
    }

  [self setNeedsDisplay: YES];
}

- (NSPropertyDescription *) propertyHitByPoint: (NSPoint) p
{
  NSRect r = NSMakeRect(SideBorder, 0, [self frame].size.width - 2*SideBorder,
    PropertyEntryHeight);
  unsigned int i, n;
  NSDictionary * propertiesByName = nil;
  NSString * propertyName = nil;

  r.origin.y += BottomHeight;

  // run through the relationships
  for (i=0, n = [relationshipCells count];
       i<n;
       i++, r.origin.y += PropertyEntryHeight)
    {
      if (NSPointInRect(p, r))
        {
          propertiesByName = [entity relationshipsByName];
          propertyName =  [[[propertiesByName allKeys]
            sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
            objectAtIndex: n - i - 1];
        }
    }
  if (n > 0)
    r.origin.y += SeparatorHeight;

  // run through the fetched properties
  for (i=0, n = [fetchedPropertyCells count];
       i<n;
       i++, r.origin.y += PropertyEntryHeight)
    {
      if (NSPointInRect(p, r))
        {
          NSDictionary * fetchedPropertiesByName = [entity fetchedPropertiesByName];

          propertiesByName = [entity fetchedPropertiesByName];
          propertyName =  [[[propertiesByName allKeys]
            sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
            objectAtIndex: n - i - 1];
        }
    }
  if (n > 0)
    r.origin.y += SeparatorHeight;

  // run through the attributes
  for (i=0, n = [attributeCells count];
       i<n;
       i++, r.origin.y += PropertyEntryHeight)
    {
      if (NSPointInRect(p, r))
        {
          propertiesByName = [entity attributesByName];
          propertyName =  [[[propertiesByName allKeys]
            sortedArrayUsingSelector: @selector(caseInsensitiveCompare:)]
            objectAtIndex: n - i - 1];
        }
    }

  // nothing hit
  return [propertiesByName objectForKey: propertyName];
}

@end

@implementation EntityView

+ (void) initialize
{
  if (self == [EntityView class])
    {
      MinimalFrame = NSMakeRect(0, 0, 150, TitleHeight + BottomHeight);
    }
}

- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(titleCell);

  TEST_RELEASE(attributeCells);
  TEST_RELEASE(fetchedPropertyCells);
  TEST_RELEASE(relationshipCells);

  TEST_RELEASE(entity);
  TEST_RELEASE(selectedProperty);

  TEST_RELEASE(knownProperties);

  [super dealloc];
}

- (void) drawRect: (NSRect) drawRect
{
  NSImage * top,
          * middle,
          * bottom,
          * attributeSeparator,
          * fetchedPropertySeparator,
          * relationshipSeparator;
  NSEnumerator * e;
  NSRect r;
  NSTextFieldCell * cell;

  if (isSelected)
    {
      LoadSelectedImagesIfNecessary();

      top = entityTopSelected;
      middle = entityMiddleSelected;
      bottom = entityBottomSelected;
      attributeSeparator = entityAttributeSeparatorSelected;
      fetchedPropertySeparator = entityFetchedPropertySeparatorSelected;
      relationshipSeparator = entityRelationshipSeparatorSelected;
    }
  else
    {
      LoadImagesIfNecessary();

      top = entityTop;
      middle = entityMiddle;
      bottom = entityBottom;
      attributeSeparator = entityAttributeSeparator;
      fetchedPropertySeparator = entityFetchedPropertySeparator;
      relationshipSeparator = entityRelationshipSeparator;
    }

  r = NSMakeRect(0, 0, [self frame].size.width, 0);

  // draw the bottom
  r.size.height = BottomHeight;
  if (!NSIsEmptyRect(NSIntersectionRect(drawRect, r)))
    [bottom compositeToPoint: r.origin operation: NSCompositeSourceOver];
  r.origin.y += r.size.height;

  // draw the properties of the entity
  if ([relationshipCells count] > 0)
    {
      DrawCells(relationshipCells, self, middle, r.origin, drawRect);
      r.origin.y += [relationshipCells count] * PropertyEntryHeight;

      DrawSeparator(relationshipSeparator, r.origin, drawRect);
      r.origin.y += SeparatorHeight;
    }

  if ([fetchedPropertyCells count] > 0)
    {
      DrawCells(fetchedPropertyCells, self, middle, r.origin, drawRect);
      r.origin.y += [fetchedPropertyCells count] * PropertyEntryHeight;

      DrawSeparator(fetchedPropertySeparator, r.origin, drawRect);
      r.origin.y += SeparatorHeight;
    }

  if ([attributeCells count] > 0)
    {
      DrawCells(attributeCells, self, middle, r.origin, drawRect);
      r.origin.y += [attributeCells count] * PropertyEntryHeight;

      DrawSeparator(attributeSeparator, r.origin, drawRect);
      r.origin.y += SeparatorHeight;
    }

  // draw the title area
  r.size.height = TitleHeight;
  if (!NSIsEmptyRect(NSIntersectionRect(drawRect, r)))
    {
      [top compositeToPoint: r.origin operation: NSCompositeSourceOver];
      [titleCell drawWithFrame: r inView: self];
    }
}

- (id) initWithEntity: (NSEntityDescription *) anEntity
         inModel: (NSManagedObjectModel *) model
{
	if ((self = [super initWithFrame: MinimalFrame]))
    {
      NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

      ASSIGN(entity, anEntity);
      knownProperties = [NSMutableArray new];

      [nc addObserver: self
             selector: @selector(noteEntityChanged:)
                 name: EntityDidChangeNotification
               object: entity];
      [nc addObserver: self
             selector: @selector(noteEntityPropertiesChanged:)
                 name: PropertiesDidChangeNotification
               object: model];
      [self resetupPropertyNotifications];

      titleCell = [NSTextFieldCell new];
      [titleCell setBordered: NO];
      [titleCell setDrawsBackground: NO];
      [titleCell setAlignment: NSCenterTextAlignment];

      [self refresh: nil];

      allowsDragging = YES;
      allowsPropertySelection = YES;

    }
	return self;
}

- (NSEntityDescription *) entity
{
  return entity;
}

- (void) setSelectedProperty: (NSPropertyDescription *) aProperty
{
  if (selectedProperty != nil)
    {
      [self changeCellDescribingProperty: selectedProperty toHighlighted: NO];
    }
  ASSIGN(selectedProperty, aProperty);
  if (selectedProperty != nil)
    {
      [self changeCellDescribingProperty: selectedProperty toHighlighted: YES];
    }
}

- (NSPropertyDescription *) selectedProperty
{
  return selectedProperty;
}

- (void) setAllowsDragging: (BOOL) flag
{
  allowsDragging = flag;
}

- (BOOL) allowsDragging
{
  return allowsDragging;
}

- (void) setAllowsPropertySelection: (BOOL) flag
{
  allowsPropertySelection = flag;
}

- (BOOL) allowsPropertySelection
{
  return allowsPropertySelection;
}

- (void) refresh: sender
{
  NSMutableDictionary * cells;
  NSTextFieldCell * prototypeCell;
  NSDictionary * attributesByName,
               * fetchedPropertiesByName,
               * relationshipsByName;
  NSEnumerator * e;
  NSPropertyDescription * property;

  NSString * propertyName;
  float newHeight;

  NSRect frame;

  [titleCell setStringValue: [entity name]];

  attributesByName = [entity attributesByName];
  fetchedPropertiesByName = [entity fetchedPropertiesByName];
  relationshipsByName = [entity relationshipsByName];

  // resize to fit all contents
  frame = [self frame];

  // this is required to make sure the superview redraws our area when
  // we become smaller (otherwise inconsistent areas could result)
  [[self superview] setNeedsDisplayInRect: frame];

  newHeight = TitleHeight + BottomHeight;
  if ([attributesByName count] > 0)
    {
      newHeight += ([attributesByName count] * PropertyEntryHeight);
      newHeight += SeparatorHeight;
    }
  if ([fetchedPropertiesByName count] > 0)
    {
      newHeight += ([fetchedPropertiesByName count] * PropertyEntryHeight);
      newHeight += SeparatorHeight;
    }
  if ([relationshipsByName count] > 0)
    {
      newHeight += ([relationshipsByName count] * PropertyEntryHeight);
      newHeight += SeparatorHeight;
    }
  frame.origin.y -= newHeight - frame.size.height;
  frame.size.height = newHeight;
  [self setFrame: frame];

  prototypeCell = [[NSTextFieldCell new] autorelease];
  [prototypeCell setFont: [NSFont systemFontOfSize:
    [NSFont smallSystemFontSize]]];
  [prototypeCell setBordered: NO];
  [prototypeCell setDrawsBackground: NO];

  // generate cells for attributes
  cells = [NSMutableDictionary dictionaryWithCapacity: [attributesByName
    count]];

  e = [[[attributesByName allKeys] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)] objectEnumerator];
  while ((propertyName = [e nextObject]) != nil)
    {
      NSAttributeDescription * attribute = [attributesByName objectForKey:
        propertyName];
      NSTextFieldCell * cell = [[prototypeCell copy] autorelease];

      [cell setStringValue: [NSString stringWithFormat:
        @"%@ (%@)", propertyName,
        StringFromAttributeType([attribute attributeType])]];
      [cells setObject: cell forKey: propertyName];
    }

  ASSIGNCOPY(attributeCells, cells);

  // generate cells for the fetched properties
  cells = [NSMutableDictionary dictionaryWithCapacity:
    [fetchedPropertiesByName count]];

  e = [[[fetchedPropertiesByName allKeys] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)] objectEnumerator];
  while ((propertyName = [e nextObject]) != nil)
    {
      NSFetchedPropertyDescription * fetchedProperty =
        [fetchedPropertiesByName objectForKey: propertyName];
      NSTextFieldCell * cell = [[prototypeCell copy] autorelease];

      [cell setStringValue: propertyName];
      [cells setObject: cell forKey: propertyName];
    }

  ASSIGNCOPY(fetchedPropertyCells, cells);

  // generate cells for relationships
  cells = [NSMutableDictionary dictionaryWithCapacity:
    [relationshipsByName count]];

  e = [[[relationshipsByName allKeys] sortedArrayUsingSelector:
    @selector(caseInsensitiveCompare:)] objectEnumerator];
  while ((propertyName = [e nextObject]) != nil)
    {
      NSRelationshipDescription * relationship = [relationshipsByName
        objectForKey: propertyName];
      NSTextFieldCell * cell = [[prototypeCell copy] autorelease];
      NSEntityDescription * destinationEntity = [relationship
        destinationEntity];

      // indicate the destination entity if one is set up
      if (destinationEntity != nil)
        {
          [cell setStringValue: [NSString stringWithFormat: @"%@ --> %@",
            propertyName, [destinationEntity name]]];
        }
      else
        {
          [cell setStringValue: propertyName];
        }
      [cells setObject: cell forKey: propertyName];
    }

  ASSIGNCOPY(relationshipCells, cells);

  // and finally redraw us
  [self setNeedsDisplay: YES];

  if (selectedProperty != nil)
    {
      [self changeCellDescribingProperty: selectedProperty
                           toHighlighted: YES];
    }
}

- (void) noteEntityChanged: (NSNotification *) notif
{
  [self refresh: nil];
}

- (void) noteEntityPropertiesChanged: (NSNotification *) notif
{
  if ([[notif userInfo] objectForKey: @"Entity"] == entity)
    {
      if (selectedProperty != nil &&
        ![[entity properties] containsObject: selectedProperty])
        {
          [self setSelectedProperty: nil];
        }

      [self resetupPropertyNotifications];

      [self refresh: nil];
    }
}

- (void) mouseDown: (NSEvent *) ev
{
  NSPoint diff = [self convertPoint: [ev locationInWindow] fromView: nil];
  NSPropertyDescription * hitProperty;

  if (allowsPropertySelection &&
    (hitProperty = [self propertyHitByPoint: diff]) != nil)
    {
      [self setSelectedProperty: hitProperty];
      if ([target respondsToSelector: action])
        {
          [target performSelector: action withObject: self];
        }
    }
  else
    {
      NSWindow * window = [self window];

      // see if the next event is a mouse-up. If yes, the user
      // selected the entity itself, otherwise start dragging.
      ev = [window nextEventMatchingMask: NSAnyEventMask];
      if ([ev type] == NSLeftMouseUp)
        {
          if (selectedProperty != nil)
            {
              [self setSelectedProperty: nil];
              if ([target respondsToSelector: action])
                {
                  [target performSelector: action withObject: self];
                }
            }
        }
      else if (allowsDragging)
        {
          NSRect frame = [self frame];
          NSView * superview = [self superview];

          while ([(ev = [window nextEventMatchingMask: NSAnyEventMask]) type] !=
            NSLeftMouseUp)
            {
              if ([ev type] == NSLeftMouseDragged)
                {
                  NSPoint p = [superview convertPoint: [ev locationInWindow]
                                             fromView: nil];

                  p.x -= diff.x;
                  p.y -= diff.y;

                  p.x = (float) ((int) ((p.x / ModelViewGridStep) + 0.5)) *
                    ModelViewGridStep;
                  p.y = (float) ((int) ((p.y / ModelViewGridStep) + 0.5)) *
                    ModelViewGridStep;

                  [superview setNeedsDisplayInRect: frame];
                  frame.origin = p;
                  [self setFrame: frame];
                  [superview setNeedsDisplayInRect: frame];
                }
            }

          [(ModelView *) [self superview] sizeToFit];
        }
    }
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) becomeFirstResponder
{
  [self select: nil];

  if ([target respondsToSelector: action])
    {
      [target performSelector: action withObject: self];
    }

  return YES;
}

- (void) setSelected: (BOOL) flag
{
  if (isSelected != flag)
    {
      if (flag == NO)
        {
          [self setSelectedProperty: nil];
        }

      isSelected = flag;
      [self setNeedsDisplay: YES];
    }
}

- (BOOL) isSelected
{
  return isSelected;
}

- (void) select: sender
{
  [self setSelected: YES];
}

- (void) deselect: sender
{
  [self setSelected: NO];
}

- (void) setTarget: aTarget
{
  target = aTarget;
}

- target
{
  return target;
}

- (void) setAction: (SEL) anAction
{
  action = anAction;
}

- (SEL) action
{
  return action;
}

@end
