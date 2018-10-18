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

// NOTE: we are a subclass of NSMenuItemCell!

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
  // sender is the menu and not the item!?!
#if 0
	NSLog(@"%@ _popUpItemAction: sender = %@ %@", self, NSStringFromClass([sender class]), sender);
#endif
	[self selectItem:sender];
	[_controlView performClick:_controlView];	// and notify whomever wants to know
}

- (NSRect) drawingRectForBounds:(NSRect) cellFrame
{
	if(_bezelStyle == NSRoundedBezelStyle)
		return NSInsetRect(cellFrame, _d.controlSize == NSMiniControlSize?2:4, floorf(cellFrame.size.height*0.12));	// make smaller than enclosing frame
	return [super drawingRectForBounds:cellFrame];
}

- (NSRect) titleRectForBounds:(NSRect)theRect
{
	theRect=[self drawingRectForBounds:theRect];
	// handle text position
	return theRect;
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
	[image drawInRect:cellFrame];
	//	[image compositeToPoint:cellFrame.origin operation:NSCompositeSourceOver];
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
//	[_menu release];
	[super dealloc];
}

- (void) addItemWithTitle:(NSString *)title
{
	[self insertItemWithTitle:title atIndex:[_menu numberOfItems]];
	[self synchronizeTitleAndSelectedItem];
}

- (void) addItemsWithTitles:(NSArray *)itemTitles
{
	NSInteger i, count = [itemTitles count];
	for (i = 0; i < count; i++)
		[self addItemWithTitle:[itemTitles objectAtIndex:i]];
}

