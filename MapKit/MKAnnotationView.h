//
//  MKAnnotationView.h
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
#define CGPoint NSPoint
#endif

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
	CGPoint calloutOffset;
	CGPoint centerOffset;
	id <MKAnnotation> annotation;
	NSString *reuseIdentifier;
	UIImage *image;
	UIView *leftCalloutAccessoryView;
	UIView *rightCalloutAccessoryView;
	MKAnnotationViewDragState dragState;
	BOOL canShowCallout;
	BOOL draggable;
	BOOL enabled;
	BOOL highlighted;
	BOOL selected;
}

- (id <MKAnnotation>) annotation;
- (CGPoint) calloutOffset;
- (BOOL) canShowCallout;
- (CGPoint) centerOffset;
- (MKAnnotationViewDragState) dragState;
- (BOOL) isDraggable;
- (BOOL) isEnabled;
- (BOOL) isHighlighted;
- (UIImage *) image;
- (BOOL) isSelected;
- (UIView *) leftCalloutAccessoryView;
- (NSString *) reuseIdentifier;
- (UIView *) rightCalloutAccessoryView;
- (void) setAnnotation:(id <MKAnnotation>) a;
- (void) setCalloutOffset:(CGPoint) offset;
- (void) setCanShowCallout:(BOOL) flag;
- (void) setCenterOffset:(CGPoint) offset;
- (void) setDraggable:(BOOL) flag;
- (void) setEnabled:(BOOL) flag;
- (void) setHighlighted:(BOOL) flag;
- (void) setImage:(UIImage *) image;
- (void) setLeftCalloutAccessoryView:(UIView *) view;
- (void) setRightCalloutAccessoryView:(UIView *) view;
- (void) setSelected:(BOOL) flag;

- (id) initWithAnnotation:(id <MKAnnotation>) annotation reuseIdentifier:(NSString *) ident;
- (void) prepareForReuse;
- (void) setDragState:(MKAnnotationViewDragState) state animated:(BOOL) animated;
- (void) setSelected:(BOOL) sel animated:(BOOL) animated;

@end

// EOF
