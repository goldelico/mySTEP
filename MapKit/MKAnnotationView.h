//
//  MKAnnotationView.h
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

typedef enum MKAnnotationViewDragState
{
	MKAnnotationViewDragStateNone = 0,
	MKAnnotationViewDragStateStarting,
	MKAnnotationViewDragStateDragging,
	MKAnnotationViewDragStateCanceling,
	MKAnnotationViewDragStateEnding
} MKAnnotationViewDragState;


@interface MKAnnotationView : UIView
{
/*	BOOL dragabble
	callout
	canShowCallout
 ? selected
 */
}

#if 0

@property (nonatomic, retain) id <MKAnnotation> annotation
@property (nonatomic) CGPoint calloutOffset
@property (nonatomic) BOOL canShowCallout
@property (nonatomic) CGPoint centerOffset
@property (nonatomic, getter=isDraggable) BOOL draggable
@property (nonatomic) MKAnnotationViewDragState dragState
@property (nonatomic, getter=isEnabled) BOOL enabled
@property (nonatomic, getter=isHighlighted) BOOL highlighted
@property (nonatomic, retain) UIImage *image
@property (retain, nonatomic) UIView *leftCalloutAccessoryView
@property (nonatomic, readonly) NSString *reuseIdentifier
@property (retain, nonatomic) UIView *rightCalloutAccessoryView
@property (nonatomic, getter=isSelected) BOOL selected

#endif

- (id) initWithAnnotation:(id <MKAnnotation>) annotation reuseIdentifier:(NSString *) ident;
- (void) prepareForReuse;
- (void) setDragState:(MKAnnotationViewDragState) state animated:(BOOL) animated;
- (void) setSelected:(BOOL) selected animated:(BOOL) animated;

@end

// EOF
