/* 
NSPopUpButton.m
 
 Popup list class
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:	Michael Hanni <mhanni@sprintmail.com>
 Date:	June 1999
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>

// NOTE: we are a sbclass of NSMenuItemCell!

#import <AppKit/NSApplication.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSMenuView.h>
#import <AppKit/NSPopUpButton.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSColor.h>

#import "NSAppKitPrivate.h"

@implementation NSPopUpButtonCell

NSString *NSPopUpButtonCellWillPopUpNotification=@"NSPopUpButtonCellWillPopUpNotification";

- (IBAction) _popUpItemAction:(id) sender;
{ // some popup item has been selected
#if 0
	NSLog(@"%@ _popUpItemAction:%@", self, sender);
#endif
	[self selectItem:sender];
	[_controlView performClick:_controlView];	// and notify whoever wants to know
}

- (NSRect) drawingRectForBounds:(NSRect) cellFrame
{
	if(_bezelStyle == NSRoundedBezelStyle)
		return NSInsetRect(cellFrame, _d.controlSize == NSMiniControlSize?2:4, floor(cellFrame.size.height*0.12));	// make smaller than enclosing frame
	return [super drawingRectForBounds:cellFrame];
}

- (void) drawBezelWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	if(_bezelStyle == NSRoundedBezelStyle)
		{ // draw default bezel - right shaped
		cellFrame=[self drawingRectForBounds:cellFrame];
		cellFrame.size.width-=cellFrame.size.height;
		[NSBezierPath _drawRoundedBezel:1 inFrame:cellFrame enabled:YES selected:NO highlighted:NO radius:5.0];	// draw left end segment
		cellFrame.origin.x+=cellFrame.size.width;
		cellFrame.size.width=cellFrame.size.height-1.0;
		[NSBezierPath _drawRoundedBezel:2 inFrame:cellFrame enabled:YES selected:YES highlighted:NO radius:5.0];	// draw right end segment
		}
	else
		[super drawBezelWithFrame:cellFrame inView:controlView];
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView  
{
	static void (*supersuper)(id, SEL, NSRect, NSView *);
	if(!supersuper) supersuper = (void (*)(id, SEL, NSRect, NSView *))[NSButtonCell instanceMethodForSelector:_cmd];	// get NSButtonCell's implementation
	NSAssert(supersuper, @"could not find NSButtonCell");
#if 0
	NSLog(@"drawWithFrame: %@", self);
#endif
	supersuper(self, _cmd, cellFrame, controlView);		// call NSButtonCell's implementation and not the one of NSMenuItem!
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView  
{ // overlay the popup/pulldown icon
	NSImage *image;
	NSSize sz;
	static void (*supersuper)(id, SEL, NSRect, NSView *);
	if(!supersuper) supersuper = (void (*)(id, SEL, NSRect, NSView *))[NSButtonCell instanceMethodForSelector:_cmd];	// get NSButtonCell's implementation
	NSAssert(supersuper, @"could not find NSButtonCell");
#if 0
	NSLog(@"drawInteriorWithFrame %@", self);
#endif
	_controlView = controlView;							// last view drawn in

	cellFrame.size.width -= cellFrame.size.height;		// make space for the arrow
	
	supersuper(self, _cmd, cellFrame, controlView);		// call NSButtonCell's implementation to draw the title and not the one of NSMenuItem!

	cellFrame.origin.x += cellFrame.size.width-2.0;
	cellFrame.size.width = cellFrame.size.height;		// make square space for the arrow on the right side

	if(!_pullsDown)
		{
		image=[NSImage imageNamed:@"GSPopup"];
		sz=[image size];
		cellFrame.origin.x += (cellFrame.size.width - sz.width) / 2;	// center
		cellFrame.origin.y += (cellFrame.size.height - sz.height) / 2;
		}
	else
		{
		switch(_arrowPosition)
			{
			default:
// FIXME:				return;	// no arrow
			case NSPopUpArrowAtCenter:
				switch(_preferredEdge)
					{
					// FIXME: is this correct with flipped images?
					case NSMinXEdge: image=[NSImage imageNamed:@"GSArrowLeft"]; break;
					case NSMaxYEdge: image=[NSImage imageNamed:@"GSArrowDown"]; break;
					case NSMaxXEdge: image=[NSImage imageNamed:@"GSArrowRight"]; break;
					case NSMinYEdge: image=[NSImage imageNamed:@"GSArrowUp"]; break;
					default: return;
					}
				sz=[image size];
				cellFrame.origin.x += (cellFrame.size.width - sz.width) / 2;	// center
				cellFrame.origin.y += (cellFrame.size.height - sz.height) / 2;
				break;
			case NSPopUpArrowAtBottom:
				switch(_preferredEdge)
					{
					// FIXME: is this correct with flipped images?
					case NSMinXEdge: image=[NSImage imageNamed:@"GSArrowLeft"]; break;
					case NSMaxYEdge: image=[NSImage imageNamed:@"GSArrowUp"]; break;
					case NSMaxXEdge: image=[NSImage imageNamed:@"GSArrowRight"]; break;
					case NSMinYEdge: image=[NSImage imageNamed:@"GSArrowDown"]; break;
					default: return;
					}
				sz=[image size];
				// FIXME: this should be part of the positioning algorithm
				cellFrame.origin.x += (cellFrame.size.width - sz.width) / 2;	// center
				cellFrame.origin.y = 0.0;	// at bottom
				break;
			}
		}
#if 0
		NSLog(@"NSPopUpButton image=%@ rect=%@", image, NSStringFromRect(rect));
#endif
	[image compositeToPoint:cellFrame.origin operation:NSCompositeSourceOver];
}

- (id) init	{ return [self initTextCell:@"PopUpButton" pullsDown:NO]; }

- (id) initTextCell:(NSString *)value pullsDown:(BOOL)flag;
{
	self=[self initTextCell:value];	// NSMenuItemCell
	if(self)
		{
		_menu=[NSMenu new];	// empty menu
		_pullsDown=flag;
		_preferredEdge=NSMinYEdge;
		_arrowPosition=NSPopUpArrowAtCenter;
		// other inits
		}
	return self;
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ [%@] with Menu %@", 
		NSStringFromClass([self class]),
		[self title], 
		[self menu]];
}

- (void) dealloc
{
	[_menu release];
	[super dealloc];
}

- (void) addItemWithTitle:(NSString *)title
{
	[self insertItemWithTitle:title atIndex:[_menu numberOfItems]];
	[self synchronizeTitleAndSelectedItem];
}

- (void) addItemsWithTitles:(NSArray *)itemTitles
{
	int i, count = [itemTitles count];	
	for (i = 0; i < count; i++)
		[self addItemWithTitle:[itemTitles objectAtIndex:i]];
}

- (void) insertItemWithTitle:(NSString *)title atIndex:(unsigned int)index
{
	int i;
	NSMenuItem *c;
#if 0
	NSLog(@"insertItemWithTitle:%@ atIndex:%d", title, index);
#endif
	if(!title)
		[NSException raise: NSInvalidArgumentException
					format: @"attempt to insertItemWithTitle with nil title."];
	c=[[[NSMenuItem alloc] initWithTitle:title 
								  action:@selector(_popUpItemAction:)
						   keyEquivalent:@""] autorelease];
	[c setTarget:self];
	i=[self indexOfItemWithTitle:title];	// already defined?
#if 0
	NSLog(@"i=%d", i);
#endif
	if(i >= 0)
		{ // remove if title already exists
		[self removeItemAtIndex:i];
		if(index > i)
			index--;	// has been referring to index list including the one we just have deleted
		}
#if 0
	NSLog(@"insert item %@", c);
#endif
	[_menu insertItem:c atIndex:index];
	[self synchronizeTitleAndSelectedItem];
}

- (void) removeItemWithTitle:(NSString *)title
{
	[_menu removeItemAtIndex:[self indexOfItemWithTitle:title]];
}

- (int) indexOfItem:(id <NSMenuItem>)item; { return [_menu indexOfItem:item]; }
- (int) indexOfItemWithTitle:(NSString *)title { return [_menu indexOfItemWithTitle:title]; }
- (int) indexOfItemWithTag:(int)t; { return [_menu indexOfItemWithTag:t]; }
- (int) indexOfItemWithRepresentedObject:(id)obj; { return [_menu indexOfItemWithRepresentedObject:obj]; }
- (int) indexOfItemWithTarget:(id)t andAction:(SEL)a; { return [_menu indexOfItemWithTarget:t andAction:a]; }

- (void) removeItemAtIndex:(int)index;
{
	if(index < 0 || index >= [_menu numberOfItems])
		[_menu removeItemAtIndex:index];
	[self synchronizeTitleAndSelectedItem];
}

- (void) removeAllItems	
{
	while([_menu numberOfItems] > 0)
		[_menu removeItemAtIndex:0];
	[self synchronizeTitleAndSelectedItem];
}

- (int) indexOfSelectedItem				{ return _selectedItem; }
- (int) numberOfItems					{ return [_menu numberOfItems]; }
- (NSArray *) itemArray					{ return [_menu itemArray]; }

	// - (NSMenu *) menu						{ return _menu; }
- (void) setMenu:(NSMenu *) m
{
	int i, cnt=[m numberOfItems];
#if 0
	NSLog(@"%@ setMenu %@", self, m);
	//	if(!m)
	//		abort();
#endif
	for(i=0; i<cnt; i++)
		{
		NSMenuItem *item=(NSMenuItem *)[m itemAtIndex:i];
		if([NSStringFromSelector([item action]) isEqualToString:@"_popUpItemAction:"])
			[item setTarget:self];	// adjust target
		}
	//	ASSIGN(_menu, m);
	[super setMenu:m];
}

- (id <NSMenuItem>) itemAtIndex:(int)index
{
	if(index < 0 || index >= [_menu numberOfItems])
		return nil;
	return [_menu itemAtIndex:index];
}

- (NSString *) itemTitleAtIndex:(int)index
{
	return [[_menu itemAtIndex:index] title];
}

- (NSArray *) itemTitles
{
	int i, count = [_menu numberOfItems];
	NSMutableArray *titles = [NSMutableArray arrayWithCapacity:count];
	for (i = 0; i < count; i++)
		[titles addObject:[[_menu itemAtIndex:i] title]];
	return titles;
}

- (id <NSMenuItem>) itemWithTitle:(NSString *)title
{
	int i = [self indexOfItemWithTitle:title];
	return (i != NSNotFound) ? [_menu itemAtIndex:i] : nil;
}

- (id <NSMenuItem>) lastItem
{
	return ([_menu numberOfItems]) ? [_menu itemAtIndex:[_menu numberOfItems]-1] : nil;
}

- (id <NSMenuItem>) selectedItem
{
	if(_selectedItem < 0 || _selectedItem >= [_menu numberOfItems])
		return nil;	// out of bounds
	return [_menu itemAtIndex:_selectedItem];
}

- (id <NSCopying>) objectValue;
{
	return [NSNumber numberWithInt:_selectedItem];
}

- (NSString *) titleOfSelectedItem
{
	return [(NSMenuItem*)[self selectedItem] title];
}

- (void) selectItemAtIndex:(int)index
{
#if 0
	NSLog(@"selectItemAtIndex: %d [0,%d]", index, [_menu numberOfItems]-1);
#endif
	if(_selectedItem >= 0 && !_pullsDown)
		[[self selectedItem] setState:NSOffState];	// deselect previous
	_selectedItem = index;
	if(_selectedItem >= 0 && !_pullsDown)
		[[self selectedItem] setState:NSOnState];	// select new
#if 0
	NSLog(@"selectedItem=%d:%@ state=%d", _selectedItem, [self selectedItem], [[self selectedItem] state]);
#endif
	[self synchronizeTitleAndSelectedItem];
}

- (void) setObjectValue:(id <NSCopying>) obj;
{
	[self selectItemAtIndex:[(id) obj intValue]];
}

- (void) selectItem:(id <NSMenuItem>) item;
{
#if 0
	NSLog(@"selectItem: %@", item);
#endif
	[self selectItemAtIndex:[self indexOfItem:item]];
}

- (void) selectItemWithTitle:(NSString *)title
{
#if 0
	NSLog(@"selectItemWithTitle:%@", title);
#endif
	[self selectItemAtIndex: [self indexOfItemWithTitle:title]];
}

- (void) setImage:(NSImage *) img { /* no effect */ }
- (void) setAltersStateOfSelectedItem:(BOOL)flag	{ _altersStateOfSelectedItem = flag; }
- (void) setAutoenablesItems:(BOOL)flag			{ _autoenablesItems = flag; }
- (void) setPullsDown:(BOOL)flag				{ _pullsDown = flag; }
- (void) setArrowPosition:(NSPopUpArrowPosition) position;	{ _arrowPosition=position; }
- (void) setPreferredEdge:(NSRectEdge) edge;	{ _preferredEdge=edge; }
- (void) setUsesItemFromMenu:(BOOL)flag;		{ _usesItemFromMenu=flag; }

