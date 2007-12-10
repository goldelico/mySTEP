/*
   NSRulerMarker.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	04. December 2007 - aligned with 10.5  
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSRulerMarker
#define _mySTEP_H_NSRulerMarker

#import <Foundation/NSObject.h>

@class NSRulerView;
@class NSImage;

@interface NSRulerMarker : NSObject <NSObject, NSCopying>

- (void) drawRect:(NSRect) aRect;
- (NSImage *) image;
- (NSPoint) imageOrigin; 
- (NSRect) imageRectInRuler; 
- (id) initWithRulerView:(NSRulerView *) aRulerView 
		  markerLocation:(CGFloat) location 
				   image:(NSImage *) anImage 
			 imageOrigin:(NSPoint) imageOrigin; 
- (BOOL) isDragging; 
- (BOOL) isMovable; 
- (BOOL) isRemovable; 
- (CGFloat) makerLocation; 
- (id <NSCopying>) representedObject;
- (NSRulerView *) ruler; 
- (void) setImage:(NSImage *) anImage; 
- (void) setImageOrigin:(NSPoint) aPoint; 
- (void) setMarkerLocation:(CGFloat) location; 
- (void) setMovable:(BOOL) flag;
- (void) setRemovable:(BOOL) flag; 
- (void) setRepresentedObject:(id <NSCopying>) anObject; 
- (CGFloat) thicknessRequiredInRuler; 
- (BOOL) trackMouse:(NSEvent *) event adding:(BOOL) flag; 

@end

#endif /* _mySTEP_H_NSRulerMarker */
