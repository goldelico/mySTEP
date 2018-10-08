//
//  main.h
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

int main(int argc, const char *argv[])
{
	NSLog(@"started");
	return NSApplicationMain(argc, argv);
}

#if 1	// for debugging of image drawing

#if 0
@implementation NSImage (override)

- (BOOL) drawRepresentation:(NSImageRep*)imageRep inRect:(NSRect)rect
{
	return NO;
}
- (void) drawInRect:(NSRect)dest
		   fromRect:(NSRect)src
		  operation:(NSCompositingOperation)op
		   fraction:(CGFloat)fraction
{
	
}
@end
#endif

@interface ImageView : NSView
{
	NSImage *img;
}
@end

@implementation ImageView

#if 0
/* if set, [self bounds].origin is at the top of the view and the image is drawn above - unless we translate */
- (BOOL) isFlipped; { return YES; }
#endif

- (void) setImage:(NSImage *) i { [img autorelease]; img=[i retain]; }

- (void) drawRect:(NSRect) Rect
{
	NSRect inRect=[self bounds];
	NSRect fromRect=NSZeroRect;
	[[NSColor redColor] set];
	NSRectFill([self bounds]);	// prefill background

#if 0	// image rotation
	{
	NSAffineTransform *atm=[NSAffineTransform transform];
	/* translation is NOT ignored by compositeToPoint! */
	[atm translateXBy:30 yBy:30];
	[atm rotateByDegrees:15.0];
	[atm scaleBy:1.5];
	[atm concat];	// apply rotation before drawing
	}
#endif

	/* flipping */
	[img setFlipped:NO];

	[img setFlipped:YES];

	/* setSize wird auch bei composite berücksichtigt! */
	//	[img setSize:NSMakeSize(50, 50)];
	// [img setSize:NSMakeSize(50, 50)];

	/* source-Rect wird bei composite berücksichtigt und verschiebt/clippt das Ergebnis */
	fromRect=NSMakeRect(20.0, 10.0, 50.0, 50.0);
	//rect=NSMakeRect(50.0, 50.0, [img size].width, [img size].height);
	//rect=NSMakeRect(15.0, 15.0, 200.0, 200.0);

#if 1
	inRect=NSMakeRect(10, 10, 50, 50);	// bei img setFlipped:NO ok, bei YES verschoben!
	fromRect=NSZeroRect;

#if 1
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSZeroRect;

#if 1
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSMakeRect(0, 0, 300, 300);

#if 1
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSMakeRect(40, 70, 300, 300);

#if 1
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSMakeRect(180, 240, 30, 30);
#endif
#endif
#endif
#endif
#endif

	/* drawInRect takes care of CTM scale and rotation */
	// [img drawInRect:inRect];
	[img drawInRect:inRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
	/* drawAtPoint takes care of CTM scale and rotation */
	// [img drawAtPoint:inRect.origin fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
	/* composite ignores any scale and rotation, takes img isFlipped */
	// [img compositeToPoint:inRect.origin fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
}
@end

@implementation NSBundle (NSNibLoading)

+ (NSImage *) img
{
#if 1
#define ISFLIPPED(C) NSLog(@"%@: isFlipped=%d", @ #C , [[[C alloc] initWithFrame:NSMakeRect(0,0,100,100)] isFlipped])
	ISFLIPPED(NSImageView);
	ISFLIPPED(NSButton);
	ISFLIPPED(NSControl);
	ISFLIPPED(NSMatrix);
	ISFLIPPED(NSScrollView);
	ISFLIPPED(NSClipView);
	ISFLIPPED(NSView);
	ISFLIPPED(NSScroller);
	ISFLIPPED(NSSplitView);
	ISFLIPPED(NSText);
	ISFLIPPED(NSTextView);
	ISFLIPPED(NSForm);
#endif

	NSString *path;
	path=@"";
	path=@"/Users/hns/Documents/Projects/QuantumSTEP/System/Sources/Frameworks/AppKit/NibTest/Lion.jpg";
//	path=@"/Users/hns/Documents/Projects/QuantumSTEP/System/Sources/MenuExtras/Icons/display.png";
//	path=@"/Users/hns/Documents/Projects/QuantumSTEP/System/Sources/Frameworks/AppKit/NibTest/1bK.png";
//	path=@"/Users/hns/Documents/Projects/QuantumSTEP/System/Sources/Frameworks/AppKit/NibTest/rss.gif";
//	path=@"/Users/hns/Documents/Projects/QuantumSTEP/System/Sources/OpenSource/GPL/MokoMaze/src/pics/qtmaze/ball.png";	/* different DPI */
//	path=@"/usr/local/QuantumSTEP/System/Sources/Frameworks/AppKit/Images/NSToolbarShowColors.icns";
//	path=@"/usr/local/QuantumSTEP/System/Sources/Frameworks/AppKit/Images/NSToolbarShowFonts.icns";
	NSImage *img=[[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	if(!img)
		{
		NSLog(@"image not found!");
		return nil;
		}

#if 0 // flipped drawing
	[img setFlipped:YES];
#endif

#if 0	// test drawing/copying into other pixmap and not to screen
	{
	NSImage *copy=[[NSImage alloc] initWithSize:[img size]];
	NSRect rect=(NSRect) { NSZeroPoint, [copy size] };
	[copy lockFocus];
#if 0	// image rotation
	{
		NSAffineTransform *atm=[NSAffineTransform transform];
		[atm rotateByDegrees:-15.0];
		[atm concat];	// apply rotation before drawing
	}
#endif
	[[NSColor redColor] set];
	NSRectFill(rect);	// prefill background
	[img drawInRect:rect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[copy unlockFocus];
	img=[copy autorelease];
	}
#endif

#if 0	// copy a second time
	{
	NSImage *copy2=[[NSImage alloc] initWithSize:[img size]];
	[copy2 lockFocus];
	[img drawAtPoint:NSZeroPoint fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[copy2 unlockFocus];
	img=[copy2 autorelease];
	}
#endif

	return img;
}

// substitute nib loading

+ (BOOL) loadNibNamed:(NSString *) name owner:(id) owner
{
	NSWindow *w=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 250, 200) styleMask:(NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask) backing:NSBackingStoreBuffered defer:NO];
	NSView *iv;
#if 1
	iv=[[ImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
#else
	iv=[[NSImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
	[iv setImageScaling:NSImageScaleNone];
	[iv setImageFrameStyle:NSImageFrameGrayBezel];
#if 1
	[iv setImageScaling:NSImageScaleProportionallyUpOrDown];
#endif
#endif
	BOOL fl=[iv isFlipped];
	NSLog(@"fl=%d", fl);

	[w setTitle:@"NSImage Drawing Test"];
	[iv setImage:[self img]];
#if 0
	[iv setFrameRotation:10.0];
#endif
#if 0
	[iv setBoundsRotation:10.0];
	NSLog(@"%@", NSStringFromRect([iv frame]));
#endif
#if 1	// keep frame size
	[[w contentView] addSubview:iv];
#else	// adjust to window frame
	[w setContentView:iv];
#endif
	NSLog(@"%@", NSStringFromRect([iv frame]));
	[iv release];
	[w makeKeyAndOrderFront:nil];
	// [w autorelease];	// don't release or it will be closed...!
	return YES;
}

@end

#endif
