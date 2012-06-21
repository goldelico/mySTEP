//
//  MKPolygon.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKMultiPoint.h>

@interface MKPolygon : MKMultiPoint <MKOverlay>
{
	NSArray *interiorPolygons;
}

- (NSArray *) interiorPolygons;
+ (MKPolygon *) polygonWithCoordinates:(CLLocationCoordinate2D *) coords count:(NSUInteger) count;
+ (MKPolygon *) polygonWithCoordinates:(CLLocationCoordinate2D *) coords count:(NSUInteger) count interiorPolygons:(NSArray *) interiorPolygons;
+ (MKPolygon *) polygonWithPoints:(MKMapPoint *) points count:(NSUInteger) count;
+ (MKPolygon *) polygonWithPoints:(MKMapPoint *) points count:(NSUInteger) count interiorPolygons:(NSArray *) interiorPolygons;

@end

// EOF
