/* 
 NSBezierPath.m
 
 Bezier path drawing class
 
 Copyright (C) 1998 Free Software Foundation, Inc.
 
 Author:  Enrico Sersale <enrico@imago.ro>
 Date:    Dec 1999
 Author:  Fred Kiefer <FredKiefer@gmx.de>
 Date:    January 2001
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 
 */ 

#import <AppKit/NSAffineTransform.h>
#import <AppKit/NSBezierPath.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSGraphicsContext.h>

#import "NSBackendPrivate.h"

#ifndef M_PI
#define M_PI 3.1415926535897932384626433
#endif

#define PMAX  10000
#define KAPPA 0.5522847498				// magic number = 4 *(sqrt(2) -1)/3	

static void flatten(NSPoint coeff[], float flatness, NSBezierPath *path);

static float __defaultLineWidth = 1.0;
static float __defaultFlatness = 1.0;
static float __defaultMiterLimit = 10.0;
static NSLineJoinStyle __defaultLineJoinStyle = NSMiterLineJoinStyle;
static NSLineCapStyle __defaultLineCapStyle = NSButtLineCapStyle;
static NSWindingRule __defaultWindingRule = NSNonZeroWindingRule;

@interface _NSRectBezierPath : NSBezierPath
{
	NSRect _rect;
}
- (id) initWithRect:(NSRect) rect;
@end

@implementation _NSRectBezierPath

// FIXME - what happens if we want to append to such a BezierPath!!!
// if we design it well, append means copying the elements in a loop
// and the rectBezierPath can generate all elements

- (id) initWithRect:(NSRect) rect;
{
	if((self=[super init]))
			{
				_rect=rect;
			}
	return self;
}

- (void) transformUsingAffineTransform:(NSAffineTransform *)transform
{
	// !!! FIXME: this can't work since we can't convert us into a standard NSBezierPath object unless we change the isa pointer!!!
	// check for translation only transform -> move origin
	// otherwise transform to real path
	NIMP;
}

- (NSPoint) currentPoint  {	return _rect.origin; }

- (NSRect) controlPointBounds		{	return _rect; }
- (NSRect) bounds		{	return _rect; }

- (BOOL) isEmpty								{ return NO; }
- (int) elementCount							{ return 5; }

- (NSBezierPathElement) elementAtIndex:(int)index
											associatedPoints:(NSPoint *)points
{
	if (index < 0 || index >= 5)
		[NSException raise: NSRangeException format: @"Bad Index"];
	if(points)
			{
				switch(index)
					{
						case 0: *points=_rect.origin; break;
						case 1: *points=_rect.origin; points->x+=_rect.size.width; break;
						case 2: *points=_rect.origin; points->x+=_rect.size.width; points->y+=_rect.size.height; break;
						case 3: *points=_rect.origin; points->y+=_rect.size.height; break;
					}
			}
	switch(index)
		{
			case 0: return NSMoveToBezierPathElement;
			case 4: return NSClosePathBezierPathElement;
			default: return NSLineToBezierPathElement;
		}
}

@end

@implementation NSBezierPath

+ (NSBezierPath *) bezierPath
{
	return [[self new] autorelease];
}

+ (NSBezierPath *) bezierPathWithRect:(NSRect)aRect
{
#if 1	// use 4 lines instead of _NSRectBezierPath
	
	NSBezierPath *path = [self new];
	NSPoint p;
	
	[path moveToPoint: aRect.origin];
	p.x = NSMaxX(aRect);
	p.y = aRect.origin.y;
	[path lineToPoint: p];
	p.y = NSMaxY(aRect);
	[path lineToPoint: p];
	p.x = NSMinX(aRect);
	[path lineToPoint: p];
	[path closePath];
	
	return [path autorelease];
#else
	// FIXME: return instance of _NSRectBezierPath
	// or we define a private _NSRectBezierPathElement defining two corner points
	// PDF and X11 can use that directly do render rects
	return [[[_NSRectBezierPath alloc] initWithRect:aRect] autorelease];
#endif
}

+ (NSBezierPath *) bezierPathWithOvalInRect:(NSRect)rect
{
	NSBezierPath *path = [self new];
	NSPoint p, p1, p2;
	double originx = rect.origin.x;
	double originy = rect.origin.y;
	double width = rect.size.width;
	double height = rect.size.height;
	double hdiff = width / 2 * KAPPA;
	double vdiff = height / 2 * KAPPA;
	
	p = NSMakePoint(originx + width / 2, originy + height);
	[path moveToPoint: p];
	
	p = NSMakePoint(originx, originy + height / 2);
	p1 = NSMakePoint(originx + width / 2 - hdiff, originy + height);
	p2 = NSMakePoint(originx, originy + height / 2 + vdiff);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];
	
	p = NSMakePoint(originx + width / 2, originy);
	p1 = NSMakePoint(originx, originy + height / 2 - vdiff);
	p2 = NSMakePoint(originx + width / 2 - hdiff, originy);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	p = NSMakePoint(originx + width, originy + height / 2);
	p1 = NSMakePoint(originx + width / 2 + hdiff, originy);
	p2 = NSMakePoint(originx + width, originy + height / 2 - vdiff);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	p = NSMakePoint(originx + width / 2, originy + height);
	p1 = NSMakePoint(originx + width, originy + height / 2 + vdiff);
	p2 = NSMakePoint(originx + width / 2 + hdiff, originy + height);
	[path curveToPoint: p controlPoint1: p1 controlPoint2: p2];	
	
	return [path autorelease];
}

+ (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)rect xRadius:(CGFloat)xrad yRadius:(CGFloat)yrad;
{
	NSBezierPath *p=[self new];
	[p appendBezierPathWithRoundedRect:rect xRadius:xrad yRadius:yrad];
	return [p autorelease];
}

// this is a special case of _drawRoundedBezel:

+ (NSBezierPath *) _bezierPathWithBoxBezelInRect:(NSRect) borderRect radius:(float) radius
{
	NSBezierPath *b=[self new];
	borderRect.size.width-=1.0;
	borderRect.size.height-=1.0;	// draw inside
	[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(borderRect)+radius, NSMinY(borderRect)+radius)
																radius:radius
														startAngle:270.0
															endAngle:180.0
														 clockwise:YES];
	[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(borderRect)+radius, NSMaxY(borderRect)-radius)
																radius:radius
														startAngle:180.0
															endAngle:90.0
														 clockwise:YES];
	[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(borderRect)-radius, NSMaxY(borderRect)-radius)
																radius:radius
														startAngle:90.0
															endAngle:0.0
														 clockwise:YES];
	[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(borderRect)-radius, NSMinY(borderRect)+radius)
																radius:radius
														startAngle:0.0
															endAngle:270.0
														 clockwise:YES];
	[b closePath];
	return [b autorelease];
}

#if 1	// should be replaced by 10.5 method + (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)rect xRadius:(CGFloat)xrad yRadius:(CGFloat)yrad;

