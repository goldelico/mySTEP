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
#import <AppKit/NSApplication.h>

NSString *NSAnimationProgressMarkNotification=@"NSAnimationProgressMarkNotification";
NSString *NSAnimationProgressMark=@"NSAnimationProgressMark";

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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSAnimationProgressMarkNotification object:_startAnimation];
	[_startAnimation removeProgressMark:_startAnimationProgress];
	[_startAnimation release];
	_startAnimation=nil;
}

- (void) clearStopAnimation;
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSAnimationProgressMarkNotification object:_stopAnimation];
	[_stopAnimation removeProgressMark:_stopAnimationProgress];
	[_stopAnimation release];
	_stopAnimation=nil;
}

- (NSAnimationProgress) currentProgress; { return _currentProgress; }

- (float) currentValue;
{ // transform [0..1] -> [0..1]
	if([_delegate respondsToSelector:@selector(animation:valueForProgress:)])
		return [_delegate animation:self valueForProgress:_currentProgress];
#if 0
	NSLog(@"currentValue from progress %f with curve %d", _currentProgress, _animationCurve);
#endif
	switch(_animationCurve)
	{
		case NSAnimationEaseInOut:
			if(_currentProgress < 0.5)
				return 2.0*_currentProgress*_currentProgress;	// slowly speed up from start
			else
				return 1.0-2.0*((1.0-_currentProgress)*(1.0-_currentProgress));	// slow down at end
		case NSAnimationEaseIn:
			return 1.0-((1.0-_currentProgress)*(1.0-_currentProgress));	// slow down at end
		case NSAnimationEaseOut:
			return _currentProgress*_currentProgress;	// slowly speed up from start
		case NSAnimationLinear:
			return _currentProgress;					
	}
#if 1
	NSLog(@"undefined curve %lu", (unsigned long)_animationCurve);
#endif
	return 0.0;
}

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
	[_timer release];
	[_startDate release];
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
	NSEnumerator *e;
	NSNumber *mark;
#if 0
	NSLog(@"_animate progress=%f", progress);
#endif
	e=[_progressMarks objectEnumerator];
	if(progress > 1.0)
		progress=1.0;	// limit
	while((mark=[e nextObject]))
		{ // send any intermediate marks
			float m=[mark floatValue];
			if(m > _currentProgress && m <= progress)
				{
					// send NSAnimationProgressMarkNotification where the delegate should be registered
					[_delegate animation:self didReachProgressMark:progress];	// WARNING: this is not necessarily ascending order!
				}
		}
	[self setCurrentProgress:progress];
	if(_currentProgress >= 1.0)	// test iVar if setCurrentProgress was redefined in subclass...
		{ // done
			[_timer invalidate];	// this will auto-remove the timer from runloops
			[_timer release];
			_timer=nil;
			[_startDate release];
			_startDate=nil;
			[_delegate animationDidEnd:self];
#if 1
			NSLog(@"animationDidEnd");
#endif
			[self release];
		}
}

- (void) startAnimation;
{
#if 1
	NSLog(@"startAnimation");
#endif
	if(!_timer && (!_delegate || [_delegate animationShouldStart:self]))
		{
			NSRunLoop *loop=[NSRunLoop currentRunLoop];
			[self retain];	// protect us from being deallocated while the timer is running (or does a notification registration retain its target?)
			_startDate=[NSDate new];
			_timer=[[NSTimer timerWithTimeInterval:_frameRate>0?(1.0/_frameRate):(1/50.0) target:self selector:@selector(_animate:) userInfo:nil repeats:YES] retain];
			[self setCurrentProgress:0.0];	// we can't have marks at 0.0
#if 0
			NSLog(@"animation started with timer %@", _timer);
#endif
			switch(_animationBlockingMode)
			{
				case NSAnimationBlocking:
				{ // run in custom mode blocking user interaction
					[loop addTimer:_timer forMode:@"NSAnimation"];
					while(_timer)	// stopAnimation should break this loop
						[loop runMode:@"NSAnimation" beforeDate:[NSDate distantFuture]];
					break;
				}
				case NSAnimationNonblockingThreaded:
					NSLog(@"can't schedule NSAnimationNonblockingThreaded: %@", self);
				case NSAnimationNonblocking:
				{ // schedule in all specified modes
					NSArray *modes=[self runLoopModesForAnimating];	// schedule only in specified modes
					if(modes)
						{ // schedule in all specified modes
							NSEnumerator *e=[modes objectEnumerator];
							NSString *mode;
							while((mode=[e nextObject]))
								[loop addTimer:_timer forMode:mode];
						}
					else
						{ // schedule in default modes
							[loop addTimer:_timer forMode:NSDefaultRunLoopMode];
							[loop addTimer:_timer forMode:NSModalPanelRunLoopMode];
							[loop addTimer:_timer forMode:NSEventTrackingRunLoopMode];
						}
					break;
				}
			}
#if 1
			NSLog(@"timer scheduled: %@", _timer);
#endif
		}
}

- (void) _startAnimation:(NSNotification *) n
{ // conditional start of animation
	NSString *m;
	if([n object] == _startAnimation && (m=[[n userInfo] objectForKey:NSAnimationProgressMark]) && [m floatValue] == _startAnimationProgress)
		[self startAnimation];	// yeah!
}

