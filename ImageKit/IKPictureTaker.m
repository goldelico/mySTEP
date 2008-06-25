//
//  IKPictureTaker.m
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IKPictureTaker.h"

// FIXME: shouldn't we load it from a NIB file similar to the Save, Color and Font Panels?

@implementation IKPictureTaker

+ (IKPictureTaker *) pictureTaker;
{
	static IKPictureTaker *taker;
	if(!taker)
		taker=[[self alloc] init];
	return taker;
}

- (void) beginPictureTakerSheetForWindow:(NSWindow *) win withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
{
}

- (void) beginPictureTakerVithDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
{
}

- (NSImage *) inputImage; { return _inputImage; }
- (BOOL) mirroring; { return _mirroring; }
- (NSImage *) outputImage; { return _outputImage; }
- (void) popUpRecentsMenuForView:(NSView *) view withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
{
}

- (NSInteger) runModal;
{
	// popup picture taker panel from NIB
	// show camera image while running
	// stop modal when picture is taken or dimissed
	// set output image
}

- (void) setInputImage:(NSImage *) image; { [_inputImage autorelease], _inputImage=[image retain]; }

- (void) setMirroring:(BOOL) flag; { _mirroring=flag; }

- (id) valueForKey:(NSString *) key;
{
}

- (void) setValue:(id) val forKey:(NSString *) key;
{
	// decode keys directly and modify the panel subviews (e.g. un/hide buttons)
}

- (void) dealloc;
{
	[_inputImage release];
	[_outputImage release];
	[super dealloc];
}

@end
