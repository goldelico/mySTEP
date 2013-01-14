/*
   NSTabView.m

   Tabbed view classes

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Michael Hanni <mhanni@sprintmail.com>
   Date:	June 1999
   Author:	Nikolaus Schaller <hns@computer.org>
   Date:	May 2005, Apr 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSArray.h> 
#import <Foundation/NSString.h>
#import <Foundation/NSCoder.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSTabView.h>
#import <AppKit/NSTabViewItem.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSSegmentedCell.h>
#import <AppKit/NSSegmentedControl.h>

#import "NSAppKitPrivate.h"

@interface NSObject (NSTabView)
- (int) indexOfSelectedItem;	// private informal protocol
@end

//*****************************************************************************
//
// 		NSTabViewItem 
//
//*****************************************************************************

@implementation NSTabViewItem

- (id) initWithIdentifier:(id)identifier
{
	if((self=[super init]))
		{
		ASSIGN(item_ident, identifier);
		item_state = NSBackgroundTab;
		}
	return self;
}

- (void) dealloc;
{
	[item_color release];
	[item_ident release];
	[item_label release];
	[item_view release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %@ (ident:%@) view: %@", 
				NSStringFromClass([self class]), item_label, item_ident, item_view];
}

- (void) setIdentifier:(id)identifier		{ ASSIGN(item_ident, identifier); }
- (id) identifier							{ return item_ident; }
- (NSString *) label						{ return item_label; }
- (void) setLabel:(NSString *)label			{ ASSIGN(item_label, label); }

- (NSSize) sizeOfLabel:(BOOL)shouldTruncateLabel
{
	if(shouldTruncateLabel)
		;
	// FIXME: set paragraph style
	return [item_label sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[item_tabview font], NSFontAttributeName, nil]];
}

// Set view to display when item is clicked

- (void) setView:(NSView *)view				{ ASSIGN(item_view, view); }
- (NSView *) view							{ return item_view; }
- (void) setColor:(NSColor *)color			{ ASSIGN(item_color, color); }	// deprecated, i.e. not used
- (NSColor *) color							{ return item_color; }
- (NSTabState) tabState						{ return item_state; }
- (void) _setTabState:(NSTabState)tabState	{ item_state = tabState; }
- (NSRect) _tabRect							{ return item_rect; }		
- (void) _setTabRect:(NSRect) rect			{ item_rect=rect; }		
// Tab view, this is the "super" view.
- (void) _setTabView:(NSTabView *)tabView	{ item_tabview=tabView; }
- (NSTabView *) tabView						{ return item_tabview; }
- (id) initialFirstResponder				{ return item_initialFirstResponder; }
- (void) setInitialFirstResponder:(NSView*)view			{ item_initialFirstResponder=view; }

- (void) drawLabel:(BOOL)shouldTruncateLabel inRect:(NSRect)tabRect
{
	NSColor *labelColor=[NSColor controlTextColor];
	id delegate=[(NSTabView *) item_tabview delegate];
	NSDictionary *attribs;
	NSSize bounds;
	NSMutableParagraphStyle *para=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
	if([delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)] &&
		![delegate tabView:(NSTabView *) item_tabview shouldSelectTabViewItem:self])
		labelColor=[NSColor disabledControlTextColor];	// show as disabled
	[para setAlignment:NSCenterTextAlignment];
	attribs=[NSDictionary dictionaryWithObjectsAndKeys:
		labelColor, NSForegroundColorAttributeName,
		[(NSTabView *) item_tabview font], NSFontAttributeName,
		para, NSParagraphStyleAttributeName,
		nil];
	[para release];
	bounds=[item_label boundingRectWithSize:(NSSize){ FLT_MAX, FLT_MAX } options:0 attributes:attribs].size;
	tabRect.origin.y+=(tabRect.size.height-bounds.height)/2.0;
	[item_label drawInRect:tabRect withAttributes:attribs];
}

- (void) encodeWithCoder: (NSCoder *)aCoder				// NSCoding protocol
{
	[aCoder encodeObject:item_ident];
	[aCoder encodeObject:item_label];
	[aCoder encodeObject:item_view];
	[aCoder encodeObject:item_color];
	[aCoder encodeValueOfObjCType: @encode(NSTabState) at: &item_state];
	[aCoder encodeObject:item_tabview];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		item_color=[[aDecoder decodeObjectForKey:@"NSColor"] retain];
		item_ident=[[aDecoder decodeObjectForKey:@"NSIdentifier"] retain];
		item_label=[[aDecoder decodeObjectForKey:@"NSLabel"] retain];
		item_tabview=[aDecoder decodeObjectForKey:@"NSTabView"];	// tabview we belong to
		item_view=[[aDecoder decodeObjectForKey:@"NSView"] retain];	// the real view
		item_state = NSBackgroundTab;
#if 0
		NSLog(@"initWithCoder -> %@", self);
#endif
		return self;
		}
	[aDecoder decodeValueOfObjCType: @encode(id) at: &item_ident];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &item_label];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &item_view];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &item_color];
	[aDecoder decodeValueOfObjCType: @encode(NSTabState) at:&item_state];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &item_tabview];
	
	return self;
}

@end /* NSTabViewItem */

