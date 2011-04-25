//
//  MKAnnotation.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol MKAnnotation <NSObject>
- (CLLocationCoordinate2D) coordinate;
- (void) setCoordinate:(CLLocationCoordinate2D) pos;	// changed by user
- (NSString *) subtitle;
- (NSString *) title;
@end

// EOF
