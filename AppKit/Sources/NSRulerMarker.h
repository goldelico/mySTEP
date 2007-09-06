/*
   NSRulerMarker.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSRulerMarker
#define _mySTEP_H_NSRulerMarker

#import <Foundation/NSObject.h>

@class NSRulerView;
@class NSImage;

@interface NSRulerMarker : NSObject <NSObject, NSCopying>

- (id)initWithRulerView:(NSRulerView *)aRulerView
		 markerLocation:(float)location
		 image:(NSImage *)anImage
		 imageOrigin:(NSPoint)imageOrigin; 

- (NSRulerView *)ruler; 

- (void)setImage:(NSImage *)anImage; 
- (NSImage *)image;

- (void)setImageOrigin:(NSPoint)aPoint; 
- (NSPoint)imageOrigin; 
- (NSRect)imageRectInRuler; 
- (float)thicknessRequiredInRuler; 

- (void)setMovable:(BOOL)flag;
- (BOOL)isMovable; 
- (void)setRemovable:(BOOL)flag; 
- (BOOL)isRemovable; 

- (void)setMarkerLocation:(float)location; 
- (float)makerLocation; 

- (void)setRepresentedObject:(id <NSCopying>)anObject; 
- (id <NSCopying>)representedObject;

- (void)drawRect:(NSRect)aRect;
- (BOOL)isDragging; 
- (BOOL)trackMouse:(NSEvent *)event adding:(BOOL)flag; 

@end

#endif /* _mySTEP_H_NSRulerMarker */
