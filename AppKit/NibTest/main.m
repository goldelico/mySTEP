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

#if 0	// debugging

@implementation NSBundle (NSNibLoading)

+ (NSImage *) img
{
#if 0
	NSImage *img=[NSImage imageNamed:@"NSToolbarShowColors"];
#else
	NSImage *img=[NSImage imageNamed:@"NSToolbarShowFonts"];
#endif
#if 0 // currently, flipped drawing is reversed
	[img setFlipped:YES];
#endif
#if 1	// test drawing/copying into other pixmap and not to screen
	NSImage *copy=[[NSImage alloc] initWithSize:[img size]];
	[copy lockFocus];
#if 1
	NSAffineTransform *atm=[NSAffineTransform transform];
	[atm rotateByDegrees:-10.0];
	[atm concat];	// apply rotation
#endif
	[img drawInRect:NSZeroRect fromRect:NSZeroRect operation:NSCompositeCopy fraction:1.0];
	[copy unlockFocus];
#if 0
	NSImage *copy2=[[NSImage alloc] initWithSize:[copy size]];
	[copy2 lockFocus];
	[copy drawInRect:NSZeroRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	[copy2 unlockFocus];
	return copy2;
#endif
	return copy;
#endif
	return img;
}

// substitute nib loading

+ (BOOL) loadNibNamed:(NSString *) name owner:(id) owner
{
	NSWindow *w=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 400, 200) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	NSImageView *iv=[[NSImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
	[w setTitle:@"NSImage Drawing Test"];
	// set other image attributes
	[iv setImage:[self img]];
	[iv setImageScaling:NSImageScaleNone];
	// set other image view attributes, e.g.  resizing, frame, bounds, rotation
	[w setContentView:iv];
	[w makeKeyAndOrderFront:nil];
	return YES;
}

@end

#endif