- (BOOL) altersStateOfSelectedItem				{ return _altersStateOfSelectedItem; }
- (BOOL) autoenablesItems						{ return _autoenablesItems; }
- (BOOL) pullsDown								{ return _pullsDown; }
- (NSPopUpArrowPosition) arrowPosition;			{ return _arrowPosition; }
- (NSRectEdge) preferredEdge;					{ return _preferredEdge; }
- (BOOL) usesItemFromMenu;						{ return _usesItemFromMenu; }

- (void) setTitle:(NSString *)aString			
{
	int i = [self indexOfItemWithTitle:aString];
#if 0
	NSLog(@"setTitle:%@ -> %d", aString, i);
#endif
	if (i == NSNotFound)
		{
		[self addItemWithTitle:aString];
		i = [_menu numberOfItems];	// has been appended
		}
	[self selectItemAtIndex: i];
}

- (void) synchronizeTitleAndSelectedItem
{
	int i = (_pullsDown) ? 0 : _selectedItem;
#if 0
	NSLog(@"synchronizeTitleAndSelectedItem i=%d", i);
#endif
	if(i < 0 || i >= [_menu numberOfItems])
		[super setTitle:@"?"];	// nothing/invalid
	else
		[super setTitle:[[_menu itemAtIndex: i] title]]; 
	//	[_controlView setNeedsDisplay:YES];	// should redraw for our cell only!
}

