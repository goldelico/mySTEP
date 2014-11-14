//
//  myView.m
//  myTest
//
//  Created by Dr. H. Nikolaus Schaller on Mon Jan 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "myView.h"

@implementation NSView (hierarchy)

- (NSString *) _subtreeDescription
{
	NSMutableString *s=[NSMutableString stringWithString:[self description]];
	NSEnumerator *e=[[self subviews] objectEnumerator];
	NSView *v;
	while((v=[e nextObject]))
		{ // prefix all lines with @"  "
		NSString *sub=[v _subtreeDescription];
		NSArray *suba=[sub componentsSeparatedByString:@"\n"];
		[s appendFormat:@"\n  %@", [suba componentsJoinedByString:@"\n  "]];
		}
	return s;
}

@end

@interface NSView (subview)
- (NSString *) _subtreeDescription;
- (NSAffineTransform *) _base2bounds;
@end

@implementation NSTabView (hierarchy)

- (void) awakeFromNib;
{
	[self selectTabViewItemAtIndex:0];
	NSLog(@"awakeFromNib: %@", [self _subtreeDescription]);
	[self selectTabViewItemAtIndex:1];	// switch
	NSLog(@"awakeFromNib: %@", [self _subtreeDescription]);
}

@end

@interface NSGraphicsContext (NSPrivate)
- (void) _setShape:(NSBezierPath *) path;
@end

static NSImage *image;

@implementation myViewFlipped

- (BOOL) isFlipped; { return YES; }

@end

@implementation myView

- (BOOL) isFlipped; { return NO; }

- (NSAffineTransform *) _base2bounds
{
	return [super _base2bounds];
}

