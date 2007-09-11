/*
   NSImageView.m

   Image view and associated image cell class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:	Felipe A. Rodriguez <farz@mindspring.com>
   Date:	January 1999
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <AppKit/NSImageView.h>
#import <AppKit/NSImage.h>

#import "NSAppKitPrivate.h"

// class variables
id __imageCellClass = nil;


//*****************************************************************************
//
// 		NSImageCell 
//
//*****************************************************************************

@implementation NSImageCell

- (id) init									{ return [self initImageCell:nil];}

- (id) copyWithZone:(NSZone *) z
{
	NSImageCell *c = [super copyWithZone:z];
	c->_ic = _ic;
	return c;
}

- (NSImageScaling) imageScaling				{ return _ic.imageScaling; }
- (NSImageAlignment) imageAlignment			{ return _ic.imageAlignment; }
- (NSImageFrameStyle) imageFrameStyle		{ return _ic.imageFrameStyle; }

- (void) setImageScaling:(NSImageScaling)scaling
{
#if 0
	NSLog(@"setImageScaling");
#endif
	_ic.imageScaling = scaling;
	[_contents setScalesWhenResized: (_ic.imageScaling != NSScaleNone)];
#if 0
	NSLog(@"setImageScaling done");
#endif
}

- (void) setImage:(NSImage *)image
{
	[image setScalesWhenResized: (_ic.imageScaling != NSScaleNone)];	// apply current scaling
	[super setImage:image];
}

- (void) setImageAlignment:(NSImageAlignment)alignment
{
	_ic.imageAlignment = alignment;
}

- (void) setImageFrameStyle:(NSImageFrameStyle)frameStyle
{
	_ic.imageFrameStyle = frameStyle;
}

- (NSSize) cellSize
{
	if (!_contents)
		return (NSSize){ 1, 1 };
	if(_ic.imageFrameStyle == NSImageFrameNone) 
		return [_contents size];
	return NSOffsetRect((NSRect){{ 0, 0 }, [_contents size]}, 3, 3).size;
}

- (NSRect) drawingRectForBounds:(NSRect)rect
{
	if(_ic.imageFrameStyle == NSImageFrameNone) 
		return rect;
	return NSInsetRect(rect, 3, 3);
}

- (void) drawWithFrame:(NSRect)cellFrame
				inView:(NSView*)controlView
{
	if (!NSWidth(cellFrame) || !NSHeight(cellFrame))
		return;

	_controlView = controlView;						// Save last view drawn to

	switch (_ic.imageFrameStyle) 
		{												
		case NSImageFrameNone:
			break;
		case NSImageFramePhoto:
			{
			float grays[] = {NSDarkGray,NSDarkGray,NSDarkGray,NSDarkGray,NSBlack,NSBlack};
			NSRect rect = NSDrawTiledRects(cellFrame, cellFrame, BUTTON_EDGES_NORMAL, grays, 6);
			NSRectFill(rect);	// prefill interior
			break;
			}
		case NSImageFrameGrayBezel:
			NSDrawGrayBezel(cellFrame, cellFrame);
			break;
		case NSImageFrameGroove:
			NSDrawGroove(cellFrame, cellFrame);
			break;
		case NSImageFrameButton:
			NSDrawButton(cellFrame, cellFrame);
			break;
		}

	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void) drawInteriorWithFrame:(NSRect)cFrame
						inView:(NSView*)controlView
{
	NSSize is;
	NSRect rect;
	if (!_contents)
		return;
	
	if(![_contents isKindOfClass:[NSImage class]])
		{
		NSLog(@"ImageCell trying to draw: %@", _contents);
		return;
		}
#if 0
	NSLog(@"NSImageCell drawInRect frame=%@", NSStringFromRect(cFrame));
#endif
	rect=[self drawingRectForBounds:cFrame];	// reduce if it has frame
	rect=NSInsetRect(rect, 4, 4);				// keep frame
#if 0
	NSLog(@"NSImageCell drawInRect rect=%@", NSStringFromRect(rect));
#endif
	
	switch (_ic.imageScaling)
		{
		case NSScaleProportionally:
			{
				float d;
				is = [_contents size];
				d = MIN(NSWidth(rect) / is.width, NSHeight(rect) / is.height);
				is.width *= d;
				is.height *= d;
				break;
			}
			
		case NSScaleToFit:
			is = rect.size;
			break;

		case NSScaleNone:
			is = [_contents size];
			break;
		}

	switch (_ic.imageAlignment) 
		{												
		case NSImageAlignCenter:
			rect.origin.x += (NSWidth(rect) - is.width) / 2;
			rect.origin.y += (NSHeight(rect) - is.height) / 2;
			break;

		case NSImageAlignTop:
			rect.origin.x += (NSWidth(rect) - is.width) / 2;
		case NSImageAlignTopLeft:
			rect.origin.y = MAX((NSMaxY(rect) - is.height), NSMinY(rect));
			break;

		case NSImageAlignTopRight:
			rect.origin.x = MAX((NSMaxX(rect) - is.width), NSMinX(rect));
			rect.origin.y = MAX((NSMaxY(rect) - is.height), NSMinY(rect));
			break;

		case NSImageAlignLeft:
			rect.origin.y += (NSHeight(rect) - is.height) / 2;
			break;

		case NSImageAlignBottom:
			rect.origin.x += (NSWidth(rect) - is.width) / 2;
		case NSImageAlignBottomLeft:
			break;

		case NSImageAlignBottomRight:
			rect.origin.x = MAX((NSMaxX(rect) - is.width), NSMinX(rect));
			break;

		case NSImageAlignRight:	
			rect.origin.x = MAX((NSMaxX(rect) - is.width), NSMinX(rect));
			rect.origin.y += (NSHeight(rect) - is.height) / 2;
			break;
		}
#if 0
	NSLog(@"NSImageCell drawInRect %@", NSStringFromRect((NSRect){rect.origin,is}));
#endif
	[_contents drawInRect:(NSRect){rect.origin,is} fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeValueOfObjCType: "S" at: &_ic];
}

- (BOOL) _animates; { return _ic.imageAnimates; }
- (void) _setAnimates:(BOOL) flag; { _ic.imageAnimates=flag; }

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_ic.imageAlignment=[aDecoder decodeIntForKey:@"NSAlign"];
		_ic.imageScaling=[aDecoder decodeIntForKey:@"NSScale"];
		_ic.imageFrameStyle=[aDecoder decodeIntForKey:@"NSStyle"];
		_ic.imageAnimates=[aDecoder decodeBoolForKey:@"NSAnimates"];
		return self;
		}
	[aDecoder decodeValueOfObjCType: "S" at: &_ic];
	
	return self;
}

@end /* NSImageCell */

