/** <title>NSOutlineView</title>

<abstract>The outline class.</abstract>

Copyright (C) 2001 Free Software Foundation, Inc.

Author:  Gregory John Casamento <greg_casamento@yahoo.com>
Date: October 2001

This file is part of the GNUstep GUI Library.

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Library General Public
License as published by the Free Software Foundation; either
version 2 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Library General Public License for more details.

You should have received a copy of the GNU Library General Public
License along with this library; see the file COPYING.LIB.
If not, write to the Free Software Foundation,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSNull.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSIndexSet.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSOutlineView.h>
#import <AppKit/NSScroller.h>
#import <AppKit/NSTableColumn.h>
#import <AppKit/NSTableHeaderView.h>
#import <AppKit/NSText.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSWindow.h>

static NSNotificationCenter *nc = nil;
// static const int current_version = 1;

//int NSOutlineViewDropOnItemIndex = -1;

static int lastVerticalQuarterPosition;
static int lastHorizontalHalfPosition;

static NSRect oldDraggingRect;
static int oldDropRow;
static int oldProposedDropRow;
static int currentDropRow;
static int oldDropLevel;
static int currentDropLevel;


// Cache the arrow images...
static NSImage *collapsed = nil;
static NSImage *expanded  = nil;
static NSImage *unexpandable  = nil;

@interface NSOutlineView (NotificationRequestMethods)
- (void) _postSelectionIsChangingNotification;
- (void) _postSelectionDidChangeNotification;
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
										   newIndex: (int) newIndex;
- (void) _postColumnDidResizeNotification;
- (BOOL) _shouldSelectTableColumn: (NSTableColumn *)tableColumn;
- (BOOL) _shouldSelectRow: (int)rowIndex;
- (BOOL) _shouldSelectionChange;
- (BOOL) _shouldEditTableColumn: (NSTableColumn *)tableColumn
							row: (int) rowIndex;
- (id)_objectValueForTableColumn: (NSTableColumn *)tb
							 row: (int)index;
- (void) _setObjectValue: (id)value
		  forTableColumn: (NSTableColumn *)tb
					 row: (int) index;
@end

// These methods are private...
@interface NSOutlineView (TableViewInternalPrivate)
- (void) _setSelectingColumns: (BOOL)flag;
- (BOOL) _editNextEditableCellAfterRow: (int)row
								column: (int)column;
- (BOOL) _editPreviousEditableCellBeforeRow: (int)row
									 column: (int)column;
- (void) _autosaveExpandedItems;
- (void) _autoloadExpandedItems;
- (void) _openItem: (id)item;
- (void) _closeItem: (id)item;
@end

NSString *NSOutlineViewColumnDidMoveNotification=@"NSOutlineViewColumnDidMoveNotification";
NSString *NSOutlineViewColumnDidResizeNotification=@"NSOutlineViewColumnDidResizeNotification";
NSString *NSOutlineViewSelectionDidChangeNotification=@"NSOutlineViewSelectionDidChangeNotification";
NSString *NSOutlineViewSelectionIsChangingNotification=@"NSOutlineViewSelectionIsChangingNotification";
NSString *NSOutlineViewItemDidExpandNotification=@"NSOutlineViewItemDidExpandNotification";
NSString *NSOutlineViewItemDidCollapseNotification=@"NSOutlineViewItemDidCollapseNotification";
NSString *NSOutlineViewItemWillExpandNotification=@"NSOutlineViewItemWillExpandNotification";
NSString *NSOutlineViewItemWillCollapseNotification=@"NSOutlineViewItemWillCollapseNotification";

@implementation NSOutlineView

// Initialize the class when it is loaded

+ (void) initialize
{
	if (self == [NSOutlineView class])
		{
//		[self setVersion: current_version];
		nc = [NSNotificationCenter defaultCenter];
		collapsed    = [NSImage imageNamed: @"GSDiscloseOff.tiff"];
		expanded     = [NSImage imageNamed: @"GSDiscloseOn.tiff"];
		unexpandable = [NSImage imageNamed: @"GSDiscloseHalf.tiff"];
		}
}

// Instance methods
- (id)initWithFrame: (NSRect)rect
{
	if((self=[super initWithFrame: rect]))
		{
	
	// Initial values
	_indentationMarkerFollowsCell = YES;
	_autoResizesOutlineColumn = NO;
	_autosaveExpandedItems = NO;
	_indentationPerLevel = 0.0;
	_outlineTableColumn = nil;
	_itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
								 NSObjectMapValueCallBacks,
								 64);
	_items = [[NSMutableArray alloc] init];
	_expandedItems = [[NSMutableArray alloc] init];
	_levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
									 NSObjectMapValueCallBacks,
									 64);
	[super setDataSource:self];	// make us the data source of the NSTableView
	[super setDelegate:self];	// make us the delegate of the NSTableView
	
		}
	return self;
}

- (void) dealloc
{
	[_items release];
	[_expandedItems release];
	NSFreeMapTable(_itemDict);
	NSFreeMapTable(_levelOfItems);
	
	if(_autosaveExpandedItems)
		{
		// notify when an item expands...
		[nc removeObserver: self
					  name: NSOutlineViewItemDidExpandNotification
					object: self];
		
		// notify when an item collapses...
		[nc removeObserver: self
					  name: NSOutlineViewItemDidCollapseNotification
					object: self];
		}
	
	[super dealloc];
}

- (BOOL)autoResizesOutlineColumn
{
	return _autoResizesOutlineColumn;
}

- (BOOL)autosaveExpandedItems
{
	return _autosaveExpandedItems;
}

// Collect all of the items under a given element.
- (void)_collectItemsStartingWith: (id)startitem
							 into: (NSMutableArray *)allChildren
{
	int num = 0;
	int i = 0;
	id object = nil;
	
	object = NSMapGet(_itemDict, startitem); 
	num = [object count];
	for(i = 0; i < num; i++)
		{
		id obj = NSMapGet(_itemDict, startitem);
		id anitem = [obj objectAtIndex: i];
		
		// Only collect the children if the item is expanded
		if([self isItemExpanded: startitem])
			{
			[allChildren addObject: anitem];
			}
		
		[self _collectItemsStartingWith: anitem
								   into: allChildren];
		}
}

- (void) _loadDictionaryStartingWith: (id) startitem
							 atLevel: (int) level
{
	int num = [_outlineDataSource outlineView: self
				numberOfChildrenOfItem: startitem];
	int i = 0;
	id sitem = (startitem == nil)?[NSNull null]:startitem;
	
	if(num > 0)
		{
		NSMapInsert(_itemDict, sitem, [NSMutableArray array]);
		}
	
	NSMapInsert(_levelOfItems, sitem, [NSNumber numberWithInt: level]);
	
	for(i = 0; i < num; i++)
		{
		id anitem = [_outlineDataSource outlineView: self
									   child: i
									  ofItem: startitem];
		
		id anarray = NSMapGet(_itemDict, sitem); 
		
		[anarray addObject: anitem];
		[self _loadDictionaryStartingWith: anitem
								  atLevel: level + 1]; 
		}
}

- (void)_closeItem: (id)item
{
	int numchildren = 0;
	int i = 0;
	NSMutableArray *removeAll = [NSMutableArray array];
	
	[self _collectItemsStartingWith: item into: removeAll];
	numchildren = [removeAll count];
	
	// close the item...
	if(item != nil)
		{
		[_expandedItems removeObject: item];
		}
	
	// For the close method it doesn't matter what order they are 
	// removed in.
	for(i=0; i < numchildren; i++)
		{
		id child = [removeAll objectAtIndex: i];
		[_items removeObject: child];
		}
}

- (void)_openItem: (id)item
{
	int numchildren = 0;
	int i = 0;
	int insertionPoint = 0;
	id object = nil;
	id sitem = (item == nil)?[NSNull null]:item;
	
	object = NSMapGet(_itemDict, sitem);
	numchildren = [object count];
	
	// open the item...
	if(item != nil)
		{
		[_expandedItems addObject: item];
		}
	
	insertionPoint = [_items indexOfObject: item];
	if(insertionPoint == NSNotFound)
		{
		insertionPoint = 0;
		}
	else
		{
		insertionPoint++;
		}
	
	[self setNeedsDisplay: YES];  
	for(i=numchildren-1; i >= 0; i--)
		{
		id obj = NSMapGet(_itemDict, sitem);
		id child = [obj objectAtIndex: i];
		
		// Add all of the children...
		if([self isItemExpanded: child])
			{
			NSMutableArray *insertAll = [NSMutableArray array];
			int i = 0, numitems = 0;
			
			[self _collectItemsStartingWith: child into: insertAll];
			numitems = [insertAll count];
			for(i = numitems-1; i >= 0; i--)
				{
				[_items insertObject: [insertAll objectAtIndex: i]
							 atIndex: insertionPoint];
				}
			}
		
		// Add the parent
		[_items insertObject: child atIndex: insertionPoint];
		}
}

- (void)collapseItem: (id)item
{
	[self collapseItem: item collapseChildren: NO];
}

- (void)collapseItem: (id)item collapseChildren: (BOOL)collapseChildren
{
	const SEL shouldSelector = @selector(outlineView:shouldCollapseItem:);
	BOOL canCollapse = YES;
	
	if([_outlineDelegate respondsToSelector: shouldSelector])
		{
		canCollapse = [_outlineDelegate outlineView: self shouldCollapseItem: item];
		}
	
	if([self isExpandable: item] && [self isItemExpanded: item] && canCollapse)
		{
		NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];      
		[infoDict setObject: item forKey: @"NSObject"];
		
		// Send out the notification to let observers know that this is about
		// to occur.
		[nc postNotificationName:NSOutlineViewItemWillCollapseNotification
						  object: self
						userInfo: infoDict];
		
		// collapse...
		[self _closeItem: item];
		
		// Send out the notification to let observers know that this has
		// occured.
		[nc postNotificationName:NSOutlineViewItemDidCollapseNotification
						  object: self
						userInfo: infoDict];
		
		// recursively find all children and call this method to open them.
		if(collapseChildren) // collapse all
			{
			NSMutableArray *allChildren = nil;
			int numchild = 0;
			int index = 0;
			id sitem = (item == nil)?[NSNull null]:item;
			
			allChildren = NSMapGet(_itemDict, sitem);
			numchild = [allChildren count];
			
			for(index = 0;index < numchild;index++)
				{
				id child = [allChildren objectAtIndex: index];
				
				if([self isExpandable: child])
					{
					[self collapseItem: child collapseChildren: collapseChildren];
					}
				}
			}
		[self noteNumberOfRowsChanged];
		}
}

- (void)expandItem: (id)item
{
	[self expandItem: item expandChildren: NO];
}

- (void)expandItem:(id)item expandChildren:(BOOL)expandChildren
{
	const SEL shouldExpandSelector = @selector(outlineView:shouldExpandItem:);
	BOOL canExpand = YES;
	
	if([_outlineDelegate respondsToSelector: shouldExpandSelector])
		{
		canExpand = [_outlineDelegate outlineView: self shouldExpandItem: item];
		}
	
	// if the item is expandable
	if([self isExpandable: item])
		{
		// if it is not already expanded and it can be expanded, then expand
		if(![self isItemExpanded: item] && canExpand)
			{
			NSMutableDictionary *infoDict = [NSMutableDictionary dictionary];
			
			[infoDict setObject: item forKey: @"NSObject"];
			
			// Send out the notification to let observers know that this is about
			// to occur.
			[nc postNotificationName:NSOutlineViewItemWillExpandNotification
							  object: self
							userInfo: infoDict];
			
			// insert the root element, if necessary otherwise insert the
			// actual object.
			[self _openItem: item];
			
			// Send out the notification to let observers know that this has
			// occured.
			[nc postNotificationName:NSOutlineViewItemDidExpandNotification
							  object: self
							userInfo: infoDict];
			}
		
		// recursively find all children and call this method to open them.
		if(expandChildren) // expand all
			{
			NSMutableArray *allChildren = nil;
			int numchild = 0;
			int index = 0;
			id sitem = (item == nil)?[NSNull null]:item;
			
			allChildren = NSMapGet(_itemDict, sitem);
			numchild = [allChildren count];
			
			for(index = 0;index < numchild;index++)
				{
				id child = [allChildren objectAtIndex: index];
				
				if([self isExpandable: child])
					{
					[self expandItem: child expandChildren: expandChildren];
					}
				}
			}      
		}
	[self noteNumberOfRowsChanged];
}

- (BOOL)indentationMarkerFollowsCell
{
	return _indentationMarkerFollowsCell;
}

- (float)indentationPerLevel
{
	return _indentationPerLevel;
}

- (BOOL)isExpandable: (id)item
{
	return [_outlineDataSource outlineView: self isItemExpandable: item];
}

- (BOOL)isItemExpanded: (id)item
{
	if(item == nil)
		return YES;
	
	// Check the array to determine if it is expanded.
	return([_expandedItems containsObject: item]);
}

- (id)itemAtRow: (int)row
{
	return [_items objectAtIndex: row];
}

- (int)levelForItem: (id)item
{
	if(item != nil)
		{
		id object = NSMapGet(_levelOfItems, item);
		return [object intValue];
		}
	
	return -1;
}

- (int)levelForRow: (int)row
{
	return [self levelForItem: [self itemAtRow: row]];
}

- (NSTableColumn *)outlineTableColumn
{
	return _outlineTableColumn;
}

- (BOOL)_findItem: (id)item
       childIndex: (int *)index
		 ofParent: (id)parent
{
	NSArray *allKeys = NSAllMapTableKeys(_itemDict);
	BOOL hasChildren = NO;
	NSEnumerator *en = [allKeys objectEnumerator];
	id object = nil;
	
	// initial values for return parameters
	*index = NSNotFound;
	parent = nil;
	
	if([allKeys containsObject: item])
		{
		hasChildren = YES;
		}
	
	while((object = [en nextObject]))
		{
		NSArray *childArray = NSMapGet(_itemDict, object);
		
		if((*index = [childArray indexOfObject: item]) != NSNotFound)
			{
			parent = object;
			break;
			}
		}
	
	return hasChildren;
}

- (void)reloadItem: (id)item
{
	[self reloadItem: item reloadChildren: NO];
}

- (void)reloadItem: (id)item reloadChildren: (BOOL)reloadChildren
{
	id parent = nil;
	id dsobj = nil;
	BOOL haschildren = NO;
	int index = 0;
	id obj = nil;
	id object = (item == nil)?([NSNull null]):item;
	
	// find the item
	haschildren = [self _findItem: object
					   childIndex: &index
						 ofParent: parent];
	
	dsobj = [_outlineDataSource outlineView: self
							   child: index
							  ofItem: parent];
	
	obj = NSMapGet(_itemDict, parent);
	[obj removeObject: item];
	[obj insertObject: dsobj atIndex: index];
	
	if(reloadChildren && haschildren) // expand all
		{
		[self _loadDictionaryStartingWith: object
								  atLevel: [self levelForItem: object]];
		[_items release];		// release the old array
		[self _openItem: nil];	// regenerate the _items array based on the new dictionary
		}      
}

- (int)rowForItem: (id)item
{
	return [_items indexOfObject: item];
}

- (void)setAutoresizesOutlineColumn: (BOOL)resize
{
	_autoResizesOutlineColumn = resize;
}

- (void)setAutosaveExpandedItems: (BOOL)flag
{
	if(flag == _autosaveExpandedItems)
		{
		return;
		}
	
	_autosaveExpandedItems = flag;
	if(flag)
		{
		[self _autoloadExpandedItems];
		// notify when an item expands...
		[nc addObserver: self
			   selector: @selector(_autosaveExpandedItems)
				   name: NSOutlineViewItemDidExpandNotification
				 object: self];
		
		// notify when an item collapses...
		[nc addObserver: self
			   selector: @selector(_autosaveExpandedItems)
				   name: NSOutlineViewItemDidCollapseNotification
				 object: self];
		}
	else
		{
		// notify when an item expands...
		[nc removeObserver: self
					  name: NSOutlineViewItemDidExpandNotification
					object: self];
		
		// notify when an item collapses...
		[nc removeObserver: self
					  name: NSOutlineViewItemDidCollapseNotification
					object: self];
		}
}

- (void)setIndentationMarkerFollowsCell: (BOOL)followsCell
{
	_indentationMarkerFollowsCell = followsCell;
}

- (void)setIndentationPerLevel: (float)newIndentLevel
{
	_indentationPerLevel = newIndentLevel;
}

- (void)setOutlineTableColumn: (NSTableColumn *)outlineTableColumn
{
	_outlineTableColumn = outlineTableColumn;
}

- (BOOL)shouldCollapseAutoExpandedItemsForDeposited: (BOOL)deposited
{
	return YES;
}

- (void) noteNumberOfRowsChanged
{
	_numberOfRows = [_items count];
	
	if (!_selectingColumns)
		{ // If we are selecting rows, we have to check that we have no selected rows below the new end of the table
		[_selectedRows removeIndexesInRange:NSMakeRange(_numberOfRows, NSNotFound-1-_numberOfRows)];	// all beyond _numberOfRows
		if (_lastSelectedRow >= _numberOfRows)
			{ // last selection was behind end of new table
			if (!_tv.allowsEmptySelection && [_selectedRows count] == 0)
				{ // try to select last existing row
				int lastRow = _numberOfRows - 1;						
				if (lastRow >= 0)
					[_selectedRows addIndex:lastRow];
				}
			_lastSelectedRow = [_selectedRows lastIndex];	// deselect if there is no last index
			}
		}
	
	[self setFrame: NSMakeRect (frame.origin.x, 
								frame.origin.y,
								frame.size.width, 
								(_numberOfRows * _rowHeight) + 1)];
	
	/* If we are shorter in height than the enclosing clipview, we
		should redraw us now. */
	if (super_view != nil)
		{
		NSRect superviewBounds; // Get this *after* [self setFrame:]
		superviewBounds = [super_view bounds];
		if ((superviewBounds.origin.x <= frame.origin.x) 
			&& (NSMaxY (superviewBounds) >= NSMaxY (frame)))
			{
			[self setNeedsDisplay: YES];
			}
		}
}

