//
//  MKAnnotationView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <MapKit/MapKit.h>


@implementation MKAnnotationView

- (id) initWithAnnotation:(id <MKAnnotation>) a reuseIdentifier:(NSString *) ident;
{
	if((self=[super initWithFrame:NSZeroRect]))
		{
		annotation=[a retain];
		reuseIdentifier=[ident retain];
		// FIXME: we need a mechanism (KVO?) so that changes of the annotation attributes result in a setNeedsDisplay (unless we are hidden)
		}
	return self;
}

- (void) dealloc
{
	[annotation release];
	[reuseIdentifier release];
	[leftCalloutAccessoryView release];
	[rightCalloutAccessoryView release];
	[super dealloc];	
}

- (id <MKAnnotation>) annotation; { return annotation; }
- (CGPoint) calloutOffset; { return calloutOffset; }
- (BOOL) canShowCallout; { return canShowCallout; }
- (CGPoint) centerOffset; { return centerOffset; }
- (MKAnnotationViewDragState) dragState; { return dragState; }
- (BOOL) isDraggable; { return draggable; }
- (BOOL) isEnabled; { return enabled; }
- (BOOL) isHighlighted; { return highlighted; }
- (BOOL) isSelected; { return selected; }
- (UIImage *) image; { return image; }
- (UIView *) leftCalloutAccessoryView; { return leftCalloutAccessoryView; }
- (NSString *) reuseIdentifier; { return reuseIdentifier; }
- (UIView *) rightCalloutAccessoryView; { return rightCalloutAccessoryView; }
- (void) setAnnotation:(id <MKAnnotation>) a; { [annotation autorelease]; annotation=[a retain]; }
- (void) setCalloutOffset:(CGPoint) offset;  { calloutOffset=offset; }
- (void) setCanShowCallout:(BOOL) flag; { canShowCallout=flag; }
- (void) setCenterOffset:(CGPoint) offset; { centerOffset=offset; }
- (void) setDraggable:(BOOL) flag; { draggable=flag; }
- (void) setEnabled:(BOOL) flag; { enabled=flag; [self setNeedsDisplay:YES]; }
- (void) setHighlighted:(BOOL) flag; { highlighted=flag; [self setNeedsDisplay:YES]; }
- (void) setImage:(UIImage *) img; { [image autorelease]; image=[img retain]; [self setFrameSize:[img size]]; [self setNeedsDisplay:YES]; }
- (void) setLeftCalloutAccessoryView:(UIView *) view; { [leftCalloutAccessoryView autorelease]; leftCalloutAccessoryView=[view retain]; }
- (void) setRightCalloutAccessoryView:(UIView *) view; { [rightCalloutAccessoryView autorelease]; rightCalloutAccessoryView=[view retain]; }
- (void) setSelected:(BOOL) flag; { [self setSelected:flag animated:NO]; }

- (void) prepareForReuse;
{ // default does nothing
	return;
}

- (void) setDragState:(MKAnnotationViewDragState) state animated:(BOOL) animated;
{
	if(animated)
		{
		
		}
	dragState=state;
	[self setNeedsDisplay:YES];
}

- (void) setSelected:(BOOL) sel animated:(BOOL) animated;
{
	if(animated)
		{
		
		}
	selected=sel;
	[self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect) rect
{ // draw with center at NSZeroPoint
	// handle selection/highlight
	// handle colors
	// FIXME: really draw centered - but this may interfere with the frame and bounds...
	[image drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (NSView *) hitTest:(NSPoint) aPoint
{
	return nil;
}

- (void) mouseDown:(NSEvent *)theEvent;
{
	NSPoint p0 = [self convertPoint:[theEvent locationInWindow] fromView:nil];	// initial point
//	MKMapPoint pnt = [(MKMapView *) [self superview] _mapPointForPoint:p0];	// where did we click on the Mercator map?
	[self isSelected];
	[self canShowCallout];
}

@end

@implementation MKPinAnnotationView

- (id) initWithAnnotation:(id <MKAnnotation>) a reuseIdentifier:(NSString *) ident;
{
	if(self=[super initWithAnnotation:a reuseIdentifier:ident])
		{
		if([a isKindOfClass:[MKUserLocation class]])
			{
			NSString *colorFile=[[NSBundle bundleForClass:[self class]] pathForResource:@"flag_cyan_32" ofType:@"png"];;
			[self setImage:[[[NSImage alloc] initWithContentsOfFile:colorFile] autorelease]];
			}
		else
			[self setPinColor:MKPinAnnotationColorRed];
		centerOffset=(NSPoint) { -5.0, -3.0 };
		[self setDraggable:NO];	
		}
	return self;
}

- (MKPinAnnotationColor) pinColor; { return pinColor; }
- (BOOL) animatesDrop; { return animatesDrop; }
- (void) setAnimatesDrop:(BOOL) flag; { animatesDrop=flag; }

- (void) setPinColor:(MKPinAnnotationColor) color
{
	NSString *colorFile;
	switch(pinColor=color) {
		case MKPinAnnotationColorRed:
			colorFile=@"flag_red_32";
			break;
		case MKPinAnnotationColorGreen:
			colorFile=@"flag_green_32";
			break;
		case MKPinAnnotationColorPurple:
		default:
			colorFile=@"flag_orange_32";
	}
	colorFile=[[NSBundle bundleForClass:[self class]] pathForResource:colorFile ofType:@"png"];
	[self setImage:[[[NSImage alloc] initWithContentsOfFile:colorFile] autorelease]];
}

- (void) prepareForReuse;
{
	// reset any changed parameters
}

- (void) drawRect:(NSRect) rect
{ // draw circle if we represent the user location
	if([annotation isKindOfClass:[MKUserLocation class]])
		{ // only the user location knows its accuracy
		CLLocation *loc=[(MKUserLocation *) annotation location];
		float accuracy=[loc horizontalAccuracy];	// meters
		//	[(MKUserLocation *) annotation isUpdating];
		if(loc && accuracy > 0.0)
			{ // draw a circle showing the accuracy
				float a;	// accuracy in pixels
				NSRect circle;
				NSBezierPath *path;
				CLLocationCoordinate2D pos=[annotation coordinate];
				// it appears as if there is a factor 2 or 4 missing, i.e. the circle is a little smaller on the map as the "meters" value indicates
				float mappoints=accuracy*MKMapPointsPerMeterAtLatitude(pos.latitude);
				a=[(MKMapView *) [self superview] _rectForMapRect:MKMapRectMake(0.0, 0.0, mappoints, 0.0)].size.width;
#if 1
				NSLog(@"accuracy %gm / %gpx", accuracy, a);
#endif
				if(a > 5.0)
					{ // is large enough to be visible
						NSView *mapView;
						NSRect clip;
						circle.size.width=2.0*a;
						circle.size.height=2.0*a;
						circle.origin.x=-a;
						circle.origin.y=-a;	// lower left corner
						[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.5] set];
						path=[NSBezierPath bezierPathWithOvalInRect:circle];
						[path setLineWidth:2.0];
						[NSGraphicsContext saveGraphicsState];
						mapView=[self superview];
						clip=[mapView convertRect:[mapView bounds] toView:self];	// convert superview's bounds to our coordinate system
						[[NSBezierPath bezierPathWithRect:clip] setClip];	// we must temporarily enlarge the clipping path if the circle is larger than the flag image!
						[path fill];	// draw circle
						[NSGraphicsContext restoreGraphicsState];
					}
			}
		// make callout show [loc altitude] and position in human readable format		
		}
	[super drawRect:rect];	// draw flag image
}

@end
