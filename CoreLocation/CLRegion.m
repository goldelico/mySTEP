//
//  CLRegion.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CLRegion.h"

@implementation CLRegion

- (CLLocationCoordinate2D) center; { return center; }
- (NSString *) identifier; { return identifier; }
- (CLLocationDistance) radius; { return radius; }

- (BOOL) containsCoordinate:(CLLocationCoordinate2D) coordinate;
{
	return NO;
}

- (void) dealloc;
{
	[identifier release];
	[super dealloc];
}

- (id) initCircularRegionWithCenter:(CLLocationCoordinate2D) cent radius:(CLLocationDistance) rad identifier:(NSString *) ident;
{
	if((self=[super init]))
		{
		center=cent;
		radius=rad;
		identifier=[ident retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	CLRegion *c=[CLRegion alloc];
	if(c)
		{
		c->center=center;
		c->radius=radius;
		c->identifier=[identifier retain];
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

// EOF