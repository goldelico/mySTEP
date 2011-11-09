//
//  CLRegion.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CLLocation.h>

@interface CLRegion : NSObject <NSCopying, NSCoding>
{
	CLLocationCoordinate2D center;
	CLLocationDistance radius;
	NSString *identifier;
}

- (CLLocationCoordinate2D) center;
- (NSString *) identifier;
- (CLLocationDistance) radius;

- (BOOL) containsCoordinate:(CLLocationCoordinate2D) coordinate;

- (id) initCircularRegionWithCenter:(CLLocationCoordinate2D) cent radius:(CLLocationDistance) rad identifier:(NSString *) ident;

@end
