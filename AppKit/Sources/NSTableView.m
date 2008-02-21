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
		_c.alignment = NSCenterTextAlignment;
		ASSIGN(_textColor, [NSColor headerTextColor]);
		ASSIGN(_backgroundColor, [NSColor headerColor]);
		}
	return self;
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	// FIXME: adjust in style and show sorting arrows/images
	float grays[] = { NSBlack, NSBlack, NSWhite, NSWhite, NSDarkGray, NSDarkGray };
	NSRectEdge *edges = BUTTON_EDGES_FLIPPED;

	if (!NSWidth(cellFrame) || !NSHeight(cellFrame))
		return;

	_controlView = controlView;							// last view drawn in

	cellFrame = NSDrawTiledRects(cellFrame, cellFrame, edges, grays, 6);
	if(_c.highlighted)
		[_backgroundColor set];	// is this a system constant or the background color?
	else
		[[NSColor controlHighlightColor] set];	// unselected header
	NSRectFill(cellFrame);

	cellFrame.origin.y += 1;
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void) drawSortIndicatorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView ascending:(BOOL) ascending priority:(int) priority;
{
	NIMP;
}

- (NSRect) sortIndicatorRectForBounds:(NSRect) theRect;
{
	NIMP;
	return NSZeroRect;
}

@end /* NSTableHeaderCell */

//*****************************************************************************
//
// 		NSTableDataCell 
//
//*****************************************************************************

@implementation NSTableDataCell	// a simple text cell

- (id) initTextCell:(NSString *)aString
{
	if((self=[super initTextCell:aString]))
		{
		_c.editable = NO;
		_c.selectable = NO;
		_c.bezeled = NO;
		ASSIGN(_backgroundColor, [NSColor controlBackgroundColor]); 
		}
	return self;
}

- (void) dealloc
{
	_contents = nil;
	[super dealloc];
}

- (void) setObjectValue:(id)anObject 			{ _contents = anObject; }
// - (NSColor*) backgroundColor					{ return [NSColor whiteColor];}

- (void) highlight:(BOOL)lit
		 withFrame:(NSRect)cellFrame						
		 inView:(NSView *)controlView					
{
	_c.highlighted = lit;
	[self drawInteriorWithFrame:cellFrame inView:controlView];
	_c.highlighted = NO;
}											

@end /* NSTableDataCell */

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
		}
	return self;
}

- (void) dealloc
{
	// [_tableView release];	// not retained!
	[super dealloc];
}