- (void) drawRect:(NSRect)aRect
{
	NSRect r;
	NSPoint pnt;
	NSAffineTransform *atm;
	NSLog(@"myView drawRect:%@", NSStringFromRect(aRect));
	NSLog(@" flipped=%d", [self isFlipped]);
	NSLog(@" graphicscontext=%@", [NSGraphicsContext currentContext]);
	NSLog(@" attribs=%@", [[NSGraphicsContext currentContext] attributes]);
	r=NSMakeRect(0.0, 0.0, 10.0, 10.0);	// a small rect
	NSRectFill(r); // draw specified rect in default color
	[[NSColor greenColor] set];
	NSFrameRect(aRect); // draw full rect in green color
	[[NSColor redColor] set];
	r=NSMakeRect(30.0, 20.0, 100.0, 60.0);
	NSFrameRect(r); // draw specified rect in red
	// use default attributes
	[@"Test 0123456789012345 abcdefghij\n\thällö" drawInRect:r withAttributes:[NSDictionary dictionary]];
	NSFrameRect(NSMakeRect(0.0, 10.0, 170.0, 1.0)); // draw line
	[@"Test-gj" drawAtPoint:NSMakePoint(70.0, 10.0) withAttributes:[NSDictionary dictionary]];
	
	if(!image)
		image=[[NSImage imageNamed:@"Lion"] retain];
	NSLog(@"image size=%@", NSStringFromSize([image size]));
	[image setFlipped:![image isFlipped]];	// flip image
	[image compositeToPoint:NSMakePoint(50.0, 130.0) operation:NSCompositeCopy];	// 1
	[image setFlipped:![image isFlipped]];
	[image setSize:NSMakeSize(32.0, 32.0)];
	NSLog(@"image size=%@", NSStringFromSize([image size]));
	[image compositeToPoint:NSMakePoint(50.0, 180.0) operation:NSCompositeCopy];	// 2
	[image recache];
	[image compositeToPoint:NSMakePoint(100.0, 180.0) operation:NSCompositeCopy];	// 3
	[image setScalesWhenResized:YES];
	[image compositeToPoint:NSMakePoint(50.0, 230.0) operation:NSCompositeCopy];	// 4
	[image recache];
	[image drawInRect:r=NSMakeRect(150.0, 210.0, 40.0, 40.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.5];	// 5 this one should scale
	pnt=r.origin;
	[[NSColor redColor] set];
	[NSBezierPath fillRect:NSMakeRect(pnt.x-2.0, pnt.y-2.0, 4.0, 4.0)];	// draw a marker
	[image drawInRect:r=NSMakeRect(150.0, 150.0, 40.0, 40.0) fromRect:NSMakeRect(10.0, 10.0, 20.0, 20.0) operation:NSCompositeSourceOver fraction:1.0];	// 5b this one should scale and show transparence
	pnt=r.origin;
	[NSBezierPath fillRect:NSMakeRect(pnt.x-2.0, pnt.y-2.0, 4.0, 4.0)];	// draw a marker
	atm=[NSAffineTransform transform];
	[atm rotateByDegrees:angle];
	NSLog(@"atm for rotate = %@", atm);
	[atm concat];
	atm=[NSAffineTransform transform];
	[atm translateXBy:10.0 yBy:10.0];
	[atm rotateByDegrees:angle];
	NSLog(@"atm for translate&rotate = %@", atm);
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:NSMakeRect(150.0, 100.0, 30.0, 30.0)];	// draw rotated rectangle
	[image compositeToPoint:pnt=NSMakePoint(100.0, 230.0) operation:NSCompositeCopy];		// 6 note: this operation does not rotate or scale the image but only the origin
	[NSBezierPath fillRect:NSMakeRect(pnt.x-2.0, pnt.y-2.0, 4.0, 4.0)];	// draw a marker
	[image drawAtPoint:pnt=NSMakePoint(150.0, 230.0) fromRect:NSZeroRect operation:NSCompositeCopy fraction:0.5];	// 7 this one rotates by 5 degrees
	[NSBezierPath fillRect:NSMakeRect(pnt.x-2.0, pnt.y-2.0, 4.0, 4.0)];	// draw a marker
	r=NSMakeRect(150.0, 20.0, 100.0, 60.0);
	[@"Rotated Text" drawInRect:r withAttributes:nil];
	[@"Red Text" drawAtPoint:NSMakePoint(150.0, 40.0) withAttributes:[NSDictionary dictionaryWithObject:[NSColor redColor]
																								 forKey:NSForegroundColorAttributeName]];
	// CHECKME: what about rotated view transformation? Does convertRect return a converted bounding box???
}

- (void) animation;
{
	NSRect rect;
	if(![[self window] isVisible])
		return;	// end animation
	angle+=10.0;
	NSLog(@"animation: angle=%f", angle);
	[self setNeedsDisplay:YES];
	[boundsRotationView setBoundsRotation:angle];		// rotates around frame center (!)
	[boundsRotationView setNeedsDisplay:YES];
	[frameRotationView setFrameRotation:angle];			// rotates around frame.origin
	[frameRotationView setNeedsDisplay:YES];
	rect=[boundsChangeView bounds];
	rect.origin.y = 100.0+100.0*sin(angle*M_PI/180.0);	// move up and down
	[boundsChangeView setBounds:rect];
	[boundsChangeView setNeedsDisplay:YES];
	[self performSelector:_cmd withObject:nil afterDelay:0.1];
}

- (void) mouseDown: (NSEvent*) event;
{
	NSLog(@"mouseDown: %@", event);
	NSLog(@"focus view: %@", [NSView focusView]);	// should be nil!
	NSLog(@"graphics context: %@", [NSGraphicsContext currentContext]);
#if 0
	{
	NSRect f;
	NSBezierPath *bp;
	NSLog(@"mouseDown: %@", event);
	NSLog(@"focus view: %@", [NSView focusView]);	// should be nil!
	NSLog(@"graphics context: %@", [NSGraphicsContext currentContext]);
	f=[self frame];	// we define the frame...
	bp=[NSBezierPath bezierPathWithOvalInRect:f];
	[self lockFocus];
	[[NSGraphicsContext currentContext] _setShape:bp];	// this should make the window oval...
	[self unlockFocus];
	}
#endif
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	// cancel any still running timer
	angle=-5.0;	// restart
	[self animation];
}