- (void) startWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) start;
{ // make us observe the other animation
	[self clearStartAnimation];
	[animation addProgressMark:start];
	_startAnimation=[animation retain];	// remember
	_startAnimationProgress=start;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_startAnimation:) name:NSAnimationProgressMarkNotification object:animation];
}

- (void) stopAnimation;
{
#if 1
	NSLog(@"stopAnimation");
#endif
	if(_timer)
		{ // was started
			[self autorelease];
			[_timer invalidate];
			[_timer release];
			_timer=nil;	// if blocking, this also breaks runloop
			[_startDate release];
			_startDate=nil;
		}
	[_delegate animationDidStop:self];
}

- (void) _stopAnimation:(NSNotification *) n
{ // conditional start of animation
	NSString *m;
	if([n object] == _stopAnimation && (m=[[n userInfo] objectForKey:NSAnimationProgressMark]) && [m floatValue] == _stopAnimationProgress)
		[self stopAnimation];	// yeah!
}

- (void) stopWhenAnimation:(NSAnimation *) animation reachesProgress:(NSAnimationProgress) stop;
{ // make us observe the other animation
	[self clearStartAnimation];
	_stopAnimation=[animation retain];	// remember
	_stopAnimationProgress=stop;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_stopAnimation:) name:NSAnimationProgressMarkNotification object:animation];
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

- (void) setCurrentProgress:(NSAnimationProgress) progress;
{ // overwrite this method so that we don't modify the progress marks and delegate mechanisms
	int i;
	float percentage;
	struct _NSViewAnimation *record=_private;
#if 0
	NSLog(@"NSViewAnimation setCurrentProgress %f", progress);
#endif
	[super setCurrentProgress:progress];
	percentage=[self currentValue];	// get percentage (using curve)
#if 0
	NSLog(@"  progress=%f percentage=%f for %d targets", _currentProgress, percentage, _count);
#endif
	for(i=0; i<_count; i++)
		{ // process all animations
			NSRect pos;
#if 0
			NSLog(@"NSViewAnimation setCurrentProgress:%f with value: %f", progress, percentage);
#endif
#if 1
			NSLog(@"effect=%d", record->effect);
#endif
			if(!record->target)
				continue;	// ignore nil target
			pos.origin.x = record->start.origin.x + percentage*record->delta.origin.x;
			pos.origin.y = record->start.origin.y + percentage*record->delta.origin.y;
			pos.size.width = record->start.size.width + percentage*record->delta.size.width;
			pos.size.height = record->start.size.height + percentage*record->delta.size.height;
#if 1
			NSLog(@"new frame %@", NSStringFromRect(pos));
#endif
			if(record->windowTarget)
				[record->target setFrame:pos display:YES];	// NSWindow
			else
				{ // NSView
					[record->target setFrame:pos];
					[record->target setNeedsDisplay:YES];
				}
			if(record->effect)
				{
					if(progress == 0.0 && record->effect > 0)
						{ // start of fade in
#if 1
							NSLog(@"start of fade in");
#endif
							if(record->windowTarget)
								[record->target orderFront:self];
							else
								[record->target setHidden:NO];	// unhide
						}
					else if(progress == 1.0 && record->effect < 0)
						{ // end of fade out
#if 1
							NSLog(@"end of fade out");
#endif
							if(record->windowTarget)
								[record->target orderOut:self];
							else
								[record->target setHidden:YES];	// hide view
						}
					// set alpha of window or view based on percentage (fade in) or 1-percentage (fade out)
				}
			record++;
		}
#if 1
	NSLog(@"NSViewAnimation setCurrentProgress done");
#endif
}

- (void) startAnimation
{ // create internal tables
	NSEnumerator *e=[_viewAnimations objectEnumerator];
	NSDictionary *dict;
	struct _NSViewAnimation *record=_private=objc_realloc(_private, (_count=[_viewAnimations count])*sizeof(*record));	// adjust size if necessary/allocate
	while((dict=[e nextObject]))
		{ // translate into internal data
			id val;
			record->target=[dict objectForKey:NSViewAnimationTargetKey];
			if(record->target)
				{
					//
					// kill from any other animation active for this target since they may interfere!!!
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
					if([val isEqualToString:NSViewAnimationFadeInEffect])
						record->effect=1;
					else if([val isEqualToString:NSViewAnimationFadeOutEffect])
						record->effect=-1;
					else
						record->effect=0;
				}
			record++;
		}
#if 0
	// This is from NSWindow
	// should be used to calculate the optimal duration
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
	[super startAnimation];
}

- (id) initWithViewAnimations:(NSArray *) animations;
{
	if((self=[super initWithDuration:0.5 animationCurve:NSAnimationEaseInOut]))
		{
		_viewAnimations=[animations retain];
		[self setAnimationBlockingMode:NSAnimationNonblocking];
		}
	return self;
}

- (void) dealloc;
{
	if(_private)
		objc_free(_private);
	[_viewAnimations release];
	[super dealloc];
}

- (void) setWithViewAnimations:(NSArray *) animations; { ASSIGN(_viewAnimations, animations); }
- (NSArray *) viewAnimations; { return _viewAnimations; }

@end

@implementation NSObject (NSAnimation)

- (void) animation:(NSAnimation *) ani didReachProgressMark:(NSAnimationProgress) progressMark; { return; }
- (void) animationDidEnd:(NSAnimation *) ani; { return; }
- (void) animationDidStop:(NSAnimation *) ani; { return; }
- (BOOL) animationShouldStart:(NSAnimation *) ani; { return NO; }	// delegate must override

@end