- (void) mouseDown:(NSEvent *)event
{
	NSEventType eventType;
	NSPoint current = [event locationInWindow];
	NSPoint p = [self convertPoint:current fromView:nil];
	NSPoint previous = current;
	int col = [_tableView columnAtPoint:p];
	NSDate *distantFuture = [NSDate distantFuture];
	NSRect c = [self visibleRect];
	BOOL scrolled = NO;
	BOOL resizing = (col == NSNotFound || [NSCursor currentCursor] == [NSCursor resizeLeftRightCursor]);
	
	if (![_tableView allowsColumnReordering])
		return;
	
	if (resizing && ![_tableView allowsColumnResizing])
		return;
#if 1
	NSLog(@"mouseDown headerview");
#endif
	[NSEvent startPeriodicEventsAfterDelay:0.05 withPeriod:0.05];
	[self lockFocus];

	if(resizing)
		{
		NSRect t, u, d = {{0,0},{2,1}};
		BOOL resizable;
		NSPoint o = p;
		NSTableColumn *column;
		float minWidth=0, maxWidth=0;
		NSRect f = [_tableView visibleRect];

		c.size.height = NSMaxY(c) + NSHeight(f);
		NSRectClip(c);
		[[NSColor lightGrayColor] set];
		u.origin.x = -1;
		o.x -= [_tableView intercellSpacing].width;
		while((col = [_tableView columnAtPoint:o]) == NSNotFound && o.x > 0)
			o.x -= 1;
		if(col == NSNotFound)
			{
			[self unlockFocus];
			[NSException raise: NSInternalInconsistencyException 
						 format: @"Unable to determine column to be resized"];
			}
		column = [[_tableView tableColumns] objectAtIndex:col];
		t = [_tableView rectOfColumn:col];

		if((resizable = ([column resizingMask]&NSTableColumnUserResizingMask)))
			{
			minWidth = [column minWidth];
			maxWidth = [column maxWidth];
			}

		while ((eventType = [event type]) != NSLeftMouseUp) 
			{
			if (eventType != NSPeriodic)
				current = [event locationInWindow];
			else
				{
				if (current.x != previous.x || scrolled) 
					{
					NSPoint p = [self convertPoint:current fromView:nil];
	
					if(resizable)
						{
						float delta = p.x - NSMinX(t);
	
						if(delta < minWidth)
							p.x = NSMinX(t) + minWidth;
						else
							if(delta > maxWidth)
								p.x = NSMinX(t) + maxWidth;
						}
					else
						p.x = NSMaxX(t);
	
					if(NSMinX(u) >= 0)
						NSRectFillUsingOperation(u, NSCompositeXOR);
					d.origin.x = p.x;
					d.origin.y = f.origin.y;
					if((scrolled = [_tableView scrollRectToVisible:d]))
						{
						[self scrollRectToVisible:(NSRect){{p.x,0},d.size}];
						[[NSColor lightGrayColor] set];
						}
	
					u = (NSRect){{p.x,0},{2,NSHeight(c)}};
					NSRectFillUsingOperation(u, NSCompositeXOR);
					[_window flushWindow];
					}
				}
	
			event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									   untilDate:distantFuture 
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			}
	
		[column setWidth:(NSMinX(u) - NSMinX(t))];
#if 1
		NSLog(@"col %d setWidth: %f\n", col, (NSMinX(u) - NSMinX(t)));
#endif
		c = [self visibleRect];
		c.size.width = c.size.width - (NSMinX(t) - NSMinX(c));
		c.origin.x = NSMinX(t);
		[self drawRect:c];
		f.origin.x = c.origin.x;
		f.size.width = c.size.width;
		[NSCursor pop];
		[_tableView setNeedsDisplayInRect:f];
		}
	else
		{
		NSPoint lastPoint = p;
		NSTableColumn *column = [[_tableView tableColumns] objectAtIndex:col];
		NSTableHeaderCell *headerCell = [column headerCell];
		NSRect h = [self headerRectOfColumn:col];
		NSRect oldRect = h, u, d = {{0,0},{2,1}};
		int cRepGState, colUnder = -1;
		NSRect cRepBounds, f;
		NSColor *tableBackground = [_tableView backgroundColor];
		float intercellWidth = [_tableView intercellSpacing].width;
		BOOL wasSelected, movedColumn = NO;
		NSRect t = [_tableView visibleRect];

		_draggedColumn = col;

		if(!(wasSelected = [_tableView isColumnSelected:col]))
			{
			[_tableView selectColumn:col byExtendingSelection:NO];
			[_tableView displayIfNeededInRect:t];
			}
		f = u = [_tableView rectOfColumn:col];

		c.size.height = NSMaxY(c) + NSHeight(t);		// clip to scrollview's
		NSRectClip(c);									// document rect 
		u.size.height = NSHeight(c);

		while ((eventType = [event type]) != NSLeftMouseUp) 
			{
			if (eventType != NSPeriodic)
				current = [event locationInWindow];
			else
				{
				if (current.x != previous.x || scrolled) 
					{
					NSPoint p = [self convertPoint:current fromView:nil];
					float delta = p.x - lastPoint.x;
					cRepGState = [[NSView focusView] gState];
					if(!_headerDragImage)				// lock focus / render
						{								// into image cache
						NSColor *color = [headerCell backgroundColor];
						NSAffineTransform *at;
						cRepBounds = (NSRect){{0,0},u.size};			
						_headerDragImage = [NSImage alloc];
						[_headerDragImage initWithSize:u.size];
						
						[_headerDragImage lockFocusOnRepresentation:nil];
						
						u.origin.y = NSMinY(t);
						at=[NSAffineTransform transform];
						[at translateXBy:-NSMinX(u) yBy:NSHeight(_frame) - NSMinY(u)];
						[at concat];
						[_tableView drawRect:u];
						[at translateXBy:0 yBy:-(NSHeight(_frame) - NSMinY(u))];
						[at concat];
						[headerCell setBackgroundColor:[NSColor blackColor]];
						[headerCell drawWithFrame:h inView:self];
						[headerCell setBackgroundColor:color];	// restore
						[at translateXBy:-NSMinX(u) yBy:0];	// is this required? not if unlock restores the graphics state
						[at concat];
						[_headerDragImage unlockFocus];
						[_tableView deselectColumn:col];
						movedColumn = YES;
						}
	
					previous = current;
					h.origin.x += delta;
					h.origin.x = MAX(0, NSMinX(h));			// limit movement
					if(NSMaxX(h) > NSWidth(_bounds))			// to view bounds
						h.origin.x = NSWidth(_bounds) - NSWidth(h);
	
					if (NSMinX(h) != NSMinX(oldRect) || scrolled) 
						{
						if(delta < 0)
							{									// moving left
							if((NSMinX(h) < NSMinX(u)) || (colUnder == -1))
								col = [_tableView columnAtPoint:h.origin];
							}
						else
							{									// moving right
							NSPoint m = {NSMaxX(h), NSMinY(h)};
						
							if((m.x > NSMaxX(u)) || (colUnder == -1))
								col = [_tableView columnAtPoint:m];
							}
												// move columns if needed and
						if(col != NSNotFound)	// not in between columns
							{
							if(col != colUnder)
								{
								if(col > _draggedColumn + 1)
									col = _draggedColumn + 1;
								else
									if(col < _draggedColumn - 1)
										col = _draggedColumn - 1;
								colUnder = col;
								u = [self headerRectOfColumn:col];
								}
							
							if(delta < 0)						// moving left
								{
								if(NSMinX(h) < NSMidX(u))
									{
									[_tableView moveColumn:_draggedColumn 
												toColumn:col];
									oldRect = NSUnionRect(oldRect, u);
									oldRect = NSUnionRect(oldRect, f);
									_draggedColumn = col;
									f = [_tableView rectOfColumn:col];
								}	}
							else								// moving right
								{
								float maxX = NSMaxX(h);
							
								if(maxX > NSMidX(u))
									{
									[_tableView moveColumn:_draggedColumn 
												toColumn:col];
									oldRect = NSUnionRect(oldRect, u);
									oldRect = NSUnionRect(oldRect, f);
									_draggedColumn = col;
									f = [_tableView rectOfColumn:col];
							}	}	}
	
						t.origin.x = oldRect.origin.x;
						oldRect.size.width += intercellWidth;
						t.size.width = oldRect.size.width;
	
						d.origin.x = p.x;
						d.origin.y = t.origin.y;
						if((scrolled = [_tableView scrollRectToVisible:d]))
						   [self scrollRectToVisible:(NSRect){{p.x,0},d.size}];
	
						[self drawRect:oldRect];
	
						[_tableView lockFocus];
						[_tableView drawRect:t];
						[tableBackground set];
						NSRectFill(f);
						[_tableView unlockFocus];

						NSCopyBits(cRepGState, cRepBounds, h.origin);	// FIXME: where are we locked on?
	
						oldRect.origin.x = NSMinX(h);
						oldRect.size.width = NSWidth(h);
						[_window flushWindow];
						lastPoint = p;
						}
					}
				}
	
			event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									   untilDate:distantFuture 
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:YES];
			}
	
		if (movedColumn)
			[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(ColumnDidMove) object:_tableView];

		if(!wasSelected || movedColumn)
			[_tableView selectColumn:_draggedColumn byExtendingSelection:NO];
		else
			[_tableView deselectColumn:_draggedColumn];
	
		oldRect = NSUnionRect(oldRect, [self headerRectOfColumn:_draggedColumn]);
		_draggedColumn = -1;
		[self drawRect:oldRect];
	
		t.origin.x = oldRect.origin.x;
		t.size.width = oldRect.size.width;
		[_tableView setNeedsDisplayInRect:t];

		[_headerDragImage release];
		_headerDragImage = nil;
		}

	[_window flushWindow];
	[self unlockFocus];
	[NSEvent stopPeriodicEvents];
	[_window invalidateCursorRectsForView:self];
}

