/*
   NSScroller.m

   Control with which to scroll another

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSDate.h>
#import <Foundation/NSRunLoop.h>

#import <AppKit/NSScroller.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSScrollView.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

// Class variables 
static NSButtonCell *__upCell = nil;					// class button cells  
static NSButtonCell *__downCell = nil;					// used by scroller 
static NSButtonCell *__leftCell = nil;					// instances to draw 
static NSButtonCell *__rightCell = nil;					// buttons and knob.
static NSActionCell *__knobCell = nil;

@interface _NSScrollerButtonCell : NSButtonCell
@end

@implementation _NSScrollerButtonCell

- (void) drawBezelWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
{
	[(_c.highlighted ? [NSColor selectedControlColor] : [NSColor controlColor]) set];
	NSRectFill(cellFrame);
}

@end

@interface _NSKnobCell : NSActionCell
@end

@implementation _NSKnobCell

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSBezierPath *p=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:cellFrame.size.width < cellFrame.size.height];	// box with halfcircular rounded ends
	NSWindow *win=[controlView window];
	if([win isKeyWindow] || [win isKindOfClass:[NSPanel class]])
		[[NSColor selectedControlColor] setFill];
	else
		[[NSColor lightGrayColor] setFill];	// dim if it is not the key window
	[p fill];		// fill with color
}

@end

@implementation NSScroller

+ (CGFloat) scrollerWidth
{
	return 18.0;	// system constant
}

+ (CGFloat) scrollerWidthForControlSize:(NSControlSize) size;
{
	switch(size)
		{
		default:	return [self scrollerWidth];
		case NSSmallControlSize: return 15.0;
		case NSMiniControlSize: return 11.0;
		}
}

- (BOOL) isFlipped; { return YES; }	// compatibility - i.e. floatValue 0.0 is at top and 0.0 y coord.

- (id) initWithFrame:(NSRect)frameRect
{
#if 0
	NSLog(@"[NSScroller initWithFrame:%@]", NSStringFromRect(frameRect));
#endif
	if((self=[super initWithFrame:frameRect]))
		{
		_isEnabled=YES;
		_isHorizontal = frameRect.size.width > frameRect.size.height;
		_arrowsPosition=_isHorizontal?NSScrollerArrowsMinEnd:NSScrollerArrowsMaxEnd;
		_hitPart = NSScrollerNoPart;
		_knobProportion = 0.3;
		[self drawParts];
		[self checkSpaceForParts];
		// FIXME: register for user defaults change notifications and redraw if needed
		}
	return self;
}

- (NSScrollArrowPosition) arrowsPosition	{ return _arrowsPosition; }
- (NSUsableScrollerParts) usableParts		{ return _usableParts; }
- (CGFloat) knobProportion					{ return _knobProportion; }
- (float) floatValue						{ return _floatValue; }
- (double) doubleValue						{ return _floatValue; }
- (NSScrollerPart) hitPart					{ return _hitPart; }

- (void) encodeWithCoder:(NSCoder *) aCoder				{ NIMP; }

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		long sflags=[aDecoder decodeInt32ForKey:@"NSsFlags"];
		long sflags2=[aDecoder decodeInt32ForKey:@"NSsFlags2"];
#define CONTROLSIZE ((sflags2>>26)&3)
		_controlSize=CONTROLSIZE;
#define HORIZONTAL ((sflags>>31)&1)
		_isHorizontal=HORIZONTAL;
		[self checkSpaceForParts];		// may have changed
#define ARROWSPOSITION ((sflags>>29)&3)
		[self setArrowsPosition:ARROWSPOSITION];	// this may apply defaults
#define USABLEPARTS ((sflags>>27)&3)
		_usableParts=USABLEPARTS;
#define CONTROLTINT ((sflags>>16)&7)
		_controlTint=CONTROLTINT;
		[self setFloatValue:[aDecoder decodeFloatForKey:@"NSCurValue"] knobProportion:[aDecoder decodeFloatForKey:@"NSPercent"]/100.0];
		[aDecoder decodeObjectForKey:@"NSControlTarget"];
		[aDecoder decodeObjectForKey:@"NSControlAction"];	// selector as string?
		_hitPart = NSScrollerNoPart;
		[self setEnabled:YES];
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder);
#endif
		return self;
		}
	return NIMP;
}

- (BOOL) isOpaque							{ return YES; }
- (BOOL) acceptsFirstMouse:(NSEvent*)event	{ return YES; }
- (SEL) action								{ return _action; }
- (id) target								{ return _target; }
- (void) setAction:(SEL)action				{ _action = action; }
- (void) setTarget:(id)target				{ _target = target; }	// not retained!

- (void) drawParts
{ // Create the class variable button cells if they do not yet exist.
	if (__knobCell)  
		return; 
	
	__upCell = [_NSScrollerButtonCell new];
	[__upCell setControlSize:NSMiniControlSize];	// automatic scaling of image
	[__upCell setButtonType:NSMomentaryLightButton];	// ???
	[__upCell setBordered:YES];
//	[__upCell setBezeled:NO];
	[__upCell setBezelStyle:NSRegularSquareBezelStyle];
	[__upCell setFocusRingType:NSFocusRingTypeNone];
	[__upCell setHighlightsBy:NSContentsCellMask];	// no PushIn effect - just swap images
	[__upCell setImagePosition:NSImageOnly];
	[__upCell setImageScaling:NSImageScaleProportionallyUpOrDown];
	[__upCell setImageDimsWhenDisabled:YES];
	[__upCell setShowsFirstResponder:NO];
	[__upCell setContinuous:YES];
	[__upCell setPeriodicDelay:0.15 interval:0.05];	// for autorepeat
	__downCell = [__upCell copy];
	__leftCell = [__upCell copy];
	__rightCell = [__upCell copy];

	[__upCell setImage:[NSImage imageNamed:@"GSArrowUp"]];
//	[[__upCell image] setScalesWhenResized:YES];
	[__upCell setAlternateImage:[NSImage imageNamed:@"GSArrowUpH"]];
//	[[__upCell alternateImage] setScalesWhenResized:YES];
	[__downCell setImage:[NSImage imageNamed:@"GSArrowDown"]];
//	[[__downCell image] setScalesWhenResized:YES];
	[__downCell setAlternateImage:[NSImage imageNamed:@"GSArrowDownH"]];
//	[[__downCell alternateImage] setScalesWhenResized:YES];
	[__leftCell setImage:[NSImage imageNamed:@"GSArrowLeft"]];
//	[[__leftCell image] setScalesWhenResized:YES];
	[__leftCell setAlternateImage:[NSImage imageNamed:@"GSArrowLeftH"]];
//	[[__leftCell alternateImage] setScalesWhenResized:YES];
	[__rightCell setImage:[NSImage imageNamed:@"GSArrowRight"]];
//	[[__rightCell image] setScalesWhenResized:YES];
	[__rightCell setAlternateImage:[NSImage imageNamed:@"GSArrowRightH"]];
//	[[__rightCell alternateImage] setScalesWhenResized:YES];

	__knobCell = [_NSKnobCell new];
}

- (void) checkSpaceForParts
{
	NSSize frameSize = [self frame].size;
	CGFloat size = (_isHorizontal ? frameSize.width : frameSize.height);
	CGFloat scrollerWidth = (_isHorizontal ? frameSize.height : frameSize.width);

	if(size > 3 * scrollerWidth + 2)
		_usableParts = NSAllScrollerParts;
	else if (size > 2 * scrollerWidth + 1)
		_usableParts = NSOnlyScrollerArrows;
	else if (size > scrollerWidth)
		_usableParts = NSNoScrollerParts;
}

- (void) setEnabled:(BOOL)flag
{
	if(_isEnabled == flag)
		return;
	_isEnabled = flag;
	[self setNeedsDisplay:YES];
}

- (void) setArrowsPosition:(NSScrollArrowPosition)where
{
	if(where == NSScrollerArrowsDefaultSetting)
		{
		NSString *str=[[NSUserDefaults standardUserDefaults] stringForKey:@"AppleScrollBarVariant"];
		if([str isEqualToString:@"DoubleMax"])
			where=NSScrollerArrowsMaxEnd;	// there is no NSScrollerArrowsDoubleMaxEnd
		else if([str isEqualToString:@"Single"])
			where=NSScrollerArrowsMinEnd;
		}
	if(_arrowsPosition == where)
		return;
	_arrowsPosition = where;
	[self setNeedsDisplay:YES];
}

- (void) setDoubleValue:(double)aFloat
{
	aFloat = MIN(MAX(aFloat, 0), 1);
	if(_floatValue == aFloat)
		return;	// no change
	_floatValue=aFloat;
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"AppleScrollAnimationEnabled"])
		{ // smooth scroll
		}
	// fixme: redraw union of old and new NSScrollerKnob
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) setFloatValue:(float)aFloat
{
	[self setDoubleValue:aFloat];
}

- (void) setKnobProportion:(CGFloat)ratio;
{
	ratio=MIN(MAX(ratio, 0), 1);
	if(_knobProportion != ratio)
		{
		_knobProportion = ratio;
		[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
		}
}

- (void) setFloatValue:(float)aFloat knobProportion:(CGFloat)ratio
{
	[self setKnobProportion:ratio];
	[self setFloatValue:aFloat];
}

- (void) setFrame:(NSRect)frameRect
{
	_isHorizontal=(frameRect.size.width > frameRect.size.height);
	if (_isHorizontal) 		// determine the
		{													// orientation of
//		frameRect.size.height = [[self class] scrollerWidthForControlSize:_controlSize];		// adjust it's size
		_arrowsPosition = NSScrollerArrowsMinEnd;			// accordingly
		}
	else 
		{
//		frameRect.size.width = [[self class] scrollerWidthForControlSize:_controlSize];
		_arrowsPosition = NSScrollerArrowsMaxEnd;
		}
	[super setFrame:frameRect];
	_hitPart = NSScrollerNoPart;
	[self checkSpaceForParts];
}

- (void) setFrameSize:(NSSize)size
{
	[super setFrameSize:size];
	[self checkSpaceForParts];
//	[self setNeedsDisplay:YES];
}

- (void) setControlSize:(NSControlSize) sz
{
	if(_controlSize == sz)
		return;
	_controlSize = sz;
//	[self drawParts];
	[self setNeedsDisplay:YES];
}

- (void) highlight:(BOOL) flag { return; }

- (NSControlSize) controlSize; { return _controlSize; }

- (void) setControlTint:(NSControlTint) t
{
	if(_controlTint == t)
		return;
	_controlTint = t;
	[self setNeedsDisplay:YES];
}

- (NSControlTint) controlTint; { return _controlTint; }

- (NSScrollerPart) testPart:(NSPoint)point
{ // return the part of the scroller hit by the mouse
	if (point.x < 0 || point.y < 0 || point.x > NSWidth(_frame) || point.y > NSHeight(_frame))
		return NSScrollerNoPart;	// outside
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerDecrementLine]])
		return NSScrollerDecrementLine;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerIncrementLine]])
		return NSScrollerIncrementLine;
	
#if 0
	if ([self mouse:point inRect:[self rectForPart:NSScrollerDecrementPage]])
		return NSScrollerDecrementPage;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerIncrementPage]])
		return NSScrollerIncrementPage;
#endif
	if ([self mouse:point inRect:[self rectForPart:NSScrollerKnob]])
		return NSScrollerKnob;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerKnobSlot]])
		{
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"AppleScrollerPagingBehavior"])
			{
			// check point.y > [self rectForPart:NSScrollerKnobSlot].origin.y
			// FIXME: return NSScrollerDecrementPage or NSScrollerIncrementPage
				// if user clicks in the slot
			}
		return NSScrollerKnobSlot;
		}
	
	return NSScrollerNoPart;
}

- (void) _scrollWheel:(NSEvent *)event
{ // handle scroll wheel events passed down from NSScrollView
	if (!_isEnabled)
		return;
	if ([event deltaX] > 0)
		_hitPart = NSScrollerIncrementPage;
	else
		_hitPart = NSScrollerDecrementPage;
	// update scroller
	[self sendAction:_action to:_target];
}

- (void) mouseDown:(NSEvent*)event
{ // handle mouse down events
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];

	if(![_target respondsToSelector:_action])
		NSLog(@"NSScroller: target %@ does not repsond to action %@!", _target, NSStringFromSelector(_action));
	if(_isHorizontal)								// configure global cells
		{
		[__leftCell setAction:_action];
		[__rightCell setAction:_action];
		[__leftCell setTarget:_target];
		[__rightCell setTarget:_target];
		}
	else
		{
		[__upCell setAction:_action];
		[__downCell setAction:_action];
		[__upCell setTarget:_target];
		[__downCell setTarget:_target];
		}

	[__knobCell setTarget:_target];
	[__knobCell setAction:_action];

	switch ((_hitPart = [self testPart: p])) 
		{
		case NSScrollerIncrementLine:
		case NSScrollerDecrementLine:
		case NSScrollerIncrementPage:
		case NSScrollerDecrementPage:
			[self trackScrollButtons:event];
			break;
		
		case NSScrollerKnob:
			[self trackKnob:event];
			break;
		
		case NSScrollerKnobSlot: 
			{
				if(0 /* ScrollerClickBehaviour default setting */)
					{
					// FIXME - we should generate (repeating) page up/down events to move the knob in page steps until we hit the knob directly
					}
				else
					{ // make scroller jump and then track
					NSRect knobRect = [self rectForPart: NSScrollerKnob];
					NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];
					CGFloat v;
					if(_isHorizontal)
						v=(p.x-knobRect.size.width/2.0-slotRect.origin.x)/(slotRect.size.width-knobRect.size.width);
					else
						v=(p.y-knobRect.size.height/2.0-slotRect.origin.y)/(slotRect.size.height-knobRect.size.height);
					[self setFloatValue:v];
					[self sendAction:_action to:_target];
					[self trackKnob:event];
					}
				break;
			}
	
		case NSScrollerNoPart:
			break;
		}
	
	_hitPart = NSScrollerNoPart;
}

