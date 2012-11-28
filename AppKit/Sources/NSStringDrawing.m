/* 
 NSStringDrawing.m
 
 Draw and Measure categories of NSString and NSAttributedString 
 
 Copyright (C) 1997 Free Software Foundation, Inc.
 
 Author:  Felipe A. Rodriguez <far@ix.netcom.com>
 Date:    Aug 1998
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		2005-2012 changed to use NSLayoutManager
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <AppKit/AppKit.h>

@implementation NSString (NSStringDrawingAdditions)

- (NSRect) boundingRectWithSize:(NSSize)size
						options:(NSStringDrawingOptions)options
					 attributes:(NSDictionary *)attributes;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attributes];
	NSRect r=[a boundingRectWithSize:size options:options];	// get rect of attributed string
	[a release];	// no longer needed
	return r;
}

- (void) drawAtPoint:(NSPoint)point
	  withAttributes:(NSDictionary *)attrs;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
	[a drawAtPoint:point];	// draw as attributed string
	[a release];	// no longer needed
}

- (void) drawInRect:(NSRect)rect withAttributes:(NSDictionary *)attrs;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
	[a drawInRect:rect];
	[a release];	// no longer needed
}

- (void) drawWithRect:(NSRect)rect
			  options:(NSStringDrawingOptions)options
		   attributes:(NSDictionary *)attrs;
{
#if 0
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSLog(@"drawWithRect");
	{
#endif
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
	[a drawWithRect:rect options:options];	// draw as attributed string
	[a release];	// no longer needed
#if 0
	}
	[arp release];
	NSLog(@"drawWithRect arp released");
#endif
}

- (NSSize) sizeWithAttributes:(NSDictionary *)attrs;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
	NSSize size=[a size];	// get size of attributed string
	[a release];	// no longer needed
	return size;
}

@end

@implementation NSAttributedString (NSAttributedStringDrawingAdditions)

// FIXME: make this thread-safe by locking (in setup) and unlocking (after use)

static NSTextStorage *_textStorage;
static NSLayoutManager *_layoutManager;
static NSTextContainer *_textContainer;
static NSAttributedString *_currentString;
static NSStringDrawingOptions _currentOptions;

- (void) _setupWithRect:(NSRect) rect options:(NSStringDrawingOptions) options;
{
	/*
	 potential options - it appears that they control the NSFont substitution
	 NSStringDrawingUsesLineFragmentOrigin
	 NSStringDrawingUsesFontLeading 
	 NSStringDrawingDisableScreenFontSubstitution
	 NSStringDrawingUsesDeviceMetrics - screenFontWithRenderingMode:NSFontIntegerAdvancementsRenderingMode
	 NSStringDrawingOneShot	- don't cache
	 NSStringDrawingTruncatesLastVisibleLine - 
	 */
	_currentOptions=options;
	if(self == _currentString)
		return;	// don't change if we size&draw the same string
	if(!_textStorage)
		{
#if 0
		NSLog(@"create global text storage");
#endif
		_textStorage=[[NSTextStorage alloc] initWithAttributedString:self];			// store a copy
		_textContainer=[[NSTextContainer alloc] initWithContainerSize:rect.size];	// predefine the size of the container
		_layoutManager=[NSLayoutManager new];
		[_layoutManager addTextContainer:_textContainer];
		[[_layoutManager typesetter] setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];	// our typesetter ignores that...
		[_textContainer release];	// is retained by _layoutManager
		[_textStorage addLayoutManager:_layoutManager];
		[_layoutManager release];	// is retained by _textStorage
		}
	else
		{
		[_textContainer setContainerSize:rect.size];	// resize container - should invalidate layout
		[_textStorage setAttributedString:self];		// replace - should invalidate glyphs
		}
	[_layoutManager setUsesFontLeading:((_currentOptions&NSStringDrawingUsesFontLeading) != 0)];
	[_layoutManager setUsesScreenFonts:((_currentOptions&NSStringDrawingDisableScreenFontSubstitution) == 0)];
#if 0
	NSLog(@"self = %@", self);
	NSLog(@"_textStorage = %@", _textStorage);
	NSLog(@"_textContainer = %@", _textContainer);
#endif
	[_currentString release];
	_currentString=[self retain];
}

- (void) _tearDown
{
	if(_currentOptions&NSStringDrawingOneShot)
		{ // remove
			[_textStorage release];
			_textStorage=nil;
			_layoutManager=nil;
			_textContainer=nil;
		}
}

// determine the bounding rect when doing the layout for the given size
// if NSStringDrawingUsesLineFragmentOrigin is not set,
// only the first line (\n) is considered and size.height is ignored
// size.width defines the maximum line fragment width if (>0.0)
// size.height defines the maximum heighgt for multiple lines (if >0.0)

