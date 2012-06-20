//
//  MKMultiPoint.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKShape.h>

@interface MKMultiPoint : MKShape
{
	/*@property (nonatomic, readonly)*/ MKMapPoint *points;
	/*@property (nonatomic, readonly)*/ NSUInteger pointCount;
	NSUInteger capacity;
}

- (NSUInteger) pointCount;
- (MKMapPoint *) points;
- (void) getCoordinates:(CLLocationCoordinate2D *) coords range:(NSRange) range;

@end

@interface MKMultiPoint (Extension)

- (void) addPoint:(MKMapPoint) point;
- (void) addCoordinate:(CLLocationCoordinate2D) coord;
// setPoint: atIndex:
// setCoordinate: atIndex:
// insertPoint: atIndex:
// insertCoordinate: atIndex:
- (void) removePointAtIndex:(unsigned int) idx;

@end

// EOF
