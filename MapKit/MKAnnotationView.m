//
//  MKAnnotationView.m
//  MapKit
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "MKAnnotation.h"
#import "MKAnnotationView.h"
#import "MKPinAnnotationView.h"


@implementation MKAnnotationView

- (id) initWithAnnotation:(id <MKAnnotation>) a reuseIdentifier:(NSString *) ident;
{
	if((self=[super init]))
		{
		annotation=[a retain];
		reuseIdentifier=[ident retain];
		}
	return self;
}

- (void) dealloc
{
	[annotation release];
	[reuseIdentifier release];
	[super dealloc];	
}

- (id <MKAnnotation>) annotation; { return annotation; }
- (BOOL) canShowCallout; { return canShowCallout; }
- (BOOL) isDraggable; { return draggable; }
- (BOOL) isEnabled; { return enabled; }
- (BOOL) isHighlighted; { return highlighted; }
- (BOOL) isSelected; { return selected; }
- (NSString *) reuseIdentifier; { return reuseIdentifier; }
- (void) setAnnotation:(id <MKAnnotation>) a; { [annotation autorelease]; annotation=[a retain]; }
- (void) setCanShowCallout:(BOOL) flag; { canShowCallout=flag; }
- (void) setDraggable:(BOOL) flag; { draggable=flag; }
- (void) setEnabled:(BOOL) flag; { enabled=flag; [self setNeedsDisplay:YES]; }
- (void) setHighlighted:(BOOL) flag; { highlighted=flag; [self setNeedsDisplay:YES]; }
- (void) setSelected:(BOOL) flag; { [self setSelected:flag animated:NO]; }

- (void) prepareForReuse;
{ // default does nothing
	return;
}

- (void) setDragState:(MKAnnotationViewDragState) state animated:(BOOL) animated;
{
	
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
{
	
}

- (NSView *) hitTest:(NSPoint)aPoint
{
	if(!enabled)
		return nil;
	// check aPoint with shape
	return self;
}

- (void) mouseDown:(NSEvent *) event
{
	// select/deselect/drag annotation
	// or make title/subtitle editable
}

@end

@implementation MKPinAnnotationView

- (void) drawRect:(NSRect) rect
{
	
}

@end
