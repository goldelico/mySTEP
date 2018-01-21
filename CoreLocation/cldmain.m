//
//  CoreLocationDaemon.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 18.09.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "CoreLocationDaemon.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	CoreLocationDaemon *d=[CoreLocationDaemon new];	// create daemon
	NSConnection *theConnection=[NSConnection new];
#if 1
	NSLog(@"Creating connection for %@...", SERVER_ID);
#endif
	[theConnection setRootObject:d];
	if([theConnection registerName:SERVER_ID] == NO)
		{
		NSLog(@"Failed to register name %@\n", SERVER_ID);
		return 1;
		}
	// process events
#if 1
	NSLog(@"Running the loop...");
#endif
	[[NSRunLoop currentRunLoop] run];	// run until all input sources have been removed (after GPS is shut down)
#if 1
	NSLog(@"Exiting daemon for %@", SERVER_ID);
#endif
	[d release];
	[pool release];
	return 0;
}
