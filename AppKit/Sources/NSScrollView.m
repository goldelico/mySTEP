/*
   NSScrollView.m

   View which scrolls another via a clip view.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	July 1997
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:	October 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <AppKit/NSScroller.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSRulerView.h>
#import <AppKit/NSTableView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSColor.h>

#import "NSAppKitPrivate.h"

// Class variables
static Class __rulerViewClass = nil;

@implementation NSScrollView

+ (void) setRulerViewClass:(Class)aClass	{ __rulerViewClass = aClass; }
+ (Class) rulerViewClass					{ return __rulerViewClass; }

+ (NSSize) contentSizeForFrameSize:(NSSize)frameSize	// calc content size by
			 hasHorizontalScroller:(BOOL)hFlag			// taking into account 
			   hasVerticalScroller:(BOOL)vFlag			// the border type
						borderType:(NSBorderType)borderType
{
	NSSize size = frameSize;

	if (hFlag)		// account for scroller
		size.height -= [NSScroller scrollerWidth];
	if (vFlag)						
		size.width -= [NSScroller scrollerWidth];

	switch (borderType) 
		{
		case NSLineBorder:
		case NSGrooveBorder:
		case NSBezelBorder:
			size.width -= 2;
			size.height -= 2;
			break;
		case NSNoBorder:
			break;
  		}

	return size;
}

+ (NSSize) frameSizeForContentSize:(NSSize)contentSize
			 hasHorizontalScroller:(BOOL)hFlag
			   hasVerticalScroller:(BOOL)vFlag
						borderType:(NSBorderType)borderType
{
	NSSize size = contentSize;

	if (hFlag)											// account for scroller
		size.height += [NSScroller scrollerWidth];
	if (vFlag)						
		size.width += [NSScroller scrollerWidth];

	switch (borderType) 
		{
		case NSLineBorder:
			size.width += 2;
			size.height += 2;
			break;
	
		case NSBezelBorder:
		case NSGrooveBorder:
			size.width += 4;
			size.height += 4;
		case NSNoBorder:
			break;
  		}

	return size;
}

- (id) initWithFrame:(NSRect)rect
{
#if 0
	NSLog(@"[NSScrollView initWithFrame]");
#endif
	if((self=[super initWithFrame:rect]))
		{
		if(!_prohibitTiling)	// skip if called from initWithCoder
			[self setContentView:[[NSClipView alloc] initWithFrame:rect]];	// install default content view
		[self setLineScroll:10];
		[self setPageScroll:40];
		_borderType = NSBezelBorder;
		_scrollsDynamically = YES;
		}
	return self;
}

#if 0
- (void) dealloc;
{
	[super dealloc];
}
#endif

- (void) setContentView:(NSClipView*)aView
{
#if 0
	NSLog(@"NSScrollView setContentView:%@", aView);
#endif
	if(_contentView == aView || aView == nil)
		return;
	if(_contentView)
		[_contentView removeFromSuperviewWithoutNeedingDisplay];
	_contentView = aView;
	[self addSubview:_contentView];
	if([aView documentView])
		[self setDocumentView:[aView documentView]];	// set document view as needed/initialized
	[self tile];
}

- (void) setHorizontalScroller:(NSScroller*)aScroller
{
	if(_horizScroller == aScroller)
		return;
	if(_horizScroller != nil)
		[_horizScroller removeFromSuperview];
	if ((_horizScroller = aScroller) != nil) 
		{
		[_horizScroller setTarget:self];
		[_horizScroller setAction:@selector(_doScroller:)];
		}
	else
		_hasHorizScroller = NO; 
}

- (void) setHasHorizontalScroller:(BOOL)flag
{
	if (_hasHorizScroller == flag)
		return;
	if (flag) 
		{
		if (_horizScroller == nil)
			[self setHorizontalScroller:[[[NSScroller alloc] initWithFrame:NSZeroRect] autorelease]];
		[self addSubview:_horizScroller];
		}
	else
		[_horizScroller removeFromSuperviewWithoutNeedingDisplay];

	_hasHorizScroller = flag;
	[self tile];
}

- (void) setVerticalScroller:(NSScroller*)aScroller
{
	if(_vertScroller == aScroller)
		return;
	if(_vertScroller != nil)
		[_vertScroller removeFromSuperview];
	if ((_vertScroller = aScroller) != nil) 
		{
		[_vertScroller setTarget:self];
		[_vertScroller setAction:@selector(_doScroller:)];
		}
	else
		_hasVertScroller = NO; 
}

- (void) setHasVerticalScroller:(BOOL)flag
{
	if (_hasVertScroller == flag)
		return;
	if (flag) 
		{
		if (_vertScroller == nil)
			{ // create one if not yet
			[self setVerticalScroller:[[[NSScroller alloc] initWithFrame:NSZeroRect] autorelease]];
			if (_contentView && [self isFlipped] != [_contentView isFlipped])
				[_vertScroller setFloatValue:1];
			}
		[self addSubview:_vertScroller];
		}
	else
		[_vertScroller removeFromSuperviewWithoutNeedingDisplay];

	_hasVertScroller = flag;
	[self tile];
}

- (void) setAutohidesScrollers:(BOOL)flag; { _autohidesScrollers=flag; }
- (BOOL) autohidesScrollers; { return _autohidesScrollers; }
- (BOOL) drawsBackground;	{ return [_contentView drawsBackground]; }
- (void) setDrawsBackground:(BOOL) flag	
{
	if(!flag && [_contentView isKindOfClass:[NSClipView class]])
		[_contentView setCopiesOnScroll:NO];
}

- (void) scrollWheel:(NSEvent *)event
{
	if (_vertScroller)
		[_vertScroller _scrollWheel:event];
	else if (_horizScroller)
		[_horizScroller _scrollWheel:event];
}

- (void) _doScroller:(NSScroller *)scroller	// may be decoded as the NSScroller action from a NIB file - so, don't rename
{ // action method of NSScroller
	float amount=0.0;
	BOOL _knobMoved=NO;
	NSRect clipBounds = [_contentView bounds];
	NSScrollerPart hitPart = [scroller hitPart];
	NSRect documentRect = [_contentView documentRect];
	NSPoint p;

	NSDebugLog (@"_doScroller: float value = %f", floatValue);
	
	switch(hitPart)
		{
		case NSScrollerIncrementLine:
			amount = (scroller == _horizScroller)?_horizontalLineScroll:_verticalLineScroll;
			break;
		case NSScrollerIncrementPage:
			amount = (scroller == _horizScroller)?_horizontalPageScroll:_verticalPageScroll;
			break;
		case NSScrollerDecrementLine:
			amount = -((scroller == _horizScroller)?_horizontalLineScroll:_verticalLineScroll);
			break;
		case NSScrollerDecrementPage:
			amount = -((scroller == _horizScroller)?_horizontalPageScroll:_verticalPageScroll);
			break;
		default:
			_knobMoved = YES;	// still unknown
		}
	
	if (!_knobMoved)
		{ // button scrolling
		if (scroller == _horizScroller) 				
			p = (NSPoint){NSMinX(clipBounds) + amount, NSMinY(clipBounds)};
    	else 
			{
			if (scroller == _vertScroller) 				
				{										
     			p.x = clipBounds.origin.x;		
																			// If view is differently flipped 
				if ([self isFlipped] != [_contentView isFlipped])			// reverse the scroll 
					amount = -amount;										// direction 
      			NSDebugLog (@"increment/decrement: amount = %f, flipped = %d",
	     					 amount, [_contentView isFlipped]);
      			p.y = clipBounds.origin.y + amount;
	   			}
    		else 
     			return;										// do nothing
			}
  		}
  	else
		{ // knob scolling
		float floatValue = [scroller floatValue];
    	if (scroller == _horizScroller) 				
			{
     		p.x = floatValue * (NSWidth(documentRect) - NSWidth(clipBounds));
      		p.y = clipBounds.origin.y;
    		}
    	else if (scroller == _vertScroller) 
			{
			p.x = clipBounds.origin.x;
			if ([self isFlipped] != [_contentView isFlipped])
				floatValue = 1 - floatValue;	// differently flipped
			p.y = floatValue * (NSHeight(documentRect) - NSHeight(clipBounds));
			}
		else 
			return;										// do nothing if unknown scroller
		}
	
	[_contentView scrollPoint:p];						// scroll clipview
	if(_headerContentView)
		[_headerContentView scrollPoint:(NSPoint){p.x, 0}];
	if(!_knobMoved)
		[self reflectScrolledClipView:_contentView];
}

- (void) reflectScrolledClipView:(NSClipView*)aClipView
{
	NSRect documentFrame = NSZeroRect;
	NSRect clipViewBounds;
	float floatValue;
	float knobProportion;
	id documentView;
															// do nothing if 
	if(aClipView != _contentView)							// aClipView is not 
		return;												// our content view
#if 0
	NSLog(@"%@ reflectScrolledClipView:%@", self, aClipView);
#endif
	clipViewBounds = [_contentView bounds];
	if((documentView = [_contentView documentView]))
		documentFrame = [documentView frame];
	if(_hasVertScroller) 
		{
		if(_autohidesScrollers && documentFrame.size.height <= clipViewBounds.size.height)
			{
			if([_vertScroller isHidden])
				{
				[_vertScroller setHidden:YES];	// hide
				[self tile];
				}
			}
		else 
			{
			if([_vertScroller isHidden])
				{
				[_vertScroller setHidden:NO];	// show
				[self tile];
				}
			knobProportion = NSHeight(clipViewBounds) / NSHeight(documentFrame);
			floatValue = clipViewBounds.origin.y / (NSHeight(documentFrame) - NSHeight(clipViewBounds));	// scrolling moves bounds in negative direction!
//			if ([self isFlipped] != [_contentView isFlipped])
//				floatValue = 1 - floatValue;
			[_vertScroller setFloatValue:floatValue 
						   knobProportion:knobProportion];
			}
		}
	if(_hasHorizScroller) 
		{
		if(_autohidesScrollers && documentFrame.size.width <= clipViewBounds.size.width)
			{
			if(![_horizScroller isHidden])
				{
				[_horizScroller setHidden:YES];
				[self tile];
				}
			}
		else 
			{
			if([_horizScroller isHidden])
				{
				[_horizScroller setHidden:NO];	// show
				[self tile];
				}
      		knobProportion = NSWidth(clipViewBounds) / NSWidth(documentFrame);
      		floatValue = clipViewBounds.origin.x / (NSWidth(documentFrame) - NSWidth(clipViewBounds));
      		[_horizScroller setFloatValue:floatValue 
							knobProportion:knobProportion];
			}
		}
}

- (void) setHorizontalRulerView:(NSRulerView*)aRulerView			// FIX ME
{
	ASSIGN(_horizRuler, aRulerView);
}

- (void) setHasHorizontalRuler:(BOOL)flag						// FIX ME
{
	if (_hasHorizRuler == flag)
		return;

	_hasHorizRuler = flag;
}

- (void) setVerticalRulerView:(NSRulerView*)ruler				// FIX ME
{
	ASSIGN(_vertRuler, ruler);
}

- (void) setHasVerticalRuler:(BOOL)flag							// FIX ME
{
	if (_hasVertRuler == flag)
		return;

	_hasVertRuler = flag;
}

- (void) setRulersVisible:(BOOL)flag
{
	[_horizRuler setHidden:!flag];
	[_vertRuler setHidden:!flag];
}

- (void) setFrame:(NSRect)rect
{
	[super setFrame:rect];
	[self tile];
}

- (void) setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self tile];
}

- (void) tile
{ // calculate layout: scrollers on right or bottom - headerView on top of contentView - note that we have flipped coordinates!
	NSRect vertScrollerRect, horizScrollerRect, contentRect;
	float borderThickness=0;
	if(_prohibitTiling)
		return;	// temporarily disabled during initWithCoder:
#if 0
	NSLog(@"tile %@", self);
#endif
	// FIXME: we should also tile the RulerViews

	switch (_borderType) 
		{
		case NSNoBorder:		borderThickness = 0; 	break;
		case NSLineBorder:
		case NSBezelBorder:
		case NSGrooveBorder:	borderThickness = 1;	break;
 		}

	contentRect.origin = (NSPoint){ borderThickness, borderThickness };
	contentRect.size = [isa contentSizeForFrameSize:bounds.size
							  hasHorizontalScroller:NO
								hasVerticalScroller:NO
										 borderType:_borderType];	// default size without any scrollers
	if(_hasHorizScroller && _horizScroller && ![_horizScroller isHidden])
		{ // make room for the horiz. scroller at the bottom
		horizScrollerRect.size.height = [_horizScroller frame].size.height;	// adjust for scroller height
		contentRect.size.height -= horizScrollerRect.size.height;
		}
	if(_hasVertScroller && _vertScroller && ![_vertScroller isHidden])
		{ // make room on the right side
		contentRect.size.width -= [_vertScroller frame].size.width;	// adjust for scroller width
		vertScrollerRect.origin.x = NSMaxX(contentRect);		// to the right
		vertScrollerRect.origin.y = NSMinY(contentRect);
		vertScrollerRect.size.width = bounds.size.width - borderThickness - vertScrollerRect.origin.x;	// what remains
		vertScrollerRect.size.height = contentRect.size.height;	// same height
		}
	else
		vertScrollerRect=NSZeroRect;
	
	if(_hasHorizScroller)
		{
		horizScrollerRect.origin.x = NSMinX(contentRect);
		horizScrollerRect.origin.y = NSMaxY(contentRect) + borderThickness;	// position below
		horizScrollerRect.size.width = contentRect.size.width;
//		horizScrollerRect.size.height = horizScrollerRect.origin.y - contentRect.origin.y;	// what remains
		}
	
	if(_headerContentView)
		{ // make as wide as the content view - shrink content view and vertical scroller to make room for the corner view
		float h = NSHeight([_headerContentView frame]);
		NSRect headerRect, cornerRect;
		contentRect.size.height -= h;
		vertScrollerRect.size.height -= h;
		headerRect = NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), NSWidth(contentRect), h);
		contentRect.origin.y += h;	// move down
		vertScrollerRect.origin.y += h;	// move down
		[_headerContentView setFrame:headerRect];
		[_headerContentView setNeedsDisplay:YES];
		if(_cornerView)
			{ // adjust corner view
			cornerRect=NSMakeRect(NSMaxX(headerRect), NSMinY(headerRect), NSWidth(vertScrollerRect), h);
			[_cornerView setFrame:cornerRect];
			[_cornerView setNeedsDisplay:YES];
			}
		}
	[_contentView setFrame:contentRect];
	[_contentView setNeedsDisplay:YES];	// mark as dirty
	if(_hasHorizScroller && _horizScroller)
		{
		[_horizScroller setFrame:horizScrollerRect];
		[_horizScroller setNeedsDisplay:YES];
		}
	if(_hasVertScroller && _vertScroller)
		{
		[_vertScroller setFrame:vertScrollerRect];
		[_vertScroller setNeedsDisplay:YES];
		if ([self isFlipped] != [_contentView isFlipped])				// If the document view is not flipped reverse the meaning
			[_vertScroller setFloatValue:1];		// of the vertical scroller's
		}
}

- (void) drawRect:(NSRect)rect
{
	float borderThickness = 0;
#if 0
	NSLog(@"NSScrollView drawRect: %@", NSStringFromRect(rect));
#endif
	switch (_borderType) 
		{
		case NSLineBorder:
			{
				borderThickness = 1;
				NSFrameRect (rect);
				break;
			}
		case NSBezelBorder:
			{
				float grays[] = { NSWhite, NSWhite, NSDarkGray, NSDarkGray,
					NSLightGray, NSLightGray, NSBlack, NSBlack };
				
				NSDrawTiledRects(rect, rect, BEZEL_EDGES_NORMAL, grays, 8);
				borderThickness = 2;
				break;
			}
			
		case NSGrooveBorder:
			{
				NSRectEdge edges[] = {NSMinXEdge,NSMaxYEdge,NSMinXEdge,NSMaxYEdge, 
					NSMaxXEdge,NSMinYEdge,NSMaxXEdge,NSMinYEdge};
				float grays[] = { NSDarkGray, NSDarkGray, NSWhite, NSWhite,
					NSWhite, NSWhite, NSDarkGray, NSDarkGray };
				
				NSDrawTiledRects(rect, rect, edges, grays, 8);
				borderThickness = 2;
				break;
			}
			
		case NSNoBorder:
			break;
		}
	// headerView, cornerView and documentView are drawn as normal subviews (if available)
}

- (NSRect) documentVisibleRect
{
	return [_contentView documentVisibleRect];
}

- (void) setBackgroundColor:(NSColor*)aColor
{
	[_contentView setBackgroundColor:aColor];	// handle all background by clipview
}

- (void) setDocumentView:(NSView*)aView
{
#if 1
	NSLog(@"NSScrollView setDocumentView:%@ _contentView=%@", aView, _contentView);
#endif
	if([_contentView documentView] == aView)
		return;	// no change
	if(aView && [aView respondsToSelector:@selector(headerView)])
		{ // peek from document view (e.g. NSTableView)
		NSTableHeaderView *header = [(NSTableView*)aView headerView];
		if(header)
			{ // really provides a header view
			NSRect rect = {{0,0},[header frame].size};
			if(_headerContentView)
				[_headerContentView removeFromSuperviewWithoutNeedingDisplay];
			_headerContentView = [[NSClipView alloc] initWithFrame:rect];
			[_headerContentView setDocumentView:header];
			[self addSubview:_headerContentView];
			}
		}
	if(aView && [aView respondsToSelector:@selector(cornerView)])
		{ // peek from document view (e.g. NSTableView)
		if(_cornerView)
			[_cornerView removeFromSuperviewWithoutNeedingDisplay];
		_cornerView = [(NSTableView*)aView cornerView];
		if(_cornerView)
			[self addSubview:_cornerView];
		}
	[_contentView setDocumentView:aView];
	if(_contentView && [self isFlipped] != [_contentView isFlipped])
		[_vertScroller setFloatValue:1];
	[self tile];
	[self reflectScrolledClipView:(NSClipView*)_contentView];		// update scroller
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{
	NSDebugLog (@"NSScrollView	resizeSubviewsWithOldSize ");
	[super resizeSubviewsWithOldSize:oldSize];
	[self tile];
}

// experimental to handle new navigation ideas

- (NSView *) hitTest:(NSPoint)aPoint
{
	NSEvent *event=[NSApp currentEvent];
	if([event type] == NSLeftMouseDown && [event clickCount] == 2)
		{ // decode long press on second click
		NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:0.3];
		while(YES)
			{
			event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
									   untilDate:limit 
										  inMode:NSEventTrackingRunLoopMode
										 dequeue:NO];
			// if mouse moved but not very far away, continue loop
			break;
			}
		if(event == nil)
			{ // timed out before we got the next event
			_doubleLongClick=YES;
			NSLog(@"NSScrollView doubleLongClick");
			return self;
			}
		}
	_doubleLongClick=NO;
	return [super hitTest:aPoint];
}

- (void) _doubleLongClick:(NSEvent *) event;
{ // grab&drag
	NSPoint last = [self convertPoint:[event locationInWindow] fromView:nil];
	NSRect clipBounds = [_contentView bounds];
	NSTimeInterval lastTime = [event timestamp];
	[[NSCursor pointingHandCursor] push];
	while(YES)
		{
		int type=[event type];
		if(type == NSLeftMouseUp)	// loop until mouse goes up 
			break;
		if(type == NSLeftMouseDragged)
			{ // drag image
			NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
			NSTimeInterval thisTime = [event timestamp];
			NSTimeInterval deltaTime = thisTime-lastTime;
			NSSize velocity = (NSSize){ (p.x-last.x)/deltaTime, (p.y-last.y)/deltaTime };	// can be used to smooth movements or continue after mouse-up
			lastTime=thisTime;
#if 0
			NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
			clipBounds.origin.x -= p.x-last.x;
			clipBounds.origin.y -= p.y-last.y;
			[_contentView scrollPoint:clipBounds.origin];
			if(_headerContentView)
				[_headerContentView scrollPoint:(NSPoint){clipBounds.origin.x, 0}];
			[self reflectScrolledClipView:_contentView];
			last=p;
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
  		}
	[NSCursor pop];
}

- (void) mouseDown:(NSEvent *) event;
{
	if(_doubleLongClick)
		{
		[self _doubleLongClick:event];
		_doubleLongClick=NO;	// has been recognized as such
		}
	else
		[super mouseDown:event];
}

- (NSColor *) backgroundColor		{ return [_contentView backgroundColor]; }
- (NSSize) contentSize				{ return [_contentView bounds].size; }
- (NSClipView *) contentView		{ return _contentView; }
- (id) documentView					{ return [_contentView documentView]; }
- (NSCursor *) documentCursor		{ return [_contentView documentCursor]; }

- (void) setDocumentCursor:(NSCursor*)aCursor
{
	[_contentView setDocumentCursor:aCursor];
}

- (void) setBorderType:(NSBorderType)type			{ _borderType = type; }
- (NSBorderType) borderType							{ return _borderType; }
- (NSScroller*) horizontalScroller					{ return _horizScroller; }
- (NSScroller*) verticalScroller					{ return _vertScroller; }
- (BOOL) hasVerticalScroller						{ return _hasVertScroller; }
- (BOOL) hasHorizontalScroller						{ return _hasHorizScroller; }
- (BOOL) hasHorizontalRuler							{ return _hasHorizRuler; }
- (BOOL) hasVerticalRuler							{ return _hasVertRuler; }
- (BOOL) rulersVisible								{ return _horizRuler && ![_horizRuler isHidden]; }
- (NSRulerView*) horizontalRulerView				{ return _horizRuler; }
- (NSRulerView*) verticalRulerView					{ return _vertRuler; }
- (void) setHorizontalLineScroll:(float)aFloat		{ _horizontalLineScroll = aFloat; }
- (void) setHorizontalPageScroll:(float)aFloat		{ _horizontalPageScroll = aFloat; }
- (void) setVerticalLineScroll:(float)aFloat		{ _verticalLineScroll = aFloat; }
- (void) setVerticalPageScroll:(float)aFloat		{ _verticalPageScroll = aFloat; }
- (void) setLineScroll:(float)aFloat				{ [self setHorizontalLineScroll:aFloat]; [self setVerticalLineScroll:aFloat]; }	// doc says we call these methods
- (void) setPageScroll:(float)aFloat				{ [self setHorizontalPageScroll:aFloat]; [self setVerticalPageScroll:aFloat]; }
- (float) horizontalPageScroll						{ return _horizontalPageScroll; }
- (float) horizontalLineScroll						{ return _horizontalLineScroll; }
- (float) verticalPageScroll						{ return _verticalPageScroll; }
- (float) verticalLineScroll						{ return _verticalLineScroll; }
- (float) pageScroll								{ return [self verticalPageScroll]; }
- (float) lineScroll								{ return [self verticalLineScroll]; }
- (void) setScrollsDynamically:(BOOL)flag			{ _scrollsDynamically = flag; }
- (BOOL) scrollsDynamically							{ return _scrollsDynamically; }
- (BOOL) isOpaque									{ return YES; }
- (BOOL) isFlipped									{ return YES; }	// compatibility

- (void) mouseUp:(NSEvent *)event					// called when mouse goes
{													// up in scroller.
	if(_headerContentView)
	   [window invalidateCursorRectsForView:[_headerContentView documentView]];
}													

- (void) encodeWithCoder: (NSCoder *)aCoder			// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
	_prohibitTiling=YES;
	self=[super initWithCoder:aDecoder];	// will call initWithFrame
	if([aDecoder allowsKeyedCoding])
		{
		int sFlags=[aDecoder decodeInt32ForKey:@"NSsFlags"];
		_horizScroller=[[aDecoder decodeObjectForKey:@"NSHScroller"] retain];
		_vertScroller=[[aDecoder decodeObjectForKey:@"NSVScroller"] retain];
#define BORDERTYPE			((sFlags&0x0003) >> 0)
		_borderType=BORDERTYPE;
#define VSCROLLER			((sFlags&0x0010) != 0)
		[self setHasVerticalScroller:VSCROLLER];
#define HSCROLLER			((sFlags&0x0020) != 0)
		[self setHasHorizontalScroller:HSCROLLER];
#define AUTOHIDE			((sFlags&0x0200) != 0)
		_autohidesScrollers=AUTOHIDE;
#if 0
		NSLog(@"%@ initWithCoder:%@ sFlags=%08x", self, aDecoder, sFlags);
#endif
		_cornerView=[[aDecoder decodeObjectForKey:@"NSCornerView"] retain];	// if we have one...
		_headerContentView=[[aDecoder decodeObjectForKey:@"NSHeaderClipView"] retain];	// if we have one...
#if 0
		NSLog(@"corner view=%@", [_cornerView _descriptionWithSubviews]);			// not embedded in a NSClipView
		NSLog(@"header view=%@", [_headerContentView _descriptionWithSubviews]);	// this is a NSClipView which embeds the real header view
#endif
		if([aDecoder containsValueForKey:@"NSScrollAmts"])
			{
			struct _AMTS { NSSwappedFloat hline, vline, hpage, vpage; } *amts;
			unsigned len=0;
			amts=(struct _AMTS *) [aDecoder decodeBytesForKey:@"NSScrollAmts" returnedLength:&len];
			if(len != sizeof(*amts))
				NSLog(@"scroll amts=%p[%u]", amts, len);
			else
				{ // byte swap from bigendian to host byte order
#if 0
				_horizontalLineScroll=NSSwapBigFloatToHost(amts->hline);
				_verticalLineScroll=NSSwapBigFloatToHost(amts->vline);
				_horizontalPageScroll=NSSwapBigFloatToHost(amts->hpage);
				_verticalPageScroll=NSSwapBigFloatToHost(amts->vpage);
#endif
				}
			}
//		[self setContentView:[aDecoder decodeObjectForKey:@"NSContentView"]];
		_contentView = [[aDecoder decodeObjectForKey:@"NSContentView"] retain];		// should load content and document view
		[self setDrawsBackground:[aDecoder decodeBoolForKey:@"NSDrawsBackground"]];	// CHECKME: is this a property of the scrollview or the content view?
#if 0
		NSLog(@"%@ initWithCoder:%@ sFlags=%08x", self, aDecoder, sFlags);
#endif
		}
	_prohibitTiling=NO;
	[self tile];	// finally tile (!may fail to properly handle scrollers because they are not yet linked as subviews!)
	return self;
}

@end /* NSScrollView */
