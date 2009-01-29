//
//  NSMenuView.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Thu Mar 27 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

///// selecting a menu item should set setDefaultButtonCell: so that 'return' selects

#import <AppKit/NSMenuView.h>
#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSStatusItem.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSPopUpButton.h>

#import "NSAppKitPrivate.h"

#define VERTICAL_PADDING		3.0		// padding at top/bottom of vertical menus
#define HORIZONTAL_PADDING		3.0		// padding at left/right of menu items
#define SHORT_CLICK_INTERVAL	0.4		// in seconds

@implementation NSMenuView

- (BOOL) _isResizingHorizontally; { return _isResizingHorizontally; }

- (void) _setHorizontalResize:(BOOL) flag;
{ // if set resize horizontal width as needed - otherwise leave untouched
#if 0
	NSLog(@"setHorizontalResize:%d", flag);
#endif
	if(_isResizingHorizontally == flag)
		return;	// unchanged
	_isResizingHorizontally=flag;
	_needsSizing=YES;
}

- (BOOL) _isStatusBar; { return _isStatusBar; }

- (void) _setStatusBar:(BOOL) flag;
{
	if(_isStatusBar==flag)
		return;	// unchanged
	_isStatusBar=flag;
	_needsSizing=YES;
}

- (BOOL) _isContextMenu; { return _isContextMenu; }
- (void) _setContextMenu:(BOOL) flag; { _isContextMenu=flag; }

// standard extensions

+ (float) menuBarHeight;
{
#if 1
	return 26.0;
#else
	// 240 -> 16
	// 320 -> 16
	// 480 -> 24
	// 640 -> 32
	// 768 -> 38
	// 1024 -> 51
	static int h=0;
	if(h == 0 && [[NSScreen screens] count] > 0)
		{
		h=[[[NSScreen screens] objectAtIndex:0] frame].size.height*0.05;  // 5% of screen size
		if(h < 12)
			h=12;	// for small screens
		if(h > 24)
			h=24;	// for large screens
		}
	return (float) h;
#endif
}

- (void) attachSubmenuForItemAtIndex:(int) index;
{
	NSRect r;
	NSMenu *submenu=[[_menumenu itemAtIndex:index] submenu];
#if 0
	NSLog(@"attachSubmenuForItemAtIndex %d", index);
#endif
	[[submenu delegate] menuNeedsUpdate:submenu];	// allow to update entries before really opening
	if([submenu numberOfItems] < 1)
		return; // ignore empty submenus
	if([_attachedMenuView menu] == submenu)
		return;	// already attached
	[self detachSubmenu];	// detach any other submenus before attaching a new submenu
	[submenu update];		// enable/disable menu items
	if(!_menuWindow)
		{ // create a new submenu window
		_menuWindow=[[NSPanel alloc] initWithContentRect:NSMakeRect(0.0, 0.0, 50.0, 50.0)
											   styleMask:NSBorderlessWindowMask
												 backing:NSBackingStoreBuffered
												   defer:YES];	// will be released on close
		[_menuWindow setWorksWhenModal:YES];
		[_menuWindow setLevel:NSSubmenuWindowLevel];
#if 1
		NSLog(@"win=%@", _menuWindow);
		NSLog(@"index=%d rect=%@", index, NSStringFromRect([self rectOfItemAtIndex:index]));
		NSLog(@"converted rect=%@", NSStringFromRect([self convertRect:[self rectOfItemAtIndex:index] toView:nil]));
		NSLog(@"autodisplay=%d", [_menuWindow isAutodisplay]);
#endif
		}
#if 1
	[_menuWindow setTitle:[submenu title]];
#endif
	_attachedMenuView=[[isa alloc] initWithFrame:[[_menuWindow contentView] frame]];	// make new NSMenuView of matching size
	[_menuWindow setContentView:_attachedMenuView];	// make content view
#if 0
	NSLog(@"attachedMenuView=%@", _attachedMenuView);
#endif
	[_attachedMenuView setHorizontal:NO];	// make submenus always vertical
#if 0
	NSLog(@"was setHorizontal:NO");
#endif
	[_attachedMenuView setMenu:submenu];		// define to manage selected submenu
	r=[self convertRect:[self rectOfItemAtIndex:index] toView:nil];
	r.origin=[_window convertBaseToScreen:r.origin];  // convert to screen coordinates
#if 0
	NSLog(@"screen rect=%@", NSStringFromRect(r));
#endif
	[_attachedMenuView setWindowFrameForAttachingToRect:r
											   onScreen:[_window screen]
										  preferredEdge:(_isHorizontal?NSMinYEdge:NSMaxXEdge)	// default: below or to the right
									  popUpSelectedItem:0];	// this should resize the submenu window and show the first item
	[_menuWindow orderFront:self];  // finally, make it visible
#if 0
	NSLog(@"attachSubmenu done");
#endif
}

- (NSMenu *) attachedMenu; { return [_attachedMenuView menu]; }

