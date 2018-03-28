//
//  MyDocument.h
//  MapKitTest
//
//  Created by H. Nikolaus Schaller on 07.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <MapKit/MapKit.h>

@interface MyDocument : NSDocument <CLLocationManagerDelegate, MKMapViewDelegate>
{
	CLLocationManager *loc;
	IBOutlet MKMapView *map;
	BOOL autorotateCourse;		// GPS
	BOOL autorotateMagnetic;	// magnetic
	BOOL autoUpdate;			// location
	BOOL autoZoom;
}

- (IBAction) trackCourse:(id) sender;
- (IBAction) trackMagnetic:(id) sender;
- (IBAction) trackLocation:(id) sender;
- (IBAction) autoZoom:(id) sender;
- (IBAction) rotateLeft:(id) sender;
- (IBAction) rotateRight:(id) sender;

@end