// this is a special case of _drawRoundedBezel:

+ (NSBezierPath *) _bezierPathWithRoundedBezelInRect:(NSRect) borderRect vertical:(BOOL) flag;	// box with halfcircular rounded ends
{
//	return [self bezierPathWithRoundedRect:borderRect xRadius:flag? :borderRect.size.width/2.0 yRadius:flag?borderRect.size.height/2.0: ];
#if 1
	NSBezierPath *p=[self new];
	NSPoint point=borderRect.origin;
	float radius;
	borderRect.size.width-=1.0;
	borderRect.size.height-=1.0;
	if(flag)
		{ // vertical
		radius=borderRect.size.width*0.5;
		point.x+=radius;
		point.y+=radius;
		radius-=1.0;
		[p appendBezierPathWithArcWithCenter:point radius:radius startAngle:180.0 endAngle:360.0];	// bottom half-circle
		point.y+=borderRect.size.height-borderRect.size.width;
		[p appendBezierPathWithArcWithCenter:point radius:radius startAngle:0.0 endAngle:180.0];	// line to first point and top halfcircle
		}
	else
		{ // horizontal
		radius=borderRect.size.height*0.5;
		point.x+=radius;
		point.y+=radius;
		radius-=1.0;
		[p appendBezierPathWithArcWithCenter:point radius:radius startAngle:90.0 endAngle:270.0];	// left half-circle
		point.x+=borderRect.size.width-borderRect.size.height;
		[p appendBezierPathWithArcWithCenter:point radius:radius startAngle:270.0 endAngle:90.0];	// line to first point and right halfcircle
		}
	[p closePath];
	return [p autorelease];
#endif
}

#endif

// rename to _drawSegmentedBezel
// add backgroundColor parameter (for the default if not enabled)
// add radius parameter - then we can also use it to draw the standard round button

+ (void) _drawRoundedBezel:(NSRoundedBezelSegments) border inFrame:(NSRect) frame enabled:(BOOL) enabled selected:(BOOL) selected highlighted:(BOOL) highlighted radius:(float) radius;
{
	NSColor *background;
	NSBezierPath *b=[self new];
	if(border&NSRoundedBezelLeftSegment)
		{ // left side shaped
		[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(frame)+radius, NSMinY(frame)+radius)
									  radius:radius
								  startAngle:270.0
									endAngle:180.0
								   clockwise:YES];
		[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMinX(frame)+radius, NSMaxY(frame)-1.0-radius)
									  radius:radius
								  startAngle:180.0
									endAngle:90.0
								   clockwise:YES];
		}
	else
		{ // left vertical
		[b moveToPoint:NSMakePoint(NSMinX(frame), NSMinY(frame))];
		[b lineToPoint:NSMakePoint(NSMinX(frame), NSMaxY(frame)-1.0)];
		}
	if(border&NSRoundedBezelRightSegment)
		{ // right side shaped
		[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(frame)-radius, NSMaxY(frame)-1.0-radius)
									  radius:radius
								  startAngle:90.0
									endAngle:0.0
								   clockwise:YES];
		[b appendBezierPathWithArcWithCenter:NSMakePoint(NSMaxX(frame)-radius, NSMinY(frame)+radius)
									  radius:radius
								  startAngle:0.0
									endAngle:270.0
								   clockwise:YES];
		}
	else
		{ // right vertical
		[b lineToPoint:NSMakePoint(NSMaxX(frame), NSMaxY(frame)-1.0)];
		[b lineToPoint:NSMakePoint(NSMaxX(frame), NSMinY(frame))];
		}
	[b closePath];
	// setting colors should be done by the caller
	if(enabled)
		{
		if(selected)
			{
			if(highlighted)
				background=[NSColor controlShadowColor];
			else
				background=[NSColor selectedControlColor];
			}
		else
			{
			if(highlighted)
				background=[NSColor controlHighlightColor];
			else
				background=[NSColor controlColor];
			}
		}
	else
		background=[NSColor controlBackgroundColor];
	[background set];
	[b fill];	// fill background
	[[NSColor blackColor] set];
	[b stroke];	// stroke border line
	[b release];
}

+ (void) fillRect:(NSRect)aRect	// Immediate mode drawing
{
	NSBezierPath *bp;
	if(NSIsEmptyRect(aRect))
		return;
	bp=[NSBezierPath bezierPathWithRect:aRect];
	[bp setWindingRule:NSEvenOddWindingRule];
	[bp fill];
}

+ (void) strokeRect:(NSRect)aRect
{
	if(NSIsEmptyRect(aRect))
		return;
	[[NSBezierPath bezierPathWithRect:aRect] stroke];
}

+ (void) clipRect:(NSRect)aRect
{
	NSBezierPath *bp=[NSBezierPath bezierPathWithRect:aRect];
	[bp setWindingRule:NSEvenOddWindingRule];
	[bp addClip];
}

+ (void) strokeLineFromPoint:(NSPoint)point1 toPoint:(NSPoint)point2
{
	NSBezierPath *path = [self new];
	
	[path moveToPoint: point1];
	[path lineToPoint: point2];
	[path stroke];
	[path release];
}

+ (void) drawPackedGlyphs:(const char *)packedGlyphs  atPoint:(NSPoint)aPoint
{
	NSBezierPath *path = [self new];	
	[path moveToPoint: aPoint];
	[path appendBezierPathWithPackedGlyphs: packedGlyphs];
	[path stroke];  
	[path release];
}

+ (void) setDefaultFlatness:(float)flatness	{ __defaultFlatness = flatness; }
+ (void) setDefaultLineWidth:(float)lnWidth	{ __defaultLineWidth = lnWidth; }
+ (void) setDefaultMiterLimit:(float)limit	{ __defaultMiterLimit = limit; }
+ (void) setDefaultWindingRule:(NSWindingRule)windingRule		{ __defaultWindingRule = windingRule; }
+ (void) setDefaultLineCapStyle:(NSLineCapStyle)lineCapStyle	{ __defaultLineCapStyle = lineCapStyle; }
+ (void) setDefaultLineJoinStyle:(NSLineJoinStyle)lineJoinStyle { __defaultLineJoinStyle = lineJoinStyle; }
+ (float) defaultMiterLimit					{ return __defaultMiterLimit; }
+ (float) defaultLineWidth					{ return __defaultLineWidth; }
+ (float) defaultFlatness					{ return __defaultFlatness; }
+ (NSWindingRule) defaultWindingRule		{ return __defaultWindingRule; }
+ (NSLineCapStyle) defaultLineCapStyle		{ return __defaultLineCapStyle; }
+ (NSLineJoinStyle) defaultLineJoinStyle	{ return __defaultLineJoinStyle; }

