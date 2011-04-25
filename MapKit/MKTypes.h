//
//  MKTypes.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

enum _MKMapType
{
	MKMapTypeStandard,
	MKMapTypeSatellite,
	MKMapTypeHybrid
};

typedef NSUInteger MKMapType;

@protocol MKAnnotation;
@protocol MKOverlay;

// EOF
