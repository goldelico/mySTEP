/* 
   NSTableView.m

   NSTableView and related component classes

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date:    June 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Aug 2006 - aligned with 10.4, use NSIndexSet
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSSortDescriptor.h>

#import <AppKit/NSTableView.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSTableHeaderCell.h>

#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSImage.h>

#import "NSAppKitPrivate.h"

#define NOTE(notif_name) NSTableView##notif_name##Notification
#define CONTROL(notif_name) NSControl##notif_name##Notification

@implementation NSTableView (NSTableViewPrivate) 

+ (NSImage *) _defaultTableHeaderReverseSortImage;
{ // small upward arrow
	return nil;
}

+ (NSImage *) _defaultTableHeaderSortImage; 
{ // small downward arrow
	return nil;
}

@end

//*****************************************************************************
//
// 		NSTableHeaderCell 
//
//*****************************************************************************

@implementation NSTableHeaderCell

- (id) initTextCell:(NSString *)aString
{
	if((self=[super initTextCell:aString]))
		{
		_c.editable = NO;
		_c.selectable = NO;
		[self setAlignment:NSCenterTextAlignment];
			[self _setTextColor:[NSColor headerTextColor]];
		ASSIGN(_backgroundColor, [NSColor headerColor]);
		}
	return self;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	// FIXME: adjust in style and show sorting arrows/images

	if(_c.highlighted)
		{
		[[NSColor controlHighlightColor] set];	// highlight when button pressed (different in style from table column selection)
		NSRectFill(cellFrame);
		}
	[[NSColor controlShadowColor] set];
	NSFrameRect(cellFrame);	// draw frame
	cellFrame.size.width -= [self sortIndicatorRectForBounds:cellFrame].size.width;	// reduce drawing area for sort arrow
	[self drawInteriorWithFrame:cellFrame inView:controlView];	// default from NSTextFieldCell
	// how do we know that we really should display a sort arrow?
	[self drawSortIndicatorWithFrame:cellFrame inView:controlView ascending:(_c.state == NSOnState) priority:0];
}

- (void) drawSortIndicatorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView ascending:(BOOL) ascending priority:(int) priority;
{
	// how do we know that we really should display a sort arrow?
	NSImage *img;
	cellFrame = [self sortIndicatorRectForBounds:cellFrame];
	if(ascending)
		img=[NSTableView _defaultTableHeaderSortImage];
	else
		img=[NSTableView _defaultTableHeaderReverseSortImage];
	[img drawAtPoint:cellFrame.origin fromRect:NSZeroRect operation:NSCompositeSourceOut fraction:1.0];
}

- (NSRect) sortIndicatorRectForBounds:(NSRect) theRect;
{ // square at the right end
	// how do we know that we really should display a sort arrow?
	theRect.origin.x=NSMaxX(theRect)-NSHeight(theRect);
	theRect.size.width=NSHeight(theRect);
	return theRect;
}

@end /* NSTableHeaderCell */

//*****************************************************************************
//
// 		NSTableHeaderView 
//
//*****************************************************************************

@implementation NSTableHeaderView

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame:frameRect]))
		{
		_draggedColumn = -1;
		_resizedColumn = -1;
		}
	return self;
}

- (void) dealloc
{
	// [_tableView release];	// not retained!
	[super dealloc];
}

#define GRAB_ZONE_MARGIN 2.0

/* FIXME:
 - resizing (done by cursor rects +/- 3 px around cell borders)
 - reordering (done by tracking mouse, generating moving overlay image, setting _draggedColumn and reordering columns etc.)
 - selection/deselection of columns
 - editable header cells (double click?)
 - popup buttons as header cells (proper tracking)
 - CHECKME: checkboxes as header cells (proper state management)
 */

- (void) mouseDown:(NSEvent *) event
{
	int clickCount = [event clickCount];
	NSPoint location;	// location in view
	id aCell;			// selected cell
	int column;			// row/col of selected cell
	NSTableColumn *tableColumn=nil;
	NSRect rect;		// rect of selected cell
	NSDate *limitDate;
	NSWindow *dragWindow=nil;
	CGFloat oldWidth=0.0;
//	int mouseDownFlags = [event modifierFlags];
	location = [self convertPoint:[event locationInWindow] fromView:nil];	// location on view
	limitDate = [NSDate dateWithTimeIntervalSinceNow:0.8];	// timeout to switch to dragging
	_draggedColumn = -1;
	_resizedColumn = -1;
	column = [self columnAtPoint:location];
	if(column >= 0)
		{
			tableColumn=[[_tableView tableColumns] objectAtIndex:column];
			aCell = [tableColumn headerCell];			// cell (if any)
			rect = [self headerRectOfColumn:column];	// the real cell rect
			if(location.x >= NSMaxX(rect) - GRAB_ZONE_MARGIN && ([tableColumn resizingMask]&NSTableColumnUserResizingMask) != 0)
				_resizedColumn=column;
			else if(column > 0 && location.x <= NSMinX(rect) + GRAB_ZONE_MARGIN && ([[[_tableView tableColumns] objectAtIndex:column-1] resizingMask]&NSTableColumnUserResizingMask) != 0)
				{ // resize previous column
					column--;
					tableColumn=[[_tableView tableColumns] objectAtIndex:column];
					aCell = [tableColumn headerCell];
					rect = [self headerRectOfColumn:column];	// the real cell rect
					_resizedColumn=column;
				}
			if(_resizedColumn >= 0)
				{
					oldWidth=[tableColumn width];
					limitDate = [NSDate distantFuture];	// wait unlimited...
				}
#if 1
			NSLog(@"mouse down in col %d resize %d rect %@ cell %@", column, _resizedColumn, NSStringFromRect(rect), aCell);
#endif
		}
	while([event type] != NSLeftMouseUp)
		{ // loop outside until mouse finally goes up
			if(_resizedColumn >= 0)
				{ // resizing
					if([event type] == NSLeftMouseDragged)
						{
							[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
							// change width
							// redraw
							// invalidate cursor rects so that they are updated
						}
				}
			else if(_draggedColumn >= 0)
				{ // dragging
				if([event type] == NSLeftMouseDragged)
					{
						[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
						if(!dragWindow)
							{
								NSLog(@"start column dragging");
								// [_tableView dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
								_draggedDistance=0.0;
							}
						else
							{
								// update distance and redraw
								// and update column so tht we know on mouse up
							}
					}
				}
			else if(column >= 0 && NSMouseInRect(location, rect, [self isFlipped]))
				{ // track header cell while in initial cell or list mode
					BOOL done = NO;
					int state=[aCell state];
					[aCell setHighlighted:YES];
					[self setNeedsDisplayInRect:rect];
					done = [aCell trackMouse:event
									  inRect:rect
									  ofView:self
								untilMouseUp:[[aCell class] prefersTrackingUntilMouseUp]];			// YES if mouse went up in cell
					[aCell setHighlighted:NO];
					[self setNeedsDisplayInRect:rect];
					if(done)
						{
							[aCell setState:state == NSOffState?NSOnState:NSOffState];	// toggle state of buttons
							if([_tableView allowsColumnSelection])
								{
								// check for modifiers... Alt should always toggle (unless we must not have an empty selection)
								if([_tableView allowsMultipleSelection])
									{
									[_tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:column] byExtendingSelection:YES];	// replace
									}
								else
									[_tableView selectColumnIndexes:[NSIndexSet indexSetWithIndex:column] byExtendingSelection:NO];	// replace
								}
							else
								[_tableView setHighlightedTableColumn:tableColumn];	// no column selection - just highlight the table column
							if(clickCount == 2)
								{ // notify a double click on header cell
									if([aCell isEditable])
										{ // cell is editable
											[aCell selectWithFrame:rect
															inView:self
															editor:[_window fieldEditor:YES forObject:aCell]
														  delegate:self	
															 start:(int)0	 
															length:(int)0];
										}
									// shouldn't we handle first responder???
									if([_tableView doubleAction])
										[[_tableView target] performSelector:[_tableView doubleAction] withObject:_tableView];
								}
							else
								{
									if([[_tableView delegate] respondsToSelector:@selector(tableView:didClickTableColumn:)])
										[[_tableView delegate] tableView:_tableView didClickTableColumn:tableColumn];
									// handle first responder???
									if([_tableView action])
										[[_tableView target] performSelector:[_tableView action] withObject:_tableView];
								}
							break;
						}
					// this timeout does not work since we have an inner loop to track the cell!
					limitDate = [NSDate distantFuture];	// wait unlimited...
				}
			event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									   untilDate:limitDate
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			if(!event)
				{ // timeout: did stay on same position for 0.8 seconds
				// switch cursor to draggingHand
					_draggedColumn=column;	// force to start dragging
					limitDate = [NSDate distantFuture];	// wait unlimited...
				}
			else
				{				
#if 1
				NSLog(@"NSTableHeaderView: got next event: %@", event);
#endif
				location = [self convertPoint:[event locationInWindow] fromView:nil];	// new location
				}
		}
	if(_draggedColumn >= 0)
		{ // end dragging
#if 1
			NSLog(@"end column dragging %d -> %d", _draggedColumn, column);
#endif
			[_tableView moveColumn:_draggedColumn toColumn:column];
			if([[_tableView delegate] respondsToSelector:@selector(tableView:didDragTableColumn:)])
				[[_tableView delegate] tableView:_tableView didDragTableColumn:tableColumn];	// as in 10.5 (10.0-4 did return the column of the new position)
			// reset cursor
			_draggedColumn=-1;
		}
	if(_resizedColumn >= 0)
		{
#if 1
			NSLog(@"end column resizing %d", _resizedColumn);
#endif
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(ColumnDidResize) object:_tableView userInfo:
				[NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithInt:_resizedColumn], @"NSTableColumn",
				[NSNumber numberWithFloat:oldWidth], @"NSOldWidth",
				nil]];
			_resizedColumn=-1;
		}
}

