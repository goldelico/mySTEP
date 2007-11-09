/*
   NSSlider.m

   NSlider and NSSliderCell classes	

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: 	August 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <AppKit/NSEvent.h>
#import <AppKit/NSSlider.h>
#import <AppKit/NSSliderCell.h>
#import <AppKit/NSSliderCell.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSBezierPath.h>


// Class global variables
static Class _sliderCellClass;


//*****************************************************************************
//
// 		NSSliderCell 
//
//*****************************************************************************

@implementation NSSliderCell

- (id) init
{
	if((self=[self initImageCell:nil]))
		{
		_altIncrementValue = -1.0;
		_isVertical = NO;
		_initializedVertical=!_isVertical;	// force initialization
		_minValue = 0;
		_maxValue = 1;
		_contents = [[NSNumber numberWithFloat:0.0] retain];
		[self setBordered:NO];
		[self setBezeled:NO];	
		_knobCell = [NSCell new];
		}
	return self;
}

#if FIXME
- (id) copyWithZone:(NSZone *) z;
{
	return NIMP;
}
#endif

- (void) dealloc
{
	[_knobCell release];
	[super dealloc];
}

- (void) drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
	// FIXME: can we cache the path?
	NSBezierPath *p=[NSBezierPath bezierPath];
	float w2=2.5;
	float w=5.0;
	int i;
	[[NSColor blackColor] set];
	for(i=0; i<_numberOfTickMarks; i++)
		NSRectFill([self rectOfTickMarkAtIndex:i]);		// draw tick marks by filling
	[p setLineWidth:w];
	if(_isVertical)
		{
		float x=rect.origin.x+rect.size.width/2.0-w2;
		[p moveToPoint:NSMakePoint(x, rect.origin.y+w)];
		[p lineToPoint:NSMakePoint(x, rect.origin.y+rect.size.height-w)];
		}
	else
		{
		float y=rect.origin.y+rect.size.height/2.0+(flipped?-w2:w2);
		[p moveToPoint:NSMakePoint(rect.origin.x+w, y)];
		[p lineToPoint:NSMakePoint(rect.origin.x+rect.size.width-w, y)];
		}
	[p setLineWidth:w];
	[p setLineCapStyle:NSRoundLineCapStyle];	// round line cap
	[p stroke];
}

- (NSRect) knobRectFlipped:(BOOL)flipped
{
	NSImage *image = [_knobCell image];
	NSSize size;
	NSPoint origin;
	float floatValue;

	if(!_controlView || fabs(_maxValue - _minValue) < 1e-6)
		return NSZeroRect;	// can't determine properly
	if(_isVertical && flipped)
		floatValue = _maxValue + _minValue - [self floatValue];
	else
		floatValue = [self floatValue];
	floatValue = (floatValue - _minValue) / (_maxValue - _minValue);	// scale from 0.0 to 1.0
	if(floatValue < 0.0) floatValue=0.0;
	if(floatValue > 1.0) floatValue=1.0;
#if 0
	NSLog(@"floatValue=%lf", floatValue);
#endif
	size = [image size];
	if (_isVertical) 
		{
		origin.x = 0;
		origin.y = ((_trackRect.size.height - size.height) * floatValue) + 2;
		}
	else 
		{
		origin.x = ((_trackRect.size.width - size.width) * floatValue) + 0;
		if(flipped)
			origin.y=_trackRect.size.height-2;
		else
			origin.y = 2;
		}
	if(_numberOfTickMarks > 0)
		{
		if(_tickMarkPosition == NSTickMarkAbove)	// == NSTickMarkLeft
			;
		// adjust to make room for tick marks
		}
	return (NSRect){ origin, size };  
}

- (void) drawKnob
{
	if(_controlView)
		[self drawKnob:[self knobRectFlipped:[_controlView isFlipped]]];
}

- (void) drawKnob:(NSRect)knobRect
{
#if 0
	NSLog(@"knobRect=%@", NSStringFromRect(knobRect));
#endif
	[_knobCell drawInteriorWithFrame:knobRect inView:_controlView];
}

- (void) drawInteriorWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSRect kr;
	_controlView=controlView;	// remember
	if(_sliderType == NSCircularSlider)
		;
	if(_initializedVertical != _isVertical)
		{ // needs to adjust
		NSImage *image;
		float size;
		if((_initializedVertical = _isVertical))
			{
			image = [NSImage imageNamed:@"GSSliderVert"];
			size = cellFrame.size.width-2.0;
			}
		else 
			{
			image = [NSImage imageNamed:@"GSSliderHoriz"];
			size = cellFrame.size.height-2.0;
			}
		if(_numberOfTickMarks > 0)
			{
			if(_tickMarkPosition == NSTickMarkAbove)	// == NSTickMarkLeft
				;
			}
		image=[image copy];	// make an independent copy
		[image setSize:NSMakeSize(size, size)];	// make it square according to orientation
		[_knobCell setImage:image];
#if 0
		NSLog(@"knob cell %@", _knobCell);
		NSLog(@"knob image %@", image);
#endif
		[image release];
		}

	_trackRect = cellFrame;
	
//	if (_titleCell)
//		[_titleCell drawInteriorWithFrame:cellFrame inView:controlView];
	
	[self drawBarInside:cellFrame flipped:[controlView isFlipped]];
	kr=[self knobRectFlipped:[_controlView isFlipped]];
	kr.origin.x+=cellFrame.origin.x;
	if([_controlView isFlipped])
		kr.origin.y+=cellFrame.origin.y-kr.size.height;	// draw relative to given frame
	else
		kr.origin.y+=cellFrame.origin.y;	// draw relative to given frame
	[self drawKnob:kr];
}

- (float) knobThickness
{
	NSSize size = [[_knobCell image] size];
	return _isVertical ? size.height : size.width;
}

- (void) setKnobThickness:(float)thickness
{
	NSImage* image = [_knobCell image];
	NSSize size = [image size];
	if (_isVertical)
		size.height = thickness;
	else
		size.width = thickness;
	[image setSize:size];
}

- (void) setAltIncrementValue:(double)increment
{
	_altIncrementValue = increment;
}

- (void) setMinValue:(double)aDouble
{
	_minValue = aDouble;
	// check if we should modify the value
}

- (void) setMaxValue:(double)aDouble
{
	_maxValue = aDouble;
	// check if we should modify the value
}

- (double) minValue						{ return _minValue; }
- (double) maxValue						{ return _maxValue; }
- (int) isVertical						{ return _isVertical; }
- (double) altIncrementValue			{ return _altIncrementValue; }
+ (BOOL) prefersTrackingUntilMouseUp	{ return YES; }
- (NSRect) trackRect					{ return _trackRect; }

- (void) setTickMarkPosition:(NSTickMarkPosition) pos; { _tickMarkPosition=pos; }
- (NSTickMarkPosition) tickMarkPosition; { return _tickMarkPosition; }

- (double) tickMarkValueAtIndex:(int) index;
{
	if(_numberOfTickMarks == 0)
		return _minValue;
	return _minValue+(index*(_maxValue-_minValue))/_numberOfTickMarks;
}

- (NSRect) rectOfTickMarkAtIndex:(int) index;
{
	NSRect r=NSZeroRect;
	float w=2.0+16.0;	// knob size
	float w2=0.5*w;
	if(_isVertical)
		{
		r.origin.x=5.0;	// FIXME: make dependent on left/right
		r.origin.y=w2+index*(_trackRect.size.height-w)/(_numberOfTickMarks-1);
		r.size=NSMakeSize(5.0, 1.0);
		}
	else
		{
		r.origin.x=w2+index*(_trackRect.size.width-w)/(_numberOfTickMarks-1);
		r.origin.y=5.0;	// FIXME: make dependent on above/below
		r.size=NSMakeSize(1.0, 5.0);
		}
	return r;
}

- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	if([decoder allowsKeyedCoding])
		{
		_minValue=[decoder decodeDoubleForKey:@"NSMinValue"];
		_maxValue=[decoder decodeDoubleForKey:@"NSMaxValue"];
		_isVertical=[decoder decodeBoolForKey:@"NSVertical"];
		_initializedVertical=!_isVertical;	// force initialization of image
		_altIncrementValue=[decoder decodeDoubleForKey:@"NSAltIncValue"];
		[self setFloatValue:[decoder decodeFloatForKey:@"NSValue"]];
//		[self setDoubleValue:[decoder decodeDoubleForKey:@"NSValue"]];
		_sliderType=[decoder decodeIntForKey:@"NSSliderType"];
		_numberOfTickMarks=[decoder decodeIntForKey:@"NSNumberOfTickMarks"];
		_allowTickMarkValuesOnly=[decoder decodeBoolForKey:@"NSAllowsTickMarkValuesOnly"];
		_tickMarkPosition=[decoder decodeIntForKey:@"NSTickMarkPosition"];
		return self;
		}
	[decoder decodeValuesOfObjCTypes:"ff@f", &_minValue, &_maxValue, 
										&_contents, &_altIncrementValue];
	return self;
}

- (void) encodeWithCoder:(NSCoder*)coder
{
	[coder encodeValuesOfObjCTypes:"ff@f", _minValue, _maxValue, 
									_contents, _altIncrementValue];
}

// deprecated

- (id) titleCell						{ return nil; }
- (NSColor*) titleColor					{ return nil; }
- (NSFont*) titleFont					{ return nil; }
- (void) setTitle:(NSString*)title		{ [super setTitle:title]; }	// default implementation
- (NSString*) title						{ return nil; }
- (void) setTitleCell:(NSCell*)aCell	{ NIMP; return; }
- (void) setTitleColor:(NSColor*)color	{ NIMP; return; }
- (void) setTitleFont:(NSFont*)font		{ NIMP; return; }

- (double) closestTickMarkValueToValue:(double) value;
{
	if(_numberOfTickMarks > 1 && _allowTickMarkValuesOnly)
		{ // round to nearest tick mark value
		double dist=(_maxValue-_minValue)/(_numberOfTickMarks-1);	// distance between tick marks
		double n=(value-_minValue)/dist;
		n=floor(n+0.5);	// round to nearest integer
		value=n*dist+_minValue;
		}
	return value;
}

- (int) indexOfTickMarkAtPoint:(NSPoint) point;
{
	return NSNotFound;
}

- (BOOL) allowsTickMarkValuesOnly;					{ return _allowTickMarkValuesOnly; }
- (int) numberOfTickMarks;							{ return _numberOfTickMarks; }
- (void) setAllowsTickMarkValuesOnly:(BOOL) flag;	{ _allowTickMarkValuesOnly=flag; }
- (void) setNumberOfTickMarks:(int) num;			{ _numberOfTickMarks=num > 0?num:0; }
- (void) setSliderType:(NSSliderType) sliderType;	{ _sliderType=sliderType; }
- (NSSliderType) sliderType;						{ return _sliderType; }

- (float) _floatValueForMousePoint:(NSPoint)point knobRect:(NSRect)knobRect flipped:(BOOL) isFlipped;
{
	NSRect slotRect = [self trackRect];
	BOOL isVertical = [self isVertical];
	float minValue = [self minValue];
	float maxValue = [self maxValue];
	float floatValue = 0;
	float position;
	// Adjust the point to lie inside the knob slot. We don't have to worry whether the view is flipped or not.
	if (isVertical)
		{
		if (point.y < slotRect.origin.y + knobRect.size.height / 2)
			position = slotRect.origin.y + knobRect.size.height / 2;
    	else 
			if (point.y <= (position = NSMaxY(slotRect) -NSHeight(knobRect)/2))
      			position = point.y;
		// Compute the float value 
    	floatValue = (position - (slotRect.origin.y + knobRect.size.height/2))
			/ (slotRect.size.height - knobRect.size.height);
   		if (isFlipped)
      		floatValue = 1 - floatValue;
  		}
	else
		{ // Adjust the point to lie inside the knob slot 
		if (point.x < slotRect.origin.x + knobRect.size.width / 2)
			position = slotRect.origin.x + knobRect.size.width / 2;
		else 
			if (point.x <= (position = NSMaxX(slotRect) - NSWidth(knobRect)/2))
      			position = point.x;
		// Compute the float value given the knob size
    	floatValue = (position - (slotRect.origin.x + knobRect.size.width / 2))
			/ (slotRect.size.width - knobRect.size.width);
  		}
	return floatValue * (maxValue - minValue) + minValue;
}

- (BOOL) startTrackingAt:(NSPoint)startPoint
				  inView:(NSView*)control
{ // we want to know tracking positions and have the knob follow where we are
	BOOL isFlipped=[control isFlipped];
	float v = [self _floatValueForMousePoint:startPoint knobRect:[self knobRectFlipped:isFlipped] flipped:isFlipped];
	if([self allowsTickMarkValuesOnly])
		v=[self closestTickMarkValueToValue:v]; // round to nearest tick mark
	[self setFloatValue:v];	// calls updateCell:
#if 1
	NSLog(@"startTrackingAt -> controlView=%@", control);
#endif
	return YES;
}

- (BOOL) continueTracking:(NSPoint)lastPoint			// Tracking the Mouse
					   at:(NSPoint)currentPoint
				   inView:(NSView *)controlView
{
#if 1
	NSLog(@"NSSliderCell continueTracking:%@ at:%@", NSStringFromPoint(lastPoint), NSStringFromPoint(currentPoint));
#endif
	[self startTrackingAt:currentPoint inView:controlView];	// move slider
	return YES;	// always continue
}

@end /* NSSliderCell */

