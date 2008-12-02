/*
 *  NSMovieView.h
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSMovie.h>
#import <AppKit/NSView.h>

typedef enum
{
	NSQTMovieNormalPlayback=0,
	NSQTMovieLoopingPlayback,
	NSQTMovieLoopingBackAndForthPlayback
} NSQTMovieLoopMode;

@interface NSMovieView : NSView
{
	NSMovie *_movie;
	float _rate;
	BOOL _isPlaying;
	BOOL _isMuted;
}

- (NSMovie *) movie;
- (void) setMovie:(NSMovie *) movie;

- (IBAction) delete:(id) sender;
- (IBAction) cut:(id) sender;
- (IBAction) copy:(id) sender;
- (IBAction) paste:(id) sender;

- (IBAction) start:(id) sender;
- (IBAction) stop:(id) sender;
- (BOOL) isPlaying;
- (IBAction) gotoBeginning:(id) sender;
- (IBAction) gotoEnd:(id) sender;
- (IBAction) gotoPosterFrame:(id) sender;
- (IBAction) stepBack:(id) sender;
- (IBAction) stepForward:(id) sender;
- (BOOL) isMuted;
- (float) rate;
- (void) setRate:(float) rate;
- (IBAction) fastForward:(id) sender;
- (IBAction) fastBackward:(id) sender;

@end