- (void) drawRect:(NSRect)rect		
{
	NSArray *tableColumns = [_tableView tableColumns];
	NSEnumerator *e=[tableColumns objectEnumerator];
	NSTableColumn *col;
	NSTableColumn *hlcol=[_tableView highlightedTableColumn];
	int i=0;
	NSRect h = [self bounds];
	CGFloat max_X = NSMaxX(rect);
	CGFloat intercellWidth = [_tableView intercellSpacing].width;
	
	[[_tableView backgroundColor] set];
	NSRectFill(rect);
	
	while((col=[e nextObject]))
		{
		h.size.width = col->_width + intercellWidth;
		if(i != _draggedColumn)
			{
			if(NSIntersectsRect(h, rect))
				{ // is visible in rect
				NSImage *img;
				NSTableHeaderCell *cell=[col headerCell];
				if(col == hlcol || i == [_tableView selectedColumn] || [[_tableView selectedColumnIndexes] containsIndex:i])
					[[NSColor selectedControlColor] set];	// selected header cell
				else
					[[NSColor controlColor] set];
				NSRectFill(h);	// draw default background
				[cell drawWithFrame:h inView:self];
				// FIXME: should we call -drawSortIndicatorWithFrame?
				// or the cell?
				// we can define the rule that only the hlcol has a sort indicator
//				[cell drawSortIndicatorWithFrame:h inView:self ascending:YES priority:0];
				img=[_tableView indicatorImageInTableColumn:col];
				if(img)
					;	// draw indicatorImage depending on cell alignment on left or right side
				}
			else if(NSMinX(h) > max_X)
				return;	// done
			}
		else
			{ // draw dragged column background
				[[NSColor disabledControlTextColor] set];
				NSRectFill(h);	// grey background
			}
		// handle special case of _draggedDistance so that columns are virtually reordered...
		h.origin.x += h.size.width;
		i++;
		}
}

- (NSRect) headerRectOfColumn:(int)column	  
{
	NSRect h = [_tableView rectOfColumn:column];
	return (NSRect){{NSMinX(h),NSMinY(_bounds)},{NSWidth(h),NSHeight(_bounds)}};
}

- (void) resetCursorRects
{ // rebuild cursor rects for resize cursors
	NSRange columnRange = [_tableView columnsInRect:[self visibleRect]];
	NSArray *tableColumns = [_tableView tableColumns];
	int i, count;
	NSCursor *resize = [NSCursor resizeLeftRightCursor];
	CGFloat intercellWidth = [_tableView intercellSpacing].width;
	NSRect r = {{-GRAB_ZONE_MARGIN, 0}, { intercellWidth+2*GRAB_ZONE_MARGIN, NSHeight(_frame)}};
	count = NSMaxRange(columnRange);
	for (i = 0; i < count; i++)
		{
		NSTableColumn *col=[tableColumns objectAtIndex:i];
		r.origin.x += [col width];
		if(i >= columnRange.location && ([col resizingMask]&NSTableColumnUserResizingMask) != 0)
			// FIXME: on OSX the cursor changes depending on whether we are at min, max width or intermediate
			[self addCursorRect:r cursor:resize];	// we are resizable
		r.origin.x += intercellWidth;
		}
}

- (int) columnAtPoint:(NSPoint)p
{
	return [_tableView columnAtPoint:p];
}

- (void) setTableView:(NSTableView*)tview	{ _tableView=tview; }	// not retained!
- (NSTableView*) tableView					{ return _tableView; }
- (CGFloat) draggedDistance					{ return _draggedDistance; }
- (int) draggedColumn						{ return _draggedColumn; }
- (int) resizedColumn						{ return _resizedColumn; }
- (BOOL) isFlipped							{ return YES; }
- (BOOL) isOpaque							{ return YES; }				
- (BOOL) acceptsFirstResponder				{ return [_tableView acceptsFirstResponder]; }

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(id)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_tableView=[aDecoder decodeObjectForKey:@"NSTableView"];
		_draggedColumn = -1;
		_resizedColumn = -1;
		return self;
		}
	return NIMP;
}

@end /* NSTableHeaderView */

@interface _NSCornerView : NSView
@end

@implementation _NSCornerView

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(id)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		return NIMP;
	return self;
}

- (BOOL) isFlipped							{ return YES; }

@end

//*****************************************************************************
//
// 		NSTableColumn 
//
//*****************************************************************************

@implementation NSTableColumn

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%p %@: identifier=%@ sortDescriptor=%@", self, NSStringFromClass([self class]), _identifier, _sortDescriptor];
}

- (id) initWithIdentifier:(id)identifier			
{
	if((self=[super init]))
		{
		ASSIGN(_identifier, identifier);
		_headerCell = [NSTableHeaderCell new];	// create default cells
		_dataCell = [NSTextFieldCell new];		// default
		_maxWidth = 9999;
		}
	return self;
}

- (void) dealloc
{
	[_identifier release];
	[_headerCell release];
	[_dataCell release];
	[_sortDescriptor release];
//	[_tableView release];	// not retained!
	[super dealloc];
}

- (void) setWidth:(CGFloat)width
{
	if(_width == width)
		return;	// unchanged
	_width = MIN(MAX(width, _minWidth), _maxWidth);
#if 0
	NSLog(@"size column %@ to %f", self, _width);
#endif
	if(_tableView)
		{
		// post NSTableViewColumnDidResizeNotification
		// which triggers a redraw
		[_tableView setNeedsDisplay:YES];
		}
}

- (id) identifier							 { return _identifier; }
- (void) setIdentifier:(id)identifier		 { ASSIGN(_identifier, identifier); }
- (void) setTableView:(NSTableView*)table	 { _tableView=table; }	// not retained!
- (NSTableView*) tableView					 { return _tableView; }
- (void) setMinWidth:(CGFloat)minWidth 		 { _minWidth = minWidth; }
- (void) setMaxWidth:(CGFloat)maxWidth 		 { _maxWidth = maxWidth; }
- (CGFloat) minWidth						 { return _minWidth; }
- (CGFloat) maxWidth						 { return _maxWidth; }
- (CGFloat) width							 { return _width; }
- (void) setHeaderCell:(NSCell *)cell		 { ASSIGN(_headerCell, cell); }
- (void) setDataCell:(NSCell *)cell			 { ASSIGN(_dataCell, cell); }
- (id) headerCell							 { return _headerCell; }
- (id) dataCell								 { return _dataCell; }
- (id) dataCellForRow:(NSInteger)row;				 { return [self dataCell]; }
- (NSSortDescriptor *) sortDescriptorPrototype; { return _sortDescriptor; }
- (void) setSortDescriptorPrototype:(NSSortDescriptor *) desc; { ASSIGN(_sortDescriptor, desc); }
- (void) setResizingMask:(unsigned)mask;	 { _cFlags.resizingMask = mask; }
- (unsigned) resizingMask;					 { return _cFlags.resizingMask; }
- (void) setResizable:(BOOL)flag			 { _cFlags.resizingMask = flag?(NSTableColumnAutoresizingMask|NSTableColumnUserResizingMask):0; }
- (BOOL) isResizable						 { return _cFlags.resizingMask != NSTableColumnNoResizing; }
- (void) setEditable:(BOOL)flag				 { _cFlags.isEditable = flag; }
- (BOOL) isEditable							 { return _cFlags.isEditable; }

- (void) sizeToFit					
{
	CGFloat w=[_headerCell cellSize].width;
	if(w < _minWidth)
		_minWidth=w;	// reduce if needed
	if(w > _maxWidth)
		_maxWidth=w;	// extend if needed
	[self setWidth:w];	// has been changed
}

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
}

- (id) initWithCoder:(id)aDecoder
{
//	self=[super initWithCoder:aDecoder];	// not in NSObject
	if([aDecoder allowsKeyedCoding])
		{
		_identifier=[[aDecoder decodeObjectForKey:@"NSIdentifier"] retain];
		_dataCell=[[aDecoder decodeObjectForKey:@"NSDataCell"] retain];
		_headerCell=[[aDecoder decodeObjectForKey:@"NSHeaderCell"] retain];
		_sortDescriptor=[[aDecoder decodeObjectForKey:@"NSSortDescriptorPrototype"] retain];
		[_headerCell setTextColor:[NSColor headerTextColor]];
		[_headerCell setBackgroundColor:[NSColor headerColor]];
		_width=[aDecoder decodeFloatForKey:@"NSWidth"];
		_minWidth=[aDecoder decodeFloatForKey:@"NSMinWidth"];
		_maxWidth=[aDecoder decodeFloatForKey:@"NSMaxWidth"];
		[self setResizable:[aDecoder decodeBoolForKey:@"NSIsResizeable"]];
		[self setEditable:[aDecoder decodeBoolForKey:@"NSIsEditable"]];
		if([aDecoder containsValueForKey:@"NSResizingMask"])
			_cFlags.resizingMask=[aDecoder decodeIntForKey:@"NSResizingMask"];	// override if we have both
		_tableView=[aDecoder decodeObjectForKey:@"NSTableView"];	// not retained!
		return self;
		}
	return NIMP;
}

// MISSING: isHidden setHidden headerToolTip setHeaderToolTip