- (NSMenuView *) attachedMenuView; { return _attachedMenuView; }

- (void) detachSubmenu;
{
	NSPanel *win;
	if(_attachedMenuView)
		{
		[self setHighlightedItemIndex:-1];				// remove any highlighting
		[[self attachedMenu] setSupermenu:nil];			// detach supermenu
		[_attachedMenuView detachSubmenu];				// recursively detach
#if 0
		NSLog(@"detachSubmenu %@", _attachedMenuView);
#endif
		win=(NSPanel *) [_attachedMenuView window];
		_attachedMenuView=nil;		// no longer attached
		[win orderOut:nil];			// make invisible but keep cached
		}
}

- (NSFont *) font; { return _font?_font:(_isStatusBar?[NSFont menuFontOfSize:0.0]:[NSFont menuBarFontOfSize:0.0]); }

- (int) highlightedItemIndex; { return _highlightedItemIndex; }

- (float) horizontalEdgePadding; { return _horizontalEdgePadding; }

- (float) imageAndTitleOffset; { if(_needsSizing) [self sizeToFit]; return _imageAndTitleOffset; }

- (float) imageAndTitleWidth; { if(_needsSizing) [self sizeToFit]; return _imageAndTitleWidth; }

- (int) indexOfItemAtPoint:(NSPoint) point
{
	int i;
	int nc=[_cells count];
	for(i=0; i<nc; i++)
		if(NSPointInRect(point, [self rectOfItemAtIndex:i]))	// CHECKME: mouseinpoint?
			return i;	// found
	return -1;
}

- (NSRect) innerRect;
{
	NSRect r=[self bounds];
	r.origin.y+=2.0;
	r.size.height-=4.0;
	return r;
}

- (id) initAsTearOff; { return NIMP; }

- (id) initWithFrame:(NSRect) fr
{ // super is NSView
#if 0
	NSLog(@"MenuView initWithFrame:%@", NSStringFromRect(fr));
#endif
	if((self=[super initWithFrame:fr]))	// WARNING: this calls [self setMenu:[isa defaultMenu]]
		{
#if 0
		NSLog(@"initWithFrame:%@ bounds:%@", NSStringFromRect([self frame]), NSStringFromRect([self bounds]));
#endif
		_cells=[[NSMutableArray arrayWithCapacity:10] retain];
		_rectOfCells=NULL;
		_highlightedItemIndex=-1;				// nothing highlighted
		[self setHorizontal:NO];				// initially vertical
		[self setHorizontalEdgePadding:3.0];	// default
		[self _setHorizontalResize:YES];		// default
		[self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];	// resize us with our superview
		}
	return self;
}

- (BOOL) isAttached; { return [_menumenu isAttached]; }

- (BOOL) isHorizontal; { return _isHorizontal; }

- (BOOL) isTornOff; { return _isTornOff; }

- (void) itemAdded:(NSNotification *) notification;
{ // new menu item has been added
	int pos=[[[notification userInfo] objectForKey:@"NSMenuItemIndex"] intValue];	// position
	id c=[[[NSMenuItemCell alloc] init] autorelease];		// make new cell
#if 0
	NSLog(@"itemAdded - pos=%d, cell=%@", pos, c);
#endif
	[_cells insertObject:c atIndex:pos];				// make new slot (will be replaced with c)
	_rectOfCells=(NSRect *) objc_realloc(_rectOfCells, [_cells count]*sizeof(NSRect));	// adjust size if needed
	_rectOfCells[pos]=NSZeroRect;	// clear
	// might have to update highlighting!!
	[self setMenuItemCell:c forItemAtIndex:pos];	// to add all cell connections and updates
	[self setNeedsDisplayForItemAtIndex:pos];		// redisplay changed item
#if 0
	NSLog(@"itemAdded - %@", self);
#endif
}

- (void) itemChanged:(NSNotification *) notification;
{
	int pos=[[[notification userInfo] objectForKey:@"NSMenuItemIndex"] intValue];	// position
	id cell=[self menuItemCellForItemAtIndex:pos];					// get cell
#if 0
	NSMenuItem *item=[[_menumenu itemArray] objectAtIndex:pos];							// changed item
	NSLog(@"itemChanged - pos=%d, item=%@", pos, item);
#endif
	// FIXME: can't we postpone and detect if we really need to resize during the display phase???
	[cell setNeedsSizing:YES];					// we may need to resize
	_needsSizing=YES;							// recalculate
	[self setNeedsDisplayForItemAtIndex:pos];   // redisplay changed item
}