//*****************************************************************************
//
// 		NSImageView 
//
//*****************************************************************************

@implementation NSImageView

+ (void) initialize
{
	if (self == [NSImageView class]) 
   		__imageCellClass = [NSImageCell class];
}

+ (Class) cellClass						{ return __imageCellClass; }
+ (void) setCellClass:(Class)aClass		{ __imageCellClass = aClass; }

- (id) initWithFrame:(NSRect)frameRect
{
	if(!_cell)
		[self setCell:[[__imageCellClass new] autorelease]];

	return [super initWithFrame:frameRect];
}

- (void) setImageAlignment:(NSImageAlignment)align
{
	[_cell setImageAlignment:align];
}

- (void) setImageScaling:(NSImageScaling)scaling
{
	[_cell setImageScaling:scaling];
}

- (void) setImageFrameStyle:(NSImageFrameStyle)style
{
	[_cell setImageFrameStyle:style];
}

- (NSImage *) image							{ return [_cell image]; }
- (void) setImage:(NSImage *)image			{ [_cell setImage:image]; }
- (void) setEditable:(BOOL)flag				{ [_cell setEditable:flag]; }
- (BOOL) isEditable							{ return [_cell isEditable]; }
- (BOOL) isOpaque							{ return YES; }
- (BOOL) isFlipped							{ return NO; }
- (NSImageScaling) imageScaling				{ return [_cell imageScaling]; }
- (NSImageAlignment) imageAlignment			{ return [_cell imageAlignment]; }
- (NSImageFrameStyle) imageFrameStyle		{ return [_cell imageFrameStyle]; }

- (BOOL) animates;							{ return [_cell _animates]; }
- (void) setAnimates:(BOOL)flag;			{ [_cell _setAnimates:flag]; }
- (BOOL) allowsCutCopyPaste;				{ return _allowsCutCopyPaste; }
- (void) setAllowsCutCopyPaste:(BOOL)flag;	{ _allowsCutCopyPaste=flag; }

- (void) encodeWithCoder:(id)ec				{ [super encodeWithCoder:ec]; }

- (id) initWithCoder:(id)dc
{
#if 0
	NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), dc);
#endif
	if((self=[super initWithCoder:dc]))
		{
		[_cell setEditable:[dc decodeBoolForKey:@"NSEditable"]];
		}
	return self;
}

// first responder methods

#if 0
- (void) mouseDown:(NSEvent*)event
{
	// handle D&D
	// handle first responder selection so that we can delete the image with backspace
	return;
}
#endif

- (void) delete:(id)sender
{ // menu item
	if(_allowsCutCopyPaste)
		[self setImage:nil];
}

- (void) deleteBackward:(id)sender
{ // key
	if(_allowsCutCopyPaste)
		[self setImage:nil];
}

- (void) cut:(id)sender
{
	if(_allowsCutCopyPaste)
		{
		; // copy to pasteboard
		[self setImage:nil];
		}
}

- (void) copy:(id)sender
{
	if(_allowsCutCopyPaste)
		; // copy to pasteboard
}

- (void) paste:(id)sender
{
	if(_allowsCutCopyPaste)
		; // paste from
}

- (BOOL) validateMenuItem:(id <NSMenuItem>)menuItem
{
	NSString *str=NSStringFromSelector([menuItem action]);
	if(!_allowsCutCopyPaste)
		return NO;
	if([str isEqualToString:@"cut:"] ||
	   [str isEqualToString:@"copy:"] ||
	   [str isEqualToString:@"delete:"])
		return [self image] != nil;
	if([str isEqualToString:@"paste:"])
		return YES;	// FIXME: check if we have matching pasteboard type
	return NO;
}

@end /* NSImageView */