@end /* NSTableColumn */

//*****************************************************************************
//
// 		NSTableView 
//
//*****************************************************************************

@implementation NSTableView

+ (NSImage *) _defaultTableHeaderReverseSortImage;
{
	return [NSImage imageNamed:@"NSDescendingSortIndicator"];	// taken from documentation of -setIndicatorImage
}

+ (NSImage *) _defaultTableHeaderSortImage;
{
	return [NSImage imageNamed:@"NSAscendingSortIndicator"];	// taken from documentation of -setIndicatorImage
}

- (id) initWithFrame:(NSRect)frameRect
{
//	NSRect h = {{NSMinX(frameRect),0},{NSWidth(frameRect),20}};
	self=[super initWithFrame:frameRect];
	if(self)
		{
		_intercellSpacing = (NSSize){2,2};
		_rowHeight = 17;
		_tableColumns = [NSMutableArray new];
		_indicatorImages = [NSMutableArray new];
		_selectedColumns = [NSMutableIndexSet new];
		_selectedRows = [NSMutableIndexSet new];
		_lastSelectedRow = _lastSelectedColumn = -1;
		_editingRow = _editingColumn = -1;
		_backgroundColor = [[NSColor controlBackgroundColor] retain];
		_gridColor = [[NSColor gridColor] retain];
		_tv.allowsColumnReordering = YES;
		_tv.allowsColumnResizing = YES;
		_numberOfRows = NSNotFound;
		}
	return self;
}

- (void) dealloc
{
	[_headerView release];
	[_tableColumns release];
	[_backgroundColor release];
	[_gridColor release];
	[_selectedColumns release];
	[_selectedRows release];
	[_autosaveName release];
	[_indicatorImages release];
	[_clickedCell release];
	[super dealloc];
}

- (void) setDataSource:(id)aSource
{
#if 0
	NSLog(@"setDataSource: %@", aSource);
#endif	
	if(_dataSource == aSource)
		return;
	if (aSource && (![aSource respondsToSelector: @selector(numberOfRowsInTableView:)] || ![aSource respondsToSelector: @selector(tableView:objectValueForTableColumn:row:)]))
		[NSException raise: NSInternalInconsistencyException 
					 format: @"TableView's data source does not implement the NSTableDataSource protocol: %@", aSource];
	_dataSource=aSource;	// weak reference
	[self reloadData];
}

- (id) dataSource								{ return _dataSource; }
- (NSView*) cornerView							{ return _cornerView; }
- (NSTableHeaderView*) headerView				{ return _headerView; }
- (void) setHeaderView:(NSTableHeaderView*)h	{ ASSIGN(_headerView, h); [_headerView setTableView:self]; }
- (void) setCornerView:(NSView*)c				{ ASSIGN(_cornerView, c); }
- (id) delegate									{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;
	SEL sel;
	if(_delegate == anObject)
		return;	// no change
#define IGNORE_(notif_name) [n removeObserver:_delegate \
							   name:NSTableView##notif_name##Notification \
							   object:self]

	n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(ColumnDidMove);
		IGNORE_(ColumnDidResize);
		IGNORE_(SelectionDidChange);
		IGNORE_(SelectionIsChanging);
		}
	[super setDelegate:anObject];
	if(!anObject)
		return;

#define OBSERVE_(notif_name) \
	if ([_delegate respondsToSelector:@selector(tableView##notif_name:)]) \
		[n addObserver:_delegate \
		   selector:@selector(tableView##notif_name:) \
		   name:NSTableView##notif_name##Notification \
		   object:self]

	OBSERVE_(ColumnDidMove);
	OBSERVE_(ColumnDidResize);
	OBSERVE_(SelectionDidChange);
	OBSERVE_(SelectionIsChanging);

	sel = @selector(tableView:willDisplayCell:forTableColumn:row:);
	_tv.delegateWillDisplayCell = [_delegate respondsToSelector:sel];
	sel = @selector(tableView:shouldSelectRow:);
	_tv.delegateShouldSelectRow = [_delegate respondsToSelector:sel];
	sel = @selector(tableView:shouldSelectTableColumn:);
	_tv.delegateShouldSelectTableColumn = [_delegate respondsToSelector:sel];
	sel = @selector(selectionShouldChangeInTableView:);
	_tv.delegateSelectionShouldChangeInTableView = [_delegate respondsToSelector:sel];
	sel = @selector(tableView:shouldEditTableColumn:row:);
	_tv.delegateShouldEditTableColumn = [_delegate respondsToSelector:sel];
	sel = @selector(tableView:heightOfRow:);
	_tv.delegateProvidesHeightOfRow = [_delegate respondsToSelector:sel];
}

- (void) setUsesAlternatingRowBackgroundColors:(BOOL) flag { _tv.usesAlternatingRowBackgroundColors=flag; }
- (BOOL) usesAlternatingRowBackgroundColors; { return _tv.usesAlternatingRowBackgroundColors; }
- (BOOL) drawsGrid							{ return _tv.gridStyleMask != NSTableViewGridNone; }
- (void) setDrawsGrid:(BOOL)flag			{ _tv.gridStyleMask = flag?(NSTableViewSolidVerticalGridLineMask|
																		NSTableViewSolidHorizontalGridLineMask):
																				NSTableViewGridNone; }
- (void) setGridStyleMask:(unsigned int) mask; { _tv.gridStyleMask=mask; }
- (unsigned int) gridStyleMask;				{ return _tv.gridStyleMask; }
- (void) setBackgroundColor:(NSColor*)color	{ ASSIGN(_backgroundColor,color); }
- (void) setGridColor:(NSColor*)color		{ ASSIGN(_gridColor, color); }
- (NSColor*) backgroundColor				{ return _backgroundColor; }
- (NSColor*) gridColor						{ return _gridColor; }
- (CGFloat) rowHeight						{ return _rowHeight; }
- (void) setRowHeight:(CGFloat)rowHeight	{ _rowHeight = rowHeight; }
- (void) setIntercellSpacing:(NSSize)aSize	{ _intercellSpacing = aSize; }
- (NSSize) intercellSpacing					{ return _intercellSpacing; }
- (NSArray*) tableColumns					{ return _tableColumns; }
- (int) numberOfColumns						{ return [_tableColumns count]; }
- (int) numberOfRows						{ return _numberOfRows; }

- (void) noteNumberOfRowsChanged
{ // clear cache
	int n=_numberOfRows;
	if(!_window || !_superview || !_dataSource)
		{
#if 0
		NSLog(@"noteNumberOfRowsChanged ignored: w:%p s:%p d:%p", _window, super_view, _dataSource);
#endif
		return;	// don't ask data source before it exists
		}
	_numberOfRows=[_dataSource numberOfRowsInTableView:self];
	if(_numberOfRows == n)
		return;	// hasn't really changed
	[self noteHeightOfRowsWithIndexesChanged:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _numberOfRows)]];
}

- (void) noteHeightOfRowsWithIndexesChanged:(NSIndexSet *) idx;
{
	if(_tv.delegateProvidesHeightOfRow)
		{
		NSUInteger first=[idx firstIndex];
		while(first != NSNotFound)
			{
			// do something, i.e. update row position tree
			first=[idx indexGreaterThanIndex:first];
			}
		}
	[self tile];
}

- (void) addTableColumn:(NSTableColumn *)column 
{
	[_tableColumns addObject:column];
	[_indicatorImages addObject:[NSNull null]];
}

- (void) removeTableColumn:(NSTableColumn *)column
{
	int i=[_tableColumns indexOfObjectIdenticalTo:column];
	if(i != NSNotFound)
		{
		if(_highlightedTableColumn == column)
			_highlightedTableColumn=nil;	// remove reference
		[self deselectColumn:i];
		[_indicatorImages removeObjectAtIndex:i];
		[_tableColumns removeObjectAtIndex:i];
		}
}

- (int) columnWithIdentifier:(id)identifier 
{
	int i, count = [_tableColumns count];
	for (i = 0; i < count; i++)
		if ([[[_tableColumns objectAtIndex:i] identifier] isEqual:identifier])
			return i;
	return -1;
}

- (NSTableColumn *) tableColumnWithIdentifier:(id)identifier 
{
int index = [self columnWithIdentifier:identifier];

	return (index != -1) ? [_tableColumns objectAtIndex:index] : nil;
}

- (void) scrollRowToVisible:(int)row 
{
	[self scrollRectToVisible:[self rectOfRow:row]];
}

- (void) scrollColumnToVisible:(int)column 
{
	[self scrollRectToVisible:[self rectOfColumn:column]];
}

- (void) moveColumn:(int)column toColumn:(int)newIndex 
{
	if(column != newIndex)
		{
			[_tableColumns exchangeObjectAtIndex:column withObjectAtIndex:newIndex];
			[_window invalidateCursorRectsForView:_headerView];
			[self setNeedsDisplay:YES];	// should limit to NSUnion(both column rects)
		}
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(ColumnDidMove) object:self userInfo:
		[NSDictionary dictionaryWithObjectsAndKeys:
					[NSNumber numberWithInt:column], @"NSOldColumn",
					[NSNumber numberWithInt:newIndex], @"NSNewColumn",
					nil]];
}

- (id) target							{ return _target; }
- (void) setTarget:anObject				{ ASSIGN(_target, anObject); }
- (void) setAction:(SEL)aSelector		{ _action = aSelector; }
- (void) setDoubleAction:(SEL)aSelector	{ _doubleAction = aSelector; }
- (SEL) action							{ return _action; }
- (SEL) doubleAction					{ return _doubleAction; }
- (BOOL) isFlipped 						{ return YES; }
- (BOOL) isOpaque						{ return YES; }

