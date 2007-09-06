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
static NSButtonCell *__knobCell = nil;

static float __halfKnobHeight;
static float __bottomOfKnob;
static float __topOfKnob;
static float __slotHeightMinusKnobHeight;

static float __halfKnobWidth;
static float __leftOfKnob;
static float __rightOfKnob;
static float __slotWidthMinusKnobWidth;

static void GSPrecalculateScroller(NSRect slotRect, NSRect knobRect, BOOL isHorizontal)
{															
	if (isHorizontal)
		{
		__halfKnobWidth = knobRect.size.width / 2;
		__leftOfKnob = slotRect.origin.x + __halfKnobWidth;
		__rightOfKnob = NSMaxX(slotRect) - __halfKnobWidth;
		__slotWidthMinusKnobWidth = slotRect.size.width - knobRect.size.width;
		}
	else
		{
		__halfKnobHeight = knobRect.size.height / 2;
		__bottomOfKnob = slotRect.origin.y + __halfKnobHeight;
		__topOfKnob = NSMaxY(slotRect) - __halfKnobHeight;
		__slotHeightMinusKnobHeight = NSHeight(slotRect) - NSHeight(knobRect);
		}
}

static float GSConvertScrollerPoint(NSPoint point, BOOL isHorizontal)
{
	static float p;

	if (isHorizontal) 									// Adjust point to lie
		{												// within the knob slot
		p = MIN(MAX(point.x, __leftOfKnob), __rightOfKnob);
		p = (p - __leftOfKnob) / __slotWidthMinusKnobWidth;
		}
	else
		{
		p = MIN(MAX(point.y, __bottomOfKnob), __topOfKnob);
		p = (p - __bottomOfKnob) / __slotHeightMinusKnobHeight;
		p = 1 - p;
		}
	return p;
}

@interface _NSKnobCell : NSActionCell
@end

@implementation _NSKnobCell

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSBezierPath *p=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:cellFrame.size.width < cellFrame.size.height];	// box with halfcircular rounded ends
	_controlView = controlView;				// Save as last view we have drawn to
	[[NSColor selectedControlColor] setFill];	// selected
	[p fill];		// fill with color
}

@end

@implementation NSScroller

+ (float) scrollerWidth
{
	return 18.0;
}

+ (float) scrollerWidthForControlSize:(NSControlSize) size;
{
	switch(size)
		{
		default:	return [self scrollerWidth];
		case NSSmallControlSize: return 15.0;
		case NSMiniControlSize: return 11.0;
		}
}

- (id) initWithFrame:(NSRect)frameRect
{
#if 0
	NSLog(@"[NSScroller initWithFrame:%@]", NSStringFromRect(frameRect));
#endif
	if((self=[super initWithFrame:frameRect]))
		{
		_isHorizontal = frameRect.size.width > frameRect.size.height;
		_arrowsPosition=_isHorizontal?NSScrollerArrowsMinEnd:NSScrollerArrowsMaxEnd;
		_hitPart = NSScrollerNoPart;
		[self drawParts];
		[self checkSpaceForParts];
		}
	return self;
}

- (NSScrollArrowPosition) arrowsPosition	{ return _arrowsPosition; }
- (NSUsableScrollerParts) usableParts		{ return _usableParts; }
- (float) knobProportion					{ return _knobProportion; }
- (float) floatValue						{ return _floatValue; }
- (NSScrollerPart) hitPart					{ return _hitPart; }

- (void) encodeWithCoder:(NSCoder *) aCoder				{ NIMP }

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
		_arrowsPosition=ARROWSPOSITION;
#define USABLEPARTS ((sflags>>27)&3)
		_usableParts=USABLEPARTS;
#define CONTROLTINT ((sflags>>16)&7)
		_controlTint=CONTROLTINT;
		[self setFloatValue:[aDecoder decodeFloatForKey:@"NSCurValue"] knobProportion:[aDecoder decodeFloatForKey:@"NSPercent"]/100.0];