- (NSRect) boundingRectWithSize:(NSSize) size
						options:(NSStringDrawingOptions) options;
{
	NSRect rect;
	NSRange rng;
	if([self length] == 0)
		return NSZeroRect;	// empty string
	if(!(options&NSStringDrawingUsesLineFragmentOrigin))
		size.height=FLT_MAX;	// single line mode
	[self _setupWithRect:(NSRect) { NSZeroPoint, size } options:options];	// create a text container from given size
	if(!(options&NSStringDrawingUsesLineFragmentOrigin))
		{
		// FIXME: we need only the bounding box of the first line...
		/* do we simply call
		 [[_layoutManager typesetter] layoutGlyphsInLayoutManager:_layoutManager
			startingAtGlyphIndex:0
		maxNumberOfLineFragments:1
		nextGlyphIndex:&nextGlyph]
		 to create just a single line fragment rect?
		 */
			rng=[_layoutManager glyphRangeForBoundingRect:(NSRect) { NSZeroPoint, size } inTextContainer:_textContainer];
			rect=[_layoutManager boundingRectForGlyphRange:rng inTextContainer:_textContainer];
			rect.origin.y-=[[_layoutManager typesetter] baselineOffsetInLayoutManager:_layoutManager glyphIndex:0];
		}
	else
		{
		rng=[_layoutManager glyphRangeForBoundingRect:(NSRect) { NSZeroPoint, size } inTextContainer:_textContainer];
		rect=[_layoutManager boundingRectForGlyphRange:rng inTextContainer:_textContainer];
		}
	[self _tearDown];
	return rect;
}

// the point is the origin of the line fragment rect and may
// be at the top left (if flipped) or bottom left corner (if not flipped)
// alignment is ignored and always natural (or left?)
// text always goes downwards on screen and glyphs are not flipped

- (void) drawAtPoint:(NSPoint) point;
{
	NSRect r=[self boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin];	// start with infinitely large box
	r.origin=point;			// move to given origin
	r.size.width=FLT_MAX;	// disable horizontal alignment
	[self drawWithRect:r options:NSStringDrawingUsesLineFragmentOrigin];
}

// draws in rect applying text aligment rules
// text always starts at the top line and is
// always going down on screen
// and glyphs are not flipped

- (void) drawInRect:(NSRect) rect;
{
	[self drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];
}

// draws in rect applying text aligment rules
// text may start at the top left (flipped) and go downwards
// or bottom left corner (unflipped) and go upwards
// if NSStringDrawingUsesLineFragmentOrigin is not set,
// only the first line (\n) is considered and size.height is ignored
// size.width defines the maximum line fragment width if (>0.0)
// size.height defines the maximum heighgt for multiple lines (if >0.0) but is
// ignored (except for flipping) if NSStringDrawingUsesLineFragmentOrigin is not set

- (void) drawWithRect:(NSRect) rect options:(NSStringDrawingOptions) options;
{ // draw with line breaks within box defined by rect - might clip if lines are too long
	NSGraphicsContext *ctxt;
	NSRange rng;
	if([self length] == 0)
		return;	// empty string
	ctxt=[NSGraphicsContext currentContext];
	if(![ctxt isFlipped])
		rect.origin.y=NSMaxY(rect);	// start at top of rect (drawGlyphsForGlyphRange assumes flipped coordinates)
#if 1
	// Clipping should be done by the layout manager/typesetter by limiting the glyph range. Not by drawing!
	[ctxt saveGraphicsState];
	[NSBezierPath clipRect:rect];	// set clipping rect
#endif
	if(!(options&NSStringDrawingUsesLineFragmentOrigin))
		rect.size.width=FLT_MAX;	// single line mode
	[self _setupWithRect:rect options:options];
#if 0
	NSLog(@"drawWithRect:options: %@", self);
#endif
#if 0	// only done here for old layoutManager
	{	// FIXME: this should have been processed by layoutManager
		NSParagraphStyle *para=[[self attributesAtIndex:0 effectiveRange:NULL] objectForKey:NSParagraphStyleAttributeName];
		switch([para alignment])
		{
			case NSLeftTextAlignment:
			case NSNaturalTextAlignment:
			break;
			case NSRightTextAlignment:
			case NSCenterTextAlignment:
			case NSJustifiedTextAlignment:
			{
			NSSize size=[_layoutManager boundingRectForGlyphRange:[_layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
																						 actualCharacterRange:NULL]
												  inTextContainer:_textContainer].size;
			if([para alignment] == NSRightTextAlignment)
				rect.origin.x = NSMaxX(rect)-size.width-2.0;	// start at right edge
			else
				rect.origin.x += (rect.size.width-size.width)/2-1.0;	// center
			}
		}
	}
#endif
#if 0
	// FIXME: determine visible glyph range for rect
	rng=[_layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
							   actualCharacterRange:NULL];
#else
	rng=[_layoutManager glyphRangeForBoundingRect:(NSRect) { NSZeroPoint, rect.size } inTextContainer:_textContainer];
#endif
	[_layoutManager drawBackgroundForGlyphRange:rng atPoint:rect.origin];
	[_layoutManager drawGlyphsForGlyphRange:rng atPoint:rect.origin];
	[ctxt restoreGraphicsState];
	[self _tearDown];
}

- (NSSize) size;
{
	return [self boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin].size;
}

@end