- (id) init
{
	if((self=[super init]))
		{
		_lineWidth = __defaultLineWidth;
		_flatness = __defaultFlatness;
		_bz.lineCapStyle = __defaultLineCapStyle;
		_bz.lineJoinStyle = __defaultLineJoinStyle;
		_bz.windingRule = __defaultWindingRule;
		_miterLimit = __defaultMiterLimit;
	
		_bPath = objc_malloc((_capacity = 8) * sizeof(PathElement *));
		if(!_bPath)
			{
			[self release];
			return nil;
			}
		_bz.flat = YES;	// default is flat and first curve makes it non-flat
#if 0
			NSLog(@"NSBezierPath init %p", self);
#endif
		}
	return self;
}

- (void) dealloc
{
#if 0
	NSLog(@"dealloc %p: %@", self, self);
#endif
	[self removeAllPoints];
	objc_free(_bPath);
	if (_dashPattern != NULL)
		objc_free(_dashPattern);
	[super dealloc];
}

- (NSString *) description;
{
	int i;
	NSString *str=@"NSBezierPath:\n";
	for(i=0; i<_count; i++)
		{
		NSPoint points[3];
		switch([self elementAtIndex:i associatedPoints:points])
			{
			case NSMoveToBezierPathElement:
				str=[str stringByAppendingFormat:@"m %@\n", NSStringFromPoint(points[0])];
				break;
			case NSLineToBezierPathElement:
				str=[str stringByAppendingFormat:@"l %@\n", NSStringFromPoint(points[0])];
				break;
			case NSCurveToBezierPathElement:
				str=[str stringByAppendingFormat:@"c %@ %@ %@\n", NSStringFromPoint(points[0]), NSStringFromPoint(points[1]), NSStringFromPoint(points[2])];
				break;
			case NSClosePathBezierPathElement:
				str=[str stringByAppendingFormat:@"h\n"];
				break;
			}
		}
	return str;
}

- (void) moveToPoint:(NSPoint)aPoint				// Path construction
{
	PathElement *e = objc_malloc(sizeof(PathElement));
	
	e->type = NSMoveToBezierPathElement;
	e->points[0] = aPoint;
	if (_count >= _capacity)
		_bPath = objc_realloc(_bPath, (_capacity = 2 * _count + 3) * sizeof(PathElement *));
	_bPath[_count++] = e;
	_bz.shouldRecalculateBounds = YES;
}

- (void) lineToPoint:(NSPoint)aPoint
{
	PathElement *e = objc_malloc(sizeof(PathElement));
	
	e->type = NSLineToBezierPathElement;
	e->points[0] = aPoint;
	if (_count >= _capacity)
		_bPath = objc_realloc(_bPath, (_capacity = 2 * _count + 3) * sizeof(PathElement *));
	_bPath[_count++] = e;
	_bz.shouldRecalculateBounds = YES;
}

- (void) curveToPoint:(NSPoint)aPoint 
		controlPoint1:(NSPoint)controlPoint1
		controlPoint2:(NSPoint)controlPoint2
{
	PathElement *e = objc_malloc(sizeof(PathElement));
	
	e->type = NSCurveToBezierPathElement;
	e->points[0] = controlPoint1;
	e->points[1] = controlPoint2;
	e->points[2] = aPoint;
	if (_count >= _capacity)
		_bPath = objc_realloc(_bPath, (_capacity = 2 * _count + 3) * sizeof(PathElement *));
	_bPath[_count++] = e;

	_bz.flat = NO;
	
	_bz.shouldRecalculateBounds = YES;
}

- (void) closePath
{
	PathElement *e = objc_malloc(sizeof(PathElement));
	e->type = NSClosePathBezierPathElement;
	if (_count >= _capacity)
		_bPath = objc_realloc(_bPath, (_capacity = 2 * _count + 3) * sizeof(PathElement *));
	_bPath[_count++] = e;
	_bz.shouldRecalculateBounds = YES;
}

- (void) removeAllPoints
{
#if 0
	NSLog(@"removeAllPoints[%u capa=%u] %p %@", _count, _capacity, _bPath, self);
#endif
	while(_count > 0)
		{
		_count--;
#if 0
		NSLog(@"remove %u %p", _count, _bPath[_count]);
#endif
		objc_free(_bPath[_count]);
		}
#if 0
	NSLog(@"  cnt=%u", _count);
#endif
	_bz.shouldRecalculateBounds = YES;
#if 0
	NSLog(@"  -> [%u] %@", _count, self);
#endif
}

- (void) relativeMoveToPoint:(NSPoint)aPoint
{
	NSPoint p = [self currentPoint];
	
	p.x = p.x + aPoint.x;
	p.y = p.y + aPoint.y;
	[self moveToPoint: p];
}

- (void) relativeLineToPoint:(NSPoint)aPoint
{
	NSPoint p = [self currentPoint];
	
	p.x = p.x + aPoint.x;
	p.y = p.y + aPoint.y;
	[self lineToPoint: p];
}

- (void) relativeCurveToPoint:(NSPoint)aPoint
				controlPoint1:(NSPoint)controlPoint1
				controlPoint2:(NSPoint)controlPoint2
{
	NSPoint p = [self currentPoint];
	
	aPoint.x = p.x + aPoint.x;
	aPoint.y = p.y + aPoint.y;
	controlPoint1.x = p.x + controlPoint1.x;
	controlPoint1.y = p.y + controlPoint1.y;
	controlPoint2.x = p.x + controlPoint2.x;
	controlPoint2.y = p.y + controlPoint2.y;
	[self curveToPoint: aPoint
		 controlPoint1: controlPoint1
		 controlPoint2: controlPoint2];
}

- (float) lineWidth								{ return _lineWidth; }
- (float) flatness								{ return _flatness; }
- (float) miterLimit							{ return _miterLimit; }
- (NSLineJoinStyle) lineJoinStyle				{ return _bz.lineJoinStyle; }
- (NSLineCapStyle) lineCapStyle					{ return _bz.lineCapStyle; }
- (NSWindingRule) windingRule					{ return _bz.windingRule; }
- (void) setLineWidth:(float)lineWidth			{ _lineWidth = lineWidth; }
- (void) setFlatness:(float)flatness			{ _flatness = flatness; }
- (void) setLineCapStyle:(NSLineCapStyle)ls		{ _bz.lineCapStyle = ls; }
- (void) setLineJoinStyle:(NSLineJoinStyle)lj	{ _bz.lineJoinStyle = lj; }
- (void) setWindingRule:(NSWindingRule)wr		{ _bz.windingRule = wr; }
- (void) setMiterLimit:(float)limit				{ _miterLimit = limit; }

- (void) getLineDash:(float *)pattern count:(int *)count phase:(float *)phase
{
	if (count != NULL)				// FIXME: How big is the pattern array?
		{							// We assume that this value is in count!
		if (*count < _dashCount)
			{
			*count = _dashCount;
			return;
			}
		*count = _dashCount;
		}
	
	if (phase != NULL)
		*phase = _dashPhase;
	
	memcpy(pattern, _dashPattern, _dashCount * sizeof(float));
}

