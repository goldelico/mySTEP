/*
	NSMovie.h
	mySTEP
 
	Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
	Copyright (c) 2003 DSITRI. All rights reserved.
 
	licensed under the LGPL
*/

#import <Foundation/Foundation.h>
#import <AppKit/NSPasteboard.h>

@interface NSMovie : NSObject <NSCoding>
{
	@private
	void *_qtmovie;	// opaque QTMovie object
	NSURL *_url;
	BOOL _byRef;
}

+ (BOOL) canInitWithPasteboard:(NSPasteboard *) pasteboard;
+ (NSArray *) movieUnfilteredFileTypes;
+ (NSArray *) movieUnfilteredPasteboardTypes;
- (id) initWithMovie:(void *) QTMovie;
- (id) initWithPasteboard:(NSPasteboard *) pasteboard;
- (id) initWithURL:(NSURL *) url byReference:(BOOL) byRef;  // can be file://xxx, rtp://xxx - should also allow camera:// (?)
- (void *) QTMovie;	// opaque QTMovie object
- (NSURL *) URL;

@end