- (void) attachPopUpWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	NSMenuView *menuView;
	NSRect r;
#if 0
	NSLog(@"attachPopUpWithFrame %08x", _menu);
	NSLog(@"attachPopUpWithFrame %@", [_menu title]);
	NSLog(@"attachPopUpWithFrame view %@", controlView);
#endif
	if(!_menu || !controlView)
		return;
	[[NSNotificationCenter defaultCenter] postNotificationName:NSPopUpButtonCellWillPopUpNotification object:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:NSPopUpButtonCellWillPopUpNotification object:controlView];
	//	[[NSMenuView _currentOpen_controlView] detachSubmenu];	// close if any other menu is open
	[_menu update];		// enable/disable menu items
	menuView=[[[NSMenuView class] alloc] initWithFrame:(NSRect) { NSZeroPoint, cellFrame.size }];	// make new NSMenuView
	[menuView setFont:_font];			// same font as the popup button
	[menuView setHorizontal:NO];		// make popup menu vertical
	[menuView _setHorizontalResize:NO];		// don't resize width!
	[menuView _setContextMenu:YES];			// close on selection
	_menuWindow=[[[NSPanel alloc] initWithContentRect:(NSRect) { NSZeroPoint, cellFrame.size }
									styleMask:NSBorderlessWindowMask
									  backing:NSBackingStoreBuffered
										defer:YES] retain];	// will be released on close
	[_menuWindow setWorksWhenModal:YES];
	[_menuWindow setLevel:NSSubmenuWindowLevel];
