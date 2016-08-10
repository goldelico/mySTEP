//
//  MyDocument.m
//  MapKitTest
//
//  Created by H. Nikolaus Schaller on 07.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "MyDocument.h"
#import <CoreLocation/CoreLocation.h>

#if TARGET_OS_MAC
// locally define methods missing on MacOS (only available in iOS or mySTEP)

@interface CLLocationManager (iOSOnly)
- (void) startUpdatingHeading;
@end

@protocol CLLocationManagerDelegateiOS <CLLocationManagerDelegate>
- (void) locationManager:(CLLocationManager *) manager didUpdateHeading:(CLHeading *) newHeading;
@end

#endif

@implementation MyDocument

- (id)init
{
	self = [super init];
	if (self) {

		// Add your subclass-specific initialization here.
		// If an error occurs here, send a [self release] message and return nil.

	}
	return self;
}

- (void) dealloc
{
	[loc stopUpdatingLocation];
	[loc release];
	[super dealloc];
}

- (NSString *) windowNibName
{
	// Override returning the nib file name of the document
	// If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
	return @"MyDocument";
}

- (void) windowControllerDidLoadNib:(NSWindowController *) aController
{
#if 1
	NSLog(@"windowControllerDidLoadNib");
#endif
	MKPlacemark *pmk;
	[super windowControllerDidLoadNib:aController];
	// Add any code here that needs to be executed once the windowController has loaded the document's window.
	pmk=[[MKPlacemark alloc] initWithCoordinate:(CLLocationCoordinate2D) { 31.134358, 29.979175 } addressDictionary:nil];
	//	[pmk setTitle:@"Cheops Pyramid"];
	[map addAnnotation:pmk];
	[pmk release];
	[map setShowsUserLocation:YES];
	[map setDelegate:self];
	loc=[[CLLocationManager alloc] init];
	[loc setDelegate:self];
	[loc startUpdatingLocation];
	if([loc respondsToSelector:@selector(startUpdatingHeading)])
		[loc startUpdatingHeading];
}

- (NSData *) dataOfType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

	// You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

	// For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:NULL];
	}
	return nil;
}

- (BOOL) readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	// Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

	// You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead.

	// For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.

	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:0 userInfo:NULL];
	}
	return YES;
}

- (void) locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"error: %@", error);
}

- (void) locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
	float angle = [newHeading magneticHeading];	// rotate north
	if(angle >= 0.0)
		{ // rotate the mapview - see http://www.osxentwicklerforum.de/index.php?page=Thread&threadID=16045
			//
			// on iOS:
			//
			// CGAffineTransform rotation = CGAffineTransformMakeRotation(radians);
			// self.mapView.transform = rotation * M_PI / 180.0;
			[map setBoundsRotation:angle];
			[map setNeedsDisplay:YES];
		}
}

- (void) locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	float angle = [newLocation course];			// rotate in movement direction
	NSLog(@"new location: %@", newLocation);
	if(angle >= 0.0)
		{ // rotate the mapview - see http://www.osxentwicklerforum.de/index.php?page=Thread&threadID=16045
			//
			// on iOS:
			//
			// CGAffineTransform rotation = CGAffineTransformMakeRotation(radians);
			// self.mapView.transform = rotation * M_PI / 180.0;
			[map setBoundsRotation:angle];
			[map setNeedsDisplay:YES];
		}
	[map setCenterCoordinate:[newLocation coordinate]];	// center
}

- (IBAction) rotateLeft:(id) sender;
{ // rotate around view center
	[map setBoundsRotation:[map boundsRotation]+10.0];
	[map setNeedsDisplay:YES];
}

- (IBAction) rotateRight:(id) sender;
{ // rotate around view center
	[map setBoundsRotation:[map boundsRotation]-10.0];
	[map setNeedsDisplay:YES];
}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control;
{

}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view didChangeDragState:(MKAnnotationViewDragState) state fromOldState:(MKAnnotationViewDragState) oldState;
{

}

- (void) mapView:(MKMapView *) mapView didAddAnnotationViews:(NSArray *) views;
{

}

- (void) mapView:(MKMapView *) mapView didAddOverlayViews:(NSArray *) views;
{

}

- (void) mapView:(MKMapView *) mapView didDeselectAnnotationView:(MKAnnotationView *) view;
{

}

- (void) mapView:(MKMapView *) mapView didFailToLocateUserWithError:(NSError *) error;
{

}

- (void) mapView:(MKMapView *) mapView didSelectAnnotationView:(MKAnnotationView *) view;
{

}

- (void) mapView:(MKMapView *) mapView didUpdateUserLocation:(MKUserLocation *) location;
{
	NSLog(@"new user location: %@", location);
}

- (void) mapView:(MKMapView *) mapView regionDidChangeAnimated:(BOOL) flag;
{

}

- (void) mapView:(MKMapView *) mapView regionWillChangeAnimated:(BOOL) flag;
{

}

- (MKAnnotationView *) mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>) annotation;
{
	return nil;
}

- (MKOverlayView *) mapView:(MKMapView *) mapView viewForOverlay:(id <MKOverlay>) overlay;
{
	return nil;
}

- (void) mapViewDidFailLoadingMap:(MKMapView *) mapView withError:(NSError *) error;
{

}

- (void) mapViewDidFinishLoadingMap:(MKMapView *) mapView;
{

}

- (void) mapViewDidStopLocatingUser:(MKMapView *) mapView;
{

}

- (void) mapViewWillStartLoadingMap:(MKMapView *) mapView;
{

}

- (void) mapViewWillStartLocatingUser:(MKMapView *) mapView;
{

}

@end
