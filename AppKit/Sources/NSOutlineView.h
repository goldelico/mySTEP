/* 
	NSOutlineView.h
 
	The outline class.
 
	Copyright (C) 2001 Free Software Foundation, Inc.
 
	Author:  Gregory John Casamento <greg_casamento@yahoo.com>
	Date: October 2001
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5
 
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

#ifndef _GNUstep_H_NSOutlineView
#define _GNUstep_H_NSOutlineView

#import <AppKit/NSTableView.h>
#import <AppKit/NSDragging.h>
#import <Foundation/NSMapTable.h>

@class NSMutableArray;
@class NSString;

@interface NSOutlineView : NSTableView
{
	NSMapTable *_itemDict;
	NSMutableArray *_items;
	NSMutableArray *_expandedItems;
	NSMapTable *_levelOfItems;
	NSTableColumn *_outlineTableColumn;
	float _indentationPerLevel;
	/*
	id _outlineDataSource;	// data source that understands the NSOutlinView datasource protocol
	id _outlineDelegate;
	//	unsigned _numberOfRows;
	BOOL _selectingColumns;
	 */
	BOOL _drawsGrid;
	BOOL _del_responds;
	BOOL _indentationMarkerFollowsCell;
	BOOL _autoResizesOutlineColumn;
	BOOL _autosaveExpandedItems;
	BOOL _dataSource_editable;
}

// Instance methods
- (BOOL) autoResizesOutlineColumn;
- (BOOL) autosaveExpandedItems;
- (void) collapseItem:(id) item;
- (void) collapseItem:(id) item collapseChildren:(BOOL) collapseChildren;
- (id) dataSource; 
- (void) expandItem:(id) item;
- (void) expandItem:(id) item expandChildren:(BOOL) expandChildren;
- (NSRect) frameOfOutlineCellAtRow:(NSInteger) row; 
- (BOOL) indentationMarkerFollowsCell;
- (CGFloat) indentationPerLevel;
- (BOOL) isExpandable:(id) item;
- (BOOL) isItemExpanded:(id) item;
- (id) itemAtRow:(NSInteger) row;
- (NSInteger) levelForItem:(id) item;
- (NSInteger) levelForRow:(NSInteger) row;
- (NSTableColumn *) outlineTableColumn;
- (id) parentForItem:(id) item; 
- (void) reloadItem:(id) item;
- (void) reloadItem:(id) item reloadChildren:(BOOL) reloadChildren;
- (NSInteger) rowForItem:(id) item;
- (void) setAutoresizesOutlineColumn:(BOOL) resize;
- (void) setAutosaveExpandedItems:(BOOL) flag;
- (void) setDataSource:(id) datasource; 
- (void) setDropItem:(id) item dropChildIndex:(NSInteger) childIndex;
- (void) setIndentationMarkerFollowsCell:(BOOL) followsCell;
- (void) setIndentationPerLevel:(CGFloat) newIndentLevel;
- (void) setOutlineTableColumn:(NSTableColumn *) outlineTableColumn;
- (BOOL) shouldCollapseAutoExpandedItemsForDeposited:(BOOL) deposited;

@end /* interface of NSOutlineView */

/* 
	Informal protocol NSOutlineViewDataSource 
*/

@interface NSObject (NSOutlineViewDataSource)

- (BOOL) outlineView:(NSOutlineView *) outlineView acceptDrop:(id <NSDraggingInfo>) info item:(id) item childIndex:(NSInteger) index;

- (id) outlineView:(NSOutlineView *) outlineView child:(NSInteger) index ofItem:(id) item;									// required method
- (BOOL) outlineView:(NSOutlineView *) outlineView isItemExpandable:(id) item;												// required method
- (id) outlineView:(NSOutlineView *) outlineView itemForPersistentObject:(id) object;										// required method
- (NSArray *) outlineView:(NSOutlineView *) outlineView namesOfPromisedFilesDroppedAtDestination:(NSURL *) dest forDraggedItems:(NSArray *) draggedItems; 
- (NSInteger) outlineView:(NSOutlineView *) outlineView numberOfChildrenOfItem:(id) item;									// required method
- (id) outlineView:(NSOutlineView *) outlineView objectValueForTableColumn:(NSTableColumn *) tableColumn byItem:(id) item;	// required method

- (id) outlineView:(NSOutlineView *) outlineView persistentObjectForItem:(id) item;
- (BOOL) outlineView:(NSOutlineView *) sender isGroupItem:(id) item;
- (void) outlineView:(NSOutlineView *) outlineView setObjectValue:(id) object forTableColumn:(NSTableColumn *) tableColumn byItem:(id) item;
- (void) outlineView:(NSOutlineView *) outlineView sortDescriptorsDidChange:(NSArray *) descriptors; 
- (NSDragOperation) outlineView:(NSOutlineView *) outlineView validateDrop:(id <NSDraggingInfo>)info proposedItem:(id)item proposedChildIndex:(NSInteger) index;
- (BOOL) outlineView:(NSOutlineView *) outlineView writeItems:(NSArray *) items toPasteboard:(NSPasteboard *) pboard;

