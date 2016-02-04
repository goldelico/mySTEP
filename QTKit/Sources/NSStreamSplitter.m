/*
 *  NSStreamSplitter.m
 *  mySTEP
 *
 *  Created by Dr. H. Nikolaus Schaller on Sat Sep 27 2003.
 *  Copyright (c) 2003 DSITRI. All rights reserved.
 *
 *  licensed under the LGPL
 */

#import "NSStreamSplitter.h"

@implementation NSStreamSplitter

- (void) dealloc;
{
	[_source release];
	[_destinations release];
	[super dealloc];
}

- (NSStream *) source; { return _source; }
- (void) setSource:(NSStream *) source; { [_source autorelease]; _source=[source retain]; [source setDelegate:self]; }
- (void) addDestination:(NSOutputStream *) handler; { if(!_destinations) _destinations=[[NSMutableArray alloc] initWithCapacity:5]; [_destinations addObject:handler]; }
- (void) removeDestination:(NSOutputStream *) handler; { [_destinations removeObject:handler]; }

- (void) stream:(NSStream *) stream handleEvent:(NSStreamEvent) event;
{ // pass to all handlers
	NSEnumerator *e=[_destinations objectEnumerator];
	id handler;
	while((handler=[e nextObject]))
		[handler stream:self handleEvent:event];
}

@end
