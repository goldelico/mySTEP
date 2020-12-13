//
//  NSScaleRotateFlipView.m
//  ElectroniCAD
//
//  Created by H. Nikolaus Schaller on 07.12.19.
//  Copyright 2019 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKitExtensions/NSScaleRotateFlipView.h>

@implementation NSScaleRotateFlipView

- (id) initWithFrame:(NSRect)frame
{
	if((self = [super initWithFrame:frame]))
		{
		_scale=1.0;	// initialize
		}
	return self;
}

- (BOOL) wantsDefaultClipping; { return NO; }	// do not clip subview to our bounds

- (void) viewDidMoveToSuperview
{ // set default scale - we now have a superview and enclosingScrollView
	[self setScale:1.0];
}

/* basic principle:
 * we are the documentView of the NSClipView
 * our frame determines scroller dimensions (in relation to the NSClipView frame)
 * the clip view moves us around (and our contentView)
 * hence we scale our frame according to the scale factor
 * based on our content view frame size (ignoring what is set here!)
 * we set the origin of the content view's frame to NSZeroPoint so that our bounds match the content view if unrotated
 * we keep our own bounds the same size as our content view
 */

- (void) updateDimensions
{
	NSView *contentView;
	if((contentView=[self contentView]))
		{
		NSRect frame=[contentView frame];
		NSPoint center=[self center];
		float angle;
		//	[super setPostsFrameChangedNotifications:YES];	- ist schon gesetzt - bei NO gibt es keine Scroller mehr
		//	[super setPostsBoundsChangedNotifications:NO];	- kein Einfluß
		frame.origin=NSZeroPoint;
		[super setFrameSize:NSMakeSize(_scale*frame.size.width, _scale*frame.size.height)];	// apply scaling
		[contentView setFrameOrigin:frame.origin];	// align with our (0, 0)
		// we have to undo rotation and flipping before setBounds sind the result seems to depend on the current internal matrix
		[super setBoundsRotation:0];	// unrotate before setting bounds
		if(_boundsAreFlipped)
			[super scaleUnitSquareToSize:NSMakeSize(1.0, -1.0)];	// undo flipping
		[super setBounds:frame];	// make the same as contentView
		[super translateOriginToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame))];	// rotate around center
		angle=_rotationAngle;
		if((_boundsAreFlipped=[self isFlipped]))
			{
			angle= -angle;
			[super scaleUnitSquareToSize:NSMakeSize(1.0, -1.0)];
			}
		[super setBoundsRotation:angle];
		[super setFrameRotation:0];
		[super translateOriginToPoint:NSMakePoint(-NSMidX(frame), -NSMidY(frame))];	// rotate around center
		[self setCenter:center];	// do all scaling and rotation around center of NSClipView
		}
}

#if 0
- (void) setFrameSize:(NSSize) frame
{ // here we apply scaling and rotation to contentView and self
	NSPoint center=[self center];
	[super setFrameSize:frame];
	[self setCenter:center];	// do all scaling and rotation around center of NSClipView
}
#endif

- (void) resizeWithOldSuperviewSize:(NSSize) oldSize
{ // resizing the NSClipView must adjust scaling
	NSRect newBounds=[[self superview] bounds];
	NSSize newSize=newBounds.size;
	// any change does not keep center stable and makes the supervierw bounds origin go to (0, 0)
	// but only on the second call!
	[super resizeWithOldSuperviewSize:oldSize];	// default behaviour
	if(_autoMagnifyOnResize)
		{ // keep contentView unscaled by resizing
			float scalex=newSize.width/oldSize.width;
			float scaley=newSize.height/oldSize.height;
			[self setScale:[self scale]*MIN(scalex, scaley)];	// or by max?
		}
	else
		[self updateDimensions];
}

- (BOOL) isHorizontallyFlipped;
{
	return _isHorizontallyFlipped;
}

- (BOOL) isFlipped;
{ // tells the drawing system we are flipped
	return _isVerticallyFlipped;
}

- (void) setFlipped:(BOOL) flag;
{
	_isVerticallyFlipped=flag;
	[self updateDimensions];
}

- (NSView *) contentView;
{
	NSArray *a=[self subviews];
	return [a count] ? [a objectAtIndex:0]:nil;
}

- (void) setContentView:(NSView *) object;
{ // replace subview or add subview
	NSView *contentView=[self contentView];
	if(!contentView)
		[self addSubview:object];
	else if(contentView != object)
		[self replaceSubview:contentView with:object];
	[self updateDimensions];	// trigger update of bounds
}

