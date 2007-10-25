/* 
   NSComboBox.m

   Control which combines a textfield and a popup list.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSAutoreleasePool.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSComboBox.h>
#import <AppKit/NSPopUpButtonCell.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSPanel.h>

#import "NSAppKitPrivate.h"

@interface NSComboTableView : NSTableView
@end

@implementation NSComboTableView
// change behaviour as needed for a combo box
// should handle initWithCoder and decode NSDataSource
@end

@implementation NSComboBoxCell (ComboBoxCellTableViewDataSource)

- (id) tableView:(NSTableView *)aTableView
	   objectValueForTableColumn:(NSTableColumn *)aTableColumn 
	   row:(int)row
{
    return [self itemObjectValueAtIndex: row];
}

- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self numberOfItems];
}

@end


@implementation NSComboBoxCell

- (void) _setupButtonCell;
{
	_buttonCell=[[NSPopUpButtonCell alloc] initTextCell:@"" pullsDown:YES];
	[(NSPopUpButtonCell *) _buttonCell setPreferredEdge:NSMaxYEdge];	// FIXME: why do we need this? because our NSControl is flipped?
	[(NSPopUpButtonCell *) _buttonCell addItemWithTitle:@""];			// don't draw title
}

- (id) initTextCell:(NSString *)aString
{
	if((self=[super initTextCell:aString]))
		{
		[self _setupButtonCell];
		_popUpList = [NSMutableArray new];
		_itemHeight=16.0;
		}
	return self;
}

- (void) dealloc
{
	[self _popDown];
	[[_tableView window] release];
	[_tableView release];
	[_buttonCell release];
	[_popUpList release];
	[_dataSource release];
	[super dealloc];
}

- (void) setHasVerticalScroller:(BOOL)flag	{ _cbc.hasVerticalScroller = flag;}
- (void) setIntercellSpacing:(NSSize)aSize	{ _intercellSpacing = aSize; }
- (void) setItemHeight:(float)itemHeight	{ _itemHeight = itemHeight; }
- (void) setNumberOfVisibleItems:(int)v		{ _visibleItems = v; }
- (void) setUsesDataSource:(BOOL)flag		{ _cbc.usesDataSource = flag; }
- (BOOL) usesDataSource						{ return _cbc.usesDataSource; }
- (BOOL) completes							{ return _cbc.completes; }
- (BOOL) isButtonBordered					{ return _cbc.buttonBordered; }
- (void) setCompletes:(BOOL)flag			{ _cbc.completes=flag; }
- (void) setButtonBordered:(BOOL)flag		{ _cbc.buttonBordered=flag; }

- (id) dataSource							{ return _dataSource; }

- (void) setDataSource:(id)aSource
{
	SEL a = @selector(numberOfItemsInComboBoxCell:);
	SEL b = @selector(comboBoxCell:objectValueForItemAtIndex:);

	if (!_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an external datasource");

	if (aSource && (![aSource respondsToSelector: a] || ![aSource respondsToSelector: b]))
		NSLog(@"dataSource does not implement NSComboBoxCellDataSource protocol: %@", aSource);

	ASSIGN(_dataSource, aSource);
	if (!_tableView)
		_tableView = [[NSComboTableView alloc] initWithFrame:NSZeroRect];
	[_tableView setDataSource:self];
}

- (void) selectItemAtIndex:(int)index
{
	[_tableView selectRow:index byExtendingSelection:NO];
}

- (void) deselectItemAtIndex:(int)index
{
	[_tableView deselectRow:index];
}

- (int) indexOfSelectedItem
{
	return [_tableView selectedRow];
}

- (int) numberOfItems
{
#if 1
	NSLog(@"numberOfItems: %@", self);
#endif
	if (_cbc.usesDataSource)
		return [_dataSource numberOfItemsInComboBoxCell: self];
    return [_popUpList count];
}

- (int) numberOfVisibleItems			{ return _visibleItems; }
- (BOOL) hasVerticalScroller			{ return YES; }
- (NSSize) intercellSpacing				{ return _intercellSpacing; }
- (float) itemHeight					{ return _itemHeight; }

- (void) addItemWithObjectValue:(id)object
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList addObject:object];
}

- (void) addItemsWithObjectValues:(NSArray *)objects
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList addObjectsFromArray: objects];
}

- (void) insertItemWithObjectValue:(id)object atIndex:(int)index
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList insertObject:object atIndex:index];
}

- (void) removeItemWithObjectValue:(id)object
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList removeObjectIdenticalTo:object];
}

- (void) removeItemAtIndex:(int)index
{ 
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList removeObjectAtIndex:index];
}

- (void) removeAllItems
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		[_popUpList removeAllObjects];
}

- (void) selectItemWithObjectValue:(id)object
{
	[self selectItemAtIndex: [self indexOfItemWithObjectValue:object]];
}

- (id) itemObjectValueAtIndex:(int)index
{
	if (_cbc.usesDataSource)
		return [_dataSource comboBoxCell:self objectValueForItemAtIndex:index];

    return [_popUpList objectAtIndex:index];
}

- (id) objectValueOfSelectedItem
{
	return [self itemObjectValueAtIndex: [_tableView selectedRow]];
}

- (int) indexOfItemWithObjectValue:(id)object
{
	if (_cbc.usesDataSource)
		NSLog(@"NSComboBoxCell is not configured for an internal datasource");
	else
		return [_popUpList indexOfObject:object];	
	return NSNotFound;
}

- (void) reloadData	{ NSLog(@"reloading"); [_tableView reloadData]; NSLog(@"reloaded"); }

- (void) noteNumberOfItemsChanged { [_tableView noteNumberOfRowsChanged]; }

- (void) scrollItemAtIndexToTop:(int)index { [_tableView scrollRowToVisible:index]; }

- (void) scrollItemAtIndexToVisible:(int)index { [_tableView scrollRowToVisible:index]; }

- (NSArray *) objectValues	{ return _popUpList; }

- (void) _popUpCellFrame:(NSRect) cellFrame controlView:(NSView *) view;
{
	NSPoint o = [view convertPoint:cellFrame.origin toView:nil];	// convert to window coordinates
	NSPoint l = [[view window] convertBaseToScreen:o];				// location on screen
	float height = _itemHeight*_visibleItems;
	NSRect f = { { l.x, l.y - height + 2.0 }, { NSWidth(cellFrame) - 1.0, height } };	// list frame
    NSScrollView *scrollView;
#if 1
	NSLog(@"pop up");
#endif
	if(!_tableView)
		{ // table view (not yet loaded from NIB)
		NSTableColumn *tc;		
		_tableView = [[NSComboTableView alloc] initWithFrame:(NSRect) { NSZeroPoint, f.size }];
		[_tableView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[_tableView setBackgroundColor:[NSColor whiteColor]];
		[_tableView setAllowsColumnReordering:NO];
		[_tableView setAllowsColumnResizing:NO];
		[_tableView setColumnAutoresizingStyle:NSTableViewUniformColumnAutoresizingStyle];
#if 0
		NSLog(@"table view: %@", [_tableView _descriptionWithSubviews]);
#endif
		tc = [[NSTableColumn alloc] initWithIdentifier:@"ComboBoxCell"];
#if 1
		NSLog(@"table column: %@", tc);
#endif
		[_tableView addTableColumn:tc];
		[_tableView setHeaderView:nil];	// no header
		[_tableView setTarget:self];	// make us the target
		[_tableView setAction:@selector(tableViewAction:)];
		[_tableView setDataSource:self];	// and data source
		[tc release];
		}
	if(![_tableView window])
		{ // create a new window
		NSPanel *popUpWindow = [[NSPanel alloc] initWithContentRect:f
												   styleMask:NSBorderlessWindowMask
													 backing:NSBackingStoreRetained
													   defer:YES
													  screen:nil];
		[popUpWindow setLevel:NSModalPanelWindowLevel];
		scrollView = [[NSScrollView alloc] initWithFrame:(NSRect) { NSZeroPoint, f.size }];
		[scrollView setHasHorizontalScroller:NO];
		[scrollView setHasVerticalScroller:[self hasVerticalScroller]];
		[scrollView setAutohidesScrollers:YES];
		[scrollView setDocumentView:_tableView];	// embed the NSTableView
#if 0
		NSLog(@"scroll view: %@", [scrollView _descriptionWithSubviews]);
#endif
		[[popUpWindow contentView] addSubview:scrollView];
		[scrollView setNeedsDisplay:YES];
		}
	else
		{ // adjust
#if 1
		NSLog(@"popup content view: %@", [[[_tableView window] contentView] _descriptionWithSubviews]);
		NSLog(@"table columns: %@", [_tableView tableColumns]);
#endif
		[[_tableView window] setFrame:f display:NO];	// reposition the window and resize the table
		}
#if 1
	NSLog(@"dataSource=%@", [_tableView dataSource]);
	NSLog(@"target=%@", [_tableView target]);
	NSLog(@"action=%@", NSStringFromSelector([_tableView action]));
#endif
	[[[_tableView tableColumns] objectAtIndex:0] setWidth:NSWidth(f)];	// make as wide as the text field
	[_tableView reloadData];
	[[_tableView window] makeKeyAndOrderFront:self];
	[_buttonCell setState:NSOnState];
}

// FIXME: should be called if we or our NSControl looses focus

- (void) _popDown;
{
#if 1
	NSLog(@"pop down");
#endif
	[[_tableView window] orderOut:self];
	[_buttonCell setState:NSOffState];
}

- (IBAction) tableViewAction:(NSTableView *) sender
{ // undocumented method
	int row=[sender selectedRow];
	if(row >= 0)
		{
		[self setObjectValue:[self itemObjectValueAtIndex:row]];	// take object value
		// should we also send our action?
		}
	[self _popDown];
}

- (BOOL) _isPoppedUp;
{
	return [[_tableView window] isVisible];
}

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)flag
{
	NSRect b, t;	// button & text
	NSPoint startPoint = [controlView convertPoint:[event locationInWindow] fromView:nil];
	NSWindow *win=[controlView window];
	NSDivideRect(cellFrame, &b, &t, cellFrame.size.height-4.0, NSMaxXEdge);
	if((NSMouseInRect(startPoint, t, YES)))
		{ // forward click event to the field editor
		return [super startTrackingAt:startPoint inView:controlView];
		}
#if 1
	NSLog(@"pop up");
#endif
	[self _popUpCellFrame:cellFrame controlView:controlView];
	while ([self _isPoppedUp])
		{ // dispatch events until user clicks somewhere outside of our popup window
		NSEvent *nextEvent = [win nextEventMatchingMask:NSAnyEventMask];
		NSWindow *ew=[nextEvent window];
		if(ew == [_tableView window])
			[ew sendEvent:nextEvent];	// dispatch to _popUpWindow to track mouse movements and selections
		else if(ew == win)
			{ // the window where we have popped up the table
			if([nextEvent type] == NSLeftMouseDown)
				{ // mouse down anywhere outside
				[self _popDown];
				[NSApp postEvent:nextEvent atStart:YES];	// process again
				break;
				}
			else
				;	// ignore other events (e.g. right mouse down) while popped up
			}
		else
			;	// ignore all (?) events for other windows
		}
	return YES;	// break mouseDown tracking loop
}													

- (NSRect) drawingRectForBounds:(NSRect) cellFrame;
{
	cellFrame.size.width -= 3.0;	// IB specifies 3 px spacing on the right hand side
	cellFrame.origin.y += 2.0;		// IB specifies 4px vertical (transparent!) spacing
	cellFrame.size.height -= 4.0;
	return cellFrame;
}

// FIXME: improve sizing calculations - we could copy controlSize to the button cell and ask for its height and ake a square

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSSize sz=NSMakeSize(20.0, 20.0);
	if(_d.controlSize ==  NSSmallControlSize) sz=NSMakeSize(16.0, 16.0);
	else if(_d.controlSize ==  NSMiniControlSize) sz=NSMakeSize(10.0, 10.0);
	cellFrame=[self drawingRectForBounds:cellFrame];
	cellFrame.size.width -= sz.width+3.0;								// we have to leave space for the button
	_controlView = controlView;										// remember as last view we did draw to
	[super drawInteriorWithFrame:cellFrame inView:controlView];		// draw text field
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSSize sz=NSMakeSize(20.0, 20.0);
	if(_d.controlSize ==  NSSmallControlSize) sz=NSMakeSize(16.0, 16.0);
	else if(_d.controlSize ==  NSMiniControlSize) sz=NSMakeSize(10.0, 10.0);
	cellFrame=[self drawingRectForBounds:cellFrame];
	cellFrame.size.width -= sz.width+3.0;						// we have to leave space for the button
	_controlView = controlView;								// remember as last view we draw to
	[_buttonCell drawWithFrame:(NSRect) { {NSMaxX(cellFrame)-7.0, NSMaxY(cellFrame)-sz.height-1.0 }, { sz.width+10.0, sz.height+3.0 } } inView:controlView];	// draw button (incl. its bezel) to the top/right
	[super drawWithFrame:cellFrame inView:controlView];		// text cell background goes to the left
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
#endif
	if((self=[super initWithCoder:aDecoder]))
		{
		[self _setupButtonCell];
		_cbc.usesDataSource = [aDecoder decodeBoolForKey:@"NSUsesDataSource"];
		_cbc.completes = [aDecoder decodeBoolForKey:@"NSCompletes"];
		if([aDecoder containsValueForKey:@"NSDataSource"])
			[self setDataSource:[aDecoder decodeObjectForKey:@"NSDataSource"]];	// this allocates new tableView if needed
		if([aDecoder containsValueForKey:@"NSPopUpListData"])
			_popUpList=[[aDecoder decodeObjectForKey:@"NSPopUpListData"] retain];
		else
			_popUpList = [NSMutableArray new];
		_cbc.hasVerticalScroller = [aDecoder decodeBoolForKey:@"NSHasVerticalScroller"];
		_visibleItems = [aDecoder decodeIntForKey:@"NSVisibleItemCount"];
		_tableView=[[aDecoder decodeObjectForKey:@"NSTableView"] retain];	// use this preinitialized one (should be a NSComboTableView)
		// _intercellSpacing = aSize;
		// _itemHeight = itemHeight;
		}
	return self;
}

- (NSString *) completedString:(NSString *) substring;
{
	NSEnumerator *e;
	NSString *val;
	if(_cbc.usesDataSource)
		{
		if([_dataSource respondsToSelector:@selector(comboBoxCell:completedString:)])
			return [_dataSource comboBoxCell:self completedString:substring];
		return nil;
		}
	e=[_popUpList objectEnumerator];
	while((val=[e nextObject]))
		if([val hasPrefix:substring])
			return val;	// found
	return nil;
}

@end /* NSComboBoxCell */