- (void) setAllowsColumnReordering:(BOOL)flag { _tv.allowsColumnReordering = flag; }
- (void) setAllowsColumnResizing:(BOOL)flag	{ _tv.allowsColumnResizing = flag; }
- (void) setAutoresizesAllColumnsToFit:(BOOL)flag { _tv.autoResizingStyle = flag?NSTableViewUniformColumnAutoresizingStyle:NSTableViewLastColumnOnlyAutoresizingStyle; }
- (void) setColumnAutoresizingStyle:(NSTableViewColumnAutoresizingStyle) style { _tv.autoResizingStyle = style; }

- (BOOL) autoresizesAllColumnsToFit	{ return _tv.autoResizingStyle&NSTableViewUniformColumnAutoresizingStyle; }
- (NSTableViewColumnAutoresizingStyle) columnAutoresizingStyle	{ return _tv.autoResizingStyle; }

- (BOOL) allowsColumnReordering			{ return _tv.allowsColumnReordering; }
- (BOOL) allowsColumnResizing			{ return _tv.allowsColumnResizing; }
- (BOOL) allowsEmptySelection			{ return _tv.allowsEmptySelection; }
- (BOOL) allowsColumnSelection 			{ return _tv.allowsColumnSelection; }
- (BOOL) allowsMultipleSelection		{ return _tv.allowsMultipleSelection; }

- (void) setAllowsMultipleSelection:(BOOL)flag
{ 
	_tv.allowsMultipleSelection = flag; 
}

- (void) setAllowsEmptySelection:(BOOL)flag
{
	_tv.allowsEmptySelection = flag;
}

- (void) setAllowsColumnSelection:(BOOL)flag 
{ 
	_tv.allowsColumnSelection = flag; 
}

- (void) selectAll:(id)sender
{
	BOOL selectionDidChange = NO;
	NSRange colRange=NSMakeRange(0, [self numberOfColumns]);
	NSRange rowRange=NSMakeRange(0, [self numberOfRows]);
	if(_tv.delegateSelectionShouldChangeInTableView && ![_delegate selectionShouldChangeInTableView:self])
		return;	// not permitted by delegate
	_lastSelectedColumn = [self numberOfColumns] - 1;
	_lastSelectedRow = [self numberOfRows] - 1;
	if(![_selectedColumns containsIndexesInRange:colRange])
		{ // not yet all
		selectionDidChange = YES;
		[_selectedColumns addIndexesInRange:colRange];
		}
	if(![_selectedRows containsIndexesInRange:colRange])
		{ // not yet all
		selectionDidChange = YES;
		[_selectedRows addIndexesInRange:rowRange];
		}
	if(selectionDidChange)
		{
		[self setNeedsDisplayInRect:[self visibleRect]];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
		}
}

- (void) deselectAll:(id)sender
{
	if(!_tv.allowsEmptySelection)
		return;
	if(_tv.delegateSelectionShouldChangeInTableView && ![_delegate selectionShouldChangeInTableView:self])
		return;	// not permitted by delegate
	_lastSelectedRow = _lastSelectedColumn = -1;
	if([_selectedColumns count]+[_selectedRows count] == 0)
		return;	// already deselected all
	[_selectedColumns removeAllIndexes];	// clear
	[_selectedRows removeAllIndexes];		// clear
	[self setNeedsDisplayInRect:[self visibleRect]];
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
}

- (void) selectColumn:(int)column byExtendingSelection:(BOOL)extend
{
	// FIXME: should be based on selectIndexes
	BOOL colSelectionDidChange = NO;
	BOOL rowSelectionDidChange = NO;
	NSRect rect = [self visibleRect];
	// FIXME: check delegate to allow selection change
	if([_selectedRows count] > 0)
		{
		_lastSelectedRow = -1;
		rowSelectionDidChange=[_selectedRows count] > 0;	// there have been rows selected
		[_selectedRows removeAllIndexes];	// deselect all rows
		}

	if(!extend)
		{
		if([_selectedColumns count] != 1 || ![_selectedColumns containsIndex:column])
			{ // really change
			colSelectionDidChange = YES;
			[_selectedColumns removeAllIndexes];
			[_selectedColumns addIndex:column];	// a single selection
			}
		}
	else if (!_tv.allowsMultipleSelection)
		[NSException raise: NSInternalInconsistencyException
					format: @"Multiple selection is not allowed"];

	if(![_selectedColumns containsIndex:column])
		{ // is not same as current selection
		if(!colSelectionDidChange && !rowSelectionDidChange)
			rect = NSIntersectionRect(rect, [self rectOfColumn:column]);
		colSelectionDidChange = YES;
		[_selectedColumns addIndex:column];
		}

	_lastSelectedColumn = column;

	if(colSelectionDidChange || rowSelectionDidChange)
		{
		[self setNeedsDisplayInRect:rect];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
		}
}

- (void) selectRow:(int)row byExtendingSelection:(BOOL)extend
{
	// FIXME: should be based on selectIndexes and optimize redrawing!
	BOOL colSelectionDidChange = NO;
	BOOL rowSelectionDidChange = NO;
	// FIXME: check delegate to allow selection change
	if([_selectedColumns count] > 0)
		{ // deselect any column
		_lastSelectedColumn = -1;
		colSelectionDidChange=[_selectedColumns count] > 0;	// there have been rows selected
		if(colSelectionDidChange)
			{
			[self setNeedsDisplayInRect:[self rectOfColumn:[_selectedColumns firstIndex]]];
			[self setNeedsDisplayInRect:[self rectOfColumn:[_selectedColumns lastIndex]]];	// invalidate full range
			[_selectedColumns removeAllIndexes];	// deselect all rows
			}
		}
	
	if(!extend)
		{
		if([_selectedRows count] != 1 || ![_selectedRows containsIndex:row])
			{ // really change
			rowSelectionDidChange = YES;
			if([_selectedRows count] > 0)
				{
				[self setNeedsDisplayInRect:[self rectOfRow:[_selectedRows firstIndex]]];
				[self setNeedsDisplayInRect:[self rectOfRow:[_selectedRows lastIndex]]];	// invalidate full range
				[_selectedRows removeAllIndexes];
				}
			[_selectedRows addIndex:row];	// a single selection
			[self setNeedsDisplayInRect:[self rectOfRow:row]];
			}
		}
	else if (!_tv.allowsMultipleSelection)
		[NSException raise: NSInternalInconsistencyException
					format: @"Multiple selection is not allowed"];
	
	if(![_selectedRows containsIndex:row])
		{ // is not already part of current selection
		rowSelectionDidChange = YES;
		[_selectedRows addIndex:row];
		[self setNeedsDisplayInRect:[self rectOfRow:row]];
		}
	
	_lastSelectedRow = row;
	
	if(colSelectionDidChange || rowSelectionDidChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
}

- (void) selectColumnIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) flag;
{ // core selection method
	// FIXME:
	[self selectColumn:[indexes firstIndex] byExtendingSelection:flag];
}

- (void) selectRowIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) flag;
{ // core selection method
	BOOL colSelectionDidChange = NO;
	BOOL rowSelectionDidChange = NO;
	// FIXME:
	[self selectRow:[indexes firstIndex] byExtendingSelection:flag];
#if 0
	// FIXME: check delegate to allow selection change
	// [indexes count] == 0 is a deselection!
	if([_selectedColumns count] > 0)
		{
		_lastSelectedColumn = -1;
		colSelectionDidChange=[_selectedColumns count] > 0;	// there have been rows selected
		[_selectedColumns removeAllIndexes];	// deselect all rows
		}
	
	if(!extend)
		{
		if([_selectedRows count] != 1 || ![_selectedRows containsIndex:row])
			{ // really change
			rowSelectionDidChange = YES;
			[_selectedRows removeAllIndexes];
			[_selectedRows addIndex:row];	// a single selection
			}
		}
	else if ([indexes count] != 1 && !_tv.allowsMultipleSelection)
		[NSException raise: NSInternalInconsistencyException
					format: @"Multiple selection is not allowed"];
	
	if(![_selectedRows containsIndex:row])
		{ // is not same as current selection
		if(!colSelectionDidChange && !rowSelectionDidChange)
			rect = NSIntersectionRect(rect, [self rectOfRow:row]);
		rowSelectionDidChange = YES;
		[_selectedRows addIndex:row];
		}
	
	_lastSelectedRow = row;
	
	if(colSelectionDidChange || rowSelectionDidChange)
		{
		[self setNeedsDisplayInRect:rect];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
		}
#endif
}

- (void) deselectColumn:(int)column 
{
	// FIXME: should be based on selectIndexes
	if([_selectedColumns containsIndex:column])
		{ // is selected
		NSRect rect = [self rectOfColumn:column];
		[_selectedColumns removeIndex:column];
		if(_lastSelectedColumn == column)
			{
			_lastSelectedColumn = [_selectedColumns lastIndex];	// highest still-selected column
			if(_lastSelectedColumn == NSNotFound)
				_lastSelectedColumn=-1;
			}
		[self setNeedsDisplayInRect:rect];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
		}
}

- (void) deselectRow:(int)row 
{
	// FIXME: should be based on selectIndexes
	if([_selectedRows containsIndex:row])
		{
		NSRect rect = [self rectOfRow:row];
		[_selectedRows removeIndex:row];
		if(_lastSelectedRow == row)
			{
			_lastSelectedRow = [_selectedRows lastIndex];	// highest still-selected row
			if(_lastSelectedRow == NSNotFound)
				_lastSelectedRow=-1;
			}
		[self setNeedsDisplayInRect:rect];
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(SelectionDidChange) object: self];
		}
}