- (void) setDataSource: (id)anObject
{
#define CHECK_REQUIRED_METHOD(selector_name) \
	if (![anObject respondsToSelector: @selector(selector_name)]) \
		[NSException raise: NSInternalInconsistencyException \
					format: @"data source does not respond to %@", @#selector_name]
		
		CHECK_REQUIRED_METHOD(outlineView:child:ofItem:);
	CHECK_REQUIRED_METHOD(outlineView:isItemExpandable:);
	CHECK_REQUIRED_METHOD(outlineView:numberOfChildrenOfItem:);
	CHECK_REQUIRED_METHOD(outlineView:objectValueForTableColumn:byItem:);
		
	/* We do *not* retain the dataSource, it's like a delegate */

	_outlineDataSource = anObject;
	[self tile];
	[self reloadData];
}

- (void) reloadData
{
	[_items release];	// release the old array
	if(_itemDict != NULL)
		{
		NSFreeMapTable(_itemDict);
		}
	
	if(_levelOfItems != NULL)
		{
		NSFreeMapTable(_levelOfItems);
		}
	
	// create a new empty one
	_items = [[NSMutableArray alloc] init]; 
	_itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
								 NSObjectMapValueCallBacks,
								 64);
	_levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
									 NSObjectMapValueCallBacks,
									 64);
	
	// reload all the open items...
	[self _loadDictionaryStartingWith: nil
							  atLevel: -1];
	[self _openItem: nil];
	[super reloadData];
}