- (void) insertItemWithTitle:(NSString *)title atIndex:(NSInteger)index
{
	NSInteger i;
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
	[c setTarget:self];	// make us the menu item target
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

- (NSInteger) indexOfItem:(NSMenuItem *)item; { return [_menu indexOfItem:item]; }
- (NSInteger) indexOfItemWithTitle:(NSString *)title { return [_menu indexOfItemWithTitle:title]; }
- (NSInteger) indexOfItemWithTag:(NSInteger)t; { return [_menu indexOfItemWithTag:t]; }
- (NSInteger) indexOfItemWithRepresentedObject:(id)obj; { return [_menu indexOfItemWithRepresentedObject:obj]; }
- (NSInteger) indexOfItemWithTarget:(id)t andAction:(SEL)a; { return [_menu indexOfItemWithTarget:t andAction:a]; }

- (void) removeItemAtIndex:(NSInteger)index;
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

- (NSInteger) indexOfSelectedItem				{ return _selectedItem; }
- (NSInteger) numberOfItems					{ return [_menu numberOfItems]; }
- (NSArray *) itemArray					{ return [_menu itemArray]; }

	// - (NSMenu *) menu						{ return _menu; }
- (void) setMenu:(NSMenu *) m
{
	NSInteger i, cnt=[m numberOfItems];
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

- (NSMenuItem *) itemAtIndex:(NSInteger)index
{
	if(index < 0 || index >= [_menu numberOfItems])
		return nil;
	return [_menu itemAtIndex:index];
}

- (NSString *) itemTitleAtIndex:(NSInteger)index
{
	return [[_menu itemAtIndex:index] title];
}

- (NSArray *) itemTitles
{
	NSInteger i, count = [_menu numberOfItems];
	NSMutableArray *titles = [NSMutableArray arrayWithCapacity:count];
	for (i = 0; i < count; i++)
		[titles addObject:[[_menu itemAtIndex:i] title]];
	return titles;
}

- (NSMenuItem *) itemWithTitle:(NSString *)title
{
	NSInteger i = [self indexOfItemWithTitle:title];
	return (i != NSNotFound) ? [_menu itemAtIndex:i] : (NSMenuItem *) nil;
}

- (NSMenuItem *) lastItem
{
	return ([_menu numberOfItems]) ? [_menu itemAtIndex:[_menu numberOfItems]-1] : (NSMenuItem *) nil;
}

- (NSMenuItem *) selectedItem
{
	if(_selectedItem < 0 || _selectedItem >= [_menu numberOfItems])
		return nil;	// out of bounds
	return [_menu itemAtIndex:_selectedItem];
}

- (id) objectValue;
{
	return [NSNumber numberWithInteger:_selectedItem];
}

- (NSString *) titleOfSelectedItem
{
	return [[self selectedItem] title];
}

- (void) selectItemAtIndex:(NSInteger)index
{
#if 0
	NSLog(@"selectItemAtIndex: %d [0,%d]", index, [_menu numberOfItems]-1);
#endif
	if(_altersStateOfSelectedItem && _selectedItem >= 0 && !_pullsDown)
		[[self selectedItem] setState:NSOffState];	// deselect previous
	_selectedItem = index;
	if(_altersStateOfSelectedItem && _selectedItem >= 0 && !_pullsDown)
		[[self selectedItem] setState:NSOnState];	// select new
#if 0
	NSLog(@"selectedItem=%d:%@ state=%d", _selectedItem, [self selectedItem], [[self selectedItem] state]);
#endif
	[self synchronizeTitleAndSelectedItem];
}

- (void) setObjectValue:(id) obj;
{
	if([obj isKindOfClass:[NSAttributedString class]])
		obj=[(NSAttributedString *) obj string];
	[self selectItemAtIndex:[(id) obj intValue]];
}

- (void) selectItem:(NSMenuItem *) item;
{
	NSInteger idx;
	idx=[self indexOfItem:item];
#if 0
	NSLog(@"selectItem [%d]: %@", idx, item);
#endif
	if(idx < 0 && item)
		NSLog(@"item is not member of the menu items: %@\n%@", item, _menu);
	[self selectItemAtIndex:idx];
}

- (BOOL) selectItemWithTag:(NSInteger)t
{
	NSInteger idx=[self indexOfItemWithTag:t];
#if 0
	NSLog(@"selectItemWithTag:%d", t);
#endif
	if(idx == NSNotFound)
		return NO;
	[self selectItemAtIndex: idx];
	return YES;
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
	NSInteger i = [self indexOfItemWithTitle:aString];
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
	NSInteger i = (_pullsDown) ? 0 : _selectedItem;
#if 0
	NSLog(@"synchronizeTitleAndSelectedItem i=%d", i);
#endif
	if(i < 0 || i >= [_menu numberOfItems])
		[super setTitle:nil];	// nothing/invalid
	else
		[super setTitle:[[_menu itemAtIndex: i] title]]; 
	[_controlView updateCell:self];
}

// this is quite similar to -[NSMenuView attachSubmenuForItemAtIndex:]

- (void) attachPopUpWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	NSPanel *menuPanel;
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
	// FIXME: [[NSMenuView _currentOpen_controlView] detachSubmenu];	// close if any main menu is open
	[_menu update];		// enable/disable menu items
	_menuView=[[NSMenuView alloc] initWithFrame:(NSRect) { NSZeroPoint, cellFrame.size }];	// make new NSMenuView
	[_menuView setFont:[self font]];			// same font as the popup button
	[_menuView setHorizontal:NO];		// make popup menu vertical
	[_menuView _setHorizontalResize:NO];		// don't resize width!
	menuPanel=[[[NSPanel alloc] initWithContentRect:(NSRect) { NSZeroPoint, cellFrame.size }
									styleMask:NSBorderlessWindowMask
									  backing:NSBackingStoreBuffered
										defer:YES] retain];	// will be released on close
	[menuPanel setWorksWhenModal:YES];
	[menuPanel setLevel:NSSubmenuWindowLevel];
#if 0
	NSLog(@"win=%@", _menuWindow);
	NSLog(@"autodisplay=%d", [_menuWindow isAutodisplay]);
#endif
#if 0
	[_menuWindow setTitle:@"PopUpButton Menu"];
#endif
	[[menuPanel contentView] addSubview:_menuView];	// add to view hiearachy
	[_menuView release];	// now retained by view hierarchy
	[_menuView setMenu:_menu];			// define to manage selected menu
	[_menuView _setAttachedMenuView:_menuView];	// make us our own attachedMenuView so that the panel is closed after menu selection
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
		[_menuView setWindowFrameForAttachingToRect:r
										  onScreen:[menuPanel screen]
									 preferredEdge:_preferredEdge	// attach below
								 popUpSelectedItem:-1];
	else
		[_menuView setWindowFrameForAttachingToRect:r
										  onScreen:[menuPanel screen]
									 preferredEdge:NSMaxXEdge	// attach to the right
								 popUpSelectedItem:_selectedItem];
	[menuPanel orderFront:self];		// make visible
}

- (void) dismissPopUp;
{
	[[_menuView window] close];	// will also release the panel
	_menuView=nil;
}

- (void) performClickWithFrame:(NSRect) frame inView:(NSView *) controlView;
{ // pop up as context menu
	NSEvent *event=[NSApp currentEvent];
#if 0
	NSLog(@"performClickWithFrame %@ - %@ - %@", _menu, event, controlView);
#endif
	// how to handle frame? Simulate as a mouseDown event and use frame center as the location?
	[NSMenu popUpContextMenu:_menu withEvent:event forView:controlView withFont:nil];
}

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)flag	// ignored
{
#if 1
	NSLog(@"NSPopUpButtonCell trackMouse:inRect:...");
#endif
	[self attachPopUpWithFrame:cellFrame inView:controlView];	// open menu
	[_menuView mouseDown:event];	// ignore cellFrame etc.
#if 1
	NSLog(@"NSPopUpButtonCell trackMouse:inRect: done...");
#endif
	return YES;	// did go up
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		return NIMP;
#if 0
	NSLog(@"NSPopupButtonCell menu=%@", _menu);
	NSLog(@"NSPopupButtonCell items=%@", [_menu itemArray]);
#endif
	_altersStateOfSelectedItem=[aDecoder decodeBoolForKey:@"NSAltersState"];
	_usesItemFromMenu=[aDecoder decodeBoolForKey:@"NSUsesItemFromMenu"];
	_pullsDown=[aDecoder decodeBoolForKey:@"NSPullDown"];
	_arrowPosition=[aDecoder decodeIntForKey:@"NSArrowPosition"];
	_preferredEdge=[aDecoder decodeIntForKey:@"NSPreferredEdge"];
	
/*	_respectAlignment = */ [aDecoder decodeBoolForKey:@"NSMenuItemRespectAlignment"];

	// _autoenablesItems=?
	if([aDecoder containsValueForKey:@"NSSelectedIndex"])
		[self selectItemAtIndex:[aDecoder decodeIntForKey:@"NSSelectedIndex"]];	// try to select
	return self;
}