// Return index of last column/row selected or added to the selection, or -1 if no column/row is selected.
- (int) selectedColumn 					{ return _lastSelectedColumn; }
- (int) selectedRow 					{ return _lastSelectedRow; }
- (NSIndexSet *) selectedColumnIndexes 	{ return _selectedColumns; }
- (NSIndexSet *) selectedRowIndexes 	{ return _selectedRows; }
- (int) editedColumn					{ return _editingColumn; }
- (int) editedRow						{ return _editingRow; }
- (int) clickedColumn					{ return _clickedColumn; }
- (int) clickedRow						{ return _clickedRow; }

- (BOOL) isColumnSelected:(int)columnIndex 
{
	return [_selectedColumns containsIndex:columnIndex];
}

- (BOOL) isRowSelected:(int)rowIndex
{ 
	return [_selectedRows containsIndex:rowIndex];
}

- (int) numberOfSelectedColumns 
{
	return [_selectedColumns count];
}

- (int) numberOfSelectedRows 
{
	return [_selectedRows count];
}

- (NSEnumerator*) selectedColumnEnumerator
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:[_selectedColumns count]];
	int i;
	for (i = 0; i < [_selectedColumns count]; i++)
		if([_selectedColumns containsIndex:i])
			[a addObject:[NSNumber numberWithInt:i]];
	return [a objectEnumerator];
}

- (NSEnumerator*) selectedRowEnumerator
{
	NSMutableArray *a = [NSMutableArray arrayWithCapacity:[_selectedRows count]];
	int i;
	for (i = 0; i < [_selectedRows count]; i++)
		if([_selectedRows containsIndex:i])
			[a addObject:[NSNumber numberWithInt:i]];
	return [a objectEnumerator];
}

- (NSRect) rectOfColumn:(int)column
{ // Layout support
	int i;
	NSEnumerator *e;
	NSTableColumn *col;
	CGFloat x = 0;

	if(column < 0 || column >= [_tableColumns count])
		return NSZeroRect;
	e=[_tableColumns objectEnumerator];
	for (i = 0; i < column; i++)
		{
		col=[e nextObject];
		x += (col->_width + _intercellSpacing.width);
		}
	col=[e nextObject];
	return (NSRect){{x, 0}, {col->_width, NSHeight(_frame)}};
}

- (NSRect) rectOfRow:(int) row 
{ // FIXME: there should be a cache if we have millions of rows...!
	CGFloat y;
	if(_tv.delegateProvidesHeightOfRow)
		{
		CGFloat rowHeight=[_delegate tableView:self heightOfRow:row];
		// FIXME: we must sum up all rows up to the one asked for...
		// or use some tree data structure to rapidly find the row
		}
	y = (_rowHeight + _intercellSpacing.height) * row;
	return NSMakeRect(0, y, NSWidth(_frame), _rowHeight);
}

- (int) columnAtPoint:(NSPoint)point 
{
	int i=0;
	NSTableColumn *col;
	NSEnumerator *e=[_tableColumns objectEnumerator];
	CGFloat x = 0;
	while((col=[e nextObject]))
		{
		if(point.x >= x && point.x < (x + col->_width + _intercellSpacing.width))
			return i;
		x += (col->_width + _intercellSpacing.width);
		if (point.x < x)
			break;
		i++;
		}
	return -1;
}

- (NSRange) columnsInRect:(NSRect)rect 
{
	NSRange r = {0,0};
	if(NSWidth(rect) > 0 && NSHeight(rect) > 0)
		{
		int i=0;
		NSEnumerator *e=[_tableColumns objectEnumerator];
		NSTableColumn *col;
		NSRect h = _bounds;
		NSRect intersection;
		CGFloat max_X = NSMaxX(rect);

		while((col=[e nextObject]))
			{
			h.size.width = col->_width + _intercellSpacing.width;

			intersection = NSIntersectionRect(h, rect);
			if(NSWidth(intersection) > 0)
				{
				if(r.length == 0)
					r = (NSRange){i,1};	// initialize with first intersecting column
				else
					r.length++;	// one more column intersects
				}
			else if (NSMinX(h) > max_X)
				break;
			h.origin.x += h.size.width;
			i++;
			}
		}
	return r;
}

- (int) _rowAtPoint:(NSPoint)point 
{
	if(_tv.delegateProvidesHeightOfRow)
		{
		int i, count = [self numberOfRows];
		// FIXME: use the cache (binary tree?) to rapidly find row for a point if we have millions of rows
		for (i = 0; i < count; i++)
			if (NSPointInRect(point, [self rectOfRow:i]))
				return i;
		return -1;
		}
	else
		{
		if(point.y < 0 || point.y > NSMaxY(_bounds))
			return -1;	// outside bounds
		return (point.y/(_rowHeight + _intercellSpacing.height));	// we could subtract _intercellSpacing.height/2 so that it jumps halfway between the cells
		}
}

- (int) rowAtPoint:(NSPoint)point 
{ // outside existing rows returns -1
	int row=[self _rowAtPoint:point];
	if(row >= _numberOfRows)
		row=-1;
	return row;
}

- (NSRange) rowsInRect:(NSRect)rect 
{
	NSRange r;
	int r2;
	r.location=[self _rowAtPoint:rect.origin];
	if(r.location < 0)
		return NSMakeRange(0, 0);
	r2=[self _rowAtPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
	if(r2 >= (int) r.location)
		r.length=r2-r.location+1;	// round up
	else
		r.length=0;
#if OLD
	// FIXME: we should cache the row rects in some tree structure for fast(er) access
	NSRange r = {0,0};

	if (!NSIsEmptyRect(rect))
		{
		int i=0;
		while(YES)
			{ // loop until we find the first rect that is inside and then collect until we find the last one
			if(NSIntersectsRect([self rectOfRow:i], rect))
				{ // row is within rect
				if (r.length == 0)
					r = (NSRange){i,1};	// first match
				else
					r.length++;	// is still within rect
				}
			else if(r.length > 0)
				break;	// rect is the first one that is outside
			i++;
			}
		}
#endif
	return r;
}

- (NSRect) frameOfCellAtColumn:(int)column row:(int)row 
{
	return NSIntersectionRect([self rectOfRow:row], [self rectOfColumn:column]);
}

- (void) editColumn:(int)column 								// Edit fields
				row:(int)row 
				withEvent:(NSEvent*)event 
				select:(BOOL)select
{
	NSRect r;
	NSText *t;

	if (!(event) && (_editingCell))
		[_window makeFirstResponder:self];

	if (!_editingCell)
		{
		NSTableColumn *c = [_tableColumns objectAtIndex:column];
		NSString *d;

		_editingRow = row;
		_editingColumn = column;
		_editingCell = [c dataCellForRow:row];
		d = [_dataSource tableView:self objectValueForTableColumn:c row:row];
		[_editingCell setObjectValue:d];
		[_editingCell setEditable: YES];
		}

	r = [self frameOfCellAtColumn:column row:row];
	[self lockFocus];
	[self scrollRectToVisible: r];
	[self unlockFocus];

	t = [_window fieldEditor:YES forObject:_editingCell];

	if (event)
		[_editingCell editWithFrame:r
					  inView:self
					  editor:t
					  delegate:self
					  event:event];
	else
		{
		int l = (select) ? [[_editingCell stringValue] length] : 0;

		[_editingCell selectWithFrame:r
					  inView:self
					  editor:t
					  delegate:self
					  start:(int)0
					  length:l];

//		[window makeFirstResponder: t];
		}
}
															// NSText delegate
- (void) textDidBeginEditing:(NSNotification *)aNotification
{
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidBeginEditing) object: self];
}

- (void) textDidChange:(NSNotification *)aNotification
{
	if ([_editingCell respondsToSelector:@selector(textDidChange:)])
		return [_editingCell textDidChange:aNotification];
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidChange) object: self];
}

- (BOOL) textShouldBeginEditing:(NSText*)textObject
{ 
	if (_delegate && [_delegate respondsToSelector:@selector(control:textShouldBeginEditing:)])
			return [_delegate control:self textShouldBeginEditing:textObject];

	return YES; 
}

- (void) textDidEndEditing:(NSNotification *)aNotification
{
	NSNumber *code;

	NSLog(@" NSTableView textDidEndEditing ");

	[_editingCell endEditing:[aNotification object]];			
	_editingCell = nil;
	_editingColumn = _editingRow = -1;

	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidEndEditing) object: self];

	if((code = [[aNotification userInfo] objectForKey:NSTextMovement]))
		switch([code intValue])
			{
			case NSReturnTextMovement:
				[_window makeFirstResponder:self];
//				[self sendAction:[self action] to:[self target]];
				break;
			case NSTabTextMovement:					// FIX ME select next cell
			case NSBacktabTextMovement:
			case NSIllegalTextMovement:
				break;
			}
}