- (void) setDelegate: (id)anObject
{
	const SEL sel = @selector(outlineView:willDisplayCell:forTableColumn:item:);
	
	if (_outlineDelegate)
		[nc removeObserver: _outlineDelegate name: nil object: self];
	_outlineDelegate = anObject;
	
#define SET_outlineDelegate_NOTIFICATION(notif_name) \
	if ([_outlineDelegate respondsToSelector: @selector(outlineView##notif_name:)]) \
		[nc addObserver: _outlineDelegate \
			   selector: @selector(outlineView##notif_name:) \
				   name: NSOutlineView##notif_name##Notification object: self]
		
		SET_outlineDelegate_NOTIFICATION(ColumnDidMove);
	SET_outlineDelegate_NOTIFICATION(ColumnDidResize);
	SET_outlineDelegate_NOTIFICATION(SelectionDidChange);
	SET_outlineDelegate_NOTIFICATION(SelectionIsChanging);
	SET_outlineDelegate_NOTIFICATION(ItemDidExpand);
	SET_outlineDelegate_NOTIFICATION(ItemDidCollapse);
	SET_outlineDelegate_NOTIFICATION(ItemWillExpand);
	SET_outlineDelegate_NOTIFICATION(ItemWillCollapse);
	
	_del_responds = [_outlineDelegate respondsToSelector: sel];
}

- (void) encodeWithCoder: (NSCoder*)aCoder
{
	[super encodeWithCoder: aCoder];
	
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autoResizesOutlineColumn];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &_indentationMarkerFollowsCell];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &_autosaveExpandedItems];
	[aCoder encodeValueOfObjCType: @encode(float) at: &_indentationPerLevel];
	[aCoder encodeConditionalObject: _outlineTableColumn];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		return self;
		}
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autoResizesOutlineColumn];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_indentationMarkerFollowsCell];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &_autosaveExpandedItems];
	[aDecoder decodeValueOfObjCType: @encode(float) at: &_indentationPerLevel];
	_outlineTableColumn = [aDecoder decodeObject];
	
	_itemDict = NSCreateMapTable(NSObjectMapKeyCallBacks,
								 NSObjectMapValueCallBacks,
								 64);
	_items = [[NSMutableArray alloc] init];
	_expandedItems = [[NSMutableArray alloc] init];
	_levelOfItems = NSCreateMapTable(NSObjectMapKeyCallBacks,
									 NSObjectMapValueCallBacks,
									 64); 
	return self;
}

