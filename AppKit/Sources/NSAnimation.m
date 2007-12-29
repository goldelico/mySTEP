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
#import <AppKit/NSWindow.h>
#import <AppKit/NSView.h>

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
		if(!curve)
			_animationCurve=NSAnimationEaseInOut;
		else
			_animationCurve=curve;
		_animationBlockingMode=NSAnimationBlocking;	// default is blocking
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
#if 1
	NSLog(@"_animate progress=%f", progress);
#endif
	if(progress > 1.0)
		{ // done
		[_timer invalidate];
		[_timer release];
		_timer=nil;
		[_startDate release];
		[_delegate animationDidEnd:self];
		return;
		}
	// check if we have reached any progress mark(s)
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
		NSRunLoop *loop=[NSRunLoop currentRunLoop];
		NSString *mode=[loop currentMode];
		_startDate=[NSDate new];
		_timer=[[NSTimer timerWithTimeInterval:1.0/_frameRate target:self selector:@selector(_animate:) userInfo:nil repeats:YES] retain];
		switch(_animationBlockingMode)
			{
			case NSAnimationBlocking:
				{
					[loop addTimer:_timer forMode:mode];
					while(_timer)	// stopAnimation should break this loop
						[loop runMode:mode beforeDate:[NSDate distantFuture]];
					break;
				}
			case NSAnimationNonblockingThreaded:
				NSLog(@"can't schedule threaded: %@", self);
			case NSAnimationNonblocking:
				{ // schedule in all specified modes
					NSArray *modes=[self runLoopModesForAnimating];	// schedule only in specified modes
					if(modes)
						{ // schedule in all specified modes
						NSEnumerator *e=[modes objectEnumerator];
						while((mode=[e nextObject]))
							[loop addTimer:_timer forMode:mode];
						}
					else
						[loop addTimer:_timer forMode:mode];	// schedule in current mode
					break;
				}
			}
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
	// if blocking - break runloop
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

- (void) animation:(NSAnimation *) animation didReachProgressMark:(NSAnimationProgress) progress;
{
	NSEnumerator *e=[_viewAnimations objectEnumerator];
	NSDictionary *dict;
#if 1
	NSLog(@"NSViewAnimation didReachProgressMark:%f", progress);
#endif
	while((dict=[e nextObject]))
		{ // process all animations
		id target=[dict objectForKey:NSViewAnimationTargetKey];
		NSRect start=[[dict objectForKey:NSViewAnimationStartFrameKey] rectValue];
		NSRect delta=[[dict objectForKey:@"delta"] rectValue];
		NSString *effect=[dict objectForKey:NSViewAnimationEffectKey];
		delta.origin.x = start.origin.x + progress*delta.origin.x;
		delta.origin.y = start.origin.y + progress*delta.origin.y;
		delta.size.width = start.size.width + progress*delta.size.width;
		delta.size.height = start.size.height + progress*delta.size.height;
		// handle effect
#if 1
		NSLog(@"new frame %@", NSStringFromRect(delta));
#endif
		if([target isKindOfClass:[NSWindow class]])
			[target setFrame:delta display:YES];
		else
			[target setFrame:delta];
		}
}

- (id) initWithViewAnimations:(NSArray *) animations;
{
	NSEnumerator *e=[animations objectEnumerator];
	NSDictionary *dict;
	while((dict=[e nextObject]))
		{
		id target=[dict objectForKey:NSViewAnimationTargetKey];
		NSRect start;
		NSRect end;
		id val;
		if(!target)
			{
			[self release];
			return nil;
			}
		val=[dict objectForKey:NSViewAnimationStartFrameKey];
		if(val)
			start=[val rectValue];
		else
			start=[target frame];
		val=[dict objectForKey:NSViewAnimationEndFrameKey];
		if(val)
			end=[val rectValue];
		else
			end=[target frame];
		// substitute and store start and delta
		}
	if((self=[super initWithDuration:0.5 animationCurve:NSAnimationEaseInOut]))
		{
		_viewAnimations=[animations retain];
		[self setAnimationBlockingMode:NSAnimationNonblocking];
		[self setDelegate:self];
#if 0
		- (NSTimeInterval) animationResizeTime:(NSRect) rect
			{
				static float t=0.0;
				float chg;	// pixels of change
				if(t == 0.0)
					{
					// replace by NSWindowResizeTime from NSUserDefaults if defined
					t=0.2;	// default
					t/=150.0;	// time per 150 pixels movement
					}
				chg = fabs(rect.origin.x-frame.origin.x);
				chg += fabs(rect.origin.y-frame.origin.y);
				chg += fabs(rect.size.width-frame.size.width);
				chg += fabs(rect.size.height-frame.size.height);
				return chg*t;
			}
#endif
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
