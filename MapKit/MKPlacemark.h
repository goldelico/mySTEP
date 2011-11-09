//
//  MKPlacemark.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#ifndef __mySTEP__
#import <MapKit/CLExtensions.h>
#endif

@interface MKPlacemark : CLPlacemark <MKAnnotation>
{
}

- (id) initWithCoordinate:(CLLocationCoordinate2D) coord addressDictionary:(NSDictionary *) addr;

@end

// EOF
