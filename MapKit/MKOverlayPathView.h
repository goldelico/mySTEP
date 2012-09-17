//
//  MKOverlayPathView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKOverlayView.h>

#if !TARGET_OS_IPHONE
#define UIColor NSColor
#endif

#if defined(__mySTEP__)
typedef NSLineCapStyle CGLineCap;
typedef NSLineJoinStyle CGLineJoin;
typedef NSBezierPath *CGPathRef;
#endif

@interface MKOverlayPathView : MKOverlayView
{
	/* @property (retain) */ UIColor *fillColor;
	/* @property */ CGLineCap lineCap;
	/* @property (copy) */ NSArray *lineDashPattern;
	/* @property */ CGFloat lineDashPhase;
	/* @property */ CGLineJoin lineJoin;
	/* @property */ CGFloat lineWidth;
	/* @property */ CGFloat miterLimit;
	/* @property */ CGPathRef path;
	/* @property (retain) */ UIColor *strokeColor;
}

- (void) applyFillPropertiesToContext:(CGContextRef) context atZoomScale:(MKZoomScale) zoomScale;
- (void) applyStrokePropertiesToContext:(CGContextRef) context atZoomScale:(MKZoomScale) zoomScale;
- (void) createPath;
- (UIColor *) fillColor;
- (void) fillPath:(CGPathRef) path inContext:(CGContextRef) context;
- (void) invalidatePath;
- (CGLineCap) lineCap;
- (NSArray *) lineDashPattern;
- (CGFloat) lineDashPhase;
- (CGLineJoin) lineJoin;
- (CGFloat) lineWidth;
- (CGFloat) miterLimit;
- (CGPathRef) path;
- (void) setFillColor:(UIColor *) color;
- (void) setLineCap:(CGLineCap) cap;
- (void) setLineDashPattern:(NSArray *) pattern;
- (void) setLineDashPhase:(CGFloat) phase;
- (void) setLineJoin:(CGLineJoin) join;
- (void) setLineWidth:(CGFloat) width;
- (void) setMiterLimit:(CGFloat) limit;
- (void) setPath:(CGPathRef) path;
- (UIColor *) strokeColor;
- (void) setStrokeColor:(UIColor *) color;
- (void) strokePath:(CGPathRef) path inContext:(CGContextRef) context;

@end

// EOF
