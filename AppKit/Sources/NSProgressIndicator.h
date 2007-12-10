/*
 NSProgressIndicator.h
 
 Copyright (C) 1999 Free Software Foundation, Inc.
 
 Author:  Gerrit van Dyk <gerritvd@decimax.com>
 Date: 1999
 
 Author:	Fabian Spillner <fabian.spillner@gmail.com>
 Date:		04. December 2007 - aligned with 10.5 
 
 This file is part of the GNUstep GUI Library.
 
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
 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 */

#ifndef _GNUstep_H_NSProgressIndicator
#define _GNUstep_H_NSProgressIndicator

#import <AppKit/NSView.h>

@class NSTimer;
@class NSThread;

/* For NSControlTint */
#import <AppKit/NSColor.h>

/* For NSControlSize */
#import <AppKit/NSCell.h>

typedef enum _NSProgressIndicatorThickness {
	NSProgressIndicatorPreferredThickness       = 14,
	NSProgressIndicatorPreferredSmallThickness  = 10,
	NSProgressIndicatorPreferredLargeThickness  = 18,
	NSProgressIndicatorPreferredAquaThickness   = 12
} NSProgressIndicatorThickness;

typedef enum _NSProgressIndicatorStyle
{
	NSProgressIndicatorBarStyle			= 0,
	NSProgressIndicatorSpinningStyle	= 1
} NSProgressIndicatorStyle;

@interface NSProgressIndicator : NSView	
{
	double						_doubleValue;
	double						_minValue;
	double						_maxValue;
	NSTimer						*_timer;
	NSThread					*_thread;
	NSTimeInterval				_animationDelay;
	NSProgressIndicatorStyle	_style;
	int							_count;  
	BOOL						_isIndeterminate;
	BOOL						_isBezeled;
	BOOL						_usesThreadedAnimation;
	BOOL						_isVertical;
	BOOL						_isDisplayedWhenStopped;
	BOOL						_isRunning;
}

- (NSControlSize) controlSize;
- (NSControlTint) controlTint;
- (double) doubleValue;
- (void) incrementBy:(double) delta;
- (BOOL) isBezeled;
- (BOOL) isDisplayedWhenStopped;
- (BOOL) isIndeterminate;
- (double) maxValue;
- (double) minValue;
- (void) setBezeled:(BOOL) flag;
- (void) setControlSize:(NSControlSize) size;
- (void) setControlTint:(NSControlTint) tint;
- (void) setDisplayedWhenStopped:(BOOL) flag;
- (void) setDoubleValue:(double) aValue;
- (void) setIndeterminate:(BOOL) flag;
- (void) setMaxValue:(double) newMaximum;
- (void) setMinValue:(double) newMinimum;
- (void) setStyle:(NSProgressIndicatorStyle) flag;
- (void) setUsesThreadedAnimation:(BOOL) flag;
- (void) sizeToFit;
- (void) startAnimation:(id) sender;
- (void) stopAnimation:(id) sender;
- (NSProgressIndicatorStyle) style;
- (BOOL) usesThreadedAnimation;

@end

@interface NSProgressIndicator (Deprecated)

- (void) animate:(id) sender; /* DEPRECATED */
- (NSTimeInterval) animationDelay; /* DEPRECATED */
- (void) setAnimimationDelay:(NSTimeInterval) delay; /* DEPRECATED */

@end

#ifndef NO_GNUSTEP
@interface NSProgressIndicator (GNUstepExtensions)

/*
 * Enables Vertical ProgressBar
 *
 * If isVertical = YES, Progress is from the bottom to the top
 * If isVertical = NO, Progress is from the left to the right
 */
- (BOOL)isVertical;
- (void)setVertical:(BOOL)flag;

@end
#endif

#endif /* _GNUstep_H_NSProgressIndicator */