//		_target = [aDecoder decodeObjectForKey:@"NSTarget"];
//		_action = NSSelectorFromString([aDecoder decodeObjectForKey:@"NSAction"]);
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
{												// Create the class variable 
	if (__knobCell)								// button cells if they do not 
		return;									// yet exist.
	
	__upCell = [NSButtonCell new];
	[__upCell setBordered:YES];
	[__upCell setBezelStyle:NSRegularSquareBezelStyle];
	[__upCell setFocusRingType:NSFocusRingTypeNone];
	[__upCell setHighlightsBy:NSContentsCellMask];	// no PushIn effect - just swap images
	[__upCell setImagePosition:NSImageOnly];
	[__upCell setContinuous:YES];
	[__upCell setPeriodicDelay:0.05 interval:0.05];
	__downCell = [__upCell copy];
	__leftCell = [__upCell copy];
	__rightCell = [__upCell copy];

	[__upCell setImage:[NSImage imageNamed:@"GSArrowUp"]];
	[__upCell setAlternateImage:[NSImage imageNamed:@"GSArrowUpH"]];
	[__downCell setImage:[NSImage imageNamed:@"GSArrowDown"]];
	[__downCell setAlternateImage:[NSImage imageNamed:@"GSArrowDownH"]];
	[__leftCell setImage:[NSImage imageNamed:@"GSArrowLeft"]];
	[__leftCell setAlternateImage:[NSImage imageNamed:@"GSArrowLeftH"]];
	[__rightCell setImage:[NSImage imageNamed:@"GSArrowRight"]];
	[__rightCell setAlternateImage:[NSImage imageNamed:@"GSArrowRightH"]];

	__knobCell = [_NSKnobCell new];
#if OLD
	[__knobCell setBordered:YES];
	[__knobCell setBezelStyle:NSRoundedBezelStyle];
	[__knobCell setButtonType:NSMomentaryChangeButton];		// highlight by changing content (but we don't have alternateImage)
	// somehow set [NSColor knobColor];
	[__knobCell setImagePosition:NSImageOnly];				// i.e. centered within knobCell
	[__knobCell setImage:[NSImage imageNamed:@"GSDimple"]];	// set dimple icon
#endif
}

- (void) checkSpaceForParts
{
	NSSize frameSize = [self frame].size;
	float size = (_isHorizontal ? frameSize.width : frameSize.height);
	float scrollerWidth = (_isHorizontal ? frameSize.height : frameSize.width);

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
	if(_arrowsPosition == where)
		return;
	_arrowsPosition = where;
	[self setNeedsDisplay:YES];
}

- (void) setFloatValue:(float)aFloat
{
	aFloat = MIN(MAX(aFloat, 0), 1);
	if(_floatValue == aFloat)
		return;
	_floatValue=aFloat;
	[self setNeedsDisplayInRect:[self rectForPart:NSScrollerKnobSlot]];
}

- (void) setFloatValue:(float)aFloat knobProportion:(float)ratio
{
	ratio=MIN(MAX(ratio, 0), 1);
	if(_knobProportion != ratio)
		{
		_knobProportion = ratio;
		[self setNeedsDisplay:YES];
		}
	[self setFloatValue:aFloat];
}

- (void) setFrame:(NSRect)frameRect
{
	_isHorizontal=(frameRect.size.width > frameRect.size.height);
	if (_isHorizontal) 		// determine the
		{													// orientation of
//		frameRect.size.height = [isa scrollerWidthForControlSize:_controlSize];		// adjust it's size
		_arrowsPosition = NSScrollerArrowsMinEnd;			// accordingly
		}
	else 
		{
//		frameRect.size.width = [isa scrollerWidthForControlSize:_controlSize];
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

- (void) highlight:(BOOL) flag
{
}

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
	if (point.x < 0 || point.y < 0 || point.x > NSWidth(frame) || point.y > NSHeight(frame))
		return NSScrollerNoPart;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerDecrementLine]])
		return NSScrollerDecrementLine;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerIncrementLine]])
		return NSScrollerIncrementLine;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerKnob]])
		return NSScrollerKnob;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerKnobSlot]])
		return NSScrollerKnobSlot;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerDecrementPage]])
		return NSScrollerDecrementPage;
	
	if ([self mouse:point inRect:[self rectForPart:NSScrollerIncrementPage]])
		return NSScrollerIncrementPage;
	
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
//	[self lockFocus];
	// redraw scroller
	[self sendAction:_action to:_target];
//	[self unlockFocus];
}

- (void) mouseDown:(NSEvent*)event
{ // handle mouse down events
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];

	[self lockFocus];	// we will call cells directly to draw their interior
	NSRectClip(bounds);
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
			NSRect knobRect = [self rectForPart: NSScrollerKnob];
			NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];

			GSPrecalculateScroller(slotRect, knobRect, _isHorizontal);
			[self setFloatValue: GSConvertScrollerPoint(p, _isHorizontal)];
			[self sendAction:_action to:_target];
			[self drawKnob];
			[self trackKnob:event];
			break;
			}
	
		case NSScrollerNoPart:
			break;
		}
	
	_hitPart = NSScrollerNoPart;
	[self unlockFocus];
}

