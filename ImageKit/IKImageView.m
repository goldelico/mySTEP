//
//  IKImageView.m
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IKImageView.h"


@implementation IKImageView

- (id) initWithFrame:(NSRect) frame
{
    if((self = [super initWithFrame:frame]))
		{
        // Initialization code here.
		}
    return self;
}

- (void) drawRect:(NSRect) rect
{
    // Drawing code here.
}

- (BOOL) autohidesScrollers;
- (BOOL) autoresizes;
- (NSColor *) backgroundColor;
- (NSString *) currentToolMode;
- (id) delegate;
- (BOOL) doubleClickOpensImageEditPanel;
- (BOOL) editable;
- (BOOL) hasHorizontalScroller;
- (BOOL) hasVerticalScroller;
- (CIFilter *) imageCorrection;
- (CGFloat) rotationAngle;
- (BOOL) supportsDragAndDrop;
- (CGFloat) zoomFactor;

- (void) setAutohidesScrollers:(BOOL) flag;
- (void) setAutoresizes:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setCurrentToolMode:(NSString *) mode;
- (void) setDelegate:(id) delegate;
- (void) setDoubleClickOpensImageEditPanel:(BOOL) flag;
- (void) setEditable:(BOOL) flag;
- (void) setHasHorizontalScroller:(BOOL) flag;
- (void) setHasVerticalScroller:(BOOL) flag;
- (void) setImageCorrection:(CIFilter *) filter;
- (void) setRotationAngle:(CGFloat) angle;
- (void) setSupportsDragAndDrop:(BOOL) flag;
- (void) setZoomFactor:(CGFloat) zoom;

- (NSPoint) convertImagePointToViewPoint:(NSPoint) pnt;
- (NSRect) convertImageRectToViewRect:(NSRect) pnt;
- (NSPoint) convertViewPointToImagePoint:(NSPoint) pnt;
- (NSRect) convertViewRectToImageRect:(NSRect) pnt;
- (void) flipImageHorizontal:(id) sender;
- (void) flipImageVertical:(id) sender;
- (CGImageRef) image;
- (NSDictionary *) imageProperties;
- (NSSize) imageSize;
- (LKLayer *) overlayForType:(NSString *) type;
- (void) scrollToPoint:(NSPoint) pnt;
- (void) scrollToRect:(NSRect) rect;
- (void) setImage:(CGImageRef) image imageProperties:(NSDictionary *) meta;
- (void) setImageWithURL:(NSURL *) url;
- (void) setImageZoomFactor:(CGFloat) zoom centerPoint:(NSPoint) center;
- (void) setOverlay:(LKLayer *) layer forType:(NSString *) type;
- (void) setRotationAngle:(CGFloat) angle centerPoint:(NSPoint) center;
- (void) zoomImageToActualSize:(id) sender;
- (void) zoomImageToFit:(id) sender;
- (void) zoomImageToRect:(NSRect) rect;

@end

#if MATERIAL

- (NSView *) hitTest:(NSPoint)aPoint
{ // this is used to prevent clicks to reach the scrolled document
	NSView *v=[super hitTest:aPoint];
	if ([v isDescendantOf:[self contentView]])
		return self;	// block content view and its content - but not our scrollers
	return v;
}

- (void) mouseDown:(NSEvent *)theEvent
{
#if 0
	NSLog(@"mouseDown - loc=%@", NSStringFromPoint([theEvent locationInWindow]));
#endif
	startPt = [theEvent locationInWindow];
	if ([theEvent clickCount] == 2) {
		NSPoint pt = [self convertPoint:startPt fromView:nil];
		NSRect frame = [self frame];
#if 0
		NSLog(@"double click");
#endif
		startOrigin = [self centredPointInDocView];	
		[self scrollPointToCentre:NSMakePoint(startOrigin.x + (pt.x - (frame.origin.x+frame.size.width/2.0))*_scale/2.0,
											  startOrigin.y - (pt.y - (frame.origin.y+frame.size.height/2.0))*_scale/2.0)];	// initial move
	}
	startOrigin = [self centredPointInDocView];	
	[self setDocumentCursor:[NSCursor closedHandCursor]];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
#if 0
	NSLog(@"mouseDragged - loc=%@", NSStringFromPoint([theEvent locationInWindow]));
#endif	
    [self scrollPointToCentre:
	 NSMakePoint(startOrigin.x - ([theEvent locationInWindow].x - startPt.x),
				 startOrigin.y - ([theEvent locationInWindow].y - startPt.y))];
}

