/* 
 NSStepper.m
 
 Text field control and cell classes
 
 Author:  Nikolaus Schaller <hns@computer.org>
 Date:    April 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>

#import <AppKit/NSStepperCell.h>
#import <AppKit/NSStepper.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSBezierPath.h>

#import "NSAppKitPrivate.h"

@implementation NSStepperCell

// draw two vertical arrow triangle buttons
// enable/disable if stuck at max/min
// update [self doubleValue] by increment;

- (id) init;
{
	if((self=[super init]))
		{
		_maxValue=59.0;
		_increment=1.0;
		_autorepeat=YES;
		_valueWraps=YES;
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSStepperCell *c = [super copyWithZone:zone];
	// copy values
	return c;
}

- (void) dealloc;
{
	[_upCell release];
	[_downCell release];
	[super dealloc];
}

- (NSSize) cellSize;
{
	// sum up all widths and use default height for controlSize
	NIMP; return NSZeroSize;
}

- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView*) controlView
{
	NSRect upper, lower;
#if 0
	NSLog(@"drawInteriorWithFrame %@", self);
#endif
	NSDivideRect(cellFrame, &upper, &lower, cellFrame.size.height/2.0, NSMaxYEdge);	// split by 2
	if(!_downCell)
		{ // allocate button cells
		int i;
		for(i=0; i<2; i++)
			{
			NSButtonCell *c=[[NSButtonCell alloc] init];
			[c setImage:[NSImage imageNamed:i==0?@"GSArrowUp":@"GSArrowDown"]];
			[c setAlternateImage:[NSImage imageNamed:i==0?@"GSArrowUpH":@"GSArrowDownH"]];
			[c setImagePosition:NSImageOnly];
			[c setTarget:self];
			[c setAction:i==0?@selector(_increment:):@selector(_decrement:)];
			[c setBezelStyle:NSRegularSquareBezelStyle];
			[c setButtonType:NSMomentaryChangeButton];	// ???
			[c setPeriodicDelay:0.5 interval:0.1];
			if(i==0)
				_upCell=c;
			else
				_downCell=c;
			}
		}
	[_upCell drawInteriorWithFrame:upper inView:controlView];
	[_downCell drawInteriorWithFrame:lower inView:controlView];
}

/*- (void) drawWithFrame:(NSRect)frame inView:(NSView*)controlView
{ // we don't have this method...
}
*/

- (BOOL) trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{ // check if we should forward to subcell
	NSPoint loc=[event locationInWindow];
	loc = [controlView convertPoint:loc fromView:nil];	// convert to controlView's coordinates
	NSLog(@"NSStepperCell trackMouse:%@ inRect:%@", NSStringFromPoint(loc), NSStringFromRect(cellFrame));
	// FIXME: do we need to know if [controlView isFlipped]?
	if(loc.y-cellFrame.origin.y > cellFrame.size.height/2.0)
		return [_upCell trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
	else
		return [_downCell trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];
}

- (BOOL) autorepeat; { return _autorepeat; }	// after 0.5 seconds with 0.1 seconds distance
- (double) increment; { return _increment; }
- (double) maxValue; { return _maxValue; }
- (double) minValue; { return _minValue; }
- (void) setAutorepeat:(BOOL) flag; { _autorepeat=flag; }
- (void) setIncrement:(double) val; { _increment=val; }
- (void) setMaxValue:(double) val; { _maxValue=val; }
- (void) setMinValue:(double) val; { _minValue=val; }
- (void) setValueWraps:(BOOL) flag; { _valueWraps=flag; }
- (BOOL) valueWraps; { return _valueWraps; }

- (float) floatValue; { return _value; }
- (double) doubleValue; { return _value; }
- (void) setFloatValue:(float) val; { _value=val; }
- (void) setDoubleValue:(double) val; { _value=val; }

- (IBAction ) _increment:(id) sender;
{
	[self willChangeValueForKey:@"Value"];
	_value+=_increment;
	if(_value > _maxValue)
		_value=_valueWraps?_minValue:_maxValue;
	[self didChangeValueForKey:@"Value"];
}

- (IBAction ) _decrement:(id) sender;
{
	[self willChangeValueForKey:@"Value"];
	_value-=_increment;
	if(_value < _minValue)
		_value=_valueWraps?_maxValue:_minValue;
	[self didChangeValueForKey:@"Value"];
}

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
	_autorepeat=[aDecoder decodeBoolForKey:@"NSAutorepeat"];
	_valueWraps=[aDecoder decodeBoolForKey:@"NSValueWraps"];
	_increment=[aDecoder decodeDoubleForKey:@"NSIncrement"];
	_minValue=[aDecoder decodeDoubleForKey:@"NSMinValue"];
	_maxValue=[aDecoder decodeDoubleForKey:@"NSMaxValue"];
	_value=[aDecoder decodeDoubleForKey:@"NSValue"];
#if 0
	NSLog(@"%@ initWithCoder:%@", self, aDecoder);
#endif
	return self;
}

@end

@implementation NSStepper

- (BOOL) autorepeat; { return [_cell autorepeat]; }
- (double) increment; { return [_cell increment]; }
- (double) maxValue; { return [_cell maxValue]; }
- (double) minValue; { return [_cell minValue]; }
- (void) setAutorepeat:(BOOL) flag; { [_cell setAutorepeat:flag]; }
- (void) setIncrement:(double) val; { [_cell setIncrement:val]; }
- (void) setMaxValue:(double) val; { [_cell setMaxValue:val]; }
- (void) setMinValue:(double) val; { [_cell setMinValue:val]; }
- (void) setValueWraps:(BOOL) flag; { [_cell setValueWraps:flag]; }
- (BOOL) valueWraps; { return [_cell valueWraps]; }

@end

