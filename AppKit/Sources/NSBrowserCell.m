/* 
   NSBrowserCell.m

   NSBrowser's default cell class

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: 	October 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSObject.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSBrowserCell.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSWindow.h>

// Class variables
static NSImage *__branchImage;
static NSImage *__highlightBranchImage;


@implementation NSBrowserCell

+ (void) initialize
{
	__branchImage = [[NSImage imageNamed: @"GSRight"] retain];
	__highlightBranchImage = [[NSImage imageNamed: @"GSRightH"] retain];
}

+ (NSImage *) branchImage				{ return __branchImage; }
+ (NSImage *) highlightedBranchImage	{ return __highlightBranchImage; }

- (id) init									
{ 
	if((self=[self initTextCell: @"aBrowserCell"]))
		{
		[self setImage:[isa branchImage]];	// default
		[self setAlternateImage:[isa highlightedBranchImage]];	// default
		}
	return self;
}

- (id) initTextCell:(NSString *)aString
{
#if 0
	NSLog(@"NSBrowserCell initTextCell");
#endif
	if((self=[super initTextCell: aString]))
		{
#if 0
		if([self isEnabled])
			NSLog(@"NSBrowserCell isEnabled");
		NSLog(@"NSBrowserCell initTextCell _textColor=%@", _textColor);
#endif
		_c.alignment = NSLeftTextAlignment;
		_c.selectable = YES;
		_c.bezeled = NO;
		_c.bordered = NO;
		_c.enabled = YES;
		[self setLeaf:NO];		// default to non-leaf
		}
	return self;
}

- (void) dealloc
{
	[_branchImage release];
	[_highlightBranchImage release];
	
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSBrowserCell *c = [super copyWithZone:zone];

	c->_branchImage = [_branchImage retain];
	c->_highlightBranchImage = [_highlightBranchImage retain];

	return c;
}

- (void) setImage:(NSImage *)anImage
{												// set image to display
	ASSIGN(_branchImage, anImage);				// when not highlighted
}

- (void) setAlternateImage:(NSImage *)anImage
{														// set image to display
	ASSIGN(_highlightBranchImage, anImage);				// when highlighted
}

- (NSImage *) image					{ return _branchImage; }
- (NSImage *) alternateImage		{ return _highlightBranchImage; }
- (BOOL) isLeaf						{ return _d.isLeaf; }
- (BOOL) isLoaded					{ return _d.isLoaded; }
- (void) setLoaded:(BOOL)flag		{ _d.isLoaded = flag; }
- (void) reset						{ _c.highlighted = _c.state = NO; }
- (void) set						{ _c.highlighted = _c.state = YES; }

- (void) setLeaf:(BOOL)flag			{ _d.isLeaf = flag; }

- (void) drawInteriorWithFrame:(NSRect)cellFrame 		// draw the cell
						inView:(NSView *)controlView
{
	NSCompositingOperation op;
	NSImage *image;

	[_textColor release];
	if (_c.highlighted || _c.state != NSOffState)
		{
		image = _highlightBranchImage;
		op = NSCompositeHighlight;
		_textColor = [NSColor selectedMenuItemTextColor];
		}									
	else
		{	
		image = _branchImage;
		op = NSCompositeSourceOver;
		_textColor = [NSColor controlTextColor];
		}
	[_textColor retain];
	if(image)
		{ // make square room for arrow
		NSRect imageRect = cellFrame;
		imageRect.size.height = cellFrame.size.height;
		imageRect.size.width = imageRect.size.height;   // make it square size
		imageRect.origin.x = NSMaxX(cellFrame) - NSWidth(imageRect);	// right end is the (potential) arrow
		cellFrame.size.width = NSMinX(imageRect)-3.0;					// reduce available cell size
		if(!_d.isLeaf)
			{ // draw the image (centered)
			NSSize size = [image size];
			imageRect.origin.x += (imageRect.size.width - size.width) / 2;
			imageRect.origin.y += (imageRect.size.height - size.height) / 2;
#if 0
			NSLog(@"NSBrowserCell draw image %@", image);
#endif
			[image compositeToPoint:imageRect.origin operation:op];
			}
		}
	[super drawInteriorWithFrame:cellFrame inView:controlView];		// standard drawing
}

- (void) drawWithFrame:(NSRect)cellFrame 		// draw the cell
				inView:(NSView *)controlView
{
	if (_c.highlighted)
		{ // draw highlight
		
		/// here or by NSMatrix?
		
		[[NSColor selectedControlColor] set];
		NSRectFill(cellFrame);
		}
	if (_c.state != NSOffState)
		{ // draw selection
		
		/// here or by NSMatrix?
		
		[[NSColor selectedControlColor] set];
		NSRectFill(cellFrame);
		}
	[super drawWithFrame:cellFrame inView:controlView];
}

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{
	[super encodeWithCoder:aCoder];

	[aCoder encodeObject: _branchImage];
	[aCoder encodeObject: _highlightBranchImage];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		_c.alignment = NSLeftTextAlignment;
		_c.selectable = YES;
		_c.bezeled = NO;
		_c.bordered = NO;
		_c.enabled = YES;
		[self setImage:[isa branchImage]];	// default
		[self setAlternateImage:[isa highlightedBranchImage]];	// default
		[self setLeaf:NO];		// default to non-leaf
		return self;
		}
	_branchImage = [[aDecoder decodeObject] retain];
	_highlightBranchImage = [[aDecoder decodeObject] retain];

	return self;
}

- (NSColor *) highlightColorInView:(NSView *) controlView;
{ // controlView (different NSBrowsers) is ignored unless you override
	return [NSColor highlightColor];
}

@end
