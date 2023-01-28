//
//  IKImageView.m
//  ImageKit
//
//  Created by H. Nikolaus Schaller on 16.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "IKImageView.h"

NSString *IKToolModeMove=@"IKToolModeMove";
NSString *IKToolModeSelect=@"IKToolModeSelect";
NSString *IKToolModeCrop=@"IKToolModeCrop";
NSString *IKToolModeRotate=@"IKToolModeRotate";
NSString *IKToolModeAnnotate=@"IKToolModeAnnotate";

#define NIMP

@interface _RotateFlipView : NSView
- (void) setContentView:(NSView *) view;
- (CGFloat) angle;
- (void) setAngle:(CGFloat) angle;
- (NSPoint) center;
- (void) setCenter:(NSPoint) center;

- (BOOL) isVerticallyFlipped;
- (BOOL) isHorizontallyFlipped;
- (void) setFlipVertical:(BOOL) flip;
- (void) setFlipHorizontal:(BOOL) flip;

- (float) scale;	// scale of superview
- (void) zoomToRect:(NSRect) rect;	// object coordinates

- (IBAction) zoomFit:(id) sender;
- (IBAction) zoomUnity:(id) sender;
- (IBAction) zoomIn:(id) sender;
- (IBAction) zoomOut:(id) sender;
- (IBAction) center:(id) sender;

- (IBAction) rotateImageLeft:(id) sender;
- (IBAction) rotateImageRight:(id) sender;
- (IBAction) rotateImageLeft90:(id) sender;
- (IBAction) rotateImageRight90:(id) sender;
- (IBAction) rotateImageUpright:(id) sender;

- (IBAction) flipHorizontal:(id) sender;
- (IBAction) flipVertical:(id) sender;
- (IBAction) unflip:(id) sender;

@end

@implementation _RotateFlipView
@end

@implementation IKImageView

- (id) initWithFrame:(NSRect) frame
{
	if((self = [super initWithFrame:frame]))
		{
		NSClipView *cv=[[[NSClipView alloc] initWithFrame:frame] autorelease];
		_rotationView=[[[_RotateFlipView alloc] initWithFrame:frame] autorelease];
		_imageView=[[[NSImageView alloc] initWithFrame:frame] autorelease];	// can also handle scaling! */
		_scrollView=[[NSScrollView alloc] initWithFrame:frame];
		[_scrollView setContentView:cv];
		[_scrollView setDocumentView:_rotationView];
		[(_RotateFlipView *) _rotationView setContentView:_imageView];
		}
	return self;
}

- (void) dealloc;
{
	[super dealloc];
}

- (void) drawRect:(NSRect) rect
{
	// Drawing code here.
}

- (BOOL) autohidesScrollers; { return [_scrollView autohidesScrollers]; }
- (BOOL) autoresizes; { return _autoresizes; }
- (NSColor *) backgroundColor; { return _backgroundColor; }
- (NSString *) currentToolMode; { return _currentToolMode; }
- (id) delegate; { return _delegate; }
- (BOOL) doubleClickOpensImageEditPanel; { return _doubleClickOpensImageEditPanel; }
- (BOOL) editable; { return _editable; }
- (BOOL) hasHorizontalScroller; { return [_scrollView hasHorizontalScroller]; }
- (BOOL) hasVerticalScroller; { return [_scrollView hasVerticalScroller]; }
- (CIFilter *) imageCorrection; { return nil; }
- (CGFloat) rotationAngle; { return [(_RotateFlipView *) _rotationView angle]; }
- (BOOL) supportsDragAndDrop; { return _supportsDragAndDrop; }
- (CGFloat) zoomFactor; { return [(_RotateFlipView *) _rotationView scale]; }

