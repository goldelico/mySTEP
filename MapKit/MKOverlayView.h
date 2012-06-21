//
//  MKOverlayView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <MapKit/MKGeometry.h>
#import <MapKit/MKOverlay.h>
#import <MapKit/MKTypes.h>

#if !TARGET_OS_IPHONE
#undef UIView
#define UIView NSView
#define UIImage NSImage
#define CGRect NSRect
#endif

@interface MKOverlayView : UIView
{
	id <MKOverlay> _overlay;
}

CGFloat MKRoadWidthAtZoomScale(MKZoomScale zoom);

- (BOOL) canDrawMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale;
- (void) drawMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale inContext:(CGContextRef) context;
- (id) initWithOverlay:(id <MKOverlay>) overlay;
- (MKMapPoint) mapPointForPoint:(CGPoint) point;
- (MKMapRect) mapRectForRect:(CGRect) rect;
- (id <MKOverlay>) overlay;
- (CGPoint) pointForMapPoint:(MKMapPoint) point;
- (CGRect) rectForMapRect:(MKMapRect) rect;
- (void) setNeedsDisplayInMapRect:(MKMapRect) rect;
- (void) setNeedsDisplayInMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale;

@end

// EOF
