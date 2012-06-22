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
		[self setImage:[NSImage imageNamed:@"flag_32"]];
		// set offet so that flag point is at the right position
		[self setDraggable:NO];	
		}
	return self;
}

- (void) prepareForReuse;
{
	// reset any changed parameters
}

- (void) drawRect:(NSRect) rect
{
	CLLocationCoordinate2D pos=[annotation coordinate];
	if(0 && [annotation isKindOfClass:[MKUserLocation class]])
		{ // general pin annotations don't know accuracy
		CLLocation *loc=[(MKUserLocation *) annotation location];
		float accuracy=[loc horizontalAccuracy];	// meters
		//	[(MKUserLocation *) annotation isUpdating];
		if(loc && accuracy > 0.0)
			{ // draw a circle showing the accuracy
				NSPoint a;
				NSRect circle;
				NSBezierPath *path;
				accuracy *= MKMapPointsPerMeterAtLatitude(pos.latitude);	// mappoint size
				a=[(MKMapView *) [self superview] _pointForMapPoint:MKMapPointMake(accuracy, 0.0)];	// convert to screen coordinates
				circle.size.width=2.0*a.x;
				circle.size.height=2.0*a.x;
				circle.origin.x=-a.x;
				circle.origin.y=-a.x;	// lower left corner
				[[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:1.0 alpha:0.5] set];
				path=[NSBezierPath bezierPathWithOvalInRect:circle];
				[path setLineWidth:2.0];
				// we must temporarily remove clipping!
				[path fill];	// draw circle
			}
		// make callout show [loc altitude] and position in human readable format		
		}
	[super drawRect:rect];	// draw flag image
}

@end
