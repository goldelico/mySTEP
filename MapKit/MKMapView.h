//
//  MKMapView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#ifndef __UIKit__
#define UIView NSView
typedef struct UIEdgeInsets
{
	CGFloat top, left, bottom, right;
} UIEdgeInsets;
#endif

#import <MapKit/MKGeometry.h>
#import <MapKit/MKAnnotation.h>
#import <MapKit/MKOverlay.h>
#import <MapKit/MKTypes.h>

@class MKAnnotationView;
@class MKOverlayView;
@class MKUserLocation;

@protocol MKMapViewDelegate <NSObject>

// mapView:viewForAnnotation:
// mapView:viewForOverlay:

@end

@interface MKMapView : UIView
{
	CLLocationCoordinate2D centerCoordinate;
	MKCoordinateRegion region;
	MKMapRect visibleMapRect;
	NSMutableArray *annotations;
	NSMutableArray *overlays;	// back to front
	id <MKMapViewDelegate> delegate;
	MKUserLocation *userLocation;
	MKMapType mapType;
	BOOL scrollEnabled;
	BOOL userLocationVisible;
	BOOL zoomEnabled;
	BOOL showsUserLocation;
}

- (void) addAnnotation:(id <MKAnnotation>) a;
- (void) addAnnotations:(NSArray *) a;
- (void) addOverlay:(id <MKOverlay>) o;
- (void) addOverlays:(NSArray *) o;
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
- (MKMapRect) mapRectThatFits:(MKMapRect) rect edgePadding:(UIEdgeInsets) insets;
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
- (void) setVisibleMapRect:(MKMapRect) rect edgePadding:(UIEdgeInsets) insets animated:(BOOL) flag;
- (void) setZoomEnabled:(BOOL) flag;
- (BOOL) showsUserLocation;
- (MKUserLocation *) userLocation;
- (MKAnnotationView *) viewForAnnotation:(id <MKAnnotation>) a;
- (MKOverlayView *) viewForOverlay:(id <MKOverlay>) o;
- (MKMapRect) visibleMapRect;

@end

// EOF
