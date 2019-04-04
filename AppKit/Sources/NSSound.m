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
#import "NSSystemServer.h"

NSString *NSSoundPboardType=@"NSSound";

static NSMutableDictionary *__nameToSoundDict = nil;

@implementation NSSound

+ (void) initialize
{
	__nameToSoundDict = [[NSMutableDictionary alloc] initWithCapacity: 10];
}

+ (NSArray *) _soundFileTypes;
{ // ask server (once)
	static NSArray *_soundFileTypes;
	if(!_soundFileTypes)
#if 0
		_soundFileTypes=[[[NSWorkspace _loginWindowServer] soundFileTypes] retain];
#else
		_soundFileTypes=[[NSArray alloc] initWithObjects:
						 @"aiff",
						 @"wav",
						 @"mp3",
						 nil];

#endif
	return _soundFileTypes;
}

+ (id) soundNamed:(NSString *) aName;
{
	NSSound *sound;
	NSString *name=aName;
	NSString *ext;
	NSString *path;
	NSArray *fileTypes;
	NSBundle *bundle;
	NSEnumerator *e;
#if 0
	NSLog(@"load soundNamed %@", aName);
#endif
	if((sound = [__nameToSoundDict objectForKey:aName]))
		{ // in cache
		if([sound isKindOfClass:[NSNull class]])
			return nil; // we know that we don't know...
		return sound;
		}
	ext = [aName pathExtension];		// dict search for it
	fileTypes = [self _soundFileTypes];
#if 0
	NSLog(@"soundFileTypes = %@", fileTypes);
#endif
	bundle = [NSBundle mainBundle];		// look into main bundle first
	path=nil;
	if([fileTypes containsObject:ext])
		{
		name = [aName stringByDeletingPathExtension];		// has a supported extension
		path = [bundle pathForResource:name ofType:ext];	// look up
		}
	if(!path)
		{ // name does not have a supported ext: search for the sound locally (mainBundle)
		id o;
		ext=nil;	// ignore extension
		e = [fileTypes objectEnumerator];
		while((o = [e nextObject]))
			{
#if 0
			NSLog(@"try %@: %@.%@", [bundle bundlePath], name, o);
#endif
			if((path = [bundle pathForResource:name ofType:o]))
				break;
			}
		}
	if(!path)
		{ // If not found in app bundle search for sound in system
		bundle=[NSBundle bundleForClass:[self class]];	// look up in AppKit.framework
		if(ext)
			path = [bundle pathForResource:name ofType:ext];
		else 
			{ // try all extensions we know
			id o;
			fileTypes = [self _soundFileTypes];
			e = [fileTypes objectEnumerator];
			while((o = [e nextObject]))
				{
#if 0
				NSLog(@"try %@: %@.%@", [bundle bundlePath], name, o);
#endif
				if((path = [bundle pathForResource:name ofType:o]))
					break;
				}
			}
		}
#if 0
	NSLog(@"found %@ at path=%@ in bundle %@", aName, path, bundle);
#endif
	sound=nil;
	if(path && (sound = [[NSSound alloc] initWithContentsOfFile:path]))
		{ // file really exists
		[sound setName:aName];	// will save in __nameToSoundDict - and increment retain count
		[sound autorelease];	// don't leak if everything is released - unfortunately we are never deleted from the sound cache
		}
	if(!sound)
		{
#if 0
		NSLog(@"could not find NSSound -soundNamed:%@", aName);
#endif
		[__nameToSoundDict setObject:[NSNull null] forKey:aName];	// save a tag that we don't know the sound
		}
#if 0
	NSLog(@"NSSound: -soundNamed:%@ -> %@", aName, sound);
#endif
	return sound;
}

+ (NSArray*) soundUnfilteredFileTypes;
{
	return [self _soundFileTypes];
}

+ (NSArray*) soundUnfilteredPasteboardTypes;
{
	return [self _soundFileTypes];
}

+ (BOOL) canInitWithPasteboard:(NSPasteboard*)pasteboard;
{
	NIMP;
	return NO;
}

- (id) initWithContentsOfFile:(NSString*)filename;
{
	if((self=[super init]))
		_url=[[NSURL fileURLWithPath:filename] retain];
	return self;
}

- (id) initWithContentsOfURL:(NSURL*)url;
{
	if((self=[super init]))
		_url=[url retain];
	return self;
}

- (id) initWithData:(NSData*)data;
{
	if((self=[super init]))
		{
		// FIXME: save to /tmp and init with the filename
		}
	return self;
}

- (id) initWithPasteboard:(NSPasteboard*)pasteboard;
{
	return [self initWithData:[pasteboard dataForType:NSSoundPboardType]];
}

- (void) dealloc;
{
	[self stop];
	if(_name && self == [__nameToSoundDict objectForKey:_name]) 
		[__nameToSoundDict removeObjectForKey:_name];	// only if we are not a copy with the same name
	[_name release];
	[_url release];
	[super dealloc];
}

- (BOOL) play;
{
	NSString *cmd=[NSString stringWithFormat:@"/root/twl -m %s", [[NSFileManager defaultManager] fileSystemRepresentationWithPath:[_url path]]];
	NSLog(@"play sound: %@", cmd);
	system([cmd UTF8String]);	// block
#if 0
	[[NSWorkspace _loginWindowServer] playSound:self withURL:_url];
#endif
	return YES;
}

- (BOOL) isPlaying;
{
	return YES;
#if 0
	return [[NSWorkspace _loginWindowServer] isPlayingSound:self];
#endif
}

- (BOOL) pause;
{
#if 0
	[[NSWorkspace _loginWindowServer] pauseSound:self];
#endif
	return YES;
}

- (BOOL) resume;
{
#if 0
	/* return? */ [[NSWorkspace _loginWindowServer] resumeSound:self];
#endif
	return YES;
}

- (BOOL) stop;
{
#if 0
	[[NSWorkspace _loginWindowServer] stopSound:self];
#endif
	return YES;
}

- (void) writeToPasteboard:(NSPasteboard *) pasteboard;
{
	// read file and paste
	NIMP;
}

- (NSString*) name; { return _name; }

- (BOOL) setName:(NSString *) name;
{
	if(!name || [__nameToSoundDict objectForKey:name])
		return NO;	// if already in dictionary
	ASSIGN(_name, name);
	[__nameToSoundDict setObject:self forKey:_name];	// save in dictionary
	return YES;
}

- (id) delegate; { return _delegate; }
- (void) setDelegate:(id)anObject; { _delegate=anObject; }

- (id) awakeAfterUsingCoder:(NSCoder*)aDecoder
{
	if(_name && [__nameToSoundDict objectForKey:_name])
		{
//		[self release];
		return [__nameToSoundDict objectForKey:_name];
		}
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return NIMP;
}

@end /* NSSound */
