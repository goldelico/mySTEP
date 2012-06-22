//
//  MKPinAnnotationView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MKAnnotationView.h>

typedef enum _MKPinAnnotationColor {
	MKPinAnnotationColorRed = 0,
	MKPinAnnotationColorGreen,
	MKPinAnnotationColorPurple
} MKPinAnnotationColor;

@interface MKPinAnnotationView : MKAnnotationView
{
	MKPinAnnotationColor pinColor;
	BOOL animatesDrop;
}

- (BOOL) animatesDrop;
- (MKPinAnnotationColor) pinColor;
- (void) setAnimatesDrop:(BOOL) flag;
- (void) setPinColor:(MKPinAnnotationColor) color;

@end

// EOF
