/*
   NSForm.m

   Single column matrix of labeled text fields.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: March 1997
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSForm.h>
#import <AppKit/NSFormCell.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSColor.h>
#import "NSAppKitPrivate.h"


// Class variables
static Class __formCellClass = Nil;


//*****************************************************************************
//
// 		NSFormCell 
//
//*****************************************************************************

@implementation NSFormCell
										 
- (id) init						{ return [self initTextCell:@"Field:"]; }

- (id) initTextCell:(NSString *)aString
{
	self=[super initTextCell:@""];
	if(self)
		{
		_c.bordered = NO;
		_c.bezeled = YES;	// this will draw a white bezel
		_c.editable = YES;
		[self setAlignment:NSLeftTextAlignment];
		_titleWidth = -1;
		_titleCell = [[NSCell alloc] initTextCell:aString];
		[_titleCell setBordered:NO];
		[_titleCell setBezeled:NO];
		[_titleCell setEditable:NO];
		[_titleCell setAlignment:NSRightTextAlignment];
		}
	return self;
}

- (void) dealloc
{
	[_titleCell release];
	_titleCell=nil;
	[super dealloc];	// will call [self setTitle:nil]
}

- (id) copyWithZone:(NSZone *) zone
{
	NSFormCell *c = [super copyWithZone:zone];
	if(c)
		{
		c->_titleWidth = _titleWidth;
		c->_titleCell = [_titleCell copyWithZone:zone];
		}
	return c;
}

- (BOOL) isOpaque
{
	return [super isOpaque] && [_titleCell isOpaque];
}

- (void) setTitle:(NSString*)aString
{
	[_titleCell setStringValue:aString];
}

- (void) setTitleAlignment:(NSTextAlignment)mode
{
	[_titleCell setAlignment:mode];
}

- (void) setTitleFont:(NSFont*)fontObject	{ [_titleCell setFont:fontObject];}
- (void) setTitleWidth:(CGFloat)width			{ _titleWidth = width; }
- (NSString*) title							{ return [_titleCell stringValue];}
- (NSTextAlignment) titleAlignment			{ return [_titleCell alignment]; }
- (NSFont*) titleFont						{ return [_titleCell font]; }

- (CGFloat) titleWidth
{
	if (_titleWidth < 0)
		return [[self title] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[_titleCell font], NSFontAttributeName, nil]].width;
	return _titleWidth;
}

- (CGFloat) titleWidth:(NSSize)aSize
{
	CGFloat w=[self titleWidth];
	if(aSize.width < w)
		return aSize.width;
	return w;
}

- (void) selectWithFrame:(NSRect)aRect					// similar to editWith-
				  inView:(NSView *)controlView	 		// Frame method but can
				  editor:(NSText *)textObject	 		// be called from more
				  delegate:(id)anObject	 				// than just mouseDown
				  start:(NSInteger)selStart
				  length:(NSInteger)selLength
{
	NSRect title, text;

	NSDivideRect(aRect, &title, &text, [self titleWidth] + 4, NSMinXEdge);

	[super selectWithFrame:NSInsetRect(text, 2, 2) 			
					inView:controlView				
					editor:textObject	
				  delegate:anObject
					 start:selStart	 
					length:selLength];
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
	NSRect title, text;

	NSDivideRect(cellFrame, &title, &text, [self titleWidth] + 4, NSMinXEdge);
#if 0
	NSLog(@"draw titleCell %@ inFrame %@", _titleCell, NSStringFromRect(title));
#endif
	[_titleCell drawWithFrame:title inView:controlView];
#if 0
	NSLog(@"draw cell %@ inFrame %@", self, NSStringFromRect(text));
#endif
	[super drawWithFrame:text inView:controlView];
}

- (void) encodeWithCoder:(id)aCoder						// NSCoding protocol
{
	[aCoder encodeObject: _titleCell];
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(id)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		// alternativ NSName und NSTitle?
		_titleWidth=[aDecoder decodeFloatForKey:@"NSTitleWidth"];
		_titleCell=[[aDecoder decodeObjectForKey:@"NSTitleCell"] retain];
		if([aDecoder containsValueForKey:@"NSContents"])
			[self setStringValue:[aDecoder decodeObjectForKey:@"NSContents"]];	// we have a setTitle: method and therefore did not initialize the string value
		[self _setTextColor:[NSColor controlTextColor]];
		[_titleCell _setTextColor:[NSColor controlTextColor]];
#if 0
		NSLog(@"initWithCoder %@ - %@", self, [self stringValue]);
#endif
		return self;
		}
	_titleCell = [aDecoder decodeObject];
	return self;
}

@end /* NSFormCell */

