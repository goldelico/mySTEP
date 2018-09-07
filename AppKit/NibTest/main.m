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

#if 1	// debugging

@implementation NSApplication (NSImage)

- (NSImage *) img
{
#if 0
	NSImage *img=[NSImage imageNamed:@"NSToolbarShowColors"];
#else
	NSImage *img=[NSImage imageNamed:@"NSToolbarShowFonts"];
#endif
#if 1 // currently, unflipped drawing works, flipped fails
	[img setFlipped:YES];
#endif
#if 1	// test drawing/copying into other pixmap and not to screen
	NSImage *copy=[[NSImage alloc] initWithSize:[img size]];
	[copy lockFocus];
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

- (void) finishLaunching
{ // override NIB loading
	NSWindow *w=[[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 400, 200) styleMask:NSTitledWindowMask backing:NSBackingStoreBuffered defer:NO];
	NSImageView *iv=[[NSImageView alloc] initWithFrame:NSMakeRect(50, 50, 100, 100)];
	// set other image attributes
	[iv setImage:[self img]];
	[iv setImageScaling:NSImageScaleNone];
	// set other image view attributes, e.g.  resizing, frame, bounds, rotation
	[w setContentView:iv];
	[w makeKeyAndOrderFront:nil];
}

@end

#endif