- (void) setLineDash:(const float *)pattern count:(int)count phase:(float)phase
{
	if ((pattern == NULL) || (count == 0))
		{
		if (_dashPattern != NULL)
			objc_free(_dashPattern);
		_dashPattern = NULL;
		_dashCount = 0;
		_dashPhase = 0.0;
		
		return;
		}
	
	if (_dashPattern == NULL)
		_dashPattern = objc_malloc(count * sizeof(float));
	else
		_dashPattern = objc_realloc(_dashPattern, count * sizeof(float));
	
	_dashCount = count;
	_dashPhase = phase;
	memcpy(_dashPattern, pattern, _dashCount * sizeof(float));
}

- (void) stroke
{
	[[NSGraphicsContext currentContext] _stroke:self];
}

- (void) fill
{
	[[NSGraphicsContext currentContext] _fill:self];
}

- (void) addClip
{
	[[NSGraphicsContext currentContext] _addClip:self reset:NO];
}

- (void) setClip
{
	[[NSGraphicsContext currentContext] _addClip:self reset:YES];
}

- (NSBezierPath *) bezierPathByFlatteningPath
{
	NSBezierPath *path;
	NSPoint pts[3];
	NSPoint coeff[4];
	NSPoint p, last_p;
	int i;
	BOOL first = YES;
	
	if(_bz.flat)
		return [[self copyWithZone:NSDefaultMallocZone()] autorelease];	// return always a copy (someone might want to add more elements)

	i=_count;
	_count=0;	// don't copy current path but current _capacity
	path = [[self copyWithZone:NSDefaultMallocZone()] autorelease];
	_count=i;

	for(i = 0; i < _count; i++)
		{
		switch([self elementAtIndex: i associatedPoints: pts]) 
			{
			case NSMoveToBezierPathElement:
				[path moveToPoint: pts[0]];
				last_p = p = pts[0];
				first = NO;
				break;
			case NSLineToBezierPathElement:
				[path lineToPoint: pts[0]];
				p = pts[0];
				if (first)
					{
					last_p = pts[0];
					first = NO;
					}
				break;
			case NSCurveToBezierPathElement:
				coeff[0] = p;
				coeff[1] = pts[0];
				coeff[2] = pts[1];
				coeff[3] = pts[2];
				flatten(coeff, [self flatness], path);
				p = pts[2];
				if (first)
					{
					last_p = pts[2];
					first = NO;
					}
				break;
			case NSClosePathBezierPathElement:
				[path closePath];
				p = last_p;
			default:
				break;
			}
		}
	path->_bz.flat=YES;
	return path;
}

- (NSBezierPath *) bezierPathByReversingPath
{
	NSBezierPath *path;
	NSBezierPathElement type, last_type = NSMoveToBezierPathElement;
	NSPoint pts[3];
	NSPoint p, cp1, cp2;
	int i, j;
	BOOL closed = NO;
	
	i=_count;
	_count=0;	// don't copy current path but current _capacity
	path = [[self copyWithZone:NSDefaultMallocZone()] retain];
	_count=i;

	for(i = _count - 1; i >= 0; i--) 
		{
		switch((type = [self elementAtIndex: i associatedPoints: pts])) 
			{
			case NSMoveToBezierPathElement:
				p = pts[0];
				break;
			case NSLineToBezierPathElement:
				p = pts[0];
				break;
			case NSCurveToBezierPathElement:
				cp1 = pts[0];
				cp2 = pts[1];
				p = pts[2];      
				break;
			case NSClosePathBezierPathElement:		// FIX ME looks wrong
				for (j = i - 1; j >= 0; j--) // find the first point of segment
					{
					type = [self elementAtIndex: i associatedPoints: pts];
					if (type == NSMoveToBezierPathElement)
						{
						p = pts[0];
						break;
						}
					}   
				// FIXME: What to do if we don't find a move element?
			default:
				break;
			}
		
		switch(last_type) 
			{
			case NSMoveToBezierPathElement:
				if (closed)
					{
					[path closePath];
					closed = NO;
					}
				[path moveToPoint: p];
				break;
			case NSLineToBezierPathElement:
				[path lineToPoint: p];
				break;
			case NSCurveToBezierPathElement:
				[path curveToPoint: p controlPoint1: cp2 controlPoint2: cp1];	      
				break;
			case NSClosePathBezierPathElement:
				closed = YES;
			default:
				break;
			}
		last_type = type;
		}
	
	if (closed)
		[path closePath];
	
	return self;
}

- (void) transformUsingAffineTransform:(NSAffineTransform *)transform
{
	NSPoint pts[3];
	int i;
	
	for(i = 0; i < _count; i++) 
		switch([self elementAtIndex: i associatedPoints: pts]) 
			{
			case NSMoveToBezierPathElement:
			case NSLineToBezierPathElement:
				pts[0] = [transform transformPoint: pts[0]];
				[self setAssociatedPoints: pts atIndex: i];
				break;
			case NSCurveToBezierPathElement:
				pts[0] = [transform transformPoint: pts[0]];
				pts[1] = [transform transformPoint: pts[1]];
				pts[2] = [transform transformPoint: pts[2]];
				[self setAssociatedPoints: pts atIndex: i];
			case NSClosePathBezierPathElement:
			default:
				break;
			}
			
	_bz.shouldRecalculateBounds = YES;
}

- (NSPoint) currentPoint
{
	NSPoint points[3];
	int i;
	
	if (!_count) 
		[NSException raise: NSGenericException
					format: @"No current Point in NSBezierPath"];
	
	switch([self elementAtIndex: _count - 1 associatedPoints: points]) 
		{
		case NSMoveToBezierPathElement:
		case NSLineToBezierPathElement:
			return points[0];
			
		case NSCurveToBezierPathElement:
			return points[2];
			
		case NSClosePathBezierPathElement:			// We have to find the last			
			for (i = _count - 2; i >= 0; i--)		// move element and take
				{									// its point
				NSBezierPathElement type = [self elementAtIndex: i
											   associatedPoints: points];
				if (type == NSMoveToBezierPathElement)
					return points[0];
				}
		default:
			break;
		}
	
	return NSZeroPoint;
}

- (NSRect) controlPointBounds
{
	if (_bz.shouldRecalculateBounds)
		[self bounds];
	
	return _controlPointBounds;
}