// table view delegates and datasource mapping to item list

- (int) numberOfRowsInTableView:(NSTableView *) tableView;
{
	return [_items count];
}

- (id) tableView:(NSTableView *)tableView 
	   objectValueForTableColumn:(NSTableColumn *)tableColumn 
						 row:(int)row;
{
	return [_outlineDataSource outlineView:self
							 objectValueForTableColumn:tableColumn
																	byItem:[_items objectAtIndex:row]];
}

- (void) tableView:(NSTableView *)tableView 
		setObjectValue:(id)object 
		forTableColumn:(NSTableColumn *)tableColumn 
							 row:(int)row;
{
	if ([_outlineDataSource respondsToSelector: @selector(outlineView:setObjectValue:forTableColumn:byItem:)])
		[_outlineDataSource outlineView:self
										 setObjectValue:object
										 forTableColumn:tableColumn
														 byItem:[_items objectAtIndex:row]];
}

- (void) tableView:(NSTableView *)aTableView willDisplayCell:(id) cell forTableColumn:(NSTableColumn *) tb row:(int) row
{
	if ([_outlineDelegate respondsToSelector: @selector(outlineView:willDisplayCell:forTableColumn:item:)])
		{
		[_outlineDelegate outlineView: self   
									willDisplayCell: cell 
									 forTableColumn: tb   
														 item: [_items objectAtIndex:row]];
		}
}