//*****************************************************************************
//
// 		NSForm 
//
//*****************************************************************************

@implementation NSForm

+ (void) initialize
{
	if (self == [NSForm class]) 
		__formCellClass = [NSFormCell class];
}

+ (Class) cellClass							{ return __formCellClass; }
+ (void) setCellClass:(Class)classId		{ __formCellClass = classId; }

- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect
						  mode:NSRadioModeMatrix
					 cellClass:[[self class] cellClass]
				  numberOfRows:0
			   numberOfColumns:1];	// NSForm is a single column matrix...
	if(self)
		{
		_m.drawsBackground=NO;
		}
	return self;
}

- (NSFormCell*) addEntry:(NSString*)title	
{
	return [self insertEntry:title atIndex:[self numberOfRows]];
}

- (NSFormCell*) insertEntry:(NSString*)title atIndex:(NSInteger)index
{
	NSFormCell *new = [[_cellPrototype copy] autorelease];

	[new setTitle:title];
	[self insertRow:index];
	[self putCell:new atRow:index column:0];
	
	return new;
}

- (void) removeEntryAtIndex:(NSInteger)index		{ [self removeRow:index]; }

- (void) setBezeled:(BOOL)flag
{
	NSUInteger i, count = [self numberOfRows];

	[_cellPrototype setBezeled:flag];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setBezeled:flag];
}

- (void) setBordered:(BOOL)flag
{
	NSUInteger i, count = [self numberOfRows];

	[_cellPrototype setBordered:flag];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setBordered:flag];
}

- (void) setEntryWidth:(CGFloat)width
{
	NSSize size = {width, [self cellSize].height};
	[self setCellSize:size];
	[self sizeToCells];	
}

- (void) setInterlineSpacing:(CGFloat)spacing
{
	[self setIntercellSpacing:NSMakeSize(0, spacing)];
}

- (void) setTitleAlignment:(NSTextAlignment)aMode
{
NSInteger i, count = [self numberOfRows];

	[_cellPrototype setTitleAlignment:aMode];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setTitleAlignment:aMode];
}

- (void) setTextAlignment:(NSInteger)aMode
{
	NSInteger i, count = [self numberOfRows];

	[_cellPrototype setAlignment:aMode];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setAlignment:aMode];
}

- (void) setTitleFont:(NSFont*)fontObject
{
	NSInteger i, count = [self numberOfRows];

	[_cellPrototype setTitleFont:fontObject];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setTitleFont:fontObject];
}

- (void) setTextFont:(NSFont*)fontObject
{
	NSInteger i, count = [self numberOfRows];

	[_cellPrototype setFont:fontObject];

	for (i = 0; i < count; i++)
		[[self cellAtRow:i column:0] setFont:fontObject];
}

- (NSInteger) indexOfCellWithTag:(NSInteger)aTag
{
	NSInteger i, count = [self numberOfRows];

	for (i = 0; i < count; i++)
		if ([[self cellAtRow:i column:0] tag] == aTag)
			return i;
	
	return -1;
}

- (NSInteger) indexOfSelectedItem		{ return [self selectedRow]; }
- (id) cellAtIndex:(NSInteger)index		{ return [self cellAtRow:index column:0]; }
- (void) selectTextAtIndex:(NSInteger)idx	{ [self selectTextAtRow:idx column:0]; }

- (void) drawCellAtIndex:(NSInteger)index
{
	id c = [self cellAtIndex:index];
	[c drawWithFrame:[self cellFrameAtRow:index column:0] inView:self];
}

- (void) drawCellAtRow:(NSInteger)row column:(NSInteger)column
{
	[self drawCellAtIndex:row];
}

#if 0	// leads to recursion because setEntryWidth: calls setFrame:
- (void) setFrameSize:(NSSize) size
{
	[self setEntryWidth:size.width];
	[super setFrameSize:size];
}
#endif

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	if((self=[super initWithCoder:aDecoder]))
		{
		[self setTitleFont:[aDecoder decodeObjectForKey:@"NSFont"]];
		}
	return self;
}

@end /* NSForm */
