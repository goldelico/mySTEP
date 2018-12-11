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

static BOOL _NSShowStringDrawingBox=NO;
static NSStringDrawingOptions _currentOptions;

static NSTextStorage *_textStorage;
static NSLayoutManager *_layoutManager;
static NSTextContainer *_textContainer;
static NSAttributedString *_currentString;

// can be boiled down to one
static NSTextView *_textView;

/* FIXME:
 * make thread-safe (why?)
 * use separate caches for sizing (infinite box) and drawing (finite box)
 * cache NSTextView objects, i.e. create complete layout networks
 * and access [view textStorage], [view layoutManager], [view textContainer]
 */

@implementation NSAttributedString (NSAttributedStringDrawingAdditions)

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
	if(!_textStorage)
		{ // first call: setup text system
			// FIXME: should be a default and not an ENV variable
			char *flag=getenv("QSShowStringDrawingBox");
			if(flag) _NSShowStringDrawingBox=strcmp(flag, "YES") == 0;
#if 0
			NSLog(@"create global text storage");
#endif
			// FIXME: we should simply create one NSTextView or multiple cached view
			_textStorage=[[NSTextStorage alloc] initWithAttributedString:self];			// store a copy
			NSAssert(!_currentString, @"current string left over");
			_currentString=[self retain];	// store first string
			NSAssert(!_textContainer, @"text container left over");
			_textContainer=[[NSTextContainer alloc] initWithContainerSize:rect.size];	// predefine the size of the container
			NSAssert(!_layoutManager, @"layout manager left over");
			_layoutManager=[NSLayoutManager new];
			[_layoutManager addTextContainer:_textContainer];
			[[_layoutManager typesetter] setTypesetterBehavior:NSTypesetterBehavior_10_2_WithCompatibility];	// our typesetter ignores that...
			[_textContainer release];	// is retained by _layoutManager
			[_textStorage addLayoutManager:_layoutManager];
			[_layoutManager release];	// is retained by _textStorage
			_textView=[[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];
			[_textContainer setTextView:_textView];
			[_textView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
										   [NSFont fontWithName:@"Helvetica" size:12],	// this defines the default font if nothing else is known!
										   NSFontAttributeName, nil]];
			// [_textView release];
		}
	else
		{
		// FIXME: we can separate infinitely sized and finitely sized calls
		[_textContainer setContainerSize:rect.size];	// resize container - should invalidate layout but keep glyphs - if it changes
		if(![self isEqual:_currentString])
			{ // has changed
			[_currentString release];
			[_textStorage setAttributedString:self];		// replace - should invalidate glyphs and layout
			_currentString=[self retain];
			}
		}
	[_layoutManager setUsesFontLeading:((_currentOptions&NSStringDrawingUsesFontLeading) != 0)];
	[_layoutManager setUsesScreenFonts:((_currentOptions&NSStringDrawingDisableScreenFontSubstitution) == 0)];
#if 0
	NSLog(@"self = %@", self);
	NSLog(@"_textStorage = %@", _textStorage);
	NSLog(@"_textContainer = %@", _textContainer);
#endif
}

- (void) _tearDown
{
	if(_currentOptions&NSStringDrawingOneShot)
		// for a cache this could mean that we don't cache the NSTextView and (auto)release it when done
		// then, we would not even need the _tearDown method
		{ // remove
			[_currentString release];
			_currentString=nil;
			[_textStorage release];
			_textStorage=nil;
			_layoutManager=nil;
			_textContainer=nil;
			_textView=nil;
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
	NSRect rect=NSZeroRect;	// or should we return the default font height?
	NSRange rng;
	if([self length] > 0)
		{
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
			rng=NSMakeRange(0, NSNotFound);	// will be cut down to textContainer
			rect=[_layoutManager boundingRectForGlyphRange:rng inTextContainer:_textContainer];
			}
		[self _tearDown];		
		}
	return rect;
}

// the point is the origin of the line fragment rect and may
// be at the top left (if flipped) or bottom left corner (if not flipped)
// alignment is ignored and always natural (or left???)
// text always goes downwards on screen and glyphs are not flipped

