/*
    ModelView.h

    Implementation of the ModelView class for the DataBuilder application.

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

#import <Foundation/Foundation.h>
#import "ModelView.h"

#import <AppKit/NSButton.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSClipView.h>
// #import <AppKit/PSOperators.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSMatrix.h>

#import <Foundation/NSDebug.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSNotification.h>

#import <CoreData/CoreData.h>

#import "NSGeometryAdditions.h"
#import "NSViewAdditions.h"
#import "EntityView.h"
#import "Connection.h"
#import "Document.h"

/// The ModelViewGridStep by which entities can be moved around.
const unsigned int ModelViewGridStep = 10;
static const float BorderOffset = 20;

/**
 * Draws the background grid in the view.
 */
static void
DrawGridInRect(NSRect r)
{
  static const float lightGray = 0.9,
                     darkGray = 0.8;

  unsigned int i, max;
#if USE_PS
  PSsetgray(lightGray);
#else
  [[NSColor colorWithCalibratedWhite:lightGray alpha:1.0] set];
#endif
  for (i = NSMinX(r) - ((unsigned) NSMinX(r) % ModelViewGridStep),
         max = NSMaxX(r);
       i <= max;
       i += ModelViewGridStep)
    {
#if USE_PS
      PSmoveto(i, r.origin.y);
      PSrlineto(0, r.size.height);
      PSstroke();
#else
	  [NSBezierPath strokeLineFromPoint:NSMakePoint(i, r.origin.y) toPoint:NSMakePoint(i, r.origin.y+r.size.height)];
#endif
    }

#if USE_PS
  PSsetgray(darkGray);
#else
  [[NSColor colorWithCalibratedWhite:darkGray alpha:1.0] set];
#endif
  for (i = NSMinX(r) - ((unsigned) NSMinX(r) % (10 * ModelViewGridStep)),
         max = NSMaxX(r);
       i <= max;
       i += (10 * ModelViewGridStep))
    {
#if USE_PS
      PSmoveto(i, r.origin.y);
      PSrlineto(0, r.size.height);
      PSstroke();
#else
	  [NSBezierPath strokeLineFromPoint:NSMakePoint(i, r.origin.y) toPoint:NSMakePoint(i, r.origin.y+r.size.height)];
#endif
    }

#if USE_PS
  PSsetgray(lightGray);
#else
  [[NSColor colorWithCalibratedWhite:lightGray alpha:1.0] set];
#endif
  for (i = NSMinY(r) - ((unsigned) NSMinY(r) % ModelViewGridStep),
         max = NSMaxY(r);
       i <= max;
       i += ModelViewGridStep)
    {
#if USE_PS
     PSmoveto(r.origin.x, i);
      PSrlineto(r.size.width, 0);
      PSstroke();
#else
	  [NSBezierPath strokeLineFromPoint:NSMakePoint(i, r.origin.y) toPoint:NSMakePoint(i+r.size.width, r.origin.y)];
#endif
    }

#if USE_PS
  PSsetgray(darkGray);
#else
  [[NSColor colorWithCalibratedWhite:darkGray alpha:1.0] set];
#endif
  for (i = NSMinY(r) - ((unsigned) NSMinY(r) % (10 * ModelViewGridStep)),
         max = NSMaxY(r);
       i <= max;
       i += (10 * ModelViewGridStep))
    {
#if USE_PS
	  PSmoveto(r.origin.x, i);
      PSrlineto(r.size.width, 0);
      PSstroke();
#else
	  [NSBezierPath strokeLineFromPoint:NSMakePoint(i, r.origin.y) toPoint:NSMakePoint(i+r.size.width, r.origin.y)];
#endif
    }
}

@interface ModelView (Private)

- (void) rebuildRelationshipDisplay;
- (void) rebuildInheritanceDisplay;

- (EntityView *) entityViewDescribingEntity: (NSEntityDescription *) entity;

 // recreates the connection object if a relationship property is selected