//*****************************************************************************
//
// 		NSSlider 
//
//*****************************************************************************

@implementation NSSlider

+ (void) initialize
{
	if (self == [NSSlider class])
		_sliderCellClass = [NSSliderCell class];		// Set our cell class
}

+ (void) setCellClass:(Class)class			{ _sliderCellClass = class; }
+ (Class) cellClass							{ return _sliderCellClass; }

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame:frameRect]))
		{
		[self setCell:[[_sliderCellClass new] autorelease]];		// set our cell
		[_cell setState:1];
		}
	return self;
}

- (NSImage *) image							{ return [_cell image]; }
- (int) isVertical							{ return [_cell isVertical]; }
- (float) knobThickness						{ return [_cell knobThickness]; }
- (void) setImage:(NSImage*)backgroundImg	{ [_cell setImage:backgroundImg]; }
- (void) setKnobThickness:(float)aFloat		{ [_cell setKnobThickness:aFloat];}
- (void) setTitle:(NSString *)aString		{ [_cell setTitle:aString]; }
- (void) setTitleCell:(NSCell *)aCell		{ [_cell setTitleCell:aCell]; }
- (void) setTitleColor:(NSColor *)aColor	{ [_cell setTitleColor:aColor]; }
- (void) setTitleFont:(NSFont *)fontObj		{ [_cell setTitleFont:fontObj]; }
- (NSString *) title						{ return [_cell title]; }
- (id) titleCell							{ return [_cell titleCell]; }
- (NSColor *) titleColor					{ return [_cell titleColor]; }
- (NSFont *) titleFont						{ return [_cell titleFont]; }
- (BOOL) allowsTickMarkValuesOnly;			{ return [_cell allowsTickMarkValuesOnly]; }
- (double) altIncrementValue				{ return [_cell altIncrementValue]; }
- (double) closestTickMarkValueToValue:(double) value;	{ return [_cell closestTickMarkValueToValue:value]; }
- (int) indexOfTickMarkAtPoint:(NSPoint) point;	{ return [_cell indexOfTickMarkAtPoint:point]; }
- (double) maxValue							{ return [_cell maxValue]; }
- (double) minValue							{ return [_cell minValue]; }
- (int) numberOfTickMarks;					{ return [_cell numberOfTickMarks]; }
- (NSRect) rectOfTickMarkAtIndex:(int) index;	{ return [_cell rectOfTickMarkAtIndex:index]; }
- (void) setAllowsTickMarkValuesOnly:(BOOL)f	{ [_cell setAllowsTickMarkValuesOnly:f]; }
- (void) setAltIncrementValue:(double)aDouble	{ [_cell setAltIncrementValue:aDouble]; }
- (void) setMaxValue:(double)aDouble		{ [_cell setMaxValue:aDouble]; }
- (void) setMinValue:(double)aDouble		{ [_cell setMinValue:aDouble]; }
- (void) setNumberOfTickMarks:(int) num;	{ [_cell setNumberOfTickMarks:num]; }
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;	{ [_cell setTickMarkPosition:pos]; }
- (NSTickMarkPosition) tickMarkPosition;	{ return [_cell tickMarkPosition]; }
- (double) tickMarkValueAtIndex:(int) index;	{ return [_cell tickMarkValueAtIndex:index]; }
- (NSRect) trackRect						{ return [_cell trackRect]; }
- (BOOL) acceptsFirstMouse:(NSEvent*)event	{ return YES; }

@end /* NSSlider */
