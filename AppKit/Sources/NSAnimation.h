/*
  NSAnimation.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI. Hinweis: Methoden verglichen, alles drin

  Author:	Fabian Spillner
  Date:		16. October 2007 
 
  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:		05. November 2007 - aligned with 10.5
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAnimation
#define _mySTEP_H_NSAnimation

#import <Foundation/Foundation.h>

enum
{
	NSAnimationEaseInOut=0,	// default
	NSAnimationEaseIn,
	NSAnimationEaseOut,
	NSAnimationLinear
};

typedef NSUInteger NSAnimationCurve;

enum
{
	NSAnimationBlocking,
	NSAnimationNonblocking,
	NSAnimationNonblockingThreaded
};

typedef NSUInteger NSAnimationBlockingMode;

extern NSString *NSAnimationTriggerOrderIn; 
extern NSString *NSAnimationTriggerOrderOut; 

typedef float NSAnimationProgress;

extern NSString *NSAnimationProgressMarkNotification;
extern NSString *NSAnimationProgressMark;

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
- (void) setCurrentProgress:(NSAnimationProgress) currentProgress;
- (void) setDelegate:(id) delegate;
- (void) setDuration:(NSTimeInterval) duration;
- (void) setFrameRate:(float) fps;
- (void) setProgressMarks:(NSArray *) progresses;
- (void) startAnimation;
- (void) startWhenAnimation:(NSAnimation *) ani reachesProgress:(NSAnimationProgress) start;
- (void) stopAnimation;
- (void) stopWhenAnimation:(NSAnimation *) ani reachesProgress:(NSAnimationProgress) stop;

@end


@interface NSObject (NSAnimation)

- (void) animation:(NSAnimation *) ani didReachProgressMark:(NSAnimationProgress) progressMark;
- (float) animation:(NSAnimation *) ani valueForProgress:(NSAnimationProgress) progressValue;
- (void) animationDidEnd:(NSAnimation *) ani;
- (void) animationDidStop:(NSAnimation *) ani;
- (BOOL) animationShouldStart:(NSAnimation *) ani;

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


@protocol NSAnimatablePropertyContainer

+ (id) defaultAnimationForKey:(NSString *) key; 

- (id) animationForKey:(NSString *) key; 
- (NSDictionary *) animations; 
- (id)animator; 
- (void) setAnimations:(NSDictionary *) animations; 

@end

extern NSString *NSAnimationTriggerOrderIn;
extern NSString *NSAnimationTriggerOrderOut;

#endif /* _mySTEP_H_NSAnimation */
