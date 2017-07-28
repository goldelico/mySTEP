//
//  floatspeed.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 18.01.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#include <sys/time.h>

@interface floatspeed : XCTestCase {
	
}

@end

#ifndef NS_TIME_START

#define NS_TIME_START(VAR) { \
struct timeval VAR, _ns_time_end; \
gettimeofday(&VAR, NULL);

#define NS_TIME_END(VAR, MESSAGE) \
gettimeofday(&_ns_time_end, NULL); \
_ns_time_end.tv_sec-=VAR.tv_sec; \
_ns_time_end.tv_usec-=VAR.tv_usec; \
if(_ns_time_end.tv_usec < 0) _ns_time_end.tv_sec-=1, _ns_time_end.tv_usec+=1000000; \
if(_ns_time_end.tv_sec > 0 || _ns_time_end.tv_usec > 0) \
fprintf(stderr, "%s: %u.%06ds\n", MESSAGE, (unsigned int) _ns_time_end.tv_sec, _ns_time_end.tv_usec); \
}

#endif

@implementation floatspeed

- (void) test1
{
	NSAffineTransform *t=[NSAffineTransform transform];
	int i;
	NS_TIME_START(timer1);
	for(i=1; i<10000000; i++)
		[t rotateByDegrees:20.0];
	NS_TIME_END(timer1, "affine rotations");
	/* typical speed:
	 * 0.67 s on a Cocoa on iMac with 2.8 GHz Intel Core 2 Duo
	 * 27s on mySTEP on GTA04 with 800 MHz TI DM3730 Cortex-A8 with(?) NEON
	 */
	XCTAssertTrue(YES);	// ok
}

@end