- (NSRect) bounds
{
	if (_bz.shouldRecalculateBounds)
		{
		NSPoint p, last_p;
		NSPoint pts[3];
		// This will compute three intermediate points per curve
		double x, y, t, k = 0.25;
		float maxx, minx, maxy, miny;
		float cpmaxx, cpminx, cpmaxy, cpminy;	
		int i;
		BOOL first = YES;
		
		if(!_count)
			{
			_bounds = NSZeroRect;
			_controlPointBounds = NSZeroRect;
			return NSZeroRect;
			}
		
		maxx = maxy = cpmaxx = cpmaxy = -1E9;		// Some big starting values
		minx = miny = cpminx = cpminy = 1E9;
		
		for(i = 0; i < _count; i++) 
			{
			switch([self elementAtIndex: i associatedPoints: pts]) 
				{
				case NSMoveToBezierPathElement:
					last_p = pts[0];							// NO BREAK
				case NSLineToBezierPathElement:
					if (first)
						{
						maxx = minx = cpmaxx = cpminx = pts[0].x;
						maxy = miny = cpmaxy = cpminy = pts[0].y;
						last_p = pts[0];
						first = NO;
						}
					else
						{
						if(pts[0].x > maxx) maxx = pts[0].x;
						if(pts[0].x < minx) minx = pts[0].x;
						if(pts[0].y > maxy) maxy = pts[0].y;
						if(pts[0].y < miny) miny = pts[0].y;
						
						if(pts[0].x > cpmaxx) cpmaxx = pts[0].x;
						if(pts[0].x < cpminx) cpminx = pts[0].x;
						if(pts[0].y > cpmaxy) cpmaxy = pts[0].y;
						if(pts[0].y < cpminy) cpminy = pts[0].y;
						}
					
					p = pts[0];
					break;
					
				case NSCurveToBezierPathElement:
					if (first)
						{
						maxx = minx = cpmaxx = cpminx = pts[0].x;
						maxy = miny = cpmaxy = cpminy = pts[0].y;
						p = last_p = pts[0];
						first = NO;
						}
					
					if(pts[2].x > maxx) maxx = pts[2].x;
					if(pts[2].x < minx) minx = pts[2].x;
						if(pts[2].y > maxy) maxy = pts[2].y;
							if(pts[2].y < miny) miny = pts[2].y;
								
								if(pts[0].x > cpmaxx) cpmaxx = pts[0].x;
									if(pts[0].x < cpminx) cpminx = pts[0].x;
										if(pts[0].y > cpmaxy) cpmaxy = pts[0].y;
											if(pts[0].y < cpminy) cpminy = pts[0].y;
												if(pts[1].x > cpmaxx) cpmaxx = pts[1].x;
													if(pts[1].x < cpminx) cpminx = pts[1].x;
														if(pts[1].y > cpmaxy) cpmaxy = pts[1].y;
															if(pts[1].y < cpminy) cpminy = pts[1].y;
																if(pts[2].x > cpmaxx) cpmaxx = pts[2].x;
																	if(pts[2].x < cpminx) cpminx = pts[2].x;
																		if(pts[2].y > cpmaxy) cpmaxy = pts[2].y;
																			if(pts[2].y < cpminy) cpminy = pts[2].y;
																				
																				for(t = k; t <= 1+k; t += k) 
																					{
																					x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))+
																					t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))+
																					t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
																					y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))+
																						t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))+
																						t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;
																					
																					if(x > cpmaxx) cpmaxx = x;
																					if(x < cpminx) cpminx = x;
																					if(y > cpmaxy) cpmaxy = y;
																					if(y < cpminy) cpminy = y;
																					}
																					
																			p = pts[2];
					break;
					
				case NSClosePathBezierPathElement:
					p = last_p;							// Changes current point
				default:
					break;
				}	}
		
		_bounds = NSMakeRect(minx, miny, maxx - minx, maxy - miny);
		_controlPointBounds = NSMakeRect(cpminx, cpminy, 
										 cpmaxx - cpminx, cpmaxy - cpminy);
		_bz.shouldRecalculateBounds = NO;
		}
	
	return _bounds;
}

- (BOOL) isEmpty								{ return (_count == 0); }
- (int) elementCount							{ return _count; }

- (NSBezierPathElement) elementAtIndex:(int)index
					  associatedPoints:(NSPoint *)points
{
	PathElement *e;
#if 0
	NSLog(@"elementAtIndex:%d [%u]", index, _count);
#endif
	if (index < 0 || index >= _count)
		[NSException raise: NSRangeException format: @"Bad Index"];

	e = _bPath[index];
	if (points != NULL) 
		{
		NSBezierPathElement t = e->type;
		
		if(t == NSMoveToBezierPathElement || t == NSLineToBezierPathElement) 
			points[0] = e->points[0];
		else if(t == NSCurveToBezierPathElement) 
			{
			points[0] = e->points[0];
			points[1] = e->points[1];
			points[2] = e->points[2];
			}
		}
	
	return e->type;
}

- (NSBezierPathElement) elementAtIndex:(int)index
{
	return [self elementAtIndex: index associatedPoints: NULL];	
}

- (void) appendBezierPath:(NSBezierPath *)aPath
{
	int i, count = [aPath elementCount];
	
	_bz.flat = _bz.flat && aPath->_bz.flat;
	
	if ((_count + count) >= _capacity)
		{
		_capacity = (2 * _count) + count;
		_bPath = objc_realloc(_bPath, _capacity * sizeof(PathElement *));
		}
	
	for (i = 0; i < count; i++)
		{
		PathElement *e = objc_malloc(sizeof(PathElement));
		
		*e = *(PathElement *)aPath->_bPath[i];
		_bPath[_count++] = e;
		}
	
	_bz.shouldRecalculateBounds = YES;
}

- (void) appendBezierPathWithRect:(NSRect)rect
{
	[self appendBezierPath: [isa bezierPathWithRect: rect]];
}

- (void) appendBezierPathWithPoints:(NSPoint *)points count:(int)count
{
	int i;
	
	if (!count)
		return;
	
	if ([self isEmpty])
		[self moveToPoint: points[0]];
	else
		[self lineToPoint: points[0]];
	
	for (i = 1; i < count; i++)
		[self lineToPoint: points[i]];
}

- (void) appendBezierPathWithOvalInRect:(NSRect)aRect
{
	[self appendBezierPath: [isa bezierPathWithOvalInRect: aRect]];
}

- (void) appendBezierPathWithRoundedRect:(NSRect) borderRect xRadius:(CGFloat) xrad yRadius:(CGFloat) yrad;
{
	NSPoint p, c;
	if(xrad <= 0.0 || yrad <= 0.0)
		xrad=yrad=0.0;	// results in rectangle
	borderRect.size.width-=1.0;
	borderRect.size.height-=1.0;	// draw inside
	p=NSMakePoint(NSMinX(borderRect)+xrad, NSMinY(borderRect));	// left bottom
	[self moveToPoint:p];
	p=NSMakePoint(NSMaxX(borderRect)-xrad, NSMinY(borderRect));	// right bottom
	[self lineToPoint:p];
	p=NSMakePoint(NSMaxX(borderRect), NSMinY(borderRect)+yrad);	// right bottom after curve
	c=NSMakePoint(NSMaxX(borderRect), NSMinY(borderRect));	// corner
	[self curveToPoint:p controlPoint1:c controlPoint2:c];
	p=NSMakePoint(NSMaxX(borderRect), NSMaxY(borderRect)-yrad);	// right top
	[self lineToPoint:p];
	p=NSMakePoint(NSMaxX(borderRect)-xrad, NSMaxY(borderRect));	// right top after curve
	c=NSMakePoint(NSMaxX(borderRect), NSMaxY(borderRect));	// corner
	[self curveToPoint:p controlPoint1:c controlPoint2:c];
	p=NSMakePoint(NSMinX(borderRect)+xrad, NSMaxY(borderRect)-yrad);	// left top
	[self lineToPoint:p];
	p=NSMakePoint(NSMinX(borderRect), NSMaxY(borderRect)-yrad);	// left top after curve
	c=NSMakePoint(NSMinX(borderRect), NSMaxY(borderRect));	// corner
	[self curveToPoint:p controlPoint1:c controlPoint2:c];
	p=NSMakePoint(NSMinX(borderRect), NSMinY(borderRect)+yrad);	// left bottom
	[self lineToPoint:p];
	p=NSMakePoint(NSMinX(borderRect)+xrad, NSMinY(borderRect));	// left bottom after curve
	c=NSMakePoint(NSMinX(borderRect), NSMinY(borderRect));	// corner
	[self curveToPoint:p controlPoint1:c controlPoint2:c];
	[self closePath];	// close to first point of segment
}

