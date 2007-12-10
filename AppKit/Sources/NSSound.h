/* 
   NSSound.h

   Sound container class
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSound
#define _mySTEP_H_NSSound

#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>
#import <Foundation/NSDate.h>

@class NSString;
@class NSData;
@class NSPasteboard;
@class NSImageRep;
@class NSColor;
@class NSView;
@class NSMutableArray;

extern NSString *NSSoundPboardType;

@interface NSSound : NSObject  <NSCoding>
{
	NSString *_name;
	NSURL *_url;
	id _delegate;

	struct __soundFlags {
		UIBITFIELD(unsigned int, dataRetained, 1);
		UIBITFIELD(unsigned int, builtIn, 1);
		UIBITFIELD(unsigned int, archiveByName, 1);
		UIBITFIELD(unsigned int, cacheSeparately, 1);
		UIBITFIELD(unsigned int, isValid, 1);
		UIBITFIELD(unsigned int, isPaused, 1);
		UIBITFIELD(unsigned int, isStopped, 1);
		} _snd;
}

+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pasteboard;
+ (id) soundNamed:(NSString *) name;
+ (NSArray *) soundUnfilteredFileTypes;
+ (NSArray *) soundUnfilteredPasteboardTypes;
+ (NSArray *)soundUnfilteredTypes;

- (NSArray *) channelMapping;
- (NSTimeInterval) currentTime; 
- (id) delegate;
- (NSTimeInterval) duration;
- (id) initWithContentsOfFile:(NSString *) filename byReference:(BOOL) flag; 
- (id) initWithContentsOfFile:(NSString *) filename; // NOT IN API
- (id) initWithContentsOfURL:(NSURL *) url byReference:(BOOL) flag;
- (id) initWithContentsOfURL:(NSURL *) url; // NOT IN API
- (id) initWithData:(NSData *) data;
- (id) initWithPasteboard:(NSPasteboard *) pasteboard;
- (BOOL) isPlaying;
- (BOOL) loops; 
- (NSString *) name; 
- (BOOL) pause;
- (BOOL) play;
- (NSString *) playbackDeviceIdentifier;
- (BOOL) resume;
- (void) setChannelMapping:(NSArray *) mappings; 
- (void) setCurrentTime:(NSTimeInterval) time;
- (void) setDelegate:(id) anObject;
- (void) setLoops:(BOOL) flag;
- (BOOL) setName:(NSString *) name;
- (void) setPlaybackDeviceIdentifier:(NSString *) name;
- (void) setVolume:(float)vol; 
- (BOOL) stop;
- (float) volume; 
- (void) writeToPasteboard:(NSPasteboard *) pasteboard;

@end


@interface NSObject (NSSoundDelegate)

- (void)sound:(NSSound *) sound didFinishPlaying:(BOOL) flag;

@end


@interface NSBundle (NSSoundAdditions) 

- (NSString *) pathForSoundResource:(NSString *) name;

@end

#endif /* _mySTEP_H_NSSound */