/*
 * Checkme: this is a workaround for the following problem:
 * the popupbuttoncell's NSMenu has an array of items
 * when decoding this menu, all items are decoded
 * each menu-item has this popupButtonCell as it's target
 * the target is also decoded
 * depending on some ordering, this may lead to either complete or incomplete menu initialization
 *
 * we may need a fundamental solution for such recursive decoding of NIBs
 */

- (void) awakeFromNib;
{
	NSLog(@"NSPopupButtonCell awakeFromNib");
	if(menuItem)
		[self selectItem:menuItem];
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
- (CGFloat) horizontalEdgePadding; { return 0.0; }
- (CGFloat) imageAndTitleOffset; { return 0.0; }

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
- (void) insertItemWithTitle:(NSString *)title atIndex:(NSInteger)index
{
	[_cell insertItemWithTitle:title atIndex:index];
}

- (void) removeItemWithTitle:(NSString *)title { [_cell removeItemWithTitle:title]; }
- (NSInteger) indexOfItem:(NSMenuItem *)item { return [_cell indexOfItem:item]; }
- (NSInteger) indexOfItemWithTitle:(NSString *)title { return [_cell indexOfItemWithTitle:title]; }
- (NSInteger) indexOfItemWithTag:(NSInteger)tag; { return [_cell indexOfItemWithTag:tag]; }
- (NSInteger) indexOfItemWithRepresentedObject:(id)obj; { return [_cell indexOfItemWithRepresentedObject:obj]; }
- (NSInteger) indexOfItemWithTarget:(id)target andAction:(SEL)action; { return [_cell indexOfItemWithTarget:target andAction:action]; }
- (void) removeItemAtIndex:(NSInteger)index	{ [_cell removeItemAtIndex:index]; }
- (void) removeAllItems					{ [_cell removeAllItems]; }
- (NSInteger) indexOfSelectedItem				{ return [_cell indexOfSelectedItem]; }
- (NSInteger) numberOfItems					{ return [_cell numberOfItems]; }
- (NSArray *) itemArray					{ return [_cell itemArray]; }
- (NSMenu *) menu						{ return [_cell menu]; }
- (void) setMenu:(NSMenu *) m		
{ 
#if 0
	NSLog(@"NSPopupButton %08x setMenu:%@", self, m);
#endif
	[_cell setMenu:m]; 
}
- (NSMenuItem *) itemAtIndex:(NSInteger)index				{ return [_cell itemAtIndex:index]; }
- (NSString *) itemTitleAtIndex:(NSInteger)index			{ return [_cell itemTitleAtIndex:index]; }
- (NSArray *) itemTitles							{ return [_cell itemTitles]; }
- (NSMenuItem *) itemWithTitle:(NSString *)title	{ return [_cell itemWithTitle:title]; }
- (NSMenuItem *) lastItem							{ return [_cell lastItem]; }
- (NSMenuItem *) selectedItem						{ return [_cell selectedItem]; }
- (NSString *) titleOfSelectedItem					{ return [_cell titleOfSelectedItem]; }
- (void) selectItem:(NSMenuItem *)item				{ [_cell selectItem:item]; }
- (void) selectItemAtIndex:(NSInteger)index				{ [_cell selectItemAtIndex:index]; }
- (BOOL) selectItemWithTag:(NSInteger)tag					{ return [_cell selectItemWithTag:tag]; }
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
- (void) setObjectValue:(id)anValue					{ [(NSPopUpButtonCell *) _cell setObjectValue:anValue]; }
- (void) synchronizeTitleAndSelectedItem			{ [_cell synchronizeTitleAndSelectedItem]; }
- (id) objectValue									{ return [_cell objectValue]; }

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