//*****************************************************************************
//
// 		NSTabView 
//
//*****************************************************************************

@implementation NSTabView

static struct _NSTabViewSizing
{
	float hspacing;		// horizontal spacing
	float baseline;		// baseline
	float tabheight;	// height of a tab
	float voffset;		// vertical offset for contentRect
	NSSize adjust;		// adjustment (inset) for contentRect
} tsz[]={
	{ 24.0, 5.0, 20.0, 10.0, { 10.0, 23.0 } },
	{ 24.0, 3.0, 16.0, 6.0, { 10.0, 19.0 } },
	{ 20.0, 4.0, 13.0, 3.0, { 10.0, 16.0 } },
	{ 24.0, 5.0, 20.0, 10.0, { 10.0, 23.0 } },
};

- (void) _tile;
{
	NSView *tv=[tab_selected view];
#if 0
	NSLog(@"NSTabView _tile %@ - %@", self, tv);
#endif
	[tv setAutoresizesSubviews:YES];
	[tv setFrame:[self contentRect]];
}

- (id) initWithFrame:(NSRect)rect
{
	if((self=[super initWithFrame:rect]))
		{
		tab_items = [NSMutableArray new];
		tab_font = [[NSFont systemFontOfSize:0] retain];
		}
	return self;
}

- (BOOL) isFlipped							{ return YES; }

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ csize %d type %d items %@", [super description], _controlSize, tab_type, tab_items];
}

- (void) addTabViewItem:(NSTabViewItem *)tabViewItem
{ // insert at end
	[self insertTabViewItem:tabViewItem atIndex:[tab_items count]];
}

