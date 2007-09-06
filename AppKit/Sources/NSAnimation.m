//
//  NSAnimation.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Mar 06 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <AppKit/NSAnimation.h>

NSString *NSAnimationProgressMarkNotification=@"NSAnimationProgressMarkNotification";

NSString *NSViewAnimationTargetKey=@"NSViewAnimationTargetKey";
NSString *NSViewAnimationStartFrameKey=@"NSViewAnimationStartFrameKey";
NSString *NSViewAnimationEndFrameKey=@"NSViewAnimationEndFrameKey";
NSString *NSViewAnimationEffectKey=@"NSViewAnimationEffectKey";
NSString *NSViewAnimationFadeInEffect=@"NSViewAnimationFadeInEffect";
NSString *NSViewAnimationFadeOutEffect=@"NSViewAnimationFadeOutEffect";

@implementation NSAnimation

- (void) addProgressMark:(NSAnimationProgress) progress;
{
	if(progress > 1.0)
		progress=1.0;
	else if(progress < 0.0)
		progress=0.0;
	[_progressMarks addObject:[NSNumber numberWithFloat:progress]];
}

- (NSAnimationBlockingMode) animationBlockingMode; { return _animationBlockingMode; }
- (NSAnimationCurve) animationCurve; { return _animationCurve; }

- (void) clearStartAnimation;
{
	NIMP;
}

- (void) clearStopAnimation;
{
	NIMP;
}

- (NSAnimationProgress) currentProgress; { return _currentProgress; }
- (float) currentValue; { return _currentValue; }
- (id) delegate; { return _delegate; }
- (NSTimeInterval) duration; { return _duration; }
- (float) frameRate; { return _frameRate; }

- (id) initWithDuration:(NSTimeInterval) duration animationCurve:(NSAnimationCurve) curve;
{
	if((self=[super init]))
		{
		_duration=duration;
		_animationCurve=curve;
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone;
{
	return NIMP;
}

- (void) dealloc;
{
	[_progressMarks release];
	[super dealloc];
}

- (BOOL) isAnimating; { return _timer != nil; }
- (NSArray *) progressMarks; { return _progressMarks; }

- (void) removeProgressMark:(NSAnimationProgress) progress;
{
	NSEnumerator *e=[_progressMarks objectEnumerator];
	NSNumber *n;
	while((n=[e nextObject]))
		if([n floatValue] == progress)
			[_progressMarks removeObjectIdenticalTo:n];
}

- (NSArray *) runLoopModesForAnimating;
{
	return nil;	// default means any mode
}

- (void) setAnimationBlockingMode:(NSAnimationBlockingMode) mode; { _animationBlockingMode=mode; }
- (void) setAnimationCurve:(NSAnimationCurve) curve; { _animationCurve=curve; }
- (void) setCurrentProgress:(NSAnimationProgress) progress; { _currentProgress=progress; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDuration:(NSTimeInterval) duration; { _duration=duration; }
- (void) setFrameRate:(float) fps; { _frameRate=fps; }

- (void) setProgressMarks:(NSArray *) progress; { [_progressMarks autorelease]; _progressMarks=[progress mutableCopy]; }

- (void) _animate:(NSTimer *) timer;
{ // called every 1/fps seconds from NSTimer
	float progress=[[NSDate date] timeIntervalSinceDate:_startDate]/_duration;
	if(progress > 1.0)
		{ // done
		[_timer invalidate];
		[_timer release];
		_timer=nil;
		[_startDate release];
		[_delegate animationDidEnd:self];
		return;
		}
	// check if we have reached progress mark(s)
	// call for any progress mark between _progress and newprogress
	// [_delegate animation:self didReachProgressMark:progress];
	_progress=progress;
	if([_delegate respondsToSelector:@selector(animation:valueForProgress:)])
		 [self setCurrentProgress:[_delegate animation:self valueForProgress:progress]];
	else
		; // use built-in curve
}

- (void) startAnimation;
{
	if(!_timer && [_delegate animationShouldStart:self])
		{
		_startDate=[NSDate new];
		[self runLoopModesForAnimating];	// schedule only in specified modes
		_timer=[[NSTimer scheduledTimerWithTimeInterval:1.0/_frameRate target:self selector:@selector(_animate:) userInfo:nil repeats:YES] retain];
		}
}

- (void) startWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) start;
{ // make us observe the other animation
	[self clearStartAnimation];
	// save the start progress value
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnimation) name:NSAnimationProgressMarkNotification object:animation];
}

- (void) stopAnimation;
{
		[_timer invalidate];
		[_timer release];
		_timer=nil;
		[_startDate release];
		[_delegate animationDidStop:self];
}

- (void) stopWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) stop;
{
	// save the stop progress value
	[self clearStartAnimation];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnimation) name:NSAnimationProgressMarkNotification object:animation];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end

@implementation NSViewAnimation

- (id) initWithViewAnimations:(NSArray *) animations;
{
	if((self=[super init]))
		{
		_viewAnimations=[animations retain];
		}
	return self;
}

- (void) dealloc;
{
	[_viewAnimations release];
	[super dealloc];
}

- (void) setCurrentProgress:(NSAnimationProgress) progress;
{
	// go through dict and adjust view parameters
	[super setCurrentProgress:progress];
}

- (void) setWithViewAnimations:(NSArray *) animations; { ASSIGN(_viewAnimations, animations); }
- (NSArray *) viewAnimations; { return _viewAnimations; }

@end
