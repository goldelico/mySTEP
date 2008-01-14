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

struct _NSViewAnimation
{ // private structure
	NSRect start;
	NSRect delta;
	id target;
	int effect;
	BOOL windowTarget;
};

- (void) animation:(NSAnimation *) animation didReachProgressMark:(NSAnimationProgress) progress;
{
	int i;
	struct _NSViewAnimation *record=_private;
	for(i=0; i<_count; i++)
		{ // process all animations
		NSRect pos;
#if 1
	NSLog(@"NSViewAnimation didReachProgressMark:%f", progress);
#endif
		pos.origin.x = record->start.origin.x + progress*record->delta.origin.x;
		pos.origin.y = record->start.origin.y + progress*record->delta.origin.y;
		pos.size.width = record->start.size.width + progress*record->delta.size.width;
		pos.size.height = record->start.size.height + progress*record->delta.size.height;
		// handle effect
#if 1
		NSLog(@"new frame %@", NSStringFromRect(pos));
#endif
		if(record->windowTarget)
			[record->target setFrame:pos display:YES];
		else
			[record->target setFrame:pos];
		record++;
		}
}

- (id) initWithViewAnimations:(NSArray *) animations;
{
	if((self=[super initWithDuration:0.5 animationCurve:NSAnimationEaseInOut]))
		{
		NSEnumerator *e=[animations objectEnumerator];
		NSDictionary *dict;
		struct _NSViewAnimation *record;
		_viewAnimations=[animations retain];
		_count=[animations count];
		record=_private=objc_malloc(_count*sizeof(struct _NSViewAnimation));
		while((dict=[e nextObject]))
			{ // translate into internal data
			id val;
			record->target=[dict objectForKey:NSViewAnimationTargetKey];
			if(!record->target)
				{ // missing
				[self release];
				return nil;
				}
			//
			// kill from any other animation using this target!!!
			//
			record->windowTarget=[record->target isKindOfClass:[NSWindow class]];
			val=[dict objectForKey:NSViewAnimationStartFrameKey];
			if(val)
				record->start=[val rectValue];
			else
				record->start=[record->target frame];
			val=[dict objectForKey:NSViewAnimationEndFrameKey];
			if(val)
				record->delta=[val rectValue];
			else
				record->delta=[record->target frame];
			record->delta.origin.x-=record->start.origin.x;
			record->delta.origin.y-=record->start.origin.y;
			record->delta.size.width-=record->start.size.width;
			record->delta.size.height-=record->start.size.height;
			val=[dict objectForKey:NSViewAnimationEffectKey];
			// store effect
			record++;
			}
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
	if(_private);
		objc_free(_private);
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
