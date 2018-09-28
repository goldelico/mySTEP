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

#if 0	// for debugging of image drawing

@implementation NSBundle (NSNibLoading)

+ (NSImage *) img
{
	NSString *path;
#if 0
	path=@"/usr/local/QuantumSTEP/System/Sources/Frameworks/AppKit/Images/NSToolbarShowColors.icns";
#else
	path=@"/usr/local/QuantumSTEP/System/Sources/Frameworks/AppKit/Images/NSToolbarShowFonts.icns";
#endif
	NSImage *img=[[[NSImage alloc] initWithContentsOfFile:path] autorelease];
	if(!img)
		{
		NSLog(@"image not found!");
		return nil;
		}

#if 0 // flipped drawing
	[img setFlipped:YES];
#endif

#if 1	// test drawing/copying into other pixmap and not to screen
	{
	NSImage *copy=[[NSImage alloc] initWithSize:[img size]];
	NSRect rect=(NSRect) { NSZeroPoint, [copy size] };
	[copy lockFocus];
#if 1	// image rotation
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
	NSImageView *iv=[[NSImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
	BOOL fl=[iv isFlipped];
	NSLog(@"fl=%d", fl);

	[w setTitle:@"NSImage Drawing Test"];
	[iv setImage:[self img]];
	[iv setImageScaling:NSImageScaleNone];
#if 1
	[iv setImageScaling:NSImageScaleProportionallyUpOrDown];
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