#if 0
	NSLog(@"win=%@", _menuWindow);
	NSLog(@"autodisplay=%d", [_menuWindow isAutodisplay]);
#endif
#if 1
	[_menuWindow setTitle:@"PopUpButton Menu"];
#endif
	[[_menuWindow contentView] addSubview:menuView];	// add to view hiearachy
	[menuView setMenu:_menu];			// define to manage selected menu
#if 0
	NSLog(@"cellFrame=%@", NSStringFromRect(cellFrame));
	NSLog(@"view Frame=%@", NSStringFromRect([controlView frame]));
	NSLog(@"view's window Frame=%@", NSStringFromRect([[controlView window] frame]));
#endif
	if(!_pullsDown)
		{ // overlay to popup button
		cellFrame.size.width=0;		// zero width so that the menu attaches to the right side
		cellFrame.origin.x -= 10;	// shift left
		}
	r=[controlView convertRect:cellFrame toView:nil];				// convert to view's frame
	r.origin=[[controlView window] convertBaseToScreen:r.origin];	// to screen coordinates
#if 0
	NSLog(@"menu to be attached to %@", NSStringFromRect(r));
#endif
	r.origin.y-=2.0;	// adjust
	if(_pullsDown)
		[menuView setWindowFrameForAttachingToRect:r
										  onScreen:[_menuWindow screen]
									 preferredEdge:_preferredEdge	// attach below
								 popUpSelectedItem:-1];
	else
		[menuView setWindowFrameForAttachingToRect:r
										  onScreen:[_menuWindow screen]
									 preferredEdge:NSMaxXEdge	// attach to the right
								 popUpSelectedItem:_selectedItem];
	[_menuWindow orderFront:self];		// make visible
}