- (void) setAutohidesScrollers:(BOOL) flag; { [_scrollView setAutohidesScrollers:flag]; }
- (void) setAutoresizes:(BOOL) flag; { _autoresizes=flag; }
- (void) setBackgroundColor:(NSColor *) color; { NIMP; }
- (void) setCurrentToolMode:(NSString *) mode; { NIMP; }
- (void) setDelegate:(id) delegate; { _delegate=delegate; }
- (void) setDoubleClickOpensImageEditPanel:(BOOL) flag; { _doubleClickOpensImageEditPanel=flag; }
- (void) setEditable:(BOOL) flag; { _editable=flag; }
- (void) setHasHorizontalScroller:(BOOL) flag; { [_scrollView setHasHorizontalScroller:flag]; }
- (void) setHasVerticalScroller:(BOOL) flag; { [_scrollView setHasVerticalScroller:flag]; }
- (void) setImageCorrection:(CIFilter *) filter; { NIMP; }
- (void) setRotationAngle:(CGFloat) angle; { [(_RotateFlipView *) _rotationView setAngle:angle]; }
- (void) setSupportsDragAndDrop:(BOOL) flag; { _supportsDragAndDrop=flag; }
- (void) setZoomFactor:(CGFloat) zoom; { [_scrollView setMagnification:zoom]; }

- (NSPoint) convertImagePointToViewPoint:(NSPoint) pnt; { return [_imageView convertPoint:pnt toView:self]; }
- (NSRect) convertImageRectToViewRect:(NSRect) rect; { return [_imageView convertRect:rect toView:self]; }
- (NSPoint) convertViewPointToImagePoint:(NSPoint) pnt; { return [_imageView convertPoint:pnt fromView:self]; }
- (NSRect) convertViewRectToImageRect:(NSRect) rect; { return [_imageView convertRect:rect fromView:self]; }

- (void) flipImageHorizontal:(id) sender; { [(_RotateFlipView *) _rotationView flipHorizontal:sender]; }
- (void) flipImageVertical:(id) sender; { [(_RotateFlipView *) _rotationView flipVertical:sender]; }
- (CGImageRef) image; { return (CGImageRef)[_imageView image]; }
- (NSDictionary *) imageProperties; { return NIMP; }
- (NSSize) imageSize; { return [(NSImage *)[self image] size]; }
- (LKLayer *) overlayForType:(NSString *) type; { return nil; }

- (void) scrollToPoint:(NSPoint) pnt;
{
	[[_scrollView contentView] scrollToPoint:pnt];
	[_scrollView reflectScrolledClipView:[_scrollView contentView]];
}

- (void) scrollToRect:(NSRect) rect; { [self scrollToPoint:NSMakePoint(NSMidX(rect), NSMidY(rect))]; }

- (void) setImage:(CGImageRef) image imageProperties:(NSDictionary *) meta;
{
	NSRect rect={ NSZeroPoint, [(NSImage *) image size] };
	[_imageView setImage:(NSImage *) image];
	[_imageView setFrame:rect]; // resize _imageView
	[_imageProperties autorelease];
	// update in NSScroolZoomView
	_imageProperties=[meta retain];
	[self setNeedsDisplay:YES];	// needs redraw
}

- (void) setImageWithURL:(NSURL *) url;
{
	[self setImage:(CGImageRef)[[[NSImage alloc] initWithContentsOfURL:url] autorelease] imageProperties:nil];
}

- (void) setImageZoomFactor:(CGFloat) zoom centerPoint:(NSPoint) center;
{
	[self setCenter:center];
	[self setScale:zoom];
}

- (void) setOverlay:(LKLayer *) layer forType:(NSString *) type; { NIMP; }

- (void) setRotationAngle:(CGFloat) angle centerPoint:(NSPoint) center;
{
	[self setCenter:center];
	[self setRotationAngle:angle];
}

- (void) zoomImageToActualSize:(id) sender; { [(_RotateFlipView *) _rotationView zoomUnity:sender]; }
- (void) zoomImageToFit:(id) sender; { [(_RotateFlipView *) _rotationView zoomFit:sender]; }
- (void) zoomImageToRect:(NSRect) rect; { [(_RotateFlipView *) _rotationView setScaleForRect:rect]; }

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

- (void) mouseDragged:(NSEvent *)theEvent
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

- (void) zoomWithScrollWheelDelta:(float) delta toCentrePoint:(NSPoint) cp
{
	float factor = 1.0;
	if ( delta > 0.5 )
		factor = 0.9;
		else if (delta < -0.5)
			factor = 1.1;

			[self zoomViewByFactor:factor andCentrePoint:cp ];
}

- (void) scrollWheel:(NSEvent *)theEvent
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

#endif