- (NSRect) contentFrame
{
	NSView *cv=[self contentView];
	if(!cv)
		return NSZeroRect;
	if([cv respondsToSelector:@selector(activeFrame)])
		return [cv activeFrame];
	return [cv frame];
}

- (NSPoint) center
{ // get center of currently visible area in document coordinates
	NSScrollView *scrollView=[self enclosingScrollView];
	if(scrollView)
		{
		NSClipView *clipView=[scrollView contentView];
		NSRect clipViewFrame=[clipView frame];
		NSPoint clipViewCenter=NSMakePoint(NSMidX(clipViewFrame), NSMidY(clipViewFrame));
		return [[self contentView] convertPoint:clipViewCenter fromView:scrollView];
		}
	return NSZeroPoint;
}

- (void) setCenter:(NSPoint) center;
{ // move this content point to center of view
	NSScrollView *scrollView;
	NSClipView *clipView;
	if((scrollView=[self enclosingScrollView]) && (clipView=[scrollView contentView]))
		{
		NSRect cvbounds=[clipView bounds];
		NSPoint cvcenter=[[self contentView] convertPoint:center toView:clipView];
		cvcenter.x -= 0.5*NSWidth(cvbounds);
		cvcenter.y -= 0.5*NSHeight(cvbounds);
		[clipView scrollToPoint:cvcenter];
		[scrollView reflectScrolledClipView:clipView];
		[self setNeedsDisplay:YES];
		}
}

- (float) scale; { return _scale; }

- (void) setScale:(float) scale
{
	_scale=MAX(MIN(scale, 1e3), 1e-3);	// limit
	[self updateDimensions];	// trigger update of bounds
}

- (void) setScaleForRect:(NSRect) area;
{ // scale so that area fills the clip view
	NSClipView *clipView;
	if(!NSIsEmptyRect(area) && (clipView=[[self enclosingScrollView] contentView]))
		{
		NSRect frame=[clipView frame];	// NSClipView frame
		[self setScale:MIN(NSWidth(frame)/NSWidth(area), NSHeight(frame)/NSHeight(area))];
		}
}

- (int) rotationAngle; { return _rotationAngle; }

- (void) setRotationAngle:(int) angle;
{
	_rotationAngle = ((angle % 360) + 360) % 360;	// also works for negative values
	[self updateDimensions];	// trigger update of bounds
}

/* menu actions */

- (IBAction) center:(id) sender;
{ // center the main view (independently of scaling)
	NSRect area=[self contentFrame];
	[self setCenter:NSMakePoint(NSMidX(area), NSMidY(area))];
}

- (IBAction) zoomFit:(id) sender;
{ // zoom content view to fit clip view
	NSRect area=[self contentFrame];
	[self setScaleForRect:area];
}

- (IBAction) zoomUnity:(id) sender;
{ // zoom content view to 100% i.e. 1/72 inch scale
	[self setScale:1.0];
}

- (IBAction) zoomIn:(id) sender;
{
	[self setScale:sqrt(2.0)*[self scale]];
}

- (IBAction) zoomOut:(id) sender;
{
	[self setScale:sqrt(0.5)*[self scale]];
}

- (IBAction) rotateImageLeft:(id) sender;
{
	[self setRotationAngle:[self rotationAngle]+10];
}

- (IBAction) rotateImageRight:(id) sender;
{
	[self setRotationAngle:[self rotationAngle]-10];
}

- (IBAction) rotateImageLeft90:(id) sender;
{
	[self setRotationAngle:[self rotationAngle]+90];
}

- (IBAction) rotateImageRight90:(id) sender;
{
	[self setRotationAngle:[self rotationAngle]-90];
}

- (IBAction) rotateImageUpright:(id) sender;
{
	[self setRotationAngle:0];
}

- (IBAction) flipHorizontal:(id) sender;
{
	[self setRotationAngle:[self rotationAngle]-180];
	_isHorizontallyFlipped=!_isHorizontallyFlipped;
	[self flipVertical:sender];
}

- (IBAction) flipVertical:(id) sender;
{
	[self setFlipped:![self isFlipped]];
}

- (IBAction) unflip:(id) sender;
{
	if(_isHorizontallyFlipped)
		[self flipHorizontal:sender];	// make it an even number of horizontal flips
	[self setFlipped:NO];
}

- (void) scrollWheel:(NSEvent *) event;
{
	if([event modifierFlags] & NSAlternateKeyMask)
		{ // translate scrollwheel up/down into zoom
		[self setScale:pow(1.2, [event scrollingDeltaY])*[self scale]];
			// rotate left/right by [event scrollingDeltaX]?
		}
	else
		[super scrollWheel:event];	// handle by ClipView/ScrollView (for panning)
}

@end