- (void) itemRemoved:(NSNotification *) notification;
{
	int pos=[[[notification userInfo] objectForKey:@"NSMenuItemIndex"] intValue];	// position
	id cell=[self menuItemCellForItemAtIndex:pos];					// get cell
#if 0
	NSMenuItem *item=[[_menumenu itemArray] objectAtIndex:pos];							// changed item
	NSLog(@"itemRemoved - pos=%d, removeditem=%@ retainCount=%d", pos, item, [item retainCount]);
#endif
	[cell setMenuItem:nil];	// remove reference to menu item to be shown
	[cell setMenuView:nil];	// remove reference to myself
	[_cells removeObjectAtIndex:pos];	// this will dealloc the itemCell
#if 0
	NSLog(@"cells count %u", [_cells count]);
#endif
	if([_cells count] > 10)	// keep last 10 items
		_rectOfCells=(NSRect *) objc_realloc(_rectOfCells, [_cells count]*sizeof(NSRect));	// adjust size
	_needsSizing=YES;	// recalculate
	[self setNeedsDisplay:YES];
}

- (float) keyEquivalentOffset; { if(_needsSizing) [self sizeToFit]; return _keyEquivalentOffset; }

- (float) keyEquivalentWidth; { if(_needsSizing) [self sizeToFit]; return _keyEquivalentWidth; }

- (NSPoint) locationForSubmenu:(NSMenu *) submenu;
{
	NSRect p;
	int idx;
#if 1
	NSLog(@"locationForSubmenu");
	NSLog(@"should not be used!");
#endif
	if(_needsSizing)
		[self sizeToFit];
	idx=[_menumenu indexOfItemWithSubmenu:submenu];	// locate submenu
	if(idx < 0)
		return [self frame].origin;
	p=_rectOfCells[idx];		// location of referenced menu item
	if(_isHorizontal)
		{ // below/above
		p.origin.y-=p.size.height;	// below
		}
	else
		{ // right/left
		p.origin.x+=p.size.width;	// right of menu
		// should check if submenu itself fits there
		}
	return p.origin;
}

- (NSMenu *) menu; { return _menumenu; }

- (NSMenuItemCell *) menuItemCellForItemAtIndex:(int) index;
{
	return [_cells objectAtIndex:index];
}

- (BOOL) needsSizing; { return _needsSizing; }

- (void) performActionWithHighlighingForItemAtIndex:(int) index;
{
	NSMenuItemCell *c=[self menuItemCellForItemAtIndex:index];
	[self setHighlightedItemIndex:index];
	[self display];
	[c performClick:[c menuItem]];
	// delay by running loop for a certain interval
	[self setHighlightedItemIndex:-1];	// remove any highlighting
	[self display];
}

- (BOOL) performKeyEquivalent:(NSEvent*)event
{ // find a menu item that responds to this key event
	return [_menumenu performKeyEquivalent:event];
}

- (NSRect) rectOfItemAtIndex:(int) index;
{
	if(_needsSizing)
		[self sizeToFit];
	NSCParameterAssert(index >= 0 && index < [_cells count]);		
	return _rectOfCells[index];
}

- (void) setFont:(NSFont *) f;
{
	if(!f) f=[NSFont menuFontOfSize:0];	// susbtitute default
	if(_font == f)
		return;
	ASSIGN(_font, f);
	_needsSizing=YES;
}

- (void) setHighlightedItemIndex:(int) index;
{
	NSMenuItemCell *c;
#if 0
	NSLog(@"setHighlightedItemIndex: %d", index);
#endif
	if(_highlightedItemIndex == index)
		return;	// no change
	if(_highlightedItemIndex >= 0)
		{ // lowlight previous
		[[self menuItemCellForItemAtIndex:_highlightedItemIndex] setHighlighted:NO];		// remove highlighting
		[self setNeedsDisplayForItemAtIndex:_highlightedItemIndex];
		}
	_highlightedItemIndex=index;
	if(_highlightedItemIndex >= 0)
		{
		NSMenuItem *i;
		c=[self menuItemCellForItemAtIndex:_highlightedItemIndex];
		i=[c menuItem];
		// FIXME: always enable items having a private view
		if([i isSeparatorItem] || ![i isEnabled])
			{ // don't highlight separators or disabled items
#if 0
			NSLog(@"item is separator or not enabled");
#endif
			_highlightedItemIndex=-1;
			return;
			}
		[c setHighlighted:YES];	// add new highlighting
		[self setNeedsDisplayForItemAtIndex:_highlightedItemIndex];
		}
}

- (void) setHorizontal:(BOOL) flag;
{
	int i;
	int nc;
	if(_isHorizontal==flag)
		return;	// no change
#if 0
	NSLog(@"setHorizontal:%d", flag);
#endif
	_isHorizontal=flag;
	nc=[_cells count];
	for(i=0; i<nc; i++)
		[[_cells objectAtIndex:i] setNeedsSizing:YES];	// all cells need resizing
	_needsSizing=YES;	// resize and rearrange
}

- (void) setHorizontalEdgePadding:(float) pad; { _horizontalEdgePadding=pad; _needsSizing=YES; }

