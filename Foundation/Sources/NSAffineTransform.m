/*
   NSAffineTransform.m

   Copyright (B) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	August 1997
   
   Author:	H. Nikolaus Schaller <hns@computer.org>
   Date:	May 2006 - some bugs fixed, heavily reworked to optimize identity and flipping transforms
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#include <math.h>

#import <Foundation/NSAffineTransform.h>
#import <Foundation/NSException.h>
#import <Foundation/NSString.h>

#define A	_ats.m11
#define B	_ats.m21
#define C	_ats.m12
#define D	_ats.m22
#define TX	_ats.tX
#define TY	_ats.tY

//	An Affine Transform look like this:
//
//    [  a  b  0 ]
//    [  c  d  0 ]
//    [ tx ty  1 ]
//

static const float pi = 3.1415926535897932384626433;

#if 0
#define check() if(!((_isIdentity && A==1.0 && B==0.0 && C==0.0 && D==1.0) || (_isFlipY && A==1.0 && B==0.0 && C==0.0 && D==-1.0) || !(_isIdentity&&_isFlipY))) NSLog(@"*** Invalid matrix flags: %@ ***", self)
#else
#define check()
#endif

@implementation NSAffineTransform

+ (NSAffineTransform *) transform
{
	NSAffineTransform *m = [NSAffineTransform alloc];
	if(m)
		{ // init identity matrix which transforms any point to itself
		m->A = m->D = 1.0;
		m->_isIdentity=YES;
		}
	return [m autorelease]; 
}

+ (NSAffineTransform *) new
{ // inline init to speed up by some microseconds...
	NSAffineTransform *m = [NSAffineTransform alloc];
	if(m)
		{ // init identity matrix
		m->A = m->D = 1;
		m->_isIdentity=YES;
		}
	return m;
}

- (id) initWithTransform:(NSAffineTransform *)aTransform
{
	if((self=[super init]))
		{
		_ats = aTransform->_ats;
		_isIdentity = aTransform->_isIdentity;
		_isFlipY = aTransform->_isFlipY;
		check();
		}
	return self;
}

- (id) init
{
	if((self=[super init]))
		{
		A = D = 1;											// init identity matrix
		_isIdentity=YES;
		check();
		}
	return self;
}

- (void) invert											// matrix transform of
{														// (X,Y) yields (X',Y')	
	float newA, newC, newB, newD, newTX, newTY;				// then inverse matrix
	float det;
	if(_isIdentity)
		{ // (1.0, 0.0, 0.0, 1.0) -> det=1.0
		TX = -TX;
		TY = -TY;
		check();
		return;
		}
	if(_isFlipY)
		{ // (1.0, 0.0, 0.0, -1.0) -> det=-1.0
		TX = -TX;
		check();
		return;
		}
	det = A * D - C * B;								// of (X',Y') is (X,Y) 	
	if(det == 0.0)	// FIXME: should we check for fabs(det) < 1e-6 meaning that inverse would be too imprecise?
		[NSException raise: NSInvalidArgumentException format: @"Inverse by zero determinant"];
	
	newA =  D / det;
	newC = -C / det;
	newB = -B / det;
	newD =  A / det;
	newTX = (-D * TX + B * TY) / det;
	newTY = ( C * TX - A * TY) / det;
	
	NSDebugLog (@"inverse of matrix ((%f, %f) (%f, %f) (%f, %f))\n"
				@"is ((%f, %f) (%f, %f) (%f, %f))", A, C, B, D, TX, TY,
				newA, newC, newB, newD, newTX, newTY);
	
	A = newA; C = newC;
	B = newB; D = newD;
	TX = newTX; TY = newTY;
	check();
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSAffineTransform *new = [isa allocWithZone:zone];
	if(new)
		{
		new->_ats = _ats;
		new->_isIdentity = _isIdentity;
		new->_isFlipY = _isFlipY;
		}
	return new;
}

- (void) scaleBy:(float)scale
{
	if(scale == 1.0)
		return;	// ignore
	A *= scale;
	B *= scale;
	C *= scale;
	D *= scale;
	_isIdentity=_isFlipY=NO;
	check();
}

- (void) scaleXBy:(float)sx yBy:(float)sy
{
	if(_isIdentity && sx == 1.0)
		{
		if(sy == 1.0)
			return;	// no scaling
		if(sy == -1.0)
			{ // A=1.0, B=C=0.0
			D= -1.0;
			_isFlipY=YES;
			_isIdentity=NO;
			check();
			return;
			}
		}
	if(_isFlipY && sx == 1.0)
		{
		if(sy == 1.0)
			return;	// no scaling
		if(sy == -1.0)
			{ // A=1.0, B=C=0.0
			D=1.0;
			_isFlipY=NO;
			_isIdentity=YES;
			check();
			return;
			}
		}
	A *= sx;
	C *= sx;
	B *= sy;
	D *= sy;
	_isIdentity=_isFlipY=NO;
	check();
}

- (void) translateXBy:(float)deltaX yBy:(float)deltaY
{
	if(_isIdentity)
		{
		TX+=deltaX;
		TY+=deltaY;
		}
	else if(_isFlipY)
		{
		TX+=deltaX;
		TY-=deltaY;
		}
	else
		{
		TX+= A * deltaX + B * deltaY;
		TY+= C * deltaX + D * deltaY;
		}
	check();
}

- (void) rotateByRadians:(float)angleRad
{
	float newA, newC, newB, newD;
	float sine, cosine;
	if(angleRad == 0.0)
		return;
	sine = sin (angleRad);
	cosine = cos (angleRad);

	newA = A * cosine + B * sine;
	newC = C * cosine + D * sine;
	newB = -A * sine + B * cosine;
	newD = -C * sine + D * cosine;
	
	A = newA; C = newC;
	B = newB; D = newD;
	_isIdentity=_isFlipY=NO;
	check();
}

- (void) rotateByDegrees:(float)angle
{
	static const float deg2rad = 3.1415926535897932384626433/180.0;
	[self rotateByRadians:angle*deg2rad];
}

- (void) appendTransform:(NSAffineTransform*)other
{
	float newA, newC, newB, newD, newTX, newTY;
	if(!other)
		[NSException raise: NSInvalidArgumentException format: @"can't append nil transform"];
	if(other->_isIdentity)
		{
		TX+=other->TX;
		TY+=other->TY;
		check();
		return;
		}
	if(other->_isFlipY)
		; // further optimization
	if(_isIdentity)
		{
		newTX = TX * other->A + TY * other->B + other->TX;
		newTY = TX * other->C + TY * other->D + other->TY;
		_ats = other->_ats;
		TX = newTX; TY = newTY;
		_isIdentity = NO;	// we know...
		_isFlipY = other->_isFlipY;
		check();
		return;
		}
	if(_isFlipY)
		; // further optimization
	newA = A * other->A + C * other->B;
	newC = A * other->C + C * other->D;
	newB = B * other->A + D * other->B;
	newD = B * other->C + D * other->D;
	newTX = TX * other->A + TY * other->B + other->TX;
	newTY = TX * other->C + TY * other->D + other->TY;
	
	A = newA; C = newC;
	B = newB; D = newD;
	TX = newTX; TY = newTY;
	/*_isIdentity=*/_isFlipY=NO;
	check();
}

