/* 
   NSActionCell.m

   Abstract cell class for target/action paradigm

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:    1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSActionCell.h>
#import <AppKit/NSControl.h>

#import <Foundation/NSCoder.h>

// class variables
static Class __controlClass;

@implementation NSActionCell

+ (void) initialize
{
	if(self == [NSActionCell class])
		__controlClass = [NSControl class];
}

- (void) setAlignment:(NSTextAlignment)mode
{
	[super setAlignment:mode];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setBezeled:(BOOL)flag
{
	[super setBezeled:flag];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setBordered:(BOOL)flag
{
	[super setBordered:flag];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setEnabled:(BOOL)flag
{
	[super setEnabled:flag];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setFloatingPointFormat:(BOOL)autoRange
						   left:(unsigned int)leftDigits
						   right:(unsigned int)rightDigits
{
	[super setFloatingPointFormat:autoRange left:leftDigits right:rightDigits];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setFont:(NSFont *)fontObject
{
	[super setFont:fontObject];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell:self];
}

- (void) setImage:(NSImage *)image
{
	[super setImage:image];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell:self];
}

- (void) setStringValue:(NSString *)aString
{
#if 0
	NSLog(@"%@: setStringValue:%@", self, aString);
#endif
	[super setStringValue:aString];
#if 0
	NSLog(@"	_controlView:%@", _controlView);
	NSLog(@"	__controlClass:%@", NSStringFromClass(__controlClass));
#endif
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell:self];
}

- (void) setDoubleValue:(double)aDouble
{
	[super setDoubleValue:aDouble];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell:self];
}

- (void) setFloatValue:(float)aFloat
{
	[super setFloatValue:aFloat];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setIntValue:(int)anInt
{
	[super setIntValue:anInt];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

- (void) setObjectValue:(id <NSCopying>)obj
{
	[super setObjectValue:obj];
	if (_controlView && ([_controlView isKindOfClass: __controlClass]))
		[(NSControl *)_controlView updateCell: self];
}

// Target / Action
- (SEL) action							{ return action; }
- (int) tag								{ return tag; }
- (id) target							{ return target; }
- (void) setAction:(SEL)aSelector		{ action = aSelector; }
- (void) setTag:(int)anInt				{ tag = anInt; }
- (void) setTarget:(id)anObject			{ target = anObject; }

- (id) copyWithZone:(NSZone *) zone;
{
	NSActionCell *c = [super copyWithZone:zone];
	if(c)
		{
		c->action = action;
		c->tag = tag;
		c->target = target;
		}
	return c;
}

- (void) encodeWithCoder:(NSCoder *) aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeValueOfObjCType:"i" at:&tag];
	[aCoder encodeConditionalObject:target];
	[aCoder encodeValueOfObjCType:@encode(SEL) at:&action];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		tag = [aDecoder decodeIntForKey:@"NSTag"];
#if 0
		NSLog(@"NSActionCell - tag=%d", tag);
#endif
		target = [[aDecoder decodeObjectForKey:@"NSTarget"] retain];
		action = NSSelectorFromString([aDecoder decodeObjectForKey:@"NSAction"]);
		return self;
		}
	[aDecoder decodeValueOfObjCType:"i" at:&tag];
	target = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType:@encode(SEL) at:&action];
	return self;
}

@end /* NSActionCell */