#if NEEDS_ADAPTATION_FOR_MYSTEP

// BTW: why do we have to override this? Can't we do everything with NSTableView's delegates?

- (void) mouseDown: (NSEvent *)theEvent
{
	NSPoint location = [theEvent locationInWindow];
	NSTableColumn *tb;
	NSImage *image = nil;
	
	location = [self convertPoint: location  fromView: nil];
	_clickedRow = [self rowAtPoint: location];
	_clickedColumn = [self columnAtPoint: location];
	
	if([self isItemExpanded: [self itemAtRow: _clickedRow]])
		{
		image = expanded;
		}
	else
		{
		image = collapsed;
		}
	
	tb = [_tableColumns objectAtIndex: _clickedColumn];
	if(tb == _outlineTableColumn)
		{
		int level = [self levelForRow: _clickedRow];
		int position = 0;
		
		if(_indentationMarkerFollowsCell)
			{
			position = _indentationPerLevel * level;
			}
		
		position += _columnOrigins[_clickedColumn];
		
		if(location.x >= position && location.x <= position + [image size].width)
			{
			if(![self isItemExpanded: [self itemAtRow: _clickedRow]])
				{
				[self expandItem: [self itemAtRow: _clickedRow]];
				}
			else
				{
				[self collapseItem: [self itemAtRow: _clickedRow]];
				}
			}
		}
	
	[super mouseDown: theEvent];
}  