- (void) appendBezierPathWithArcWithCenter:(NSPoint)center  
									radius:(float)radius
								startAngle:(float)startAngle
								  endAngle:(float)endAngle
								 clockwise:(BOOL)clockwise
{											// startAngle and endAngle are in 
	float startAngle_rad, endAngle_rad, diff;	// degrees, counterclockwise, from 
	NSPoint p0, p1, p2, p3;						// the x axis
#if 0
	NSLog(@"appendBezierPathWithArcWithCenter:%@ radius:%f startAngle:%f endAngle:%f %@",
				NSStringFromPoint(center), radius, startAngle, endAngle, clockwise?@"clockwise":@"counter-clockwise");
	NSLog(@"  %@", self);
#endif
	
	/* We use the Postscript prescription for managing the angles and
		drawing the arc.  See the documentation for `arc' and `arcn' in
		the Postscript Reference. */
	if (clockwise)
		{	// This modification of the angles is the postscript prescription.
		while (startAngle < endAngle)
			endAngle -= 360;
		
		/* This is used when we draw a clockwise quarter of
		circumference.  By adding diff at the starting angle of the
		quarter, we get the ending angle.  diff is negative because
		we draw clockwise. */
		diff = - M_PI_2;
		}
	else
		{	// This modification of the angles is the postscript prescription.
		while (endAngle < startAngle)
			endAngle += 360;
		
		/* This is used when we draw a counterclockwise quarter of
		circumference.  By adding diff at the starting angle of the
		quarter, we get the ending angle.  diff is positive because
		we draw counterclockwise. */
		diff = M_PI_2;
		}
	
	/* Convert the angles to radians */
	startAngle_rad = (M_PI/180) * startAngle;
	endAngle_rad = (M_PI/180) * endAngle;
	
	/* Start point */
	p0 = NSMakePoint (center.x + radius * cos (startAngle_rad), 
					  center.y + radius * sin (startAngle_rad));
	if (_count == 0)
		[self moveToPoint: p0];
	else
		{
		NSPoint ps = [self currentPoint];
		
		if (p0.x != ps.x  ||  p0.y != ps.y)
			[self lineToPoint: p0];
		}
	
	while ((clockwise) ? (startAngle_rad > endAngle_rad) 
					   : (startAngle_rad < endAngle_rad))
		{
		/* Add a quarter circle */
		if ((clockwise) ? (startAngle_rad + diff >= endAngle_rad) 
						: (startAngle_rad + diff <= endAngle_rad))
			{
			float sin_start = sin (startAngle_rad);
			float cos_start = cos (startAngle_rad);
			float sign = (clockwise) ? -1.0 : 1.0;
#if 0
				NSLog(@"start=%f end=%f sign=%f", startAngle_rad, endAngle_rad, sign);
				NSLog(@"sin=%f cos=%f", sin_start, cos_start);
				NSLog(@"sin=%lf cos=%lf", sin_start, cos_start);
				NSLog(@"sin=%lf cos=%lf", sin (startAngle_rad), cos (startAngle_rad));
#endif
				p1 = NSMakePoint (center.x 
							  + radius * (cos_start - KAPPA * sin_start * sign), 
							  center.y 
							  + radius * (sin_start + KAPPA * cos_start * sign));
			p2 = NSMakePoint (center.x 
							  + radius * (-sin_start * sign + KAPPA * cos_start),
							  center.y 
							  + radius * (cos_start * sign + KAPPA * sin_start));
			p3 = NSMakePoint (center.x + radius * (-sin_start * sign),
							  center.y + radius *   cos_start * sign);
			
			[self curveToPoint: p3  controlPoint1: p1  controlPoint2: p2];
			startAngle_rad += diff;
			}
		else
			{
			/* Add the missing bit
			* We require that the arc be less than a semicircle.
			* The arc may go either clockwise or counterclockwise.
			* The approximation is a very simple one: a single curve
			* whose middle two control points are a fraction F of the way
			* to the intersection of the tangents, where
			*      F = (4/3) / (1 + sqrt (1 + (d / r)^2))
			* where r is the radius and d is the distance from either tangent
			* point to the intersection of the tangents. This produces
			* a curve whose center point, as well as its ends, lies on
			* the desired arc.
			*/
			NSPoint ps = [self currentPoint];
			/* tangent is the tangent of half the angle */
			float tangent = tan ((endAngle_rad - startAngle_rad) / 2);
			/* trad is the distance from either tangent point to the
				intersection of the tangents */
			float trad = radius * tangent;
			/* pt is the intersection of the tangents */
			NSPoint pt = NSMakePoint (ps.x - trad * sin (startAngle_rad),
									  ps.y + trad * cos (startAngle_rad));
			/* This is F - in this expression we need to compute 
				(trad/radius)^2, which is simply tangent^2 */
			float f = (4.0 / 3.0) / (1.0 + sqrt (1.0 +  (tangent * tangent)));
			
#if 0
				NSLog(@"ps=%@ tan=%f trad=%f pt=%@ f=%f", NSStringFromPoint(ps), tangent, trad, NSStringFromPoint(pt), f);
#endif
				p1 = NSMakePoint (ps.x + (pt.x - ps.x) * f, ps.y + (pt.y - ps.y) * f);
			p3 = NSMakePoint(center.x + radius * cos (endAngle_rad),
							 center.y + radius * sin (endAngle_rad));
			p2 = NSMakePoint (p3.x + (pt.x - p3.x) * f, p3.y + (pt.y - p3.y) * f);
			[self curveToPoint: p3  controlPoint1: p1  controlPoint2: p2];
			break;
			}
		}
#if 0
	NSLog(@"-> %@", self);
#endif
}

- (void) appendBezierPathWithArcWithCenter:(NSPoint)center  
									radius:(float)radius
								startAngle:(float)startAngle
								  endAngle:(float)endAngle
{
	[self appendBezierPathWithArcWithCenter: center
									 radius: radius
								 startAngle: startAngle
								   endAngle: endAngle
								  clockwise: NO];
}

