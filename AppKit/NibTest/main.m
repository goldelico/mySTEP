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

#if 0
@implementation NSImageView (override)
- (BOOL) isFlipped { return YES; }
@end
#endif

@interface FlippableView : NSView
{
	BOOL _isFlipped;
}
- (void) setFlipped:(BOOL) flag;
@end

@interface ImageView : FlippableView
{
	NSImage *img;
}
@end

@implementation FlippableView

- (BOOL) isFlipped; { return _isFlipped; }
- (void) setFlipped:(BOOL) flag; { _isFlipped=flag; }

@end

@implementation ImageView

- (void) setImage:(NSImage *) i { [img autorelease]; img=[i retain]; }

- (void) drawRect:(NSRect) Rect
{
	NSRect inRect=[self bounds];
	NSRect fromRect=NSZeroRect;
	[[NSColor redColor] set];
	NSRectFill([self bounds]);	// prefill background

#if 1	// image rotation
	{
	NSAffineTransform *atm=[NSAffineTransform transform];
	/* translation is NOT ignored by compositeToPoint! */
	[atm translateXBy:10 yBy:-30];
	[atm rotateByDegrees:15.0];
	[atm scaleBy:1.5];
	[atm concat];	// apply rotation before drawing
	}
#endif

	/* flipping */
	[img setFlipped:NO];

	//	[img setFlipped:YES];

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

#if 0
	inRect=NSMakeRect(10, 10, 70, 70);
	CGFloat scale=0.3;
	fromRect=NSMakeRect(0, 0, scale*[img size].width, scale*[img size].height);

#if 0
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSMakeRect(80, 140, 300, 300);

#if 1
	inRect=NSMakeRect(10, 10, 70, 70);
	fromRect=NSMakeRect(180, 240, 30, 30);
#endif
#endif
#endif
#endif
#endif

#if 0
	/* image rep drawing takes care of CTM scale and rotation and pixel size, but does not change size of rep! */
	// it takes the current compositing operation
	// note: Cocoa uses a rotated scan/clip rect differently from what mySTEP backend does!
	// so the result for transparent parts is different
	NSImageRep *rep=[[img representations] objectAtIndex:0];
	//	[rep drawAtPoint:inRect.origin];
	[rep drawInRect:inRect];
	return;
#endif

	/* drawInRect takes care of CTM scale and rotation */
	// [img drawInRect:inRect]; return;
	[img drawInRect:inRect fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0]; return;
	/* drawAtPoint takes care of CTM scale and rotation */
	// [img drawAtPoint:inRect.origin fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0]; return;
	/* composite ignores any scale and rotation, takes img isFlipped */
	// [img compositeToPoint:inRect.origin fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0]; return;
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
	ISFLIPPED(NSTableView);
	ISFLIPPED(NSTableHeaderView);
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

#if 1 // flipped drawing
	[img setFlipped:NO];
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
	iv=[[ImageView alloc] initWithFrame:NSMakeRect(50, 10, 100, 100)];

#if 1
	[(ImageView *) iv setFlipped:NO];	// flips the image! but does not move it
#endif

#else
	iv=[[NSImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
	[(NSImageView *) iv setImageScaling:NSImageScaleNone];
	[(NSImageView *) iv setImageFrameStyle:NSImageFrameGrayBezel];
#if 1
	[(NSImageView *) iv setImageScaling:NSImageScaleProportionallyUpOrDown];
#endif
#endif

	[w setTitle:@"NSImage Drawing Test"];
	[(NSImageView *) iv setImage:[self img]];

#if 1
	FlippableView *fv=[[FlippableView alloc] initWithFrame:[iv frame]];
	[iv setFrameOrigin:NSZeroPoint];
	[fv addSubview:iv];	// embed in another flipped view
	[fv setFlipped:YES];	// has no effect on Cocoa!
							// [fv autorelease];	// don't autorelease or we will end in some SEGFAULT on Cocoa ([NSView viewWillDraw])
	iv=fv;
#endif


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