// class variables
static Class __comboBoxCellClass = Nil;

@implementation NSComboBox

+ (void) initialize
{
	__comboBoxCellClass = [NSComboBoxCell class];
}

+ (Class) cellClass							{ return __comboBoxCellClass?__comboBoxCellClass:[super cellClass]; }
+ (void) setCellClass:(Class)class			{ __comboBoxCellClass = class; }

- (BOOL) isOpaque; { return NO; }	// bounds are defined larger by IB than filled by the cell

#if OLD

- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if(self)
		{
		[self setCell: [[NSComboBoxCell new] autorelease]];
		}
	return self;
}
#endif

- (void) dealloc
{
	[self setDelegate:nil];
	[super dealloc];
}

// pass all to controlled cell

- (void) setHasVerticalScroller:(BOOL)f	{ [_cell setHasVerticalScroller:f]; }
- (void) setIntercellSpacing:(NSSize)s	{ [_cell setIntercellSpacing:s]; }
- (void) setItemHeight:(float)h			{ [_cell setItemHeight:h]; }
- (void) setNumberOfVisibleItems:(int)v	{ [_cell setNumberOfVisibleItems:v]; }
- (BOOL) hasVerticalScroller			{ return [_cell hasVerticalScroller]; }
- (NSSize) intercellSpacing				{ return [_cell intercellSpacing]; }
- (float) itemHeight					{ return [_cell itemHeight]; }
- (int) numberOfVisibleItems			{ return [_cell numberOfVisibleItems];}
- (void) reloadData						{ [_cell reloadData]; }
- (void) noteNumberOfItemsChanged		{ [_cell noteNumberOfItemsChanged]; }
- (void) scrollItemAtIndexToTop:(int)index	{ [_cell scrollItemAtIndexToTop:index]; }
- (void) scrollItemAtIndexToVisible:(int)index	{ [_cell scrollItemAtIndexToVisible:index]; }
- (void) selectItemAtIndex:(int)index	{ [_cell selectItemAtIndex:index]; }
- (void) deselectItemAtIndex:(int)index	{ [_cell deselectItemAtIndex:index]; }
- (int) indexOfSelectedItem				{ return [_cell indexOfSelectedItem]; }
- (int) numberOfItems					{ return [_cell numberOfItems]; }
- (void) setUsesDataSource:(BOOL)flag	{ [_cell setUsesDataSource:flag]; }
- (BOOL) usesDataSource					{ return [_cell usesDataSource]; }
- (BOOL) completes						{ return [_cell completes]; }
- (BOOL) isButtonBordered				{ return [_cell isButtonBordered]; }
- (void) setCompletes:(BOOL)flag		{ [_cell setCompletes:flag]; }
- (void) setButtonBordered:(BOOL)flag	{ [_cell setButtonBordered:flag]; }