/*
 * (NotificationRequestMethods)
 */
- (void) _postSelectionIsChangingNotification
{
	[nc postNotificationName:
		NSOutlineViewSelectionIsChangingNotification
					  object: self];
}
- (void) _postSelectionDidChangeNotification
{
	[nc postNotificationName:
		NSOutlineViewSelectionDidChangeNotification
					  object: self];
}
- (void) _postColumnDidMoveNotificationWithOldIndex: (int) oldIndex
										   newIndex: (int) newIndex
{
	[nc postNotificationName:
		NSOutlineViewColumnDidMoveNotification
					  object: self
					userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
						[NSNumber numberWithInt: newIndex],
						@"NSNewColumn",
						[NSNumber numberWithInt: oldIndex],
						@"NSOldColumn",
						nil]];
}

- (void) _postColumnDidResizeNotificationWithOldWidth: (float) oldWidth
{
	[nc postNotificationName:
		NSOutlineViewColumnDidResizeNotification
					  object: self
					userInfo: [NSDictionary 
		  dictionaryWithObjectsAndKeys:
						[NSNumber numberWithFloat: oldWidth],
						@"NSOldWidth", 
						nil]];
}

- (BOOL) _isDraggingSource
{
	return [_outlineDataSource respondsToSelector:
		@selector(outlineView:writeItems:toPasteboard:)];
}

- (BOOL) _writeRows: (NSArray *) rows
       toPasteboard: (NSPasteboard *)pboard
{
	int count = [rows count];
	int i;
	NSMutableArray *itemArray = [NSMutableArray
				arrayWithCapacity: count];
	
	for ( i = 0; i < count; i++ )
		{
		[itemArray addObject: 
			[self itemAtRow: 
				[[rows objectAtIndex: i] intValue]]];
		}
	
	if ([_outlineDataSource respondsToSelector:
		@selector(outlineView:writeItems:toPasteboard:)] == YES)
		{
		return [_outlineDataSource outlineView: self
							 writeItems: itemArray
						   toPasteboard: pboard];
		}
	return NO;
}

/*
 *  Drag'n'drop support
 */