- (void) updateRelationshipConnection;

@end

@implementation ModelView

- (void) dealloc
{
  NSDebugLog(@"%@: dealloc", [self className]);

  [[NSNotificationCenter defaultCenter] removeObserver: self];

  TEST_RELEASE(model);
  TEST_RELEASE(configuration);

  TEST_RELEASE(selectedEntity);
  TEST_RELEASE(selectedProperty);

  TEST_RELEASE(connections);
  TEST_RELEASE(cachedEntityViews);

  [super dealloc];
}

- (id) initWithFrame: (NSRect) frame
{
  if ((self = [super initWithFrame: frame]))
    {
      cachedEntityViews = [NSMutableDictionary new];

    }
	return self;
}

- (void) awakeFromNib
{
  [self sizeToFit];
}

- (void) drawRect: (NSRect) r
{
  [[NSColor whiteColor] set];
  NSRectFill(r);

  DrawGridInRect(r);

  [connections makeObjectsPerformSelector: @selector(draw)];
}

- (void) sizeToFit
{
  NSEnumerator * e;
  NSView * subview;
  NSRect rect = NSZeroRect;
  NSScrollView * sv;

  // pass through all views and find out the minimum size we need to have
  // to include them all
  e = [[self subviews] objectEnumerator];
  while ((subview = [e nextObject]) != nil)
    {
      NSRect viewRect = [subview frame];

      rect = NSUnionRect(rect, viewRect);
    }

  // put some border so that some views aren't pushed to an extreme edge
  rect.origin.x -= BorderOffset;
  rect.origin.y -= BorderOffset;
  rect.size.width += 2*BorderOffset;
  rect.size.height += 2*BorderOffset;

  sv = [self enclosingScrollView];
  if (sv != nil)
    {
      NSSize diff;
      NSSize clipViewSize = [[sv contentView] frame].size;

      if (rect.size.width < clipViewSize.width)
        {
          if (NSMaxX(rect) > clipViewSize.width)
            diff.width = NSMaxX(rect) - clipViewSize.width;
          else if (NSMinX(rect) < 0)
            diff.width = NSMinX(rect);
          else
            diff.width = 0;
        }
      else
        diff.width = rect.origin.x;

      if (rect.size.height < clipViewSize.height)
        {
          if (NSMaxY(rect) > clipViewSize.height)
            diff.height = NSMaxY(rect) - clipViewSize.height;
          else if (NSMinY(rect) < 0)
            diff.height = NSMinY(rect);
          else
            diff.height = 0;
        }
      else
        diff.height = rect.origin.y;

      // push around all subviews to fit inside
      e = [[self subviews] objectEnumerator];
      while ((subview = [e nextObject]) != nil)
        {
          NSRect r;

          r = [subview frame];
          r.origin.x -= diff.width;
          r.origin.y -= diff.height;
          [subview setFrame: r];
        }

      rect.origin.x = 0;
      rect.origin.y = 0;
      if (rect.size.width < clipViewSize.width)
        rect.size.width = clipViewSize.width;
      if (rect.size.height < clipViewSize.height)
        rect.size.height = clipViewSize.height;
    }
  else
    {
      e = [[self subviews] objectEnumerator];
      while ((subview = [e nextObject]) != nil)
        {
          NSRect r;

          r = [subview frame];
          r.origin.x -= rect.origin.x;
          r.origin.y -= rect.origin.y;
          [subview setFrame: r];
        }

      rect.origin.x = [self frame].origin.x;
      rect.origin.y = [self frame].origin.y;
    }

  [self setFrame: rect];
  [self setNeedsDisplay: YES];
}

