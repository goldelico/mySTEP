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

	switch (borderType) {
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

	switch (borderType) {
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
		[self setContentView:[[[NSClipView alloc] initWithFrame:rect] autorelease]];	// install default content view
		[self setLineScroll:10];
		[self setPageScroll:40];
		_sv.borderType = NSBezelBorder;
		_sv.scrollsDynamically = YES;
		// FIXME: register for user defaults change notifications and tile if needed (e.g. the scroller position has changed)
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
		_sv.hasHorizScroller = NO;
}

- (void) setHasHorizontalScroller:(BOOL)flag
{
	if (_sv.hasHorizScroller == flag)
		return;
	if (flag)
		{
		if (_horizScroller == nil)
			[self setHorizontalScroller:[[[NSScroller alloc] initWithFrame:NSZeroRect] autorelease]];
		[_horizScroller setControlSize:NSRegularControlSize];
		[self addSubview:_horizScroller];
		}
	else
		[_horizScroller removeFromSuperviewWithoutNeedingDisplay];

	_sv.hasHorizScroller = flag;
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
		_sv.hasVertScroller = NO;
}

- (void) setHasVerticalScroller:(BOOL)flag
{
	if (_sv.hasVertScroller == flag)
		return;
	if (flag)
		{
		if (_vertScroller == nil)
			{ // create one if not yet
				[self setVerticalScroller:[[[NSScroller alloc] initWithFrame:NSZeroRect ] autorelease]];
				[_vertScroller setControlSize:NSRegularControlSize];
				if (_contentView && [self isFlipped] != [_contentView isFlipped])
					[_vertScroller setFloatValue:1];
			}
		[self addSubview:_vertScroller];
		}
	else
		[_vertScroller removeFromSuperviewWithoutNeedingDisplay];

	_sv.hasVertScroller = flag;
	[self tile];
}

- (void) setAutohidesScrollers:(BOOL)flag; { _sv.autohidesScrollers=flag; }
- (BOOL) autohidesScrollers; { return _sv.autohidesScrollers; }
- (BOOL) drawsBackground;	{ return [_contentView drawsBackground]; }

- (void) setDrawsBackground:(BOOL) flag
{
	[_contentView setDrawsBackground:flag];
	if(!flag && [_contentView respondsToSelector:@selector(setCopiesOnScroll:)])
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
	CGFloat amount=0.0;
	BOOL _knobMoved=NO;
	NSRect clipBounds = [_contentView bounds];
	NSScrollerPart hitPart = [scroller hitPart];
	NSRect documentRect = [_contentView documentRect];
	NSPoint p;

	NSDebugLog (@"_doScroller: float value = %f", floatValue);

	switch(hitPart) {
		case NSScrollerIncrementLine:
			amount = (scroller == _horizScroller)?_horizontalLineScroll:_verticalLineScroll;
			break;
		case NSScrollerIncrementPage:
			// FIXME: this amount is the delta to a full page - i.e. ask the contentView for a page height
			amount = (scroller == _horizScroller)?_horizontalPageScroll:_verticalPageScroll;
			break;
		case NSScrollerDecrementLine:
			amount = -((scroller == _horizScroller)?_horizontalLineScroll:_verticalLineScroll);
			break;
		case NSScrollerDecrementPage:
			// FIXME: this amount is the delta to a full page - i.e. ask the contentView for a page height
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
			CGFloat floatValue = [scroller floatValue];
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

	[_contentView scrollToPoint:p];						// scroll clipview
	if(_headerContentView)
		[_headerContentView scrollToPoint:(NSPoint){p.x, 0}];
	if(!_knobMoved)
		[self reflectScrolledClipView:_contentView];
}

- (void) reflectScrolledClipView:(NSClipView*)aClipView
{
	NSRect documentFrame = NSZeroRect;
	NSRect clipViewBounds;
	CGFloat floatValue;
	CGFloat knobProportion;
	id documentView;
	BOOL hide;
	if(_sv.autohidingScrollers)
		return;	// recursive call
	if(aClipView != _contentView)	// do nothing if aClipView is not our content view
		return;
#if 0
	NSLog(@"reflectScrolledClipView: %@", self);
#endif
	clipViewBounds = [_contentView bounds];
	if((documentView = [_contentView documentView]))
		documentFrame = [documentView frame];
#if 0
	NSLog(@"  clipView %@", aClipView);
	NSLog(@"  documentView %@", documentView);
#endif
	if(_sv.hasVertScroller)
		{
		hide = (_sv.autohidesScrollers && documentFrame.size.height <= clipViewBounds.size.height);
		if([_vertScroller isHidden] != hide)
			{ // needs to change
#if 0
				NSLog(@"vertScroller hidden: %d", hide);
#endif
				[_vertScroller setHidden:hide];
				_sv.autohidingScrollers=YES;
				[self tile];	// this will recurse!
			}
		if(!hide)
			{ // update scroller size
				knobProportion = NSHeight(clipViewBounds) / NSHeight(documentFrame);
				floatValue = clipViewBounds.origin.y / (NSHeight(documentFrame) - NSHeight(clipViewBounds));	// scrolling moves bounds in negative direction!
																												//			if ([self isFlipped] != [_contentView isFlipped])
																												//				floatValue = 1 - floatValue;
				[_vertScroller setFloatValue:floatValue];
				[_vertScroller setKnobProportion:knobProportion];
			}
		}
	if(_sv.hasHorizScroller)
		{
		hide = (_sv.autohidesScrollers && documentFrame.size.width <= clipViewBounds.size.width);
		if([_horizScroller isHidden] != hide)
			{ // needs to change
#if 0
				NSLog(@"horizScroller hidden: %d", hide);
#endif
				[_horizScroller setHidden:hide];
				_sv.autohidingScrollers=YES;
				[self tile];	// this may recurse!
			}
		if(!hide)
			{ // update scroller size
				knobProportion = NSWidth(clipViewBounds) / NSWidth(documentFrame);
				floatValue = clipViewBounds.origin.x / (NSWidth(documentFrame) - NSWidth(clipViewBounds));
				[_horizScroller setFloatValue:floatValue];
				[_horizScroller setKnobProportion:knobProportion];
			}
		}
	_sv.autohidingScrollers=NO;
}

- (void) setHorizontalRulerView:(NSRulerView*)aRulerView			// FIX ME
{
	ASSIGN(_horizRuler, aRulerView);
}

- (void) setHasHorizontalRuler:(BOOL)flag						// FIX ME
{
	if (_sv.hasHorizRuler == flag)
		return;
	_sv.hasHorizRuler = flag;
}

- (void) setVerticalRulerView:(NSRulerView*)ruler				// FIX ME
{
	ASSIGN(_vertRuler, ruler);
}

- (void) setHasVerticalRuler:(BOOL)flag							// FIX ME
{
	if (_sv.hasVertRuler == flag)
		return;
	_sv.hasVertRuler = flag;
}

- (void) setRulersVisible:(BOOL)flag
{
	[_horizRuler setHidden:!flag];
	[_vertRuler setHidden:!flag];
}

- (void) tile
{ // calculate layout: scrollers on right or bottom - headerView on top of contentView - note that we have flipped coordinates!
	NSRect vertScrollerRect, horizScrollerRect, contentRect;
	CGFloat borderThickness=0;
	if(!_contentView || !_window || !_superview)
		{ // no need to tile now
#if 0
			NSLog(@"tiling without window or superview %@", self);
#endif
			return;
		}
#if 0
	NSLog(@"tile %@", self);
#endif
	// FIXME: we should also tile the RulerViews
	switch (_sv.borderType) {
		case NSNoBorder:		borderThickness = 0; 	break;
		case NSLineBorder:
		case NSBezelBorder:
		case NSGrooveBorder:	borderThickness = 1;	break;
	}

	contentRect.origin = (NSPoint){ borderThickness, borderThickness };
	contentRect.size = [[self class] contentSizeForFrameSize:_bounds.size
									   hasHorizontalScroller:NO
										 hasVerticalScroller:NO
												  borderType:_sv.borderType];	// default size without any scrollers
	horizScrollerRect=NSZeroRect;
	vertScrollerRect=NSZeroRect;
	if(_sv.hasHorizScroller && _horizScroller && ![_horizScroller isHidden])
		{ // make room for the horiz. scroller at the bottom
			CGFloat height=[_horizScroller frame].size.height;
			if(height < 1.0)
				height=[NSScroller scrollerWidthForControlSize:[_horizScroller controlSize]];
			horizScrollerRect.size.height = height;	// adjust for scroller height
			contentRect.size.height -= horizScrollerRect.size.height;
		}
	if(_sv.hasVertScroller && _vertScroller && ![_vertScroller isHidden])
		{ // make room on the right or left side
			BOOL scrollerLeftPosition=[[[NSUserDefaults standardUserDefaults] stringForKey:@"NSScrollerPosition"] isEqualToString:@"left"];
			CGFloat width=[_vertScroller frame].size.width;
			if(width < 1.0)
				width=[NSScroller scrollerWidthForControlSize:[_vertScroller controlSize]];
			contentRect.size.width -= width;	// adjust for scroller width
			vertScrollerRect.origin.x = NSMaxX(contentRect);		// to the right
			vertScrollerRect.origin.y = NSMinY(contentRect);
			vertScrollerRect.size.width = _bounds.size.width - borderThickness - vertScrollerRect.origin.x;	// what remains
			vertScrollerRect.size.height = contentRect.size.height;	// same height
			if(scrollerLeftPosition)
				{ // move vertical scrollers to the left side
					contentRect.origin.x += vertScrollerRect.size.width;
					vertScrollerRect.origin.x = 0.0;	// to the left
				}
		}

	if(_sv.hasHorizScroller)
		{
		horizScrollerRect.origin.x = NSMinX(contentRect);
		horizScrollerRect.origin.y = NSMaxY(contentRect) + borderThickness;	// position below
		horizScrollerRect.size.width = contentRect.size.width;
		//		horizScrollerRect.size.height = horizScrollerRect.origin.y - contentRect.origin.y;	// what remains
		}

	if(_headerContentView)
		{ // make as wide as the content view - shrink content view and vertical scroller to make room for the corner view
			CGFloat h = NSHeight([_headerContentView frame]);
			NSRect headerRect, cornerRect;
			contentRect.size.height -= h;	// reduce height
			vertScrollerRect.size.height -= h;	// reduce height
			headerRect = NSMakeRect(NSMinX(contentRect), NSMinY(contentRect), NSWidth(contentRect), h);
			contentRect.origin.y += h;	// move down
			vertScrollerRect.origin.y += h;	// move down
			if(_headerContentView && !NSEqualRects([_headerContentView frame], headerRect))
				[_headerContentView setFrame:headerRect];
			[_headerContentView setNeedsDisplay:YES];
			if(_cornerView)
				{ // adjust corner view to be above the vertical scroller
					cornerRect=NSMakeRect(NSMinX(vertScrollerRect), NSMinY(vertScrollerRect), NSWidth(vertScrollerRect), h);	// may result in zero size
					if(!NSEqualRects([_cornerView frame], cornerRect))
						[_cornerView setFrame:cornerRect];
					[_cornerView setNeedsDisplay:YES];
				}
		}
	if(_sv.hasHorizScroller && _horizScroller && !NSEqualRects([_horizScroller frame], horizScrollerRect))
		{
		[_horizScroller setFrame:horizScrollerRect];
		[_horizScroller setNeedsDisplay:YES];
		}
	if(_sv.hasVertScroller && _vertScroller && !NSEqualRects([_vertScroller frame], vertScrollerRect))
		{
		[_vertScroller setFrame:vertScrollerRect];
		[_vertScroller setNeedsDisplay:YES];
		}
#if 0
	NSLog(@"resizing contentView to frame %@", NSStringFromRect(contentRect));
#endif
	if(!NSEqualRects([_contentView frame], contentRect))
		[_contentView setFrame:contentRect];	// this may recurse if scrollers are auto-hidden/unhidden
	[_contentView setNeedsDisplay:YES];		// mark as dirty
}

- (void) viewDidMoveToWindow;		{ [self tile]; }
- (void) viewDidMoveToSuperView;	{ [self tile]; }

- (void) drawRect:(NSRect)rect
{
	CGFloat borderThickness = 0;
#if 0
	NSLog(@"NSScrollView drawRect: %@", NSStringFromRect(rect));
#endif
	switch (_sv.borderType) {
			// FIXME: this does not match tiling calculations and visual expectations
		case NSLineBorder: {
			borderThickness = 1;
			NSFrameRect (rect);
			break;
		}
		case NSBezelBorder: {
			CGFloat grays[] = { NSWhite, NSWhite, NSDarkGray, NSDarkGray,
				NSLightGray, NSLightGray, NSBlack, NSBlack };

			NSDrawTiledRects(rect, rect, BEZEL_EDGES_NORMAL, grays, 8);
			borderThickness = 2;
			break;
		}

		case NSGrooveBorder: {
			NSRectEdge edges[] = {NSMinXEdge,NSMaxYEdge,NSMinXEdge,NSMaxYEdge,
				NSMaxXEdge,NSMinYEdge,NSMaxXEdge,NSMinYEdge};
			CGFloat grays[] = { NSDarkGray, NSDarkGray, NSWhite, NSWhite,
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
#if 0
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

- (void) setFrame:(NSRect) rect
{
	NSDebugLog (@"NSScrollView	setFrame ");
	if(NSEqualRects(rect, _frame))
		return;	// ignore unchanged frame
	if(NSEqualPoints(rect.origin, _frame.origin))
		{
		[super setFrame:rect];	// will call our setFrameSize method an tile
		return;
		}
	[super setFrame:rect];
	[self tile];	// this will setFrame for all our subviews
}

- (void) setFrameSize:(NSSize) size
{
	NSDebugLog (@"NSScrollView	setFrameSize ");
	if(NSEqualSizes(size, _frame.size))
		return;	// ignore unchanged size
	[super setFrameSize:size];
	[self tile];	// this will setFrame for all our subviews
}

- (void) resizeSubviewsWithOldSize:(NSSize) size
{
	NSDebugLog (@"NSScrollView	resizeSubviewsWithOldSize ");
	if(NSEqualSizes(size, _frame.size))
		return;	// ignore unchanged size
	[self tile];	// this will setFrame for all our subviews
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
					_sv.doubleLongClick=YES;
					NSLog(@"NSScrollView doubleLongClick");
					return self;
				}
		}
	_sv.doubleLongClick=NO;
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
				[_contentView scrollToPoint:clipBounds.origin];
				if(_headerContentView)
					[_headerContentView scrollToPoint:(NSPoint){clipBounds.origin.x, 0}];
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
	if(_sv.doubleLongClick)
		{
		[self _doubleLongClick:event];
		_sv.doubleLongClick=NO;	// has been recognized as such
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

- (void) setBorderType:(NSBorderType)type			{ _sv.borderType = type; }
- (NSBorderType) borderType							{ return _sv.borderType; }
- (NSScroller*) horizontalScroller					{ return _horizScroller; }
- (NSScroller*) verticalScroller					{ return _vertScroller; }
- (BOOL) hasVerticalScroller						{ return _sv.hasVertScroller; }
- (BOOL) hasHorizontalScroller						{ return _sv.hasHorizScroller; }
- (BOOL) hasHorizontalRuler							{ return _sv.hasHorizRuler; }
- (BOOL) hasVerticalRuler							{ return _sv.hasVertRuler; }
- (BOOL) rulersVisible								{ return _horizRuler && ![_horizRuler isHidden]; }
- (NSRulerView*) horizontalRulerView				{ return _horizRuler; }
- (NSRulerView*) verticalRulerView					{ return _vertRuler; }
- (void) setHorizontalLineScroll:(CGFloat)aFloat	{ _horizontalLineScroll = aFloat; }
- (void) setHorizontalPageScroll:(CGFloat)aFloat	{ _horizontalPageScroll = aFloat; }
- (void) setVerticalLineScroll:(CGFloat)aFloat		{ _verticalLineScroll = aFloat; }
- (void) setVerticalPageScroll:(CGFloat)aFloat		{ _verticalPageScroll = aFloat; }
- (void) setLineScroll:(CGFloat)aFloat				{ [self setHorizontalLineScroll:aFloat]; [self setVerticalLineScroll:aFloat]; }	// doc says we call these methods
- (void) setPageScroll:(CGFloat)aFloat				{ [self setHorizontalPageScroll:aFloat]; [self setVerticalPageScroll:aFloat]; }
- (CGFloat) horizontalPageScroll					{ return _horizontalPageScroll; }
- (CGFloat) horizontalLineScroll					{ return _horizontalLineScroll; }
- (CGFloat) verticalPageScroll						{ return _verticalPageScroll; }
- (CGFloat) verticalLineScroll						{ return _verticalLineScroll; }
- (CGFloat) pageScroll								{ return [self verticalPageScroll]; }
- (CGFloat) lineScroll								{ return [self verticalLineScroll]; }
- (void) setScrollsDynamically:(BOOL)flag			{ _sv.scrollsDynamically = flag; }
- (BOOL) scrollsDynamically							{ return _sv.scrollsDynamically; }
- (BOOL) isOpaque									{ return YES; }
- (BOOL) isFlipped									{ return YES; }	// compatibility

- (void) mouseUp:(NSEvent *)event					// called when mouse goes
{													// up in scroller.
	if(_headerContentView)
		[_window invalidateCursorRectsForView:[_headerContentView documentView]];
}

- (void) encodeWithCoder: (NSCoder *)aCoder			// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder: (NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];	// will call initWithFrame
	if([aDecoder allowsKeyedCoding])
		{
		int sFlags=[aDecoder decodeInt32ForKey:@"NSsFlags"];
		_horizScroller=[[aDecoder decodeObjectForKey:@"NSHScroller"] retain];
		_vertScroller=[[aDecoder decodeObjectForKey:@"NSVScroller"] retain];
#define BORDERTYPE			((sFlags&0x0003) >> 0)
		_sv.borderType=BORDERTYPE;
#define VSCROLLER			((sFlags&0x0010) != 0)
		[self setHasVerticalScroller:VSCROLLER];
#define HSCROLLER			((sFlags&0x0020) != 0)
		[self setHasHorizontalScroller:HSCROLLER];
#define AUTOHIDE			((sFlags&0x0200) != 0)
		_sv.autohidesScrollers=AUTOHIDE;
#if 0
		NSLog(@"%@ initWithCoder:%@ sFlags=%08x", self, aDecoder, sFlags);
#endif
		_cornerView=[[aDecoder decodeObjectForKey:@"NSCornerView"] retain];	// if we have one...
		_headerContentView=[[aDecoder decodeObjectForKey:@"NSHeaderClipView"] retain];	// if we have one...
#if 0
		NSLog(@"corner view=%@", [_cornerView _subtreeDescription]);			// not embedded in a NSClipView
		NSLog(@"header view=%@", [_headerContentView _subtreeDescription]);	// this is a NSClipView which embeds the real header view
#endif
		if([aDecoder containsValueForKey:@"NSScrollAmts"])
			{
			struct _AMTS { NSSwappedFloat hline, vline, hpage, vpage; } *amts;
			NSUInteger len=0;
			amts=(struct _AMTS *) [aDecoder decodeBytesForKey:@"NSScrollAmts" returnedLength:&len];
			if(len != sizeof(*amts))
				NSLog(@"scroll amts=%p[%lu]", amts, (unsigned long)len);
			else
				{ // byte swap from bigendian to host byte order // FIXME: really?
#if 0
					_horizontalLineScroll=NSSwapBigFloatToHost(amts->hline);
					_verticalLineScroll=NSSwapBigFloatToHost(amts->vline);
					_horizontalPageScroll=NSSwapBigFloatToHost(amts->hpage);
					_verticalPageScroll=NSSwapBigFloatToHost(amts->vpage);
#endif
				}
			}
		[self setContentView:[aDecoder decodeObjectForKey:@"NSContentView"]];
		//		_contentView = [[aDecoder decodeObjectForKey:@"NSContentView"] retain];		// should load content and document view
		if([aDecoder containsValueForKey:@"NSDrawsBackground"])
			[self setDrawsBackground:[aDecoder decodeBoolForKey:@"NSDrawsBackground"]];	// CHECKME: is this a property of the scrollview or the content view?
		[aDecoder decodeDoubleForKey:@"NSMaxMagnification"];
		[aDecoder decodeDoubleForKey:@"NSMinMagnification"];
		[aDecoder decodeDoubleForKey:@"NSMagnification"];
#if 0
		NSLog(@"%@ initWithCoder:%@ sFlags=%08x", self, aDecoder, sFlags);
#endif
		}
	return self;
}

@end /* NSScrollView */
