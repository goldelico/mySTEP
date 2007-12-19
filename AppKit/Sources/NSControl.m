/* 
   NSControl.m

   Abstract control class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date:    August 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSGeometry.h> 
#import <Foundation/NSNotification.h>

#import <AppKit/NSControl.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSActionCell.h>

#import "NSAppKitPrivate.h"

// Class variables
static Class __controlCellClass = Nil;

@implementation NSControl

+ (void) initialize
{
	if (self == [NSControl class])
		__controlCellClass = [NSActionCell class];
}

+ (Class) cellClass						{ return __controlCellClass; }
+ (void) setCellClass:(Class)aClass		{ __controlCellClass = aClass; }

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame:frameRect]))
		{
		[self setCell:[[[isa cellClass] new] autorelease]];	// allows to override cellClass in subclasses
		}
	return self;
}

- (void) dealloc
{
    [self setCell:nil];										// release our cell
 	[self setDelegate:nil];	
	[super dealloc];
}

- (void) setCell:(NSCell*)aCell	{ ASSIGN(_cell, aCell); }
- (id) cell						{ return _cell; }
- (id) selectedCell				{ return _cell; }
- (BOOL) isEnabled				{ return [[self selectedCell] isEnabled]; }
- (void) setEnabled:(BOOL)flag	{ [[self selectedCell] setEnabled:flag]; }
- (void) setNeedsDisplay		{ [self setNeedsDisplay:YES]; }
- (void) setFont:(NSFont*)font	{ [_cell setFont:font]; }
- (NSFont*) font				{ return [_cell font]; }
- (int) selectedTag				{ return [[self selectedCell] tag]; }
- (int) intValue				{ return [[self selectedCell] intValue]; }
- (NSInteger) integerValue		{ return [[self selectedCell] integerValue]; }
- (float) floatValue			{ return [[self selectedCell] floatValue]; }
- (double) doubleValue			{ return [[self selectedCell] doubleValue]; }
- (NSString*) stringValue		{ return [[self selectedCell] stringValue]; }
- (NSAttributedString*) attributedStringValue		{ return [[self selectedCell] attributedStringValue]; }
- (id) objectValue				{ return [[self selectedCell] objectValue]; }
- (id) formatter;				{ return [[self selectedCell] formatter]; }

- (void) setFormatter:(NSFormatter *) newFormatter;
{
	[[self selectedCell] setFormatter:newFormatter];
	[self setNeedsDisplay];
}

- (void) setObjectValue:(id <NSCopying>)anObject
{
	NSCell *cell=[self selectedCell];
#if 0
	NSLog(@"setObjectValue 1");
#endif
	[cell setObjectValue:anObject];
#if 0
	NSLog(@"setObjectValue 2");
#endif
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
#if 0
	NSLog(@"setObjectValue 3");
#endif
}

- (void) setStringValue:(NSString*)aString
{
	NSCell *cell=[self selectedCell];
#if 0
	NSLog(@"%@: setStringValue:%@", self, aString);
#endif
	if([[cell stringValue] isEqualToString:aString])
		return;	// does not change
	[cell setStringValue:aString];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) setAttributedStringValue:(NSAttributedString*)aString
{
	NSCell *cell=[self selectedCell];
	[cell setAttributedStringValue:aString];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) setDoubleValue:(double)aDouble
{
	NSCell *cell=[self selectedCell];
	[cell setDoubleValue:aDouble];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) setFloatValue:(float)aFloat
{
	NSCell *cell=[self selectedCell];
	[cell setFloatValue:aFloat];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) setIntValue:(int)anInt
{
	NSCell *cell=[self selectedCell];
	[cell setIntValue:anInt];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) setIntegerValue:(NSInteger)anInt
{
	NSCell *cell=[self selectedCell];
	[cell setIntegerValue:anInt];
	if(cell && ![cell isKindOfClass:[NSActionCell class]])
		[self updateCellInside:cell];	// mark for needing update
}

- (void) takeDoubleValueFrom:(id)sender
{
	[[self selectedCell] takeDoubleValueFrom:sender];
	[self setNeedsDisplay];
}

- (void) takeFloatValueFrom:(id)sender
{
	[[self selectedCell] takeFloatValueFrom:sender];
	[self setNeedsDisplay];
}

- (void) takeIntValueFrom:(id)sender
{
	[[self selectedCell] takeIntValueFrom:sender];
	[self setNeedsDisplay];
}

- (void) takeIntegerValueFrom:(id)sender
{
	[[self selectedCell] takeIntegerValueFrom:sender];
	[self setNeedsDisplay];
}

- (void) takeStringValueFrom:(id)sender
{
	[[self selectedCell] takeStringValueFrom:sender];
	[self setNeedsDisplay];
}

- (void) takeObjectValueFrom:(id)sender					// override NSControl
{
	[[self selectedCell] takeObjectValueFrom:sender];
	[self setNeedsDisplay];
}

- (NSTextAlignment) alignment
{ 
	return (_cell != nil) ? [_cell alignment] : NSLeftTextAlignment;
}

- (void) setAlignment:(NSTextAlignment)mode
{
	if(_cell)
		{
		[_cell setAlignment:mode];
		[self setNeedsDisplay];
		}
}

- (void) setFloatingPointFormat:(BOOL)autoRange
						   left:(unsigned)leftDigits
						   right:(unsigned)rightDigits
{
	[[self selectedCell] setFloatingPointFormat:autoRange left:leftDigits right:rightDigits];
}

- (BOOL) abortEditing
{
	NSText *t=[_window fieldEditor:NO forObject:_cell];
#if 1
	NSLog(@"abort editing %@ - %@", self, t);
#endif
	if(!t)
		return NO;
	if([t delegate] != self)
		return NO;	// someone else owns...
	[[self selectedCell] endEditing:t];
	[_window makeFirstResponder:self];
	return YES;
}

- (NSText*) currentEditor
{
	NSText *t = [_window fieldEditor:NO forObject:_cell];
#if 1
	NSLog(@"self=%@", self);
	NSLog(@"cell=%@", _cell);
	NSLog(@"currentEditor=%@", t);
	NSLog(@"[t delegate]=%@", [t delegate]);
	NSLog(@"[window firstResponder]=%@", [_window firstResponder]);
#endif
//	return ([t delegate] == self && [window firstResponder] == self) ? t : nil;
	return ([t delegate] == self && [_window firstResponder] == t) ? t : nil;
}

- (void) validateEditing
{
	NSText *t = [_window fieldEditor:NO forObject:_cell];
#if 1
	NSLog(@"validateEditing t=%@ - value=%@", t, [t string]);
#endif
	if([t delegate] != self)
		return;	// editing someone else
	if([t isRichText])
		{
		// FIXME: get attributed string
		}
	[_cell setStringValue:[t string]];
}

- (void) calcSize	{ return; }	// may override in subclass
- (void) sizeToFit	{ return; }

- (void) drawRect:(NSRect)rect
{
	[_cell drawWithFrame:(NSRect){NSZeroPoint, _bounds.size} inView:self]; 
}

- (void) drawCell:(NSCell*)aCell
{
	if (_cell == aCell)
		{
		[self lockFocus];
		[_cell drawWithFrame:_bounds inView:self];
		[self unlockFocus];
		}
}

- (void) drawCellInside:(NSCell*)aCell
{
	if (_cell == aCell)
		{
		[self lockFocus];
		[_cell drawInteriorWithFrame:_bounds inView:self];
		[self unlockFocus];
		}
}

- (void) selectCell:(NSCell*)aCell			
{ 
	if (_cell == aCell) 
		[_cell setState:1];
}

- (BOOL) sendAction:(SEL)action to:(id)target				// Target / Action
{
	return [NSApp sendAction:action to:target from:self];
}

- (void) setIgnoresMultiClick:(BOOL)flag	{ _ignoresMultiClick=flag; }
- (BOOL) ignoresMultiClick					{ return _ignoresMultiClick; }
- (BOOL) isContinuous						{ return [_cell isContinuous]; }
- (void) setContinuous:(BOOL)flag			{ [_cell setContinuous:flag]; }

- (void) updateCell:(NSCell*)aCell
{
#if 0
	NSLog(@"%@ updateCell:%@", self, aCell);
#endif
	[self setNeedsDisplay:YES];
#if 0
	NSLog(@"setNeedsDisplay done");
#endif
}

- (void) updateCellInside:(NSCell*)aCell
{
#if 0
	NSLog(@"%@ updateCellInside:%@", self, aCell);
#endif
	[self setNeedsDisplay:YES];
}

- (void) setTag:(int)anInt					{ _tag = anInt; }
- (int) tag									{ return _tag; }
- (int) sendActionOn:(int)msk				{ return [(NSCell *) _cell sendActionOn:msk];}
- (SEL) action								{ return [_cell action]; }
- (void) setAction:(SEL)aSelector			{ [_cell setAction:aSelector]; }
- (id) target								{ return [_cell target]; }
- (void) setTarget:(id)anObject				{ [_cell setTarget:anObject]; }
- (NSMenu *) menu							{ return [_cell menu]; }
- (void) setMenu:(NSMenu *)menu				{ [_cell setMenu:menu]; }
- (BOOL) refusesFirstResponder;				{ return _refusesFirstResponder; }
- (void) setRefusesFirstResponder:(BOOL)flag; { _refusesFirstResponder=flag; }
- (BOOL) acceptFirstResponder;				{ return !_refusesFirstResponder; }
- (NSWritingDirection) baseWritingDirection; { return [_cell baseWritingDirection]; }
- (void) setBaseWritingDirection:(NSWritingDirection) direction; { [_cell setBaseWritingDirection:direction]; }
- (void) performClick:(id) sender;		{ [_cell performClick:sender]; }

- (void) mouseDown:(NSEvent*)event
{
#if 0
	NSLog(@"NSControl mouseDown");
#endif
	if(![self isEnabled])
		return;	// If we are not enabled then ignore the mouse
	if(_ignoresMultiClick && [event clickCount] > 1)
		{
		[super mouseDown:event];	// will try to forward to next responder
		return;
		}
	while([event type] != NSLeftMouseUp)	// loop outside until mouse goes up 
		{
		NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
#if 0
		NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
		if(NSMouseInRect(p, _bounds, [self isFlipped]))
			{ // highlight cell
			BOOL done;
			[_cell setHighlighted:YES];	
			[self setNeedsDisplay:YES];
#if 0
			NSLog(@"NSControl mouseDown highlighted");
#endif
			done=[_cell trackMouse:event
					  inRect:_bounds
					  ofView:self
					  untilMouseUp:[[_cell class] prefersTrackingUntilMouseUp]];
			[_cell setHighlighted:NO];	
			[self setNeedsDisplay:YES];
#if 0
			NSLog(@"NSControl mouseDown lowlighted, done=%@", done?@"YES":@"NO");
#endif
			if(done)
				break;
			}

		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];

  		}
#if 0
	NSLog(@"NSControl mouseDown up");
#endif
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeValueOfObjCType: "i" at: &_tag];
	[aCoder encodeObject: _cell];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_cell = [[aDecoder decodeObjectForKey:@"NSCell"] retain];
		[self setTag:[aDecoder decodeIntForKey:@"NSTag"]];	// might be different from cell's tag
		if([aDecoder containsValueForKey:@"NSTarget"])	// cell might not understand!
			[self setTarget:[aDecoder decodeObjectForKey:@"NSTarget"]];
		if([aDecoder containsValueForKey:@"NSAction"])
			[self setAction:NSSelectorFromString([aDecoder decodeObjectForKey:@"NSAction"])];
		if([aDecoder containsValueForKey:@"NSFont"])	// cell might not understand!
			[self setFont:[aDecoder decodeObjectForKey:@"NSFont"]];
	// FIXME: this appears to be broken or at least inconsistent...
		if([aDecoder containsValueForKey:@"NSEnabled"])
			{
#if 1
			NSLog(@"%@", self);
			NSLog(@"[self isEnabled]=%@", [self isEnabled]?@"YES":@"NO");
			NSLog(@"NSEnabled=%@", [aDecoder decodeBoolForKey:@"NSEnabled"]?@"YES":@"NO");
#endif
			[self setEnabled:[aDecoder decodeBoolForKey:@"NSEnabled"]];	// enable/disable current cell (unless setEnabled is overwritten)
			}
		return self;
		}
	[aDecoder decodeValueOfObjCType: "i" at: &_tag];
	_cell = [[aDecoder decodeObject] retain];
	
	return self;
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return NO; }	// don't start inking in controls

- (NSPoint) locationOfPrintRect:(NSRect) rect
{
	// check current print operation and add margins
	return rect.origin;
}

// these methods are private interface for some subclasses

- (id) delegate								{ return _delegate; }

- (void) setDelegate:(id)anObject
{
	NSNotificationCenter *n;
	
	if(_delegate == anObject)
		return;	// unchanged
	
#define IGNORE_(notif_name) [n removeObserver:_delegate \
										 name:NSControlText##notif_name##Notification \
									   object:self]
		
		n = [NSNotificationCenter defaultCenter];
	if (_delegate)
		{
		IGNORE_(DidEndEditing);
		IGNORE_(DidBeginEditing);
		IGNORE_(DidChange);
		}
	
	ASSIGN(_delegate, anObject);
	if(anObject)
		{
#define OBSERVE_(notif_name) \
	if ([_delegate respondsToSelector:@selector(controlText##notif_name:)]) \
		[n addObserver:_delegate \
			  selector:@selector(controlText##notif_name:) \
				  name:NSControlText##notif_name##Notification \
				object:self]
		
		OBSERVE_(DidEndEditing);
		OBSERVE_(DidBeginEditing);
		OBSERVE_(DidChange);
		}
}

@end
