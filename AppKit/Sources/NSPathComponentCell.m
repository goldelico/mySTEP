//
//  NSPathComponentCell.m
//  AppKit
//
//  Created by Fabian Spillner on 29.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  Implemented by Nikolaus Schaller on 03.03.08.
//

#import <AppKit/AppKit.h>


@implementation NSPathComponentCell

- (id) initTextCell:(NSString *) title
{
	if((self=[super initTextCell:title]))
			{
				[self setBezeled:NO];
				[self setLineBreakMode:NSLineBreakByTruncatingMiddle];
			}
	return self;
}

- (NSSize) cellSize;
{
	NSSize m=[super cellSize];	// calculate from content
	if(_image)
		m.width += [_image size].width + 8;	// and image
	return m;
}

- (NSRect) imageRectForBounds:(NSRect) cellFrame;
{
	if(_image)
			{
				NSSize s=[_image size];
				cellFrame.origin.x=NSMaxX(cellFrame)-s.width-4.0;
				cellFrame.size.width=s.width;
				cellFrame.origin.y += (cellFrame.size.height - s.height)/2;	// vertically centered
				cellFrame.size.height = s.height;
			}
	return cellFrame;
}

- (NSRect) titleRectForBounds:(NSRect) cellFrame;
{
	if(_image)
			{ // reduce width and height
				NSSize s=[_image size];
				cellFrame.size.width -= s.width + 8;
			}
	return cellFrame;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
	NSRect imageRect = [self imageRectForBounds:cellFrame];	// draw image on right part
	NSRect titleRect = [self titleRectForBounds:cellFrame];	// call [super drawWithFrame:left
	[_image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];	// first the image
	[super drawWithFrame:titleRect inView:controlView];	// we are a NSTextFieldCell
}

- (void) dealloc; { [_image release]; [_URL release]; [super dealloc]; }
- (NSImage *) image; { return _image; }
- (void) setImage:(NSImage *) image; { ASSIGN(_image, image); }
- (void) setURL:(NSURL *) url; { ASSIGN(_URL, url); }
- (NSURL *) URL; { return _URL; }

- (id) initWithCoder:(NSCoder *) coder;
{
	if ((self=[super initWithCoder:coder]))
		{
		[self setURL:[coder decodeObjectForKey:@"url"]];
		[self setImage:[coder decodeObjectForKey:@"image"]];
		}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	[coder encodeObject:_URL forKey:@"url"];
	[coder encodeObject:_image forKey:@"image"];
}

@end
