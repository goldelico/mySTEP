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
#import "NSAppKitPrivate.h"


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
	if((self=[self initTextCell:@""]))
		{
		_altIncrementValue = -1.0;
		_isVertical = NO;
		_minValue = 0;
		_maxValue = 1;
		_contents = [[NSNumber numberWithFloat:0.0] retain];
		[self setBordered:NO];
		[self setBezeled:NO];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) z;
{
	NSSliderCell *c=[super copyWithZone:z];
	c->_minValue=_minValue;
	c->_maxValue=_maxValue;
	c->_altIncrementValue=_altIncrementValue;
	c->_numberOfTickMarks=_numberOfTickMarks;
	c->_sliderType=_sliderType;
	c->_tickMarkPosition=_tickMarkPosition;
	c->_isVertical=_isVertical;
	c->_allowTickMarkValuesOnly=_allowTickMarkValuesOnly;
	return c;
}

- (void) dealloc
{
	[_knobCell release];
	[super dealloc];
}

- (void) setObjectValue:(id <NSCopying>)anObject
{ // should be a float!
#if 0
	NSLog(@"%@ setObjectValue:%@ (_contents=%@)", self, anObject, _contents);
#endif
	if(anObject == _contents)
		return;	// needn't do anything
	[_contents release];	// we can release since it was a copy
	_contents=[anObject copyWithZone:NULL];	// save a copy
}

- (void) drawBarInside:(NSRect)rect flipped:(BOOL)flipped
{
	// FIXME: can we cache the path?
	NSBezierPath *p=[NSBezierPath bezierPath];
	CGFloat w2=2.5;
	CGFloat w=5.0;
	int i;
	[[NSColor blackColor] set];
	for(i=0; i<_numberOfTickMarks; i++)
		NSRectFill([self rectOfTickMarkAtIndex:i]);		// draw tick marks by filling
	[p setLineWidth:w];
	if(_isVertical)
		{
		CGFloat x=rect.origin.x+rect.size.width/2.0-w2;
		[p moveToPoint:NSMakePoint(x, rect.origin.y+w)];
		[p lineToPoint:NSMakePoint(x, rect.origin.y+rect.size.height-w)];
		}
	else
		{
		CGFloat y=rect.origin.y+rect.size.height/2.0+(flipped?-w2:w2);
		[p moveToPoint:NSMakePoint(rect.origin.x+w, y)];
		[p lineToPoint:NSMakePoint(rect.origin.x+rect.size.width-w, y)];
		}
	[p setLineWidth:w];
	[p setLineCapStyle:NSRoundLineCapStyle];	// round line cap
	[p stroke];
}

