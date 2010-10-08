//
//  MKAnnotation.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol MKAnnotation
- (CLLocationCoordinate2D) coordinate;
- (void) setCoordinate:(CLLocationCoordinate2D) pos;	// changed by user
- (NSString *) subtitle;
- (NSString *) title;
@end

// EOF