- (void) refreshDisplay: sender
{
  [[self subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
  DESTROY(connections);

  if (model != nil)
    {
      switch (displayMode)
        {
        case RelationshipView:
          [self rebuildRelationshipDisplay];
          break;

        case InheritanceView:
          [self rebuildInheritanceDisplay];
          break;
        }
    }
}

- (void) setShowsNoConfiguration
{
  [[self subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];

  DESTROY(connections);
  DESTROY(selectedEntity);
  DESTROY(selectedProperty);

  showsAConfiguration = NO;
}

- (void) setModel: (NSManagedObjectModel *) aModel
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  [nc removeObserver: self];
  ASSIGN(model, aModel);

  [self setShowsNoConfiguration];

  [nc addObserver: self
         selector: @selector(noteConfigurationsChanged:)
             name: ConfigurationsDidChangeNotification
           object: model];
  [nc addObserver: self
         selector: @selector(noteConfigurationNameChanged:)
             name: ConfigurationNameDidChangeNotification
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

- (NSManagedObjectModel *) model
{
  return model;
}

- (void) setConfiguration: (NSString *) aConfiguration
{
  if (showsAConfiguration &&
    ((configuration == nil && aConfiguration == nil) ||
    [configuration isEqualToString: aConfiguration]))
    {
      return;
    }
  else
    {
      ASSIGN(configuration, aConfiguration);
      [self refreshDisplay: nil];
      showsAConfiguration = YES;
    }
}

- (NSString *) configuration
{
  return configuration;
}

- (void) setSelectedEntity: (NSEntityDescription *) anEntity
{
  [self setSelectedProperty: nil];

  ASSIGN(selectedEntity, anEntity);

  switch (displayMode)
    {
    case RelationshipView:
      {
        NSEnumerator * e;
        EntityView * entityView;

        // select the proper entity view
        e = [[self subviews] objectEnumerator];
        while ((entityView = [e nextObject]) != nil)
          {
            if ([entityView entity] == anEntity)
              {
                [entityView setSelected: YES];
              }
            else
              {
                [entityView setSelected: NO];
              }
          }
      }
      break;
    case InheritanceView:
      // rebuild the inheritance display
      [[self subviews] makeObjectsPerformSelector:
        @selector(removeFromSuperview)];
      [self rebuildInheritanceDisplay];
      break;
    }
}

- (NSEntityDescription *) selectedEntity
{
  return selectedEntity;
}

- (void) setSelectedProperty: (NSPropertyDescription *) aProperty
{
  NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];

  // make sure notifications get set up properly
  if (selectedProperty != nil)
    {
      [nc removeObserver: self
                    name: PropertyDidChangeNotification
                  object: selectedProperty];
    }
  ASSIGN(selectedProperty, aProperty);
  if (selectedProperty != nil)
    {
      [nc addObserver: self
             selector: @selector(updateRelationshipConnection)
                 name: PropertyDidChangeNotification
               object: selectedProperty];
    }

  if (displayMode == RelationshipView)
    {
      EntityView * entityView = [self entityViewDescribingEntity:
        selectedEntity];

      [entityView setSelectedProperty: selectedProperty];
      [self updateRelationshipConnection];
    }
}

- (NSPropertyDescription *) selectedProperty
{
  return selectedProperty;
}

- (void) setTarget: _target
{
  target = _target;
}

- target
{
  return target;

}

- (void) setAction: (SEL) _action
{
  action = _action;
}

- (SEL) action
{
  return action;
}

static const float buttonSize = 22;

- (NSView *) headerView
{
  NSRect superviewFrame = [[self superview] frame];
  NSMatrix * matrix;
  NSButtonCell * cell;
  NSView * headerView;
  NSButton * titleView;

  headerView = [[[NSView alloc] initWithFrame: NSMakeRect(0, 0,
    superviewFrame.size.width, buttonSize)] autorelease];
  [headerView setAutoresizingMask: NSViewWidthSizable | NSViewHeightSizable];

  cell = [[NSButtonCell new] autorelease];
  [cell setImagePosition: NSImageOnly];
  [cell setButtonType: NSPushOnPushOffButton];

  matrix = [[[NSMatrix alloc] initWithFrame: NSMakeRect(0, 0,
    2 * buttonSize, buttonSize)]
    autorelease];
  [matrix setAutoresizingMask: NSViewHeightSizable];

  [matrix setPrototype: cell];

  [matrix setMode: NSRadioModeMatrix];
  [matrix setAutosizesCells: YES];
  [matrix setIntercellSpacing: NSZeroSize];
  [matrix setCellSize: NSMakeSize(buttonSize, buttonSize)];
  [matrix setTarget: self];
  [matrix setAction: @selector(updateDisplayMode:)];

  [matrix addColumn];
  cell = [matrix cellAtRow:0 column: 0];
  [cell setImage: [NSImage imageNamed: @"RelationshipView"]];
  [cell setTag: 0];

  [matrix addColumn];
  cell = [matrix cellAtRow:0 column: 1];
  [cell setImage: [NSImage imageNamed: @"InheritanceView"]];
  [cell setTag: 1];

  [matrix sizeToCells];

  [headerView addSubview: matrix];

  titleView = [[[NSButton alloc]
    initWithFrame: NSMakeRect(2*buttonSize, 0, superviewFrame.size.width -
    2 * buttonSize, buttonSize)]
    autorelease];
  [titleView setTitle: @""];
  [titleView setEnabled: NO];
  [headerView addSubview: titleView];

  return headerView;
}

- (NSView *) cornerView
{
  NSButton * cornerView = [[[NSButton alloc]
    initWithFrame: NSMakeRect(0, 0, [NSScroller scrollerWidth]+1, buttonSize)]
    autorelease];

  [cornerView setTitle: @""];
  [cornerView setEnabled: NO];

  return cornerView;
}

- (void) resizeWithOldSuperviewSize: (NSSize)oldSize
{
  [self sizeToFit];
}

- (BOOL) acceptsFirstResponder
{
  return YES;
}

- (BOOL) becomeFirstResponder
{
  [self entityViewSelected: nil];

  return YES;
}

- (void) mouseDown: (NSEvent *) ev
{
  [self setSelectedEntity: nil];

  if ([target respondsToSelector: action])
    {
      [target performSelector: action withObject: self];
    }
}

- (void) updateDisplayMode: sender
{
  int mode = [[sender selectedCell] tag];

  if (mode != (int) displayMode)
    {
      displayMode = mode;
      [self refreshDisplay: nil];
    }
}

- (void) noteConfigurationsChanged: (NSNotification *) notif
{
  if (configuration != nil && ![[model configurations] containsObject: configuration])
    {
      [self setShowsNoConfiguration];
    }
}

- (void) noteConfigurationNameChanged: (NSNotification *) notif
{
  NSDictionary * userInfo = [notif userInfo];
  NSString * oldName = [userInfo objectForKey: @"OldName"],
           * newName = [userInfo objectForKey: @"NewName"];

  if ([configuration isEqualToString: oldName])
    {
      ASSIGN(configuration, newName);
    }
}

- (void) noteEntitiesChanged: (NSNotification *) notif
{
  NSString * config = [[notif userInfo] objectForKey: @"Configuration"];

  if ((configuration == nil && config == nil) ||
    [configuration isEqualToString: config])
    {
      [self refreshDisplay: nil];
    }
}

- (void) notePropertiesChanged: (NSNotification *) notif
{
  NSEntityDescription * entity = [[notif userInfo] objectForKey: @"Entity"];

  if (entity == selectedEntity)
    {
      if (selectedProperty != nil &&
        ![[selectedEntity properties] containsObject: selectedProperty])
        {
          [self setSelectedProperty: nil];
        }
    }
}

- (void) entityViewSelected: (EntityView *) sender
{
  NSEnumerator * e;
  EntityView * entityView;

  ASSIGN(selectedEntity, [sender entity]);
  switch (displayMode)
    {
    case RelationshipView:
      [self setSelectedProperty: [sender selectedProperty]];

      // deselect all other entity views
      e = [[self subviews] objectEnumerator];
      while ((entityView = [e nextObject]) != nil)
        {
          if (entityView != sender)
            {
              [entityView setSelected: NO];
            }
        }
      break;
    case InheritanceView:
      [self refreshDisplay: nil];
      break;
    }

  if ([target respondsToSelector: action])
    {
      [target performSelector: action withObject: self];
    }
}

@end

@implementation ModelView (Private)

- (void) rebuildRelationshipDisplay
{
  NSMutableSet * entities, * modelledEntities;
  NSMutableArray * entityViews;
  NSEnumerator * e;
  NSEntityDescription * entity;
  unsigned int i, n;
  NSRect myFrame = [self frame];

  [[self subviews] makeObjectsPerformSelector: @selector(removeFromSuperview)];
  DESTROY(connections);

  // get the configuration's entities and the corresponding cached
  // entity views
  if (configuration == nil)
    {
      entities = [NSMutableSet setWithArray: [model entities]];
      entityViews = [cachedEntityViews objectForKey: [NSNull null]];
    }
  else
    {
      entities = [NSMutableSet setWithArray: [model
        entitiesForConfiguration: configuration]];
      entityViews = [cachedEntityViews objectForKey: configuration];
    }

  // create a new cache if necessary
  if (entityViews == nil)
    {
      entityViews = [NSMutableArray arrayWithCapacity: [entities count]];
      if (configuration == nil)
        {
          [cachedEntityViews setObject: entityViews
                                forKey: [NSNull null]];
        }
      else
        {
          [cachedEntityViews setObject: entityViews
                                forKey: configuration];
        }
    }

  // this is the set of entities which are already modelled in entity views
  modelledEntities = [NSMutableSet setWithCapacity: 1];

  // sort out entity views who's entities aren't in the model anymore
  for (i=0, n = [entityViews count]; i<n; i++)
    {
      EntityView * entityView = [entityViews objectAtIndex: i];
      NSEntityDescription * entity = [entityView entity];

      if ([entities containsObject: entity] == NO)
        {
          [entityViews removeObjectAtIndex: i];
          i--;
          n--;
        }
      else
        {
          [modelledEntities addObject: entity];
          [self addSubview: entityView];

          // selection may have changed in the mean time
          if ([entityView entity] == selectedEntity)
            {
              [entityView setSelected: YES];
              [entityView setSelectedProperty: selectedProperty];
            }
          else
            {
              [entityView setSelected: NO];
            }
        }
    }

  // now create entity views for entities which have been
  // added in the mean time
  [entities minusSet: modelledEntities];
  e = [entities objectEnumerator];
  while ((entity = [e nextObject]) != nil)
    {
      EntityView * entityView;
      NSRect r;

      entityView = [[[EntityView alloc]
        initWithEntity: entity inModel: model]
        autorelease];

      // selection may have changed in the mean time
      if (entity == selectedEntity)
        {
          [entityView setSelected: YES];
          [entityView setSelectedProperty: selectedProperty];
        }
      else
        {
          [entityView setSelected: NO];
        }

      [entityView setTarget: self];
      [entityView setAction: @selector(entityViewSelected:)];

      r = [entityView frame];
      r.origin.y = BorderOffset;
      r.origin.x = BorderOffset;

      // shift around the new entity view so long until it doesn't overlap
      // with anything anymore
      for (i=0; [self containsSubviewOverlappingWithRect: r]; i++)
        {
          r.origin.x += r.size.width + BorderOffset;
          if (myFrame.size.width > r.size.width + 2*BorderOffset &&
            NSMaxX(r) > myFrame.size.width)
            {
              r.origin.y += r.size.height + BorderOffset;
              r.origin.x = BorderOffset;
            }
        }

      [entityView setFrame: r];

      [self addSubview: entityView];
      [entityViews addObject: entityView];
    }

  [self sizeToFit];
  [self updateRelationshipConnection];
}

- (void) rebuildInheritanceDisplay
{
  static const float entitySkip = 50;
  NSEntityDescription * entity;
  EntityView * entityView, * subentityView;
  NSMutableArray * newConnections;

  if (selectedEntity == nil)
    {
      return;
    }

  // create an entity view for the selected entity first
  entityView = [[[EntityView alloc]
    initWithEntity: selectedEntity inModel: model]
    autorelease];
  [entityView setAllowsDragging: NO];
  [entityView setAllowsPropertySelection: NO];
  [entityView setSelected: YES];
  [self addSubview: entityView];

  newConnections = [NSMutableArray array];

  // now create entity views for all superentities
  for (entity = [selectedEntity superentity], subentityView = entityView;
       entity != nil;
       entity = [entity superentity], subentityView = entityView)
    {
      NSRect frame;
      Connection * conn;

      entityView = [[[EntityView alloc]
        initWithEntity: entity inModel: model]
        autorelease];
      [entityView setAllowsDragging: NO];
      [entityView setAllowsPropertySelection: NO];
      [entityView setTarget: self];
      [entityView setAction: @selector(entityViewSelected:)];

      frame = [entityView frame];
      frame.origin.y = NSMaxY([subentityView frame]) + entitySkip;
      [entityView setFrame: frame];
      [self addSubview: entityView];

      conn = [[Connection new] autorelease];
      [conn setView1: subentityView];
      [conn setView2: entityView];
      [conn setView2ArrowStyle: SingleArrowStyle];

      [newConnections addObject: conn];
    }

  // and finally process subentities
  // TODO

  ASSIGNCOPY(connections, newConnections);
  [self sizeToFit];
  [self setNeedsDisplay: YES];
}

- (EntityView *) entityViewDescribingEntity: (NSEntityDescription *) entity
{
  NSEnumerator * e = [[self subviews] objectEnumerator];
  EntityView * entityView;

  while ((entityView = [e nextObject]) != nil)
    {
      if ([entityView entity] == entity)
        return entityView;
    }

  return nil;
}

- (void) updateRelationshipConnection
{
  NSEntityDescription * destEntity;

  // remove the old connection and repaint over it's area
  if ([connections count] == 1)
    {
      [self setNeedsDisplayInRect:
      [[connections objectAtIndex: 0] drawingRect]];
    }
  DESTROY(connections);

  // if we've selected a relationship and it has a destination entity
  // create a connection between them
  if (displayMode == RelationshipView &&
    [selectedProperty isKindOfClass: [NSRelationshipDescription class]] &&
    (destEntity = [(NSRelationshipDescription *) selectedProperty
          destinationEntity]) != nil)
    {
      NSRelationshipDescription
        * relationship =
          (NSRelationshipDescription *) selectedProperty,
        * invRelationship = [relationship inverseRelationship];
      EntityView * view1, * view2;
      Connection * connection;

      view1 = [self entityViewDescribingEntity: selectedEntity];
      view2 = [self entityViewDescribingEntity: destEntity];

      connection = [[Connection new] autorelease];
      [connection setView1: view1];
      [connection setView2: view2];

      ASSIGN(connections, [NSArray arrayWithObject: connection]);

      // set up cardinality on the connection
      if ([relationship isToMany])
        {
          [connection setView2ArrowStyle: DoubleArrowStyle];
        }
      else
        {
          [connection setView2ArrowStyle: SingleArrowStyle];
        }

      if (invRelationship != nil)
        {
          if ([invRelationship isToMany])
            {
              [connection setView1ArrowStyle: DoubleArrowStyle];
            }
          else
            {
              [connection setView1ArrowStyle: SingleArrowStyle];
            }
        }

      // repaint us
      [self setNeedsDisplayInRect: [connection drawingRect]];
    }
}

- (void) setNeedsDisplayInRect: (NSRect) r
{
  [super setNeedsDisplayInRect: r];

  if (displayMode == RelationshipView && [connections count] == 1)
    {
      [super setNeedsDisplayInRect: [[connections objectAtIndex: 0]
        drawingRect]];
    }
}

@end
