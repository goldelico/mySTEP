//
//  MKOverlayView.h
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

@interface MKOverlayView : UIView
{
}

@end

CGFloat MKRoadWidthAtZoomScale(MKZoomScale zoom);

// EOF
