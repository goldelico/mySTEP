//
//  NSGradient.h
//  AppKit
//
//  Created by Fabian Spillner on 08.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NSUInteger NSGradientDrawingOptions;

enum {
	NSGradientDrawsBeforeStartingLocation =   (1 << 0),
	NSGradientDrawsAfterEndingLocation =    (1 << 1),
};

@class NSBezierPath;
@class NSColor;
@class NSColorSpace;

@interface NSGradient : NSObject {

}

- (NSColorSpace *) colorSpace; 
- (void) drawFromCenter:(NSPoint) startCenterPt 
			 	 radius:(CGFloat) startRad 
			   toCenter:(NSPoint) endCenterPt 
				 radius:(CGFloat) endRad 
			    options:(NSGradientDrawingOptions) opts;
- (void) drawFromPoint:(NSPoint) startPt 
			   toPoint:(NSPoint) endPt 
			   options:(NSGradientDrawingOptions) opts;
- (void) drawInBezierPath:(NSBezierPath *) bezPath angle:(CGFloat) ang;
- (void) drawInBezierPath:(NSBezierPath *) bezPath relativeCenterPosition:(NSPoint) relCenterPt;
- (void) drawInRect:(NSRect) rect angle:(CGFloat) ang;
- (void) drawInRect:(NSRect) rect relativeCenterPosition:(NSPoint) relCenterPt;
- (void) getColor:(NSColor **) col 
		 location:(CGFloat *) loc 
		  atIndex:(NSInteger) idx;
- (id) initWithColors:(NSArray *) colArray;
- (id) initWithColors:(NSArray *) colArray 
		  atLocations:(const CGFloat *) locs 
		   colorSpace:(NSColorSpace *) colSpace;
- (id) initWithColorsAndLocations:(NSColor *) color, ...;
- (id) initWithStartingColor:(NSColor *) startCol endingColor:(NSColor *) endCol;
- (NSColor *) interpolatedColorAtLocation:(CGFloat) loc;
- (NSInteger) numberOfColorStops;

@end
