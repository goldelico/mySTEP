//
//  NSAnimation.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSAnimation
#define _mySTEP_H_NSAnimation

#import <Foundation/Foundation.h>

typedef enum _NSAnimationCurve
{
	NSAnimationEaseInOut=0,	// default
	NSAnimationEaseIn,
	NSAnimationEaseOut,
	NSAnimationLinear
} NSAnimationCurve;

typedef enum _NSAnimationBlockingMode
{
	NSAnimationBlocking,
	NSAnimationNonblocking,
	NSAnimationNonblockingThreaded
} NSAnimationBlockingMode;

typedef float NSAnimationProgress;

extern NSString *NSAnimationProgressMarkNotification;

@interface NSAnimation : NSObject <NSCopying, NSCoding>
{
	NSAnimationBlockingMode _animationBlockingMode;
	NSAnimationCurve _animationCurve;
	NSAnimationProgress _currentProgress;
	NSMutableArray *_progressMarks;
	NSDate *_startDate;
	NSTimer *_timer;
	id _delegate;
	NSTimeInterval _duration;
	float _progress;
	float _currentValue;
	float _frameRate;
	BOOL _isAnimating;	// ?or the NSThread *
}

- (void) addProgressMark:(NSAnimationProgress) progress;
- (NSAnimationBlockingMode) animationBlockingMode;
- (NSAnimationCurve) animationCurve;
- (void) clearStartAnimation;
- (void) clearStopAnimation;
- (NSAnimationProgress) currentProgress;
- (float) currentValue;
- (id) delegate;
- (NSTimeInterval) duration;
- (float) frameRate;
- (id) initWithDuration:(NSTimeInterval) duration animationCurve:(NSAnimationCurve) curve;
- (BOOL) isAnimating;
- (NSArray *) progressMarks;
- (void) removeProgressMark:(NSAnimationProgress) progress;
- (NSArray *) runLoopModesForAnimating;
- (void) setAnimationBlockingMode:(NSAnimationBlockingMode) mode;
- (void) setAnimationCurve:(NSAnimationCurve) curve;
- (void) setCurrentProgress:(NSAnimationProgress) progress;
- (void) setDelegate:(id) delegate;
- (void) setDuration:(NSTimeInterval) duration;
- (void) setFrameRate:(float) fps;
- (void) setProgressMarks:(NSArray *) progress;
- (void) startAnimation;
- (void) startWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) start;
- (void) stopAnimation;
- (void) stopWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) stop;

@end


@interface NSObject (NSAnimation)

- (void) animation:(NSAnimation *) animation didReachProgressMark:(NSAnimationProgress) progress;
- (float) animation:(NSAnimation *) animation valueForProgress:(NSAnimationProgress) progress;
- (void) animationDidEnd:(NSAnimation *) animation;
- (void) animationDidStop:(NSAnimation *) animation;
- (BOOL) animationShouldStart:(NSAnimation *) animation;

@end


extern NSString *NSViewAnimationTargetKey;
extern NSString *NSViewAnimationStartFrameKey;
extern NSString *NSViewAnimationEndFrameKey;
extern NSString *NSViewAnimationEffectKey;
extern NSString *NSViewAnimationFadeInEffect;
extern NSString *NSViewAnimationFadeOutEffect;

@interface NSViewAnimation : NSAnimation
{
	NSArray *_viewAnimations;
}

- (id) initWithViewAnimations:(NSArray *) animations;
- (void) setWithViewAnimations:(NSArray *) animations;
- (NSArray *) viewAnimations;

@end

#endif /* _mySTEP_H_NSAnimation */