- (void) setMenu:(NSMenu *) m;
{
	int i, cnt;
	if(_menumenu == m)
		return;	// no change
#if 1
	NSLog(@"setMenu");
#endif
#if 0
	NSLog(@"%@ setMenu: %@", self, m);
#endif
	if(_menumenu)
		{ // remove all observers for this menu
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidAddItemNotification object:_menumenu];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidChangeItemNotification object:_menumenu];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidRemoveItemNotification object:_menumenu];
		[_menumenu setMenuRepresentation:nil];
		if([self highlightedItemIndex] >= [m numberOfItems])
			[self setHighlightedItemIndex:-1];	// remove highlighting
		}
	for(i=[m numberOfItems], cnt=[_cells count]; i<cnt; i++)
		{ // remove all cells we don't need any more
		id cell=[_cells lastObject];
		[cell setMenuItem:nil];
		[cell setMenuView:nil];	// invalidate cell connection
		[_cells removeLastObject];
		}
	[_menumenu autorelease];
	if((_menumenu=[m retain]))
		{ // set new menu
		cnt=[_menumenu numberOfItems];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemAdded:) name:NSMenuDidAddItemNotification object:_menumenu];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemChanged:) name:NSMenuDidChangeItemNotification object:_menumenu];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemRemoved:) name:NSMenuDidRemoveItemNotification object:_menumenu];
		[_menumenu setMenuRepresentation:self];
#if 0
		NSLog(@"itemAdded - pos=%d, cell=%@", pos, c);
#endif
		_rectOfCells=(NSRect *) objc_realloc(_rectOfCells, cnt*sizeof(NSRect));	// adjust size
#if 0
		NSLog(@"itemAdded - %@", self);
#endif
		for(i=[_cells count]; i<cnt; i++)
			[_cells addObject:[[[NSMenuItemCell alloc] init] autorelease]];		// make more item cells
		for(i=0; i<cnt; i++)
			{ // update menu items
			id cell=[_cells objectAtIndex:i];
			_rectOfCells[i]=NSZeroRect;	// clear size info
			[self setMenuItemCell:cell forItemAtIndex:i];		// to add all cell connections and updates
			}
		if(cnt > 50)
			NSLog(@"set large menu");
		_needsSizing=YES;		// even if we have no cells...
		[_menumenu update];		// auto-enable and resize if needed
		}
}

- (void) setMenuItemCell:(NSMenuItemCell *) cell forItemAtIndex:(int) index;
{
	[_cells replaceObjectAtIndex:index withObject:cell];
	[cell setMenuItem:[[_menumenu itemArray] objectAtIndex:index]];	// make a reference to menu item to be shown
	[cell setMenuView:self];			// make reference to myself
	[cell setFont:[self font]];			// set font
	[cell setHighlighted:(_highlightedItemIndex==index)];	// may be the currently highlighted element
	_needsSizing=YES;	// we will need to recalc size - which will also redisplay the full menu
}

- (void) setNeedsDisplayForItemAtIndex:(int) index;
{
	[[_cells objectAtIndex:index] setNeedsDisplay:YES];				// mark cell to redraw itself
	[self setNeedsDisplayInRect:[self rectOfItemAtIndex:index]];	// we need redrawing for this cell
}

- (void) setNeedsSizing:(BOOL) flag; { _needsSizing=flag; }

