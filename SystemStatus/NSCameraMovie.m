/* 
 Camera driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/NSCameraMovie.h>
	
NSString *NSCameraShutterPressedNotification=@"NSCameraShutterPressedNotification";
NSString *NSCameraShutterReleasedNotification=@"NSCameraShutterReleasedNotification";

@interface NSFileHandle (writeString)
- (void) writeString:(NSString *) str;
@end

@implementation NSFileHandle (writeString)

- (void) writeString:(NSString *) str
{
	[self writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[self synchronizeFile];
}

@end

@implementation NSCameraStream

- (void) _dataReceived:(NSNotification *) n;
{
	NSData *d;
#if 1
	NSLog(@"_dataReceived %@", n);
#endif
	d=[[n userInfo] objectForKey:@"NSFileHandleNotificationDataItem"];
	// do we need to splice together data chunks?
	[file readInBackgroundAndNotify];	// and trigger more notifications
}

- (void) deviceShouldLock:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"NSCameraMovie: deviceInserted %@", dev);
#endif
	if(![dev isLocked] &&
	   [[dev deviceManufacturer] isEqualToString:@"SHARP"] &&
	   [[dev deviceManufacturer] isEqualToString:@"CEAG06  "]
	   )
		{ // Sharp Zaurus Camera
#if 1
		NSLog(@"Camera card found: %@", dev);
#endif
		camera=dev;
		[dev lock:YES];	// found and grab!
		[dev resume];	// and enable
		}
}

- (void) deviceEjected:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"NSCameraMovie: deviceEjected %@", dev);
#endif
	if(dev != camera)
		return;	// ignore
	camera=nil;
}

- (void) deviceSuspended:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
#if 1
	NSLog(@"NSCameraMovie: deviceSuspended %@", dev);
#endif
	if(dev != camera)
		return;	// ignore
	if(file)
		{
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSFileHandleReadCompletionNotification
													  object:file];	// don't observe any more
		[file closeFile];
#if 1
		NSLog(@"Location: file closed");
#endif
		[file release];
#if 1
		NSLog(@"Location: file released");
#endif
		file=nil;
		}
}

- (void) deviceResumed:(NSNotification *) n;
{
	SYSDevice *dev=[n object];
	if(dev != camera)
		return;	// ignore
	file=[[dev open:nil] retain];	// open device - no speed settings required
	if(!file)
		{
		NSLog(@"was not able to open device file %@", dev);
		return;
		}
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_dataReceived:)
												 name:NSFileHandleReadCompletionNotification 
											   object:file];	// make us see notifications
	//	[file setNonBlocking:YES];
	// initialize, e.g. write init string to file
#if 1
	NSLog(@"waiting for data on %@", [dev devicePath]);
#endif
	[file readInBackgroundAndNotify];	// and trigger notifications
	[self setCaptureFrame:NO size:NSMakeSize(640.0, 320.0) zoom:1.0];	// default to VGA resolution

}

- (id) init;
{
	self=[super init];
	if(self)
		{
		[SYSDevice addObserver:self];	// make me observe devices
		}
	return self;
}

- (void) dealloc;
{
	[SYSDevice removeObserver:self];	// remove me as observer
	[super dealloc];
}

- (BOOL) available;
	{ // camera device is available
	return [(SYSDevice *) camera isReady];
	}

	// the following methods will raise an exception if the camera is not available
#define NEED // if(![self available]) NSRaiseException...

- (int) getStatus;
{
	NEED;
	// sendmode NO
	// wait for 4 characters
	// return value
	return 0;
}

- (BOOL) startCapture;
{
	NEED;
	[file writeString:@"C"];
	capturing=YES;
	return YES;
}

- (BOOL) clearShutterLatch;
{
	NEED;
	[file writeString:@"B"];
	capturing=NO;
	return YES;
}

- (BOOL) _sendMode:(BOOL) mode;
{
	[file writeString:[NSString stringWithFormat:@"M=%c", (mode?'0':'1')+(speed>1.0?0x02:0)+(hflip?0x04:0)+(vflip?0x08:0)]];
	return YES;
}


- (BOOL) setCaptureFrame:(BOOL) rotate size:(NSSize) size zoom:(float) z; 
{
	int w=16*(int)(width=size.width/16);
	int h=16*(int)(height=size.height/16);
	int iz=256*(zoom=z);
	NEED;
	[file writeString:[NSString stringWithFormat:@"%c=%d,%d,%d,%d", rotate?'R':'S', w, h, iz, 0]];
	return YES;
}

- (BOOL) setHorizontalFlip:(BOOL) flip;
{
	NEED;
	hflip=flip;
	return [self _sendMode:YES];
}

- (BOOL) setVerticalFlip:(BOOL) flip;
{
	NEED;
	vflip=flip;
	return [self _sendMode:YES];
}

- (BOOL) setCaptureSpeed:(float) s;
{ // values below 1.0 are "slow", 1.0 and above are "high"
	NEED;
	speed=s;
	return [self _sendMode:YES];
}

@end
