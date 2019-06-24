/* 
   NSBox.m

   Box view that can display a border and title

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   Author:  H. N. Schaller <hns@computer.org>
   Date: 2006 - adapted to latest Cocoa style and behaviour
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSEnumerator.h>

#import <AppKit/NSBezierPath.h>
#import <AppKit/NSBox.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSTextFieldCell.h>

#import "NSAppKitPrivate.h"

@implementation NSBox

- (NSRect) _calcSizes
{ // returns contentRect
	NSRect r;
	NSSize title = (_bx.titlePosition == NSNoTitle) ? NSZeroSize : [_titleCell cellSize];	// ask cell what it needs
	NSSize border;
#if 0
	NSLog(@"NSBox title cell size = %@ for %@", NSStringFromSize(title), [_titleCell title]);
#endif
	switch(_bx.borderType)
		{
		case NSGrooveBorder:
		case NSBezelBorder: border = NSMakeSize(3,3);	break;
		case NSLineBorder: 	border = NSMakeSize(0,0);	break;
		case NSNoBorder:
		default:			border = NSZeroSize;		break;
		}

#if 0
	NSLog(@"NSBox _calcSizes");
	NSLog(@"frame=%@", NSStringFromRect([self frame]));
	NSLog(@"bounds=%@", NSStringFromRect([self bounds]));
	NSLog(@"border=%@", NSStringFromSize(border));
	NSLog(@"_offsets=%@", NSStringFromSize(_offsets));
	NSLog(@"_borderRect=%@", NSStringFromRect(_borderRect));
#endif

	_borderRect = NSInsetRect(_bounds, border.width, border.height);	// move everything inwards if needed
	title.width += 1;						// Add spacer around title
	title.height += 1;
	_titleRect.origin.x=_borderRect.origin.x + 3;
	_titleRect.origin.y=_borderRect.origin.y;	// default position
	_titleRect.size = title;

	switch (_bx.titlePosition)
		{
		case NSNoTitle:				// Add the _offsets to border rect
			break;
		case NSAboveTop:
		case NSBelowTop:
		case NSAtTop:
			{
				_borderRect.size.height -= title.height;	// Adjust by the title size
				_titleRect.origin.y = NSMaxY(_borderRect);	// above border box
				break;
			}
		case NSAboveBottom:
		case NSAtBottom:
		case NSBelowBottom:
			{
				_borderRect.size.height -= title.height;
				_borderRect.origin.y += title.height;
				break;
			}
		}
	r = NSInsetRect(_borderRect, _offsets.width/2.0, _offsets.height/2.0);	// move inwards by offset
	r.origin=_borderRect.origin;
#if 0
	NSLog(@"_titleRect=%@", NSStringFromRect(_titleRect));
	NSLog(@"content rect=%@", NSStringFromRect(r));
#endif
	return r;
}

- (id) initWithFrame:(NSRect)frameRect
{
#if 0
	NSLog(@"%@ initWithFrame:%@", NSStringFromClass([self class]), NSStringFromRect(frameRect));
#endif
	if((self=[super initWithFrame:frameRect]))
		{	
		_titleCell = [[NSTextFieldCell alloc] initTextCell:@"Title"];
		[_titleCell setAlignment: NSCenterTextAlignment];
		[_titleCell setBordered: NO];
		[_titleCell setEditable: NO];
		[_titleCell setBackgroundColor: [NSColor controlBackgroundColor]];
		_offsets = (NSSize){5,5};	// defaults
		_borderRect = _bounds;
		_bx.borderType = NSLineBorder;
		_bx.titlePosition = NSAtTop;
		[self addSubview:[[[NSView alloc] initWithFrame:[self _calcSizes]] autorelease] positioned:NSWindowAbove relativeTo:nil];	// don't call our diversion to the contentView
		}
	return self;
}

- (void) dealloc
{
	[_titleCell release];
	[super dealloc];
}

// Border+Title attribs
- (NSColor *) borderColor;				{ return NIMP; }
- (NSRect) borderRect					{ return _borderRect; }
- (NSBorderType) borderType				{ return _bx.borderType; }
- (CGFloat) borderWidth;				{ NIMP; return 0; }

- (void) setBorderType:(NSBorderType)aType
{
	if (_bx.borderType != aType)
		{
		_bx.borderType = aType;
		[[self contentView] setFrame: [self _calcSizes]];
		[self setNeedsDisplay: YES];
		}
}

- (NSBoxType) boxType				{ return _bx.boxType; }

- (NSColor *) fillColor;	{ return NIMP; }

- (void) setBorderWidth:(CGFloat) width;
{
	NIMP;
}

- (void) setBoxType:(NSBoxType)aType
{
	if (_bx.boxType != aType)
		{
		_bx.boxType = (unsigned int) aType;
		[[self contentView] setFrame: [self _calcSizes]];
		[self setNeedsDisplay: YES];
		}
}

- (void) setContentView:(NSView *)aView
{
	NSView *contentView=[self contentView];
	if(aView == contentView)
		return;
	if(aView)
		{
		if(contentView)
			[self replaceSubview:contentView with:aView];	// replace first
		else
			[super addSubview:aView positioned:NSWindowAbove relativeTo:nil];	// don't call our diversion to the contentView
		}
	else if([contentView superview] == self)
		{
		[[contentView retain] autorelease];
		[contentView removeFromSuperview];	// if I am still the owner, just remove
		}
	[contentView setFrame:[self _calcSizes]];
	[contentView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
	[contentView setAutoresizesSubviews:YES];
}

- (void) setFillColor:(NSColor *) color;
{
	NIMP;
}

- (void) setTitle:(NSString *)aString
{
	[_titleCell setStringValue:aString];
	[[self contentView] setFrame: [self _calcSizes]];
	[self setNeedsDisplay: YES];
}

- (void) setTitleWithMnemonic:(NSString *)aString
{
	[self setTitle:aString];
}

- (void) setTitleFont:(NSFont *)fontObj
{
	[_titleCell setFont:fontObj];
	[[self contentView] setFrame: [self _calcSizes]];
	[self setNeedsDisplay: YES];
}

- (void) setTitlePosition:(NSTitlePosition)aPosition
{
	if (_bx.titlePosition != aPosition)
		{
		_bx.titlePosition = aPosition;
		[[self contentView] setFrame: [self _calcSizes]];
		[self setNeedsDisplay: YES];
		}
}

- (void) setBorderColor:(NSColor *) color;
{
	NIMP;
}

- (void) setCornerRadius:(CGFloat) radius;
{
	NIMP;
}

- (NSString *) title					{ return [_titleCell stringValue]; }
- (id) titleCell						{ return _titleCell; }
- (id) contentView						{ return [[self subviews] lastObject]; }	// assume there is only one
- (NSFont *) titleFont					{ return [_titleCell font]; }
- (NSRect) titleRect					{ return _titleRect; }
- (NSSize) contentViewMargins			{ return _offsets; }
- (NSTitlePosition) titlePosition		{ return _bx.titlePosition; }
- (CGFloat) cornerRadius;				{ NIMP; return 0; }

- (void) setContentViewMargins:(NSSize)offsetSize
{
	_offsets = offsetSize;
#if 0 	// doc says this call does not automatically resize the view!
	[[self contentView] setFrame: [self _calcSizes]];
	[self setNeedsDisplay: YES];
#endif
}
														// Resizing the Box 
- (void) setFrameFromContentFrame:(NSRect)contentFrame
{												// First calc the sizes to see
	NSRect r = [self _calcSizes];				// how much we are off by 
	NSRect f = [self frame];					// Add difference to the frame
	f.size.width += (contentFrame.size.width - r.size.width);
	f.size.height += (contentFrame.size.height - r.size.height);
	[self setFrame: f];
}

- (void) sizeToFit
{
	NSView *contentView=[self contentView];
	if(contentView)
		{
		if([contentView respondsToSelector:_cmd])
			{ // ask the content view to fit
			[contentView sizeToFit];
			[self setFrameFromContentFrame:[contentView frame]];
			}
		else
			{ // calculate the union of the content views
			NSRect r = NSZeroRect;
			id o, e = [[contentView subviews] objectEnumerator];
			while ((o = [e nextObject]))
				r = NSUnionRect(r, [o frame]);	// Loop through subviews and calculate union rect to encompass all	
			[self setFrameFromContentFrame: r];
			}
		}
}

- (void) resizeSubviewsWithOldSize:(NSSize)oldSize
{ // special handling of our content view
	NSView *contentView=[self contentView];
	[contentView setFrame: [self _calcSizes]];	// resize so that they match our current size
	[contentView setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)rect							// Draw the box
{
#if 0	// testing
	[[NSColor redColor] set];
	NSFrameRect(_bounds);
#endif	
	if(_bx.titlePosition != NSNoTitle)
		{ // Draw the title
		[_titleCell setBackgroundColor: [_window backgroundColor]];
		[_titleCell drawWithFrame: _titleRect inView: self];
		}
	switch(_bx.boxType)
		{
		case NSBoxSeparator:
			{ // horizontal or vertical line
#if 0
				NSLog(@"line for %@", NSStringFromRect(_bounds));
#endif
				[[NSColor blackColor] set];
				if(_bounds.size.width > _bounds.size.height)
					[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(_bounds), NSMidY(_bounds)) toPoint:NSMakePoint(NSMaxX(_bounds), NSMidY(_bounds))];	// horizontal
				else
					[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMidX(_bounds), NSMinY(_bounds)) toPoint:NSMakePoint(NSMidX(_bounds), NSMaxY(_bounds))];	// vertical
				break;
			}
		case NSBoxPrimary:
		case NSBoxSecondary:
		case NSBoxOldStyle:
			{
			switch(_bx.borderType)								// Draw the border
				{
				case NSLineBorder:
					{
						// can we be transparent?
						[[_window backgroundColor] set];
						NSRectFill(rect);			// fill with standard control background
						[[NSColor blackColor] set];
						NSFrameRect(_borderRect);	// draw black line border
						break;
					}
				case NSBezelBorder:
				case NSGrooveBorder:
					{
						// we could/should cache the path and clear the cache by _calcSizes
						NSBezierPath *b=[NSBezierPath _bezierPathWithBoxBezelInRect:_borderRect radius:6.0];
						if(!_bx.transparent)
							{
							[[NSColor controlHighlightColor] set];
							[b fill];	// draw box background
							}
						[[NSColor lightGrayColor] set];
						[b stroke];	// stroke border line
					}
				case NSNoBorder:
					break;
				}
			}
		}
}

- (BOOL) isTransparent; { return _bx.transparent; }
- (void) setTransparent:(BOOL) flag; { _bx.transparent = flag; }

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{
	[super encodeWithCoder:aCoder];	// make it not encode the subviews?
	
	[aCoder encodeObject: _titleCell];
	[aCoder encodeObject: [self contentView]];
	[aCoder encodeSize: _offsets];
	[aCoder encodeRect: _borderRect];
	[aCoder encodeRect: _titleRect];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_bx];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
#if 0
	NSLog(@"NSBox initWithCoder");
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_offsets = [aDecoder decodeSizeForKey:@"NSOffsets"];
		_bx.borderType = [aDecoder decodeIntForKey:@"NSBorderType"];
		_bx.boxType = [aDecoder decodeIntForKey:@"NSBoxType"];
		_bx.titlePosition = [aDecoder decodeIntForKey:@"NSTitlePosition"];
		_bx.transparent=[aDecoder decodeBoolForKey:@"NSTransparent"];
		/*	??? =  */ [aDecoder decodeBoolForKey:@"IBNSBoxIsUsingDocumentContentView"];
#if 0
		NSLog(@"offsets=%@", NSStringFromSize(_offsets));
		NSLog(@"borderType=%d", _bx.borderType);
		NSLog(@"boxType=%d", _bx.boxType);
		NSLog(@"titlePosition=%d", _bx.titlePosition);
		NSLog(@"transparent=%d", _bx.transparent);
#endif
		[self setContentView:[aDecoder decodeObjectForKey:@"NSContentView"]];		// decode and insert
		_titleCell = [[aDecoder decodeObjectForKey:@"NSTitleCell"] retain];
#if 0
		NSLog(@"contentView=%@", [[self contentView] _subtreeDescription]);
#endif		
		[self _calcSizes];	// recalculate _titleRect with latest _titleCell
		return self;
		}
	
	_titleCell = [[aDecoder decodeObject] retain];
	// _contentView = [[aDecoder decodeObject] retain];
	_offsets = [aDecoder decodeSize];
	_borderRect = [aDecoder decodeRect];
	_titleRect = [aDecoder decodeRect];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_bx];
	return self;
}

@end