- (BOOL) textShouldEndEditing:(NSText*)textObject
{ 
	NSLog(@" NSTableView textShouldEndEditing ");

	if(![_window isKeyWindow])
		return NO;

	if([_editingCell isEntryAcceptable: [textObject string]])
		{
		SEL a = @selector(tableView:setObjectValue:forTableColumn:row:);

		if (_delegate && [_delegate respondsToSelector:@selector(control:textShouldEndEditing:)])
			{
			if(![_delegate control:self textShouldEndEditing:textObject])
				{
				NSBeep();

				return NO;
			}	}

		if ([_dataSource respondsToSelector: a])
			{
			NSTableColumn *col = [_tableColumns objectAtIndex:_editingColumn];

			[_dataSource tableView:self 
						 setObjectValue:[textObject string] 
						 forTableColumn:col
						 row:_editingRow];
			return YES;
		}	}

	NSBeep();												// entry not valid
	[textObject setString:[_editingCell stringValue]];

	return NO;
}

- (void) mouseDown:(NSEvent *)event
{
	NSPoint current, previous = [event locationInWindow];
	NSPoint p = [self convertPoint:previous fromView:nil];
	int i, startRow, lastRow, scrollRow=-1;
	int row = [self rowAtPoint:p];
	NSRange extend = {-1, 0}, reduce = {-1, 0};
	NSEventType eventType;
	NSEvent *lastMouseEvent=nil;
	NSRect r, visibleRect;
	NSTableColumn *clickedCol;
	BOOL scrolled=NO;

	_clickedColumn=[self columnAtPoint:p];
	_clickedRow=row;
#if 1
	NSLog(@"mouseDown row=%d col=%d rows=%d", _clickedRow, _clickedColumn, _numberOfRows);
#endif
	if(_lastSelectedRow >= 0)
		{ // pre-existing sel
		if ((_lastSelectedRow == row) && [event clickCount] > 1)									
			{ // double click on selected row
			if(_clickedRow >= 0 && _clickedColumn >= 0 && [[_tableColumns objectAtIndex:_clickedColumn] isEditable])
				[self editColumn:_clickedColumn row:row withEvent:event select:NO];
			else if(_target && _doubleAction)				// double click
				[_target performSelector:_doubleAction withObject:self];
			return;
			}
		}
	clickedCol = [_tableColumns objectAtIndex:_clickedColumn];
	if(row >= 0)
		{ // an existing row
		id data;
		_clickedCell = [[clickedCol dataCellForRow:row] copy];	// we need a copy since a single cell will be used for all rows!
		_clickedCellFrame = [self frameOfCellAtColumn:_clickedColumn row:_clickedRow];
		data=[_dataSource tableView:self objectValueForTableColumn:clickedCol row:_clickedRow];	// ask data source
		[_clickedCell setObjectValue:data];	// set as object value
		if(_tv.delegateWillDisplayCell)
			[_delegate tableView:self willDisplayCell:_clickedCell forTableColumn:clickedCol row:_clickedRow];	// give delegate a chance to modify the cell
		[self selectRow:row byExtendingSelection:NO];			// select start row
		}
	else
		_clickedCell = nil;
	startRow = lastRow = row;
	visibleRect = [self visibleRect];

	while (YES) 
		{
		eventType = [event type];
		if([event type] == NSPeriodic)
			{
			NSLog(@"periodic");
			event=lastMouseEvent;	// repeat
			continue;			
			}
		if(eventType == NSLeftMouseUp)
			break;	// done
		current = [event locationInWindow];	// update location
		if (eventType == NSLeftMouseDown || current.x != previous.x || current.y != previous.y || scrolled) 
			{ // something changed
			previous = current;
			p = [self convertPoint:current fromView:nil];
			row = [self rowAtPoint:p];
			if(row >= 0)
				{
				if(!_tv.allowsMultipleSelection)
					{
					extend = (NSRange){row, row};
					if (row != lastRow)
						reduce = (NSRange){lastRow, lastRow};
					}
				else
					{
					if(row >= startRow && lastRow >= startRow)
						{
						if(row > lastRow)
							extend = (NSRange){lastRow + 1, row};
						else
							if(row < lastRow)
								reduce = (NSRange){row + 1, lastRow};
						}
					else
						{
						if(row <= startRow && lastRow <= startRow)
							{
							if(row < lastRow)
								extend = (NSRange){row, lastRow - 1};
							else
								if(row > lastRow)
									reduce = (NSRange){lastRow, row - 1};
							}
						else							// switch over
							{
							if(lastRow < startRow)	
								reduce = (NSRange){lastRow, startRow - 1};
							else
								if(lastRow > startRow)
									reduce = (NSRange){startRow+1,lastRow};
							if(row > startRow)
								extend = (NSRange){startRow + 1, row};
							else
								if(row < startRow)
									extend = (NSRange){row, startRow - 1};
							}
						}
					}
				
				// FIXME: use selectRowIndex:byExtendingSelection
				
				if(extend.location >= 0)				// extend selection
					{
					r = [self rectOfRow: extend.location];
					r.origin.x = NSMinX(visibleRect);
					
					for (i = extend.location; i <= extend.length; i++)
						{
						[_selectedRows addIndex:i];
						[self setNeedsDisplayInRect:r];
						r.origin.y += _rowHeight + _intercellSpacing.height;
						}
					extend.location = -1;
					}
				
				if(reduce.location >= 0)				// reduce selection
					{
					r = [self rectOfRow: reduce.location];
					r.origin.x = NSMinX(visibleRect);
					
					for (i = reduce.location; i <= reduce.length; i++)
						{
						[_selectedRows removeIndex:i];
						[self setNeedsDisplayInRect:r];
						r.origin.y += _rowHeight +_intercellSpacing.height;
						}
					reduce.location = -1;
					}
				
				lastRow = row;
				}
			
			if(lastRow != scrollRow)					// auto scroll
				{
				r = [self rectOfRow: (scrollRow = lastRow)];
				r.size.width = 1;
				r.origin.x = NSMinX(visibleRect);
				if ((scrolled = [self scrollRectToVisible:r]))
					visibleRect = [self visibleRect];
				}
			if(_clickedCell && [clickedCol isEditable] && NSMouseInRect(p, _clickedCellFrame, [self isFlipped]))
				{ // it was a click into an editable cell - track while we are in the cell
				BOOL done;
				[_clickedCell setHighlighted:YES];	
				[self setNeedsDisplayInRect:_clickedCellFrame];
				done=[_clickedCell trackMouse:event inRect:_clickedCellFrame ofView:self untilMouseUp:NO];	// track until we leave the cell rect
				[_clickedCell setHighlighted:NO];	
				[self setNeedsDisplayInRect:_clickedCellFrame];
				if(done && [_dataSource respondsToSelector:@selector(tableView:setObjectValue:forTableColumn:row:)])
					{ // mouse went up in cell
					[_dataSource tableView:self setObjectValue:[_clickedCell objectValue] forTableColumn:clickedCol row:row];	// send editing result to data source
					break;	// end the tracking loop
					}
				else
					{ // we did simply leave the cell
					}
				}
			}
		if([event type] == NSLeftMouseDragged)
			{ // moved
				[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
////				rng=NSUnionRange(initialRange, NSMakeRange(pos, 0));	// extend initial selection
				if([self autoscroll:event])
					{ // repeat autoscroll
						if(!lastMouseEvent)
							[NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
						lastMouseEvent=event;					
					}
				else
					{
					if(lastMouseEvent) [NSEvent stopPeriodicEvents];
					lastMouseEvent=nil;
					}
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture] 
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
		}
	
	if(lastMouseEvent) [NSEvent stopPeriodicEvents];
	
	if(_tv.allowsMultipleSelection)
		_lastSelectedRow = (startRow > lastRow) ? startRow : lastRow;
	else
		_lastSelectedRow = lastRow;
	if (_target && _action)
		{
		_clickedRow=lastRow;
		_clickedColumn=[self columnAtPoint:p];
		[_target performSelector:_action withObject:self];	// single click
		}

	[_clickedCell release];
	_clickedCell=nil;
}

- (void) tile 
{
#if 0
	if(!_window)
		NSLog(@"tiling without window %@", self);
	if(_numberOfRows == NSNotFound)
		NSLog(@"tiling before any noteNumberOfRowsChanged", self);
#endif
	if(_window && _superview && _dataSource)
		{
		int cols;
		if(_numberOfRows == NSNotFound)
			[self noteNumberOfRowsChanged];		// read from data source
		cols = [_tableColumns count];
#if 0
		NSLog(@"tile %@", self);
		NSLog(@"rows %d", _numberOfRows);
		NSLog(@"cols %d", cols);
#endif
		if(cols > 0)
			{
			// FIXME: handle resizing policy - if resize last column to fit and minsize allows, use [[sv contentView] documentVisibleRect] as the reference
			NSScrollView *sv=[self enclosingScrollView];
			NSRect c = [self rectOfColumn: cols - 1];	// last column (c.size.height comes from current frame height and may be 0!)
			CGFloat minH = _superview?[_superview bounds].size.height:10;
			NSRect r;
			CGFloat lheight;
			if(!sv)
				{
				NSLog(@"not enclosed in scrollview %@", self);
				return;
				}
			if(!_superview)
				{
				NSLog(@"no superview %@", self);
				return;
				}
			if(_numberOfRows > 0)
				r = [self rectOfRow:_numberOfRows - 1];	// up to including last row
			else
				r = NSZeroRect;
			if(NSMaxY(r) < minH)
				r.size.height=minH-r.origin.y;	// apply minimum height so that we are asked to draw the background
#if 0
			NSLog(@"self visibleRect %@", NSStringFromRect([self visibleRect]));
			NSLog(@"superview bounds %@", NSStringFromRect([super_view bounds]));
#endif
			c.size.height = NSMaxY(r);		// adjust column rect to real height (rectOfColumn return is not reliable)
			r.size.width = NSMaxX(c);		// adjust row rect to real width (rectOfRow return is not reliable)
#if 0
			NSLog(@"tile r=%@ c=%@", NSStringFromRect(r), NSStringFromRect(c));
#endif
			r=NSUnionRect(r, c);
#if 0
			NSLog(@"union r=%@", NSStringFromRect(r));
#endif
			if(_headerView)
				{ // resize headerview if present
				NSRect h = [_headerView frame];
				h.size.width = NSMaxX(c);	// resize header to total width
#if 0
				NSLog(@"header view frame: %@", NSStringFromRect(r));
#endif
				[_headerView setFrame:h];	// adjust our header view
				[_window invalidateCursorRectsForView:_headerView];
				}
			[super setFrame:r];			// does nothing if we did not really change - otherwise notifies NSClipView
			[sv tile];	// tile scrollview (i.e. properly layout header and our superview)
			lheight=[self rowHeight]+[self intercellSpacing].height;
			[sv setVerticalLineScroll:lheight];	// scroll by one line
			[sv setVerticalPageScroll:lheight];	// scroll by one page keeping one line visible
	//		[sv setHorizontalLineScroll:??];	// smallest column? average column?
			[sv setHorizontalPageScroll:0.0];	// no additional delta
			}
		else
			NSLog(@"no columns");
		}
	[self setNeedsDisplay:YES];
#if 0
	NSLog(@"tile done");
#endif
}

- (void) setFrame:(NSRect) rect
{
	if(NSEqualRects(rect, _frame))
		return;
	[super setFrame:rect];
	[self sizeToFit];	// resizes only if needed
}

- (void) setFrameSize:(NSSize) size
{
	if(NSEqualSizes(size, _frame.size))
		return;
	[super setFrameSize:size];
	[self sizeToFit];	// resizes only if needed
}

- (void) resizeSubviewsWithOldSize:(NSSize) size
{
	if(NSEqualSizes(size, _frame.size))
		return;		// unchanged
	[self sizeToFit];	// resize components
}

- (void) viewDidMoveToWindow;
{
#if 0
	NSLog(@"movetowin w:%p %@", _window, self);
#endif
	[self reloadData];
}

- (void) viewDidMoveToSuperView;
{
#if 0
	NSLog(@"movetosuper s:%p %@", super_view, self);
#endif
	[self reloadData];
}

- (void) reloadData							
{
#if 0
	NSLog(@"reloadData: %@", self);
#endif
	// FIXME: cancel any editing
	[self noteNumberOfRowsChanged];
	[self setNeedsDisplay:YES];	// number of rows may have been unchanged so it will not have called setNeedsDisplay
#if 0
	NSLog(@"reloadData done.");
#endif
}

- (void) drawRect:(NSRect)rect								// Draw tableview
{
	NSRange rowRange = [self rowsInRect:rect];
	int i, maxRowRange = NSMaxRange(rowRange), cnt=[self numberOfColumns];
	if(!_window || _numberOfRows == NSNotFound)
		{
		NSLog(@"win=%@ _numRows=%d: %@", _window, _numberOfRows, self);
		return;	// not yet initialized
		}
#if 0
	NSLog(@"drawRect of %@: %@", self, NSStringFromRect(rect));
#endif
	[self drawBackgroundInClipRect:rect];					// draw table background

	if(_lastSelectedColumn >= 0)							// if cols selected
		{													// highlight them
		for (i = 0; i <cnt; i++)
			{
			if([_selectedColumns containsIndex:i])
				{
				NSRect c = [self rectOfColumn:i];
				c=NSIntersectionRect(rect, c);
				if(NSIsEmptyRect(c))
					continue;	// skip drawing
				[self highlightSelectionInClipRect: c];		// draw selected column background
				}
			}
		}

	for (i = rowRange.location; i < maxRowRange; i++)
		{ // draw rows
			NSRect rowClipRect=[self rectOfRow:i];
			// intersect with column range!
		if([_selectedRows containsIndex:i])
			[self highlightSelectionInClipRect: rowClipRect];	// draw selected column background
		[self drawRow:i clipRect:rowClipRect];					// cell might also highlight
		}

	if(_tv.gridStyleMask !=  NSTableViewGridNone)
		[self drawGridInClipRect:rect];						// finally draw grid
}

- (void) updateCell:(NSCell *) cell;
{
#if 0
	NSLog(@"NSTableView updateCell:%@", cell);
#endif
	if(cell == _clickedCell)
		{
#if 0
		NSLog(@"update clicked cell");
#endif
		[self setNeedsDisplayInRect:_clickedCellFrame];
		}
	return;	// don't call super to avoid recursion, since we know that we update the cell during drawRect:
}

- (NSCell *) preparedCellAtColumn:(int)col row:(int)row
{
	NSTableColumn *column;
	NSCell *aCell;
	id data;
	if(_clickedCell && _clickedRow == row && _clickedColumn == col)
		{ // we are tracking this cell - don't update from data source!
			return _clickedCell;
#if 0
			NSLog(@"draw clicked cell");
#endif
		}
	column = [_tableColumns objectAtIndex:col];
	if(row >= [self numberOfRows])
		return nil;	// row does not exist
	data=[_dataSource tableView:self objectValueForTableColumn:column row:row];	// ask data source
	if(!data)
		return nil;	// invalid data
	aCell = [column dataCellForRow:row];
#if 0
	NSLog(@"preparedCellAtColumn:%d row %d", col, row);
	NSLog(@"column=%@", column);
	NSLog(@"cell=%@", aCell);
	NSLog(@"data=%p", data);
	NSLog(@"data.class=%@", NSStringFromClass([data class]));
	NSLog(@"data=%@", data);
#endif
	[aCell setObjectValue:data];	// set data from data source
	if(_tv.delegateWillDisplayCell)
		[_delegate tableView:self willDisplayCell:aCell forTableColumn:column row:row];	// give delegate a chance to modify the cell
	return aCell;
}

- (void) drawRow:(int)row clipRect:(NSRect)rect
{ // draws no cells if row is not inside table (but updates caches etc.)
	NSUInteger i, cnt=[self numberOfColumns];
#if 0
	NSLog(@"drawRow:%d", row);
#endif
	for (i = 0; i < cnt; i++)
		{ // draw all columns of this row that are within this row clipRect
			NSCell *aCell = [self preparedCellAtColumn:i row:row];
			if(aCell)
				{
				NSRect cellRect=[self rectOfColumn:i];
				cellRect=NSIntersectionRect(cellRect, rect);
				if(NSIsEmptyRect(cellRect))
					continue;	// skip if nothing to draw
				[aCell drawWithFrame:cellRect inView:self];	// draw
				}
		}
}

- (void) highlightSelectionInClipRect:(NSRect)rect
{ // fill row/column background before drawing cell
	[[NSColor selectedControlColor] set];
	NSRectFill(rect);
}

- (void) drawGridInClipRect:(NSRect)rect
{
	BOOL horz=((_tv.gridStyleMask&NSTableViewSolidHorizontalGridLineMask) != 0);
	BOOL vert=((_tv.gridStyleMask&NSTableViewSolidVerticalGridLineMask) != 0);
	if(horz || vert)
		[_gridColor set];
	if(vert)
		{ // draw column separators
		int col=[self columnAtPoint:rect.origin];	// determine first row
		int maxcol=[_tableColumns count];
		CGFloat right=NSMaxX(rect);
		while(col < maxcol)
			{
			NSRect colRect=[self rectOfColumn:col];
			if(colRect.origin.x > right)
				break;	// column no longer inside
			[NSBezierPath strokeLineFromPoint:NSMakePoint(colRect.origin.x+colRect.size.width+1.0, colRect.origin.y)
									  toPoint:NSMakePoint(colRect.origin.x+colRect.size.width+1.0, colRect.origin.y+colRect.size.height)];
			col++;
			}
		}
	if(horz)
		{ // draw row separators
		int row=[self _rowAtPoint:rect.origin];	// determine first row
		CGFloat bottom=NSMaxY(rect);
		while(YES)
			{
			NSRect rowRect=[self rectOfRow:row];
			if(rowRect.origin.y > bottom)
				break;	// row no longer inside
			[NSBezierPath strokeLineFromPoint:NSMakePoint(rowRect.origin.x, rowRect.origin.y-1.0 /*+rowRect.size.height*/)
									  toPoint:NSMakePoint(rowRect.origin.x+rowRect.size.width, rowRect.origin.y-1.0 /*+rowRect.size.height*/)];
			row++;
			}
		}
}

- (void) drawBackgroundInClipRect:(NSRect)rect
{
	if(_tv.usesAlternatingRowBackgroundColors)
		{ // we ignore background color
		NSArray *colors=[NSColor controlAlternatingRowBackgroundColors];
		NSUInteger ncolors=[colors count];
		if(ncolors > 0)
			{
			int row=[self _rowAtPoint:rect.origin];	// determine first row
			CGFloat bottom=NSMaxY(rect);
			while(YES)
				{
				NSRect rowRect=[self rectOfRow:row];
				if(rowRect.origin.y > bottom)
					break;	// row no longer inside
				[[colors objectAtIndex:row%ncolors] setFill];	// set color (cycling through color list)
				NSRectFill(rowRect);
				row++;	// next row
				}
			return;
			}
		}
	[_backgroundColor set];	// draw uniform color
	NSRectFill(rect);
}

- (void) sizeToFit;
{
	NSUInteger cnt=[_tableColumns count];
	NSTableColumn *last=[_tableColumns lastObject];
	if(_superview && cnt > 0 && [last isResizable])
		{
		BOOL changed=YES;
		NSRect bounds=[_superview bounds];
#if 0
		NSLog(@"size to fit");
#endif
		
		// FIXME: we need to improve and correct the algorithm
		
		// we should repeat this as long as we achieve a change
		
		while(changed && NSMaxX([self rectOfColumn:cnt-1]) > NSWidth(bounds))
			{ // last column is completely outside - try to reduce all others by an evenly distributed value
			int i;
			CGFloat oversize=NSWidth(bounds)/NSMaxX([self rectOfColumn:cnt-1]);	// oversize factor
#if 0
			NSLog(@"oversize=%f", oversize);
#endif
			changed=NO;
			for(i=0; i<cnt; i++)
				{
				NSTableColumn *tc=[_tableColumns objectAtIndex:i];
				if([tc isResizable])
					{
					CGFloat width=[tc width];
					[tc setWidth:width*oversize];	// set new width (limited to minimum)
					if([tc width] != width)
						changed=YES;	// there was a real change
					}
				}
			}
		[last setWidth:(NSWidth(bounds)-NSMinX([self rectOfColumn:cnt-1]))];	// finally resize last column to fit (or minWidth)
		[self tile];
		}
}

- (void) sizeLastColumnToFit 
{ // resize last column to fit for scrollview's width
	NSUInteger cnt=[_tableColumns count];
	NSTableColumn *last=[_tableColumns lastObject];
	if(_superview && cnt > 0 && [last isResizable])
		{
		NSRect bounds=[_superview bounds];
#if 0
		NSLog(@"size last column");
#endif
		[last setWidth:(NSWidth(bounds)-NSMinX([self rectOfColumn:cnt-1]))];
		[self tile];
		}
}

// FIXME: we could simply take [[col headerCell] image]!

- (NSImage *) indicatorImageInTableColumn:(NSTableColumn *) col;
{
	int i=[_tableColumns indexOfObjectIdenticalTo:col];
	if(i != NSNotFound)
		{
		NSImage *img=[_indicatorImages objectAtIndex:i];
		if(![img isKindOfClass:[NSNull class]])
			return img;
		}
	return nil;
}

- (void) setIndicatorImage:(NSImage *) img inTableColumn:(NSTableColumn *) col;
{
	NSUInteger i=[_tableColumns indexOfObjectIdenticalTo:col];
	if(i != NSNotFound)
		{
		if(!img) img=(NSImage *) [NSNull null];
		[_indicatorImages replaceObjectAtIndex:i withObject:img];
		}
}

- (NSUInteger) draggingSourceOperationMaskForLocal:(BOOL) isLocal;
{
	return isLocal?_draggingSourceOperationMaskForLocal:_draggingSourceOperationMaskForRemote;
}

- (void) setDraggingSourceOperationMask:(NSDragOperation) mask forLocal:(BOOL) isLocal;
{
	if(isLocal)
		_draggingSourceOperationMaskForLocal=mask;
	else
		_draggingSourceOperationMaskForRemote=mask;
}

/* missing methods
-setDropRow:dropOperation:
-dragImageForRowsWithIndexes:tableColumns:event:offset:
-canDragRowsWithIndexes:atPoint:
*/

- (BOOL) autosaveTableColumns; { return _tv.autosaveTableColumns; }
- (NSString *) autosaveName; { return _autosaveName; }
- (NSTableColumn *) highlightedTableColumn; { return _highlightedTableColumn; }
- (BOOL) verticalMotionCanBeginDrag; { return _tv.verticalMotionCanBeginDrag; }
- (void) setAutosaveTableColumns:(BOOL) flag; { _tv.autosaveTableColumns=flag; }
- (void) setAutosaveName:(NSString *) name; { ASSIGN(_autosaveName, name); }
- (void) setHighlightedTableColumn:(NSTableColumn *) tc; { _highlightedTableColumn=tc; }
- (void) setVerticalMotionCanBeginDrag:(BOOL) flag; { _tv.verticalMotionCanBeginDrag=flag; }

- (NSArray *) sortDescriptors;
{
	NSMutableArray *a=[NSMutableArray arrayWithCapacity:[_tableColumns count]];
	NSEnumerator *e=[_tableColumns objectEnumerator];
	NSTableColumn *col;
	while((col=[e nextObject]))
		[a addObject:[col sortDescriptorPrototype]];	// if nil-> raises exception
	return a;
}

- (void) setSortDescriptors:(NSArray *) sd;
{
	int i, count=[sd count];
	if(count != [_tableColumns count])
		return;	// should raise exception
	for(i=0; i<count; i++)
		[[_tableColumns objectAtIndex:i] setSortDescriptorPrototype:[sd objectAtIndex:i]];
}

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeValueOfObjCType: "i" at: &_lastSelectedColumn];
	[aCoder encodeValueOfObjCType: "i" at: &_lastSelectedRow];
	[aCoder encodeObject: _headerView];
	[aCoder encodeObject: _cornerView];
}