@end

/*
	Constants
*/

enum {
	NSOutlineViewDropOnItemIndex = -1
};

/*
	Notifications
*/
extern NSString *NSOutlineViewColumnDidMoveNotification;
extern NSString *NSOutlineViewColumnDidResizeNotification;
extern NSString *NSOutlineViewSelectionDidChangeNotification;
extern NSString *NSOutlineViewSelectionIsChangingNotification;
extern NSString *NSOutlineViewItemDidExpandNotification;
extern NSString *NSOutlineViewItemDidCollapseNotification;
extern NSString *NSOutlineViewItemWillExpandNotification;
extern NSString *NSOutlineViewItemWillCollapseNotification;

/*
	Methods Implemented by the Delegate
*/
@interface NSObject (NSOutlineViewDelegate)

- (void) outlineViewColumnDidMove: (NSNotification *)aNotification;
- (void) outlineViewColumnDidResize: (NSNotification *)aNotification;
- (void) outlineViewItemDidCollapse: (NSNotification *)aNotification;
- (void) outlineViewItemDidExpand: (NSNotification *)aNotification;
- (void) outlineViewItemWillCollapse: (NSNotification *)aNotification;
- (void) outlineViewItemWillExpand: (NSNotification *)aNotification;
- (void) outlineViewSelectionDidChange: (NSNotification *)aNotification;
- (void) outlineViewSelectionIsChanging: (NSNotification *)aNotification;

// delegate methods
- (NSCell *) outlineView:(NSOutlineView *) outlineView 
  dataCellForTableColumn:(NSTableColumn *) tableColumn 
					item:(id) item;
- (void) outlineView:(NSOutlineView *) outlineView 
 didClickTableColumn:(NSTableColumn *) tableColumn;
- (void) outlineView:(NSOutlineView *) outlineView 
  didDragTableColumn:(NSTableColumn *) tableColumn;
- (CGFloat) outlineView:(NSOutlineView *) outlineView 
	  heightOfRowByItem:(id) item;
- (BOOL) outlineView:(NSOutlineView *) outlineView 
		 isGroupItem:(id) item; 
- (void) outlineView:(NSOutlineView *) outlineView 
mouseDownInHeaderOfTableColumn:(NSTableColumn *) tableColumn;
- (id) outlineView:(NSOutlineView *) outlineView 
nextTypeSelectMatchFromItem:(id) fromItem 
			toItem:(id) toItem 
		 forString:(NSString *) searchStr; 
- (BOOL) outlineView:(NSOutlineView *) outlineView 
  shouldCollapseItem:(id) item;
- (BOOL)  outlineView:(NSOutlineView *) outlineView 
shouldEditTableColumn:(NSTableColumn *) tableColumn
				 item:(id) item;
- (BOOL)  outlineView:(NSOutlineView *) outlineView 
     shouldExpandItem:(id) item;
- (BOOL)  outlineView:(NSOutlineView *) outlineView 
     shouldSelectItem:(id) item;
- (BOOL) outlineView:(NSOutlineView *) outlineView 
shouldSelectTableColumn:(NSTableColumn *) tableColumn;
- (BOOL) outlineView:(NSOutlineView *) outlineView 
shouldShowCellExpansionForTableColumn:(NSTableColumn *) tableColumn 
				item:(id) item; 
- (BOOL) outlineView:(NSOutlineView *) outlineView 
	 shouldTrackCell:(NSCell *) cell 
	  forTableColumn:(NSTableColumn *) tableColumn 
				item:(id) item; 
- (BOOL) outlineView:(NSOutlineView *) outlineView 
shouldTypeSelectForEvent:(NSEvent *) evt 
withCurrentSearchString:(NSString *) searchStr;
- (NSString *) outlineView:(NSOutlineView *) outlineView 
			toolTipForCell:(NSCell *) cell 
					  rect:(NSRectPointer) rect 
			   tableColumn:(NSTableColumn *) tableColumn 
					  item:(id) item 
			 mouseLocation:(NSPoint) mouseLoc;
- (NSString *) outlineView:(NSOutlineView *) outlineView 
typeSelectStringForTableColumn:(NSTableColumn *) tableColumn 
					  item:(id) item; 
- (void) outlineView:(NSOutlineView *) outlineView 
	 willDisplayCell:(id) cell
	  forTableColumn:(NSTableColumn *) tableColumn
				item:(id) item;  
- (void)  outlineView:(NSOutlineView *) outlineView 
willDisplayOutlineCell:(id) cell
       forTableColumn:(NSTableColumn *) tableColumn
                 item:(id) item;

- (BOOL) selectionShouldChangeInOutlineView:(NSOutlineView *) outlineView;

@end

#endif /* _GNUstep_H_NSOutlineView */