- (void) setWindowFrameForAttachingToRect:(NSRect) ref
								 onScreen:(NSScreen *) screen
							preferredEdge:(NSRectEdge) edge
						popUpSelectedItem:(int) index;
{
	NSRect mf;  // new menu frame in content rect coordinates
	NSRect sf=[[_window screen] visibleFrame];
	NSRect item=NSZeroRect;
#if 1
	NSLog(@"setWindowFrameForAttachingToRect:%@ screen:... edge:%d item:%d", NSStringFromRect(ref), edge, index);
#endif
	if(_needsSizing)
		[self sizeToFit];	// this will initially resize the window and our frame/bounds to fit the full menu
	edge &= 3;
	mf.size=_frame.size;   // copy content size
	if(index >= 0)
		item=[self rectOfItemAtIndex:index];	// get rect of item to show
#if 1
	NSLog(@"screen visble frame=%@", NSStringFromRect(sf));
	NSLog(@"item rect=%@", NSStringFromRect(item));
#endif
	switch(edge)
		{ // calculate preferred location
		case NSMinXEdge:	// to the left
			mf.origin.x=ref.origin.x-mf.size.width;
			mf.origin.y=ref.origin.y+ref.size.height-mf.size.height+item.origin.y; // align top edge of selected item
			break;
		case NSMaxXEdge:	// to the right
			mf.origin.x=ref.origin.x+ref.size.width;
			mf.origin.y=ref.origin.y+ref.size.height-mf.size.height+item.origin.y; // align top edge
			break;
		case NSMinYEdge:	// below
			mf.origin.x=ref.origin.x-item.origin.x;
			mf.origin.y=ref.origin.y-mf.size.height;
			break;
		case NSMaxYEdge:	// above
			mf.origin.x=ref.origin.x-item.origin.x;
			mf.origin.y=ref.origin.y+ref.size.height;
			break;
		}
	if(mf.origin.x < 0)		// does not fit to the left - try to the right
		mf.origin.x=ref.origin.x+ref.size.width;
	if(mf.origin.x+mf.size.width > sf.size.width)   // does (still) not fit to the right - try (again) to the left but align right border on horizontal menus
		mf.origin.x=ref.origin.x-mf.size.width+((edge==NSMinYEdge || edge==NSMaxYEdge)?ref.size.width:0.0);
	if(mf.origin.x < 0)
		{
		mf.origin.x=0.0;	// still no fit - needs horizontal scrolling
		mf.size.width=sf.size.width;	// limit to screen
		}
	if(mf.origin.y < 0)		// try above if it does not fit below
		mf.origin.y=ref.origin.y+((edge==NSMinYEdge || edge==NSMaxYEdge)?ref.size.height:0.0);
	if(mf.origin.y+mf.size.height > sf.size.height) // try below
		mf.origin.y=ref.origin.y-mf.size.height;
	if((_isVerticallyScrolling=(mf.origin.y < 0)))
		{
		mf.origin.y=0.0;	// still no fit - needs vertical scrolling
		mf.size.height=sf.size.height;	// limit to screen
		}
#if 1
	NSLog(@"set frame=%@", NSStringFromRect(mf));
#endif
	[_window setFrame:[_window frameRectForContentRect:mf] display:NO];	// this will also change our frame&bounds since we are the contentView!
	if(_isVerticallyScrolling && index >= 0)
			{ // menu needs vertical scrolling
				NSRect f=_frame;
				if(edge == NSMinYEdge)
					f.origin.y+=item.origin.y-3.0;	// menu below
				else
					;	// above
				[self setFrameOrigin:f.origin];	// move us up/down
			}
	[self setNeedsDisplay:YES];	// needs display everything
#if 1
	NSLog(@"set frame done");
#endif
}

- (void) _calcMaxWidthOfCellComponents;
{ // get maximum width of all cell components
	unsigned int i;
	unsigned int nc;
	_imageAndTitleWidth=0.0;
	_keyEquivalentWidth=0.0;
	_stateImageWidth=0.0;
	for(i=0, nc=[_cells count]; i<nc; i++)
		{ // get element widths and determine their maximum
		NSMenuItemCell *c=[_cells objectAtIndex:i];
		float iw, tw, iatw;
		[c setNeedsSizing:YES];		// get latest values
		if((iw=[c stateImageWidth]) > _stateImageWidth)
			_stateImageWidth=iw;		// new maximum
		iw=[c imageWidth];
		tw=[c titleWidth];
		iatw=iw+tw;	// image and title width
		if(iw > 0.0 && tw > 0.0)
			iatw+=_horizontalEdgePadding;	// add padding if both elements are present
		if(iatw > _imageAndTitleWidth)
			_imageAndTitleWidth=iatw;					// new maximum
		if((iw=[c keyEquivalentWidth]) > _keyEquivalentWidth)
			_keyEquivalentWidth=iw;	// new maximum
		}
}

- (float) _calcHorizontalPositionOfCellComponents;
{
	float x=_horizontalEdgePadding;	// x: layout position - start with left-hand padding
	_stateImageOffset=x;				// state image starts here
	if(_stateImageWidth > 0)
		x+=_stateImageWidth+_horizontalEdgePadding;	// include space between state image/title
	_imageAndTitleOffset=x;			// image&title starts here
	x+=_imageAndTitleWidth;			// already includes padding between image and title
	if(_keyEquivalentWidth > 0)
		x+=_horizontalEdgePadding;	// additional space between image/title and key equivalent
	_keyEquivalentOffset=x;			// key equivalents start here
	x+=_keyEquivalentWidth;			// total cell width ends here after keyEquivalent
	return x+_horizontalEdgePadding;	// add right-hand padding
}