- (id) dataSource						{ return _dataSource; }

- (void) setDataSource:(id)aSource
{
	SEL a = @selector(numberOfItemsInComboBox:);
	SEL b = @selector(comboBox:objectValueForItemAtIndex:);
	if(!aSource)
		{
		ASSIGN(_dataSource, aSource);
		return;
		}
	if(![_cell usesDataSource])
		NSLog(@"NSComboBox is not configured for an external datasource");
	if((![aSource respondsToSelector: a] || ![aSource respondsToSelector: b]))
		NSLog(@"dataSource does not implement NSComboBoxDataSource protocol: %@", aSource);
	ASSIGN(_dataSource, aSource);
	[_cell setDataSource:self];	// make us the data source of our cell so that we can translate all data source calls
}

- (void) addItemWithObjectValue:(id)o	{ [_cell addItemWithObjectValue:o]; }

- (void) addItemsWithObjectValues:(NSArray *)objects
{
	[_cell addItemsWithObjectValues:objects];
	[self setNeedsDisplay: YES];
}

- (void) insertItemWithObjectValue:(id)object atIndex:(int)index
{
	[_cell insertItemWithObjectValue:object atIndex:index];
	[self setNeedsDisplay: YES];
}

- (void) removeItemWithObjectValue:(id)o{ [_cell removeItemWithObjectValue:o];}
- (void) removeItemAtIndex:(int)index	{ [_cell removeItemAtIndex:index]; }
- (void) removeAllItems					{ [_cell removeAllItems]; }
- (NSArray *) objectValues				{ return [_cell objectValues]; }
- (void) selectItemWithObjectValue:(id)object	{ [_cell selectItemWithObjectValue:object]; }
- (id) itemObjectValueAtIndex:(int)index	{ return [_cell itemObjectValueAtIndex:index]; }
- (id) objectValueOfSelectedItem		{ return [_cell objectValueOfSelectedItem]; }
- (int) indexOfItemWithObjectValue:(id)object	{ return [_cell indexOfItemWithObjectValue:object]; }