- (void) trackKnob:(NSEvent*)event
{
	NSDate *distantFuture = [NSDate distantFuture];
	NSRect knobRect = [self rectForPart: NSScrollerKnob];
	NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];
	NSPoint initial = [self convertPoint:[event locationInWindow] fromView:nil];
	NSSize offset = NSMakeSize(initial.x - knobRect.origin.x, initial.y - knobRect.origin.y);	// offset to origin within knob
	NSEventType type;
#if 0
	NSLog(@"NSScroller trackKnob");
	NSLog(@" offset=%@", NSStringFromSize(offset));
#endif
	_hitPart = NSScrollerKnob;

	while((type = [event type]) != NSLeftMouseUp)				 
		{ // user is moving scroller
		if (type == NSLeftMouseDragged) 
			{ // mouse has moved
			CGFloat v;
			NSPoint point = [self convertPoint:[event locationInWindow] fromView:nil];
			[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
			if(_isHorizontal)
				v=(point.x-offset.width-slotRect.origin.x)/(slotRect.size.width-knobRect.size.width);
			else
				v=(point.y-offset.height-slotRect.origin.y)/(slotRect.size.height-knobRect.size.height);
			if(v < 0.0)
				v=0.0;
			else if(v > 1.0)
				v=1.0;
			if (v != _floatValue)
				{ // value has really changed
				_floatValue = v;
				knobRect = [self rectForPart: NSScrollerKnob];	// update
				[self setNeedsDisplayInRect:slotRect];	// redraw (could be optimized to redraw the scroller knob union previous position only)
				[_target performSelector:_action withObject:self];	// _target should be the NSScrollView and _action should be @selector(_doScroller:)
				}
			}
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:distantFuture 
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
  		}
	if([_target isKindOfClass:[NSResponder class]])
		[_target mouseUp:event];
}

