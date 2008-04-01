/*
   NSAffineTransform.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	August 1997
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	01. April 2008 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAffineTransform
#define _mySTEP_H_NSAffineTransform

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

typedef struct _NSAffineTransformStruct
{
	float m11, m12, m21, m22;
	float tX, tY;
} NSAffineTransformStruct;


@interface NSAffineTransform : NSObject <NSCopying>
{
	NSAffineTransformStruct _ats;
	BOOL _isIdentity;	// special case: A=D=1 and B=C=0
	BOOL _isFlipY;		// special case: A=1 D=-1 and B=C=0
}

+ (NSAffineTransform *) transform;

- (void) appendTransform:(NSAffineTransform *) transform;
- (id) initWithTransform:(NSAffineTransform *) transform;
- (void) invert;
- (void) prependTransform:(NSAffineTransform *) transform;
- (void) rotateByDegrees:(CGFloat) angle;
- (void) rotateByRadians:(CGFloat) angle;
- (void) scaleBy:(CGFloat) scale;
- (void) scaleXBy:(CGFloat) sx yBy:(CGFloat) sy;
- (void) setTransformStruct:(NSAffineTransformStruct) transformStruct;
- (NSPoint) transformPoint:(NSPoint) point;
- (NSSize) transformSize:(NSSize) size;
- (NSAffineTransformStruct) transformStruct;
- (void) translateXBy:(CGFloat) deltaX yBy:(CGFloat) deltaY;

@end

#endif /* _mySTEP_H_NSAffineTransform */
