/* 

   NSGraphicsContext.h

   Abstract Context (drawing destination) superclass.  

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    Nov 1998
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4

   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _NSGraphicsContext_h_INCLUDE
#define _NSGraphicsContext_h_INCLUDE

#import <Foundation/NSObject.h>
#import <AppKit/NSGraphics.h>

@class NSAffineTransform;
@class NSColor;
@class NSFont;
@class NSDictionary;
@class NSBitmapImageRep;
@class NSWindow;

extern NSString *NSGraphicsContextDestinationAttributeName;
extern NSString *NSGraphicsContextRepresentationFormatAttributeName;

extern NSString *NSGraphicsContextPDFFormat;	
extern NSString *NSGraphicsContextPSFormat;

typedef enum _NSImageInterpolation
{
	NSImageInterpolationDefault,
	NSImageInterpolationNone,
	NSImageInterpolationLow,
	NSImageInterpolationHigh
} NSImageInterpolation;

typedef NSInteger NSColorRenderingIntent;

enum {
	NSColorRenderingIntentDefault,
	NSColorRenderingIntentAbsoluteColorimetric,
	NSColorRenderingIntentRelativeColorimetric,
	NSColorRenderingIntentPerceptual,
	NSColorRenderingIntentSaturation
};

@interface NSGraphicsContext : NSObject
{
@private
	void *_focusStack;
@public
	void *_graphicsState;	// top of graphics state stack
	void *_graphicsPort;	// the underlying graphics object
	// the following should probably be part of the current graphics state (?)
	NSPoint _patternPhase;
	NSCompositingOperation _compositingOperation;
	NSImageInterpolation _imageInterpolation;
	BOOL _shouldAntialias;
	BOOL _isFlipped;
}

+ (NSGraphicsContext *) currentContext;
+ (BOOL) currentContextDrawingToScreen;
+ (NSGraphicsContext *) graphicsContextWithAttributes:(NSDictionary *) attr;
+ (NSGraphicsContext *) graphicsContextWithBitmapImageRep:(NSBitmapImageRep *) rep;
+ (NSGraphicsContext *) graphicsContextWithGraphicsPort:(void *) port flipped:(BOOL) flag;
+ (NSGraphicsContext *) graphicsContextWithWindow:(NSWindow *) window;
+ (void) restoreGraphicsState;
+ (void) saveGraphicsState;
+ (void) setCurrentContext:(NSGraphicsContext *) context;
+ (void) setGraphicsState:(NSInteger) state;

- (NSDictionary *) attributes;
- (NSColorRenderingIntent) colorRenderingIntent; 
- (NSCompositingOperation) compositingOperation;
- (void) flushGraphics;
- (void *) focusStack;
- (void *) graphicsPort;
- (NSImageInterpolation) imageInterpolation;
- (BOOL) isDrawingToScreen;
- (BOOL) isFlipped;
- (NSPoint) patternPhase;
- (void) restoreGraphicsState;
- (void) saveGraphicsState;
- (void) setColorRenderingIntent:(NSColorRenderingIntent) intent;
- (void) setCompositingOperation:(NSCompositingOperation) operation;
- (void) setFocusStack:(void *) stack;
- (void) setImageInterpolation:(NSImageInterpolation) interpolation;
- (void) setPatternPhase:(NSPoint) phase;
- (void) setShouldAntialias:(BOOL) flag;
- (BOOL) shouldAntialias;

@end

#endif /* _NSGraphicsContext_h_INCLUDE */