- (void) dismissPopUp;
{
#if 1
	NSLog(@"dimiss popup");
#endif
	[_menuWindow close];
	_menuWindow=nil;
}

- (void) performClickWithFrame:(NSRect) frame inView:(NSView *) controlView;
{ // pop up as context menu
	NSEvent *event=[NSApp currentEvent];
#if 1
	NSLog(@"performClickWithFrame %@ - %@ - %@", _menu, event, controlView);
#endif
	// how to handle frame? Simulate as a mouseDown event and use frame as the location?
	[NSMenu popUpContextMenu:_menu withEvent:event forView:controlView withFont:nil];
}

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)flag
{
#if 1
	NSLog(@"NSPopUpButtonCell trackMouse:inRect:...");
#endif
	[self attachPopUpWithFrame:cellFrame inView:controlView];	// open menu
	[[[[_menuWindow contentView] subviews] lastObject] mouseDown:event];	// ignore cellFrame etc.
#if 0
	while([event type] != NSLeftMouseUp)
		{ // loop until mouse goes up
		NSMenuView *menuView=[[[_menuWindow contentView] subviews] lastObject];
		NSLog(@"NSPopUpButonCell event = %@", event);
		NSLog(@"NSPopUpButonCell menuView = %@", menuView);
		if(![menuView trackWithEvent:event])
			;	// now outside
		event = [NSApp nextEventMatchingMask:NSLeftMouseDraggedMask | NSLeftMouseDownMask | NSMouseMovedMask | NSLeftMouseUpMask 
								   untilDate:[NSDate distantFuture]
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
		}
#endif
	NSLog(@"NSPopUpButtonCell trackMouse:inRect: done...");
	[self dismissPopUp];
	return YES;	// did go up
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		return NIMP;
	_altersStateOfSelectedItem=[aDecoder decodeBoolForKey:@"NSAltersState"];
	_usesItemFromMenu=[aDecoder decodeBoolForKey:@"NSUsesItemFromMenu"];
	_pullsDown=[aDecoder decodeBoolForKey:@"NSPullDown"];
	_arrowPosition=[aDecoder decodeIntForKey:@"NSArrowPosition"];
	_preferredEdge=[aDecoder decodeIntForKey:@"NSPreferredEdge"];
	_selectedItem=[aDecoder decodeIntForKey:@"NSSelectedIndex"];
	// _autoenablesItems=?
	return self;
}

@end

//*****************************************************************************
//
// 		NSPopUpButton 
//
//*****************************************************************************

@implementation NSPopUpButton

NSString *NSPopUpButtonWillPopUpNotification=@"NSPopUpButtonWillPopUpNotification";

- (BOOL) isHorizontal; { return NO; }	// behaves like a vertical menu (NSPopUpButtonCell assumes we are a NSMenuView)
- (float) horizontalEdgePadding; { return 0.0; }
- (float) imageAndTitleOffset; { return 0.0; }

- (id) init
{
	return [self initWithFrame:NSZeroRect pullsDown:NO];
}

- (id) initWithFrame:(NSRect)frameRect
{
	return [self initWithFrame:frameRect pullsDown:NO];
}

- (void) _popUpButtonCellWillPopUpForwarder:(NSNotification *) n
{ // convert the notification to NSPopUpButtonWillPopUpNotification
	[[NSNotificationCenter defaultCenter] postNotificationName:NSPopUpButtonWillPopUpNotification object:self];
}

- (id) initWithFrame:(NSRect)frameRect pullsDown:(BOOL)flag
{
	self=[super initWithFrame:frameRect];
	if(self)
		{
		//		NSLog(@"cell %@", _cell);
		[self setCell:[[NSPopUpButtonCell new] autorelease]];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_popUpButtonCellWillPopUpForwarder:) name:NSPopUpButtonCellWillPopUpNotification object:self];
		//		NSLog(@"cell %@", _cell);
		[self setPullsDown:flag];
		[self setEnabled:YES];
		}
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];	// remove us from cell(s)
	[super dealloc];
}

