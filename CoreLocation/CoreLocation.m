//
//  CoreLocation.m
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@implementation CLLocation

- (id) copyWithZone:(NSZone *) zone
{
	CLLocation *c=[CLLocation alloc];
	if(c)
		{
		
		}
	return c;
}

- (id) initWithCoder:(NSCoder *) coder
{
	return self;	
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	
}

@end

@implementation CLLocationManager

@end

