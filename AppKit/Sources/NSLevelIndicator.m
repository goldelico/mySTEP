/* 
 NSLevelIndicator.m
 
 Text field control and cell classes
 
 Author:  Nikolaus Schaller <hns@computer.org>
 Date:    April 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import <AppKit/NSLevelIndicatorCell.h>
#import <AppKit/NSLevelIndicator.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

// missing: enable for user modifications/track

@implementation NSLevelIndicatorCell

- (id) initWithLevelIndicatorStyle:(NSLevelIndicatorStyle) style;
{
	if((self=[super init]))
		{
		_d.verticallyCentered=YES;
		_c.alignment=NSCenterTextAlignment;
		_style=style;
		_maxValue=10.0;
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSLevelIndicatorCell *c = [super copyWithZone:zone];
	// copy values
	return c;
}

- (void) dealloc;
{
	[_image release];
	[super dealloc];
}

- (NSSize) cellSize;
{
	// sum up all widths and use default height for controlSize
	NIMP; return NSZeroSize;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
	NSColor *fillColor;
	double val=(_value-_minValue)/(_maxValue-_minValue);
	BOOL vertical=(cellFrame.size.height > cellFrame.size.width);
	if(_value < _warningValue)
		fillColor=[NSColor greenColor];
	else if(_value < _criticalValue)
		fillColor=[NSColor yellowColor];
	else
		fillColor=[NSColor redColor];
	if(_numberOfTickMarks != 0)
		{
		float x;
		float y0, y1;
		float step=_numberOfTickMarks > 1?(cellFrame.size.width-1.0)/(_numberOfTickMarks-1):1.0;
		int tick;
		if(_tickMarkPosition == NSTickMarkBelow)
			{
			cellFrame.origin.y+=8.0;
			cellFrame.size.height-=8.0;
			y0=4.0;
			y1=8.0;
			}
		else
			{
			cellFrame.size.height-=8.0;
			y0=cellFrame.size.height;
			y1=y0+4.0;
			}
		[[NSColor darkGrayColor] set];
		for(x=0.0, tick=0; tick <= _numberOfTickMarks; x+=step, tick++)
			{
			[NSBezierPath strokeLineFromPoint:NSMakePoint(x, y0) toPoint:NSMakePoint(x, y1)];
			// draw _numberOfMajorTickMarks thick ticks (ignore if more than _numberOfTickMarks)
			}
		}
	switch(_style)
		{
		case NSDiscreteCapacityLevelIndicatorStyle:
			{
				int segments=(int) (_maxValue-_minValue);
				float step=(segments > 0?((vertical?cellFrame.size.height:cellFrame.size.width)/segments):10.0);	// width of one segment
				int i;
				int ifill=val*segments+0.5;
				for(i=0; i<segments; i++)
					{ // draw segments
					NSRect seg=cellFrame;
					if(vertical)
						{
						seg.size.height=step-1.0;
						seg.origin.y+=i*step;
						}
					else
						{
						seg.size.width=step-1.0;
						seg.origin.x+=i*step;
						}
					if(i < ifill)
						[fillColor set];
					else
						[[NSColor controlBackgroundColor] set];
					// we could also fill with a scaled horizontal/vertical image
					NSRectFill(seg);
					[[NSColor lightGrayColor] set];
					NSFrameRect(seg);	// draw border
					}
				break;
			}
		case NSContinuousCapacityLevelIndicatorStyle:
			{
				NSRect ind, fill;
				if(vertical)
					NSDivideRect(cellFrame, &ind, &fill, cellFrame.size.height*val, NSMinYEdge);
				else
					NSDivideRect(cellFrame, &ind, &fill, cellFrame.size.width*val, NSMinXEdge);
				[fillColor set];
				// we could also fill with a scaled horizontal/vertical image
				NSRectFill(ind);
				[[NSColor controlBackgroundColor] set];
				NSRectFill(fill);
				[[NSColor lightGrayColor] set];
				NSFrameRect(cellFrame);	// draw border
				break;
			}
		case NSRelevancyLevelIndicatorStyle:
			{
				[[NSColor controlBackgroundColor] set];
				NSRectFill(cellFrame);
				[[NSColor darkGrayColor] set];
				if(vertical)
					{
					float y;
					float yfill=val*cellFrame.size.height+0.5;
					for(y=0.0; y<yfill; y+=2.0)
						[NSBezierPath strokeLineFromPoint:NSMakePoint(0.0, y) toPoint:NSMakePoint(cellFrame.size.width, y)];
					}
				else
					{
					float x;
					float xfill=val*cellFrame.size.width+0.5;
					for(x=0.0; x<xfill; x+=2.0)
						[NSBezierPath strokeLineFromPoint:NSMakePoint(x, 0.0) toPoint:NSMakePoint(x, cellFrame.size.height)];
					}
				break;
			}
		case NSRatingLevelIndicatorStyle:
			{
				NSImage *indicator=_image;
				NSSize isize;
				if(!indicator)
					indicator=[NSImage imageNamed:@"NSRatingLevelIndicator"];	// default
				isize=[indicator size];
				[[NSColor controlBackgroundColor] set];
				NSRectFill(cellFrame);
				if(vertical)
					{
					int y;
					for(y=0.0; y<(val+0.5); y++)
						{
						NSPoint pos=NSMakePoint(0, y*isize.height+2.0);
						if(pos.y >= cellFrame.size.height)
							break;
						// here we can strech the image as needed by using drawInRect:
						[indicator drawAtPoint:pos fromRect:(NSRect){NSZeroPoint, isize} operation:NSCompositeCopy fraction:1.0];
						}
					}
				else
					{
					int x;
					for(x=0.0; x<(val+0.5); x++)
						{
						NSPoint pos=NSMakePoint(x*isize.width+2.0, 0.0);
						if(pos.x >= cellFrame.size.width)
							break;
						[indicator drawAtPoint:pos fromRect:(NSRect){NSZeroPoint, isize} operation:NSCompositeCopy fraction:1.0];
						}
					}
			}
		}
}

- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView*)controlView
{ // we don't have/use this method...
	return;	// do nothing
}

- (double) criticalValue; { return _criticalValue; }
- (NSLevelIndicatorStyle) style; { return _style; }
- (NSImage *) image; { return _image; }
- (double) maxValue; { return _maxValue; }
- (double) minValue; { return _minValue; }
- (int) numberOfMajorTickMarks; { return _numberOfMajorTickMarks; }
- (int) numberOfTickMarks; { return _numberOfTickMarks; }

- (NSRect) rectOfTickMarkAtIndex:(int) index;
{
	NIMP; return NSZeroRect;
}

- (void) setCriticalValue:(double) val; { _criticalValue=val; }
- (void) setImage:(NSImage *) image; { ASSIGN(_image, image); }
- (void) setLevelIndicatorStyle:(NSLevelIndicatorStyle) style; { _style=style; }
- (void) setMaxValue:(double) val; { _maxValue=val; }
- (void) setMinValue:(double) val; { _minValue=val; }
- (void) setNumberOfMajorTickMarks:(int) count; { _numberOfMajorTickMarks=count; }
- (void) setNumberOfTickMarks:(int) count; { _numberOfTickMarks=count; }
- (void) setTickMarkPosition:(NSTickMarkPosition) pos; { _tickMarkPosition=pos; }
- (void) setWarningValue:(double) val; { _warningValue=val; }
- (NSTickMarkPosition) tickMarkPosition; { return _tickMarkPosition; }

- (double) tickMarkValueAtIndex:(int) index;
{
	return _minValue+(index*(_maxValue-_minValue))/_numberOfTickMarks;
}

- (double) warningValue; { return _warningValue; }

- (float) floatValue; { return _value; }
- (double) doubleValue; { return _value; }
- (void) setFloatValue:(float) val; { _value=val; }
- (void) setDoubleValue:(double) val; { _value=val; }

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
	NIMP;
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		{ [self release]; return nil; }
	_minValue=[aDecoder decodeDoubleForKey:@"NSMinValue"];
	_warningValue=[aDecoder decodeDoubleForKey:@"NSWarningValue"];
	_criticalValue=[aDecoder decodeDoubleForKey:@"NSCriticalValue"];
	_maxValue=[aDecoder decodeDoubleForKey:@"NSMaxValue"];
	_value=[aDecoder decodeDoubleForKey:@"NSValue"];
	_style=[aDecoder decodeIntForKey:@"NSIndicatorStyle"];
	_numberOfMajorTickMarks=[aDecoder decodeIntForKey:@"NSNumberOfMajorTickMarks"];
	_numberOfTickMarks=[aDecoder decodeIntForKey:@"NSNumberOfTickMarks"];
	_tickMarkPosition=[aDecoder decodeIntForKey:@"NSTickMarkPosition"];
#if 0
	NSLog(@"%@ initWithCoder:%@", self, aDecoder);
#endif
	return self;
}

// tracking

@end

@implementation NSLevelIndicator

- (double) criticalValue; { return [_cell criticalValue]; }
- (double) maxValue; { return [_cell maxValue]; }
- (double) minValue; { return [_cell minValue]; }
- (int) numberOfMajorTickMarks; { return [_cell numberOfMajorTickMarks]; }
- (int) numberOfTickMarks; { return [_cell numberOfTickMarks]; }
- (NSRect) rectOfTickMarkAtIndex:(int) index; { return [_cell rectOfTickMarkAtIndex:index]; }
- (void) setCriticalValue:(double) val; { [_cell setCriticalValue:val]; }
- (void) setMaxValue:(double) val; { [_cell setMaxValue:val]; }
- (void) setMinValue:(double) val; { [_cell setMinValue:val]; }
- (void) setNumberOfMajorTickMarks:(int) count; { [_cell setNumberOfMajorTickMarks:count]; }
- (void) setNumberOfTickMarks:(int) count; { [_cell setNumberOfTickMarks:count]; }
- (void) setTickMarkPosition:(NSTickMarkPosition) pos; { [_cell setTickMarkPosition:pos]; }
- (void) setWarningValue:(double) val; { [_cell setWarningValue:val]; }
- (NSTickMarkPosition) tickMarkPosition; { return [_cell tickMarkPosition]; }
- (double) tickMarkValueAtIndex:(int) index; { return [_cell tickMarkValueAtIndex:index]; }
- (double) warningValue; { return [_cell warningValue]; }

@end

