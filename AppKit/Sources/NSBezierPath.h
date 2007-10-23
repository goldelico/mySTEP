/* 
   The NSBezierPath class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Enrico Sersale <enrico@imago.ro>
   Date: Dec 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	19. October 2007  
 
   This file is part of the mySTEP Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111 - 1307, USA.
*/

#ifndef BEZIERPATH_H
#define BEZIERPATH_H

#import <Foundation/Foundation.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSFont.h>

@class NSAffineTransform;
@class NSImage;

typedef enum _NSLineCapStyle
{
	NSButtLineCapStyle = 0,
	NSRoundLineCapStyle = 1,
	NSSquareLineCapStyle = 2
} NSLineCapStyle;

typedef enum NSLineJoinStyle
{
	NSMiterLineJoinStyle = 0,
	NSRoundLineJoinStyle = 1,
	NSBevelLineJoinStyle = 2
} NSLineJoinStyle;

typedef enum NSWindingRule
{
	NSNonZeroWindingRule,
	NSEvenOddWindingRule
} NSWindingRule;

typedef enum NSBezierPathElement
{
	NSMoveToBezierPathElement,
	NSLineToBezierPathElement,
	NSCurveToBezierPathElement,
	NSClosePathBezierPathElement
} NSBezierPathElement;

@interface NSBezierPath : NSObject <NSCopying, NSCoding>
{
	@private
	int _dashCount;
	float _dashPhase;
	float *_dashPattern;
	float _lineWidth;
	float _flatness;
	float _miterLimit;
	NSRect _bounds;
	NSRect _controlPointBounds;
//	NSImage *_cacheImage;
	
	void **_bPath;
	unsigned int _count;
	unsigned int _capacity;
	
    struct __BezierFlags {
		TYPEDBITFIELD(NSWindingRule, windingRule, 2);
		TYPEDBITFIELD(NSLineCapStyle, lineCapStyle, 2);
		TYPEDBITFIELD(NSLineJoinStyle, lineJoinStyle, 2);
		UIBITFIELD(unsigned int, flat, 1);
		UIBITFIELD(unsigned int, shouldRecalculateBounds, 1);
//		UIBITFIELD(unsigned int, cachesBezierPath, 1);
		UIBITFIELD(unsigned int, reserved, 7);
	} _bz;
}

+ (NSBezierPath *) bezierPath;
+ (NSBezierPath *) bezierPathWithOvalInRect:(NSRect) rect;
+ (NSBezierPath *) bezierPathWithRect:(NSRect) rect;
+ (void) clipRect:(NSRect) rect;
+ (float) defaultFlatness;
+ (NSLineCapStyle) defaultLineCapStyle;
+ (NSLineJoinStyle) defaultLineJoinStyle;
+ (float) defaultLineWidth;
+ (float) defaultMiterLimit;
+ (NSWindingRule) defaultWindingRule;
+ (void) drawPackedGlyphs:(const char *) glyphs atPoint:(NSPoint) pt;
+ (void) fillRect:(NSRect) rect;
+ (void) setDefaultFlatness:(float) value;
+ (void) setDefaultLineCapStyle:(NSLineCapStyle) style;
+ (void) setDefaultLineJoinStyle:(NSLineJoinStyle) style;
+ (void) setDefaultLineWidth:(float) lineWidth;
+ (void) setDefaultMiterLimit:(float) miterLimit;
+ (void) setDefaultWindingRule:(NSWindingRule) rule;
+ (void) strokeLineFromPoint:(NSPoint) pt1 toPoint:(NSPoint) pt2;
+ (void) strokeRect:(NSRect) rect;

- (void) addClip;
- (void) appendBezierPath:(NSBezierPath *) path;
- (void) appendBezierPathWithArcFromPoint:(NSPoint) pt1 toPoint:(NSPoint) pt2 radius:(float) rad;
- (void) appendBezierPathWithArcWithCenter:(NSPoint) centerPt radius:(float) rad startAngle:(float) startValue endAngle:(float) endValue;
- (void) appendBezierPathWithArcWithCenter:(NSPoint) centerPt radius:(float) rad startAngle:(float) startValue endAngle:(float) endValue clockwise:(BOOL) flag;
- (void) appendBezierPathWithGlyph:(NSGlyph) glyph inFont:(NSFont *) font;
- (void) appendBezierPathWithGlyphs:(NSGlyph *) glyphs count:(int) count inFont:(NSFont *) font;
- (void) appendBezierPathWithOvalInRect:(NSRect) rect;
- (void) appendBezierPathWithPackedGlyphs:(const char *) glyphs;
- (void) appendBezierPathWithPoints:(NSPoint *) pts count:(int) count;
- (void) appendBezierPathWithRect:(NSRect) rect;
- (NSBezierPath *) bezierPathByFlatteningPath;
- (NSBezierPath *) bezierPathByReversingPath;
- (NSRect) bounds;
- (BOOL) cachesBezierPath;
- (void) closePath;
- (BOOL) containsPoint:(NSPoint) pt;
- (NSRect) controlPointBounds;
- (NSPoint) currentPoint;
- (void) curveToPoint:(NSPoint) pt controlPoint1:(NSPoint) controlPt1 controlPoint2:(NSPoint) controlPt2;
- (NSBezierPathElement) elementAtIndex:(int) loc;
- (NSBezierPathElement) elementAtIndex:(int) loc associatedPoints:(NSPoint *) pts;
- (int) elementCount;
- (void) fill;
- (float) flatness;
- (void) getLineDash:(float *) patternValue count:(int *) count phase:(float *) phaseValue;
- (BOOL) isEmpty;
- (NSLineCapStyle) lineCapStyle;
- (NSLineJoinStyle) lineJoinStyle;
- (void) lineToPoint:(NSPoint) pt;
- (float) lineWidth;
- (float) miterLimit;
- (void) moveToPoint:(NSPoint) pt;
- (void) relativeCurveToPoint:(NSPoint) pt controlPoint1:(NSPoint) controlPt1 controlPoint2:(NSPoint) controlPt2;
- (void) relativeLineToPoint:(NSPoint) pt;
- (void) relativeMoveToPoint:(NSPoint) pt;
- (void) removeAllPoints;
- (void) setAssociatedPoints:(NSPointArray) pts atIndex:(int) loc;
- (void) setCachesBezierPath:(BOOL) flag;
- (void) setClip;
- (void) setFlatness:(float) flatness;
- (void) setLineCapStyle:(NSLineCapStyle) style;
- (void) setLineDash:(const float *) patternPointer count:(int) count phase:(float) phaseValue;
- (void) setLineJoinStyle:(NSLineJoinStyle) style;
- (void) setLineWidth:(float) width;
- (void) setMiterLimit:(float) limit;
- (void) setWindingRule:(NSWindingRule) windingRule;
- (void) stroke;
- (void) transformUsingAffineTransform:(NSAffineTransform *) transform;
- (NSWindingRule) windingRule;

@end

#endif // BEZIERPATH_H