- (void) trackKnob:(NSEvent*)event
{
	NSDate *distantFuture = [NSDate distantFuture];
	NSRect knobRect = [self rectForPart: NSScrollerKnob];
	NSRect slotRect = [self rectForPart: NSScrollerKnobSlot];
	NSPoint point, current, offset = NSZeroPoint;
	float previous = _floatValue;
	NSEventType type;

	NSDebugLog(@"NSScroller trackKnob");
	
	GSPrecalculateScroller(slotRect, knobRect, _isHorizontal);
	point = [self convertPoint:[event locationInWindow] fromView:nil];
	if (_isHorizontal)
		offset.x = NSMidX(knobRect) - point.x;
	else
		offset.y = NSMidY(knobRect) - point.y;
	current.x += offset.x;
	current.y += offset.y;
	knobRect.origin = [self convertPoint:point fromView:nil];

	_hitPart = NSScrollerKnob;						// set periodic events rate
													// to achieve max of ~30fps
	[NSEvent startPeriodicEventsAfterDelay:0.02 withPeriod:0.033];

	while ((type = [event type]) != NSLeftMouseUp)				 
		{											// user is moving scroller
		if (type != NSPeriodic)						// loop until left mouse up
			{
			current = [event locationInWindow];
			current.x += offset.x;
			current.y += offset.y;
			}
		else				
			{
			point = [self convertPoint:current fromView:nil];

			if (point.x != knobRect.origin.x || point.y != knobRect.origin.y) 
				{ // mouse has moved							
				float v = GSConvertScrollerPoint(point, _isHorizontal);

				if (v != previous)
					{ // value has changed
					previous = v;
					_floatValue = MIN(MAX(v, 0), 1);
					[self drawKnob];				// draw the scroller knob
					[window flushWindow];
					[_target performSelector:_action withObject:self];
					}

				knobRect.origin = point;
			}	}

		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:distantFuture 
									  inMode:NSEventTrackingRunLoopMode
									 dequeue:YES];
  		}

	[NSEvent stopPeriodicEvents];

	if([_target isKindOfClass:[NSResponder class]])
		[_target mouseUp:event];
}