- (void) trackScrollButtons:(NSEvent*)event
{
	NSDate *distantFuture = [NSDate distantFuture];
	NSUInteger mask = NSLeftMouseDownMask | NSLeftMouseUpMask 
				  | NSLeftMouseDraggedMask | NSMouseMovedMask;

	do	{
		NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
		id theCell;
		
		switch ((_hitPart = [self testPart:p])) 			// determine which 
			{												// cell was hit
			case NSScrollerIncrementLine:
			case NSScrollerIncrementPage:
				theCell = (_isHorizontal ? __rightCell : __downCell);
				// if option key - _hitPart=NSScrollerIncrementPage;
				break;

			case NSScrollerDecrementLine:
			case NSScrollerDecrementPage:
				theCell = (_isHorizontal ? __leftCell : __upCell);
				// if option key - _hitPart=NSScrollerDecrementPage;
				break;

			default:
				theCell = nil;
				break;
			}

		if (theCell) 
			{
			NSRect rect = [self rectForPart:_hitPart];
			BOOL done = NO;

			[theCell setHighlighted:YES];
			[self setNeedsDisplayInRect:rect];

			NSDebugLog (@"tracking cell %x", theCell);

			done = [theCell trackMouse:event				// Track the mouse
							inRect:rect						// until left mouse
							ofView:self						// goes up
							untilMouseUp:YES];

			[theCell setHighlighted:NO];
			[self setNeedsDisplayInRect:rect];

			// FIXME: what is this good for?
				// _target is the ScrollView and mouseUp invalidates some cursor rects

			if (done)
				{
				if([_target isKindOfClass:[NSResponder class]])
					[_target mouseUp:event];	// pass to target
				break;
				}
			}

		event = [NSApp nextEventMatchingMask:mask
								   untilDate:distantFuture 
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
		}
	while ([event type] == NSLeftMouseDragged);
}

- (void) drawRect:(NSRect)rect								// draw scroller
{
	NSDebugLog (@"NSScroller drawRect: ((%f, %f), (%f, %f))",
			rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
	[[NSColor controlColor] set];
	NSRectFill(rect);		// draw background
	[[NSColor controlShadowColor] set];
	NSFrameRect(rect);	// draw frame
	[self drawArrow:NSScrollerDecrementArrow highlight:_hitPart == NSScrollerDecrementLine];	
	[self drawArrow:NSScrollerIncrementArrow highlight:_hitPart == NSScrollerIncrementLine];	
	[self drawKnob];
}

- (void) drawArrow:(NSScrollerArrow)whichButton highlight:(BOOL)flag
{
	id theCell = nil;
	NSRect rect = [self rectForPart:(whichButton == NSScrollerIncrementArrow
						? NSScrollerIncrementLine : NSScrollerDecrementLine)];
	NSSize isize;	// image size
	NSDebugLog (@"position of %s cell is (%f, %f)",
		(whichButton == NSScrollerIncrementArrow ? "increment" : "decrement"),
		rect.origin.x, rect.origin.y);
	
	if(rect.size.width <= 0.0 || rect.size.height <= 0.0)
		return;	// nothing to draw

	isize=NSMakeSize(rect.size.width-2, rect.size.height-2);

	switch(whichButton) 
		{
		case NSScrollerDecrementArrow:
			theCell = (_isHorizontal ? __leftCell : __upCell);
			break;
		case NSScrollerIncrementArrow:
			theCell = (_isHorizontal ? __rightCell : __downCell);
			break;
		}
	[[theCell image] setSize:isize];
	[[theCell alternateImage] setSize:isize];
	[theCell setHighlighted:flag];
	[theCell drawWithFrame:rect inView:self];
}

- (void) drawKnob
{
	NSRect rect=[self rectForPart: NSScrollerKnobSlot];
	[[NSColor scrollBarColor] set];
	NSRectFill(rect);		// draw bar slot
	rect=[self rectForPart:NSScrollerKnob];
	[__knobCell drawWithFrame:rect inView:self];			// draw frame/interior (i.e. dimple image)
}

- (NSRect) rectForPart:(NSScrollerPart)partCode
{ // FIXME: we should cache these values
	NSRect scrollerFrame = _frame;
	CGFloat x = 1, y = 1, width = 0, height = 0;
	NSUsableScrollerParts usableParts;
	// If the scroller is disabled then
	if (!_isEnabled)						// the scroller buttons and the 
		usableParts = NSNoScrollerParts;	// knob are not displayed at all.
	else
		usableParts = _usableParts;
	// Assign to `width' and `height' values describing 
	// the width and height of the scroller regardless of orientation
	if (_isHorizontal)
		{	
		width = scrollerFrame.size.height-2;	// room for border
		height = scrollerFrame.size.width-2;
		}
    else 
		{
		width = scrollerFrame.size.width-2;
		height = scrollerFrame.size.height-2;
    	}

	switch (partCode)
		{ 	// The x, y, width and height values are computed below for the vertical scroller.  The height of the scroll buttons is assumed to be equal to the width.
    	case NSScrollerKnob:
			{
				CGFloat knobHeight, knobPosition, slotHeight;
				if (usableParts == NSNoScrollerParts || usableParts == NSOnlyScrollerArrows)
					return NSZeroRect;		// If the scroller does not have parts or a knob return a zero rect. 
				slotHeight = height - (_arrowsPosition == NSScrollerArrowsNone ? 0 : 2 * width);	// calc the slot Height
				knobHeight = floorf(_knobProportion * slotHeight);
				if (knobHeight < width)			// adjust knob height and proportion if necessary
					{ // make it at least square
					knobHeight = width; 
					_knobProportion = (CGFloat)(knobHeight / slotHeight);
					}
				knobPosition = _floatValue * (slotHeight - knobHeight);	// calc knob's position (left/top end)
//			knobPosition = (CGFloat)floor(knobPosition);	// avoid (why?) rounding error
				
				y += knobPosition;	// move knob
				if(_arrowsPosition == NSScrollerArrowsMinEnd)
					y += 2 * width;	// leave room for two rectangular buttons
				height = knobHeight;
				break;										
    		}
			
		case NSScrollerKnobSlot:
			{ // if the scroller does	not have buttons the slot completely fills the scroller.
				if (usableParts == NSNoScrollerParts)
					break;
				
				if (_arrowsPosition == NSScrollerArrowsMaxEnd) 
					height -= 2 * width;
				else if (_arrowsPosition == NSScrollerArrowsMinEnd) 
					{
					y += 2 * width;
					height -= 2 * width;
					}
				break;
			}
		case NSScrollerDecrementPage:
			// FIXME: should be area between knob and buttons
		case NSScrollerDecrementLine:
			{ // left/up arrow
				if (usableParts == NSNoScrollerParts)		// if scroller has no
					return NSZeroRect;						// parts or knob then
															// return a zero rect
				if (_arrowsPosition == NSScrollerArrowsMaxEnd)
					y = height-1 - 2 * width;
				else if(_arrowsPosition != NSScrollerArrowsMinEnd)
					return NSZeroRect;
				height = width;	// square
				break;
			}
		case NSScrollerIncrementPage:
			// FIXME: should be area between knob and buttons
		case NSScrollerIncrementLine:	// up/down arrow
			{
				if (usableParts == NSNoScrollerParts)		// if scroller has no
					return NSZeroRect;						// parts or knob then
															// return a zero rect
				if (_arrowsPosition == NSScrollerArrowsMaxEnd)
					y = height-1 - width;
				else if (_arrowsPosition == NSScrollerArrowsMinEnd)
					y += width;
				else
					return NSZeroRect;
				height = width;	// square
				break;
			}
			
		case NSScrollerNoPart:
      		return NSZeroRect;
  		}
	if(_isHorizontal)
		return (NSRect) {{y, x}, {height, width}};
	else
		return (NSRect) {{x, y}, {width, height}};
}

@end