- (void) drawRect:(NSRect)rect		
{
	NSArray *tableColumns = [_tableView tableColumns];
	NSEnumerator *e=[tableColumns objectEnumerator];
	NSTableColumn *col;
	NSTableColumn *hlcol=[_tableView highlightedTableColumn];
	int i=0;
	NSRect h = _bounds, aRect;
	float max_X = NSMaxX(rect);
	float intercellWidth = [_tableView intercellSpacing].width;
	
	[[_tableView backgroundColor] set];
	NSRectFill(rect);
	
	while((col=[e nextObject]))
		{
		h.size.width = col->_width + intercellWidth;
		if(i != _draggedColumn)
			{
			aRect = NSIntersectionRect(h, rect);
			if(NSWidth(aRect) > 0)
				{
				NSImage *img;
				[[col headerCell] highlight:(col == hlcol) withFrame:h inView:self];
				// FIXME: or should we call -drawSortIndicatorWithFrame?
//				[[col headerCell] drawSortIndicatorWithFrame:h inView:self ascending:YES priority:0];
				img=[_tableView indicatorImageInTableColumn:col];
				if(img)
					;	// draw indicatorImage depending on cell alignment on left or right side
				}
			else if(NSMinX(h) > max_X)
				return;
			}
		h.origin.x += h.size.width;
		}
	i++;
}

