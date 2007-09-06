/* 
   The NSBezierPath class

   Copyright (C) 1999 Free Software Foundation, Inc.

   Author:  Enrico Sersale <enrico@imago.ro>
   Date: Dec 1999
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
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
	NSImage *_cacheImage;
	
	void **_bPath;
	unsigned int _count;
	unsigned int _capacity;
	
    struct __BezierFlags {
		TYPEDBITFIELD(NSWindingRule, windingRule, 2);
		TYPEDBITFIELD(NSLineCapStyle, lineCapStyle, 2);
		TYPEDBITFIELD(NSLineJoinStyle, lineJoinStyle, 2);
		UIBITFIELD(unsigned int, flat, 1);
		UIBITFIELD(unsigned int, cachesBezierPath, 1);
		UIBITFIELD(unsigned int, shouldRecalculateBounds, 1);
		UIBITFIELD(unsigned int, reserved, 7);
	} _bz;
}

+ (NSBezierPath *)bezierPath;
+ (NSBezierPath *)bezierPathWithOvalInRect:(NSRect)rect;
+ (NSBezierPath *)bezierPathWithRect:(NSRect)aRect;
+ (void)clipRect:(NSRect)aRect;
+ (float)defaultFlatness;
+ (NSLineCapStyle)defaultLineCapStyle;
+ (NSLineJoinStyle)defaultLineJoinStyle;
+ (float)defaultLineWidth;
+ (float)defaultMiterLimit;
+ (NSWindingRule)defaultWindingRule;
+ (void)drawPackedGlyphs:(const char *)packedGlyphs atPoint:(NSPoint)aPoint;
+ (void)fillRect:(NSRect)aRect;
+ (void)setDefaultFlatness:(float)flatness;
+ (void)setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle;
+ (void)setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;
+ (void)setDefaultLineWidth:(float)lineWidth;
+ (void)setDefaultMiterLimit:(float)limit;
+ (void)setDefaultWindingRule:(NSWindingRule)windingRule;
+ (void)strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2;
+ (void)strokeRect:(NSRect)aRect;

- (void)addClip;
- (void)appendBezierPath:(NSBezierPath *)aPath;
- (void)appendBezierPathWithArcFromPoint:(NSPoint)point1
								 toPoint:(NSPoint)point2
								  radius:(float)radius;
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
								   radius:(float)radius
							   startAngle:(float)startAngle
								 endAngle:(float)endAngle;
- (void)appendBezierPathWithArcWithCenter:(NSPoint)center  
								   radius:(float)radius
							   startAngle:(float)startAngle
								 endAngle:(float)endAngle
								clockwise:(BOOL)clockwise;
- (void)appendBezierPathWithGlyph:(NSGlyph)glyph
						   inFont:(NSFont *)font;
- (void)appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
							 count:(int)count
							inFont:(NSFont *)font;
- (void)appendBezierPathWithOvalInRect:(NSRect)aRect;
- (void)appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs;
- (void)appendBezierPathWithPoints:(NSPoint *)points count:(int)count;
- (void)appendBezierPathWithRect:(NSRect)rect;
- (NSBezierPath *)bezierPathByFlatteningPath;
- (NSBezierPath *)bezierPathByReversingPath;
- (NSRect)bounds;
- (BOOL)cachesBezierPath;
- (void)closePath;
- (BOOL)containsPoint:(NSPoint)point;
- (NSRect)controlPointBounds;
- (NSPoint)currentPoint;
- (void)curveToPoint:(NSPoint)aPoint 
       controlPoint1:(NSPoint)controlPoint1
       controlPoint2:(NSPoint)controlPoint2;
- (NSBezierPathElement)elementAtIndex:(int)index;
- (NSBezierPathElement)elementAtIndex:(int)index
					 associatedPoints:(NSPoint *)points;
- (int)elementCount;
- (void)fill;
- (float)flatness;
- (void)getLineDash:(float *)pattern count:(int *)count phase:(float *)phase;
- (BOOL)isEmpty;
- (NSLineCapStyle)lineCapStyle;
- (NSLineJoinStyle)lineJoinStyle;
- (void)lineToPoint:(NSPoint)aPoint;
- (float)lineWidth;
- (float)miterLimit;
- (void)moveToPoint:(NSPoint)aPoint;
- (void)relativeCurveToPoint:(NSPoint)aPoint
			   controlPoint1:(NSPoint)controlPoint1
			   controlPoint2:(NSPoint)controlPoint2;
- (void)relativeLineToPoint:(NSPoint)aPoint;
- (void)relativeMoveToPoint:(NSPoint)aPoint;
- (void)removeAllPoints;
- (void)setAssociatedPoints:(NSPointArray)points atIndex:(int)index;
- (void)setCachesBezierPath:(BOOL)flag;
- (void)setClip;
- (void)setFlatness:(float)flatness;
- (void)setLineCapStyle:(NSLineCapStyle)lineCapStyle;
- (void)setLineDash:(const float *)pattern count:(int)count phase:(float)phase;
- (void)setLineJoinStyle:(NSLineJoinStyle)lineJoinStyle;
- (void)setLineWidth:(float)lineWidth;
- (void)setMiterLimit:(float)limit;
- (void)setWindingRule:(NSWindingRule)windingRule;
- (void)stroke;
- (void)transformUsingAffineTransform:(NSAffineTransform *)transform;
- (NSWindingRule)windingRule;

@end

#endif // BEZIERPATH_H
