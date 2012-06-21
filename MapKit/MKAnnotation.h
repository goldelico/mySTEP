//
//  MKAnnotation.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

@protocol MKAnnotation <NSObject>
/* required */
- (CLLocationCoordinate2D) coordinate;
/* optional */
- (NSString *) subtitle;
- (NSString *) title;
- (void) setCoordinate:(CLLocationCoordinate2D) pos;	// changed by user
@end

// EOF