- (void) mouseUp:(NSEvent *)theEvent
{
#if 0
	NSLog(@"mouseUp");
#endif	
	[self setDocumentCursor:[NSCursor pointingHandCursor]];
}

- (id) initWithFrame:(NSRect)frame
{
    if ((self = [super initWithFrame:frame])) {
		[self awakeFromNib];	// initialize everything
	}
    return self;
}

- (void) setFrameSize:(NSSize) size;
{ // keep position of document view stable even if view is resized
#if DEBUG
	NSLog(@"setframesize = %@", NSStringFromSize(size));
#endif
	[super setFrameSize:size];
}

- (void) setFrame:(NSRect) frame;
{ // keep position of document view stable even if view is resized
	NSPoint p=[self centredPointInDocView];
	// FIXME: this might resize the document view and the clip view and reset their scaling
	[super setFrame:frame];
	[self scrollPointToCentre:p];	// keep center point stable during resize of the scrollview
	//	[self zoomViewByFactor:1.0/_scale andCentrePoint:p];	// use current scale
	[self setNeedsDisplay:YES];	
}

- (void) awakeFromNib
{
	_scale = 1.0;	// initial scale as assumed by view hierarchy
	//	[self zoomViewToAbsoluteScale:[[NSUserDefaults standardUserDefaults] floatForKey:@"zoom"]];	// as defined by user defaults
	[self zoomViewToAbsoluteScale:[[[NSUserDefaultsController sharedUserDefaultsController] valueForKeyPath:@"values.zoom"] floatValue]];	// as defined by user defaults
	[[self contentView] setCopiesOnScroll:NO];	// we may have changed the scale
	if (control) 	{ // adjust
		[control setAction:@selector(zoomToValueOfControl:)];
		[control setTarget:self];
		[self reflectInControl:_scale];
	}
	[self center:nil];
	[self setDocumentCursor:[NSCursor pointingHandCursor]];
}

- (IBAction) center:(id) sender;
{
	NSRect  fr = [[self documentView] frame];
	NSPoint cp;
	cp.x = (fr.origin.x + fr.size.width / 2.0);
	cp.y = (fr.origin.y + fr.size.height / 2.0);
	[self scrollPointToCentre:cp];	// show center point
}

- (IBAction) zoomIn: (id) sender
{
	// zooms the view IN by a factor of 2 (command/action)
	
	[self zoomViewByFactor:sqrt(2.0)];
}

- (IBAction) zoomOut: (id) sender
{
	// zooms the view OUT by a factor of 2 (command/action)
	
	[self zoomViewByFactor:sqrt(0.5)];
}

- (IBAction) zoomToActualSize: (id) sender
{
	// zooms the view to 100% (command/action)
	
	[self zoomViewToAbsoluteScale:1.0];
}

- (IBAction) zoomToValueOfControl: (id) sender;
{
#if 0
	NSLog(@"temp disabled");
	return;
#endif
	if ([control respondsToSelector:@selector(minValue)]) { // stepper or slider
		double val = ([control doubleValue]-[(NSSlider *)control minValue])/([(NSSlider *)control maxValue]-[(NSSlider *)control minValue]);	// % of slider scale
#if 0
		NSLog(@"slider %.2f %%", val);
#endif
		val = exp(val*(log([self maximumScale])-log([self minimumScale]))+log([self minimumScale]));
#if 0
		NSLog(@"scale %.2f %%", val);
#endif
		[self zoomViewToAbsoluteScale:val];	
	}
	else {
		[self zoomViewToAbsoluteScale:[sender floatValue]];
	}
}

