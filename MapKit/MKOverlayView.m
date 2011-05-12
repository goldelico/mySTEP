//
//  MKOverlayView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "MKOverlayView.h"


@implementation MKOverlayView

- (NSView *) hitTest:(NSPoint)aPoint
{
	return nil;	// always fail
}

- (void) drawRect:(NSRect) rect
{
#if 1
	[[NSColor greenColor] set];
	NSRectFill(rect);
#endif
}

@end