- (void) appendBezierPathWithArcFromPoint:(NSPoint)point1
								  toPoint:(NSPoint)point2
								   radius:(float)radius
{
	float x1 = point1.x;
	float y1 = point1.y;
	float dx1, dy1, dx2, dy2;
	float l, a1, a2;
	NSPoint p;
	if (_count == 0)
		[NSException raise:NSGenericException format:@"trying to append arc to empty path"];
	p = [self currentPoint];
	
	dx1 = p.x - x1;
	dy1 = p.y - y1;
	
	if ((l = dx1*dx1 + dy1*dy1) <= 0)	// can't be negative - but simply be sure...
		{
		[self lineToPoint: point1];
		return;
		}
	l = 1.0/sqrt(l);
	dx1 *= l;
	dy1 *= l;
	
	dx2 = point2.x - x1;
	dy2 = point2.y - y1;
	
	if ((l = dx2*dx2 + dy2*dy2) <= 0)
		{
		[self lineToPoint: point1];
		return;
		}
	
	l = 1.0/sqrt(l);
	dx2 *= l; 
	dy2 *= l;
	
	if ((l = dx1*dx2 + dy1*dy2) < -0.999)
		{
		[self lineToPoint: point1];
		return;
		}
	
	l = radius/sin(acos(l));
	p.x = x1 + (dx1 + dx2)*l;
	p.y = y1 + (dy1 + dy2)*l;
	
	if (dx1 < -1)
		a1 = 180;
	else if (dx1 > 1)
		a1 = 0;
	else
		a1 = acos(dx1)*(180/M_PI);
	if (dy1 < 0)
		a1 = -a1;
	
	if (dx2 < -1)
		a2 = 180;
	else if (dx2 > 1)
		a2 = 0;
	else
		a2 = acos(dx2)*(180/M_PI);
	if (dy2 < 0)
		a2 = -a2;
	
	if ((dx1*dy2 - dx2*dy1) < 0)
		{
		a2 = a2 - 90;
		a1 = a1 + 90;
		[self appendBezierPathWithArcWithCenter: p  
										 radius: radius
									 startAngle: a1  
									   endAngle: a2  
									  clockwise: NO];
		}
	else
		{
		a2 = a2 + 90;
		a1 = a1 - 90;
		[self appendBezierPathWithArcWithCenter: p  
										 radius: radius
									 startAngle: a1  
									   endAngle: a2  
									  clockwise: YES];
		}
}

- (void) appendBezierPathWithGlyph:(NSGlyph)glyph
							inFont:(NSFont *)font
{
	[self appendBezierPathWithGlyphs:&glyph 
							   count:1
							  inFont:font];
}

- (void) appendBezierPathWithGlyphs:(NSGlyph *)glyphs 
							  count:(int)count
							 inFont:(NSFont *)font
{
	BACKEND;	// libFreetype can provide and override this as a category
}

- (void) appendBezierPathWithPackedGlyphs:(const char *)packedGlyphs
{
	BACKEND;
}

- (BOOL) cachesBezierPath	{ return NO; }	// no effect
- (void) setCachesBezierPath:(BOOL) flag	{ return; }	// no effect