- (IBAction) zoomFitInWindow: (id) sender
{
	// zooms the view to fit within the current window (command/action)
	NSRect  sfr = [[self contentView] frame];
	[self zoomViewToFitRect:sfr];
	[self center:nil];
}

- (void) zoomViewByFactor: (float) factor
{
	NSRect  fr = [[self contentView] documentVisibleRect];
	NSPoint cp;
	
	//	cp.x = (fr.origin.x + (fr.size.width / 2.0)*factor)*_scale;	// center point before zooming
	//	cp.y = (fr.origin.y + (fr.size.height / 2.0))*_scale;
	
	cp.x = (fr.origin.x*_scale + (fr.size.width / 2.0)*_scale)*factor;	// new center point after zooming
	cp.y = (fr.origin.y*_scale + (fr.size.height / 2.0)*_scale)*factor;
	
	[self zoomViewByFactor:factor andCentrePoint:cp];
}

- (void) zoomViewToAbsoluteScale: (float) newScale
{
	// zooms the view to the scale <newScale> e.g. 2.0 = 200%, etc. The currently centred point remains centred.
	
	float factor = newScale / [self scale];
	[self zoomViewByFactor:factor];
}

- (void) zoomViewToFitRect: (NSRect) aRect
{
	NSRect  fr = [[self documentView] frame];
	
	float sx, sy;
	
	sx = aRect.size.width / fr.size.width;
	sy = aRect.size.height / fr.size.height;
	float s = MIN( sx, sy );
	
	[self zoomViewByFactor:s andCentrePoint:[self centredPointInDocView]];
}

- (void) zoomViewToRect: (NSRect) aRect;
{
	NSRect  fr = [[self contentView] documentVisibleRect];
	NSPoint cp;
	
	float sx, sy;
	
	sx = fr.size.width / aRect.size.width;
	sy = fr.size.height / aRect.size.height;
	
	cp.x = aRect.origin.x + aRect.size.width / 2.0;
	cp.y = aRect.origin.y + aRect.size.height / 2.0;
	
	[self zoomViewByFactor:MIN( sx, sy ) andCentrePoint:cp];
}

- (void)	zoomViewByFactor: (float) factor andCentrePoint:(NSPoint) p
{
#if 0
	NSLog(@"zoomViewByFactor:%.6lf andCentrePoint:%@", factor, NSStringFromPoint(p));
#endif
	if ( factor != 0.0 ) {
		NSSize  newSize;
		NSRect  fr;
		float   sc;
		
		sc = factor * [self scale];
		
		if ( sc <= [self minimumScale]+0.01) {
			sc = [self minimumScale];
			factor = sc / [self scale];
		}
		
		if ( sc >= [self maximumScale]-0.01) {
			sc = [self maximumScale];
			factor = sc / [self scale];
		}
		
		if ( sc != [self scale]) { // change scale
			_scale = sc;
			//			[[NSUserDefaults standardUserDefaults] setValue:[NSNumber numberWithFloat:_scale] forKey:@"zoom"];
			[[NSUserDefaultsController sharedUserDefaultsController] setValue:[NSNumber numberWithFloat:_scale] forKeyPath:@"values.zoom"];
#if 0
			NSLog(@"scale=%lf", sc);
#endif
			[self reflectInControl:_scale];
			
			fr = [[self documentView] frame];
			
			newSize.width = newSize.height = factor;
			
			[[self documentView] scaleUnitSquareToSize:newSize];
			
			fr.size.width *= factor;
			fr.size.height *= factor;
			
			[[self documentView] setFrame:fr];
			[[self documentView] setNeedsDisplay:YES];
			
			[self scrollPointToCentre:p];
			[self setNeedsDisplay:YES];
		}
	}
}

- (void)	zoomWithScrollWheelDelta:(float) delta toCentrePoint:(NSPoint) cp
{
	float factor = 1.0;
	if ( delta > 0.5 )
		factor = 0.9;
	else if (delta < -0.5)
		factor = 1.1;
	
	[self zoomViewByFactor:factor andCentrePoint:cp ];
}

