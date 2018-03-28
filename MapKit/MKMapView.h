//
//  MKMapView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if !defined(__mySTEP__)
#import <MapKit/CLExtensions.h>
#endif


#if !TARGET_OS_IPHONE
#define UIView NSView
#define UIControl NSControl
typedef struct UIEdgeInsets
{
	CGFloat top, left, bottom, right;
} UIEdgeInsets;
#endif

#import <MapKit/MKGeometry.h>
#import <MapKit/MKAnnotationView.h>
#import <MapKit/MKTypes.h>

@class MKAnnotationView;
@class MKOverlayView;
@class MKUserLocation;
@class MKMapView;

@protocol MKMapViewDelegate <NSObject>
- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control;
- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view didChangeDragState:(MKAnnotationViewDragState) state fromOldState:(MKAnnotationViewDragState) oldState;
- (void) mapView:(MKMapView *) mapView didAddAnnotationViews:(NSArray *) views;
- (void) mapView:(MKMapView *) mapView didAddOverlayViews:(NSArray *) views;
- (void) mapView:(MKMapView *) mapView didDeselectAnnotationView:(MKAnnotationView *) view;
- (void) mapView:(MKMapView *) mapView didFailToLocateUserWithError:(NSError *) error;
- (void) mapView:(MKMapView *) mapView didSelectAnnotationView:(MKAnnotationView *) view;
- (void) mapView:(MKMapView *) mapView didUpdateUserLocation:(MKUserLocation *) location;
- (void) mapView:(MKMapView *) mapView regionDidChangeAnimated:(BOOL) flag;
- (void) mapView:(MKMapView *) mapView regionWillChangeAnimated:(BOOL) flag;
- (MKAnnotationView *) mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>) annotation;
- (MKOverlayView *) mapView:(MKMapView *) mapView viewForOverlay:(id <MKOverlay>) overlay;
- (void) mapViewDidFailLoadingMap:(MKMapView *) mapView withError:(NSError *) error;
- (void) mapViewDidFinishLoadingMap:(MKMapView *) mapView;
- (void) mapViewDidStopLocatingUser:(MKMapView *) mapView;
- (void) mapViewWillStartLoadingMap:(MKMapView *) mapView;
- (void) mapViewWillStartLocatingUser:(MKMapView *) mapView;
@end

@interface MKMapView : UIView
{
	MKMapRect visibleMapRect;
	NSMutableArray *annotations;
	NSMutableArray *overlays;	// back to front
	NSMapTable *viewForAnnotation;
	NSMapTable *viewForOverlay;
	id <MKMapViewDelegate> delegate;
	CLLocationManager *locationManager;
	MKUserLocation *userLocation;
	MKMapType mapType;
	BOOL scrollEnabled;
	BOOL userLocationVisible;
	BOOL zoomEnabled;
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
- (MKAnnotationView *) dequeueReusableAnnotationViewWithIdentifier:(NSString *) ident;
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

@interface MKMapView (NSResponder)

- (IBAction) zoomIn:(id) sender;
- (IBAction) zoomOut:(id) sender;
- (IBAction) moveLeft:(id) sender;	// move west (like horizontal scrollwheel)
- (IBAction) moveRight:(id) sender;	// move east
- (IBAction) moveUp:(id) sender;	// move north (like vertical scrollwheel)
- (IBAction) moveDown:(id) sender;	// move south

@end

@interface MKMapView (Private)

- (NSPoint) _pointForMapPoint:(MKMapPoint) pnt;
- (NSRect) _rectForMapRect:(MKMapRect) rect;
- (MKMapPoint) _mapPointForPoint:(NSPoint) pnt;
- (MKMapRect) _mapRectForRect:(NSRect) rect;
- (NSString *) _tileURLForZ:(int) z x:(int) x y:(int) y;
- (BOOL) _drawTileForZ:(int) z x:(int) x y:(int) y intoRect:(NSRect) rect load:(BOOL) flag;
- (void) _scaleBy:(float) factor aroundCenter:(MKMapPoint) center;
- (void) _scaleBy:(float) factor;
- (void) _moveByX:(double) x Y:(double) y;

@end

// EOF