- (void) sizeToFit;
{ // calculate new size and positon of cells - handle horizontal vs. vertical - handle rightToLeft
	NSRect p;				// cell position
	NSRect f;				// frame size
	int i;
	int nc;
	if(!_needsSizing)
		return;
#if 1
	NSLog(@"sizeToFit %@", self);
#endif
	if(!_window)
		{
#if 1
		NSLog(@"  menu %@ sizeToFit has no window", [_menumenu title]);
#endif
		return;	// no reference frame (yet)
		}
	_needsSizing=NO;	// will have been done when calling other methods (avoid endless recursion)
	f=[_window frame];	// get enclosing window frame
#if 0
	NSLog(@"window: %@", window);
	NSLog(@"frame before: %@", NSStringFromRect(f));
#endif
	nc=[_cells count];
	if(nc > 50)
		NSLog(@"sizing large");
	if(_isHorizontal)
		{ // horizontal menu
		_imageAndTitleWidth=0.0;	// we don't know for a horizontal menu
		_keyEquivalentWidth=0.0;
		_stateImageWidth=0.0;
		_keyEquivalentOffset=_imageAndTitleOffset=_stateImageOffset=_horizontalEdgePadding;
		p.origin=NSMakePoint(_horizontalEdgePadding, 0.0);	// initial position (top left)
		for(i=0; i<nc; i++)
			{ // determine item positions
			NSMenuItemCell *c=[_cells objectAtIndex:i];
			[c setNeedsSizing:YES];			// get latest values (which might change dynamically if the representedObject supports the -length method)
			p.size=[c cellSize];			// get cell size (based on new total state/image widths)
			// fixme: this should already be returned by [c cellSize] - but self might not be initialized properly yet!
			p.size.height=f.size.height;	// enforce full menu bar height
#if 0
			NSLog(@"item %d width=%lf", i, p.size.width);
#endif
			_rectOfCells[i]=p;				// set new cell rectangle
			if(_isStatusBar)
				p.origin.x-=p.size.width;	// move left one cell
			else
				p.origin.x+=p.size.width;	// move right one cell
			}
		if(_isResizingHorizontally)
			f.size.width=fabs(p.origin.x);		// resize to total width of menu
		if(_isStatusBar)
			{ // flush whole status menu to right end
			for(i=0; i<nc; i++)
				{ // determine modified element positions - and redraw full status bar
				_rectOfCells[i].origin.x+=f.size.width-_horizontalEdgePadding-_rectOfCells[i].size.width; // p.origin.x is negative of total menu width
				// [self setNeedsDisplayForItemAtIndex:i];	// and we need to redraw this cell at its new position
				}
			}	
		}
	else
		{ // vertical menu
		p.origin=NSMakePoint(0.0, VERTICAL_PADDING);	// initial position
		[self _calcMaxWidthOfCellComponents];	// get maximum width
		if(_isResizingHorizontally)
			f.size.width=[self _calcHorizontalPositionOfCellComponents];	// replace by standard total width
		else
			[self _calcHorizontalPositionOfCellComponents];	// calculate only
#if 0
		NSLog(@"si:%lf-%lf i&t:%lf-%lf ke:%lf-%lf width:%lf", stateImageOffset, stateImageWidth, imageAndTitleOffset, imageAndTitleWidth, keyEquivalentOffset, keyEquivalentWidth, f.size.width);
#endif		
		for(i=0; i<nc; i++)
			{ // determine element positions
			NSMenuItemCell *c;
			c=[_cells objectAtIndex:i];
			p.size=[c cellSize];			// get cell size (based on new total state/image widths)
			p.size.width=f.size.width;				// extend cell width to total menu width
			/// FIXME: we should adjust p already here for the statusBar so that we can reduce redisplay for changed cells
			/// but how should we do that before we know the total width of the status bar???
			//		if(!NSEqualRects(rectOfCells[i], p))
			//			{ // cell has been moved/resized
			_rectOfCells[i]=p;	// set new cell rectangle
			//			[self setNeedsDisplayForItemAtIndex:ii];	// and we need to redraw this cell
			//			}
			p.origin.y+=p.size.height;	// move down one cell
			}
		f.size.height=p.origin.y+VERTICAL_PADDING;	// resize to total height
		}
#if 0
	NSLog(@"NSMenuView sizetofit: window frame=%@", NSStringFromRect(f));
#endif
	[_window setFrame:f display:NO];	// resize enclosing window (also sets our frame/bounds since we are the content view)
	[self setNeedsDisplay:YES];			// we later on need to redraw the full menu, i.e. all items
#if 1
	NSLog(@"sizetofit: done");
#endif
	if(_needsSizing)	NSLog(@"NSMenuView sizeToFit: internal inconsistency - did set needsSizing");
}

- (float) stateImageOffset; { if(_needsSizing) [self sizeToFit]; return _stateImageOffset; }

- (float) stateImageWidth; { if(_needsSizing) [self sizeToFit]; return _stateImageWidth; }

- (void) update;
{ // update autoenabling status and sizes - called once per runloop
#if 1
	NSLog(@"NSMenuView update");
#endif
	[_menumenu update];	// update our menu (and submenus)
	if(_needsSizing)
		[self sizeToFit];	// will finally set needsDisplay
#if 1
	NSLog(@"NSMenuView update done");
#endif
}

// overridden methods

- (BOOL) isFlipped; { return YES; }

- (BOOL) mouseDownCanMoveWindow; { return NO; }	// no click-move

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return NO; }	// no inking in menus...

- (BOOL) isOpaque; { return YES; }	// completely fills its background

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc %@", self);
#endif
	[self detachSubmenu];	// detach any submenu
	[_font release];
	if(_rectOfCells)
		objc_free(_rectOfCells), _rectOfCells=NULL;
	[_cells release];
	_cells=nil;	// no longer available
	[super dealloc];		// will itself call setMenu:nil !!!
}