- (void) drawAtPoint:(NSPoint) point;
{
	if([self length] > 0)
		{
		NSGraphicsContext *ctxt;
		NSRect rect={ NSZeroPoint, { FLT_MAX, FLT_MAX }};
		NSRange rng;
		ctxt=[NSGraphicsContext currentContext];
		if(_NSShowStringDrawingBox)
			{ // show small dot at drawing origin
				NSRect r={ { point.x-2.0, point.y-2.0 }, { 4.0, 4.0 }};
				[ctxt saveGraphicsState];
				[[NSColor brownColor] set];
				NSFrameRect(r);	// drawing origin
				[ctxt restoreGraphicsState];	
			}
		[self _setupWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];	// infinitely large container
#if 0
		NSLog(@"drawAtPoint:%@ %@", NSStringFromPoint(point), self);
#endif
		rng=[_layoutManager glyphRangeForBoundingRect:rect inTextContainer:_textContainer];
		if([ctxt isFlipped])
			{
			[_layoutManager drawBackgroundForGlyphRange:rng atPoint:point];
			[_layoutManager drawGlyphsForGlyphRange:rng atPoint:point];		
			}
		else
			{ // in this case the layout manager draws lines "bootom up" so we must flip the CTM
				static NSAffineTransform *flip=nil;
				NSRect rect=[_layoutManager boundingRectForGlyphRange:rng inTextContainer:_textContainer];
				point.y=-(point.y+rect.size.height);	// start at top of rect (drawGlyphsForGlyphRange assumes flipped coordinates)
				if(!flip)
					{
					flip=[NSAffineTransform transform];
					[flip scaleXBy:1.0 yBy:-1.0];
					[flip retain];
					}
				[ctxt saveGraphicsState];
				[flip concat];	// flip before drawing
				[_layoutManager drawBackgroundForGlyphRange:rng atPoint:point];
				[_layoutManager drawGlyphsForGlyphRange:rng atPoint:point];
				[ctxt restoreGraphicsState];
			}
		[self _tearDown];
		}
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
// text may start at the bottom left (flipped)
// or top left corner (unflipped)
// text always goes downwards on screen
// if NSStringDrawingUsesLineFragmentOrigin is not set,
// only the first line (\n) is considered and size.height is ignored
// size.width defines the maximum line fragment width if (>0.0)
// size.height defines the maximum heighgt for multiple lines (if >0.0) but is
// ignored (except for flipping) if NSStringDrawingUsesLineFragmentOrigin is not set

- (void) drawWithRect:(NSRect) rect options:(NSStringDrawingOptions) options;
{ // draw with line breaks within box defined by rect - might clip if lines are too long
	if([self length] > 0)
		{
		NSGraphicsContext *ctxt;
		NSRange rng;
		ctxt=[NSGraphicsContext currentContext];
#if 0
		{ // Clipping should be done by the layout manager/typesetter by limiting the glyph range. Not by drawing!
			NSRect r=rect;
			if(r.size.width > 1e4) r.size.width=1e4;	// limit to avoid problems with bezier paths
			if(r.size.height > 1e4) r.size.height=1e4;	// limit
			[ctxt saveGraphicsState];
			[NSBezierPath clipRect:rect];	// set clipping rect
		}
#endif
		if(_NSShowStringDrawingBox)
			{ // show string drawing box
				NSRect r=rect;
				if(r.size.width > 1e6) r.size.width=1e6;	// limit to avoid problems with bezier paths
				if(r.size.height > 1e6) r.size.height=1e6;	// limit
				[ctxt saveGraphicsState];
				[[NSColor brownColor] set];
				NSFrameRect(r);	// drawing rect
				[ctxt restoreGraphicsState];	
			}
		if(!(options&NSStringDrawingUsesLineFragmentOrigin))
			rect.size.width=FLT_MAX;	// single line mode
		[self _setupWithRect:rect options:options];
#if 0
		NSLog(@"drawWithRect:%@ options:%d %@", NSStringFromRect(rect), options, self);
#endif
		rng=[_layoutManager glyphRangeForBoundingRect:(NSRect) { NSZeroPoint, rect.size } inTextContainer:_textContainer];
		if([ctxt isFlipped])
			{
			[_layoutManager drawBackgroundForGlyphRange:rng atPoint:rect.origin];
			[_layoutManager drawGlyphsForGlyphRange:rng atPoint:rect.origin];		
			}
		else
			{ // in this case the layout manager draws lines "bootom up" so we must flip the CTM
				static NSAffineTransform *flip=nil;
				if(!flip)
					{
					flip=[NSAffineTransform transform];
					[flip scaleXBy:1.0 yBy:-1.0];
					[flip retain];
					}
				[ctxt saveGraphicsState];
				[flip concat];	// flip before drawing
				rect.origin.y=-NSMaxY(rect);	// start at top of rect (drawGlyphsForGlyphRange assumes flipped coordinates)
				[_layoutManager drawBackgroundForGlyphRange:rng atPoint:rect.origin];
				[_layoutManager drawGlyphsForGlyphRange:rng atPoint:rect.origin];
				[ctxt restoreGraphicsState];
			}
#if 0
		[ctxt restoreGraphicsState];
#endif
		[self _tearDown];
		}
}

- (NSSize) size;
{
	return [self boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin].size;
}

@end

@implementation NSString (NSStringDrawingAdditions)

- (NSRect) boundingRectWithSize:(NSSize) size
						options:(NSStringDrawingOptions) options
					 attributes:(NSDictionary *) attributes;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attributes];
	NSRect r;
	[a _setupWithRect:(NSRect) { NSZeroPoint, size } options:options];	// create a text container from given size
	[[_textContainer textView] setTypingAttributes:attributes];	// needed to handle empty strings
	r=[a boundingRectWithSize:size options:options];	// get rect of attributed string
	[a release];	// no longer needed
	return r;
}

- (void) drawAtPoint:(NSPoint) point
	  withAttributes:(NSDictionary *) attrs;
{
	if([self length] > 0)
		{
		NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
		[a drawAtPoint:point];	// draw as attributed string
		[a release];	// no longer needed
		}
}

- (void) drawInRect:(NSRect)rect withAttributes:(NSDictionary *) attrs;
{
	if([self length] > 0)
		{
		NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
		[a drawWithRect:rect options:NSStringDrawingUsesLineFragmentOrigin];
		[a release];	// no longer needed
		}
}

- (void) drawWithRect:(NSRect)rect
			  options:(NSStringDrawingOptions)options
		   attributes:(NSDictionary *) attrs;
{
	if([self length] > 0)
		{
		NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attrs];
		[a drawWithRect:rect options:options];	// draw as attributed string
		[a release];	// no longer needed
		}
}

- (NSSize) sizeWithAttributes:(NSDictionary *) attrs;
{
	return [self boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attrs].size;
}

@end