- (void)	scrollWheel:(NSEvent *)theEvent
{
	if (([theEvent modifierFlags] & NSAlternateKeyMask) != 0 ) {   
		// note to self - using the current mouse position here makes zooming really difficult, contrary
		// to what you might think. It's more intuitive if the centre point remains constant
		
		NSPoint p = [self centredPointInDocView];
		[self zoomWithScrollWheelDelta:[theEvent deltaY] toCentrePoint:p];
	}
	else {
		// [super scrollWheel: theEvent]; - NO: this moves the scrollers only if they are visible at all!
		NSPoint p = [self centredPointInDocView];
		p.x += [theEvent deltaX];
		p.y -= [theEvent deltaY];
		[self scrollPointToCentre:p];
	}
}

- (NSPoint)	centredPointInDocView
{
	NSRect  fr = [[self contentView] documentVisibleRect];
	NSPoint cp;
	
	cp.x = (fr.origin.x + (fr.size.width / 2.0))*_scale;
	cp.y = (fr.origin.y + (fr.size.height / 2.0))*_scale;
	return cp;
}

- (void) scrollPointToCentre:(NSPoint) aPoint
{
	// given a point in view coordinates, the view is scrolled so that the point is centred in the
	// current document view
	
	NSRect  fr = [[self contentView] documentVisibleRect];	// frame of the clip view in document view's coordinates
	NSPoint sp;
#if 0
	NSRect  dv = [[self documentView] frame];
	NSLog(@"target center=%@", NSStringFromPoint(aPoint));
	NSLog(@"scale=%f", _scale);
	NSLog(@"[self frame]=%@", NSStringFromRect([self frame]));
	NSLog(@"[self centredPointInDocView]=%@", NSStringFromPoint([self centredPointInDocView]));
	NSLog(@"[contentView frame]=%@", NSStringFromRect([[self contentView] frame]));
	NSLog(@"[contentView bounds]=%@", NSStringFromRect([[self contentView] bounds]));
	NSLog(@"[documentView frame]=%@", NSStringFromRect([[self documentView] frame]));
	NSLog(@"[documentView bounds]=%@", NSStringFromRect([[self documentView] bounds]));
	NSLog(@"[contentView documentVisibleRect]=%@", NSStringFromRect(fr));
	
#endif
	sp.x = (aPoint.x - ( fr.size.width / 2.0 ) *_scale);
	sp.y = (aPoint.y - ( fr.size.height / 2.0 ) *_scale);
#if 0
	NSLog(@"scroll to point=%@", NSStringFromPoint(sp));
#endif
	//	[self scrollPoint:sp];
	[[self contentView] scrollToPoint:sp];
	[[self documentView] setNeedsDisplay:YES];
	[self reflectScrolledClipView:[self contentView]];
#if 0
	if (!NSEqualPoints(aPoint, [self centredPointInDocView])) {
		NSLog(@"scroll point to center failed!!!");
		NSLog(@"[self frame]=%@", NSStringFromRect([self frame]));
		NSLog(@"[contentView frame]=%@", NSStringFromRect([[self contentView] frame]));
		NSLog(@"[contentView bounds]=%@", NSStringFromRect([[self contentView] bounds]));
		NSLog(@"[documentView frame]=%@", NSStringFromRect([[self documentView] frame]));
		NSLog(@"[documentView bounds]=%@", NSStringFromRect([[self documentView] bounds]));
		NSLog(@"[contentView documentVisibleRect]=%@", NSStringFromRect(fr));
		NSLog(@"target=%@", NSStringFromPoint(aPoint));
		NSLog(@"result=%@", NSStringFromPoint([self centredPointInDocView]));
	}
#endif
}

- (float) scale
{
	// returns the current scaling factor. 1.0 = 100%, i.e. actual size.
	if (_scale == 0.0) {
		NSLog(@"!!! scale == 0.0 !!!");
	}
	return _scale;
}

#endif