/* 
NSStringDrawing.m
 
 Draw and Measure categories of NSString and NSAttributedString 
 
 Copyright (C) 1997 Free Software Foundation, Inc.
 
 Author:  Felipe A. Rodriguez <far@ix.netcom.com>
 Date:    Aug 1998
 
 Author:	H. N. Schaller <hns@computer.org>
 Date:		2005-2007 changed to use NSLayoutManager
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <AppKit/NSStringDrawing.h>
#import <AppKit/AppKit.h>

// can be removed for new implementation:

#import "NSBackendPrivate.h"

@implementation NSString (NSStringDrawingAdditions)

- (NSRect) boundingRectWithSize:(NSSize)size
						options:(NSStringDrawingOptions)options
					 attributes:(NSDictionary *)attributes;
{
	NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attributes];
	NSRect r=[a boundingRectWithSize:size options:options];		// get rect of attributed string
	[a release];			// no longer needed
	return r;
}

- (void) drawAtPoint:(NSPoint)point
	  withAttributes:(NSDictionary *)attrs;
{
	NSRect r=[self boundingRectWithSize:NSMakeSize(16000.0, 16000.0) options:0 attributes:attrs];	// start with infinite box
	r.origin=point; // move to given origin
//	if([[NSGraphicsContext currentContext] isFlipped])
//		r.origin.y-=r.size.height;
	[self drawWithRect:r options:0 attributes:attrs];
}

- (void) drawInRect:(NSRect)rect withAttributes:(NSDictionary *)attrs;
{
	[self drawWithRect:rect options:0 attributes:attrs];
}

- (void) drawWithRect:(NSRect)rect
			  options:(NSStringDrawingOptions)options
		   attributes:(NSDictionary *)attributes;
{
#if 0
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSLog(@"drawWithRect");
	{
#endif
		NSAttributedString *a=[[NSAttributedString alloc] initWithString:self attributes:attributes];
		[a drawWithRect:rect options:options];	// draw as attributed string
		[a release];							// no longer needed
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
	[a release];			// no longer needed
	return size;
}

@end

@implementation NSAttributedString (NSAttributedStringDrawingAdditions)

// FIXME: make this thread-safe by locking (in setup) and unlocking (after use)

static NSTextStorage *_textStorage;
static NSLayoutManager *_layoutManager;
static NSTextContainer *_textContainer;
static NSAttributedString *_currentString;

- (void) _setupWithRect:(NSRect) rect options:(NSStringDrawingOptions) options;
{
	/*
	 potential options - it appears that they control the NSFont substitution
	 NSStringDrawingUsesLineFragmentOrigin
	 NSStringDrawingUsesFontLeading 
	 NSStringDrawingDisableScreenFontSubstitution
	 NSStringDrawingUsesDeviceMetrics - screenFontWithRenderingMode:NSFontIntegerAdvancementsRenderingMode
	 NSStringDrawingOneShot	- don't cache
	 */
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
		[_textContainer setContainerSize:rect.size];	// resize container
		[_textStorage setAttributedString:self];		// replace
		}
#if 0
	NSLog(@"self = %@", self);
	NSLog(@"_textStorage = %@", _textStorage);
	NSLog(@"_textContainer = %@", _textContainer);
#endif
	[_currentString release];
	_currentString=[self retain];
}

- (NSRect) boundingRectWithSize:(NSSize) size
						options:(NSStringDrawingOptions) options;
{
	if([self length] == 0)
		return NSZeroRect;	// empty string
	[self _setupWithRect:(NSRect) { NSZeroPoint, size } options:options];	// create a text container from given size
	return [_layoutManager boundingRectForGlyphRange:[_layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
																			actualCharacterRange:NULL]
									 inTextContainer:_textContainer];
	// FIXME: handle oneshot option...
}

- (void) drawAtPoint:(NSPoint) point;
{
	NSRect r=[self boundingRectWithSize:NSMakeSize(16000.0, 16000.0) options:0];	// start with infinite box
	r.origin=point; // move to given origin
	[self drawWithRect:r options:0];
}

- (void) drawInRect:(NSRect) rect;
{
	[self drawWithRect:rect options:0];
}

- (void) drawWithRect:(NSRect) rect options:(NSStringDrawingOptions) options;
{ // draw with line breaks within box defined by rect - might clip if lines are too long
	NSGraphicsContext *ctxt;
	NSRange rng;
	if([self length] == 0)
		return;	// empty string
	[self _setupWithRect:rect options:options];
	ctxt=[NSGraphicsContext currentContext];
	[ctxt saveGraphicsState];
	[NSBezierPath clipRect:rect];	// set clipping rect
	if(![ctxt isFlipped])
		rect.origin.y+=rect.size.height;	// start at top of rect (drawGlyphsForGlyphRange expects flipped coordinates)
#if 0
	NSLog(@"drawWithRect:options: %@", self);
#endif
#if 1
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
	rng=[_layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
							   actualCharacterRange:NULL];
	[_layoutManager drawBackgroundForGlyphRange:rng atPoint:rect.origin];
	[_layoutManager drawGlyphsForGlyphRange:rng atPoint:rect.origin];
	[ctxt restoreGraphicsState];
	if(options&NSStringDrawingOneShot)
			{ // remove
				[_textStorage release];
				_textStorage=nil;
				_layoutManager=nil;
				_textContainer=nil;
			}
}

- (NSSize) size;
{
#if 0
	if([self length] == 0)
		return NSZeroSize;	// empty string
	[self _setupWithRect:(NSRect) { NSZeroPoint, { 16000.0, 16000.0 } } options:0];	// start with a very large text container
	return [_layoutManager boundingRectForGlyphRange:[_layoutManager glyphRangeForCharacterRange:NSMakeRange(0, [_textStorage length])
																			actualCharacterRange:NULL]
									 inTextContainer:_textContainer].size;	// get really required bounding box
#else
	return [self boundingRectWithSize:NSMakeSize(16000.0, 16000.0) options:0].size;
#endif
}

@end
