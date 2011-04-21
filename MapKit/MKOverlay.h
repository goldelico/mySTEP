//
//  MKOverlay.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKAnnotation.h>

@protocol MKOverlay <MKAnnotation>
- (MKMapRect) boundingMapRect;
- (CLLocationCoordinate2D) coordinate;
- (BOOL) intersectsMapRect:(MKMapRect) rect;
@end

// EOF
