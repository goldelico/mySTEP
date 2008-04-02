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
		{ // create one
		}
	return taker;
}

- (void) beginPictureTakerSheetForWindow:(NSWindow *) win withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (void) beginPictureTakerVithDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (NSImage *) inputImage;
- (BOOL) mirroring;
- (NSImage *) outputImage;
- (void) popUpRecentsMenuForView:(NSView *) view withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (NSInteger) runModal;
- (void) setInputImage:(NSImage *) image;
- (void) setMirroring:(BOOL) flag;

- (id) valueForKey:(NSString *) key;
{
}

- (void) setValue:(id) val forKey:(NSString *) key;
{
	// decode keys directly and modify the panel subviews (e.g. un/hide buttons)
}

@end