- (id) initWithCoder:(id)aDecoder
{
#if 0
	NSLog(@"%@ initWithCoder:%@", self, aDecoder);
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		long tvFlags=[aDecoder decodeInt32ForKey:@"NSTvFlags"];
		int i;
		NSNull *null=[NSNull null];
#if 0
		NSLog(@"TvFlags=%08lx", tvFlags);
#endif
#define ALLOWSCOLUMNREORDERING ((tvFlags&0x80000000)!=0)
		_tv.allowsColumnReordering=ALLOWSCOLUMNREORDERING;
#define ALLOWSCOLUMNRESIZING ((tvFlags&0x40000000)!=0)
		_tv.allowsColumnResizing=ALLOWSCOLUMNRESIZING;
#define ALLOWSEMPTYSELECTION ((tvFlags&0x10000000)!=0)
		_tv.allowsEmptySelection=ALLOWSEMPTYSELECTION;
#define ALLOWSMULTIPLESELECTION ((tvFlags&0x08000000)!=0)
		_tv.allowsMultipleSelection=ALLOWSMULTIPLESELECTION;
#define ALLOWSCOLUMNSELECTION ((tvFlags&0x04000000)!=0)
		_tv.allowsColumnSelection=ALLOWSCOLUMNSELECTION;
#define REFUSESFIRSTRESPONDER ((tvFlags&0x00000002)!=0)
		_refusesFirstResponder=REFUSESFIRSTRESPONDER;	// NSControl
#define ALTERNATINGBACKGROUND ((tvFlags&0x00800000)!=0)
		_tv.usesAlternatingRowBackgroundColors=ALTERNATINGBACKGROUND;
		_tv.autoResizingStyle=[aDecoder decodeIntForKey:@"NSColumnAutoresizingStyle"];
		_tv.gridStyleMask=[aDecoder decodeIntForKey:@"NSGridStyleMask"];
		_tv.allowsTypeSelect=[aDecoder decodeBoolForKey:@"NSAllowsTypeSelect"];
		_intercellSpacing.height=[aDecoder decodeFloatForKey:@"NSIntercellSpacingHeight"];
		_intercellSpacing.width=[aDecoder decodeFloatForKey:@"NSIntercellSpacingWidth"];
		_rowHeight=[aDecoder decodeFloatForKey:@"NSRowHeight"];
		_backgroundColor=[[aDecoder decodeObjectForKey:@"NSBackgroundColor"] retain];
		_gridColor=[[aDecoder decodeObjectForKey:@"NSGridColor"] retain];
		_cornerView=[[aDecoder decodeObjectForKey:@"NSCornerView"] retain];
		_headerView=[[aDecoder decodeObjectForKey:@"NSHeaderView"] retain];	// will have a backreference to the tableView
		_tableColumns = [[aDecoder decodeObjectForKey:@"NSTableColumns"] retain];
		_draggingSourceOperationMaskForLocal=[aDecoder decodeIntForKey:@"NSDraggingSourceMaskForLocal"];
		_draggingSourceOperationMaskForRemote=[aDecoder decodeIntForKey:@"NSDraggingSourceMaskForNonLocal"];
		[aDecoder decodeIntForKey:@"NSTableViewDraggingDestinationStyle"];
		// [aDecoder decodeObject:@"NSSortDescriptors"]; --- isn't this stored in the table column?
		_indicatorImages = [NSMutableArray new];
		i=[_tableColumns count];
		while(i-- > 0)
			[_indicatorImages addObject:null];
		_selectedColumns = [NSMutableIndexSet new];
		_selectedRows = [NSMutableIndexSet new];
		_lastSelectedRow = _lastSelectedColumn = -1;	// empty selection
		_editingRow = _editingColumn = -1;
		[aDecoder decodeObjectForKey:@"NSAutosaveName"];
		// we might also have to load some settings from autosaved values!
		[self setDelegate:[aDecoder decodeObjectForKey:@"NSDelegate"]];	// only used for NSComboBox - dataSource&delegate are usually set by a NSNibOutletConnector
		_dataSource=[aDecoder decodeObjectForKey:@"NSDataSource"];	// not retained
#if 0
		NSLog(@"initWithCoder -> enclosingScrollView=%@", [[self enclosingScrollView] _subtreeDescription]);
#endif
		_numberOfRows=NSNotFound;	// recache
		return self;
		}
	[aDecoder decodeValueOfObjCType: "i" at: &_lastSelectedColumn];
	[aDecoder decodeValueOfObjCType: "i" at: &_lastSelectedRow];
	_headerView = [aDecoder decodeObject];
	_cornerView = [aDecoder decodeObject];
	return self;
}

@end /* NSTableView */
