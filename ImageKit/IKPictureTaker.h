//
//  IKPictureTaker.h
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface IKPictureTaker : NSPanel
{
	IBOutlet NSImageView *_image;
	BOOL _mirroring;
}

+ (IKPictureTaker *) pictureTaker;

- (void) beginPictureTakerSheetForWindow:(NSWindow *) win withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (void) beginPictureTakerVithDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (NSImage *) inputImage;
- (BOOL) mirroring;
- (NSImage *) outputImage;
- (void) popUpRecentsMenuForView:(NSView *) view withDelegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;
- (NSInteger) runModal;
- (void) setInputImage:(NSImage *) image;
- (void) setMirroring:(BOOL) flag;

@end

// to be used in setValue:forKey:

extern NSString *IKPictureTakerAllowsVideoCaptureKey;
// etc.