- (void) trackScrollButtons:(NSEvent*)event
{
	NSDate *distantFuture = [NSDate distantFuture];
	unsigned int mask = NSLeftMouseDownMask | NSLeftMouseUpMask 
				  | NSLeftMouseDraggedMask | NSMouseMovedMask;

	do	{
		NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
		id theCell;
		
		switch ((_hitPart = [self testPart:p])) 			// determine which 
			{												// cell was hit
			case NSScrollerIncrementLine:
			case NSScrollerIncrementPage:
				theCell = (_isHorizontal ? __rightCell : __upCell);
				break;

			case NSScrollerDecrementLine:
			case NSScrollerDecrementPage:
				theCell = (_isHorizontal ? __leftCell : __downCell);
				break;

			default:
				theCell = nil;
				break;
			}

		if (theCell) 
			{
			NSRect rect = [self rectForPart:_hitPart];
			BOOL done = NO;

			[theCell highlight:YES withFrame:rect inView:self];	
			[window flushWindow];

			NSDebugLog (@"tracking cell %x", theCell);

			done = [theCell trackMouse:event				// Track the mouse
							inRect:rect						// until left mouse
							ofView:self						// goes up
							untilMouseUp:YES];

			[theCell highlight:NO withFrame:rect inView:self];
			[window flushWindow];

			if (done)
				{
				if([_target isKindOfClass:[NSResponder class]])
					[_target mouseUp:event];

				break;
			}	}

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
	NSFrameRect(rect);	// border box
	[self drawArrow:NSScrollerDecrementArrow highlight:NO];	
	[self drawArrow:NSScrollerIncrementArrow highlight:NO];	
	[self drawKnob];
}

- (void) drawArrow:(NSScrollerArrow)whichButton highlight:(BOOL)flag
{
	id theCell = nil;
	NSRect rect = [self rectForPart:(whichButton == NSScrollerIncrementArrow
						? NSScrollerIncrementLine : NSScrollerDecrementLine)];

	NSDebugLog (@"position of %s cell is (%f, %f)",
		(whichButton == NSScrollerIncrementArrow ? "increment" : "decrement"),
		rect.origin.x, rect.origin.y);
	
	if(rect.size.width <= 0.0 || rect.size.height <= 0.0)
		return;	// nothing to draw

	switch(whichButton) 
		{
		case NSScrollerDecrementArrow:
			theCell = (_isHorizontal ? __leftCell : __downCell);
			break;
		case NSScrollerIncrementArrow:
			theCell = (_isHorizontal ? __rightCell : __upCell);
			break;
		}	
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
{
	NSRect scrollerFrame = frame;
	float x = 1, y = 1, width = 0, height = 0, floatValue;
	NSScrollArrowPosition arrowsPosition;
	NSUsableScrollerParts usableParts;
											// If the scroller is disabled then
	if (!_isEnabled)						// the scroller buttons and the 
		usableParts = NSNoScrollerParts;	// knob are not displayed at all.
	else
		usableParts = _usableParts;
								// Since we haven't yet flipped views we have 
	if (!_isHorizontal) 		// to swap the meaning of the arrows position
		{						// if the scroller's orientation is vertical.
		if (_arrowsPosition == NSScrollerArrowsMaxEnd)
			arrowsPosition = NSScrollerArrowsMinEnd;
		else
			{ 
			if (_arrowsPosition == NSScrollerArrowsMinEnd)
				arrowsPosition = NSScrollerArrowsMaxEnd;
			else
				arrowsPosition = NSScrollerArrowsNone;
		}	}
	else
		arrowsPosition = _arrowsPosition;

						// Assign to `width' and `height' values describing 
						// the width and height of the scroller regardless 
						// of its orientation.  Also compute the `floatValue' 
   if (_isHorizontal) 	// which is essentially the same width as _floatValue
		{				// but keeps track of the scroller's orientation.
		width = scrollerFrame.size.height-2;	// room for border
		height = scrollerFrame.size.width-2;
		floatValue = _floatValue;
		}
    else 
		{
		width = scrollerFrame.size.width-2;
		height = scrollerFrame.size.height-2;
		floatValue = 1 - _floatValue;
    	}								// The x, y, width and height values 
										// are computed below for the vertical  	
	switch (partCode) 					// scroller.  The height of the scroll 
		{								// buttons is assumed to be equal to 
    	case NSScrollerKnob: 			// the width.
			{
			float knobHeight, knobPosition, slotHeight;
										// If the scroller does not have parts 
										// or a knob return a zero rect. 
			if (usableParts == NSNoScrollerParts || usableParts == NSOnlyScrollerArrows)
				return NSZeroRect;
      		
			// calc the slot Height
			
			slotHeight = height - (arrowsPosition == NSScrollerArrowsNone ? 
								0 : 2 * width);
			knobHeight = floor(_knobProportion * slotHeight);
			if (knobHeight < width)			// adjust knob height
				{							// and proportion if
				knobHeight = width;			// necessary
      			_knobProportion = (float)(knobHeight / slotHeight);
				}
														// calc knob's position
      		knobPosition = floatValue * (slotHeight - knobHeight);
     		knobPosition = (float)floor(knobPosition);	// avoid rounding error

			if(knobPosition > 0)
				y += knobPosition;	// move knob
			if(arrowsPosition == NSScrollerArrowsMinEnd)
				y += 2 * width;	// leave room
			height = knobHeight;
			break;										
    		}

		case NSScrollerKnobSlot:
			// if the scroller does	not have buttons the slot completely fills the scroller.
			if (usableParts == NSNoScrollerParts)
				break;

			if (arrowsPosition == NSScrollerArrowsMaxEnd) 
				height -= 2 * width;
			else if (arrowsPosition == NSScrollerArrowsMinEnd) 
				{
				y += 2 * width;
				height -= 2 * width;
				}
			break;

		case NSScrollerDecrementPage:
			// should be area between knob and buttons
		case NSScrollerDecrementLine:	// left/down arrow
			// FIXME: we could recursively call ourselves for the NSScrollerKnobSlot and split by 2
			if (usableParts == NSNoScrollerParts)		// if scroller has no
				return NSZeroRect;						// parts or knob then
														// return a zero rect
			if (arrowsPosition == NSScrollerArrowsMaxEnd)
				y = height-1 - 2 * width;
			else if(arrowsPosition != NSScrollerArrowsMinEnd)
				return NSZeroRect;
			height = width;	// square
			break;

		case NSScrollerIncrementPage:
			// should be area between knob and buttons
		case NSScrollerIncrementLine:	// up/right arrow
			if (usableParts == NSNoScrollerParts)		// if scroller has no
				return NSZeroRect;						// parts or knob then
														// return a zero rect
      		if (arrowsPosition == NSScrollerArrowsMaxEnd)
				y = height-1 - width;
      		else if (arrowsPosition == NSScrollerArrowsMinEnd)
				y += width;
			else
				return NSZeroRect;
			height = width;	// square
			break;

		case NSScrollerNoPart:
      		return NSZeroRect;
  		}
	if(_isHorizontal)
		return (NSRect) {{y, x}, {height, width}};
	 else
		 return (NSRect) {{x, y}, {width, height}};
}

@end