- (NSRect) knobRectFlipped:(BOOL)flipped
{
	NSSize size;
	NSPoint origin;
	CGFloat floatValue;

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
	if(!_knobCell)
		{ // needs to setup knob image
			NSImage *image;
			CGFloat sz;
			_knobCell = [NSCell new];
			if(_isVertical)
				{
				image = [NSImage imageNamed:@"GSSliderVert"];
				sz = _slotRect.size.width-2.0;
				}
			else
				{
				image = [NSImage imageNamed:@"GSSliderHoriz"];
				sz = _slotRect.size.height-2.0;
				}
			if(_numberOfTickMarks > 0)
				{
				if(_tickMarkPosition == NSTickMarkAbove)	// == NSTickMarkLeft
					;
				}
			image=[image copy];	// make an independent copy
			size=NSMakeSize(sz, sz);
			[image setSize:size];	// make it square according to orientation
			[_knobCell setImage:image];
#if 0
			NSLog(@"knob cell %@", _knobCell);
			NSLog(@"knob image %@", image);
#endif
			[image autorelease];
		}
	else
		size = [[_knobCell image] size];

	if (_isVertical)
		{
		origin.x = 0;
		origin.y = ((_slotRect.size.height - size.height) * floatValue) + 2;
		}
	else
		{
		origin.x = ((_slotRect.size.width - size.width) * floatValue) + 0;
		if(flipped)
			origin.y=_slotRect.size.height-2;
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
	BOOL flipped;
	NSRect kr;
	_controlView=controlView;	// remember
	flipped=[_controlView isFlipped];
	_slotRect=cellFrame;	// used inside knobRectFlipped
	if(_sliderType == NSCircularSlider)
		;
	//	if (_titleCell)
	//		[_titleCell drawInteriorWithFrame:cellFrame inView:controlView];

	[self drawBarInside:cellFrame flipped:flipped];
	kr=[self knobRectFlipped:flipped];
	kr.origin.x+=cellFrame.origin.x;
	if(flipped)
		kr.origin.y+=cellFrame.origin.y-kr.size.height;	// draw relative to given frame
	else
		kr.origin.y+=cellFrame.origin.y;	// draw relative to given frame
	[self drawKnob:kr];
}

- (CGFloat) knobThickness
{
	NSSize size;
	if(!_knobCell) [self knobRectFlipped:NO];
	size= [[_knobCell image] size];
	return _isVertical ? size.height : size.width;
}

- (void) setKnobThickness:(CGFloat)thickness
{
	NSImage* image;
	if(!_knobCell) [self knobRectFlipped:NO];
	image = [_knobCell image];
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
	// check if we should modify the max value
}

- (void) setMaxValue:(double)aDouble
{
	_maxValue = aDouble;
	// check if we should modify the min value
}

- (double) minValue						{ return _minValue; }
- (double) maxValue						{ return _maxValue; }
// FIXME: is vertical if height > width - but it is also initialized from initWithCoder!
- (BOOL) isVertical				{ return _isVertical; }
- (double) altIncrementValue			{ return _altIncrementValue; }
+ (BOOL) prefersTrackingUntilMouseUp	{ return YES; }

- (void) setTickMarkPosition:(NSTickMarkPosition) pos; { _tickMarkPosition=pos; }
- (NSTickMarkPosition) tickMarkPosition; { return _tickMarkPosition; }

- (double) tickMarkValueAtIndex:(NSInteger) index;
{
	if(_numberOfTickMarks == 0)
		return _minValue;
	return _minValue+(index*(_maxValue-_minValue))/_numberOfTickMarks;
}

- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;
{ // index from 0 .. numberOfTickmarks-1
	NSRect r=NSZeroRect;
	CGFloat w=[[_knobCell image] size].width;
	CGFloat w2=0.5*w;
	if(_isVertical)
		{
		r.origin.x=0.0;	// FIXME: make dependent on left/right
		r.origin.y=w2+index*(_slotRect.size.height-w)/(_numberOfTickMarks-1);
		r.size=NSMakeSize(5.0, 1.0);
		}
	else
		{
		r.origin.x=w2+index*(_slotRect.size.width-w)/(_numberOfTickMarks-1)-1;
		r.origin.y=5.0;	// FIXME: make dependent on above/below
		r.size=NSMakeSize(1.0, 5.0);
		}
	return r;
}

- (id) initWithCoder:(NSCoder*)decoder
{
	// FIXME: _c.type makes it an image cell which gives problems with setObjectValue
	self = [super initWithCoder:decoder];
	if([decoder allowsKeyedCoding])
		{
		_minValue=[decoder decodeDoubleForKey:@"NSMinValue"];
		_maxValue=[decoder decodeDoubleForKey:@"NSMaxValue"];
		if(_maxValue <= _minValue)
			NSLog(@"invalid min/max values");
		_isVertical=[decoder decodeBoolForKey:@"NSVertical"];
		_altIncrementValue=[decoder decodeDoubleForKey:@"NSAltIncValue"];
		[self setFloatValue:[decoder decodeFloatForKey:@"NSValue"]];
		//		[self setDoubleValue:[decoder decodeDoubleForKey:@"NSValue"]];
		_sliderType=[decoder decodeIntForKey:@"NSSliderType"];
		_numberOfTickMarks=[decoder decodeIntForKey:@"NSNumberOfTickMarks"];
		_allowTickMarkValuesOnly=[decoder decodeBoolForKey:@"NSAllowsTickMarkValuesOnly"];
		_tickMarkPosition=[decoder decodeIntForKey:@"NSTickMarkPosition"];
		return self;
		}
	[decoder decodeValuesOfObjCTypes:"ff@f", &_minValue, &_maxValue, &_contents, &_altIncrementValue];
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
			n=rint(n);	// round to nearest integer
			value=n*dist+_minValue;
		}
	return value;
}