- (void) drawRect:(NSRect) rect
{ // Drawing code here.
	int i;
	int nc=[_cells count];
	BOOL any=NO;
	if(nc > 50)
		NSLog(@"drawing large menu");
	if(_needsSizing)
		NSLog(@"NSMenuView drawRect: please call sizeToFit explicitly before calling display");	// rect is most probably inaccurate
#if 0
	NSLog(@"NSMenuView - %@ (nc=%d) drawRect:%@", [[_menumenu itemAtIndex:0] title], nc, NSStringFromRect(rect));
#endif
	//// FIXME: the following code deletes all menu items in the drawing rectangle which may be the union of 2 non-adjacent cells!
	//// so this greys out the cells in between unless we draw them all...
	[[NSColor windowBackgroundColor] set];	// draw white/light grey lines
	NSRectFill(rect);	// draw background
#if 0	// draw box around menu for testing
	if(!_isHorizontal)
		{ // draw box
		[[NSColor brownColor] set];
		// shouldn't this be frame/bounds clipped by rect???
		// everything else could generate artefacts
		NSFrameRect(rect);
		}
#endif
#if 0
	NSLog(@"background filled");
#endif
	for(i=0; i<nc; i++)
		{ // go through cells and draw them at their calculated position - if needed (needsDisplay of cell)
		NSRect cRect=[self rectOfItemAtIndex:i];	// get cell rectangle
#if 0
		NSLog(@"menu=%@", _menumenu);
		NSLog(@"menuitem=%@", [_menumenu itemAtIndex:0]);
		NSLog(@"menuitem title=%@", [[_menumenu itemAtIndex:0] title]);
		NSLog(@"%@ cell:%@%@", [[_menumenu itemAtIndex:0] title], NSStringFromRect(cRect), NSIntersectsRect(rect, cRect)?@" intersects":@"");
#endif
		// FIXME: check needsDisplay - the following code enforces all cells to display!
		// clip to rect
		if(NSMinY(_bounds) < NSMinY(_frame))
			{
			NSLog(@"up arrow");
			}
		if(NSMaxY(_bounds) > NSMaxY(_frame))
			{
			NSLog(@"down arrow");
			}
		if(NSIntersectsRect(cRect, rect))
			{
			NSMenuItemCell *cell=[_cells objectAtIndex:i];
			// FIXME - this is to avoid the grey rects
			[cell setNeedsDisplay:YES];	// so that we really (re)draw...
			[cell drawInteriorWithFrame:cRect inView:self];
			any=YES;
			}
		else if(any)
			break;	// we did leave the rect
		}
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ menu:%@ item[0]:%@ %@", 
		NSStringFromClass([self class]), 
		[_menumenu title],
		[_menumenu numberOfItems] > 0?[[_menumenu itemAtIndex:0] title]:@"?", 
		_menumenu
		];
}

- (NSString *) _longDescription;
{
	return [NSString stringWithFormat:@"%@ menu:%@ item[0]:%@ %@", 
		[super description], 
		[_menumenu title],
		[_menumenu numberOfItems] > 0?[[_menumenu itemAtIndex:0] title]:@"?", 
		_menumenu
		];
}

- (BOOL) shouldDelayWindowOrderingForEvent:(NSEvent *)anEvent; { return YES; }	// don't become key or main window
- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent { return YES; } // yes, respond immediately on activation

- (BOOL) trackWithEvent:(NSEvent *) event;
{ // FIXME: should we runloop here?
	NSPoint p;
	if(_attachedMenuView && [_attachedMenuView trackWithEvent:event])
		return YES;	// yes, it has been successfully handled by the submenu(s)
	p=[self convertPoint:[_window mouseLocationOutsideOfEventStream] fromView:nil];	// get coordinates relative to our window (we might have a different one as the event!)
	if(NSMouseInRect(p, _bounds, [self isFlipped]))
		{ // highlight (new) cell
		int item=[self indexOfItemAtPoint:p];	// get selected item
#if 0
		NSLog(@"item=%d", item);
#endif
		if(item != _highlightedItemIndex)
			{ // has changed
			[self setHighlightedItemIndex:item];	// highlight new item (which will initiate redisplay)
			if(!NSEqualRects(_bounds, _frame))
				{ // check how we have to move the bounds to keep the current item visible
				NSLog(@"autoscroll menu");
				}
			if(item >= 0 && [[_menumenu itemAtIndex:item] hasSubmenu])
				[self attachSubmenuForItemAtIndex:item];	// and open submenu if available
			else
				[self detachSubmenu];						// detach any open submenu hierarchy
			}
		return YES;
		}
	if(!_attachedMenuView)
		{
		[self setHighlightedItemIndex:-1];	// unhighligt item if we leave the menu
		return NO;
		}
	return NO;
}

