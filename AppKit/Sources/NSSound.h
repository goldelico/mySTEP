/* 
   NSSound.h

   Sound container class

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSound
#define _mySTEP_H_NSSound

#import <Foundation/NSBundle.h>
#import <AppKit/AppKitDefines.h>

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
	NSString *_filePath;
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

+ (BOOL) canInitWithPasteboard:(NSPasteboard*)pasteboard;
+ (id) soundNamed:(NSString*)name;
+ (NSArray*) soundUnfilteredFileTypes;
+ (NSArray*) soundUnfilteredPasteboardTypes;

- (id) delegate;
- (id) initWithContentsOfFile:(NSString*)filename;
- (id) initWithContentsOfURL:(NSURL*)url;
- (id) initWithData:(NSData*)data;
- (id) initWithPasteboard:(NSPasteboard*)pasteboard;
- (BOOL) isPlaying;
- (NSString*) name;
- (BOOL) pause;
- (BOOL) play;
- (BOOL) resume;
- (void) setDelegate:(id)anObject;							// Set the Delegate
- (BOOL) setName:(NSString *) name;
- (BOOL) stop;
- (void) writeToPasteboard:(NSPasteboard *) pasteboard;

@end


@interface NSObject (NSSoundDelegate)						// Implemented by the delegate
- (void)sound:(NSSound *) sound didFinishPlaying:(BOOL) flag;

@end


@interface NSBundle (NSSoundAdditions) 

- (NSString *) pathForSoundResource:(NSString *) name;

@end

#endif /* _mySTEP_H_NSSound */