- (void) setDelegate:(id)anObject
{
NSNotificationCenter *n;

	if(_delegate == anObject)
		return;

#define IGNORE_(notif_name) [n removeObserver:_delegate \
								name:NSComboBox##notif_name##Notification \
								object:self]

	n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(SelectionIsChanging);
		IGNORE_(SelectionDidChange);
		IGNORE_(WillDismiss);
		IGNORE_(WillPopUp);
		}

	[super setDelegate:anObject];
	// ASSIGN(_delegate, anObject);
	if(anObject)
		{

#define OBSERVE_(notif_name) \
	if ([_delegate respondsToSelector:@selector(comboBox##notif_name:)]) \
		[n addObserver:_delegate \
		   selector:@selector(comboBox##notif_name:) \
		   name:NSComboBox##notif_name##Notification \
		   object:self]

		OBSERVE_(SelectionIsChanging);
		OBSERVE_(SelectionDidChange);
		OBSERVE_(WillDismiss);
		OBSERVE_(WillPopUp);
		}
}

- (void) resetCursorRects								// Manage the cursor
{
	NSRect b, t;
	NSDivideRect(bounds, &b, &t, bounds.size.height-4.0, NSMaxXEdge);
	[self addCursorRect:t cursor:[NSCursor IBeamCursor]];
}

- (void) takeObjectValueFrom:(id)sender					// override NSControl
{
	[_cell setObjectValue: [_cell objectValueOfSelectedItem]];
}

// translate cell dataSource methods

- (NSString *)comboBoxCell:(NSComboBoxCell *)aComboBoxCell completedString:(NSString *)uncompletedString;
{
	if(aComboBoxCell == _cell)
		return [_dataSource comboBox:self completedString:uncompletedString];
	return uncompletedString;
}

- (unsigned int)comboBoxCell:(NSComboBoxCell *)aComboBoxCell indexOfItemWithStringValue:(NSString *)aString
{
	if(aComboBoxCell == _cell)
		return [_dataSource comboBox:self indexOfItemWithStringValue:aString];
	return NSNotFound;
}

- (id)comboBoxCell:(NSComboBoxCell *)aComboBoxCell objectValueForItemAtIndex:(int)index
{
	if(aComboBoxCell == _cell)
		return [_dataSource comboBox:self objectValueForItemAtIndex:index];
	return nil;
}

- (int)numberOfItemsInComboBoxCell:(NSComboBoxCell *)aComboBoxCell
{
	if(aComboBoxCell == _cell)
		return [_dataSource numberOfItemsInComboBox:self];
	return 0;
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
#endif
	if((self=[super initWithCoder:aDecoder]))
		{
		[self setDataSource:[aDecoder decodeObjectForKey:@"NSDataSource"]];
		}
#if 0
	NSLog(@"%@ initWithCoder:%@ -> %@", NSStringFromClass([self class]), aDecoder, self);
#endif
	return self;
}

@end /* NSComboBox */
