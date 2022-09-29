//
//  main.m
//  ElectroniCAD
//
//  Created by H. Nikolaus Schaller on 20.11.09.
//  Copyright Golden Delicious Computers GmbH&Co. KG 2009 . All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	/* install catch-all exception handler like described here: https://www.cocoawithlove.com/2010/05/handling-unhandled-exceptions-and.html */
	return NSApplicationMain(argc, (const char **) argv);
}

@interface DemoImageView : NSImageView
@end

@implementation DemoImageView

#if 1	// bei 1 verkleinert sich das Bild beim drehen !?!
- (void) drawRect:(NSRect) rect
{
#if 1	// draw a box for the bounds rect
	[[NSColor yellowColor] set];
	[NSBezierPath fillRect:NSMakeRect(10.0, 10.0, 10.0, 10.0)];
#endif
	[super drawRect:rect];
}
#endif

@end

@interface DemoView : NSView
@end

@implementation DemoView

#if 0
- (BOOL) wantsDefaultClipping;
{
	return YES;
}
#endif

- (void) drawRect:(NSRect) rect
{
#if 1	// draw a box for the bounds rect
	[[NSColor redColor] set];
	[NSBezierPath fillRect:[self bounds]];
	[[NSColor greenColor] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeRect:NSInsetRect([self bounds], 1.0, 1.0)];
//	NSLog(@"rect=%@ bounds=%@ frame=%@", NSStringFromRect(rect), NSStringFromRect([self bounds]), NSStringFromRect([self frame]));
//	NSLog(@"Image   bounds=%@ frame=%@", NSStringFromRect([[[self subviews] lastObject] bounds]), NSStringFromRect([[[self subviews] lastObject] frame]));
#endif
#if 1	// draw a box for the redraw rect
	[[NSColor blueColor] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeRect:NSInsetRect(rect, 3.0, 3.0)];
#endif
#if 1	// draw a line across
	[[NSColor greenColor] set];
	[NSBezierPath setDefaultLineWidth:2.0];
	[NSBezierPath strokeLineFromPoint:[self bounds].origin toPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds]))];
#endif
#if 1
	// verify scaling to screen during rotation
	// see https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CocoaViewsGuide/WorkingWithAViewHierarchy/WorkingWithAViewHierarchy.html#//apple_ref/doc/uid/TP40002978-CH4-SW25
	NSPoint p1, p2;
	p1=[[self window] convertBaseToScreen:[self convertPoint:[self bounds].origin toView:nil]];
	p2=[[self window] convertBaseToScreen:[self convertPoint:NSMakePoint(NSMaxX([self bounds]), NSMaxY([self bounds])) toView:nil]];
//	NSLog(@"p1=%@ p2=%@", NSStringFromPoint(p1), NSStringFromPoint(p2));
//	NSLog(@"length=%lf", sqrt((p1.x-p2.x)*(p1.x-p2.x)+(p1.y-p2.y)*(p1.y-p2.y)));
#endif
}

@end
