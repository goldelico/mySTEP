//
//  CLHeading.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLHeading.h"

@implementation CLHeading

// init...

- (CLLocationDirection) headingAccuracy; { return headingAccuracy; }
- (CLLocationDirection) magneticHeading; { return magneticHeading; }
- (NSDate *) timestamp; { return timestamp; }
- (CLLocationDirection) trueHeading; { return trueHeading; }
- (CLHeadingComponentValue) x; { return x; }
- (CLHeadingComponentValue) y; { return y; }
- (CLHeadingComponentValue) z; { return z; }

- (void) dealloc
{
	[timestamp release];
	[super dealloc];
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"magneticHeading %lg trueHeading %lg accuracy %lg x %lg y %lg z %lg a %lg @ %@",
			magneticHeading, trueHeading, headingAccuracy,
			x, y, z,
			headingAccuracy, timestamp];
}

- (id) copyWithZone:(NSZone *) zone
{
	CLHeading *c=[CLHeading alloc];
	if(c)
		{
		c->headingAccuracy=headingAccuracy;
		c->magneticHeading=magneticHeading;
		c->trueHeading=trueHeading;
		c->x=x;
		c->y=y;
		c->z=z;
		c->timestamp=[timestamp retain];
		}
	return c;
}

- (id) initWithCoder:(NSCoder *) coder
{
	//	self=[super initWithCoder:coder];
	if(self)
		{
		// decode keyed values
		}
	return self;	
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	//	[super encodeWithCoder:coder];
	// encode keyed values
}

@end