- (void) mouseDown:(NSEvent *) theEvent;
{ // is not an NSControl so we must track ourselves
	NSTimeInterval menuOpenTimestamp=[theEvent timestamp];
	NSMenuView *mv;
	int idx;
	BOOL stayOpen=NO;
	[NSApp preventWindowOrdering];
#if 1
	NSLog(@"mouseDown:%@", theEvent);
#endif
	[self update];	// update/enable menu(s)
	while(YES)
		{ // loop until mouse goes up
		NSEventType type=[theEvent type];
		// FIXME: we may not even have to check this. If we are deactivated, we should simply hide the menu windows like any other panel
		if(![NSApp isActive])	// was deactivated (FIXME: do we ever see this as an event???)
			{ // detach all open submenu items
			[self detachSubmenu];
			break;
			}
		if(type == NSLeftMouseDown)
			{
			if(![self trackWithEvent:theEvent] && stayOpen)
				{ // user clicked outside after a mouse up in this loop
				[NSApp postEvent:theEvent atStart:YES];	// re-queue
				break;	// clicked outside of menu
				}
			}
		else if(type == NSLeftMouseUp)
			{
			if([theEvent timestamp]-menuOpenTimestamp > 0.5)
				break;	// wasn't hold down long enough
			stayOpen=YES;
			}
		else if(type == NSMouseMoved || type == NSLeftMouseDragged)
			{
			if(![self trackWithEvent:theEvent])
				[self detachSubmenu];	// outside of top level
			}
		theEvent = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									  untilDate:[NSDate distantFuture]			// get next event
										 inMode:NSEventTrackingRunLoopMode 
										dequeue:YES];
		}
	mv=self;
	while([mv attachedMenuView])
		mv=[mv attachedMenuView];	// go down to lowest open submenu level
	idx=[mv highlightedItemIndex];
#if 1
	NSLog(@"item selected %d", idx);
#endif
	[self setHighlightedItemIndex:-1];	// unhighligt my item
	[self detachSubmenu];				// detach all open submenu items
	if(idx >= 0)
		[[mv menu] performActionForItemAtIndex:idx];	// finally perform action - processes responder chain
}

// - (void) mouseDragged:(NSEvent *) theEvent; { return; }
// - (void) mouseUp:(NSEvent *) theEvent; { return; }

@end

@implementation NSMenu (NSPopupContextMenu)

+ (void) popUpContextMenu:(NSMenu *) menu withEvent:(NSEvent *) event forView:(NSView *) view withFont:(NSFont *) font;
{
	static NSPanel *win;
	static NSMenuView *menuView;
	NSRect r;
	int item;	// item to pop up when scrolling
#if 1
	NSLog(@"popUpContextMenu %08x", menu);
	NSLog(@"popUpContextMenu %@", [menu title]);
	NSLog(@"popUpContextMenu event %@", event);
	NSLog(@"popUpContextMenu view %@", view);
	NSLog(@"popUpContextMenu font %@", font);
#endif
	if(!menu || !event || !view)
		return;
//	[menu update];					// enable/disable menu items
	if(!win)
			{
				win=[[NSPanel alloc] initWithContentRect:NSMakeRect(49.0, 49.0, 49.0, 49.0)	// some initial position
									styleMask:NSBorderlessWindowMask
									  backing:NSBackingStoreBuffered
										defer:YES];
				[win setWorksWhenModal:YES];
				[win setLevel:NSSubmenuWindowLevel];
#if 0
				[win setTitle:@"Context Menu"];
#endif
				menuView=[[[NSMenuView class] alloc] initWithFrame:[[win contentView] frame]];	// make new NSMenuView
				[menuView setFont:font];		// set default font
				[menuView setHorizontal:NO];	// make popup menu vertical
				[menuView _setContextMenu:YES];	// close on mouseUp
				[[win contentView] addSubview:menuView];	// add to view hiearachy
			}
	[menuView setMenu:menu];		// define to manage selected menu
#if 0
	NSLog(@"win=%@", win);
	NSLog(@"autodisplay=%d", [win isAutodisplay]);
#endif
	r.origin=[[view window] convertBaseToScreen:[event locationInWindow]];	// to screen coordinates
	r.size=NSMakeSize(1.0, 1.0);
#if 1
	NSLog(@"menu to be attached to %@", NSStringFromRect(r));
#endif
	if([view respondsToSelector:@selector(selectedItem)])
		item=[(NSPopUpButton *) view indexOfSelectedItem];
	else
		item=0;	// default
	if(item < 0 || item >= [menu numberOfItems])
		item=0;
	[menuView setWindowFrameForAttachingToRect:r
									  onScreen:[win screen]
								 preferredEdge:NSMinYEdge	// default: pull down
							 popUpSelectedItem:item];
	[win orderFront:self];		// make visible
	[menuView mouseDown:event];	// pass event down - runs a tracking loop
	[win orderOut:nil];	// and close after tracking ends
}

@end
