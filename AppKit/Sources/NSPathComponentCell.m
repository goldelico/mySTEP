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

- (NSSize) cellSize;
{
	// calculate from content and image
	NSSize m=[super cellSize];
	if(_image)
		m.width += [_image size].width + 8;
	return m;
}

- (NSRect) imageRectForBounds:(NSRect) cellFrame;
{
	if(_image)
			{
				cellFrame.origin.x=NSMaxX(cellFrame)-20.0;
				cellFrame.size.width=20.0;
			}
	return cellFrame;
}

- (NSRect) titleRectForBounds:(NSRect) cellFrame;
{
	if(_image)
			{ // reduce width
				cellFrame.size.width-=20.0;
			}
	return cellFrame;
}

- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView
{
	NSRect imageRect = [self imageRectForBounds:cellFrame];	// draw image on right part
	NSRect titleRect = [self titleRectForBounds:cellFrame];	// call [super drawWithFrame:left	
	[_image drawInRect:cellFrame fromRect:imageRect operation:NSCompositeSourceOver fraction:1.0];	// first the image
	[[self title] drawInRect:titleRect withAttributes:nil];	// then the text
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
