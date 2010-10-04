//
//  MKMapView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __UIKit__
#define UIView NSView
#endif

#import <Cocoa/Cocoa.h>
#import <MapKit/MKGeometry.h>
#import <MapKit/MKOverlay.h>
#import <MapKit/MKTypes.h>

@interface MKMapView : UIView
{
	NSMutableArray *_annotations;
	NSMutableArray *_overlays;
	id <MKMapViewDelegate>) _delegate;
	CLLocationCoordinate2D _centerCoordinate;
	MKCoordinateRegion _region;
	MKMapRect _visibleMapRect;
	MKMapType _mapType;
	BOOL _isScrollEnabled;
	BOOL _isUserLocationVisible;
	BOOL _isZoomEnabled;
	BOOL _showsUserLocation;
}

- (void) addAnnotation:(id <MKAnnotation>) a;
- (void) addAnnotations:(NSArray *) a;
- (void) addOverlay:(id <MKOverlay>) o;
- (void) addOverlayss:(NSArray *) o;
- (NSArray *) annotations;
- (NSRect) annotationVisibleRect;
- (CLLocationCoordinate2D) centerCoordinate;
- (NSPoint) convertCoordinate:(CLLocationCoordinate2D) coord toPointToView:(UIView *) view;
- (CLLocationCoordinate2D) convertPoint:(NSPoint) point toCoordinateFromView:(UIView *) view;
- (MKCoordinateRegion) convertRect:(NSRect) coord toRegionFromView:(UIView *) view;
- (NSRect) convertRegion:(MKCoordinateRegion) region toRectToView:(UIView *) view;
- (id <MKMapViewDelegate>) delegate;
- (MKAnnotationView *) equeueReusableAnnotationViewWithIdentifier:(NSString *) ident;
- (void) deselectAnnotation:(id <MKAnnotation>) a animated:(BOOL) flag;
- (void) exchangeOverlayAtIndex:(NSUInteger) idx1 withOverlayAtIndex:(NSUInteger) idx2;
- (void) insertOverlay:(id <MKOverlay>) o aboveOverlay:(id <MKOverlay>) sibling;
- (void) insertOverlay:(id <MKOverlay>) o atIndex:(NSUInteger) idx;
- (void) insertOverlay:(id <MKOverlay>) o belowOverlay:(id <MKOverlay>) sibling;
- (BOOL) isScrollEnabled;
- (BOOL) isUserLocationVisible;
- (BOOL) isZoomEnabled;
- (MKMapRect) mapRectThatFits:(MKMapRect) rect;
- (MKMapRect) mapRectThatFits:(MKMapRect) rect edgePadding:(NSEdgeInsets) insets;
- (MKMapType) mapType;
- (NSArray *) overlays;
- (MKCoordinateRegion) region;
- (MKCoordinateRegion) regionThatFits:(MKCoordinateRegion) region;
- (void) removeAnnotation:(id <MKAnnotation>) a;
- (void) removeAnnotations:(NSArray *) a;
- (void) removeOverlay:(id <MKOverlay>) a;
- (void) removeOverlays:(NSArray *) a;
- (void) selectAnnotation:(id <MKAnnotation>) a animated:(BOOL) flag;
- (NSArray *) selectedAnnotations;
- (void) setCenterCoordinate:(CLLocationCoordinate2D) center;
- (void) setCenterCoordinate:(CLLocationCoordinate2D) center animated:(BOOL) flag;
- (void) setDelegate:(id <MKMapViewDelegate>) d;
- (void) setMapType:(MKMapType) type;
- (void) setRegion:(MKCoordinateRegion) region;
- (void) setRegion:(MKCoordinateRegion) region animated:(BOOL) flag;
- (void) setScrollEnabled:(BOOL) flag;
- (void) setSelectedAnnotation:(NSArray *) a;	// copy property
- (void) setShowsUserLocation:(BOOL) flag;
- (void) setUserLocationVisible:(BOOL) flag;
- (void) setVisibleMapRect:(MKMapRect) rect;
- (void) setVisibleMapRect:(MKMapRect) rect animated:(BOOL) flag;
- (void) setVisibleMapRect:(MKMapRect) rect edgePadding:(NSEdgeInsets) insets animated:(BOOL) flag;
- (void) setZoomEnabled:(BOOL) flag;
- (BOOL) showsUserLocation;
- (MKUserLocation *) userLocation;
- (MKAnnotationView *) viewForAnnotation:(id <MKAnnotation>) a;
- (MKOverlayView *) viewForOverlay:(id <MKOverlay>) o;
- (MKMapRect) visibleMapRect;

@end

#else

@interface MKMapView : UIView

@end

#endif

@protocol MKMapViewDelegate
mapView:viewForAnnotation:
mapView:viewForOverlay:

@end

// FIXME (korrekt aufteilen):
@interface MKAnnotationView : UIView
{
	BOOL dragabble
	callout
	canShowCallout
}
@end
@interface MKPinAnnotationView : MKAnnotationView
@end


@interface MKOverlayView : UIView
- drawMapRect:zoomScale:inContext:	// muß Multithreaded sein
@end

@interface MKOverlayPathView : MKOverlayView
@end

@interface MKPlacemark : NSObject <MKAnnotation>
@end
@interface MKUserLocation : MKPlacemark
@end

@protocol MKAnnotation
@end

@protocol MKOverlay <MKAnnotation>
@end

@interface MKCircle, MKShape, MKMultiPoint, ...
@end

// EOF
