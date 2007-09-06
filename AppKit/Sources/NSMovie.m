/*
 *  NSMovie.m
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import <AppKit/NSMovie.h>
#import <AppKit/NSMovieView.h>
#import <AppKit/NSColor.h>

#ifndef __linux__
@interface QTMovie : NSObject
#else
@interface xxxQTMovie : NSObject	// gcc 2.95.3 does not accept method names identical to class names
#endif
- (id) initWithURL:(NSURL *) url error:(NSError *) err;
@end

static Class __qtmovie;		// runtime link to QTMovie framework

@implementation NSMovie 

+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pasteboard;
{
	return NO;
}

+ (NSArray*) movieUnfilteredFileTypes;
{
	return [NSArray arrayWithObjects:@"mpeg", nil];
}

+ (NSArray*) movieUnfilteredPasteboardTypes;
{
	return [NSArray arrayWithObjects:@"mpeg", nil];
}

- (id) initWithMovie:(void*) movie;
{
	if((self=[super init]))
		{
		_qtmovie=[(NSObject *) movie retain];
		}
	return self;
}

- (id) initWithPasteboard:(NSPasteboard *) pasteboard;
{
	return NIMP;
}

- (id) initWithURL:(NSURL *) url byReference:(BOOL) byRef;
{
	if(!__qtmovie)
		{
		__qtmovie=NSClassFromString(@"QTMovie");
		if(!__qtmovie)
			{
			NSLog(@"Not linked with QTMovie");
			// we could also try [[NSBundle bundleWithPath:@"/System/Library/Frameworks/QTKit.framework"] load];
			return nil;
			}
		}
	if((self=[self initWithMovie:[[__qtmovie alloc] initWithURL:url error:NULL]]))
		{
		_url=[url retain];
		_byRef=byRef;
		}
	return self;
}

- (void) dealloc;
{
	[(NSObject *) _qtmovie release];
	[_url release];
	[super dealloc];
}

- (void *) QTMovie;
{
	return _qtmovie;
}

- (NSURL*) URL;
{
	return _url;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
		{
		}
	return self;
}

@end

@implementation NSMovieView

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
		{
		_movie=[[coder decodeObjectForKey:@"NSMovie"] retain];
		_rate=[coder decodeFloatForKey:@"NSRate"];
		[coder decodeBoolForKey:@"NSEditable"];
		[coder decodeBoolForKey:@"NSControllerVisible"];
		[coder decodeFloatForKey:@"NSVolume"];
		[coder decodeIntForKey:@"NSLoopMode"];
		}
	return self;
}

- (void) dealloc;
{
	[_movie release];
	[super dealloc];
}

// use timer...

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
	// draw current/next frame
}

- (BOOL) isMuted;		{ return _isMuted; }
- (BOOL) isPlaying;		{ return _isPlaying; }
- (NSMovie *) movie;	{ return _movie; }
- (float) rate;			{ return _rate; }
- (void) setMovie:(NSMovie *) movie;	{ ASSIGN(_movie, movie); }
- (void) setRate:(float) rate;	{ _rate=rate; }	// should call [[_movie QTMovie] setRate:] 

/*
 
- (IBAction) delete:(id) sender;
- (IBAction) cut:(id) sender;
- (IBAction) copy:(id) sender;
- (IBAction) paste:(id) sender;

- (IBAction) start:(id) sender;
- (IBAction) stop:(id) sender;
- (IBAction) gotoBeginning:(id) sender; { [[_movie QTMovie] gotoBeginning]; }
- (IBAction) gotoEnd:(id) sender;
- (IBAction) gotoPosterFrame:(id) sender;
- (IBAction) stepBack:(id) sender;
- (IBAction) stepForward:(id) sender;
- (IBAction) fastForward:(id) sender;
- (IBAction) fastBackward:(id) sender;

*/

@end