//
//  MKOverlayView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __UIKit__
#define UIView NSView
#define CGContextRef NSGraphicsContext *
#define CGPoint NSPoint
#define CGRect NSRect
#endif

#import <Cocoa/Cocoa.h>
#import <MapKit/MKGeometry.h>
#import <MapKit/MKOverlay.h>
#import <MapKit/MKTypes.h>

@interface MKOverlayView : UIView
{
}

CGFloat MKRoadWidthAtZoomScale(MKZoomScale zoom);

- (void) drawMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale inContext:(CGContextRef) context;
- (id) initWithOverlay:(id <MKOverlay>) overlay;
- (MKMapPoint) mapPointForPoint:(CGPoint) point;
- (MKMapRect) mapRectForRect:(CGRect) rect;
- (CGPoint) pointForMapPoint:(MKMapPoint) point;
- (CGRect) rectForMapRect:(MKMapRect) rect;
- (void) setNeedsDisplayInMapRect:(MKMapRect) rect;
- (void) setNeedsDisplayInMapRect:(MKMapRect) rect zoomScale:(MKZoomScale) scale;

@end

// EOF