- (void) insertTabViewItem:(NSTabViewItem *)tabViewItem 
				   atIndex:(int)index
{
	[tabViewItem _setTabView:self];
	[tab_items insertObject:tabViewItem atIndex:index];
//	[[tabViewItem view] setHidden:YES];
//	[self addSubview:[tabViewItem view]];
//	if(!tab_selected)
//		[self selectFirstTabViewItem:nil];	
	if([tab_delegate respondsToSelector:
			@selector(tabViewDidChangeNumberOfTabViewItems:)])
		[tab_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

- (void) removeTabViewItem:(NSTabViewItem *)tabViewItem
{
	int i = [tab_items indexOfObject:tabViewItem];
	if(tabViewItem == tab_selected)
		[self selectNextTabViewItem:nil];	// we are the selected one
	if(i == NSNotFound)
		return;

	[[tabViewItem view] removeFromSuperview];
	[tab_items removeObjectAtIndex:i];

	if([tab_delegate respondsToSelector:
		@selector(tabViewDidChangeNumberOfTabViewItems:)])
		[tab_delegate tabViewDidChangeNumberOfTabViewItems:self];
}

- (int) indexOfTabViewItem:(NSTabViewItem *)tabViewItem
{
	return [tab_items indexOfObject:tabViewItem];
}

- (int) indexOfTabViewItemWithIdentifier:(id)identifier
{
	int numberOfTabs = [tab_items count];
	int i;
	for(i = 0; i < numberOfTabs; i++)
		{
		NSTabViewItem *anItem = [tab_items objectAtIndex:i];
		if([[anItem identifier] isEqual:identifier])
			return i;
		}
	return NSNotFound;
}

- (NSTabViewItem *) tabViewItemAtIndex:(int)index
{
	return [tab_items objectAtIndex:index];
}

- (int) numberOfTabViewItems			{ return [tab_items count]; }
- (NSArray *) tabViewItems				{ return (NSArray *)tab_items; }

- (void) selectFirstTabViewItem:(id)sender	
{ 
	if([tab_items count] > 0)
		[self selectTabViewItemAtIndex:0];
}

- (void) selectLastTabViewItem:(id)sender
{
	[self selectTabViewItem:[tab_items lastObject]];
}

- (void) selectNextTabViewItem:(id)sender
{
	if(tab_selected_item < [tab_items count]-1)
		[self selectTabViewItemAtIndex:tab_selected_item+1];
}

- (void) selectPreviousTabViewItem:(id)sender
{
	if(tab_selected_item > 0)
		[self selectTabViewItemAtIndex:tab_selected_item-1];
}

- (NSTabViewItem *) selectedTabViewItem
{
	return [tab_items objectAtIndex:tab_selected_item];
}

- (void) selectTabViewItem:(NSTabViewItem *)tabViewItem
{
#if 0
	NSLog(@"selectTabViewItem: %@", tabViewItem);
#endif
	if(tab_selected == tabViewItem)
		return;	// not changed
	if([tab_delegate respondsToSelector:@selector(tabView:shouldSelectTabViewItem:)] &&
		![tab_delegate tabView:self shouldSelectTabViewItem:tabViewItem])
			return;
	if([tab_delegate respondsToSelector:@selector(tabView:willSelectTabViewItem:)])
		[tab_delegate tabView:self willSelectTabViewItem:tab_selected];
	if(tab_selected)
		{ // unselect previous tab
		NSView *v=[tab_selected view];
		[tab_selected _setTabState:NSBackgroundTab];
		[self setNeedsDisplayInRect:[tab_selected _tabRect]];
		[v removeFromSuperview];
		}
	tab_selected = tabViewItem;
	tab_selected_item = [tab_items indexOfObjectIdenticalTo:tab_selected];	// item number
	if(tab_selected_item == NSNotFound)
		NSLog(@"NSTabViewItem is not an item of the NSTabView: %@", tab_selected);
	else
		{
		NSView *v=[tab_selected view];
		[tab_selected _setTabState:NSSelectedTab];
		[self setNeedsDisplayInRect:[tab_selected _tabRect]];	// redraw tab
		if([_subviews indexOfObjectIdenticalTo:v] == NSNotFound)
			[self addSubview:v];	// if not yet a subview - this may already resize the sbviews
#if 1	// FIXME
		if(!NSEqualRects([v frame], [self contentRect]))
			{
			NSLog(@"mismatch between loaded content rect %@ and calculated %@", NSStringFromRect([v frame]), NSStringFromRect([self contentRect]));
			[self _tile];	// resize to fit - but only once
			}
#endif
		[v setNeedsDisplay:YES];	// redraw new content
		if([tab_delegate respondsToSelector:@selector(tabView:didSelectTabViewItem:)])
			[tab_delegate tabView:self didSelectTabViewItem:tab_selected];
		}
}

- (void) viewDidMoveToWindow { [self _tile]; }
- (void) viewDidMoveToSuperview { [self _tile]; }

- (void) setFrame:(NSRect)rect
{
	if(NSEqualRects(rect, _frame))
		return;	// ignore unchanged size
	[super setFrame:rect];
	[self _tile];
}

- (void) setFrameSize:(NSSize)size
{
	if(NSEqualSizes(size, _frame.size))
		return;	// ignore unchanged size
	[super setFrameSize:size];
	[self _tile];
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
	if(NSEqualSizes(oldSize, _frame.size))
		return;	// ignore unchanged size
	[self _tile];
}

- (void) selectTabViewItemAtIndex:(int)index
{
	[self selectTabViewItem:[tab_items objectAtIndex:index]];
}

- (void) selectTabViewItemWithIdentifier:(id)identifier;
{
	int index=[tab_items count];
	while(index-- > 0)
		{
		NSTabViewItem *i=[tab_items objectAtIndex:index];
		if([[i identifier] isEqual:identifier])
			{ // found
			[self selectTabViewItem:i];
			return;
			}
		}
}

- (void) takeSelectedTabViewItemFromSender:(id)sender
{
	if([sender respondsToSelector:@selector(indexOfSelectedItem)])
		[self selectTabViewItemAtIndex:[sender indexOfSelectedItem]];
	else if([sender isKindOfClass:[NSMatrix class]])
		{
		// determine index of selectedCell (column+nColumns*row)
		NIMP;
		}
	else if([sender isKindOfClass:[NSSegmentedControl class]])
		[self selectTabViewItemAtIndex:[(NSSegmentedCell *) [sender cell] tagForSegment:[(NSSegmentedControl *)sender selectedSegment]]];
}

- (void) setFont:(NSFont *)font			{ ASSIGN(tab_font, font); }
- (NSFont *) font						{ return tab_font; }

- (void) setTabViewType:(NSTabViewType)tabViewType
{
	tab_type = tabViewType;
}

- (NSTabViewType) tabViewType			{ return tab_type; }
- (void) setDrawsBackground:(BOOL)flag	{ tab_draws_background = flag; }
- (BOOL) drawsBackground				{ return tab_draws_background; }

- (void) setAllowsTruncatedLabels:(BOOL)allowTruncatedLabels
{
	tab_truncated_label = allowTruncatedLabels;
}

- (BOOL) allowsTruncatedLabels			{ return tab_truncated_label; }
- (void) setDelegate:(id)anObject		{ tab_delegate = anObject; }
- (id) delegate							{ return tab_delegate; }
- (NSSize) minimumSize					{ return NSZeroSize; }

- (void) setControlSize:(NSControlSize) sz
{
	_controlSize = sz&3;
	[self setTabViewType:tab_type];	// resize
}

- (NSControlSize) controlSize; { return _controlSize; }

- (void) setControlTint:(NSControlTint) t
{
	_controlTint = t;
	// update display
}

- (NSControlTint) controlTint; { return _controlTint; }

- (NSRect) _tabRect
{
	switch(tab_type)
		{
		case NSTopTabsBezelBorder:
		case NSLeftTabsBezelBorder:
		case NSBottomTabsBezelBorder:
		case NSRightTabsBezelBorder:
			{
				unsigned i, numberOfTabs = [tab_items count];
				float hspacing;
				NSRect tabRect=[self bounds];
				float width=0.0;
				hspacing=tsz[_controlSize].hspacing;
				tabRect.origin.y+=tsz[_controlSize].baseline;
				tabRect.size.height=tsz[_controlSize].tabheight;
				for(i = 0; i < numberOfTabs; i++) 
					{ // calculate total width of all tabs (to center)
					NSTabViewItem *anItem = [tab_items objectAtIndex:i];
					width+=[anItem sizeOfLabel:tab_truncated_label].width;
					}
				tabRect.origin.x=(tabRect.size.width-width-numberOfTabs*hspacing)/2.0;	// start at center
				return tabRect;
			}
		case NSNoTabsBezelBorder:
		case NSNoTabsLineBorder:
		case NSNoTabsNoBorder:
		default:
			return NSZeroRect;
		}
}

- (NSRect) contentRect
{
	NSRect rect=[self bounds];
	rect.origin=NSZeroPoint;
	switch(tab_type) 
		{
/*
		case NSLeftTabsBezelBorder:
			rect.origin.y+=8.0;
			break;
		case NSRightTabsBezelBorder:
			rect.origin.y+=8.0;
			break;
*/
		case NSBottomTabsBezelBorder:
			rect.origin.y-=2.0*tsz[_controlSize].voffset;
			break;
		case NSTopTabsBezelBorder:
			break;
		case NSNoTabsBezelBorder:
		case NSNoTabsLineBorder:
		default:
			return rect;
		}
	rect.origin.y+=tsz[_controlSize].voffset;
	rect=NSInsetRect(rect, tsz[_controlSize].adjust.width, tsz[_controlSize].adjust.height);
	return rect;
}

- (void) _drawItem:(NSTabViewItem *) anItem;
{
	NSRect tabRect=[anItem _tabRect];
	unsigned i=[tab_items indexOfObjectIdenticalTo:anItem];
	int border=(i==0?1:0)+(i==[tab_items count]-1?2:0);	// handle rounded corners
	NSTabState itemState = [anItem tabState];
	[NSBezierPath _drawRoundedBezel:border inFrame:tabRect enabled:YES selected:(itemState == NSSelectedTab) highlighted:(itemState == NSPressedTab) radius:5.0];
	[anItem drawLabel:tab_truncated_label inRect:tabRect];	// this saves the tabRect
}

- (void) drawRect:(NSRect)rect
{
	unsigned i, numberOfTabs = [tab_items count];
	float width=0.0;
	float hspacing;
	NSRect tabRect=[self bounds];
	NSRect borderRect;
	float delta;
	// FIXME: can we skip/optimize this if we have NSNoTabs*Border?
	hspacing=tsz[_controlSize].hspacing;
	tabRect.origin.y+=tsz[_controlSize].baseline;
	tabRect.size.height=tsz[_controlSize].tabheight;
	for(i = 0; i < numberOfTabs; i++) 
		{ // calculate total width of all tabs (to center)
		NSTabViewItem *anItem = [tab_items objectAtIndex:i];
		width+=[anItem sizeOfLabel:tab_truncated_label].width;
		}
	tabRect.origin.x=(tabRect.size.width-width-numberOfTabs*hspacing)/2.0;	// center all tabs
	borderRect=NSInsetRect([self contentRect], -3.0, -3.0);	// basically around tabs
	delta=borderRect.origin.y-(tabRect.origin.y+tabRect.size.height/2.0-0.5);
	borderRect.origin.y-=delta;
	borderRect.size.height+=delta;
	switch(tab_type) 
		{
		case NSLeftTabsBezelBorder:
		case NSRightTabsBezelBorder:
		case NSTopTabsBezelBorder:
		case NSBottomTabsBezelBorder:
		case NSNoTabsBezelBorder:
			{
				NSBezierPath *b;
				b=[NSBezierPath _bezierPathWithBoxBezelInRect:borderRect radius:6.0];
				[[NSColor controlHighlightColor] set];
				[b fill];
				[[NSColor lightGrayColor] set];
				[b stroke];
#if 0
				[[NSColor redColor] set];
				NSRectFill([self contentRect]);
#endif
				break;
			}
		case NSNoTabsLineBorder:
			{
				[[NSColor controlHighlightColor] set];
				NSRectFill(borderRect);
				[[NSColor lightGrayColor] set];
				NSFrameRect(borderRect);
				break;
			}
		default:
			break;
		}
	for (i = 0; i < numberOfTabs; i++) 
		{ // draw tab if it falls within rect
		NSTabViewItem *anItem = [tab_items objectAtIndex:i];
		NSSize s = [anItem sizeOfLabel:tab_truncated_label];
		tabRect.size.width=s.width+hspacing;	// define drawing box incl. spacing
		if(NSIntersectsRect(tabRect, rect))
			{ // is at least partially visible
			[anItem _setTabRect:tabRect];	// cache for mouseDown etc. (must be drawn once to be initialized)
			[self _drawItem:anItem];
			}
		tabRect.origin.x+=tabRect.size.width;	// go to next one
		}
}

- (NSTabViewItem *) tabViewItemAtPoint:(NSPoint)point
{
	int numberOfTabs = [tab_items count];						// Event handling.
	int i;
	for(i = 0; i < numberOfTabs; i++) 
		{
		NSTabViewItem *aTab = [tab_items objectAtIndex:i];
		if(NSPointInRect(point, [aTab _tabRect]))	// private method returns where it has been drawn last time
			return aTab;
		}
	return nil;
}

- (void) mouseDown:(NSEvent *)event
{
	NSTabViewItem *aTab=nil, *prev=nil;
	NSTabState prevstate=NSBackgroundTab;
	while([event type] != NSLeftMouseUp)	// loop until mouse goes up 
		{
		NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
		aTab = [self tabViewItemAtPoint:p];
#if 0
		NSLog(@"NSTabView mouseDown point=%@", NSStringFromPoint(p));
		NSLog(@"NSTabView item=%@", aTab);
#endif
		if(aTab != prev)
			{ // mouse has moved to a different tab
			if(prev)
				{ // there was one selected
				[prev _setTabState:prevstate];
				[self setNeedsDisplayInRect:[prev _tabRect]];	// redraw in previous state
				}
			if(aTab)
				{ // there is one selected now
				prevstate=[aTab tabState];	// save previous state (NSSelectedTab/NSBackgroundTab)
				if(prevstate != NSSelectedTab)
					[aTab _setTabState:NSPressedTab];	// selected tab overrides
				[self setNeedsDisplayInRect:[aTab _tabRect]];	// redraw in pressed state
				}
			prev=aTab;
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
  		}
	if(prev)
		{ // unhighlight last one
		[prev _setTabState:prevstate];
		[self setNeedsDisplayInRect:[prev _tabRect]];	// redraw in previous state
		}
#if 0
	NSLog(@"clicked tab: %@", aTab);
#endif
	if(aTab)
		[self selectTabViewItem:aTab];	// this will update anything else
}

- (void) encodeWithCoder: (NSCoder*)aCoder				// NSCoding Protocol
{ 
	[super encodeWithCoder: aCoder];
			
	[aCoder encodeObject:tab_items];
	[aCoder encodeObject:tab_font];
	[aCoder encodeValueOfObjCType: @encode(NSTabViewType) at: &tab_type];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &tab_draws_background];
	[aCoder encodeValueOfObjCType: @encode(BOOL) at: &tab_truncated_label];
	[aCoder encodeObject:tab_delegate];
	[aCoder encodeValueOfObjCType: "i" at: &tab_selected_item];
}

- (id) initWithCoder: (NSCoder*)aDecoder
{
	self=[super initWithCoder: aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		int vFlags;
		tab_truncated_label=[aDecoder decodeBoolForKey:@"NSAllowTruncatedLabels"];
		tab_draws_background=[aDecoder decodeBoolForKey:@"NSDrawsBackground"];
		vFlags=[aDecoder decodeIntForKey:@"NSTvFlags"];
#define NEEDSLAYOUT ((vFlags&0x80000000)!=0)
#define CONTROLTINT ((vFlags>>28)&7)	// ???
		_controlTint=CONTROLTINT;
#define CONTROLSIZE ((vFlags>>27)&3)
		_controlSize=CONTROLSIZE;
#if 0
		NSLog(@"vFlags=%08x controlSize=%d", vFlags, _controlSize);
#endif
#define TABTYPE ((vFlags>>0)&0x00000007)
		tab_type=TABTYPE;
		tab_items=[[aDecoder decodeObjectForKey:@"NSTabViewItems"] retain];
		tab_font=[[aDecoder decodeObjectForKey:@"NSFont"] retain];
		[self selectTabViewItem:[aDecoder decodeObjectForKey:@"NSSelectedTabViewItem"]];
		[self setDelegate:[aDecoder decodeObjectForKey:@"NSDelegate"]];
		if(!tab_selected)
			[self selectFirstTabViewItem:nil];
#if 0
		NSLog(@"NSTabView initialized to %@", [self _descriptionWithSubviews]);
#endif
		return self;
		}
	[aDecoder decodeValueOfObjCType: @encode(id) at: &tab_items];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &tab_font];
	[aDecoder decodeValueOfObjCType: @encode(NSTabViewType) at:&tab_type];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tab_draws_background];
	[aDecoder decodeValueOfObjCType: @encode(BOOL) at: &tab_truncated_label];
	[aDecoder decodeValueOfObjCType: @encode(id) at: &tab_delegate];
	[aDecoder decodeValueOfObjCType: "i" at: &tab_selected_item];
	
	return self;
}

// - (NSWindow *) window; { return _window; }

@end /* NSTabView */