- (NSRect) headerRectOfColumn:(int)column	  
{
	NSRect h = [_tableView rectOfColumn:column];
	return (NSRect){{NSMinX(h),NSMinY(_bounds)},{NSWidth(h),NSHeight(_bounds)}};
}

- (void) resetCursorRects
{
	NSRange columnRange = [_tableView columnsInRect:[self visibleRect]];
	NSArray *tableColumns = [_tableView tableColumns];
	int i, count;
	NSCursor *resize = [NSCursor resizeLeftRightCursor];
	float intercellWidth = [_tableView intercellSpacing].width;
	NSRect r = {{0,0}, {MAX(1, intercellWidth), NSHeight(_frame)}};
	
	count = NSMaxRange(columnRange);
	for (i = 0; i < count; i++)
		{
		r.origin.x += ((NSTableColumn *) [tableColumns objectAtIndex:i])->_width;
		if(i >= columnRange.location)
			[self addCursorRect:r cursor:resize];
		r.origin.x += intercellWidth;
		}
}

- (int) columnAtPoint:(NSPoint)p
{
	return [_tableView columnAtPoint:p];
}

- (void) setTableView:(NSTableView*)tview	{ _tableView=tview; }	// not retained!
- (NSTableView*) tableView					{ return _tableView; }
- (float) draggedDistance					{ return _draggedDistance; }
- (int) draggedColumn						{ return _draggedColumn; }
- (int) resizedColumn						{ return -1; }
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
	return [NSString stringWithFormat:@"%p %@: identifier=%@ sortDescriptor=%@", self, NSStringFromClass(isa), _identifier, _sortDescriptor];
}