- (void) prependTransform:(NSAffineTransform*)other
{
	float newA, newC, newB, newD, newTX, newTY;

	if(!other)
		[NSException raise: NSInvalidArgumentException format: @"can't prepend nil transform"];
	if(other->_isIdentity)
		{
		newTX = other->TX * A + other->TY * B + TX;
		newTY = other->TX * C + other->TY * D + TY;
		TX = newTX; TY = newTY;
		check();
		return;
		}
	if(other->_isFlipY)
		; // further optimization
	if(_isIdentity)
		{
		other->TX+=TX;
		other->TY+=TY;
		_ats = other->_ats;
		_isIdentity = NO;	// we know...
		_isFlipY = other->_isFlipY;
		check();
		return;
		}
	if(_isFlipY)
		; // further optimization
	newA = other->A * A + other->C * B;
	newC = other->A * C + other->C * D;
	newB = other->B * A + other->D * B;
	newD = other->B * C + other->D * D;
	newTX = other->TX * A + other->TY * B + TX;
	newTY = other->TX * C + other->TY * D + TY;

	A = newA; C = newC;
	B = newB; D = newD;
	TX = newTX; TY = newTY;
	/*_isIdentity=*/_isFlipY=NO;
	check();
}

- (NSPoint) transformPoint:(NSPoint)point
{
	NSPoint new;
	check();
	if(_isIdentity)
		{
		new.x = point.x + TX;
		new.y = point.y + TY;
		}
	else if(_isFlipY)
		{
		new.x = point.x + TX;
		new.y = - point.y + TY;
		}
	else
		{
		new.x = A * point.x + B * point.y + TX;
		new.y = C * point.x + D * point.y + TY;
		}	
	return new;
}

- (NSSize) transformSize:(NSSize)size
{
	NSSize new;
	check();
	if(_isIdentity)
		return size;
	if(_isFlipY)
		{
		new.width = size.width;
		new.height = -size.height;
		}
	else
		{
		new.width = A * size.width + B * size.height;
		new.height = C * size.width + D * size.height;
		}
	return new;
}

- (NSString*) description
{
	NSString *fmt = @"NSAffineTransform ((%f, %f) (%f, %f) (%f, %f)%@%@)";
	return [NSString stringWithFormat:fmt, A, C, B, D, TX, TY, _isIdentity?@"I":@"", _isFlipY?@"F":@""];
}

- (NSAffineTransformStruct) transformStruct
{
	return _ats;
}

- (void) setTransformStruct:(NSAffineTransformStruct) aTransformStruct
{
	memcpy(&_ats, &aTransformStruct, sizeof(NSAffineTransformStruct));
	_isIdentity=_isFlipY=NO;
}

@end /* NSAffineTransform */