#if 0
NSString *flags(unsigned char *addr)
{
	NSString *str=@"";
	int i;
	for(i=64-8; i<64+8; i++)
		{
		str=[str stringByAppendingFormat:@"%02x", addr[i]];
		}
	return str;
}
#endif

- (void) awakeFromNib;
{
	NSView *cv;
	NSView *v;
	NSRect r;
	NSLog(@"[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
	NSLog(@"window frame %@", NSStringFromRect([[self window] frame]));
	cv=[[self window] contentView];
	NSLog(@"view frame %@", NSStringFromRect([cv frame]));
	NSLog(@"view bounds %@", NSStringFromRect([cv bounds]));
//	[cv scaleUnitSquareToSize:NSMakeSize(0.5, 0.5)];	mySTEP does not handle scaling
	[cv setNeedsDisplay:YES];
	NSLog(@"view frame %@", NSStringFromRect([cv frame]));
	NSLog(@"view bounds %@", NSStringFromRect([cv bounds]));
	image=[[NSImage imageNamed:@"Default"] copy];
	NSLog(@"Default image=%@", image);
	NSLog(@"Default size=%@", NSStringFromSize([image size]));
	[[self window] makeKeyAndOrderFront:nil];
	v=nil;
	r=NSMakeRect(20, 30, 40, 50);
	NSLog(@"convertPoint:%@ fromView:%@ -> %@", NSStringFromPoint(r.origin), v, NSStringFromPoint([self convertPoint:r.origin fromView:v]));
	NSLog(@"convertPoint:%@ toView:%@ -> %@", NSStringFromPoint(r.origin), v, NSStringFromPoint([self convertPoint:r.origin toView:v]));
	NSLog(@"convertSize:%@ fromView:%@ -> %@", NSStringFromSize(r.size), v, NSStringFromSize([self convertSize:r.size fromView:v]));
	NSLog(@"convertSize:%@ toView:%@ -> %@", NSStringFromSize(r.size), v, NSStringFromSize([self convertSize:r.size toView:v]));
	NSLog(@"convertRect:%@ fromView:%@ -> %@", NSStringFromRect(r), v, NSStringFromRect([self convertRect:r fromView:v]));
	NSLog(@"convertRect:%@ toView:%@ -> %@", NSStringFromRect(r), v, NSStringFromRect([self convertRect:r toView:v]));
#if 0
	{
		int i=NSNoImage;
	NSButtonCell *bc=[[NSButtonCell alloc] init];
	NSLog(@"\n_CFlags=%@", flags(bc));
	for(i=0; i<=NSImageOverlaps; i++)
		{
		[bc setImagePosition:i];
		NSLog(@"imagePosition=%d\n_CFlags=%@", [bc imagePosition], flags(bc));
		}
	}
#endif
	angle=5.0;
}

@end

/* Findings:

NSString:
drawInRect always starts at the top left edge of the box
The horizontal bar of the letter T starts approx. 2-3 pixels below
The left edge touches the surrounding box
Text wraps to next line at blank characters - overlong lines are cut off

drawAtPoint either draws below (if flipped) or above (if not flipped) the specified point
If drawing is above, the descenders are touching the origin
If drawing is below, it starts approx. 2-3 pixels below

*/

@implementation CalcButton
@end

@implementation SilverBox
@end

@implementation myTextView

- (void)drawInsertionPointInRect:(NSRect)aRect color:(NSColor *)aColor turnedOn:(BOOL)flag
{
	NSLog(@"rect %@ flag %d", NSStringFromRect(aRect), flag);
	[super drawInsertionPointInRect:aRect color:aColor turnedOn:flag];
}

@end