- (NSInteger) indexOfTickMarkAtPoint:(NSPoint) point;
{
	NIMP;
	return NSNotFound;
}

- (BOOL) allowsTickMarkValuesOnly;					{ return _allowTickMarkValuesOnly; }
- (NSInteger) numberOfTickMarks;					{ return _numberOfTickMarks; }
- (void) setAllowsTickMarkValuesOnly:(BOOL) flag;	{ _allowTickMarkValuesOnly=flag; }
- (void) setNumberOfTickMarks:(NSInteger) num;		{ _numberOfTickMarks=num > 0?num:0; }
- (void) setSliderType:(NSSliderType) sliderType;	{ _sliderType=sliderType; }
- (NSSliderType) sliderType;						{ return _sliderType; }

- (CGFloat) _floatValueForMousePoint:(NSPoint)point knobRect:(NSRect)knobRect flipped:(BOOL) isFlipped;
{
	CGFloat minValue = [self minValue];
	CGFloat maxValue = [self maxValue];
	CGFloat floatValue;
	if ([self isVertical])
		{
		floatValue = (point.y - _slotRect.origin.y - knobRect.size.height/2) / (_slotRect.size.height - knobRect.size.height);
		if (isFlipped)
			floatValue = 1 - floatValue;
		}
	else
		floatValue = (point.x - _slotRect.origin.x- knobRect.size.width/2) / (_slotRect.size.width - knobRect.size.width);
	if(floatValue < 0.0) floatValue=0.0;	// limit to valid range
	else if(floatValue > 1.0) floatValue=1.0;
	return floatValue * (maxValue - minValue) + minValue;
}

// FIXME: we should save the value until tracking ends successfully!

- (BOOL) startTrackingAt:(NSPoint)startPoint	// coordinate inside control
				  inView:(NSView*)control
{ // we want to know tracking positions and have the knob follow where we are
	BOOL isFlipped=[control isFlipped];
	CGFloat v;
	v=[self _floatValueForMousePoint:startPoint knobRect:[self knobRectFlipped:isFlipped] flipped:isFlipped];
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

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)untilMouseUp
{
	_slotRect=cellFrame;	// store so that we can calculate relative coordinates in startTrackingAt:inView:
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
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
- (BOOL) isVertical							{ return [_cell isVertical]; }
// NOT TESTED: - (BOOL) isFlipped			{ return YES; }
- (CGFloat) knobThickness					{ return [_cell knobThickness]; }
- (void) setImage:(NSImage*)backgroundImg	{ [_cell setImage:backgroundImg]; }
- (void) setKnobThickness:(CGFloat)aFloat	{ [_cell setKnobThickness:aFloat];}
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
- (NSInteger) indexOfTickMarkAtPoint:(NSPoint) point;	{ return [_cell indexOfTickMarkAtPoint:point]; }
- (double) maxValue							{ return [_cell maxValue]; }
- (double) minValue							{ return [_cell minValue]; }
- (NSInteger) numberOfTickMarks;			{ return [_cell numberOfTickMarks]; }
- (NSRect) rectOfTickMarkAtIndex:(NSInteger) index;	{ return [_cell rectOfTickMarkAtIndex:index]; }
- (void) setAllowsTickMarkValuesOnly:(BOOL)f	{ [_cell setAllowsTickMarkValuesOnly:f]; }
- (void) setAltIncrementValue:(double)aDouble	{ [_cell setAltIncrementValue:aDouble]; }
- (void) setMaxValue:(double)aDouble		{ [_cell setMaxValue:aDouble]; }
- (void) setMinValue:(double)aDouble		{ [_cell setMinValue:aDouble]; }
- (void) setNumberOfTickMarks:(NSInteger) num;	{ [_cell setNumberOfTickMarks:num]; }
- (void) setTickMarkPosition:(NSTickMarkPosition) pos;	{ [_cell setTickMarkPosition:pos]; }
- (NSTickMarkPosition) tickMarkPosition;	{ return [_cell tickMarkPosition]; }
- (double) tickMarkValueAtIndex:(NSInteger) index;	{ return [_cell tickMarkValueAtIndex:index]; }
- (BOOL) acceptsFirstMouse:(NSEvent*)event	{ return YES; }

@end /* NSSlider */