- (void) encodeWithCoder:(NSCoder *)aCoder			// NSCoding protocol
{
	NSBezierPathElement type;
	NSPoint pts[3];
	int i, count;
	float f = [self lineWidth];
	
	[aCoder encodeValueOfObjCType: @encode(float) at: &f];
	[aCoder encodeValueOfObjCType: @encode(unsigned int) at: &_bz];
	
	count = [self elementCount];
	[aCoder encodeValueOfObjCType: @encode(int) at: &count];
	
	for(i = 0; i < count; i++) 
		{
		type = [self elementAtIndex: i associatedPoints: pts];
		[aCoder encodeValueOfObjCType: @encode(NSBezierPathElement) at: &type];
		switch(type) 
			{
			case NSMoveToBezierPathElement:
			case NSLineToBezierPathElement:
				[aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
				break;
			case NSCurveToBezierPathElement:
				[aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
				[aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[1]];
				[aCoder encodeValueOfObjCType: @encode(NSPoint) at: &pts[2]];
				break;
			case NSClosePathBezierPathElement:
			default:
				break;
			}
		}
}

- (id) initWithCoder:(NSCoder *)aCoder
{
	/*
	 NSSegments
	 NSLineWidth
	 NSFlatness
	*/
	
	NSBezierPathElement type;
	NSPoint pts[3];
	int i, count;
	float f;

	self=[self init];

	if([aCoder allowsKeyedCoding])
		{
		return NIMP;
		}

	[aCoder decodeValueOfObjCType: @encode(float) at: &f];
	[self setLineWidth: f];
	[aCoder decodeValueOfObjCType: @encode(unsigned int) at: &_bz];
	_bz.shouldRecalculateBounds = YES;
	
	[aCoder decodeValueOfObjCType: @encode(int) at: &count];
	
	for(i = 0; i < count; i++) 
		{
		[aCoder decodeValueOfObjCType: @encode(NSBezierPathElement) at: &type];
		switch(type) 
			{
			case NSMoveToBezierPathElement:
				[aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
				[self moveToPoint: pts[0]];
			case NSLineToBezierPathElement:
				[aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
				[self lineToPoint: pts[0]];
				break;
			case NSCurveToBezierPathElement:
				[aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[0]];
				[aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[1]];
				[aCoder decodeValueOfObjCType: @encode(NSPoint) at: &pts[2]];
				[self curveToPoint: pts[0] controlPoint1: pts[1] controlPoint2: pts[2]];
				break;
			case NSClosePathBezierPathElement:
				[self closePath];
			default:
				break;
			}
		}
	
	return self;
}

- (id) copyWithZone:(NSZone *) zone		// NSCopying Protocol
{
	NSBezierPath *path = (NSBezierPath*) NSCopyObject (self, 0, zone);
	int i;
	if(!path)
		return nil;	// could not create copy
	if (_dashPattern != NULL)
		{
		float *pattern = objc_malloc(_dashCount * sizeof(*pattern));
		memcpy(pattern, _dashPattern, _dashCount * sizeof(*pattern));
		path->_dashPattern = pattern;
		}
	
	path->_bPath = objc_malloc(_capacity * sizeof(void *));
	for (i = 0; i < _count; i++)
		{
		PathElement *e = objc_malloc(sizeof(PathElement));
		*e = *(PathElement *)_bPath[i];
		path->_bPath[i] = e;
		}
	return path;
}

- (void) setAssociatedPoints:(NSPoint *)points atIndex:(int)index
{
	PathElement *e;
	if (index < 0 || index >= _count)
		[NSException raise:NSRangeException format:@"Bad Index"];
	e = _bPath[index];
	switch(e->type) 
		{
		case NSMoveToBezierPathElement:
		case NSLineToBezierPathElement:
			e->points[0] = points[0];
			break;
		case NSCurveToBezierPathElement:
			e->points[0] = points[0];
			e->points[1] = points[1];
			e->points[2] = points[2];
			break;
		case NSClosePathBezierPathElement:
		default:
			break;
		}
	_bz.shouldRecalculateBounds = YES;
}

- (BOOL) containsPoint:(NSPoint)point
{
	NSPoint draftPolygon[PMAX];
	int i, pcount = 0;
	double cx, cy;							// Coordinates of the current point
	double lx, ly;							// Coordinates of the last point
	int Rcross = 0;
	int Lcross = 0;	
	NSPoint p, pts[3];
	double x, y, t, k = 0.25;
	
	if(!_count || !NSPointInRect(point, [self bounds]))
		return NO;
	// FIX ME: This does not handle multiple segments!
	for(i = 0; i < _count; i++) 
		{
		NSBezierPathElement e = [self elementAtIndex: i associatedPoints: pts];
		
		if(e == NSMoveToBezierPathElement || e == NSLineToBezierPathElement) 
			{
			draftPolygon[pcount].x = pts[0].x;
			draftPolygon[pcount].y = pts[0].y;
			
			pcount++;
			} 
		else if(e == NSCurveToBezierPathElement) 
			{
			if(pcount) 
				{
				p.x = draftPolygon[pcount -1].x;
				p.y = draftPolygon[pcount -1].y;
				} 
			else 
				{
				p.x = pts[0].x;
				p.y = pts[0].y;
				}
			
			for(t = k; t <= 1+k; t += k) 
				{
				x = (p.x+t*(-p.x*3+t*(3*p.x-p.x*t)))+
				t*(3*pts[0].x+t*(-6*pts[0].x+pts[0].x*3*t))+
				t*t*(pts[1].x*3-pts[1].x*3*t)+pts[2].x*t*t*t;
				y = (p.y+t*(-p.y*3+t*(3*p.y-p.y*t)))+
					t*(3*pts[0].y+t*(-6*pts[0].y+pts[0].y*3*t))+
					t*t*(pts[1].y*3-pts[1].y*3*t)+pts[2].y*t*t*t;
				
				draftPolygon[pcount].x = x;
				draftPolygon[pcount].y = y;
				pcount++;
				}
			}
		
		if (pcount == PMAX)						// Simple overflow check
			return NO;
		}  
	
	lx = draftPolygon[pcount - 1].x - point.x;
	ly = draftPolygon[pcount - 1].y - point.y;
	for(i = 0; i < pcount; i++) 
		{
		cx = draftPolygon[i].x - point.x;
		cy = draftPolygon[i].y - point.y;
		if(cx == 0 && cy == 0)							// on a vertex
			return NO;
		
		if((cy > 0)  && !(ly > 0)) 
			{
			if (((cx * ly - lx * cy) / (ly - cy)) > 0)
				Rcross++;
			}
		if((cy < 0 ) && !(ly < 0)) 
			{ 
			if (((cx * ly - lx * cy) / (ly - cy)) < 0)
				Lcross++;		
			}
		lx = cx;
		ly = cy;
		}
	
	if((Rcross % 2) != (Lcross % 2))
		return NO;										// On the border
	
	return ((Rcross % 2) == 1) ? YES : NO;
}

@end  /* NSBezierPath */

static void
flatten(NSPoint coeff[], float flatness, NSBezierPath *path)
{
	// Check if the Bezier path defined by the four points has the given flatness.
	// If not split it up in the middle and recurse. 
	// Otherwise add the end point to the path.
	BOOL flat = YES;
	
	/*  This criteria for flatness is based on code from Libart which has the 
	following copyright:
	
		  Libart_LGPL - library of basic graphic primitives
		  Copyright (C) 1998 Raph Levien
	*/
	double x1_0, y1_0;
	double x3_2, y3_2;
	double x3_0, y3_0;
	double z3_0_dot;
	double z1_dot, z2_dot;
	double z1_perp, z2_perp;
	double max_perp_sq;
	
	x3_0 = coeff[3].x - coeff[0].x;
	y3_0 = coeff[3].y - coeff[0].y;
	x3_2 = coeff[3].x - coeff[2].x;
	y3_2 = coeff[3].y - coeff[2].y;
	x1_0 = coeff[1].x - coeff[0].x;
	y1_0 = coeff[1].y - coeff[0].y;
	z3_0_dot = x3_0 * x3_0 + y3_0 * y3_0;
	
	if (z3_0_dot < 0.001)
		flat = YES;
	else
		{
		max_perp_sq = flatness * flatness * z3_0_dot;
		
		z1_perp = y1_0 * x3_0 - x1_0 * y3_0;
		if (z1_perp * z1_perp > max_perp_sq)
			flat = NO;
		else
			{
			z2_perp = y3_2 * x3_0 - x3_2 * y3_0;
			if (z2_perp * z2_perp > max_perp_sq)
				flat = NO;
			else
				{
				z1_dot = x1_0 * x3_0 + y1_0 * y3_0;
				if (z1_dot < 0 && z1_dot * z1_dot > max_perp_sq)
					flat = NO;
				else
					{
					z2_dot = x3_2 * x3_0 + y3_2 * y3_0;
					if (z2_dot < 0 && z2_dot * z2_dot > max_perp_sq)
						flat = NO;
					else
						{
						if ((z1_dot + z1_dot > z3_0_dot) ||
							(z2_dot + z2_dot > z3_0_dot))
							flat = NO;
						}	}	}	}	}
	
	if (!flat)
		{
		NSPoint bleft[4], bright[4];
		
		bleft[0] = coeff[0];
		bleft[1].x = (coeff[0].x + coeff[1].x) / 2;
		bleft[1].y = (coeff[0].y + coeff[1].y) / 2;
		bleft[2].x = (coeff[0].x + 2*coeff[1].x + coeff[2].x) / 4;
		bleft[2].y = (coeff[0].y + 2*coeff[1].y + coeff[2].y) / 4;
		bleft[3].x = (coeff[0].x + 3*(coeff[1].x + coeff[2].x) + coeff[3].x) / 8;
		bleft[3].y = (coeff[0].y + 3*(coeff[1].y + coeff[2].y) + coeff[3].y) / 8;
		bright[0].x =  bleft[3].x;
		bright[0].y =  bleft[3].y;
		bright[1].x = (coeff[3].x + 2*coeff[2].x + coeff[1].x) / 4;
		bright[1].y = (coeff[3].y + 2*coeff[2].y + coeff[1].y) / 4;
		bright[2].x = (coeff[3].x + coeff[2].x) / 2;
		bright[2].y = (coeff[3].y + coeff[2].y) / 2;
		bright[3] = coeff[3];
		
		flatten(bleft, flatness, path);
		flatten(bright, flatness, path);
		}
	else
		{
		//[path lineToPoint: coeff[1]];
		//[path lineToPoint: coeff[2]];
		[path lineToPoint: coeff[3]];
		}
}

