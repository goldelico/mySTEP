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
	NSMutableDictionary *_attributes;
	IBOutlet NSImageView *_image;
	NSImage *_inputImage;
	NSImage *_outputImage;
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

- (id) valueForKey:(NSString *) key;
- (void) setValue:(id) val forKey:(NSString *) key;

@end

// to be used in setValue:forKey:

extern NSString *IKPictureTakerAllowsVideoCaptureKey;
extern NSString *IKPictureTakerAllowsFileChoosingKey;
extern NSString *IKPictureTakerShowRecentPictureKey;
extern NSString *IKPictureTakerUpdateRecentPictureKey;
extern NSString *IKPictureTakerAllowsEditingKey;
extern NSString *IKPictureTakerShowEffectsKey;
extern NSString *IKPictureTakerInformationalTextKey;
extern NSString *IKPictureTakerImageTransformsKey;
extern NSString *IKPictureTakerOutputImageMaxSizeKey;
extern NSString *IKPictureTakerCropAreaSizeKey;
extern NSString *IKPictureTakerShowAddressBookPictureKey;
extern NSString *IKPictureTakerShowEmptyPictureKey;
