/* 
 NSSound.m
 
 Sound container class
 
 Author:  Nikolaus Schaller <hns@computer.org>
 Date:    August 2006
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.

 */ 

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>

#import <AppKit/NSSound.h>
#import <AppKit/NSPasteboard.h>
#import "NSAppKitPrivate.h"
#import "NSUIServer.h"

NSString *NSSoundPboardType=@"NSSound";

@implementation NSSound

+ (BOOL) canInitWithPasteboard:(NSPasteboard*)pasteboard;
{
	NIMP;
	return NO;
}

+ (id) soundNamed:(NSString*)name;
{
	return NIMP;
}

+ (NSArray *) _soundFileTypes;
{ // ask server (once)
	static NSArray *_soundFileTypes;
	if(!_soundFileTypes)
		_soundFileTypes=[[[NSWorkspace _distributedWorkspace] soundFileTypes] retain];
	return _soundFileTypes;
}

+ (NSArray*) soundUnfilteredFileTypes;
{
	return [self _soundFileTypes];
}

+ (NSArray*) soundUnfilteredPasteboardTypes;
{
	return [self _soundFileTypes];
}

- (id) initWithContentsOfFile:(NSString*)filename;
{
	// save filename only
	return NIMP;
}

- (id) initWithContentsOfURL:(NSURL*)url;
{
	// save URL
	return NIMP;
}

- (id) initWithData:(NSData*)data;
{
	if(!data)
		;
	// write to temp file and save filename
	return NIMP;
}

- (id) initWithPasteboard:(NSPasteboard*)pasteboard;
{
	return [self initWithData:[pasteboard dataForType:NSSoundPboardType]];
}

- (void) dealloc;
{
	[self stop];
	[_name release];
	[super dealloc];
}

- (BOOL) play;
{
	[[NSWorkspace _distributedWorkspace] play:self];
	return YES;
}

- (BOOL) isPlaying;
{
	return [[NSWorkspace _distributedWorkspace] isPlaying:self];
}

- (BOOL) pause;
{
	[[NSWorkspace _distributedWorkspace] pause:self];
	return YES;
}

- (BOOL) resume;
{
	[[NSWorkspace _distributedWorkspace] resume:self];
	return YES;
}

- (BOOL) stop;
{
	[[NSWorkspace _distributedWorkspace] stop:self];
	return YES;
}

- (void) writeToPasteboard:(NSPasteboard *) pasteboard;
{
	NIMP;
}

- (NSString*) name; { return _name; }

- (void) setName:(NSString *) name;
{
	ASSIGN(_name, name);
	// manage named sound cache i.e. remove id name==nil
}

- (id) delegate; { return _delegate; }
- (void) setDelegate:(id)anObject; { _delegate=anObject; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end /* NSSound */