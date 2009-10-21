//
//  ScreenSaverView.m
//  ScreenSaver
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "ScreenSaverView.h"


@implementation ScreenSaverView

+ (NSBackingStoreType) backingStoreType; { return NSBackingStoreBuffered; }
+ (BOOL) performGammaFade; { return YES; }

- (id) initWithFrame:(NSRect) frame; { return [self initWithFrame:frame isPreview:NO]; }

- (id) initWithFrame:(NSRect) frame isPreview:(BOOL) flag
{
    self = [super initWithFrame:frame];
    if (self)
		{
		_isPreview=flag;
		}
    return self;
}

- (void) drawRect:(NSRect) rect
{
    [[NSColor blackColor] set];
	NSRectFill(rect);
}

- (void) animateOneFrame; { return; }

- (void) _animateOneFrame;
{
	[self lockFocus];
	[self animateOneFrame];
	[self unlockFocus];
}

- (NSTimeInterval) animationTimeInterval; { return _animationTimeInterval; }
- (NSWindow *) configureSheet; { return nil; }
- (BOOL) hasConfigureSheet; { return NO; }
- (BOOL) isAnimating; { return _timer != nil; }
- (BOOL) isPreview; { return _isPreview; }
- (void) setAnimationTimeInterval:(NSTimeInterval) interval; { _animationTimeInterval=interval; }

- (void) startAnimation;
{
	if(_timer)
		return;	// already...
	_timer=[NSTimer scheduledTimerWithTimeInterval:_animationTimeInterval target:self selector:@selector(_animateOneFrame) userInfo:nil repeats:YES];
}

- (void) stopAnimation;
{
	[_timer invalidate];
	_timer=nil;
}

@end

NSRect SSCenteredRectInRect(NSRect inner, NSRect outer)
{
	return NSMakeRect(floorf(0.5*(NSWidth(outer) - NSWidth(inner))),
					  floorf(0.5*(NSHeight(outer) - NSHeight(inner))),
					  NSWidth(inner),
					  NSHeight(inner));
}

float SSRandomFloatBetween(float a, float b)
{
	float r=0.5;
	if(a < b)
		return a+(b-a)*r;
	else
		return b+(a-b)*r;
	return a;
}

int SSRandomIntBetween(int a, int b)
{
	float r=0.5;
	if(a < b)
		return a+(b-a)*r;
	else
		return b+(a-b)*r;
	return a;
}

NSPoint SSRandomPointForSizeWithinRect(NSSize size, NSRect rect)
{
	return NSMakePoint(floorf(SSRandomFloatBetween(NSMinX(rect), NSMaxX(rect) - size.width)),
                       floorf(SSRandomFloatBetween(NSMinY(rect), NSMaxY(rect) - size.height)));
}