- (unsigned int) draggingEntered: (id <NSDraggingInfo>) sender
{
	NSLog(@"draggingEntered");
	currentDropRow = -1;
	//  currentDropOperation = -1;
	oldDropRow = -1;
	lastVerticalQuarterPosition = -1;
	oldDraggingRect = NSMakeRect(0.,0., 0., 0.);
	return NSDragOperationCopy;
}

- (void) draggingExited: (id <NSDraggingInfo>) sender
{
	[self setNeedsDisplayInRect: oldDraggingRect];
	[self displayIfNeeded];
}

- (unsigned int) draggingUpdated: (id <NSDraggingInfo>) sender
{
	NSPoint p = [sender draggingLocation];
	NSRect newRect;
	int row;
	int verticalQuarterPosition;
	int horizontalHalfPosition;
	int levelBefore;
	int levelAfter;
	int level;
	
	p = [self convertPoint: p fromView: nil];
	verticalQuarterPosition = 
		(p.y - bounds.origin.y) / _rowHeight * 4.;
	horizontalHalfPosition = 
		(p.x - bounds.origin.y) / _indentationPerLevel * 2.;
	
	
	if ((verticalQuarterPosition - oldProposedDropRow * 4 <= 2) &&
		(verticalQuarterPosition - oldProposedDropRow * 4 >= -3) )
		{
		row = oldProposedDropRow;
		}
	else
		{
		row = (verticalQuarterPosition + 2) / 4;
		}
	
	if (row > _numberOfRows)
		row = _numberOfRows;
	
	//  NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);
	
	//  NSLog(@"dropRow %d", row);
	
	if (row == 0)
		{
		levelBefore = 0;
		}
	else
		{
		levelBefore = [self levelForRow: (row - 1)];
		}
	if (row == _numberOfRows)
		{
		levelAfter = 0;
		}
	else
		{
		levelAfter = [self levelForRow: row];
		}
	
	if (levelBefore < levelAfter)
		levelBefore = levelAfter;
	
	
	//  NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);
	//  NSLog(@"level before = %d", levelBefore);
	//  NSLog(@"level after = %d", levelAfter);
	
	
	
	if ((lastVerticalQuarterPosition != verticalQuarterPosition)
		|| (lastHorizontalHalfPosition != horizontalHalfPosition))
		{
		id item;
		int childIndex;
		
		if (horizontalHalfPosition / 2 < levelAfter)
			horizontalHalfPosition = levelAfter * 2;
		else if (horizontalHalfPosition / 2 > levelBefore)
			horizontalHalfPosition = levelBefore * 2 + 1;
		level = horizontalHalfPosition / 2;
		
		
		lastVerticalQuarterPosition = verticalQuarterPosition;
		lastHorizontalHalfPosition = horizontalHalfPosition;
		
		//      NSLog(@"horizontalHalfPosition = %d", horizontalHalfPosition);
		//      NSLog(@"verticalQuarterPosition = %d", verticalQuarterPosition);
		
		currentDropRow = row;
		currentDropLevel = level;
		
		{
			int i;
			int j = 0;
			int lvl;
			for ( i = row - 1; i >= 0; i-- )
				{
				lvl = [self levelForRow: i];
				if (lvl == level - 1)
					{
					break;
					}
				else if (lvl == level)
					{
					j++;
					}
				}
			//	NSLog(@"found %d (proposed childIndex = %d)", i, j);
			if (i == -1)
				item = nil;
			else
				item = [self itemAtRow: i];
			
			childIndex = j;
		}
		
		
		oldProposedDropRow = currentDropRow;
		if ([_outlineDataSource respondsToSelector: 
			@selector(outlineView:validateDrop:proposedItem:proposedChildIndex:)])
			{
			//	  NSLog(@"currentDropLevel %d, currentDropRow %d",
			//		currentDropRow, currentDropLevel);
			[_outlineDataSource outlineView: self
						validateDrop: sender
						proposedItem: item
				  proposedChildIndex: childIndex];
			//	  NSLog(@"currentDropLevel %d, currentDropRow %d", 
			//		currentDropRow, currentDropLevel);
			}
		
		if ((currentDropRow != oldDropRow) || (currentDropLevel != oldDropLevel))
			{
			[self lockFocus];
			
			[self setNeedsDisplayInRect: oldDraggingRect];
			[self displayIfNeeded];
			
			[[NSColor darkGrayColor] set];
			
			//	  NSLog(@"currentDropLevel %d, currentDropRow %d", 
			//		currentDropRow, currentDropLevel);
			if (currentDropLevel != NSOutlineViewDropOnItemIndex)
				{
				if (currentDropRow == 0)
					{
					newRect = NSMakeRect([self visibleRect].origin.x,
										 currentDropRow * _rowHeight,
										 [self visibleRect].size.width,
										 3);
					}
				else if (currentDropRow == _numberOfRows)
					{
					newRect = NSMakeRect([self visibleRect].origin.x,
										 currentDropRow * _rowHeight - 2,
										 [self visibleRect].size.width,
										 3);
					}
				else
					{
					newRect = NSMakeRect([self visibleRect].origin.x,
										 currentDropRow * _rowHeight - 1,
										 [self visibleRect].size.width,
										 3);
					}
				newRect.origin.x += currentDropLevel * _indentationPerLevel;
				newRect.size.width -= currentDropLevel * _indentationPerLevel;
				NSRectFill(newRect);
				oldDraggingRect = newRect;
				
				}
			else
				{
				newRect = [self frameOfCellAtColumn: 0
												row: currentDropRow];
				newRect.origin.x = _bounds.origin.x;
				newRect.size.width = _bounds.size.width + 2;
				newRect.origin.x -= _intercellSpacing.height / 2;
				newRect.size.height += _intercellSpacing.height;
				oldDraggingRect = newRect;
				oldDraggingRect.origin.y -= 1;
				oldDraggingRect.size.height += 2;
				
				newRect.size.height -= 1;
				
				newRect.origin.x += 3;
				newRect.size.width -= 3;
				
				if (_drawsGrid)
					{
					//newRect.origin.y += 1;
					//newRect.origin.x += 1;
					//newRect.size.width -= 2;
					newRect.size.height += 1;
					}
				else
					{
					}
				
				newRect.origin.x += currentDropLevel * _indentationPerLevel;
				newRect.size.width -= currentDropLevel * _indentationPerLevel;
				
				NSFrameRectWithWidth(newRect, 2.0);
				//	      NSRectFill(newRect);
				
				}
			[window flushWindow];
			
			[self unlockFocus];
			
			oldDropRow = currentDropRow;
			oldDropLevel = currentDropLevel;
			}
		}
	
	
	return NSDragOperationCopy;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)sender
{
	NSLog(@"performDragOperation");
	if ([_outlineDataSource 
	respondsToSelector: 
		@selector(outlineView:acceptDrop:item:childIndex:)])
		{
		id item;
		int childIndex;
		int i;
		int j = 0;
		int lvl;
		for ( i = currentDropRow - 1; i >= 0; i-- )
			{
			lvl = [self levelForRow: i];
			if (lvl == currentDropLevel - 1)
				{
				break;
				}
			else if (lvl == currentDropLevel)
				{
				j++;
				}
			}
		if (i == -1)
			item = nil;
		else
			item = [self itemAtRow: i];
		
		childIndex = j;
		
		
		return [_outlineDataSource 
	       outlineView: self
			acceptDrop: sender
				  item: item
			childIndex: childIndex];
		}
	else
		return NO;
}