- (void) addItemWithTitle:(NSString *)title { [_cell addItemWithTitle:title]; }
- (void) addItemsWithTitles:(NSArray *)itemTitles
{ [_cell addItemsWithTitles:itemTitles]; }
- (void) insertItemWithTitle:(NSString *)title atIndex:(unsigned int)index
{
	[_cell insertItemWithTitle:title atIndex:index];
}

- (void) removeItemWithTitle:(NSString *)title { [_cell removeItemWithTitle:title]; }
- (int) indexOfItemWithTitle:(NSString *)title { return [_cell indexOfItemWithTitle:title]; }
- (int) indexOfItemWithTag:(int)tag; { return [_cell indexOfItemWithTag:tag]; }
- (int) indexOfItemWithRepresentedObject:(id)obj; { return [_cell indexOfItemWithRepresentedObject:obj]; }
- (int) indexOfItemWithTarget:(id)target andAction:(SEL)action; { return [_cell indexOfItemWithTarget:target andAction:action]; }
- (void) removeItemAtIndex:(int)index	{ [_cell removeItemAtIndex:index]; }
- (void) removeAllItems					{ [_cell removeAllItems]; }
- (int) indexOfSelectedItem				{ return [_cell indexOfSelectedItem]; }
- (int) numberOfItems					{ return [_cell numberOfItems]; }
- (NSArray *) itemArray					{ return [_cell itemArray]; }
- (NSMenu *) menu						{ return [_cell menu]; }
- (void) setMenu:(NSMenu *) m		
{ 
	NSLog(@"NSPopupButton %08x setMenu:%@", self, m);
	[_cell setMenu:m]; 
}
- (id <NSMenuItem>) itemAtIndex:(int)index			{ return [_cell itemAtIndex:index]; }
- (NSString *) itemTitleAtIndex:(int)index			{ return [_cell itemTitleAtIndex:index]; }
- (NSArray *) itemTitles							{ return [_cell itemTitles]; }
- (id <NSMenuItem>) itemWithTitle:(NSString *)title	{ return [_cell itemWithTitle:title]; }
- (id <NSMenuItem>) lastItem						{ return [_cell lastItem]; }
- (id <NSMenuItem>) selectedItem					{ return [_cell selectedItem]; }
- (NSString *) titleOfSelectedItem					{ return [_cell titleOfSelectedItem]; }
- (void) selectItem:(id <NSMenuItem>)item			{ [_cell selectItem:item]; }
- (void) selectItemAtIndex:(int)index				{ [_cell selectItemAtIndex:index]; }
- (void) selectItemWithTitle:(NSString *)title		{ [_cell selectItemWithTitle:title]; }
- (void) setPullsDown:(BOOL)flag					{ [_cell setPullsDown:flag]; }
- (void) setAutoenablesItems:(BOOL)flag				{ [_cell setAutoenablesItems:flag]; }
- (void) setArrowPosition:(NSPopUpArrowPosition) position;	{ [_cell setArrowPosition:position]; }
- (void) setPreferredEdge:(NSRectEdge) edge;		{ [_cell setPreferredEdge:edge]; }
	// - (NSString *) stringValue						{ return nil; }
- (BOOL) autoenablesItems							{ return [_cell autoenablesItems]; }
- (BOOL) pullsDown									{ return [_cell pullsDown]; }
- (NSPopUpArrowPosition) arrowPosition;				{ return [_cell arrowPosition]; }
- (NSRectEdge) preferredEdge;						{ return [_cell preferredEdge]; }
- (void) setTitle:(NSString *)aString				{ [_cell setTitle:aString]; }
- (void) setImage:(NSImage *)anImage				{ [_cell setImage:anImage]; }
- (void) setObjectValue:(id)anValue					{ [_cell setObjectValue:anValue]; }
- (void) synchronizeTitleAndSelectedItem			{ [_cell synchronizeTitleAndSelectedItem]; }
- (id <NSCopying>) objectValue						{ return [_cell objectValue]; }

- (void) encodeWithCoder:(NSCoder*)aCoder
{
	[super encodeWithCoder: aCoder];
}

- (id) initWithCoder:(NSCoder*)aDecoder
{
	self=[super initWithCoder: aDecoder];
	return self;
}

@end /* NSPopUpButton */
