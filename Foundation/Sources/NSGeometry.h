/* 
   NSGeometry.h

   Interface to geometry routines

   Copyright (C) 1995 Free Software Foundation, Inc.
   
   Author:  Adam Fedor <fedor@boulder.colorado.edu>
   Date:	1995
   mySTEP:  Felipe A. Rodriguez <farz@mindspring.com>
   Date:	January 1999
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSGeometry
#define _mySTEP_H_NSGeometry

#import <Foundation/NSObjCRuntime.h>	// define BOOL etc.

@class NSString;

typedef struct _NSPoint
{
	float x;
	float y;
} NSPoint, *NSPointArray, *NSPointPointer;

typedef struct _NSSize
{
	float width;
	float height;
} NSSize, *NSSizeArray, *NSSizePointer;

typedef struct _NSRect
{
	NSPoint origin;
	NSSize size;
} NSRect, *NSRectArray, *NSRectPointer;

typedef enum _NSRectEdge
{
	NSMinXEdge,
	NSMinYEdge,
	NSMaxXEdge,
	NSMaxYEdge
} NSRectEdge;

extern NSPoint NSZeroPoint;  						// A zero point
extern NSRect  NSZeroRect;    						// A zero origin rectangle
extern NSSize  NSZeroSize;    						// A zero size rectangle

#if 1	// use macros instead of function calls (tradeoff speed for code size)

#define NSMakePoint(x, y)		((NSPoint){(float) (x), (float) (y)})
#define NSMakeSize(w, h)		((NSSize){(float) (w), (float) (h)})
#define NSMakeRect(x, y, w, h)	((NSRect){{(float) (x), (float) (y)}, {(float) (w), (float) (h)}})

#else

// Returns an NSPoint having x-coordinate X and y-coordinate Y
extern NSPoint NSMakePoint(float x, float y);
				// Returns NSSize having width WIDTH and height HEIGHT
extern NSSize  NSMakeSize(float w, float h);
				// Returns NSRect having point of origin (X, Y) and size {W, H}
extern NSRect  NSMakeRect(float x, float y, float w, float h);

#endif

#define	NSMaxX(aRect)	((aRect).origin.x + (aRect).size.width)  // max x coord
#define	NSMaxY(aRect)	((aRect).origin.y + (aRect).size.height) // max y coord
#define	NSMidX(aRect)	((float) (NSMinX(aRect) + 0.5f*NSWidth(aRect)))	 // mid x coord
#define	NSMidY(aRect)	((float) (NSMinY(aRect) + 0.5f*NSHeight(aRect)))	 // mid y coord
#define	NSMinX(aRect)	((aRect).origin.x)						 // min x coord
#define	NSMinY(aRect)	((aRect).origin.y)						 // min y coord
#define	NSWidth(aRect)	((aRect).size.width)					 // rect width
#define	NSHeight(aRect)	((aRect).size.height)					 // rect height

						// Returns the rectangle obtained by moving each of 
						// ARECT's horizontal sides inward by DY and each of 
						// ARECT's vertical sides inward by DX.
extern NSRect NSInsetRect(NSRect aRect, float dX, float dY);

						// Returns the rectangle obtained by translating ARECT
						// horizontally by DX and vertically by DY
extern NSRect NSOffsetRect(NSRect aRect, float dX, float dY);

						// Divides ARECT into two rectangles (namely SLICE and 
						// REMAINDER) by "cutting" ARECT---parallel to, and a 
						// distance AMOUNT from the edge v of ARECT determined 
						// by EDGE.  You may pass 0 in as either of SLICE or
						// REMAINDER to avoid obtaining either of the created 
						// rectangles.
extern void NSDivideRect(NSRect aRect,
						NSRect *slice,
						NSRect *remaind,	// name conflict with math.h remainder()
						float amount,
						NSRectEdge edge);

						// Returns a rect obtained by expanding ARECT minimally
						// so that all four of its defining components are ints
extern NSRect NSIntegralRect(NSRect aRect);

						// Returns the smallest rectangle which contains both 
						// ARECT and BRECT (modulo a set of measure zero).  If 
						// either of ARECT or BRECT is an empty rectangle, then 
						// the other rectangle is returned.  If both are empty, 
						// then the empty rectangle is returned.
extern NSRect NSUnionRect(NSRect aRect, NSRect bRect);

						// Returns the largest rect which lies in both ARECT 
						// and BRECT.  If ARECT & BRECT have empty intersection 
						// (or, rather, intersection of measure zero, since 
						// this includes having their intersection be only a 
						// point or a line), then the empty rect is returned.
extern NSRect NSIntersectionRect(NSRect aRect, NSRect bRect);

						// Returns 'YES' if ARECT's and BRECT's origin and size 	
						// are the same.
extern BOOL NSEqualRects(NSRect aRect, NSRect bRect);

						// Returns 'YES' if ASIZE's and BSIZE's width and 
						// height are the same.
extern BOOL NSEqualSizes(NSSize aSize, NSSize bSize);

						// Returns 'YES' iff APOINT's and BPOINT's x- and 
						// y-coordinates are the same. */
extern BOOL NSEqualPoints(NSPoint aPoint, NSPoint bPoint);

						// Returns 'YES' iff the area of ARECT is zero (if 
						// either ARECT's width or height is negative or zero).
extern BOOL NSIsEmptyRect(NSRect aRect);

						// Returns 'YES' iff APOINT is inside ARECT.
extern BOOL NSMouseInRect(NSPoint aPoint, NSRect aRect, BOOL flipped);
extern BOOL NSPointInRect(NSPoint aPoint, NSRect aRect);

						// Returns 'YES' if ARECT totally encloses BRECT.  For
						// this to be the case, ARECT cannot be empty, nor can 
						// any side of BRECT coincide with any side of ARECT.
extern BOOL NSContainsRect(NSRect aRect, NSRect bRect);

						// Returns Yes if aRect intersects bRect.
extern BOOL NSIntersectsRect(NSRect aRect, NSRect bRect);

					// Returns an NSString of the form "{x=X; y=Y}", where X  
					// and Y are the x-, y-coordinates of APOINT, respectively.
extern NSString * NSStringFromPoint(NSPoint aPoint);

					// Returns an NSString of the form "{x=X; y=Y; width=W; 
					// height=H}", where X, Y, W, and H are the x-coordinate, 
					// y-coordinate, width, and height of ARECT, respectively.
extern NSString * NSStringFromRect(NSRect aRect);

					// Returns an NSString of the form "{width=W; height=H}", 
					// where W and H are the width and height of ASIZE.
extern NSString * NSStringFromSize(NSSize aSize);

extern NSPoint NSPointFromString(NSString *string);
extern NSSize  NSSizeFromString(NSString *string);
extern NSRect  NSRectFromString(NSString *string);

#endif /* _mySTEP_H_NSGeometry */
