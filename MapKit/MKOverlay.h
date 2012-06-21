//
//  MKOverlay.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKAnnotation.h>

@protocol MKOverlay <MKAnnotation>
// - (CLLocationCoordinate2D) coordinate;	// through MKAnnotation
- (MKMapRect) boundingMapRect;
- (BOOL) intersectsMapRect:(MKMapRect) rect;
@end

// EOF
