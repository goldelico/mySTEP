//
//  ScreenSaverView.h
//  ScreenSaver
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ScreenSaverView : NSView
{
	NSTimer *_timer;
	NSTimeInterval _animationTimeInterval;
	BOOL _isPreview;
}

+ (NSBackingStoreType) backingStoreType;
+ (BOOL) performGammaFade;

- (void) animateOneFrame;
- (NSTimeInterval) animationTimeInterval;
- (NSWindow *) configureSheet;
- (BOOL) hasConfigureSheet;
- (id) initWithFrame:(NSRect) frame isPreview:(BOOL) flag;
- (BOOL) isAnimating;
- (BOOL) isPreview;
- (void) setAnimationTimeInterval:(NSTimeInterval) interval;
- (void) startAnimation;
- (void) stopAnimation;

@end

extern NSRect SSCenteredRectInRect(NSRect inner, NSRect outer);
extern float SSRandomFloatBetween(float a, float b);
extern int SSRandomIntBetween(int a, int b);
extern NSPoint SSRandomPointForSizeWithinRect(NSSize size, NSRect rect);

// EOF