- (BOOL) prepareForDragOperation: (id<NSDraggingInfo>)sender
{
	[self setNeedsDisplayInRect: oldDraggingRect];
	[self displayIfNeeded];
	
	return YES;
}

// Autosave methods...
- (void) setAutosaveName: (NSString *)name
{
	[super setAutosaveName: name];
	[self _autoloadExpandedItems];
}

- (void) _autosaveExpandedItems
{
	if (_autosaveExpandedItems && _autosaveName != nil) 
		{
		NSUserDefaults      *defaults;
		NSString            *tableKey;
		
		defaults  = [NSUserDefaults standardUserDefaults];
		tableKey = [NSString stringWithFormat: @"NSOutlineView Expanded Items %@", 
			_autosaveName];
		[defaults setObject: _expandedItems  forKey: tableKey];
		[defaults synchronize];
		}
}

- (void) _autoloadExpandedItems
{
	if (_autosaveExpandedItems && _autosaveName != nil) 
		{ 
		NSUserDefaults     *defaults;
		id                  config;
		NSString           *tableKey;
		
		defaults  = [NSUserDefaults standardUserDefaults];
		tableKey = [NSString stringWithFormat: @"NSOutlineView Expanded Items %@", 
			_autosaveName];
		config = [defaults objectForKey: tableKey];
		if (config != nil) 
			{
			NSEnumerator *en = [config objectEnumerator];
			id item = nil;
			
			while ((item = [en nextObject]) != nil) 
				{
				[self expandItem: item];
				}
			}
		}
}


#endif

@end /* implementation of NSOutlineView */