- (id) initWithIdentifier:(id)identifier			
{
	if((self=[super init]))
		{
		ASSIGN(_identifier, identifier);
		_headerCell = [NSTableHeaderCell new];	// create default cells
		_dataCell = [NSTableDataCell new];
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

- (void) setWidth:(float)width
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
- (void) setMinWidth:(float)minWidth 		 { _minWidth = minWidth; }
- (void) setMaxWidth:(float)maxWidth 		 { _maxWidth = maxWidth; }
- (float) minWidth							 { return _minWidth; }
- (float) maxWidth							 { return _maxWidth; }
- (float) width								 { return _width; }
- (void) setHeaderCell:(NSCell *)cell		 { ASSIGN(_headerCell, cell); }
- (void) setDataCell:(NSCell *)cell			 { ASSIGN(_dataCell, cell); }
- (id) headerCell							 { return _headerCell; }
- (id) dataCell								 { return _dataCell; }
- (id) dataCellForRow:(int)row;				 { return _dataCell; }
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
	float w=[_headerCell cellSize].width;
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
	NSRect h = {{NSMinX(frameRect),0},{NSWidth(frameRect),20}};
	self=[super initWithFrame:frameRect];
	if(self)
		{
		_intercellSpacing = (NSSize){2,2};
		_rowHeight = 17;
		_headerView = [[NSTableHeaderView alloc] initWithFrame:h];
		[_headerView setTableView:self];
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

- (id) dataSource							{ return _dataSource; }
- (NSView*) cornerView						{ return _cornerView; }
- (NSTableHeaderView*) headerView			{ return _headerView; }
- (void) setHeaderView:(NSTableHeaderView*)h{ ASSIGN(_headerView, h); }
- (void) setCornerView:(NSView*)cornerView	{ ASSIGN(_cornerView,cornerView); }
- (id) delegate								{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;
	SEL sel;
	if(_delegate == anObject)
		return;
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
//	ASSIGN(_delegate, anObject);
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
- (float) rowHeight							{ return _rowHeight; }
- (void) setRowHeight:(float)rowHeight		{ _rowHeight = rowHeight; }
- (void) setIntercellSpacing:(NSSize)aSize	{ _intercellSpacing = aSize; }
- (NSSize) intercellSpacing					{ return _intercellSpacing; }
- (NSArray*) tableColumns					{ return _tableColumns; }
- (int) numberOfColumns						{ return [_tableColumns count]; }
- (int) numberOfRows						{ return _numberOfRows; }

- (void) noteNumberOfRowsChanged
{ // clear cache
	int n=_numberOfRows;
	if(!_window || !super_view || !_dataSource)
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
		unsigned first=[idx firstIndex];
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
	NSTableColumn *c = [_tableColumns objectAtIndex:column];

	[_tableColumns removeObjectAtIndex:column];
	[_tableColumns insertObject:c atIndex:newIndex];

	if ([_headerView draggedColumn] == -1)				// if not dragging
		[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(ColumnDidMove) object: self];
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
	NIMP;
}

- (void) selectRowIndexes:(NSIndexSet *) indexes byExtendingSelection:(BOOL) flag;
{ // core selection method
	BOOL colSelectionDidChange = NO;
	BOOL rowSelectionDidChange = NO;
	NIMP;
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
	NSMutableArray *a = [NSMutableArray new];
	int i;
	for (i = 0; i < [_selectedColumns count]; i++)
		if([_selectedColumns containsIndex:i])
			[a addObject:[NSNumber numberWithInt:i]];
	return [a objectEnumerator];
}

- (NSEnumerator*) selectedRowEnumerator
{
	NSMutableArray *a = [NSMutableArray new];
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
	float x = 0;

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
	float y;
	if(_tv.delegateProvidesHeightOfRow)
		{
		float rowHeight=[_delegate tableView:self heightOfRow:row];
		// and: we must sum up all rows up to the one asked for...
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
	float x = 0;
	while((col=[e nextObject]))
		{
		if(point.x >= x && point.x < (x + col->_width))
			return i;
		x += (col->_width + _intercellSpacing.width);
		if (point.x < x)
			break;
		i++;
		}
	
	return NSNotFound;
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
		float max_X = NSMaxX(rect);

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

	[NSEvent startPeriodicEventsAfterDelay:0.05 withPeriod:0.03];
	
	while (YES) 
		{
		eventType = [event type];
		if(eventType == NSLeftMouseUp)
			break;	// done
		// 
		// we should make periodic events after some delay simply call [self autoscroll:lastmouse] while the mouse is outside of a certain inner frame
		//
		if (eventType != NSPeriodic)
			current = [event locationInWindow];	// update location
		if (eventType == NSLeftMouseDown || eventType == NSPeriodic || current.x != previous.x || current.y != previous.y || scrolled) 
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
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture] 
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
		}

	[NSEvent stopPeriodicEvents];
	
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
	if(_window && super_view && _dataSource)
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
			NSRect h = [_headerView frame];
			float minH = super_view?[super_view bounds].size.height:10;
			NSRect r;
			float lheight;
			if(!sv || !_headerView || !super_view)
				{
				NSLog(@"can't tile %@", self);
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
			h.size.width = NSMaxX(c);	// resize header to total width
#if 0
			NSLog(@"header view frame: %@", NSStringFromRect(r));
#endif
			[_headerView setFrame:h];	// adjust our header view
										// [_headerView resetCursorRects];
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
	// end any editing
	[self noteNumberOfRowsChanged];
#if 0
	NSLog(@"reloadData done.");
#endif
}

- (void) drawRect:(NSRect)rect								// Draw tableview
{
	NSRange rowRange = [self rowsInRect:rect];
	NSRect rowClipRect;
	int i, maxRowRange = NSMaxRange(rowRange);
	if(!_window || _numberOfRows == NSNotFound)
		{
		NSLog(@"win=%@ _numRows=%d: %@", _window, _numberOfRows, self);
		return;	// not yet initialized
		}
#if 0
	NSLog(@"drawRect of %@: %@", self, NSStringFromRect(rect));
#endif
	if(_cacheOrigin != NSMinX(rect) || (_cacheWidth != NSWidth(rect)))
		{
		_cacheOrigin = NSMinX(rect);						// cache col origin
		_cacheWidth = NSWidth(rect);						// and size info
		_columnRange = [self columnsInRect:rect];
		_cachedColOrigin = NSMinX([self rectOfColumn:_columnRange.location]);
		}

	[self drawBackgroundInClipRect:rect];					// draw table background

	if(_lastSelectedColumn >= 0)							// if cols selected
		{													// highlight them
		int maxColRange = NSMaxRange(_columnRange);
		for (i = _columnRange.location; i <= maxColRange; i++)
			{
			if([_selectedColumns containsIndex:i])
				{
				NSRect c = NSIntersectionRect(rect, [self rectOfColumn:i]);
				[self highlightSelectionInClipRect: c];		// draw selected column background
				}
			}
		}

	for (i = rowRange.location; i < maxRowRange; i++)
		{ // draw rows
		rowClipRect=[self rectOfRow:i];
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

- (void) drawRow:(int)row clipRect:(NSRect)rect
{ // draws empty cells if row is not inside table
	int i, maxColRange;
#if 0
	NSLog(@"drawRow:%d", row);
#endif
	if(_cacheOrigin != NSMinX(rect) || (_cacheWidth != NSWidth(rect)))
		{
#if 0
		NSLog(@"drawRow: recache");
#endif
		_cacheOrigin = NSMinX(rect);						// cache col origin
		_cacheWidth = NSWidth(rect);						// and size info
		_columnRange = [self columnsInRect:rect];
		_cachedColOrigin = NSMinX([self rectOfColumn:_columnRange.location]);
		}

	maxColRange = NSMaxRange(_columnRange);
	rect.origin.x = _cachedColOrigin;

	for (i = _columnRange.location; i < maxColRange; i++)
		{ // draw all columns of this row that are visible
		NSTableColumn *col = [_tableColumns objectAtIndex:i];
		rect.size.width = col->_width;
		if(_clickedCell && _clickedRow == row && _clickedColumn == i)
			{ // we are tracking this cell - don't update from data source!
#if 0
			NSLog(@"draw clicked cell");
#endif
			[_clickedCell drawWithFrame:rect inView:self];
			}
		else
			{ // get from data source
			NSTableDataCell *aCell = [col dataCellForRow:row];
			id data;
			if(row < [self numberOfRows])
				data=[_dataSource tableView:self objectValueForTableColumn:col row:row];	// ask data source
			else
				data=nil;
#if 0
			NSLog(@"drawRow:%d column %d", row, i);
			NSLog(@"col=%@", col);
			NSLog(@"cel=%@", aCell);
			NSLog(@"data=%@", data);
#endif
			if(data)
				{ // set data from data source
				[aCell setObjectValue:data];
				if(_tv.delegateWillDisplayCell)
					[_delegate tableView:self willDisplayCell:aCell forTableColumn:col row:row];	// give delegate a chance to modify the cell
				[aCell drawWithFrame:rect inView:self];
				}
			}
		rect.origin.x = NSMaxX(rect) + _intercellSpacing.width;
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
	if(horz)
		{
		int col=[self columnAtPoint:rect.origin];	// determine first row
		int maxcol=[_tableColumns count];
		float right=NSMaxX(rect);
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
	if(vert)
		{
		int row=[self _rowAtPoint:rect.origin];	// determine first row
		float bottom=NSMaxY(rect);
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
		unsigned int ncolors=[colors count];
		if(ncolors > 0)
			{
			int row=[self _rowAtPoint:rect.origin];	// determine first row
			float bottom=NSMaxY(rect);
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
	unsigned cnt=[_tableColumns count];
	NSTableColumn *last=[_tableColumns lastObject];
	if(super_view && cnt > 0 && [last isResizable])
		{
		BOOL changed=YES;
		NSRect bounds=[super_view bounds];
#if 0
		NSLog(@"size to fit");
#endif
		
		// FIXME: we need to improve and correct the algorithm
		
		// we should repeat this as long as we achieve a change
		
		while(changed && NSMaxX([self rectOfColumn:cnt-1]) > NSWidth(bounds))
			{ // last column is completely outside - try to reduce all others by an evenly distributed value
			int i;
			float oversize=NSWidth(bounds)/NSMaxX([self rectOfColumn:cnt-1]);	// oversize factor
#if 0
			NSLog(@"oversize=%f", oversize);
#endif
			changed=NO;
			for(i=0; i<cnt; i++)
				{
				NSTableColumn *tc=[_tableColumns objectAtIndex:i];
				if([tc isResizable])
					{
					float width=[tc width];
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
	unsigned cnt=[_tableColumns count];
	NSTableColumn *last=[_tableColumns lastObject];
	if(super_view && cnt > 0 && [last isResizable])
		{
		NSRect bounds=[super_view bounds];
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
	int i=[_tableColumns indexOfObjectIdenticalTo:col];
	if(i != NSNotFound)
		{
		if(!img) img=(NSImage *) [NSNull null];
		[_indicatorImages replaceObjectAtIndex:i withObject:img];
		}
}

- (unsigned int) draggingSourceOperationMaskForLocal:(BOOL) isLocal;
{
	return isLocal?_draggingSourceOperationMaskForLocal:_draggingSourceOperationMaskForRemote;
}

- (void) setDraggingSourceOperationMask:(unsigned int) mask forLocal:(BOOL) isLocal;
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
		NSLog(@"initWithCoder -> enclosingScrollView=%@", [[self enclosingScrollView] _descriptionWithSubviews]);
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
