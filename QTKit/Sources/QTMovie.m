/*
 *  NSMovie.m
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import <QTKit/QTMovie.h>

@implementation QTMovie

- (void) rewindMovie;
{
	[self windMovieTo:0.0];
}

- (float) movieLength;   // in seconds
{
	return 10.0;
}

- (BOOL) windMovieTo:(float) pos;
{ // position is in seconds
	if(pos < 0.0 || pos > [self movieLength])
		return NO;
	_position=pos;
	return YES;
}

- (NSImage *) movieFrame;				// get current frame
{
	return nil;
}

- (float) moviePosition;					// current time stamp
{
	return _position;
}

- (float) nextMovieFrame;				// go to next frame and return time stamp
{
	return 0.5;
}

@end

#if OTHER

@implementation NSStreamSplitter

- (void) dealloc;
{
	[_source release];
	[_destinations release];
	[super dealloc];
}

- (NSStream *) source; { return _source; }
- (void) setSource:(NSStream *) source; { [_source autorelease]; _source=[source retain]; [source setDelegate:self]; }
- (void) addDestination:(NSOutputStream *) handler; { if(!_destinations) _destinations=[[NSMutableArray alloc] initWithCapacity:5]; [_destinations addObject:handler]; }
- (void) removeDestination:(NSOutputStream *) handler; { [_destinations removeObject:handler]; }

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event;
{ // pass to all handlers
	NSEnumerator *e=[_destinations objectEnumerator];
	id handler;
	while((handler=[e nextObject]))
		[handler stream:self handleEvent:event];
}

@end

#endif

@implementation NSMovieView
//
// use this for a simple movie player in NSMovieView
// init movie with File-URL/CameraMovie
// [movie rewind];
// get length
// save start_time
// while(real_time-start_time < length)
//   [movie windTo:real_time-start_time];   // this will resample at available speed
//   [ImageView setImage:[movie frame]];	// show current frame
//   [ImageView display];   // and display
//   // wait nextMovieFrame-real_time - so we do not process this frame several times
//

- (BOOL) isOpaque; { return YES; }	// completely fills its background

- (void) drawRect:(NSRect) rect
{ // Drawing code here.
	[[NSColor blueColor] set];
	NSRectFill(rect);	// draw background
	// draw current frame
}

@end
