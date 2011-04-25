//
//  MKAnnotationView.h
//  MapKit
//
//  Created by H. Nikolaus Schaller on 04.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __UIKit__
#define UIView NSView
#endif

#import <Cocoa/Cocoa.h>
#import <MapKit/MKGeometry.h>
#import <MapKit/MKOverlay.h>
#import <MapKit/MKTypes.h>

typedef enum MKAnnotationViewDragState
{
	MKAnnotationViewDragStateNone = 0,
	MKAnnotationViewDragStateStarting,
	MKAnnotationViewDragStateDragging,
	MKAnnotationViewDragStateCanceling,
	MKAnnotationViewDragStateEnding
} MKAnnotationViewDragState;

// a better design decision by those who defined this API
// would have been to subclass NSCell...
// and have MKMapView use a dataSource like NSTableView

@interface MKAnnotationView : UIView
{
	id <MKAnnotation> annotation;
	NSString *reuseIdentifier;
	BOOL canShowCallout;
	BOOL draggable;
	BOOL enabled;
	BOOL highlighted;
	BOOL selected;
}

- (id <MKAnnotation>) annotation;
- (BOOL) canShowCallout;
- (BOOL) isDraggable;
- (BOOL) isEnabled;
- (BOOL) isHighlighted;
- (BOOL) isSelected;
- (NSString *) reuseIdentifier;
- (void) setAnnotation:(id <MKAnnotation>) a;
- (void) setCanShowCallout:(BOOL) flag;
- (void) setDraggable:(BOOL) flag;
- (void) setEnabled:(BOOL) flag;
- (void) setHighlighted:(BOOL) flag;
- (void) setSelected:(BOOL) flag;

#if 0

@property (nonatomic) CGPoint calloutOffset
@property (nonatomic) CGPoint centerOffset
@property (nonatomic) MKAnnotationViewDragState dragState
@property (nonatomic, retain) UIImage *image
@property (retain, nonatomic) UIView *leftCalloutAccessoryView
@property (retain, nonatomic) UIView *rightCalloutAccessoryView

#endif

- (id) initWithAnnotation:(id <MKAnnotation>) annotation reuseIdentifier:(NSString *) ident;
- (void) prepareForReuse;
- (void) setDragState:(MKAnnotationViewDragState) state animated:(BOOL) animated;
- (void) setSelected:(BOOL) sel animated:(BOOL) animated;

@end

// EOF
