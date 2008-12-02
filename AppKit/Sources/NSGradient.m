//
//  NSGradient.m
//  AppKit
//
//  Created by Fabian Spillner on 08.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/AppKit.h>


@implementation NSGradient

- (NSColorSpace *) colorSpace; 
{
	return _colorSpace;
}

- (void) drawFromCenter:(NSPoint) startCenterPt 
								 radius:(CGFloat) startRad 
							 toCenter:(NSPoint) endCenterPt 
								 radius:(CGFloat) endRad 
								options:(NSGradientDrawingOptions) opts;
{
}

- (void) drawFromPoint:(NSPoint) startPt 
							 toPoint:(NSPoint) endPt 
							 options:(NSGradientDrawingOptions) opts;
{
}

- (void) drawInBezierPath:(NSBezierPath *) bezPath angle:(CGFloat) ang;
{
	[bezPath addClip];
	[self drawInRect:[bezPath bounds] angle:ang];
}

- (void) drawInBezierPath:(NSBezierPath *) bezPath relativeCenterPosition:(NSPoint) relCenterPt;
{
	[bezPath addClip];
	[self drawInRect:[bezPath bounds] relativeCenterPosition:relCenterPt];
}

- (void) drawInRect:(NSRect) rect angle:(CGFloat) ang;
{
}

- (void) drawInRect:(NSRect) rect relativeCenterPosition:(NSPoint) relCenterPt;
{
}

- (void) getColor:(NSColor **) col 
				 location:(CGFloat *) loc 
					atIndex:(NSInteger) idx;
{
	NSAssert(idx >= 0 && idx <_numberOfColorStops, @"invalid index");
	if(col)
		*col=[_colors objectAtIndex:idx];
	if(loc)
		*loc=_locations[idx];
}

- (id) initWithColors:(NSArray *) colArray;
{
	unsigned i;
	if((self=[self initWithColors:colArray atLocations:NULL colorSpace:[[colArray objectAtIndex:0] colorSpace]]))
			{
				for(i=0; i<_numberOfColorStops; i++)
					_locations[i]=(float)i/(_numberOfColorStops-1);	// evenly spaced
			}
	return self;
}

- (id) initWithColors:(NSArray *) colArray 
					atLocations:(const CGFloat *) locs 
					 colorSpace:(NSColorSpace *) colSpace;
{
	if((self=[super init]))
			{
				_numberOfColorStops=[colArray count];
				NSAssert(_numberOfColorStops >= 2, @"needs at least 2 locations");
				_colors=[colArray retain];
				_locations=objc_malloc(sizeof(_locations[0])*_numberOfColorStops);
				if(locs)
					memcpy(_locations, locs, sizeof(_locations[0])*_numberOfColorStops);
				_colorSpace=[colSpace retain];
			}
	return self;
}

- (void) dealloc;
{
	[_colorSpace release];
	[_colors release];
	objc_free(_locations);
	[super dealloc];
}

- (id) initWithColorsAndLocations:(NSColor *) color, ...;
{
	return NIMP;
}

- (id) initWithStartingColor:(NSColor *) startCol endingColor:(NSColor *) endCol;
{
	return [self initWithColors:[NSArray arrayWithObjects:startCol, endCol, nil]];
}

- (NSColor *) interpolatedColorAtLocation:(CGFloat) loc;
{
	return nil;
}

- (NSInteger) numberOfColorStops;
{
	return _numberOfColorStops;
}

@end
