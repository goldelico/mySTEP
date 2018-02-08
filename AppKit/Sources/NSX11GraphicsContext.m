/*
 NSX11GraphicsContext.m
 mySTEP

 X11 Backend Graphics Context class.  Conceptually, instances of
 this subclass encapsulate a connection to an X display (X server).

 Copyright (C) 1998 Free Software Foundation, Inc.

 Author:	Felipe A. Rodriguez <far@pcmagic.net>
 Date:		November 1998

 Author:	H. N. Schaller <hns@computer.org>
 Date:		Jan 2006 - completely reworked so that it has more or less nothing in common with GNUstep and mGstep any more

 Useful Manuals:
 http://tronche.com/gui/x/xlib											Xlib - basic X11 calls
 http://freetype.sourceforge.net/freetype2/docs/reference/ft2-toc.html	libFreetype2 - API
 http://freetype.sourceforge.net/freetype2/docs/tutorial/step1.html		tutorial
 (http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xft.3.html		Xft - freetype glue)
 (http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xrandr.3.html	XResize - rotate extension)
 http://netmirror.org/mirror/xfree86.org/4.4.0/doc/HTML/Xrender.3.html	XRender - antialiased, alpha, subpixel rendering

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

/*
 Note when dealing with X11:
 - if we need to check that an object is not rotated, check that ctm transformStruct.m12 and .m21 both are 0.0
 - we can't handle any rotation for text drawing (yet)
 - we can't rotatate windows by angles not multiples of 90 degrees (well we could do that in combination with setShape)
 - note that X11 coordinates are flipped. This is taken into account by the _screen2X11 CTM.
 - But: for NSSizes you have to use -height because of a flipping CTM
 - finally, drawing into a window is relative to the screen origin of the window
 */

#import "NSX11GraphicsContext.h"

// load full headers (to expand @class forward references)

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"
#import "NSApplication.h"
#import "NSAttributedString.h"
#import "NSBezierPath.h"
#import "NSCachedImageRep.h"
#import "NSColor.h"
#import "NSCursor.h"
#import "NSFont.h"
#import "NSGraphics.h"
#import "NSGraphicsContext.h"
#import "NSImage.h"
#import "NSScreen.h"
#import "NSWindow.h"
#import "NSPasteboard.h"

#define USE_XRENDER 0
#define USE_XRENDER_GLYPHSTORE 0

#if 1	// all windows are borderless, i.e. the frontend draws the title bar and manages windows directly
#define WINDOW_MANAGER_TITLE_HEIGHT 0
#else
#define WINDOW_MANAGER_TITLE_HEIGHT 23	// number of pixels added by window manager - the content view is moved down by that amount
#endif

static BOOL _doubleBufferering=YES;

#pragma mark Class variables

static Display *_display;		// we can currently manage only one Display - but multiple Screens
static BOOL _hasRender;			// display has XRender extension

static Atom _stateAtom;
static Atom _protocolsAtom;
static Atom _deleteWindowAtom;
static Atom _windowDecorAtom;

static NSArray *_XRunloopModes;	// runloop modes to handle X11 events

unsigned int __modFlags = 0;		// current global modifier flags - updated every keyDown/keyUp event

static NSMapTable *__WindowNumToNSWindow = NULL;	// map Window to NSWindow

static unsigned int xKeyModifierFlags(unsigned int state);
static unsigned short xKeyCode(XEvent *xEvent, KeySym keysym, unsigned int *eventModFlags);
// extern void xHandleSelectionRequest(XSelectionRequestEvent *xe);

#pragma mark GraphicsPipeline

// A filter pipeline has some resemblance to the concept of Core Image but runs completely on the CPU

struct RGBA8
{ // 8 bit per channel RGBA
	unsigned char R, G, B, A;
};

struct pipeline
{ // a filter chain element
	struct pipeline *source;					// filter source (could also be an id)
	struct RGBA8 (*method)(float x, float y);	// get pixel after processing
};

@interface _NSGraphicsPipeline : NSObject
{
	id source;		// source image or _NSGraphicsPipeline subclass
	id parameter;	// a second parameter (other image source, NSAffineTransform etc.)
@public	// allows us to use (pointer->method)(x, y)
	struct RGBA8 (*method)(float x, float y);	// get pixel after processing
}
@end

/*
 basically, we need the following filter pipeline nodes:
 - sample into RGBA8 (from a given bitmap or XImage)
 - transform (rotate/scale/flip) by CTM
 - clip

 - composite (with a second source)
 - interpolate (with adjacent pixels)
 - convert RGBA8 to RGB24 or RGB16
 - store into XImage
 */

@implementation _NSX11GraphicsContext

#pragma mark BitmapDrawing

static unsigned char tab5[32];	// convert 5bit color value to 8 bit (using full range 0..255)
static unsigned char tab6[64];

static void inittab565(void)
{ // initialize color translation table
	int i;
	for(i=0; i<=31; i++)
		tab5[i]=(i*255+31/2)/31;
	for(i=0; i<=63; i++)
		tab6[i]=(i*255+63/2)/63;
}

// this is the XImage sampler

inline static void XSetRGBA8(XImage *img, int x, int y, struct RGBA8 *dest)
{ // set RGBA8
  // FIXME: depending on color space we should apply a calibration curves
	// we should use a table driven approach (faster)
#if 0
	if(dest->A != 255)
		{ // we are drawing a transparent result
			struct RGBA8 src=XGetPixel(img, x, y);
			// blend
		}
#endif
	switch(img->depth) {
		case 24:
			XPutPixel(img, x, y, (dest->R<<16)+(dest->G<<8)+(dest->B<<0));
			break;
		case 16:
			XPutPixel(img, x, y, ((dest->R & 0x00f8)<<8)+((dest->G & 0x00fc)<<3)+((dest->B & 0x00f8)>>3));	// 5/6/5 bit
			break;
		default:
			;
	}
}

inline static struct RGBA8 Pixel2RGBA8(NSInteger depth, NSUInteger pixel)
{ // get RGBA8
	struct RGBA8 dest;
	// apply calibration curves/tables - we can read the tables from a file on the first call!
	switch(depth) {
		case 24:
		{
		dest.R=(pixel>>16);
		dest.G=(pixel>>8);
		dest.B=(pixel>>0);
		break;
		}
		case 16:
		{ // scale 0..31 to 0..255
			dest.R=tab5[(pixel>>11)&0x1f];	// highest 5 bit
			dest.G=tab6[(pixel>>5)&0x3f];	// middle 6 bit
			dest.B=tab5[pixel&0x1f];		// lowest 5 bit
		}
	}
	dest.A=255;
	return dest;
}

inline static struct RGBA8 XGetRGBA8(XImage *img, int x, int y)
{ // get RGBA8
	return Pixel2RGBA8(img->depth, XGetPixel(img, x, y));
}

static inline void composite(NSCompositingOperation compositingOperation, struct RGBA8 *src, struct RGBA8 *dest)
{
	// FIXME: (255*255>>8) => 254???
	// FIXME: using Highlight etc. must be limited to pixel value 0/255
	// we must divide by 255 and not 256 - or adjust F&G scaling
	// check if these formulas are correct if we assume premultiplied
	unsigned short F, G;
	switch(compositingOperation) { // based on http://www.cs.wisc.edu/~schenney/courses/cs559-s2001/lectures/lecture-8-online.ppt
			// dest=F*src+G*dest;
		case NSCompositeClear:
			// F=0, G=0;
			dest->R=0;
			dest->G=0;
			dest->B=0;
			dest->A=0;
			break;
		default:
		case NSCompositeCopy:
			// F=255, G=0;
			*dest=*src;
			break;
		case NSCompositeHighlight:			// deprecated and mapped to NSCompositeSourceOver
		case NSCompositeSourceOver:
			F=256, G=255-src->A;
			if(G == 0)
				{
				*dest=*src;	// F=256
				}
			else
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R+G*dest->R)>>8;
					dest->G=(F*src->G+G*dest->G)>>8;
					dest->B=(F*src->B+G*dest->B)>>8;
					dest->A=(F*src->A+G*dest->A)>>8;
				}
			break;
		case NSCompositeSourceIn:
			F=dest->A /*, G=0 */;
			dest->R=(F*src->R)>>8;
			dest->G=(F*src->G)>>8;
			dest->B=(F*src->B)>>8;
			dest->A=(F*src->A)>>8;
			break;
		case NSCompositeSourceOut:
			F=255-dest->A /*, G=0 */;
			dest->R=(F*src->R)>>8;
			dest->G=(F*src->G)>>8;
			dest->B=(F*src->B)>>8;
			dest->A=(F*src->A)>>8;
			break;
		case NSCompositeSourceAtop:
			F=dest->A, G=255-src->A;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=(F*src->A)>>8;
				}
			else if(F == 0)
				{
				dest->R=(G*dest->R)>>8;
				dest->G=(G*dest->G)>>8;
				dest->B=(G*dest->B)>>8;
				/* dest->A=(G*dest->A)>>8; does not change - F=dest->A == 0 */
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			/* FIXME
			 if(dest->R > 255) dest->R=255;
			 if(dest->G > 255) dest->G=255;
			 if(dest->B > 255) dest->B=255;
			 if(dest->A > 255) dest->A=255;
			 */
			break;
		case NSCompositeDestinationOver:
			F=255-dest->A, G=255;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=(F*src->A)>>8;
				}
			else if(F == 0)
				{
				*dest=*src;
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			/* FIXME
			 if(dest->R > 255) dest->R=255;
			 if(dest->G > 255) dest->G=255;
			 if(dest->B > 255) dest->B=255;
			 if(dest->A > 255) dest->A=255;
			 */
			break;
		case NSCompositeDestinationIn:
			/*F=0,*/ G=src->A;
			dest->R=(G*dest->R)>>8;
			dest->G=(G*dest->G)>>8;
			dest->B=(G*dest->B)>>8;
			dest->A=(G*dest->A)>>8;
			break;
		case NSCompositeDestinationOut:
			/*F=0,*/ G=255-src->A;
			dest->R=(G*dest->R)>>8;
			dest->G=(G*dest->G)>>8;
			dest->B=(G*dest->B)>>8;
			dest->A=(G*dest->A)>>8;
			break;
		case NSCompositeDestinationAtop:
			F=255-dest->A, G=src->A;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=0 /* (F*src->A)>>8; -- G == src->A is known to be 0 */;
				}
			else if(F == 0)
				{
				dest->R=(G*dest->R)>>8;
				dest->G=(G*dest->G)>>8;
				dest->B=(G*dest->B)>>8;
				dest->A=(G*dest->A)>>8;
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			/* FIXME
			 if(dest->R > 255) dest->R=255;
			 if(dest->G > 255) dest->G=255;
			 if(dest->B > 255) dest->B=255;
			 if(dest->A > 255) dest->A=255;
			 */
			break;
		case NSCompositePlusDarker:
			F=255-25, G=255-25;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=(F*src->A)>>8;
				}
			else if(F == 0)
				{
				dest->R=(G*dest->R)>>8;
				dest->G=(G*dest->G)>>8;
				dest->B=(G*dest->B)>>8;
				dest->A=(G*dest->A)>>8;
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			/* FIXME
			 if(dest->R > 255) dest->R=255;
			 if(dest->G > 255) dest->G=255;
			 if(dest->B > 255) dest->B=255;
			 if(dest->A > 255) dest->A=255;
			 */
			break;		// FIXME: should not influence alpha of result!
		case NSCompositePlusLighter:
			F=255+25, G=255+25;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=(F*src->A)>>8;
				}
			else if(F == 0)
				{
				dest->R=(G*dest->R)>>8;
				dest->G=(G*dest->G)>>8;
				dest->B=(G*dest->B)>>8;
				dest->A=(G*dest->A)>>8;
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			/* FIXME
			 if(dest->R > 255) dest->R=255;
			 if(dest->G > 255) dest->G=255;
			 if(dest->B > 255) dest->B=255;
			 if(dest->A > 255) dest->A=255;
			 */
			break;
		case NSCompositeXOR:
			F=255-dest->A, G=255-src->A;
			if(G == 0)
				{ // calculation is done with 'int' precision; stores only 8 bit
					dest->R=(F*src->R)>>8;
					dest->G=(F*src->G)>>8;
					dest->B=(F*src->B)>>8;
					dest->A=(F*src->A)>>8;
				}
			else if(F == 0)
				{
				dest->R=(G*dest->R)>>8;
				dest->G=(G*dest->G)>>8;
				dest->B=(G*dest->B)>>8;
				dest->A=(G*dest->A)>>8;
				}
			else
				{
				dest->R=(F*src->R+G*dest->R)>>8;
				dest->G=(F*src->G+G*dest->G)>>8;
				dest->B=(F*src->B+G*dest->B)>>8;
				dest->A=(F*src->A+G*dest->A)>>8;
				}
			break;
	}
}

inline static struct RGBA8 getPixel(int x, int y,
									int pixelsWide,
									int pixelsHigh,
									/*
									 int bitsPerSample,
									 int samplesPerPixel,
									 int bitsPerPixel,
									 */
									int bytesPerRow,
									BOOL isPlanar,
									BOOL hasAlpha,
									BOOL isPremultiplied,
									BOOL isAlphaFirst,
									unsigned char *data[5])
{ // extract RGBA8 value of given pixel from bitmap
	int offset;
	struct RGBA8 src;
	if(x < 0 || y < 0 || x >= pixelsWide || y >= pixelsHigh)
		{ // outside - transparent
			src.R=0;
			src.G=0;
			src.B=0;
			src.A=0;
		}
	else if(isPlanar)
		{ // planar
			offset=x+bytesPerRow*y;
			src.R=data[0][offset];
			src.G=data[1][offset];
			src.B=data[2][offset];
			if(hasAlpha)
				src.A=data[3][offset];
			else
				src.A=255;	// opaque
		}
	else
		{ // meshed
			offset=(hasAlpha?4:3)*x + bytesPerRow*y;
			src.R=data[0][offset+0];	// a good compiler should be able to optimize this constant expression data[0][offset]
			src.G=data[0][offset+1];
			src.B=data[0][offset+2];
			if(hasAlpha)
				src.A=data[0][offset+3];
			else
				src.A=255;	// opaque
		}
	if(!isPremultiplied)
		{
		src.R=(src.R*src.A)/255;
		src.G=(src.G*src.A)/255;
		src.B=(src.B*src.A)/255;
		}
	return src;
}

#pragma mark BackingStoreBuffered

static NSString *NSStringFromXRect(XRectangle rect)
{
	return [NSString stringWithFormat:
			@"{%d, %d}, {%u, %u}",
			rect.x,
			rect.y,
			rect.width,
			rect.height];
}

static inline void XIntersectRect(XRectangle *result, XRectangle *with)
{
	if(with->x > result->x+result->width)
		result->width=0;	// second box is completely to the right
	else if(with->x > result->x)
		result->width-=(with->x-result->x), result->x=with->x;	// new left border
	if(with->x+with->width < result->x)
		result->width=0;	// second box is completely to the left
	else if(with->x+with->width < result->x+result->width)
		result->width=with->x+with->width-result->x;	// new right border
	if(with->y > result->y+result->height)
		result->height=0;
	else if(with->y > result->y)
		result->height-=(with->y-result->y), result->y=with->y;
	if(with->y+with->height < result->y)
		result->height=0;	// empty
	else if(with->y+with->height < result->y+result->height)
		result->height=with->y+with->height-result->y;
}

static inline void XUnionRect(XRectangle *result, XRectangle *with)
{
#if 0
	NSLog(@"XUnion: %@ %@", NSStringFromXRect(*result), NSStringFromXRect(*with));
#endif
	if(result->width == 0)
		result->x=with->x, result->width=with->width;	// first point
	else
		{
		if(with->x+with->width > result->x+result->width)
			result->width=with->x+with->width-result->x;			// extend to the right
		if(with->x < result->x)
			result->width+=result->x-with->x, result->x=with->x;	// extend to the left
		}
	if(result->height == 0)
		result->y=with->y, result->height=with->height;	// first point
	else
		{
		if(with->y+with->height > result->y+result->height)
			result->height=with->y+with->height-result->y;		// extend to the top
		if(with->y < result->y)
			result->height+=result->y-with->y, result->y=with->y;	// extend to the bottom
		}
#if 0
	NSLog(@"result: %@", NSStringFromXRect(*result));
#endif
}

static inline int _isDoubleBuffered(_NSX11GraphicsContext *win)
{
	return (((Window) win->_graphicsPort) != win->_realWindow);
}

static inline void _setDirtyRect(_NSX11GraphicsContext *ctxt, int x, int y, unsigned width, unsigned height)
{ // enlarge dirty area for double buffer
	if(_isDoubleBuffered(ctxt))
		{
		XRectangle r={x, y, width, height};
		if(((_NSX11GraphicsState *) ctxt->_graphicsState)->_clip)
			XIntersectRect(&r, &((_NSX11GraphicsState *) ctxt->_graphicsState)->_clipBox);	// intersect with box (if any)
		XUnionRect(&ctxt->_dirty, &r);
		}
}

static inline void _setDirtyPoints(_NSX11GraphicsContext *ctxt, XPoint *points, int npoints)
{
	if(_isDoubleBuffered(ctxt))
		{
		int n=npoints;
		BOOL clip=((_NSX11GraphicsState *) ctxt->_graphicsState)->_clip != NULL;
		while(n-->0)
			{
			XRectangle r={points[n].x, points[n].y, 1, 1};
			if(clip)
				XIntersectRect(&r, &((_NSX11GraphicsState *) ctxt->_graphicsState)->_clipBox);	// intersect with box (if any)
			XUnionRect(&ctxt->_dirty, &r);
			}
		}
}

#pragma mark WindowManager

typedef struct
{ // WindowMaker window manager support
	CARD32 flags;
	CARD32 window_style;
	CARD32 window_level;
	CARD32 reserved;
	Pixmap miniaturize_pixmap;			// pixmap for miniaturize button
	Pixmap close_pixmap;				// pixmap for close button
	Pixmap miniaturize_mask;			// miniaturize pixmap mask
	Pixmap close_mask;					// close pixmap mask
	CARD32 extra_flags;
} GSAttributes;

#define GSWindowStyleAttr 					(1<<0)
#define GSWindowLevelAttr 					(1<<1)
#define GSMiniaturizePixmapAttr				(1<<3)
#define GSClosePixmapAttr					(1<<4)
#define GSMiniaturizeMaskAttr				(1<<5)
#define GSCloseMaskAttr						(1<<6)
#define GSExtraFlagsAttr       				(1<<7)

#define GSDocumentEditedFlag				(1<<0)			// extra flags
#define GSWindowWillResizeNotificationsFlag (1<<1)
#define GSWindowWillMoveNotificationsFlag 	(1<<2)
#define GSNoApplicationIconFlag				(1<<5)

#define WMFHideOtherApplications			10
#define WMFHideApplication					12

+ (void) initialize;
{
	inittab565();	// initialize color profile table(s)
}

- (void) _setSizeHints;
{
	XSizeHints size_hints;		// also specified as a hint
	size_hints.x=_xRect.x;
	size_hints.y=_xRect.y;
	size_hints.flags = PPosition | USPosition;
	XSetNormalHints(_display, _realWindow, &size_hints);
}

- (id) _initWithAttributes:(NSDictionary *) attributes;
{
	NSWindow *window;
	Window win;
	unsigned long valuemask = 0;
	XSetWindowAttributes winattrs;
	XWMHints *wm_hints;
	NSRect frame;
	NSUInteger styleMask;
	NSBackingStoreType backingType;
	_compositingOperation = NSCompositeCopy;	// this is because we don't call [super _initWithAttributes]
#if 0
	NSLog(@"_NSX11GraphicsContext _initWithAttributes:%@", attributes);
#endif
	window=[attributes objectForKey:NSGraphicsContextDestinationAttributeName];
	frame=[window frame];	// window frame in screen coordinates
#if 0
	NSLog(@"window frame=%@", NSStringFromRect(frame));
#endif
	styleMask=[window styleMask];
	backingType=[window backingType];
	_nsscreen=(_NSX11Screen *) [window screen];	// we know that we only have _NSX11Screen instances
	if(![window isKindOfClass:[NSWindow class]])
		{ [self release]; return nil; }	// must provide a NSWindow
										// check that there isn't a non-rectangular rotation!
	_windowRect.origin=[(NSAffineTransform *) (_nsscreen->_screen2X11) transformPoint:frame.origin];
	_windowRect.size=[(NSAffineTransform *) (_nsscreen->_screen2X11) transformSize:frame.size];
#if 0
	NSLog(@"transformed window frame=%@", NSStringFromRect(frame));
#endif
	if(!(wm_hints = XAllocWMHints()))
		[NSException raise:NSMallocException format:@"XAllocWMHints() failed"];
#if (WINDOW_MANAGER_TITLE_HEIGHT==0)	// always hide from window manager
	winattrs.override_redirect = True;
	valuemask |= CWOverrideRedirect;
#else
	// FIXME: should be for all windows
	if((styleMask&GSAllWindowMask) == NSBorderlessWindowMask)
		{ // set X override if borderless
			valuemask |= CWOverrideRedirect;
			winattrs.override_redirect = True;
			valuemask |= CWSaveUnder;
			winattrs.save_under = True;
		}
	else
		_windowRect.origin.y -= WINDOW_MANAGER_TITLE_HEIGHT;   // if window manager moves window down by that amount!
#endif
#if 0
	_windowRect.size.height=-_windowRect.size.height;
	NSLog(@"_windowRect %@", NSStringFromRect(_windowRect));	// _windowRect.size.heigh is negative
	_windowRect.size.height=-_windowRect.size.height;
#endif
	_xRect.x=NSMinX(_windowRect);
	_xRect.y=NSMaxY(_windowRect);
	_xRect.width=NSWidth(_windowRect);
	_xRect.height=NSMinY(_windowRect)-NSMaxY(_windowRect);	// _windowRect.size.height is negative (!)
	if(_xRect.width == 0) _xRect.width=48;
	if(_xRect.height == 0) _xRect.height=49;
#if 0
	NSLog(@"XCreateWindow(%@)", NSStringFromXRect(_xRect));
#endif
	win=XCreateWindow(_display,
					  RootWindowOfScreen(_nsscreen->_screen),		// create an X window on the screen defined by RootWindow
					  _xRect.x,
					  _xRect.y,
					  _xRect.width,
					  _xRect.height,
					  0,
					  CopyFromParent,
					  CopyFromParent,
					  CopyFromParent,
					  valuemask,
					  &winattrs);
	if(!win)
		NSLog(@"did not create Window");
	if(!__WindowNumToNSWindow)
		__WindowNumToNSWindow=NSCreateMapTable(NSIntMapKeyCallBacks,
											   NSNonRetainedObjectMapValueCallBacks, 20);
	NSMapInsert(__WindowNumToNSWindow, (void *) win, window);		// X11 Window to NSWindow
#if 0
	NSLog(@"NSWindow number=%lu", win);
	NSLog(@"Window list: %@", NSAllMapTableValues(__WindowNumToNSWindow));
#endif
	self=[self _initWithGraphicsPort:(void *) win];	// makes the window the "_realWindow"
	if(backingType ==  NSBackingStoreBuffered && _doubleBufferering)
		{ // allocate a backing store buffer pixmap for our window
			XWindowAttributes xwattrs;
			XGetWindowAttributes(_display, win, &xwattrs);
			_graphicsPort=(void *) XCreatePixmap(_display, _realWindow, _xRect.width, _xRect.height, xwattrs.depth);
#if 0
			XCopyArea(_display,
					  _realWindow,
					  (Window) _graphicsPort,
					  _state->_gc,
					  0, 0,
					  _xRect.width, _xRect.height,
					  0, 0);			// copy initial window background
#endif
		}
	if(styleMask&NSUnscaledWindowMask)
		{ // set 1:1 transform (here or in NSWindow???)
		}
	[self _setSizeHints];
	wm_hints->initial_state = NormalState;			// set window manager hints
	wm_hints->input = True;
	wm_hints->flags = StateHint | InputHint;		// WindowMaker ignores the
	XSetWMHints(_display, _realWindow, wm_hints);	// frame origin unless it's also specified as a hint
	XFree(wm_hints);
	[self _setLevel:[window level] andStyle:styleMask];
	if((styleMask & NSClosableWindowMask))			// if window has close, button inform WM
		XSetWMProtocols(_display, _realWindow, &_deleteWindowAtom, 1);
	return self;
}

// _nsscreen must be pre-initialized here

- (id) _initWithGraphicsPort:(void *) port;
{ // port should be the X11 Window *
#if 0
	NSLog(@"_NSX11GraphicsContext _initWithGraphicsPort:%@", attributes);
#endif
#if FIXME
	// get NSScreen/screen from port (Window *)
	// something like XGetScreen(XGetDisplay((Window *) port))
	_nsscreen=[window screen];
	// FIXME: read window size from screen!
	//	_windowRect=frame;
	// e.g. get size hints
#endif
	_graphicsPort=port;	// _window is a typed alias for _graphicsPort
	_realWindow=(Window) port;	// default is unbuffered
								// FIXME: apply [_X112screen transformPoint:NSMakePoint(root_x, root_y)]
	_scale=_nsscreen->_screenScale;
	[self saveGraphicsState];	// initialize graphics state with transformations, GC etc. - don't use anything which depends on graphics state before here!
	XSelectInput(_display, _realWindow,
				 ExposureMask | KeyPressMask |
				 KeyReleaseMask | ButtonPressMask |
				 ButtonReleaseMask | /* ButtonMotionMask | */
				 StructureNotifyMask | PointerMotionMask |
				 EnterWindowMask | LeaveWindowMask |
				 FocusChangeMask | PropertyChangeMask |
				 ColormapChangeMask | KeymapStateMask |
				 VisibilityChangeMask);
	// query server for extensions
#if USE_XRENDER
	if(_hasRender)
		{
		unsigned long valuemask;
		XRenderPictureAttributes attributes;
		XRenderPictFormat *format;
		XWindowAttributes xattr;
		XGetWindowAttributes(_display, ((Window) _graphicsPort), &xattr);

		// FIXME - what do we have to do to really handle transparent windows?

		format=XRenderFindVisualFormat(_display, xattr.visual);
		// NO:		format=XRenderFindStandardFormat(_display, PictStandardARGB32);
		valuemask=0;
		_picture=XRenderCreatePicture(_display, ((Window) _graphicsPort), format, valuemask, &attributes);
#if 1
			{
			XRenderColor c;
			c.red=c.green=c.blue=(65535 * 0.8);
			c.alpha=(65535 * 1.0);
			XRenderFillRectangle(_display, PictOpSrc, _picture, &c, 0, 0, 500, 500);	// fill picture with grey color
			NSLog(@"picture %p", _picture);
			}
#endif
		}
#endif
	return self;
}

- (void) dealloc
{
#if USE_XRENDER
	if(_picture)
		XRenderFreePicture(_display, _picture);	// release picture handle
#endif
#if 1
	NSLog(@"_NSX11GraphicsContext dealloc: %@", self);
#endif
	if(_isDoubleBuffered(self))
		XFreePixmap(_display, (Pixmap) _graphicsPort);
	if(_realWindow)
		{
		NSMapRemove(__WindowNumToNSWindow, (void *) _realWindow);	// Remove X11 Window to NSWindows mapping
		XDestroyWindow(_display, _realWindow);						// Destroy the X Window
		XFlush(_display);
		}
	if(_neutralGC)
		XFreeGC(_display, _neutralGC);
	[_textMatrix release];
	[_textLineMatrix release];
	// here we could check if we were the last window and XDestroyWindow(_display, xAppRootWindow); XCloseDisplay(_display);
	[super dealloc];
}

- (BOOL) isDrawingToScreen	{ return YES; }

#pragma mark PDFOperators

- (void) _setColor:(NSColor *) color;
{
	if(_hasRender)
		{
		ASSIGN(_state->_fillColor, (_NSX11Color *)color);
		ASSIGN(_state->_strokeColor, (_NSX11Color *)color);
		}
	else
		{
		unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
		NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
		XSetBackground(_display, _state->_gc, pixel);
		XSetForeground(_display, _state->_gc, pixel);
		}
}

- (void) _setFillColor:(NSColor *) color;
{
	if(_hasRender)
		ASSIGN(_state->_fillColor, (_NSX11Color *)color);
	else
		{
		unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
		NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
		XSetBackground(_display, _state->_gc, pixel);
		//		XSetForeground(_display, _state->_gc, pixel);
		}
}

- (void) _setStrokeColor:(NSColor *) color;
{
	if(_hasRender)
		ASSIGN(_state->_strokeColor, (_NSX11Color *)color);
	else
		{
		unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
		NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
		XSetForeground(_display, _state->_gc, pixel);
		}
}

- (void) _setCTM:(NSAffineTransform *) atm;
{ // we must also translate window base coordinates to window-relative X11 coordinates
  // NOTE: we could also cache this window relative transformation!
	[_state->_ctm release];
	_state->_ctm=[(NSAffineTransform *) (_nsscreen->_screen2X11) copy];									// this translates to screen coordinates
	if(_scale == 1.0)
		[_state->_ctm translateXBy:0.0 yBy:(HeightOfScreen(_nsscreen->_screen)-_xRect.height)];		// X11 uses window relative coordinates for all drawing
	else
		[_state->_ctm translateXBy:0.0 yBy:(HeightOfScreen(_nsscreen->_screen)-_xRect.height)/_scale];		// X11 uses window relative coordinates for all drawing
	[self _concatCTM:atm];
}

- (void) _concatCTM:(NSAffineTransform *) atm;
{
	[_state->_ctm prependTransform:atm];
#if 0
	NSLog(@"_concatCTM -> %@", _state->_ctm);
#endif
	// FIXME - we must apply the CTM inverse to the source picture when using XRender!
	if(_hasRender)
		{
		NSAffineTransformStruct atms=[_state->_ctm transformStruct];
		XTransform xtransform;

		xtransform.matrix[0][0] = XDoubleToFixed(atms.m11);
		xtransform.matrix[0][1] = XDoubleToFixed(atms.m12);
		xtransform.matrix[0][2] = XDoubleToFixed(atms.tX);

		xtransform.matrix[1][0] = XDoubleToFixed(atms.m21);
		xtransform.matrix[1][1] = XDoubleToFixed(atms.m22);
		xtransform.matrix[1][2] = XDoubleToFixed(atms.tY);

		xtransform.matrix[2][0] = 0;
		xtransform.matrix[2][1] = 0;
		xtransform.matrix[2][2] = 1 << 16;

		//		XRenderSetPictureTransform (_display, _picture, &xtransform);
		}
}

- (int) _XRenderPictOp
{
	switch(_compositingOperation) {
		case NSCompositeClear:
			return PictOpClear;
		case NSCompositeCopy:
			return PictOpSrc;
		case NSCompositeSourceOver:
		case NSCompositeHighlight:
			return PictOpOver;
		case NSCompositeSourceIn:
			return PictOpIn;
		case NSCompositeSourceOut:
			return PictOpOut;
		case NSCompositeSourceAtop:
			return PictOpAtop;
		case NSCompositeDestinationOver:
			return PictOpOverReverse;
		case NSCompositeDestinationIn:
			return PictOpInReverse;
		case NSCompositeDestinationOut:
			return PictOpOutReverse;
		case NSCompositeDestinationAtop:
			return PictOpAtopReverse;
		case NSCompositeXOR:
			return PictOpXor;
		case NSCompositePlusLighter:
			return PictOpAdd;
		case NSCompositePlusDarker:
			return PictOpSaturate;
		default:
			return PictOpOver;
	}
}

- (void) _setCompositing
{
	XGCValues values;
	switch(_compositingOperation) {
			/* try to translate to
			 GXclear				0x0	0
			 GXand				0x1	src AND dst
			 GXandReverse		0x2	src AND NOT dst
			 GXcopy				0x3	src
			 GXandInverted		0x4	(NOT src) AND dst
			 GXnoop				0x5	dst
			 GXxor				0x6	src XOR dst
			 GXor				0x7	src OR dst
			 GXnor				0x8	(NOT src) AND (NOT dst)
			 GXequiv				0x9	(NOT src) XOR dst
			 GXinvert			0xa	NOT dst
			 GXorReverse			0xb	src OR (NOT dst)
			 GXcopyInverted		0xc	NOT src
			 GXorInverted		0xd	(NOT src) OR dst
			 GXnand				0xe	(NOT src) OR (NOT dst)
			 GXset				0xf	1
			 */
		case NSCompositeClear:
			values.function=GXclear;
			break;
		case NSCompositeCopy:
			values.function=GXcopy;
			break;
		case NSCompositeSourceOver:
			values.function=GXor;
			break;
		case NSCompositeXOR:
			values.function=GXxor;
			break;
		default:
			NSLog(@"can't draw using compositingOperation %d", _compositingOperation);
			values.function=GXcopy;
			break;
	}
	XChangeGC(_display, _state->_gc, GCFunction, &values);
}

#pragma mark Paths

static int _capStyles[]=
{ // translate cap styles
	CapButt,	// NSButtLineCapStyle
	CapRound,	// NSRoundLineCapStyle
	CapProjecting,	// NSSquareLineCapStyle
	CapNotLast	// undefined
};

static int _joinStyles[]=
{ // translate join style
	JoinMiter,	// NSMiterLineJoinStyle
	JoinRound,	// NSRoundLineJoinStyle
	JoinBevel,	// NSBevelLineJoinStyle
	JoinBevel	// undefined
};

typedef struct _PointsForPathState
{
	NSBezierPath *path;
	unsigned int element;	// current element being expanded
	unsigned int elements;	// number of elements in path
	XPoint *points;		// points array
	XPoint lastpoint;
	int npoints;		// number of entries in array
	unsigned int capacity;	// how many elements are allocated
} PointsForPathState;

static inline void addPoint(PointsForPathState *state, NSPoint point)
{
	XPoint pnt;
	if(state->npoints >= state->capacity)
		state->points=(XPoint *) objc_realloc(state->points, sizeof(state->points[0])*(state->capacity=2*state->capacity+5));	// make more room
																																// FIXME: limit to short?
	pnt.x=point.x;		// convert to integer
	pnt.y=point.y;
	if(state->npoints == 0 || pnt.x != state->lastpoint.x || pnt.y != state->lastpoint.y)
		{ // first or really different
#if 0
			if(state->npoints == 0)
				NSLog(@"first point");
#endif
			state->lastpoint=pnt;
			state->points[state->npoints++]=pnt;	// store point
#if 0
			NSLog(@"addPoint:(%d, %d)", (int) point.x, (int) point.y);
#endif
		}
#if 0
	else
		NSLog(@"addPoint duplicate ignored:(%d, %d)", pnt.x, pnt.y);
#endif
}

// CHECKME if this is really triggered by rectangle primitives and e.g. NSSegmentedCell

- (BOOL) _rectForPath:(PointsForPathState *) state rect:(XRectangle *) rect;
{ // check if points[] describe a simple Rectangle (clockwise orientation)
	if(state->npoints != 5)
		return NO;
	if((state->points[0].x == state->points[1].x) &&
	   (state->points[1].y == state->points[2].y) &&
	   (state->points[2].x == state->points[3].x) &&
	   (state->points[3].y == state->points[4].y))
		{
		rect->x=state->points[0].x;
		rect->y=state->points[0].y;
		if(state->points[3].x < state->points[0].x || state->points[1].y < state->points[0].y)
			return NO;
		rect->width=state->points[3].x-state->points[0].x;
		rect->height=state->points[1].y-state->points[0].y;
		return YES;
		}
	return NO;
}

- (BOOL) _pointsForPath:(PointsForPathState *) state;
{ // process next part - return YES if anything found
	NSPoint points[3];
	NSPoint first=NSZeroPoint, current=NSZeroPoint, next;
	NSBezierPathElement element;
	if(state->element == 0)
		state->elements=(int)[state->path elementCount];	// initialize
	if(state->element >= state->elements)
		{ // no more elements
			if(state->points)
				objc_free(state->points);	// release buffer
			return NO;	// all done
		}
	state->npoints=0;
	element=[state->path elementAtIndex:state->element associatedPoints:points];	// get first element
	while(YES)
		{ // get next (closed or open) subpath
			switch(element) {
				case NSMoveToBezierPathElement:
					current=first=[_state->_ctm transformPoint:points[0]];
					addPoint(state, current);
					break;
				case NSLineToBezierPathElement:
					next=[_state->_ctm transformPoint:points[0]];
					addPoint(state, next);
					current=next;
					break;
				case NSCurveToBezierPathElement: {
#if 0	// untested but should be better

				// FIXME: we should better create a path by subdividig the path or by using some algorithm like the following:

				// http://www.niksula.cs.hut.fi/~hkankaan/Homepages/bezierfast.html

				unsigned int i, steps=10;
				float x, xd, xdd, xddd, xdd_per_2, xddd_per_2, xddd_per_6;
				float y, yd, ydd, yddd, ydd_per_2, yddd_per_2, yddd_per_6;
				double t = 1.0 / steps;
				double t3 = 3.0 * t;
				double tt = t * t;
				double tt3 = 3.0 * tt;
				x = p[0].x;
				xd = (p[1].x - p[0].x) * t3;
				xdd_per_2 = (p[0].x - 2 * p[1].x + p[2].x) * tt3;
				xddd_per_2 = (3 * (p[1].x - p[2].x) + p[3].x - p[0].x) * tt * t3;
				xddd = xddd_per_2 + xddd_per_2;
				xdd = xdd_per_2 + xdd_per_2;
				xddd_per_6 = xddd_per_2 * (1.0 / 3.0);
				y = p[0].y;
				yd = (p[1].y - p[0].y) * t3;
				ydd_per_2 = (p[0].y - 2 * p[1].y + p[2].y) * tt3;
				yddd_per_2 = (3 * (p[1].y - p[2].y) + p[3].y - p[0].y) * tt * t3;
				yddd = yddd_per_2 + yddd_per_2;
				ydd = ydd_per_2 + ydd_per_2;
				yddd_per_6 = yddd_per_2 * (1.0 / 3.0);

				// uses 14 additions per step

				for(i=0; i < steps; i++)
					{
					addPoint(state, NSMakePoint(x, y));
					x = x + xd + xdd_per_2 + xddd_per_6;
					xd = xd + xdd + xddd_per_2;
					xdd = xdd + xddd;
					xdd_per_2 = xdd_per_2 + xddd_per_2;
					y = y + yd + ydd_per_2 + yddd_per_6;
					yd = yd + ydd + yddd_per_2;
					ydd = ydd + yddd;
					ydd_per_2 = ydd_per_2 + yddd_per_2;
					}
				addPoint(state, next=NSMakePoint(x, y));	// add last one (should be p3)

				// or http://www.antigrain.com/research/adaptive_bezier/

				// is there a better algorithm? That resembles Bresenham or CORDIC that
				//
				// - works with integer values
				// - moves one pixel per step either in x or y direction
				// - is not based on a predefined number of steps
				// - uses screen resolution as the smoothness limit
				//

#else
				// straight forward - works
				NSPoint p0=current;
				NSPoint p1=[_state->_ctm transformPoint:points[0]];
				NSPoint p2=[_state->_ctm transformPoint:points[1]];
				NSPoint p3=[_state->_ctm transformPoint:points[2]];
				float t;
#if 0
				NSLog(@"pointsForPath: curved element");
				NSLog(@"p0=%@ p1=%@ p2=%@ p3=%@", NSStringFromPoint(p0), NSStringFromPoint(p1), NSStringFromPoint(p2), NSStringFromPoint(p3));
#endif

				/* here is DeCasteljau Algorithm avoiding sqares and cubes

				 uses 12 multiplications, 12 additions, 12 subtractions per arbitrary point

				 // simple linear interpolation between two points
				 void lerp (point &dest, point &a, point &b, float t)
				 {
				 dest.x = a.x + (b.x-a.x)*t;
				 dest.y = a.y + (b.y-a.y)*t;
				 }

				 // evaluate a point on a bezier-curve. t goes from 0 to 1.0
				 void bezier (point &dest, float t)
				 {
				 point ab,bc,cd,abbc,bccd;
				 lerp (ab, a,b,t);           // point between a and b (green)
				 lerp (bc, b,c,t);           // point between b and c (green)
				 lerp (cd, c,d,t);           // point between c and d (green)
				 lerp (abbc, ab,bc,t);       // point between ab and bc (blue)
				 lerp (bccd, bc,cd,t);       // point between bc and cd (blue)
				 lerp (dest, abbc,bccd,t);   // point on the bezier-curve (black)
				 }

				 */
				// FIXME: we should adjust the step size to the size of the path
				for(t=0.1; t<=0.9; t+=0.1)
					{ // very simple and slow approximation
					  // uses 16 multiplications, 2 scaling, 7 additions per step
						float t1=(1.0-t);
						float t1sq=t1*t1;
						float t1cub=t1*t1sq;
						float t2=t*t;
						float t3=t*t2;
						NSPoint pnt;
						pnt.x=p0.x*t1cub+3.0*(p1.x*t*t1sq+p2.x*t2*t1)+p3.x*t3;
						pnt.y=p0.y*t1cub+3.0*(p1.y*t*t1sq+p2.y*t2*t1)+p3.y*t3;
						addPoint(state, pnt);
					}
				addPoint(state, next=p3);	// move to final point (if not already there)
#endif
				current=next;
				break;
				}
				case NSClosePathBezierPathElement:
					addPoint(state, first);
					state->element++;
					return YES;	// stroke/fill the closed path and start a new one if we have multiple sections
			}
			state->element++;
			if(state->element >= state->elements)
				return YES;	// done
			element=[state->path elementAtIndex:state->element associatedPoints:points];	// get next element
			if(element == NSMoveToBezierPathElement)
				return YES;	// end of previous (non-closed) element
		}
}

- (Region) _regionFromPath:(NSBezierPath *) path
{ // get region from path
	PointsForPathState state={ path };	// initializes other struct components with 0
	Region region=NULL;
	while([self _pointsForPath:&state])
		{
		if(!region)
			{
			if(state.npoints < 2)
				region=XCreateRegion();	// create empty region
			else
				region=XPolygonRegion(state.points, (int)state.npoints, [path windingRule] == NSNonZeroWindingRule?WindingRule:EvenOddRule);
			}
		else
			NSLog(@"can't handle complex winding rules"); // else  FIXME: build the Union or intersection of both (depending on winding rule)
		}
	return region;
}

- (void) _stroke:(NSBezierPath *) path;
{
	if(_picture)
		{ // stroke to XRender Picture
			[(_NSX11BezierPath *) path _stroke:self color:_state->_strokeColor];
			return;
		}
	else
		{
		PointsForPathState state={ path };	// initializes other struct components with 0
		CGFloat *pattern=NULL;	// FIXME: who is owner of this data? and who takes care not to overflow?
		NSInteger count;
		CGFloat phase;
		int width=(_scale != 1.0)?[path lineWidth]*_scale:[path lineWidth];	// multiply with userSpaceScale factor of current NSScreen!
		if(width < 1)
			width=1;	// default width
#if 0
		NSLog(@"_stroke %@", path);
#endif
		[self _setCompositing];
		[path getLineDash:pattern count:&count phase:&phase];
		XSetLineAttributes(_display, _state->_gc,
						   width,
						   count == 0 ? LineSolid : LineOnOffDash,
						   _capStyles[[path lineCapStyle]&0x03],
						   _joinStyles[[path lineJoinStyle]&0x03]
						   );
		if(count > 0 && count < 100 && pattern)
			{
			char dash_list[count];	// allocate on stack
			int i;
			for(i = 0; i < count; i++)
				dash_list[i] = (char) pattern[i];
			XSetDashes(_display, _state->_gc, phase, dash_list, (int)count);
			}
		while([self _pointsForPath:&state])
			{
#if 0
			NSLog(@"npoints=%d", state.npoints);
#endif
			XDrawLines(_display, ((Window) _graphicsPort), _state->_gc, state.points, (int)state.npoints, CoordModeOrigin);
			_setDirtyPoints(self, state.points, (int)state.npoints);
			}
		}
}


- (void) _renderTrapezoid:(NSPoint [4]) points color:(_NSX11Color *) color;
{ // callback from _fill
#if USE_XRENDER
	XTrapezoid trap;
#if 0
	NSLog(@"{%@, %@, %@, %@}", NSStringFromPoint(points[0]), NSStringFromPoint(points[1]), NSStringFromPoint(points[2]), NSStringFromPoint(points[3]));
#endif
#if 0
	{
	XRenderColor color = { 255<<8, 0, 255<<8, 0<<8 };
	XRenderFillRectangle(_display, PictOpSrc, _picture, &color, 8, 11, 43, 19);
	XRenderComposite(_display, PictOpSrc, [color _pictureForColor], None, _picture, 0, 0, 0, 0, 100, 150, 300, 500);
	XFlush(_display);
	}
#endif
	trap.left.p1.x=XDoubleToFixed(points[0].x);
	trap.left.p1.y=XDoubleToFixed(points[0].y);
	trap.left.p2.x=XDoubleToFixed(points[1].x);
	trap.left.p2.y=XDoubleToFixed(points[1].y);
	trap.right.p1.x=XDoubleToFixed(points[2].x);
	trap.right.p1.y=XDoubleToFixed(points[2].y);
	trap.right.p2.x=XDoubleToFixed(points[3].x);
	trap.right.p2.y=XDoubleToFixed(points[3].y);
	if(trap.right.p1.x < trap.left.p1.x)
		{ // how can this happen? We sort points in ascending y and x?
			XPointFixed h;
			NSLog(@"renderTrapezoid problem: should swap!");
			h=trap.left.p1; trap.left.p1=trap.right.p1; trap.right.p1=h;
			h=trap.left.p2; trap.left.p2=trap.right.p2; trap.right.p2=h;
		}
	// this requires that the edges are already intra/extrapolated to the base/top lines
	trap.bottom=MAX(trap.left.p1.y, trap.left.p2.y);
	trap.top=MIN(trap.left.p1.y, trap.left.p2.y);
	XRenderCompositeTrapezoids(_display,
							   [self _XRenderPictOp],
							   [_state->_fillColor _pictureForColor],
							   _picture,
							   XRenderFindStandardFormat(_display, PictStandardA8),	// PictStandardA1 would give non-antialised result
							   0, 0,	// we should properly define xSrc and ySrc if we use a pattern color
							   &trap, 1);
#endif
}

- (void) _fill:(NSBezierPath *) path;
{
	if(_picture)
		{
		[(_NSX11BezierPath *) path _fill:self color:_state->_fillColor];
		return;
		}
	else
		{
		PointsForPathState state={ path };	// initializes other struct components with 0
		XGCValues values; // we have to temporarily swap background & foreground colors since X11 uses the FG color to fill!
#if 0
		NSLog(@"_fill");
#endif
		// FIXME: is this fetched from the Server? If yes, to reduce the roundtrip time, we should have TWO GCs
		XGetGCValues(_display, _state->_gc, GCForeground | GCBackground, &values);
		XSetForeground(_display, _state->_gc, values.background);	// set the fill color
		XSetFillStyle(_display, _state->_gc, FillSolid);
		XSetFillRule(_display, _state->_gc, [path windingRule] == NSNonZeroWindingRule?WindingRule:EvenOddRule);
		[self _setCompositing];
		while([self _pointsForPath:&state])
			{
			XRectangle rect;
			if([self _rectForPath:&state rect:&rect])
				{
				XFillRectangles(_display, ((Window) _graphicsPort), _state->_gc, &rect, 1);
				_setDirtyRect(self, rect.x, rect.y, rect.width, rect.height);
				}
			else
				{
				XFillPolygon(_display, ((Window) _graphicsPort), _state->_gc, state.points, state.npoints, Complex, CoordModeOrigin);
				_setDirtyPoints(self, state.points, state.npoints);
				}
			}
		XSetForeground(_display, _state->_gc, values.foreground);	// restore stroke color
		}
}

- (void) _addClip:(NSBezierPath *) path reset:(BOOL) flag;
{
	Region r;
	XRectangle clip;
#if 0
	NSLog(@"_addClip reset:%d", flag);
#endif
	r=[self _regionFromPath:path];
	if(_state->_clip)
		{ // region exists
			if(flag)
				{
					XDestroyRegion(_state->_clip);	// delete previous
					_state->_clip=r;	// save
				}
			else
				{ // intersect with existing region
#if 0
					{
					XRectangle box;
					XClipBox(r, &box);
					NSLog(@"_addClip box=%@", NSStringFromXRect(box));
					XClipBox(_state->_clip, &box);
					NSLog(@"      to box=%@", NSStringFromXRect(box));
					}
#endif
					XIntersectRegion(_state->_clip, r, _state->_clip);
					XDestroyRegion(r);	// no longer needed
				}
		}
	else
		_state->_clip=r;	// first call
	XSetRegion(_display, _state->_gc, _state->_clip);
	XClipBox(_state->_clip, &_state->_clipBox);	// get current clipping box
	clip.x=0;
	clip.y=0;
	clip.width=_xRect.width;
	clip.height=_xRect.height;
	XIntersectRect(&_state->_clipBox, &clip);	// clip to window (to avoid errors when using XGetImage)
												// FIXME: interset with the screen rect expressed in window coordinates so that we never try to draw outside of the screen
#if 0
	NSLog(@"         box=%@", NSStringFromXRect(_state->_clipBox));
#endif
#if USE_XRENDER
	if(_hasRender)
		XRenderSetPictureClipRegion(_display, _picture, _state->_clip);
#endif
}

- (void) _setShadow:(NSShadow *) shadow;
{ // we can't draw shadows without alpha
	NIMP;
}

// FIXME: replace this with a binary alpha-plane

- (void) _setShape:(NSBezierPath *) path;
{ // set window shape - the filled path defines the non-transparent area (needs Xext)
	Region region=[self _regionFromPath:path];
#if 0
	NSLog(@"_setShape: %@", self);
#endif
#if 0
	{ // check the result...
		Bool bounding_shaped, clip_shaped;
		int x_bounding, y_bounding, x_clip, y_clip;
		unsigned int w_bounding, h_bounding, w_clip, h_clip;
		XShapeQueryExtents(_display, _realWindow,
						   &bounding_shaped,
						   &x_bounding, &y_bounding,
						   &w_bounding, &h_bounding,
						   &clip_shaped,
						   &x_clip, &y_clip, &w_clip, &h_clip);
		NSLog(@"before %@%@ b:(%d, %d, %u, %u) clip:(%d, %d, %u, %u)",
			  bounding_shaped?@"bounding shaped ":@"",
			  clip_shaped?@"bounding shaped ":@"",
			  x_bounding, y_bounding, w_bounding, h_bounding,
			  x_clip, y_clip, w_clip, h_clip);
	}
#endif
	XShapeCombineRegion(_display, _realWindow,
						ShapeClip,
						0, 0,
						region,
						ShapeSet);
	XShapeCombineRegion(_display, _realWindow,
						ShapeBounding,
						0, 0,
						region,
						ShapeSet);
	XDestroyRegion(region);
	// ...inking also needs an overlaid InputOnly window to receive events at all pixels
#if 0
	{ // check the result...
		Bool bounding_shaped, clip_shaped;
		int x_bounding, y_bounding, x_clip, y_clip;
		unsigned int w_bounding, h_bounding, w_clip, h_clip;
		XShapeQueryExtents(_display, _realWindow,
						   &bounding_shaped,
						   &x_bounding, &y_bounding,
						   &w_bounding, &h_bounding,
						   &clip_shaped,
						   &x_clip, &y_clip, &w_clip, &h_clip);
		NSLog(@"after %@%@ b:(%d, %d, %u, %u) clip:(%d, %d, %u, %u)",
			  bounding_shaped?@"bounding shaped ":@"",
			  clip_shaped?@"clip shaped ":@"",
			  x_bounding, y_bounding, w_bounding, h_bounding,
			  x_clip, y_clip, w_clip, h_clip);
	}
#endif
}

#pragma mark Text

- (void) _setFont:(NSFont *) font;
{
	if(!font || font == _state->_font)
		return;	// change only if needed
	[_state->_font release];
	_state->_font=(_NSX11Font *)[font retain];
}

- (void) _beginText;
{
	ASSIGN(_textMatrix, [NSAffineTransform transform]);	// identity
	ASSIGN(_textLineMatrix, _textMatrix);
	// FIXME: reset other text state ???
	_rise=0.0;
	_horizontalScale=1.0;
}

- (void) _endText; { return; }

- (void) _setTextPosition:(NSPoint) pos;
{ // PDF: x y Td
#if 0
	NSLog(@"Td %@", NSStringFromPoint(pos));
#endif
	[_textLineMatrix translateXBy:pos.x yBy:pos.y];
	ASSIGN(_textMatrix, _textLineMatrix);	// update text line matrix
}

- (void) _setTM:(NSAffineTransform *) tm;
{ // PDF: a b c d e f Tm
#if 0
	NSLog(@"Tm %@", tm);
#endif
	ASSIGN(_textLineMatrix, tm);
	ASSIGN(_textMatrix, tm);
}

- (void) _setLeading:(CGFloat) val;
{ // PDF: x TL
	_leading=val;
}

- (void) _setCharSpace:(CGFloat) val;
{ // PDF: v Tc
	_characterSpace=val;
}

- (void) _setHorizontalScale:(CGFloat) val;
{ // PDF: v Tz
	_horizontalScale=val;
}

- (void) _setWordSpace:(CGFloat) val;
{ // PDF: v Tw
	_wordSpace=val;
}

- (void) _setBaseline:(CGFloat) val;
{ // PDF: v Ts
	_rise=val;
}

// do we need this operator or can a good PDF context cache & optimize to use combined operators?
- (void) _newLine:(NSPoint) pos;
{ // PDF: x y TD
	_leading=-pos.y;	// really a - ?
	[self _setTextPosition:pos];
}

- (void) _newLine;
{ // PDF: T*
	[self _setTextPosition:NSMakePoint(0.0, _leading)];	// FIXME - shouldn't we apply current matrix.tX?
}

// FIXME:
// does not handle rotation
// ignores CTM scaling (only in cursor position!)
// ignores flipping which appears to be correct (can only be verified by generating PDF documents)

// DEPRECATED
- (void) _drawGlyphBitmap:(unsigned char *) buffer x:(int) x y:(int) y width:(unsigned) width height:(unsigned) height;
{ // paint to screen
	XImage *img;
	int screen_number=XScreenNumberOfScreen(_nsscreen->_screen);
	int pxx, pxy;
	XGCValues values;
	BOOL mustFetch;
	struct RGBA8 stroke;
#if 0
	NSLog(@"_drawGlyphBitmap x:%d y:%d width:%u height:%u", x, y, width, height);
	NSLog(@"font=%@", _state->_font);
#endif
	if(x > _state->_clipBox.x+_state->_clipBox.width || x+width <  _state->_clipBox.x)
		return;	// completely outside
	if(y > _state->_clipBox.y+_state->_clipBox.height || y+height <  _state->_clipBox.y)
		return;	// completely outside
	// FIXME: if partially outside, reduce area to be processed
	// CHECKME: does the compositing operation apply to text drawing?
	//	mustFetch=_compositingOperation != NSCompositeClear && _compositingOperation != NSCompositeCopy &&
	//		_compositingOperation != NSCompositeSourceIn && _compositingOperation != NSCompositeSourceOut;
	mustFetch=YES;
	if(mustFetch)
		{ // we must really fetch the current image from our context
		  // FIXME: this is quite slow even if we have double buffering!
			// FIXME: restrict to window/screen
#if 0
			NSLog(@"fetch %u pixels text", width*height);
			NSLog(@"glyph: XGetImage (%p, %p, %d, %d, %u, %u)", _display, _graphicsPort, x, y, width, height);
			NSLog(@"double buffered=%d gp=%p real=%p", _isDoubleBuffered(self), (void *) _graphicsPort, (void *) _realWindow);
#endif
			img=XGetImage(_display, ((Window) _graphicsPort),
						  x, y, width, height,
						  AllPlanes, ZPixmap);
#if 0
			NSLog(@"img=%p", img);
#endif
		}
	else
		{
		img=XCreateImage(_display, DefaultVisual(_display, screen_number), DefaultDepth(_display, screen_number),
						 ZPixmap, 0, NULL,
						 width, height,
						 8, 0);
		if(!(img && (img->data = objc_malloc(img->bytes_per_line*img->height))))
			return;	// error
		}
	if(!img)
		{ // NSBackingStoreRetained sometimes returns BadMatch and nil
		NSLog(@"glyph: could not XGetImage (%d, %d, %u, %u)", x, y, width, height);
		[[NSColor redColor] set];	// will set _gc
		XFillRectangle(_display, ((Window) _graphicsPort), _state->_gc, x, y, width, height);
		return;	// can't allocate or fetch
		}
	XGetGCValues(_display, _state->_gc, GCForeground | GCBackground, &values);
	stroke = Pixel2RGBA8(img->depth, values.foreground);	// translate 565 or 888 color to RGBA8

	for(pxy=0; pxy<height; pxy++)
		{ // composite all pixels of the glyph
			for(pxx=0; pxx<width; pxx++)
				{
				struct RGBA8 src = { stroke.R, stroke.G, stroke.B, *buffer++ };	// alpha-blend stroke color by grey value of bitmap
				struct RGBA8 dest;
				if(mustFetch)
					dest=XGetRGBA8(img, pxx, pxy);	// get current image value
				else
					dest = (struct RGBA8){ 0, 0, 0, 0 };
				//			composite(/*_compositingOperation*/ NSCompositeSourceOver, &src, &dest);
				// "simple" composition
				dest.R=(src.A*src.R + (255-src.A)*dest.R)>>8;
				dest.G=(src.A*src.G + (255-src.A)*dest.G)>>8;
				dest.B=(src.A*src.B + (255-src.A)*dest.B)>>8;
				XSetRGBA8(img, pxx, pxy, &dest);
				}
		}

	values.function=GXcopy;
	XChangeGC(_display, _state->_gc, GCFunction, &values);	// use X11 copy compositing
#if 0
	NSLog(@"put %u pixels text", width*height);
	NSLog(@"glyph: XPutImage (%p, %p, %p, %p, %d, %d, %d, %d, %u, %u)", _display, _graphicsPort, _state->_gc, img, 0, 0, x, y, width, height);
#endif
	XPutImage(_display, ((Window) _graphicsPort), _state->_gc, img, 0, 0, x, y, width, height);
	_setDirtyRect(self, x, y, width, height);
	XDestroyImage(img);
	// should this somehow distinguish between character and word spacing?
	[_textMatrix translateXBy:width+_characterSpace
						  yBy:0.0];		// advance text matrix in horizontal mode according to info from glyph
}

- (void) _drawGlyphs:(NSGlyph *) glyphs count:(NSUInteger) cnt;	// (string) Tj
{
	static XChar2b *buf;	// translation buffer (NSGlyph -> XChar2b)
	static unsigned int buflen;
	unsigned int i;
	XFontStruct *font;
#if 0
	NSLog(@"NSString: _drawGlyphs:%p count:%u font:%@", glyphs, cnt, _state->_font);
#endif
#if USE_XRENDER
	if(_picture)
		{
#if 0
		NSLog(@"cnt=%u picture=%d fillColor=%d", cnt, _picture, _state->_fillColor);
#endif
#if 0
		[self _setStrokeColor:[NSColor colorWithDeviceRed:0.7 green:0.3 blue:0.0 alpha:0.7]];
#endif
#if 0
		NSLog(@"stroke color %@", _state->_strokeColor);
#endif
#if USE_XRENDER_GLYPHSTORE
		XRenderCompositeString32(_display,
								 [self _XRenderPictOp],
								 [_state->_strokeColor _pictureForColor],	// (src) color pattern
								 _picture,				// (dest)
								 XRenderFindStandardFormat(_display, PictStandardA8),	// the format of the glyph mask
								 [_state->_font _glyphSet],	// current font
								 0, 0,	// x,y src
								 atms.tX, atms.tY,	// x,y dest
								 glyphs,
								 cnt);
#else
		for(; cnt > 0; glyphs++, cnt--)
			{
			_CachedGlyph glyph;
			NSSize advance;
			NSAffineTransform *trm=[NSAffineTransform transform];
			NSAffineTransformStruct atms;
			[trm setTransformStruct:(NSAffineTransformStruct){ _horizontalScale, 0.0, 0.0, 1.0, 0.0, _rise }];
			[trm appendTransform:_textMatrix];
			[trm appendTransform:_state->_ctm];
			atms=[trm transformStruct];
			glyph=[_state->_font _pictureForGlyph:*glyphs];
			if(!glyph)
				continue;	// not found
							// setup any transforms
							// i.e. get glyph position from text matrix
							// apply CTM
							// [self renderSrc:[_state->_strokeColor _pictureForColor] mask:glyph->picture CTM:_state->ctm];
			XRenderComposite(_display,
							 PictOpOver /*[self _XRenderPictOp]*/,
							 [_state->_strokeColor _pictureForColor],	// (src) color (pattern)
							 glyph->picture,	// use glyph picture to mask the text color
							 _picture,
							 0, 0,
							 0, 0,
							 (int) atms.tX, ((int) atms.tY)-glyph->y,
							 glyph->width, glyph->height);
			[_state->_font getAdvancements:&advance forGlyphs:glyphs count:1];	// for current glyph
																				// if it is a space character code 32, apply word spacing
																				// what exactly should be done is described on page 313 of PDF-1.4
			[self _setTextPosition:NSMakePoint((advance.width+_characterSpace)*_horizontalScale, 0.0)];		// advance text matrix in horizontal mode according to info from glyph
			}
#endif
		/*
		 _setDirtyRect(self,
		 cursor.x, cursor.y,
		 XTextWidth16(font, buf, cnt),
		 font->ascent + font->descent);
		 */
		return;
		}
#endif
	if([_state->_font renderingMode] == NSFontIntegerAdvancementsRenderingMode)
		{ // use the basic X11 bitmap font rendering services
			int width;
			NSAffineTransformStruct atms=[_textMatrix transformStruct];
			NSPoint cursor=[_state->_ctm transformPoint:NSMakePoint(atms.tX, atms.tY)];
			[_state->_font _setScale:_scale];
			font=[_state->_font _font];
			XSetFont(_display, _state->_gc, font->fid);	// set font-ID in GC
														// set any other attributes
			[self _setCompositing];	// use X11 compositing
#if 1
			{
			XRectangle box;
			XClipBox(_state->_clip, &box);
			NSLog(@"draw %lu glyphs at (%d,%d) clip=%@", (unsigned long)cnt, (int) cursor.x, (int)(cursor.y-_rise+font->ascent+1), NSStringFromXRect(box));
			}
#endif
			if(!buf || cnt > buflen)
				buf=(XChar2b *) objc_realloc(buf, sizeof(buf[0])*(buflen=(unsigned int)cnt+20));	// increase translation buffer if needed
			if(sizeof(XChar2b) != 2)
				{ // fix subtle bug when struct alignment rules of the compiler make XChar2b larger than 2 bytes
					for(i=0; i<cnt; i++)
						{ // we need a different encoding for XDrawString16() and XTextWidth16()
							NSGlyph g=glyphs[i];
							((XChar2b *) (((short *)buf)+i))->byte1=g>>8;
							((XChar2b *) (((short *)buf)+i))->byte2=g;
						}
				}
			else
				{
				for(i=0; i<cnt; i++)
					{
					NSGlyph g=glyphs[i];
					buf[i].byte1=g>>8;
					buf[i].byte2=g;
					}
				}
			XDrawString16(_display, ((Window) _graphicsPort),
						  _state->_gc,
						  cursor.x, (int)(cursor.y-_rise+font->ascent+1),	// X11 defines y as the character top line so we have to adjust for the ascent
						  /* NOTE:
						   XChar2b is a struct which may be 4 bytes locally depending on struct alignment rules!
						   But here it appears to work since Xlib appears to assume that there are 2*length bytes to send to the server
						   */
						  buf,
						  (int) cnt);		// Unicode drawing
			if(sizeof(XChar2b) != 2)
				{ // fix subtle bug when struct alignment rules of the compiler make XChar2b larger than 2 bytes
					for(i=0; i<cnt; i++)
						{
							NSGlyph g=glyphs[i];
							buf[i].byte1=g>>8;
							buf[i].byte2=g;
						}
				}
			width=XTextWidth16(font, buf, (int) cnt);	// width in pixels
			_setDirtyRect(self,
						  cursor.x, cursor.y,
						  width,
						  font->ascent + font->descent);
			// handle character and word space
			[_textMatrix translateXBy:width+_characterSpace yBy:0.0];
		}
	else
		{ // use Freetype
			NSAffineTransform *trm=[NSAffineTransform transform];
#if 0
			NSLog(@"trm 1=%@", trm);
#endif
			[trm setTransformStruct:(NSAffineTransformStruct){ _horizontalScale, 0.0, 0.0, 1.0, 0.0, _rise }];
#if 0
			NSLog(@"trm 2=%@", trm);
			NSLog(@"textMatrix=%@", _textMatrix);
#endif
			[trm appendTransform:_textMatrix];
#if 0
			NSLog(@"trm 3=%@", trm);
#endif
			[trm appendTransform:_state->_ctm];
#if 0
			NSLog(@"trm 4=%@", trm);
#endif
			[_state->_font _drawAntialisedGlyphs:glyphs count:cnt inContext:self matrix:trm];
		}
}

- (void) _beginPage:(NSString *) title;
{ // can we (mis-)use that as setTitle to notify an X11 window manager?
	_characterSpace=0.0;	// reset text parameters to default
	_wordSpace=0.0;
	_scale=1.0;
	_leading=0.0;
	_textRenderMode=0;
	_rise=0.0;
	return;
}

- (void) _endPage; { return; }

#pragma mark Bitmap

- (void) _setFraction:(CGFloat) fraction;
{
	if(fraction > 1.0)
		_fraction=1.0;
	else if(fraction < 0.0)
		_fraction=0.0;
	else
		_fraction=fraction;	// save compositing fraction - fixme: convert to 0..256-integer
}

/* idea for sort of core-image extension
 *
 * struct filter { struct RGBA8 (*filter)(float x, float y); struct filter *input; other paramters }; describes a generic filter node
 *
 * now, build a chain of filter modules, i.e.
 * 0. scanline RGBA to output image
 * 1. composite with a second image (i.e. the image fetched from screen)
 * 2. rotate&scale coordinates
 * 3. sample/interpolate
 * 4. fetch as RGBA from given bitmap
 * could add color space transforms etc.
 *
 */

- (BOOL) _draw:(NSImageRep *) rep;
{ // composite into unit square using current CTM, current compositingOp & fraction etc.
	BOOL cached=[rep isKindOfClass:[NSCachedImageRep class]];
#if USE_XRENDER
	if(_picture)
		{
		Picture src;
		NSRect rect;
		NSAffineTransformStruct atms;
		if(cached)
			{ // we already have a Picture on the X-Server
				_NSX11GraphicsContext *c=(_NSX11GraphicsContext *) [[(NSCachedImageRep *) rep window] graphicsContext];
				src=c->_picture;
				rect=[(NSCachedImageRep *) rep rect];
			}
		else
			{ // send bitmap to X Server
				Window root=DefaultRootWindow(_display);	// first root window
				XRenderPictureAttributes pa;
				Pixmap pixmap;
				//				Pixmap alphapixmap;
				unsigned char *imagePlanes[5];
				NSBitmapFormat bitmapFormat=[(NSBitmapImageRep *) rep bitmapFormat];
				BOOL hasAlpha=[rep hasAlpha];
				BOOL isPlanar=[(NSBitmapImageRep *) rep isPlanar];
				BOOL isFlipped=[self isFlipped];
				BOOL calibrated;
				int width=[rep pixelsWide];
				int height=[rep pixelsHigh];
				int bytesPerRow=[(NSBitmapImageRep *) rep bytesPerRow];
				NSString *csp=[rep colorSpaceName];
				unsigned int buffersize;
				int fragment;
				XImage *image;
				//				XImage *alphaimage;
				GC gc;
				//				GC agc;
				union
				{
				unsigned long pixel;
				struct
					{
					unsigned char B, G, R, A;	// assumes B as MSB
					} components;
				} pixel;
				XGCValues gcValues={ 0 };
				int y;
				calibrated=[csp isEqualToString:NSCalibratedRGBColorSpace];
				[(NSBitmapImageRep *) rep getBitmapDataPlanes:imagePlanes];
				pixmap=XCreatePixmap(_display, root, width, height, 4*8);	// ARGB32 - picture
																			//				alphapixmap=XCreatePixmap(_display, root, width, height, 8);	// ARGB8 - alpha channel
				gc=XCreateGC(_display, pixmap, 0, &gcValues);
				//				agc=XCreateGC(_display, alphapixmap, 0, &gcValues);
				pa.repeat=1;
				//				pa.repeat=RepeatNormal;	// ???? repeat pattern image by default
				src=XRenderCreatePicture(_display, pixmap,
										 XRenderFindStandardFormat(_display, PictStandardARGB32),
										 CPRepeat, &pa);
#if 0
				{ // check if all pixels are filled
					XRenderColor c;
					c.red=c.green=c.blue=(int) rep;	// virtually randomize
					c.alpha=(65535 * 0.5);
					XRenderFillRectangle(_display, PictOpSrc, src, &c, 0, 0, width, height);	// prefill picture with semitransparent grey color
				}
#endif
				buffersize=width*height*4;			// 4 bytes per pixel
				if(buffersize > 128*128*4)
					buffersize=128*128*4;			// limit - note: we have 3 copies of the bitmap: NSBitmapRep, this buffer and the X server so we have to take care of memory footprint for large images
				fragment=buffersize/(4*width);
				image=XCreateImage(_display,
								   None,
								   32,			// depth
								   ZPixmap,
								   0,      // offset
								   objc_malloc(buffersize),
								   width,
								   height,
								   8,
								   4*width);
				/*
				 alphaimage=XCreateImage(_display,
				 None,
				 8,			// depth
				 ZPixmap,
				 0,      // offset
				 objc_malloc(1),
				 1,
				 1,
				 8,
				 1);	// make 1x1 pixel image for fraction
				 */
				for(y=0; y<height; y+=fragment)
					{ // fill next stride from imageplanes
						int dy;	// delta
						for(dy=0; dy < fragment; dy++)
							{ // all scan lines of this fragment
								int yy;
								int x;
								if(!isFlipped)	// ! because X11 is flipped
									yy=height-y-dy-1;
								else
									yy=y+dy;
								for(x=0; x<width; x++)
									{ // all pixels of each scan line
										if(bitmapFormat & NSFloatingPointSamplesBitmapFormat)
											;	// take 4 byte float instead of 8 bit char
										if(bitmapFormat & NSAlphaFirstBitmapFormat)
											;	// switch byte order to ARGB (we could simply switch image planes for planar)
										if(isPlanar)
											{ // planar
												int offset=x+bytesPerRow*yy;
												pixel.components.R=imagePlanes[0][offset];
												pixel.components.G=imagePlanes[1][offset];
												pixel.components.B=imagePlanes[2][offset];
												if(hasAlpha)
													pixel.components.A=imagePlanes[3][offset];
												else
													pixel.components.A=255;	// opaque
											}
										else
											{ // meshed
												int offset=(hasAlpha?4:3)*x + bytesPerRow*yy;
												pixel.components.R=imagePlanes[0][offset+0];	// a good compiler should be able to optimize this constant expression imagePlanes[0][offset]
												pixel.components.G=imagePlanes[0][offset+1];
												pixel.components.B=imagePlanes[0][offset+2];
												if(hasAlpha)
													pixel.components.A=imagePlanes[0][offset+3];
												else
													pixel.components.A=255;	// opaque
											}
										if(bitmapFormat & NSAlphaNonpremultipliedBitmapFormat)
											{ // not premultiplied
												pixel.components.R=(pixel.components.R*pixel.components.A)/255;
												pixel.components.G=(pixel.components.G*pixel.components.A)/255;
												pixel.components.B=(pixel.components.B*pixel.components.A)/255;
											}
										if(!calibrated)
											;	// convert color space
										XPutPixel(image, x, dy, pixel.pixel);
										//												XPutPixel(alphaimage, x, dy, src.A);
									}
							}
						XPutImage(_display, pixmap, gc, image, 0, 0, 0, y, width, fragment);	// send fragment to X-Server
																								//						XPutImage(_display, alphapixmap, agc, alphaimage, 0, 0, 0, y, width, fragment);	// send fragment to X-Server
					}
				XFreeGC(_display, gc);
				//			XFreeGC(_display, agc);
				XDestroyImage(image);
				//			XDestroyImage(alphaimage);
				XFreePixmap(_display, pixmap);	// no explicit reference required
												//			XFreePixmap(_display, alphapixmap);	// no explicit reference required
				rect=(NSRect) { NSZeroPoint, { width, height } };
			}
		if(!src)
			return NO;
		switch(_imageInterpolation) {
			case NSImageInterpolationNone:
				XRenderSetPictureFilter(_display, src, FilterFast, NULL, 0);
				break;
			case NSImageInterpolationDefault:
			case NSImageInterpolationLow:
				XRenderSetPictureFilter(_display, src, FilterGood, NULL, 0);
				break;
			case NSImageInterpolationHigh:
				XRenderSetPictureFilter(_display, src, FilterBest, NULL, 0);
				break;
		}
		atms=[_state->_ctm transformStruct];
		// we need the inverse to get rotation&scaling components
		// we should use the transform for the full CTM to allow subpixel positions !?!
		/*
		 XTransform transform = {{
		 {XDoubleToFixed (0.3), XDoubleToFixed (1.0), XDoubleToFixed (10.0) },
		 {XDoubleToFixed (-1.0), XDoubleToFixed (0.3), XDoubleToFixed (0.0) },
		 {0, 0, XDoubleToFixed (1.0)}}};
		 XRenderSetPictureTransform(display, _src, &transform);
		 */
		XRenderComposite(_display,
						 [self _XRenderPictOp],
						 src,				// src
						 None,			// mask - can we handle _fraction != 1.0 as a repeating Alpha mask??? We could then simply use a transparency color as the mask
						 _picture,	// dest
						 rect.origin.x, rect.origin.y,		// src origin
						 0, 0,		// mask origin
						 (int) atms.tX, (int) atms.tY, rect.size.width, rect.size.height		// dest origin + width, height
						 );
		if(!cached)
			XRenderFreePicture(_display, src);
		}
	else
#endif
		if(cached)
			{ // draw from cache (can't handle alpha in this case!)
				NSGraphicsContext *ctxt=[[(NSCachedImageRep *) rep window] graphicsContext];
				if(ctxt)
					{
					_NSGraphicsState *state=(_NSGraphicsState *) (ctxt->_graphicsState);	// cache window
					[self _copyBits:state fromRect:[(NSCachedImageRep *) rep rect] toPoint:NSZeroPoint];
					return YES;
					}
				return NO;
			}


	{ // composite into unit square using current CTM, current compositingOp & fraction etc.
		/* here we know:
		 - source bitmap: rep
		 - source rect: defined indirectly by clipping path
		 - clipping path (we only need to scan-line and interpolate visible pixels): _state->_clip
		 - compositing operation: _compositingOperation
		 - compositing fraction: _fraction
		 - interpolation algorithm: _imageInterpolation
		 - CTM (scales, rotates and translates): _state->_ctm
		 -- how do we know if we should really rotate or not? we don't need to know.
		 */
		static NSRect unitSquare={{ 0.0, 0.0 }, { 1.0, 1.0 }};
		NSString *csp;		// color space name
		int bytesPerRow;
		CGFloat width, height;	// source image width&height
		unsigned char *imagePlanes[5];
		NSPoint origin;			// drawing origin in X11 coords
		NSRect scanRect;		// dest on screen in X11 coords
		NSBitmapFormat bitmapFormat;
		BOOL hasAlpha;
		BOOL isPlanar;
		BOOL isPremultiplied;
		BOOL isAlphaFirst;
		BOOL isFlipped;
		BOOL calibrated;
		NSAffineTransform *atm;	// projection from X11 window-relative to bitmap coordinates
		NSAffineTransformStruct atms;
		XRectangle xScanRect;	// X11 coords where the full bitmap should be drawn (if there were no clipping)
		XRectangle xClipRect;	// same but clipped to clipping rect, window and screen - this is where we get the image from
		XImage *img;			// the X11 image data structure
		int x, y;				// current position within XImage
		NSPoint pnt;			// current pixel position in source bitmap
								// maybe, we should use 26.6 fixed point coordinates and convert to float only if needed!
		XGCValues values;
		BOOL mustFetch;		// must fetch existing image
		unsigned short fract=256.0*_fraction+0.5;
		if(fract > 256)
			fract=256;	// limit
		/*
		 * check if we can draw
		 */
		if(!rep)	// could check for NSBitmapImageRep subclass
			{
			NSLog(@"_draw: nil representation!");
			// raise exception?
			return NO;
			}
		bitmapFormat=[(NSBitmapImageRep *) rep bitmapFormat];
		isPremultiplied=(bitmapFormat&NSAlphaNonpremultipliedBitmapFormat) == 0;
		isAlphaFirst=(bitmapFormat&NSAlphaFirstBitmapFormat) != 0;
		if((bitmapFormat&~NSAlphaNonpremultipliedBitmapFormat) != 0)
			{ // can't handle alphafirst and float pixel formats
				NSLog(@"_draw: can't draw bitmap format %0x yet", [(NSBitmapImageRep *) rep bitmapFormat]);
				// raise exception
				return NO;
			}
		hasAlpha=[rep hasAlpha];
		isPlanar=[(NSBitmapImageRep *) rep isPlanar];
		bytesPerRow=(int) [(NSBitmapImageRep *) rep bytesPerRow];
		[(NSBitmapImageRep *) rep getBitmapDataPlanes:imagePlanes];
		csp=[rep colorSpaceName];
		calibrated=[csp isEqualToString:NSCalibratedRGBColorSpace];
		if(!calibrated && ![csp isEqualToString:NSDeviceRGBColorSpace])
			{
			NSLog(@"_draw: colorSpace %@ not supported!", csp);
			// raise exception?
			return NO;
			}
		/*
		 * locate where to draw in X11 coordinates
		 */
		isFlipped=[self isFlipped];
		origin=[_state->_ctm transformPoint:unitSquare.origin];	// determine real drawing origin in X11 coordinates
		scanRect=[_state->_ctm _transformRect:unitSquare];	// get bounding box for transformed unit square (may be bigger if rotated!)
#if 0
		NSLog(@"_draw: %@", rep);
		NSLog(@"context %@", self);
		NSLog(@"window number %d", _realWindow);
		NSLog(@"window %@", [NSWindow _windowForNumber:_realWindow]);
		NSLog(@"focusview %@", [NSView focusView]);
		NSLog(@"scan rect=%@", NSStringFromRect(scanRect));
#endif
		xScanRect.width=scanRect.size.width;
		xScanRect.height=scanRect.size.height;
		xScanRect.x=scanRect.origin.x;
		xScanRect.y=scanRect.origin.y;	// X11 specifies upper left corner
#if 0
		NSLog(@"  scan box=%@", NSStringFromXRect(xScanRect));
#endif
		/*
		 * clip to visible area (by clipping box, window and screen - note: window may be partially outside of screen)
		 */
#if 0
		NSLog(@"  clip box=%@", NSStringFromXRect(_state->_clipBox));
#endif
		xClipRect=xScanRect;
		XIntersectRect(&xClipRect, &_state->_clipBox);

		/*
		 FIXME: clip by Screen rect (if window is partially offscreen)
		 or we will get errors when trying to fetch the XImage

		 for this calculation use:
		 WidthOfScreen(_screen);			// screen width in pixels
		 HeightOfScreen(_screen);			// screen height in pixels
		 _windowRect

		 onscreenbox in window Koordinaten:
		 onscreen.x=MIN(0, -_windowRect.x)
		 onscreen.width=MAX(widthofscreen, windowRect.x+windowRect.width)
		 if(windowRect.x < 0)
		 box.x-=windowRect.x, box.width+=windowRect.x;

		 */

#if 0
		NSLog(@"  final clipped scan box=%@", NSStringFromXRect(xClipRect));
#endif
		if(xClipRect.width == 0 || xClipRect.height == 0)
			return YES;	// empty
		/*
		 * calculate reverse projection from XImage pixel coordinate to bitmap coordinates
		 */
		atm=[NSAffineTransform transform];
		[atm translateXBy:-origin.x yBy:-origin.y];		// we will scan through XImage which is thought to be relative to the drawing origin
		[atm prependTransform:_state->_ctm];
		[atm invert];				// get reverse mapping (XImage coordinates to unit square)
		width=[rep pixelsWide];
		height=[rep pixelsHigh];
		if(isFlipped)
			[atm scaleXBy:width yBy:height];	// and directly map to pixel coordinates
		else
			[atm scaleXBy:width yBy:-height];	// and directly map to flipped pixel coordinates
		atms=[atm transformStruct];	// extract raw coordinate transform
		/*
		 * get current screen image for compositing
		 */

		// struct context { atm, NSPoint currentPoint, int lastx, int lasty, rep, fract } - so that sampler can optimize advancements by float coordinates

		mustFetch=(atms.m12 != 0.0 || atms.m21 != 0.0 || !(atms.m11 == atms.m22 || atms.m11 == -atms.m22) ||
				   (hasAlpha && _compositingOperation != NSCompositeClear && _compositingOperation != NSCompositeCopy &&
					_compositingOperation != NSCompositeSourceIn && _compositingOperation != NSCompositeSourceOut));
		if(mustFetch)
			{ // if rotated or any alpha blending, we must really fetch the current image from our context
#if 0
				NSLog(@"fetch from screen alpha=%d", hasAlpha);
				NSLog(@"atms.m11=%lf", atms.m11);
				NSLog(@"atms.m22=%lf", atms.m22);
				NSLog(@"atms.m12=%lf", atms.m12);
				NSLog(@"atms.m21=%lf", atms.m21);
				NSLog(@"composite=%d", _compositingOperation);
#endif
				// FIXME: this is quite slow even if we have double buffering!
#if 0
				NSLog(@"XGetImage(%d, %d, %u, %u)", xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
#endif
#if 0
				NSLog(@"get %ld pixels image", xClipRect.width*xClipRect.height);
#endif
				img=XGetImage(_display, ((Window) _graphicsPort),
							  xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height,
							  AllPlanes, ZPixmap);
#if 0
				// NSBackingStoreRetained sometimes returns nil
				NSLog(@"got %p", img);
#endif
			}
		else
			{ // we can simply create a new rectangular image and don't use anything existing
				int screen_number=XScreenNumberOfScreen(_nsscreen->_screen);
#if 0
				NSLog(@"XCreateImage(%u, %u)", xClipRect.width, xClipRect.height);
#endif
				// FIXME: can we reuse this?
				img=XCreateImage(_display, DefaultVisual(_display, screen_number), DefaultDepth(_display, screen_number),
								 ZPixmap, 0, NULL,
								 xClipRect.width, xClipRect.height,
								 8, 0);
				if(img && !(img->data = objc_malloc(img->bytes_per_line*img->height)))
					{ // we failed to allocate a data area
						XDestroyImage(img);
						img=NULL;
					}
#if 0
				NSLog(@"created %p", img);
#endif
			}
		if(!img)
			{
			NSLog(@"bitmap: could not XGetImage or XCreateImage (%d, %d, %u, %u)", xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
			[[NSColor redColor] set];	// will set _gc
			XFillRectangle(_display, ((Window) _graphicsPort), _state->_gc, xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
			return NO;
			}
#if 0
		{
		int redshift;
		int greenshift;
		int blueshift;
		NSLog(@"width=%d height=%d", img->width, img->height);
		NSLog(@"xoffset=%d", img->xoffset);
		NSLog(@"format=%d", img->format);
		NSLog(@"byte_order=%d", img->byte_order);
		NSLog(@"bitmap_unit=%d", img->bitmap_unit);
		NSLog(@"bitmap_bit_order=%d", img->bitmap_bit_order);
		NSLog(@"bitmap_pad=%d", img->bitmap_pad);
		NSLog(@"depth=%d", img->depth);
		NSLog(@"bytes_per_line=%d", img->bytes_per_line);
		NSLog(@"bits_per_pixel=%d", img->bits_per_pixel);
		for(redshift=0; ((1<<redshift)&img->red_mask) == 0; redshift++);
		for(greenshift=0; ((1<<greenshift)&img->green_mask) == 0; greenshift++);
		for(blueshift=0; ((1<<blueshift)&img->blue_mask) == 0; blueshift++);
		NSLog(@"red_mask=%lu", img->red_mask);
		NSLog(@"green_mask=%lu", img->green_mask);
		NSLog(@"blue_mask=%lu", img->blue_mask);
		NSLog(@"redshift=%d", redshift);
		NSLog(@"greenshift=%d", greenshift);
		NSLog(@"blueshift=%d", blueshift);
		}
#endif
#if 0
		[[NSColor redColor] set];	// will set _gc
		XFillRectangle(_display, ((Window) _graphicsPort), _state->_gc, xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
#endif
		/*
		 * draw by scanning lines
		 */
		for(y=0; y<img->height; y++)
			{ // scan through the xClipRect
				struct RGBA8 src={0,0,0,255}, dest={0,0,0,255};	// initialize with clear color
				x=0;
				pnt.x=atms.m11*(x+xClipRect.x-xScanRect.x) + atms.m12*(y+xClipRect.y-xScanRect.y)+atms.tX;	// first bitmap point of this scan line
				pnt.y=atms.m21*(x+xClipRect.x-xScanRect.x) + atms.m22*(y+xClipRect.y-xScanRect.y)+atms.tY;
				for(; x<img->width; x++, pnt.x+=atms.m11, pnt.y+=atms.m21)	// track sampling point avoiding new calculations
					{
					if(mustFetch)
						dest=XGetRGBA8(img, x, y);	// get current image value
					if(_compositingOperation != NSCompositeClear)
						{ // get smoothed RGBA from bitmap
						  // we should pipeline this through core-image like filter modules
							switch(_imageInterpolation) {
								case NSImageInterpolationDefault:	// default is same as low
								case NSImageInterpolationLow:
								case NSImageInterpolationHigh: { // here we interpolate adjacent source points
									struct RGBA8 src00, src01, src10, src11;	// 4 sample points
									int xx=pnt.x;	// get integer part
									int yy=pnt.y;
									int wx=256*(pnt.x-xx);	// weight based on fractional part
									int wy=256*(pnt.y-yy);
									int w00=(256-wx)*(256-wy);
									int w01=(256-wx)*wy;
									int w10=wx*(256-wy);
									int w11=wx*wy;
									if(w00 != 0)
										src00=getPixel(xx, yy, width, height,
													   /*
														bitsPerSample,
														samplesPerPixel,
														bitsPerPixel,
														bitmapFormat
														*/
													   bytesPerRow,
													   isPlanar, hasAlpha,
													   isPremultiplied, isAlphaFirst,
													   imagePlanes);
									if(w01 != 0)
										src01=getPixel(xx, yy+1, width, height,
													   /*
														bitsPerSample,
														samplesPerPixel,
														bitsPerPixel,
														bitmapFormat
														*/
													   bytesPerRow,
													   isPlanar, hasAlpha,
													   isPremultiplied, isAlphaFirst,
													   imagePlanes);
									if(w10 != 0)
										src10=getPixel(xx+1, yy, width, height,
													   /*
														bitsPerSample,
														samplesPerPixel,
														bitsPerPixel,
														bitmapFormat
														*/
													   bytesPerRow,
													   isPlanar, hasAlpha,
													   isPremultiplied, isAlphaFirst,
													   imagePlanes);
									if(w11 != 0)
										src11=getPixel(xx+1, yy+1, width, height,
													   /*
														bitsPerSample,
														samplesPerPixel,
														bitsPerPixel,
														bitmapFormat
														*/
													   bytesPerRow,
													   isPlanar, hasAlpha,
													   isPremultiplied, isAlphaFirst,
													   imagePlanes);
									// FIXME! contribution is a mix of all 4 values
									src.R=(w00*src00.R+w10*src10.R+w01*src01.R+w11*src11.R)/65536;	// weighted interpolation
									src.G=(w00*src00.G+w10*src10.G+w01*src01.G+w11*src11.G)/65536;
									src.B=(w00*src00.B+w10*src10.B+w01*src01.B+w11*src11.B)/65536;
									src.A=(w00*src00.A+w10*src10.A+w01*src01.A+w11*src11.A)/65536;
									break;
								}
								case NSImageInterpolationNone: { // no interpolation
									src=getPixel((int) pnt.x, (int) pnt.y, width, height,
												 /*
												  bitsPerSample,
												  samplesPerPixel,
												  bitsPerPixel,
												  bitmapFormat
												  */
												 bytesPerRow,
												 isPlanar, hasAlpha,
												 isPremultiplied, isAlphaFirst,
												 imagePlanes);
									break;
								}
							}
							if(fract != 256)
								{ // dim source image by fraction
									src.R=(fract*src.R)>>8;
									src.G=(fract*src.G)>>8;
									src.B=(fract*src.B)>>8;
									src.A=(fract*src.A)>>8;
								}
						}
					composite(_compositingOperation, &src, &dest);
					XSetRGBA8(img, x, y, &dest);
					}
			}
		/*
		 * draw to screen
		 * FIXME: this is quite slow if we don't have double buffering
		 */
#if 0
		NSLog(@"XPutImage(%d, %d, %u, %u)", xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
#endif
		values.function=GXcopy;
		XChangeGC(_display, _state->_gc, GCFunction, &values);	// use X11 copy compositing
#if 0
		NSLog(@"put %ld pixels image", xClipRect.width*xClipRect.height);
#endif
		XPutImage(_display, ((Window) _graphicsPort), _state->_gc, img, 0, 0, xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
		XDestroyImage(img);
		_setDirtyRect(self, xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
#if 0
		[[NSColor redColor] set];	// will change _gc
		XDrawRectangle(_display, ((Window) _graphicsPort), _state->_gc, xClipRect.x, xClipRect.y, xClipRect.width, xClipRect.height);
#endif
	}
	return YES;
}

- (void) _copyBits:(void *) srcGstate fromRect:(NSRect) srcRect toPoint:(NSPoint) destPoint;
{ // copy srcRect using CTM from (_NSX11GraphicsState *) srcGstate to destPoint transformed by current CTM
	XRectangle src, dest;
#if 0
	NSLog(@"_copyBits from %@ to %@", NSStringFromRect(srcRect), NSStringFromPoint(destPoint));
	NSLog(@"  clip box %@", NSStringFromRect([self _clipBox]));
#endif
	if(_picture)
		{
		// use XRender compositing from src to dest _picture (may be the same) and PictOpSrc
		}
	else
		{
		[self _setCompositing];
		srcRect.origin=[((_NSX11GraphicsState *) srcGstate)->_ctm transformPoint:srcRect.origin];
		srcRect.size=[((_NSX11GraphicsState *) srcGstate)->_ctm transformSize:srcRect.size];
		destPoint=[_state->_ctm transformPoint:destPoint];
		src.x=srcRect.origin.x;
		src.y=srcRect.origin.y;
		src.width=srcRect.size.width;
		dest.width=src.width;
		dest.height=src.height;
		if(srcRect.size.height < 0)
			{
			src.height=-srcRect.size.height;	// negative if not flipped
			src.y-=src.height;					// caller expects he has specified bottom+left of rect
			dest.y=(int)(destPoint.y)-dest.height;
			}
		else
			{
			src.height=srcRect.size.height;
			dest.y=destPoint.y;
			}
		dest.x=destPoint.x;
#if 0
		NSLog(@"  X11 %@ to %@", NSStringFromXRect(src), NSStringFromXRect(dest));
		NSLog(@"  src-win=%d", (((_NSGraphicsState *) srcGstate)->_context->_graphicsPort));
		NSLog(@"  dest-win=%d", _graphicsPort);
#endif
#if 0
		XSetForeground(_display, gc, 0x555555);
		XFillRectangles(_display, ((Window) _graphicsPort), gc, &src, 1);
		_setDirtyRect(self, src.x, src.y, src.width, src.height);
#endif
#if 0
		XSetForeground(_display, gc, 0xaaaaaa);
		XFillRectangles(_display, ((Window) _graphicsPort), gc, &dest, 1);
		_setDirtyRect(self, dest.x, dest.y, dest.width, dest.height);
#endif
		XCopyArea(_display,
				  (Window) (((_NSGraphicsState *) srcGstate)->_context->_graphicsPort),	// source window/bitmap
				  ((Window) _graphicsPort),
				  _state->_gc,	// defines clipping etc.
				  src.x, src.y,
				  src.width, src.height,
				  dest.x, dest.y);
		_setDirtyRect(self, dest.x, dest.y, dest.width, dest.height);
		}
}

#pragma mark WindowControl

- (NSInteger) _windowNumber; { return _realWindow; }

- (void) _orderWindow:(NSWindowOrderingMode) place relativeTo:(NSInteger) otherWin;
{ // NSWindow frontend should have identified the otherWin number from the global window list or pass 0 if global front/back
	XWindowChanges values;
	NSWindow *win=[NSApp windowWithWindowNumber:_realWindow];
#if 1
	NSLog(@"_orderWindow: %d %@ %d%@", (int)_realWindow, (place==NSWindowOut?@"out":(place==NSWindowAbove?@"above":@"below")), (int)otherWin, [win isVisible]?@" visible":@"");
#if 0
	{
	char bfr[256];
	sprintf(bfr, "/usr/X11/bin/xprop -id %d", (int) _realWindow);
	system(bfr);
	sprintf(bfr, "/usr/X11/bin/xprop -id %d", otherWin);
	if(otherWin)
		system(bfr);
	}
#endif
#endif
	if(!win)
		{
		NSLog(@"window not known");
		return;
		}
	if([win isMiniaturized])	// FIXME: used as special trick not to really map the window during init
		return;
	if(_realWindow == otherWin)
		{
		NSLog(@"can't order relative to self");	// already total front or back
		return;
		}
	switch(place) {
		case NSWindowOut:
			if([win isVisible])
				XUnmapWindow(_display, _realWindow);
			break;
		case NSWindowAbove:
			if(![win isVisible])
				XMapWindow(_display, _realWindow);	// if not yet
			values.sibling=(Window) otherWin;		// 0 will order front
			values.stack_mode=Above;
			XConfigureWindow(_display, _realWindow, (otherWin?(CWStackMode|CWSibling):CWStackMode), &values);
			break;
		case NSWindowBelow:
			if(![win isVisible])
				XMapWindow(_display, _realWindow);	// if not yet
			values.sibling=(Window) otherWin;		// 0 will order back
			values.stack_mode=Below;
			XConfigureWindow(_display, _realWindow, (otherWin?(CWStackMode|CWSibling):CWStackMode), &values);
			break;
	}
#if 0
	{ // test code
		NSPoint points[4] = { { 10.0, 10.0 } , { 20.0, 50.0 } , { 100.0, 0.0 } , { 80.0, 50.0 } };
		[self _setFillColor:[NSColor greenColor]];
		[self _renderTrapezoid:points];
	}
#endif
	// could also use XMaskEvent(_display, SubstructureNotifyMask, _realWindow) and wait for a MapNotify!
	while([self flushGraphics], (place == NSWindowOut)?[win isVisible]:![win isVisible])
		{ // process incoming X11 events until window becomes (in)visible - but prevent timers and other delegates to modify the window or recursively call orderFront
			[[NSRunLoop currentRunLoop] runMode:/*NSEventTrackingRunLoopMode*/@"NSX11GraphicsContextMode" beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];	// wait some fractions of a second...
		}
#if 1
	NSLog(@"_orderWindow done");
#endif
}

- (void) _miniaturize;
{
	NSLog(@"_miniaturize");
	//	Status XIconifyWindow(_display, _realWindow, _screen_number)
}

- (void) _setOrigin:(NSPoint) point;
{ // note: it is the optimization task of NSWindow to call this only if setFrame really changes the origin
#if 0
	NSLog(@"_setOrigin:%@", NSStringFromPoint(point));
#endif
	_windowRect.origin=[(NSAffineTransform *)(_nsscreen->_screen2X11) transformPoint:point];
	_xRect.x=NSMinX(_windowRect);
	_xRect.y=NSMaxY(_windowRect)+WINDOW_MANAGER_TITLE_HEIGHT;
	XMoveWindow(_display, _realWindow,
				_xRect.x,
				_xRect.y);
	[self _setSizeHints];
}

- (void) _setOriginAndSize:(NSRect) frame;
{ // note: it is the optimization task of NSWindow to call this only if setFrame really changes origin or size
	unsigned newWidth, newHeight;
#if 0
	NSLog(@"_setOriginAndSize:%@", NSStringFromRect(frame));
#endif
	_windowRect.origin=[(NSAffineTransform *)(_nsscreen->_screen2X11) transformPoint:frame.origin];
	_windowRect.size=[(NSAffineTransform *)(_nsscreen->_screen2X11) transformSize:frame.size];
	_xRect.x=NSMinX(_windowRect);
	_xRect.y=NSMaxY(_windowRect)+WINDOW_MANAGER_TITLE_HEIGHT;
	// compare with previous and don't allocate a new double buffer
	newWidth=NSWidth(_windowRect);
	newHeight=NSMinY(_windowRect)-NSMaxY(_windowRect);	// _windowRect.size.heigh is negative
	if(newWidth == 0) newWidth=48;
	if(newHeight == 0) newHeight=49;
	if(newWidth != _xRect.width || newHeight != _xRect.height)
		{ // did change size
			XMoveResizeWindow(_display, _realWindow,
							  _xRect.x,
							  _xRect.y,
							  _xRect.width=newWidth,
							  _xRect.height=newHeight);
			if(_isDoubleBuffered(self))
				{ // resize backing store buffer
					XWindowAttributes xwattrs;
#if 1
					NSLog(@"resize backing store buffer { %u %u }", _xRect.width, _xRect.height);
#endif
					XGetWindowAttributes(_display, _realWindow, &xwattrs);
					XFreePixmap(_display, (Pixmap) _graphicsPort);
					_graphicsPort=(void *) XCreatePixmap(_display, _realWindow, _xRect.width, _xRect.height, xwattrs.depth);
#if 0
					XCopyArea(_display,
							  win,	// should be old pixmap...
							  (Window) _graphicsPort,
							  _state->_gc,
							  0, 0,
							  _xRect.width, _xRect.height,
							  0, 0);
#endif
				}
		}
	else
		XMoveWindow(_display, _realWindow, _xRect.x, _xRect.y);
	[self _setSizeHints];
}

- (void) _setTitle:(NSString *) string;
{ // note: it is the task of NSWindow to call this only if setTitle really changes the title
	XTextProperty windowName;
	const char *newTitle = [string UTF8String];
	XStringListToTextProperty((char**) &newTitle, 1, &windowName);
	XSetWMName(_display, _realWindow, &windowName);
	XSetWMIconName(_display, _realWindow, &windowName);
	// XStoreName???
}

- (void) _setLevel:(NSInteger) level andStyle:(NSInteger) mask;
{ // note: it is the optimization task of NSWindow to call this only if setLevel really changes the level
	GSAttributes wmattrs;
#if 0
	NSLog(@"setLevel %d of window %d (%d)", level, _realWindow, _realWindow);
#endif
	wmattrs.window_level = (unsigned int) level;
	wmattrs.flags = GSWindowStyleAttr|GSWindowLevelAttr;
	wmattrs.window_style = (mask & GSAllWindowMask);		// set WindowMaker WM window style hints
	XChangeProperty(_display, _realWindow, _windowDecorAtom, _windowDecorAtom,
					32, PropModeReplace, (unsigned char *)&wmattrs,
					sizeof(GSAttributes)/sizeof(CARD32));
}

- (void) _makeKeyWindow;
{
	//	fprintf(stderr, "_makeKeyWindow %d\n", _realWindow);
	XSetInputFocus(_display, _realWindow, RevertToNone, CurrentTime);
}

- (NSRect) _frame;
{ // get current window frame as on screen (might have been moved by window manager)
	int x, y;
	unsigned width, height;
	NSAffineTransform *ictm=[_nsscreen _X112screen];
	XGetGeometry(_display, _realWindow, NULL, &x, &y, &width, &height, NULL, NULL);
	return (NSRect){[ictm transformPoint:NSMakePoint(x, y)], [ictm transformSize:NSMakeSize(width, -height)]};	// translate to screen coordinates!
}

- (NSRect) _clipBox;
{
	XRectangle box;
	NSAffineTransform *ictm=[_nsscreen _X112screen];
	if(!_state->_clip)
		return (NSRect) { NSZeroPoint, { FLT_MAX, FLT_MAX } };	// not clipped
	XClipBox(_state->_clip, &box);
#if 0
	NSLog(@" X clip box %@", NSStringFromXRect(box));
#endif
	return (NSRect){[ictm transformPoint:NSMakePoint(box.x, box.y)], [ictm transformSize:NSMakeSize(box.width, -box.height)]};	// translate to screen coordinates!
}

- (void) _setDocumentEdited:(BOOL)flag					// mark doc as edited
{
	GSAttributes attrs;
	memset(&attrs, 0, sizeof(GSAttributes));
	attrs.extra_flags = (flag) ? GSDocumentEditedFlag : 0;
	attrs.flags = GSExtraFlagsAttr;						// set WindowMaker WM window style hints
	XChangeProperty(_display, _realWindow,
					_windowDecorAtom, _windowDecorAtom,
					32, PropModeReplace, (unsigned char *)&attrs,
					sizeof(GSAttributes)/sizeof(CARD32));
}

- (_NSGraphicsState *) _copyGraphicsState:(_NSGraphicsState *) state;
{
	XGCValues values;
	_NSX11GraphicsState *new=(_NSX11GraphicsState *) objc_malloc(sizeof(*new));	// this does not clear all components!
	new->_gc=XCreateGC(_display, ((Window) _graphicsPort), 0l, &values);	// create a fresh GC without values
	if(state)
		{ // copy
			new->_font=[((_NSX11GraphicsState *) state)->_font retain];
			new->_ctm=[((_NSX11GraphicsState *) state)->_ctm copyWithZone:NSDefaultMallocZone()];
			XCopyGC(_display, ((_NSX11GraphicsState *) state)->_gc,
					GCFunction |
					GCPlaneMask |
					GCForeground |
					GCBackground |
					GCLineWidth	|
					GCLineStyle	|
					GCCapStyle |
					GCJoinStyle	|
					GCFillStyle	|
					// GCFillRule
					// GCTile
					// GCStipple
					// GCTileStipXOrigin
					// GCTileStipYOrigin
					GCFont |
					GCSubwindowMode	|
					GCGraphicsExposures	|
					GCClipXOrigin |
					GCClipYOrigin |
					GCClipMask
					// GCDashOffset
					// GCDashList
					// GCArcMode
					, new->_gc);	// copy from existing
			if(((_NSX11GraphicsState *) state)->_clip)
				{
				new->_clip=XCreateRegion();	// create new region
				XUnionRegion(((_NSX11GraphicsState *) state)->_clip, ((_NSX11GraphicsState *) state)->_clip, new->_clip);	// copy clipping region
				new->_clipBox=((_NSX11GraphicsState *) state)->_clipBox;
				}
			else
				new->_clip=NULL;	// not clipped
			new->_fillColor=[((_NSX11GraphicsState *) state)->_fillColor retain];
			new->_strokeColor=[((_NSX11GraphicsState *) state)->_strokeColor retain];
		}
	else
		{ // alloc
			new->_ctm=nil;		// no initial screen transformation (set by first lockFocus)
			new->_clip=NULL;	// not clipped
			new->_font=nil;
			new->_fillColor=nil;
			new->_strokeColor=nil;
		}
	return (_NSGraphicsState *) new;
}

- (void) restoreGraphicsState;
{
	if(!_graphicsState)
		return;
	[_state->_fillColor release], _state->_fillColor=nil;
	[_state->_strokeColor release], _state->_strokeColor=nil;
	if(_state->_ctm)
		[_state->_ctm release], _state->_ctm=NULL;
	if(_state->_clip)
		XDestroyRegion(_state->_clip), _state->_clip=NULL;
	if(_state->_gc)
		XFreeGC(_display, _state->_gc), _state->_gc=NULL;
	if(_state->_font)
		[_state->_font release];
	[super restoreGraphicsState];
#if 0
	{
	XRectangle box;
	if(_state && _state->_clip)
		{
		XClipBox(_state->_clip, &box);
		NSLog(@"clip     box=%@", NSStringFromXRect(box));
		}
	else
		NSLog(@"no clip");
	}
#endif
}

- (NSColor *) _readPixel:(NSPoint) location;
{ // read single pixel from screen
	XImage *img;
	struct RGBA8 pix;
	NSColor *c;
	location=[_state->_ctm transformPoint:location];
	// clip to window?
	img=XGetImage(_display, _realWindow,
				  location.x, location.y, 1, 1,
				  AllPlanes, ZPixmap);
	pix=XGetRGBA8(img, 0, 0);
	XDestroyImage(img);
	c=[NSColor colorWithDeviceRed:pix.R/255.0 green:pix.G/255.0 blue:pix.B/255.0 alpha:pix.A/255.0];	// convert pixel to NSColor
	return c;
}

-  (void) _initBitmap:(NSBitmapImageRep *) bitmap withFocusedViewRect:(NSRect) rect;
{
	XImage *img;
	rect.origin=[_state->_ctm transformPoint:rect.origin];
	rect.size=[_state->_ctm transformSize:rect.size];
	// clip to window?
	img=XGetImage(_display, _realWindow,
				  rect.origin.x, rect.origin.y, rect.size.width, -rect.size.height,
				  AllPlanes, ZPixmap);
	// FIXME: copy pixels to bitmap
	XDestroyImage(img);
}

- (void) flushGraphics;
{
#if 1
	NSLog(@"X11 flushGraphics");
#endif
	if(_isDoubleBuffered(self) && _dirty.width > 0 && _dirty.height > 0)
		{ // copy dirty area (if any) from back to front buffer
#if 1
			NSLog(@"flushing backing store buffer: %@ of %@", NSStringFromXRect(_dirty), self);
#endif
			if(!_neutralGC)
				_neutralGC=XCreateGC(_display, (Window) _graphicsPort, 0, NULL);	// create a default GC
			XCopyArea(_display,
					  ((Window) _graphicsPort),
					  _realWindow,
					  _neutralGC,
					  _dirty.x, _dirty.y,
					  _dirty.width, _dirty.height,
					  _dirty.x, _dirty.y);
			_dirty=(XRectangle){ 0, 0, 0, 0 };	// clear
		}
	XFlush(_display);
#if 0
	NSLog(@"events %d", XPending(_display));
#endif
	[_NSX11Screen _handleNewEvents];	// flush and process any pending events
}

#if OLD
- (NSPoint) _mouseLocationOutsideOfEventStream;
{ // Return mouse location in receiver's base coords ignoring the event loop
	Window root, child;
	int root_x, root_y, window_x, window_y;
	unsigned int mask;	// modifier and mouse keys
	if(!XQueryPointer(_display, _realWindow, &root, &child, &root_x, &root_y, &window_x, &window_y, &mask))
		return NSZeroPoint;
	if(_scale != 1.0)
		return NSMakePoint(window_x/_scale, (_xRect.height-window_y)/_scale);
	return NSMakePoint(window_x, _xRect.height-window_y);
}
#endif

- (void) _grabKey:(int) keycode;
{
	int r=XGrabKey(_display, keycode, AnyModifier, _realWindow, True, GrabModeAsync, GrabModeAsync);
	if(r)
		NSLog(@"XGrabKey returns %d", r);
	/* XUngrabKey(display, keycode, modifiers, grab_window)
	 Display *display;
	 int keycode;
	 unsigned int modifiers;
	 Window grab_window; */
}

@end /* _NSX11GraphicsContext */

static unsigned short xKeyCode(XEvent *xEvent, KeySym keysym, unsigned int *eventModFlags)
{ // translate key codes to NSEvent key codes and add some modifier flags
	unsigned short keyCode = 0;

#if 1
	NSLog(@"xkeycode: %d", xEvent->xkey.keycode);
#endif
#if TRASH	// this is only on Neo...
	switch(xEvent->xkey.keycode) { // specials
		case 8:	// AUX button on Neo1973
			*eventModFlags |= NSFunctionKeyMask;
			return NSF1FunctionKey;
	}
#endif
	switch(keysym) {
		case XK_Return:
		case XK_KP_Enter:
			return '\r';
		case XK_Linefeed:
			return '\r';
		case XK_Tab:
			return '\t';
		case XK_space:
			return ' ';
	}
	if ((keysym >= XK_F1) && (keysym <= XK_F35))
		{ // if a function key was pressed
			*eventModFlags |= NSFunctionKeyMask;
			switch(keysym) { // FIXME: why not use keysym here??
				case XK_F1:  keyCode = NSF1FunctionKey;  break;
				case XK_F2:  keyCode = NSF2FunctionKey;  break;
				case XK_F3:  keyCode = NSF3FunctionKey;  break;
				case XK_F4:  keyCode = NSF4FunctionKey;  break;
				case XK_F5:  keyCode = NSF5FunctionKey;  break;
				case XK_F6:  keyCode = NSF6FunctionKey;  break;
				case XK_F7:  keyCode = NSF7FunctionKey;  break;
				case XK_F8:  keyCode = NSF8FunctionKey;  break;
				case XK_F9:  keyCode = NSF9FunctionKey;  break;
				case XK_F10: keyCode = NSF10FunctionKey; break;
				case XK_F11: keyCode = NSF11FunctionKey; break;
				case XK_F12: keyCode = NSF12FunctionKey; break;
				case XK_F13: keyCode = NSF13FunctionKey; break;
				case XK_F14: keyCode = NSF14FunctionKey; break;
				case XK_F15: keyCode = NSF15FunctionKey; break;
				case XK_F16: keyCode = NSF16FunctionKey; break;
				case XK_F17: keyCode = NSF17FunctionKey; break;
				case XK_F18: keyCode = NSF18FunctionKey; break;
				case XK_F19: keyCode = NSF19FunctionKey; break;
				case XK_F20: keyCode = NSF20FunctionKey; break;
				case XK_F21: keyCode = NSF21FunctionKey; break;
				case XK_F22: keyCode = NSF22FunctionKey; break;
				case XK_F23: keyCode = NSF23FunctionKey; break;
				case XK_F24: keyCode = NSF24FunctionKey; break;
				case XK_F25: keyCode = NSF25FunctionKey; break;
				case XK_F26: keyCode = NSF26FunctionKey; break;
				case XK_F27: keyCode = NSF27FunctionKey; break;
				case XK_F28: keyCode = NSF28FunctionKey; break;
				case XK_F29: keyCode = NSF29FunctionKey; break;
				case XK_F30: keyCode = NSF30FunctionKey; break;
				case XK_F31: keyCode = NSF31FunctionKey; break;
				case XK_F32: keyCode = NSF32FunctionKey; break;
				case XK_F33: keyCode = NSF33FunctionKey; break;
				case XK_F34: keyCode = NSF34FunctionKey; break;
				case XK_F35: keyCode = NSF35FunctionKey; break;
				default:								 break;
			}
		}
	else if ((keysym > XK_KP_Space) && (keysym < XK_KP_9)) 		// If the key press
		{													// originated from
			*eventModFlags |= NSNumericPadKeyMask;				// the key pad

			switch(keysym) {
				case XK_KP_F1:        keyCode = NSF1FunctionKey;         break;
				case XK_KP_F2:        keyCode = NSF2FunctionKey;         break;
				case XK_KP_F3:        keyCode = NSF3FunctionKey;         break;
				case XK_KP_F4:        keyCode = NSF4FunctionKey;         break;
				case XK_KP_Home:      keyCode = NSHomeFunctionKey;       break;
				case XK_KP_Left:      keyCode = NSLeftArrowFunctionKey;  break;
				case XK_KP_Up:        keyCode = NSUpArrowFunctionKey;    break;
				case XK_KP_Right:     keyCode = NSRightArrowFunctionKey; break;
				case XK_KP_Down:      keyCode = NSDownArrowFunctionKey;  break;
				case XK_KP_Page_Up:   keyCode = NSPageUpFunctionKey;     break;
				case XK_KP_Page_Down: keyCode = NSPageDownFunctionKey;   break;
				case XK_KP_End:       keyCode = NSEndFunctionKey;        break;
				case XK_KP_Begin:     keyCode = NSBeginFunctionKey;      break;
				case XK_KP_Insert:    keyCode = NSInsertFunctionKey;     break;
				case XK_KP_Delete:    keyCode = NSDeleteFunctionKey;     break;
				default:												 break;
			}
		}

	else
		{
		switch(keysym) {
			case XK_BackSpace:  keyCode = NSBackspaceKey;			break;
			case XK_Delete: 	keyCode = NSDeleteFunctionKey;		break;
			case XK_Home:		keyCode = NSHomeFunctionKey;		break;
			case XK_Left:		keyCode = NSLeftArrowFunctionKey;	break;
			case XK_Up:  		keyCode = NSUpArrowFunctionKey;		break;
			case XK_Right:		keyCode = NSRightArrowFunctionKey;	break;
			case XK_Down:		keyCode = NSDownArrowFunctionKey;	break;
			case XK_Prior:		keyCode = NSPrevFunctionKey;		break;
			case XK_Next:  		keyCode = NSNextFunctionKey;		break;
			case XK_End:  		keyCode = NSEndFunctionKey;			break;
			case XK_Begin:  	keyCode = NSBeginFunctionKey;		break;
			case XK_Select:		keyCode = NSSelectFunctionKey;		break;
			case XK_Print:  	keyCode = NSPrintScreenFunctionKey;	break;
			case XK_Execute:  	keyCode = NSExecuteFunctionKey;		break;
			case XK_Insert:  	keyCode = NSInsertFunctionKey;		break;
			case XK_Undo: 		keyCode = NSUndoFunctionKey;		break;
			case XK_Redo:		keyCode = NSRedoFunctionKey;		break;
			case XK_Menu:		keyCode = NSMenuFunctionKey;		break;
			case XK_Find:  		keyCode = NSFindFunctionKey;		break;
			case XK_Help:		keyCode = NSHelpFunctionKey;		break;
			case XK_Break:  	keyCode = NSBreakFunctionKey;		break;
				//			case XK_Mode_switch:keyCode = NSModeSwitchFunctionKey;	break;
			case XK_Sys_Req:	keyCode = NSSysReqFunctionKey;		break;
			case XK_Scroll_Lock:keyCode = NSScrollLockFunctionKey;	break;
			case XK_Pause:  	keyCode = NSPauseFunctionKey;		break;
			case XK_Clear:		keyCode = NSClearDisplayFunctionKey;break;
				// NSPageUpFunctionKey
				// NSPageDownFunctionKey
				// NSResetFunctionKey
				// NSStopFunctionKey
				// NSUserFunctionKey
				// and others
			default:												break;
		}

		if(!keyCode)
			{ // no keycode - flag keys to handle
				if ((keysym == XK_Shift_L) || (keysym == XK_Shift_R))
					*eventModFlags |= NSShiftKeyMask;
				else if ((keysym == XK_Control_L) || (keysym == XK_Control_R))
					*eventModFlags |= NSControlKeyMask;
				else if ((keysym == XK_Alt_R) || (keysym == XK_Meta_R))
					*eventModFlags |= NSAlternateKeyMask;
				else if ((keysym == XK_Alt_L) || (keysym == XK_Meta_L))
					*eventModFlags |= NSCommandKeyMask | NSAlternateKeyMask;
				else if (keysym == XK_Mode_switch)
					*eventModFlags |= NSCommandKeyMask | NSAlternateKeyMask;
			}
		}

	if (((keysym > XK_KP_Space) && (keysym <= XK_KP_9)) ||
		((keysym > XK_space) && (keysym <= XK_asciitilde)))
		{ // translate into key code

		}

	return keyCode;
}

// determine which modifier
// keys (Command, Control,
// Shift, etc..) were held down
// while the event occured.

static unsigned int	xKeyModifierFlags(unsigned int state)
{
	unsigned int flags = 0;

	if (state & ControlMask)
		flags |= NSControlKeyMask;

	if (state & ShiftMask)
		flags |= NSShiftKeyMask;

	if (state & Mod1Mask)
		flags |= NSAlternateKeyMask;	// not recognized??

	if (state & Mod2Mask)
		flags |= NSCommandKeyMask;

	if (state & Mod3Mask)
		flags |= NSAlphaShiftKeyMask;

	if (state & Mod4Mask)
		flags |= NSHelpKeyMask;

	if (state & Mod5Mask)
		flags |= NSControlKeyMask;
	// we don't handle the NSNumericPadKeyMask and NSFunctionKeyMask here
#if 0
	NSLog(@"state=%x flags=%x", state, flags);
#endif
	return flags;
}

static void X11ErrorHandler(Display *display, XErrorEvent *error_event)
{
	static struct { char *name; int major; } requests[]={
		{ "CreateWindow", 1 },
		{ "ChangeWindowAttributes", 2 },
		{ "GetWindowAttributes", 3 },
		{ "DestroyWindow", 4 },
		{ "DestroySubwindows", 5 },
		{ "ChangeSaveSet", 6 },
		{ "ReparentWindow", 7 },
		{ "MapWindow", 8 },
		{ "MapSubwindows", 9 },
		{ "UnmapWindow", 10 },
		{ "UnmapSubwindows", 11 },
		{ "ConfigureWindow", 12 },
		{ "CirculateWindow", 13 },
		{ "GetGeometry", 14 },
		{ "QueryTree", 15 },
		{ "InternAtom", 16 },
		{ "GetAtomName", 17 },
		{ "ChangeProperty", 18 },
		{ "DeleteProperty", 19 },
		{ "GetProperty", 20 },
		{ "ListProperties", 21 },
		{ "SetSelectionOwner", 22 },
		{ "GetSelectionOwner", 23 },
		{ "ConvertSelection", 24 },
		{ "SendEvent", 25 },
		{ "GrabPointer", 26 },
		{ "UngrabPointer", 27 },
		{ "GrabButton", 28 },
		{ "UngrabButton", 29 },
		{ "ChangeActivePointerGrab", 30 },
		{ "GrabKeyboard", 31 },
		{ "UngrabKeyboard", 32 },
		{ "GrabKey", 33 },
		{ "UngrabKey", 34 },
		{ "AllowEvents", 35 },
		{ "GrabServer", 36 },
		{ "UngrabServer", 37 },
		{ "QueryPointer", 38 },
		{ "GetMotionEvents", 39 },
		{ "TranslateCoords", 40 },
		{ "WarpPointer", 41 },
		{ "SetInputFocus", 42 },
		{ "GetInputFocus", 43 },
		{ "QueryKeymap", 44 },
		{ "OpenFont", 45 },
		{ "CloseFont", 46 },
		{ "QueryFont", 47 },
		{ "QueryTextExtents", 48 },
		{ "ListFonts", 49 },
		{ "ListFontsWithInfo", 50 },
		{ "SetFontPath", 51 },
		{ "GetFontPath", 52 },
		{ "CreatePixmap", 53 },
		{ "FreePixmap", 54 },
		{ "CreateGC", 55 },
		{ "ChangeGC", 56 },
		{ "CopyGC", 57 },
		{ "SetDashes", 58 },
		{ "SetClipRectangles", 59 },
		{ "FreeGC", 60 },
		{ "ClearArea", 61 },
		{ "CopyArea", 62 },
		{ "CopyPlane", 63 },
		{ "PolyPoint", 64 },
		{ "PolyLine", 65 },
		{ "PolySegment", 66 },
		{ "PolyRectangle", 67 },
		{ "PolyArc", 68 },
		{ "FillPoly", 69 },
		{ "PolyFillRectangle", 70 },
		{ "PolyFillArc", 71 },
		{ "PutImage", 72 },
		{ "GetImage", 73 },
		{ "PolyText8", 74 },
		{ "PolyText16", 75 },
		{ "ImageText8", 76 },
		{ "ImageText16", 77 },
		{ "CreateColormap", 78 },
		{ "FreeColormap", 79 },
		{ "CopyColormapAndFree", 80 },
		{ "InstallColormap", 81 },
		{ "UninstallColormap", 82 },
		{ "ListInstalledColormaps", 83 },
		{ "AllocColor", 84 },
		{ "AllocNamedColor", 85 },
		{ "AllocColorCells", 86 },
		{ "AllocColorPlanes", 87 },
		{ "FreeColors", 88 },
		{ "StoreColors", 89 },
		{ "StoreNamedColor", 90 },
		{ "QueryColors", 91 },
		{ "LookupColor", 92 },
		{ "CreateCursor", 93 },
		{ "CreateGlyphCursor", 94 },
		{ "FreeCursor", 95 },
		{ "RecolorCursor", 96 },
		{ "QueryBestSize", 97 },
		{ "QueryExtension", 98 },
		{ "ListExtensions", 99 },
		{ "ChangeKeyboardMapping", 100 },
		{ "GetKeyboardMapping", 101 },
		{ "ChangeKeyboardControl", 102 },
		{ "GetKeyboardControl", 103 },
		{ "Bell", 104 },
		{ "ChangePointerControl", 105 },
		{ "GetPointerControl", 106 },
		{ "SetScreenSaver", 107 },
		{ "GetScreenSaver", 108 },
		{ "ChangeHosts", 109 },
		{ "ListHosts", 110 },
		{ "SetAccessControl", 111 },
		{ "SetCloseDownMode", 112 },
		{ "KillClient", 113 },
		{ "RotateProperties", 114 },
		{ "ForceScreenSaver", 115 },
		{ "SetPointerMapping", 116 },
		{ "GetPointerMapping", 117 },
		{ "SetModifierMapping", 118 },
		{ "GetModifierMapping", 119 },
		{ "NoOperation", 127 },
		{ "XRender", 153 },
		{ NULL } };
	char string[1025];
	int i;
	XGetErrorText(display, error_event->error_code, string, sizeof(string)-1);
	string[sizeof(string)-1]=0;
	NSLog(@"X Error: %s", string);
	NSLog(@"  code: %u", error_event->error_code);
	NSLog(@"  display: %s", DisplayString(display));
	for(i=0; requests[i].name; i++)
		if(requests[i].major == error_event->request_code)
			break;
	NSLog(@"  sequence: %lu:%lu", LastKnownRequestProcessed(display), NextRequest(display));
	if(requests[i].name)
		NSLog(@"  request: %s(%hhu).%hhu", requests[i].name, error_event->request_code, error_event->minor_code);
	else
		NSLog(@"  request: %hhu.%hhu", error_event->request_code, error_event->minor_code);
	NSLog(@"  resource: %lu", error_event->resourceid);
	if(error_event->request_code == 73)
		return;	// ignore errors from XGetImage until we clip to the real window
#if 1
	fprintf(stderr, "abort through X Error %s code %u display %s sequence %lu:%lu request %s(%u.%u) resource %lu\n",
			string,
			error_event->error_code,
			DisplayString(display),
			LastKnownRequestProcessed(display), NextRequest(display),
			requests[i].name?requests[i].name:"", error_event->request_code, error_event->minor_code,
			error_event->resourceid);
	*((long *) 1)=0;	// force SEGFAULT to ease debugging by writing a core dump
	abort();
#endif
	[NSException raise:NSGenericException format:@"X11 Internal Error"];
}  /* X11ErrorHandler */

@implementation NSGraphicsContext (NSBackendOverride)

+ (NSGraphicsContext *) graphicsContextWithGraphicsPort:(void *) port flipped:(BOOL) flipped;
{
	// FIXME: _nsscreen?
	NSGraphicsContext *gc=[[(_NSX11GraphicsContext *)NSAllocateObject([_NSX11GraphicsContext class], 0, NSDefaultMallocZone()) _initWithGraphicsPort:port] autorelease];
	if(gc)
		gc->_isFlipped=flipped;
	return gc;
}

+ (NSGraphicsContext *) graphicsContextWithWindow:(NSWindow *) window
{
	return [_NSX11GraphicsContext graphicsContextWithAttributes:
			[NSDictionary dictionaryWithObject:window forKey:NSGraphicsContextDestinationAttributeName]];
}

@end

@implementation NSWindow (NSBackendOverride)

+ (NSInteger) _getLevelOfWindowNumber:(NSInteger) windowNum;
{ // even if it is not a NSWindow
	Atom actual_type_return;
	int actual_format_return;
	unsigned long nitems_return;
	unsigned long bytes_after_return;
	unsigned char *prop_return;
	int level;
	NSWindow *win=[NSApp windowWithWindowNumber:windowNum];
	if(win)
		return [win level];	// it is our window so we don't have to ask the windows server
#if 0
	NSLog(@"getLevel of window %d", windowNum);
#if 1
	{
	char bfr[256];
	sprintf(bfr, "/usr/X11/bin/xprop -id %d", windowNum);
	system(bfr);
	}
#endif
#endif
	if(XGetWindowProperty(_display, (Window) windowNum,
						  _windowDecorAtom,
						  0, sizeof(GSAttributes)/sizeof(CARD32),
						  False, AnyPropertyType,
						  &actual_type_return, &actual_format_return,
						  &nitems_return, &bytes_after_return, &prop_return) != Success)
		return -1;	// some error
	if(actual_type_return == None)
		return -1;	// no level for this window number available
					// should check if nitems_return matches size of GSAttributes
	level=((GSAttributes *) prop_return)->window_level;
	XFree(prop_return);
#if 0
	NSLog(@"got of window %d = %d", windowNum, level);
#endif
	return level;
}

@end

@implementation NSScreen (NSBackendOverride)

+ (void) initialize;	// called when looking at the first screen
{
	[_NSX11Screen class];
}

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (NSArray *) screens
{
	static NSMutableArray *screens;
	if(!screens)
		{ // create screens list
			int i;
			screens=[[NSMutableArray alloc] initWithCapacity:ScreenCount(_display)];
			for(i=0; i<ScreenCount(_display); i++)
				{
				_NSX11Screen *s=[[_NSX11Screen alloc] init];	// create screen object
				s->_screen=XScreenOfDisplay(_display, i);	// Screen
				if(s->_screen)
					{
					if(i == XDefaultScreen(_display))
						[screens insertObject:s atIndex:0];	// make it the first screen
					else
						[screens addObject:s];
					}
				[s release];	// retained by array
				}
#if 0
			NSLog(@"screens=%@", screens);
#endif
		}
	return screens;
}

// FIXME: handle the context
// according to latest documentation: Provides an ordered list of onscreen windows for a particular application, identified by context, which is a window server connection ID
// so is it equivalent to a client ID
// FIXME: how is the stacking order defined for multiple screens?

+ (int) _systemWindowListForContext:(NSInteger) context size:(NSInteger) size list:(NSInteger *) list;	// list may be NULL. Then, return # of entries copied
{ // get window numbers of visible windows from front to back
	int i, j, s;
	static Window *children;	// list of children (cached)
	static unsigned int nchildren; // number of entries (cached)
	j=0;
	for(s=0; s<ScreenCount(_display) && j<size; s++)
		{ // loop over all screens (this mixes up the stacking order!)
#if 1
			NSLog(@"XQueryTree for screen %d (size=%ld list=%p)", s, (long)size, list);
#endif
			if(!list || !children)
				{ // asking for number of windows only or not yet cached
					Window root, parent;
					nchildren=(unsigned int) size;
					// NOTE: XQueryTree could fail since it does not return appropriate stacking order for child windows with different parent!
					// but all our windows are children of the root window
					if(!XQueryTree(_display, RootWindowOfScreen(XScreenOfDisplay(_display, s)), &root, &parent, &children, &nchildren))
						return 0;	// failed
#if 0
					NSLog(@"  nchildren= %d", nchildren);
#endif
				}
			for(i=nchildren-1; i >= 0 && j < size; i--)
				{ // process and count or append windows
					NSWindow *win;
					if(context != 0 && 0 /* not equal */)
						{
						// context is a client ID
						// FIXME: remove from children list cache
						continue;	// skip since it is owned by a different application
						}
					win=[NSApp windowWithWindowNumber:children[i]];
					if(!win)
						{ // get visibility from Server
							XWindowAttributes xwattrs;
							XGetWindowAttributes(_display, children[i], &xwattrs);
							if(xwattrs.map_state != IsViewable)
								// FIXME: remove from children list cache
								continue;	// Server says this window is not visible
						}
					else if(![win isVisible])	// ask local state
												// FIXME: remove from children list cache
						continue;	// skip windows that are not visible
					if(list)
						list[j]=(int) children[i];	// get windows in front2back order and translate to window numbers
					j++;
				}
			if(list)
				XFree(children), children=NULL;	// recache once we have really used the list
		}
	return j;
}

@end

@implementation NSApplication (NSBackend)

- (NSArray *) windows;
{ // get all NSWindows of this application
	if(__WindowNumToNSWindow)
		return NSAllMapTableValues(__WindowNumToNSWindow);		// all windows we currently know by window number
	return nil;
}

- (NSWindow *) windowWithWindowNumber:(NSInteger) windowNum;
{
#if 0
	NSLog(@"_windowForNumber %d -> %@", windowNum, NSMapGet(__WindowNumToNSWindow, (void *) windowNum));
#endif
	return NSMapGet(__WindowNumToNSWindow, (void *) windowNum);
}

@end

@implementation _NSX11Screen

static NSDictionary *_x11settings;
static NSFileHandle *fh;

+ (void) initialize;	// called when looking at the first screen
{ // initialize backend
	static char *atomNames[] =
	{
	"WM_STATE",
	"WM_PROTOCOLS",
	"WM_DELETE_WINDOW",
	"_GNUSTEP_WM_ATTR"
	};
	Atom atoms[sizeof(atomNames)/sizeof(atomNames[0])];
	NSUserDefaults *def=[[[NSUserDefaults alloc] initWithUser:@"root"] autorelease];	// load /Library/Preferences user defaults (if they exist)
#if 1
	NSLog(@"NSScreen backend +initialize");
	//	system("export;/usr/X11R6/bin/xeyes&");
#endif
	_x11settings=[[def persistentDomainForName:@"com.quantumstep.X11"] retain];	// /Library/Preferences/com.quantumstep.X11
	if(!_x11settings)
		NSLog(@"warning: no defaults for root/com.quantumstep.X11 found");
	if([def boolForKey:@"NSBackingStoreNotBuffered"])
		{
		_doubleBufferering=NO;
		fprintf(stderr, "*** double buffering disabled ***\n");
		}
#if 0
	XInitThreads();	// make us thread-safe
#endif
	if((_display=XOpenDisplay(NULL)) == NULL) 		// connect to X server based on DISPLAY variable
		{
		fprintf(stderr, "Unable to connect to X server\n");
		exit(1);
		}
	XSetErrorHandler((XErrorHandler) X11ErrorHandler);
#if 1
#endif
	if(1 || [def boolForKey:@"X11RunSynchronized"])
		{
		XSynchronize(_display, True);
		fprintf(stderr, "*** X11 runs synchronized (i.e. slowly) ***\n");
		}
	fh=[[NSFileHandle alloc] initWithFileDescriptor:XConnectionNumber(_display)];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_X11EventNotification:)
												 name:NSFileHandleDataAvailableNotification
											   object:fh];
	_XRunloopModes=[[NSArray alloc] initWithObjects:
					NSDefaultRunLoopMode,
#if 1
					// CHECKME:
					// do we really have to handle NSConnectionReplyMode?
					// Well, this keeps the UI responsive if DO is multi-threaded but might also lead to strange synchronization issues (nested runloops)
					NSConnectionReplyMode,
#endif
					NSModalPanelRunLoopMode,
					NSEventTrackingRunLoopMode,
					@"NSX11GraphicsContextMode",	// private mode
					nil];
	[fh waitForDataInBackgroundAndNotifyForModes:_XRunloopModes];
	if(XInternAtoms(_display, atomNames, sizeof(atomNames)/sizeof(atomNames[0]), False, atoms) == 0)
		[NSException raise: NSGenericException format:@"XInternAtoms()"];
	_stateAtom = atoms[0];
	_protocolsAtom = atoms[1];
	_deleteWindowAtom = atoms[2];
	_windowDecorAtom = atoms[3];
#if USE_XRENDER
	//	if([def boolForKey:@"NSXRender"])
	{
	int error, event;
	_hasRender=XRenderQueryExtension(_display, &event, &error);
	}
#if 1
	if(_hasRender)
		_doubleBufferering=NO;	// needs different algorithms
	else
		NSLog(@"has no XRender");
#endif
#endif
}

+ (void) _X11EventNotification:(NSNotification *) n;
{
#if 0
	NSLog(@"X11 notification");
#endif
	[self _handleNewEvents];
#if 0
	NSLog(@"  X11 notification done");
#endif
	[[n object] waitForDataInBackgroundAndNotifyForModes:_XRunloopModes];
}

- (CGFloat) userSpaceScaleFactor;
{ // get dots per point
	static CGFloat factor=0.0;
	if(factor <= 0.01)
		{
		// FIXME: read from user defaults!
		//		if(_x11settings)
		//			 factor=[[_x11settings objectForKey:@"userSpaceScaleFactor"] floatValue];
		if(factor <= 0.01) factor=1.0;	// force default
		}
	return factor;
}

- (NSDictionary *) deviceDescription;
{
	if(!_device)
		{ // (re)load resolution
			BOOL changed=NO;
			NSSize size, resolution;
			int major_opcode_return;
			int first_event_return;
			int first_error_return;
			id val;
			float xdpp=(25.4*WidthOfScreen(_screen))/(72.0*WidthMMOfScreen(_screen));	// dpp: dots per point
			float ydpp=(25.4*HeightOfScreen(_screen))/(72.0*HeightMMOfScreen(_screen));
			float avg=(xdpp+ydpp)*0.5;	// take average for 72dpi
			avg=avg*(1.0 + (0.8/500.0)*((WidthMMOfScreen(_screen)+HeightMMOfScreen(_screen)) - 500.0));	// enlarge for big and far away screens / reduce for handhelds
			if(fabs(avg - rint(avg)) < 0.1)
				avg=rint(avg);	// round to nearest integer if near enough
			_screenScale=avg;
#if 0
			printf("%g\n", _screenScale);
#endif
#if 1
			NSLog(@"pixel: w=%d h=%d", WidthOfScreen(_screen), HeightOfScreen(_screen));
			NSLog(@"   mm: w=%d h=%d", WidthMMOfScreen(_screen), HeightMMOfScreen(_screen));
			NSLog(@"dpp:   x=%lf y=%lf", xdpp, ydpp);
			NSLog(@"calculated system space scale factor=%lf", _screenScale);
#endif
			val=[_x11settings objectForKey:@"systemSpaceScaleFactor"];
			if(val)
				{
				_screenScale *= [val floatValue];	// modify
#if 1
				NSLog(@" adjusted system space scale factor=%lf", _screenScale);
#endif
				}
			_xRect.width=WidthOfScreen(_screen);			// screen width in pixels
			_xRect.height=HeightOfScreen(_screen);			// screen height in pixels
			size.width=_xRect.width/_screenScale;					// screen width in 1/72 points
			size.height=_xRect.height/_screenScale;					// screen height in 1/72 points
			resolution.width=(25.4*size.width)/WidthMMOfScreen(_screen);	// returns size in mm -> translate to DPI
			resolution.height=(25.4*size.height)/HeightMMOfScreen(_screen);
			[(NSAffineTransform *) _screen2X11 release];
			_screen2X11=[[NSAffineTransform alloc] init];
			[(NSAffineTransform *) _screen2X11 translateXBy:0.5 yBy:0.5+_xRect.height];		// adjust for real screen height and proper rounding
			[(NSAffineTransform *) _screen2X11 scaleXBy:_screenScale yBy:-_screenScale];	// flip Y axis and scale
#if 0
			NSLog(@"_screen2X11=%@", (NSAffineTransform *) _screen2X11);
#endif
#if 0
			if(XDisplayString(_display)[0] == ':' ||
			   strncmp(XDisplayString(_display), "localhost:", 10) == 0)
				{ // local server
				  // setup a timer to verify/update the deviceDescription/orientation every now and then
				  // based on CoreMotion values
				}
#endif
			if(XQueryExtension(_display, "Apple-WM", &major_opcode_return, &first_event_return, &first_error_return))
				// FIXME: apply [_X112screen transformPoint:NSMakePoint(root_x, root_y)]
				size.height-=[self _windowTitleHeight]/_screenScale;	// if we display on Apple X11, leave room for menu bar
			_device=[[NSMutableDictionary alloc] initWithObjectsAndKeys:
					 [NSNumber numberWithInt:PlanesOfScreen(_screen)], NSDeviceBitsPerSample,
					 @"DeviceRGBColorSpace", NSDeviceColorSpaceName,
					 @"NO", NSDeviceIsPrinter,
					 @"YES", NSDeviceIsScreen,
					 [NSValue valueWithSize:resolution], NSDeviceResolution,
					 [NSValue valueWithSize:size], NSDeviceSize,
					 [NSNumber numberWithInt:XScreenNumberOfScreen(_screen)], @"NSScreenNumber",
					 [NSNumber numberWithFloat:_screenScale], @"systemSpaceScaleFactor",
					 nil];
#if 0
			NSLog(@"deviceDescription=%@", _device);
			NSLog(@"  resolution=%@", NSStringFromSize(resolution));
			NSLog(@"  size=%@", NSStringFromSize(size));
#endif
			if(changed)
				[[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidChangeScreenParametersNotification object:NSApp];
		}
	return _device;
}

- (NSWindowDepth) depth
{
	int BpS=PlanesOfScreen(_screen);
	return WindowDepth(BpS, BpS/3, YES, NSRGBColorSpaceModel);
}

- (const NSWindowDepth *) supportedWindowDepths;
{
	/*
	 int *XListDepths(display, screen_number, count_return)
	 Display *display;
	 int screen_number;
	 int *count_return;

	 and translate

	 */
	NIMP; return NULL;
}

- (NSAffineTransform *) _X112screen;
{
	if(!_X112screen)
		{ // calculate and cache
			_X112screen=[(NSAffineTransform *)_screen2X11 copy];
			[_X112screen invert];
		}
	return _X112screen;
}

- (BOOL) _hasWindowManager;
{ // check if there is a window manager so we should not add _NSWindowTitleView
	return YES;
}

- (NSInteger) _keyWindowNumber;
{ // returns the global focus window number (may be on a different screen!)
	Window focus;
	int revert_to;
	XGetInputFocus(_display, &focus, &revert_to);
	return focus;
}

- (int) _windowTitleHeight;
{ // amount added by window manager for window title
	return 22;
}

- (NSPoint) _mouseLocation
{
	Window root, child;
	int root_x, root_y, window_x, window_y;
	unsigned int mask;	// modifier and mouse keys
	if(!XQueryPointer(_display, XDefaultRootWindow(_display), &root, &child, &root_x, &root_y, &window_x, &window_y, &mask))
		return NSZeroPoint;
	// FIXME: apply [_X112screen transformPoint:NSMakePoint(root_x, root_y)]
	root_y=HeightOfScreen(_screen)-root_y-1;
	if(_screenScale != 1.0)
		return NSMakePoint(root_x/_screenScale, root_y/_screenScale+1);
	return NSMakePoint(root_x, root_y+1);
}

// FIXME: should translate mouse locations by CTM to account for screen rotation through CTM!

#define X11toScreen(record) (windowScale != 1.0?NSMakePoint(record.x/windowScale, (windowHeight-record.y)/windowScale):NSMakePoint(record.x, windowHeight-record.y))
#define X11toTimestamp(record) ((NSTimeInterval)(record.time*0.001))

+ (void) _handleNewEvents;
{
	int count;
	while((count = XPending(_display)) > 0)		// while X events are pending - we don't use the count except for debugging
		{
		// FIXME: the lastXWin/lastMotionEvent mechanism isn't used any more
		static Window lastXWin=None;		// last window (cache key)
		static NSInteger windowNumber;		// number of lastXWin
		static int windowHeight;			// attributes of lastXWin (signed so that we can calculate windowHeight-y and return negative coordinates)
		static CGFloat windowScale;			// scaling factor
		static NSEvent *lastMotionEvent=nil;
		static Time timeOfLastClick = 0;
		static int clickCount = 1;
		NSEventType type;
		Window thisXWin;				// window of this event
		XEvent xe;
		NSEvent *e = nil;	// resulting event
#if 0
		fprintf(stderr,"_NSX11Screen ((XPending count = %d): \n", count);
#endif
		XNextEvent(_display, &xe);
		switch(xe.type) { // extract window from event
			case ButtonPress:
			case ButtonRelease:
				thisXWin=xe.xbutton.window;
				break;
			case EnterNotify:						// when the pointer enters or leaves a window, pass upwards as a motion event
			case LeaveNotify:
				thisXWin=xe.xcrossing.window;
				break;
			case MotionNotify:
				thisXWin=xe.xmotion.window;
				if(thisXWin != lastXWin)
					lastMotionEvent=nil;	// window has changed - we need a new event
				break;
			case ReparentNotify:
				thisXWin=xe.xreparent.window;
				break;
			case Expose:
				thisXWin=xe.xexpose.window;
				break;
			case ClientMessage:
				thisXWin=xe.xclient.window;
				break;
			case ConfigureNotify:					// window has been resized
				thisXWin=xe.xconfigure.window;
				break;
			case FocusIn:
			case FocusOut:							// keyboard focus left
				thisXWin=xe.xfocus.window;
				break;
			case KeyPress:							// a key has been pressed
			case KeyRelease:						// a key has been released
				thisXWin=xe.xkey.window;
				break;
			case MapNotify:							// when a window changes
			case UnmapNotify:
				thisXWin=xe.xmap.window;
				break;
			case PropertyNotify:
				thisXWin=xe.xproperty.window;
				break;
			default:
				thisXWin=lastXWin;	// assume unchanged
		}
		if(xe.type != MotionNotify)
			lastMotionEvent=nil;	// any other event - start a new motion notification
		if(thisXWin != lastXWin)
			{ // update cached references to window and prepare for translation
				NSWindow *lastWindow=NSMapGet(__WindowNumToNSWindow, (void *) thisXWin);
				_NSX11GraphicsContext *ctxt=(_NSX11GraphicsContext *)[lastWindow graphicsContext];
				windowNumber=[lastWindow windowNumber];
				if(ctxt)
					{ // may be nil if we receive e.g. a cursor update event
						windowHeight=ctxt->_xRect.height;
						windowScale=ctxt->_scale;
					}
				else
					{
					windowHeight=0;
					windowScale=1.0;
					}
				lastXWin=thisXWin;
			}
		// we could post the raw X-event as a NSNotification so that we could build a window managerin Obj-C...
		switch(xe.type) {
			case ButtonPress: { // mouse button events
				float pressure=0.0;
				NSDebugLog(@"ButtonPress: X11 time %u timeOfLastClick %u \n",
						   xe.xbutton.time, timeOfLastClick);
				// hardwired test for a double click
				// default of 300 should be user set;
				// under NS the windowserver does this
				if(xe.xbutton.time < (unsigned long)(timeOfLastClick+300))
					clickCount++;
				else
					clickCount = 1;							// reset click cnt
				timeOfLastClick = xe.xbutton.time;
				switch (xe.xbutton.button) {
					case Button4:
						type = NSScrollWheel;
						pressure = -(float)clickCount;
						break;
					case Button5:
						type = NSScrollWheel;
						pressure = (float)clickCount;
						break;
					case Button1:	type = NSLeftMouseDown;		break;
					case Button3:	type = NSRightMouseDown;	break;
					default:		type = NSOtherMouseDown;	break;
				}
				e = [NSEvent mouseEventWithType:type		// create NSEvent
									   location:X11toScreen(xe.xbutton)
								  modifierFlags:__modFlags
									  timestamp:X11toTimestamp(xe.xbutton)
								   windowNumber:windowNumber
					 // FIXME: this should send some graphics context!
										context:(void *) self
									eventNumber:xe.xbutton.serial
									 clickCount:clickCount
									   pressure:pressure];
				break;
			}
			case ButtonRelease: {
			NSDebugLog(@"ButtonRelease");
			if(xe.xbutton.button == Button1)
				type=NSLeftMouseUp;
			else if(xe.xbutton.button == Button3)
				type=NSRightMouseUp;
			else
				type=NSOtherMouseUp;
			e = [NSEvent mouseEventWithType:type		// create NSEvent
								   location:X11toScreen(xe.xbutton)	// relative to the current window
							  modifierFlags:__modFlags
								  timestamp:X11toTimestamp(xe.xbutton)
							   windowNumber:windowNumber
									context:(void *) self
								eventNumber:xe.xbutton.serial
								 clickCount:clickCount
								   pressure:1.0];
			break;
			}
			case CirculateNotify:	// a change to the stacking order
				NSDebugLog(@"CirculateNotify\n");
				break;
			case CirculateRequest:
				NSDebugLog(@"CirculateRequest");
				break;
			case ClientMessage:								// client events
				NSDebugLog(@"ClientMessage\n");
				if(xe.xclient.message_type == _protocolsAtom &&
				   xe.xclient.data.l[0] == _deleteWindowAtom)
					{ // WM is asking us to close
						[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) performClose:self];
					}									// to close window
														// send NSAppKit / NSSystemDefined event
#if DND
				else
					XRProcessXDND(_display, &xe);		// handle X DND
#endif
				break;
			case ColormapNotify:					// colormap attribute chg
				NSDebugLog(@"ColormapNotify\n");
				break;
			case ConfigureNotify:					// window has been moved or resized by window manager
				NSDebugLog(@"ConfigureNotify\n");
				[[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) _themeFrame] setNeedsDisplay:YES];	// make us redraw content
#if 1
				e = [NSEvent otherEventWithType:NSAppKitDefined
									   location:X11toScreen(xe.xconfigure)	// or do we notify relative movement?
								  modifierFlags:__modFlags
									  timestamp:0 //X11toTimestamp(xe.xconfigure)
								   windowNumber:windowNumber
										context:(void *) self
										subtype:NSWindowMovedEventType
										  data1:xe.xconfigure.width
										  data2:xe.xconfigure.height];	// new position and dimensions
																		// this should allow to precisely track mouse position if the window is moved
																		// for that it could be sufficient to track window movements and report top-left corner only
#endif
#if FIXME
				// we should at least redisplay the window
				if(!xe.xconfigure.override_redirect ||
				   xe.xconfigure.window == _wAppTileWindow)
					{
					NSRect f = (NSRect){{(float)xe.xconfigure.x,
						(float)xe.xconfigure.y},
						{(float)xe.xconfigure.width,
							(float)xe.xconfigure.height}};	// get frame rect
					if(!(w = XRWindowWithXWindow(xe.xconfigure.window)) && xe.xconfigure.window == _wAppTileWindow)
						w = XRWindowWithXWindow(__xAppTileWindow);
					if(xe.xconfigure.above == 0)
						f.origin = [w xFrame].origin;
					//					if(!xe.xconfigure.override_redirect && xe.xconfigure.send_event == 0)
					f.origin.y += WINDOW_MANAGER_TITLE_HEIGHT;		// adjust for title bar offset
					NSDebugLog(@"New frame %f %f %f %f\n",
							   f.origin.x, f.origin.y,
							   f.size.width, f.size.height);
					// FIXME: shouldn't this be an NSNotification that a window can catch?
					[NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) _setFrame:f];
					}
				if(xe.xconfigure.window == lastXWin)
					{
					// xFrame = [w xFrame];
					xFrame = (NSRect){{(float)xe.xconfigure.x,
						(float)xe.xconfigure.y},
						{(float)xe.xconfigure.width,
							(float)xe.xconfigure.height}};
					}
#endif
				break;
			case ConfigureRequest:					// same as ConfigureNotify but we get this event
				NSDebugLog(@"ConfigureRequest\n");	// before the change has
				break;								// actually occurred
			case CreateNotify:						// a window has been
				NSDebugLog(@"CreateNotify\n");		// created
				break;
			case DestroyNotify:						// a window has been
				NSLog(@"DestroyNotify\n");			// Destroyed
				break;
			case LeaveNotify:
			case EnterNotify:						// when the pointer enters or leves a window, pass upwards as a first/last motion event
													// FIXME: this may collide with lastMotionEvent
				if([(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) acceptsMouseMovedEvents])
					e = [NSEvent mouseEventWithType:NSMouseMoved
										   location:X11toScreen(xe.xcrossing)
									  modifierFlags:__modFlags
										  timestamp:X11toTimestamp(xe.xcrossing)
									   windowNumber:windowNumber
											context:(void *) self
										eventNumber:xe.xcrossing.serial
										 clickCount:1
										   pressure:1.0];
				break;
			case Expose: {
			_NSX11GraphicsContext *ctxt=(_NSX11GraphicsContext *)[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) graphicsContext];
			if(_isDoubleBuffered(ctxt))
				{ // copy from backing store
					_setDirtyRect(ctxt, xe.xexpose.x, xe.xexpose.y, xe.xexpose.width, xe.xexpose.height);	// flush at least the exposed area
																											// FIXME - we should collect and merge all expose events into a single one
																											// we should also be able to postpone expose events after resizing the window
																											// or setDirtyRect should setup a timer to flush after a while...
																											//			[ctxt flushGraphics];	// plus anything else we need to flush anyway
				}
			else
				{ // queue up an expose event
					NSSize sz;
					if(windowScale != 1.0)
						sz=NSMakeSize(xe.xexpose.width/windowScale+0.5, xe.xexpose.height/windowScale+0.5);
					else
						sz=NSMakeSize(xe.xexpose.width, xe.xexpose.height);
#if 1
					NSLog(@"not double buffered expose %@ -> %@", NSMapGet(__WindowNumToNSWindow, (void *) thisXWin),
						  //  NSStringFromXRect(xe.xexpose),
						  NSStringFromSize(sz));
#endif
					xe.xexpose.y+=xe.xexpose.height;	// X11 specifies top left while we expect bottom left
					e = [NSEvent otherEventWithType:NSAppKitDefined
										   location:X11toScreen(xe.xexpose)
									  modifierFlags:0
										  timestamp:0
									   windowNumber:windowNumber
											context:(void *) self
											subtype:NSWindowExposedEventType
											  data1:sz.width
											  data2:sz.height];	// truncated to (int)
				}
			break;
			}
			case FocusIn: {
			// keyboard focus entered one of our windows - take this a a hint from the WindowManager to bring us to the front
#if 0
				NSLog(@"FocusIn 1: %d\n", xe.xfocus.detail);
#endif
				break;
			}
			case FocusOut: {
			// keyboard focus has left one of our windows
#if 0
				NSDebugLog(@"FocusOut");
#endif
				break;
			}
			case GraphicsExpose:
				NSDebugLog(@"GraphicsExpose\n");
				break;
			case NoExpose:
				NSDebugLog(@"NoExpose\n");
				break;
			case GravityNotify:						// window is moved because
				NSDebugLog(@"GravityNotify\n");		// of a change in the size
				break;								// of its parent
			case KeyPress:							// a key has been pressed
			case KeyRelease: {
				// a key has been released
			NSEventType eventType=(xe.type == KeyPress)?NSKeyDown:NSKeyUp;
			char buf[256];
			KeySym ksym;
			NSString *keys = @"";
			unsigned short keyCode = 0;
			unsigned mflags;
			// FIXME: if we want to get not only ISO-Latin 1 we should use XLookupKeysym()
			unsigned int count = XLookupString(&xe.xkey, buf, sizeof(buf), &ksym, NULL);
#if 1
				{
				int idx;
				NSLog(@"xKeyEvent: xkey.state=%d keycode=%d keysym=%lu:%s", xe.xkey.state, xe.xkey.keycode, ksym, XKeysymToString(ksym));
				for(idx=0; idx < 8; idx++)
					NSLog(@"%d: %08lx", idx, XLookupKeysym(&xe.xkey, idx));
				/* it looks as if Apple X11 delivers
				 idx=0: lower case - or base keycode (0xff7e)
				 idx=1: upper case
				 idx=2: Unicode lower case
				 idx=3: Unicode upper case
				 */
				}
#endif
			buf[MIN(count, sizeof(buf)-1)] = '\0'; // Terminate string properly
#if 1
			NSLog(@"Process key event");
#endif
			mflags = xKeyModifierFlags(xe.xkey.state);		// decode (initial) modifier flags
			if((keyCode = xKeyCode(&xe, ksym, &mflags)) != 0 || count != 0)
				{
				if(count == 0)
					keys = [NSString stringWithFormat:@"%C", keyCode];	// unicode key code
				else
					keys = [NSString stringWithCString:buf encoding:NSISOLatin1StringEncoding];	// key has a code or a string
				__modFlags=mflags;							// may also be modified
				}
			else
				{ // if we have neither a keyCode nor characters we have just changed a modifier Key
					if(eventType == NSKeyUp)
						__modFlags &= ~mflags;	// just reset flags defined by this key
					else
						__modFlags=mflags;		// if modified
					eventType=NSFlagsChanged;
				}
			e= [NSEvent keyEventWithType:eventType
								location:NSZeroPoint
						   modifierFlags:__modFlags
							   timestamp:X11toTimestamp(xe.xkey)
							windowNumber:windowNumber
								 context:(void *) self
							  characters:keys
			 charactersIgnoringModifiers:[keys lowercaseString]		// FIX ME?
							   isARepeat:NO	// any idea how to FIXME? - maybe comparing time stamp and keycode with previous key event
								 keyCode:keyCode];
#if 1
			NSLog(@"xKeyEvent -> %@", e);
#endif
			break;
			}

			case KeymapNotify:						// reports the state of the
				NSDebugLog(@"KeymapNotify");		// keyboard when pointer or
				break;								// focus enters a window

			case MapNotify:							// when a window changes
#if 1
				NSLog(@"MapNotify");			// state from ummapped to mapped
												//	fprintf(stderr, "MapNotify\n");
#endif
				[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) _setIsVisible:YES];
				break;

			case UnmapNotify:						// find the NSWindow and
#if 1
				NSLog(@"UnmapNotify\n");		// inform it that it is no longer visible
#endif
				[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) _setIsVisible:NO];
				break;

			case VisibilityNotify:						// window's visibility
				NSDebugLog(@"VisibilityNotify");		// has changed
				break;

			case MapRequest:						// like MapNotify but
				NSDebugLog(@"MapRequest\n");		// occurs before the
				break;								// request is carried out

			case MappingNotify:						// keyboard or mouse
				NSDebugLog(@"MappingNotify\n");		// mapping has been changed
													//	XRefreshKeyboardMapping(<#XMappingEvent * #>);
				break;								// by another client

			case MotionNotify: {
			  // the mouse has moved
				NSDebugLog(@"MotionNotify");
				if(xe.xmotion.state & Button1Mask)
					type = NSLeftMouseDragged;
				else if(xe.xmotion.state & Button3Mask)
					type = NSRightMouseDragged;
				else if(xe.xmotion.state & Button2Mask)
					type = NSOtherMouseDragged;
				else if([(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) acceptsMouseMovedEvents])
					type = NSMouseMoved;	// no button pressed
				else
					break;	// ignore mouse moved events unless the window really wants to see them
#if 0
				if(lastMotionEvent &&
				   [NSApp _eventIsQueued:lastMotionEvent])
					{
					NSLog(@"motion event still in queue: %@", lastMotionEvent);
					}
#endif
				// FIXME: coalesce motion events
				if(NO && lastMotionEvent &&
				   // FIXME - must also be the first event in queue!!!
				   [NSApp _eventIsQueued:lastMotionEvent] &&	// must come first because event may already have been relesed/deallocated
				   [lastMotionEvent type] == type)
					{ // replace/update if last motion event which is still unprocessed in queue
#if OLD
						typedef struct _NSEvent_t { @defs(NSEvent) } _NSEvent;
						_NSEvent *a = (_NSEvent *)lastMotionEvent;	// this allows to access iVars directly
#if 0
						NSLog(@"update last motion event");
#endif
						a->location_point=X11toScreen(xe.xmotion);
						a->modifier_flags=__modFlags;
						a->event_time=X11toTimestamp(xe.xmotion);
						a->event_data.mouse.event_num=xe.xmotion.serial;
#else
						[lastMotionEvent _setLocation:X11toScreen(xe.xmotion) modifierFlags: __modFlags eventTime:X11toTimestamp(xe.xmotion) number:xe.xmotion.serial];
#endif
						break;
					}
				e = [NSEvent mouseEventWithType:type		// create NSEvent
									   location:X11toScreen(xe.xmotion)
								  modifierFlags:__modFlags
									  timestamp:X11toTimestamp(xe.xmotion)
								   windowNumber:windowNumber
										context:(void *) self
									eventNumber:xe.xmotion.serial
									 clickCount:1
									   pressure:1.0];
				lastMotionEvent = e;
#if 0
				NSLog(@"MotionNotify e=%@", e);
#endif
				break;
			}
			case PropertyNotify: {
			 // a window property has changed or been deleted
				NSDebugLog(@"PropertyNotify");
				if(_stateAtom == xe.xproperty.atom)
					{
					Atom target;
					unsigned long number_items, bytes_remaining;
					unsigned char *data;
					int status, format;
					status = XGetWindowProperty(_display,
												xe.xproperty.window,
												xe.xproperty.atom,
												0, 1, False, _stateAtom,
												&target, &format,
												&number_items,&bytes_remaining,
												(unsigned char **)&data);
					if(status != Success || !data)
						break;
					if(*data == IconicState)
						[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) miniaturize:self];
					else if(*data == NormalState)
						[(NSWindow *) NSMapGet(__WindowNumToNSWindow, (void *) thisXWin) deminiaturize:self];
					if(number_items > 0)
						XFree(data);
					}
#if 1	// debug
				if(_stateAtom == xe.xproperty.atom)
					{
					char *data = XGetAtomName(_display, xe.xproperty.atom);
					NSLog(@"PropertyNotify: Atom name is '%s' \n", data);
					XFree(data);
					}
#endif
				// FIXME: if window was moved or changed screen externally, queue an NSAppKitDefinedEvent / NSWindowMovedEventType
				break;
			}
			case ReparentNotify:					// a client successfully
				NSDebugLog(@"ReparentNotify\n");	// reparents a window
				break;
			case ResizeRequest:						// another client (or WM) attempts to change window size
				NSDebugLog(@"ResizeRequest");
				break;
			case SelectionNotify:
				NSLog(@"SelectionNotify");
			{
			//						NSPasteboard *pb = [NSPasteboard generalPasteboard];

			// FIXME: should this be an NSNotification? Or where should we send this event to?
			//						[pb _handleSelectionNotify:(XSelectionEvent *)&xe];

			e = [NSEvent otherEventWithType:NSFlagsChanged
								   location:NSZeroPoint
							  modifierFlags:0
								  timestamp:X11toTimestamp(xe.xbutton)
							   windowNumber:windowNumber	// 0 ??
									context:(void *) self
									subtype:999
									  data1:0
									  data2:0];
			break;
			}
			case SelectionClear:						// X selection events
			case SelectionRequest:
				NSLog(@"SelectionRequest");
#if FIXME
				xHandleSelectionRequest((XSelectionRequestEvent *)&xe);
#endif
				break;
			default:									// should not get here
				NSLog(@"Received an untrapped event");
				break;
		} // end of event type switch
		if(e != nil)
			{
			[NSApp postEvent:e atStart:NO];			// add event to app queue
			[[NSWorkspace sharedWorkspace] extendPowerOffBy:1];	// extend power off if there was a user activity
			}
		}
}

- (void) _sendEvent:(NSEvent *) e;
{ // based on http://homepage3.nifty.com/tsato/xvkbd/events.html
	NSWindow *win;
	NSPoint loc;
	XKeyEvent event;
	_NSX11GraphicsContext *ctxt;
	long mask;
	int type=[e type];
#if 1
	NSLog(@"_sendEvent %@", e);
#endif
	switch(type) {
		case NSKeyUp:
			event.type = KeyRelease;
			mask = KeyReleaseMask;
			break;
		case NSKeyDown:
			event.type = KeyPress;
			mask = KeyPressMask;
			break;
		default:
			// raise exception or ignore
			return;
	}
	event.window=[e windowNumber];
	win=[NSApp windowWithWindowNumber:event.window];	// try to find
	if(!win)
		{ // we don't know this window...
		  // ???
			return;
		}
	ctxt=(_NSX11GraphicsContext *) [win graphicsContext];
	event.display = _display;
	event.root = RootWindowOfScreen(_screen);
	event.subwindow = None;
	event.time = [e timestamp]/1000.0;
	if(event.time == 0)
		event.time=CurrentTime;
	loc=[e locationInWindow];
	event.x = loc.x*ctxt->_scale;
	event.y = ctxt->_xRect.height - (int)(loc.y*ctxt->_scale);
	event.x_root = 1;
	event.y_root = 1;
	event.same_screen=([win screen] == self);
	// FIXME: translate Cocoa keycodes and modifier flags to what X11 expects!
	event.keycode = [e keyCode];
	event.state = (unsigned int)[e modifierFlags];
	XSendEvent(event.display, event.window, True, mask, (XEvent *) &event);
}

@end

@implementation NSColor (NSBackendOverride)

+ (id) allocWithZone:(NSZone *) z;
{
	return NSAllocateObject([_NSX11Color class], 0, z?z:NSDefaultMallocZone());
}

@end

@implementation _NSX11Color

- (Picture) _pictureForColor;
{
#if USE_XRENDER
	if(!_picture)
		{
		if(_colorPatternImage)
			{
			// get Picture from image's cache
			// make a copy?
			// set repetition flag
			}
		else
			{ // create an 1x1 repeating Picture filled with our color
				Window root=DefaultRootWindow(_display);	// first root window
				Pixmap pixmap;
				XRenderColor c;
				XRenderPictureAttributes pa;
				pixmap=XCreatePixmap(_display, root, 1, 1, 4*8);	// ARGB32
				pa.repeat=1;
				//			pa.repeat=RepeatNormal;	// repeat pattern
				_picture=XRenderCreatePicture(_display, pixmap,
											  XRenderFindStandardFormat(_display, PictStandardARGB32),
											  CPRepeat, &pa);
				c.red=(65535 * [self redComponent]);
				c.green=(65535 * [self greenComponent]);
				c.blue=(65535 * [self blueComponent]);
				c.alpha=(65535 * [self alphaComponent]);
				XRenderFillRectangle(_display, PictOpSrc, _picture, &c, 0, 0, 1, 1);	// fill picture with given color
				XFreePixmap(_display, pixmap);	// no explicit reference required
			}
		}
#endif
	return _picture;
}

- (unsigned long) _pixelForScreen:(Screen *) scr;
{
	// FIXME: we must cache different pixel values for different screens!
	if(!_colorData || _screen != scr)
		{ // not yet cached or for a different screen
			NSColor *color;
			_screen=scr;
			if(!(_colorData = objc_malloc(sizeof(XColor))))
				[NSException raise:NSMallocException format:@"Unable to malloc XColor backend structure"];
			if(_colorspaceName != NSDeviceRGBColorSpace)
				color=(_NSX11Color *) [self colorUsingColorSpaceName:NSDeviceRGBColorSpace];	// convert
			else
				color=self;
			if(self)
				{
				((XColor *) _colorData)->red = (unsigned short)(65535 * [color redComponent]);
				((XColor *) _colorData)->green = (unsigned short)(65535 * [color greenComponent]);
				((XColor *) _colorData)->blue = (unsigned short)(65535 * [color blueComponent]);
				}
			if(!self || !scr || !XAllocColor(_display, XDefaultColormapOfScreen(scr), _colorData))
				{
				NSLog(@"Unable to allocate color %@ for X11 Screen %p", color, scr);
				return 0;
				}
		}
	return ((XColor *) _colorData)->pixel;
}

- (void) dealloc;
{
#if USE_XRENDER
	if(_picture)
		XRenderFreePicture(_display, _picture);
#endif
	if(_colorData)
		objc_free(_colorData);
	[super dealloc];
}

@end

@implementation NSFont (NSBackendOverride)

+ (id) allocWithZone:(NSZone *) z;
{
	return NSAllocateObject([_NSX11Font class], 0, z?z:NSDefaultMallocZone());
}

@end

@implementation _NSX11Font

#if 0
+ (void) initialize
{ // ask X Server for list of fonts
	/*
	 NSDictionary *record;
	 int count_return;
	 XFontStruct *info_return;
	 char ** names=XListFontsWithInfo(_display, "*", 200, &count_return, &info_return)
	 // go through all fonts
	 // split name
	 // add required info to easily find the font
	 [NSFontDescriptor _addFont:name withRecord:record];
	 */
}
#endif

- (NSFont *) screenFontWithRenderingMode:(NSFontRenderingMode) mode;
{ // check if we can make it an X11 screen font - otherwise make it a freetype font
#if 1
	// Screen fonts are broken since private font methods assume a freetype font
	return self;
#endif
	if(_renderingMode == NSFontIntegerAdvancementsRenderingMode)
		return nil;	// is already a screen font!
	if(mode == NSFontDefaultRenderingMode)
		mode = NSFontIntegerAdvancementsRenderingMode;	// read from user defaults...
														// FIXME: check if we either have no transform matrix or it is an identity matrix
	if((self=[[self copy] autorelease]))
		{ // make a modified copy
			_renderingMode=mode;
			if(mode == NSFontIntegerAdvancementsRenderingMode)
				{ // try to use an X11 font
					[self _setScale:1.0];
					if(![self _font])
						{ // we can't find a matching X11 font
							return nil;
						}
				}
		}
	return self;
}

- (NSFont *) printerFont;
{ // we make no distinction
	return self;
}

- (void) _setScale:(CGFloat) scale;
{ // scale font
	scale*=10.0;
	if(_fontScale != scale)
		{ // has been changed
			_fontScale=scale;
			if(_fontStruct)
				{ // clear cache
					XFreeFont(_display, _fontStruct);	// no longer needed
					_fontStruct=NULL;
				}
		}
}

- (XFontStruct *) _font;
{
	NSString *name=[self fontName];
#if 0
	NSLog(@"_font %@ %.1f scale %f", name, [self pointSize], _fontScale);
#endif
	if(_fontScale == 1.0 && _unscaledFontStruct)
		return _unscaledFontStruct;
	if(!_fontStruct)
		{
		char *xFoundry = "*";
		char *xFamily = "*";									// default font family
		char *xWeight = "*";									// font weight (light, bold)
		char *xSlant = "r";										// font slant (roman, italic, oblique)
		char *xWidth = "*";										// width (normal, condensed, narrow)
		char *xStyle = "*";										// additional style (sans serif)
		char *xPixel = "*";
		char xPoint[32];										// variable size
		char *xXDPI = "*";										// we could try to match screen resolution first and try again with *
		char *xYDPI = "*";
		char *xSpacing = "*";									// P proportional, M monospaced, C cell
		char *xAverage = "*";									// average width
		char *xRegistry = "*";									// should try ISO10646-1, iso8859-1, iso8859-2, etc.
		char *xEncoding = "*";									// -1 goes here...
		NSString *xf = nil;

		if(!_display)
			[NSScreen class];	// +initialize
								// [NSException raise:NSGenericException format:@"font %@: no _display: %@", self, xf];
#if 1
		if(_fontScale*[self pointSize] < 1.0)
			{
			NSLog(@"??? zero point font: %@ descriptor:%@", self, [[self fontDescriptor] fontAttributes]);
			NSLog(@"scale %f", _fontScale);
			NSLog(@"pointSize %f", [self pointSize]);
			}
#endif
		sprintf(xPoint, "%.0f", _fontScale*[self pointSize]);	// scaled font for X11 server
		if([name caseInsensitiveCompare:@"Helvetica"] == NSOrderedSame)
			{
			xFamily = "helvetica";
			xWeight = "medium";
			}
		else if([name caseInsensitiveCompare:@"Helvetica-Bold"] == NSOrderedSame)
			{
			xFamily = "helvetica";
			xWeight = "bold";
			}
		else if(([name caseInsensitiveCompare: @"Courier"] == NSOrderedSame))
			{
			xFamily = "courier";
			xWeight = "medium";
			}
		else if(([name caseInsensitiveCompare: @"Courier-Bold"] == NSOrderedSame))
			{
			xFamily = "courier";
			xWeight = "bold";
			}
		else if(([name caseInsensitiveCompare: @"Ohlfs"] == NSOrderedSame))
			{
			xFamily="fixed";
			xWidth="ohlfs";
			xRegistry="iso8859";
			xFamily="1";
			}
		else
			{ // default
				xFamily="lucida*";
				xWeight="medium";
			}
		xf=[NSString stringWithFormat: @"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
			xFoundry, xFamily, xWeight, xSlant, xWidth, xStyle,
			xPixel, xPoint, xXDPI, xYDPI, xSpacing, xAverage,
			xRegistry, xEncoding];
#if 1
		NSLog(@"try %@", xf);
#endif
		if((_fontStruct = XLoadQueryFont(_display, [xf UTF8String])))	// Load X font
			return _fontStruct;
		xWeight="*";	// try any weight
		xf=[NSString stringWithFormat: @"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
			xFoundry, xFamily, xWeight, xSlant, xWidth, xStyle,
			xPixel, xPoint, xXDPI, xYDPI, xSpacing, xAverage,
			xRegistry, xEncoding];
#if 1
		NSLog(@"try %@", xf);
#endif
		if((_fontStruct = XLoadQueryFont(_display, [xf UTF8String])))	// Load X font
			return _fontStruct;
		xFamily="*";	// try any family
		xf=[NSString stringWithFormat: @"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
			xFoundry, xFamily, xWeight, xSlant, xWidth, xStyle,
			xPixel, xPoint, xXDPI, xYDPI, xSpacing, xAverage,
			xRegistry, xEncoding];
#if 1
		NSLog(@"try %@", xf);
#endif
		if((_fontStruct = XLoadQueryFont(_display, [xf UTF8String])))	// Load X font
			return _fontStruct;
		NSLog(@"font: %@ is not available", xf);
		NSLog(@"Trying 9x15 system font instead");
		if((_fontStruct = XLoadQueryFont(_display, "9x15")))
			return _fontStruct;	// "9x15" exists
		NSLog(@"Trying fixed font instead");
		if((_fontStruct = XLoadQueryFont(_display, "fixed")))
			return _fontStruct;	// "fixed" exists
		[NSException raise:NSGenericException format:@"Unable to open any fixed font for %@:%f", name, [self pointSize]];
		return NULL;
		}
	return _fontStruct;
}

- (CGFloat) _widthOfAntialisedString:(NSString *) string;
{ // overwritten by NSFreeTypeFont.m
	NSLog(@"can't determine width of antialiased strings");
	return 0.0;
}

- (void) _defineGlyphs
{ // overwritten by NSFreeTypeFont.m; call [self _addGlyph:...]
	NSLog(@"can't define fonts");
}

- (_CachedGlyph) _defineGlyph:(NSGlyph) glyph;
{ // overwritten by NSFreeTypeFont.m; call [self _addGlyph:...]
	NSLog(@"can't define fonts");
	return NULL;
}

#if OLD
// FIXME: can be removed if we use our own _glyphCache

- (GlyphSet) _glyphSet;
{ // get XRender glyph set
#if USE_XRENDER
	if(!_glyphSet)
		{ // create a new glyphset for this font
		  // we must be able to dealloc a glyph set (LRU...) on the server if it needs too much memory!
			_glyphSet=XRenderCreateGlyphSet(_display, XRenderFindStandardFormat(_display, PictStandardA8));
			[self _defineGlyphs];	// render all glyphs into cache
		}
	// update LRU list
#endif
	return _glyphSet;
}

- (void) _addGlyph:(NSGlyph) glyph bitmap:(char *) buffer x:(int) left y:(int) top width:(unsigned) width height:(unsigned) rows;
{
#if USE_XRENDER
	XGlyphInfo info = { width, rows,
		left, 0,
		width, 0 };	// should be advancement - correct for integer advancement only!!!
	Glyph g=glyph;	// Glyph is of type XID, i.e. must not be 0
	int stride=((width+3)&~3);
#if 0
	static int cnt;
	if(cnt > 100)
		return;
	cnt++;
#endif
#if 0
	NSLog(@"_addGlyph:%d x=%d y=%d w=%u h=%u", g, left, top, width, rows);
	{
	NSString *pattern=@"";
	int x, y;
	for(y=0; y<rows; y++)
		{
		for(x=0; x<width; x++)
			{
			char bits=buffer[y*width+x];
			static char px[]=" .,;/+*#";
			pattern=[pattern stringByAppendingFormat:@"%c", px[(bits>>5)&7]];
			}
		pattern=[pattern stringByAppendingString:@"\n"];
		}
	NSLog(@"\n%@", pattern);
	}
#endif
	if(width == stride)
		XRenderAddGlyphs(_display, _glyphSet, &g, &info, 1, buffer, width*rows);
	else
		{ // convert to ZPixmap format with pad to 4 bytes
			char *tmp=objc_malloc(stride*rows);
			int x, y;
			for(y=0; y<rows; y++)
				{
				int ys=y*stride;
				for(x=0; x<width; x++)
					tmp[ys+x]=*buffer++;	// copy
				}
			XRenderAddGlyphs(_display, _glyphSet, &g, &info, 1, tmp, stride*rows);
			objc_free(tmp);
		}
#endif
}
#endif

- (void) _addGlyphToCache:(_CachedGlyph) g bitmap:(char *) buffer x:(int) left y:(int) top width:(unsigned) width height:(unsigned) rows;
{
	Window root=DefaultRootWindow(_display);	// first root window
	Pixmap pixmap;
	GC gc;
	XGCValues gcValues={ 0 };
	XRenderPictureAttributes pa;
	XImage *image;
	int x, y;
#if 0	// print as letter pattern so that we can see what libFreetype is doing
	NSLog(@"_addGlyphToCache:%d x=%d y=%d w=%u h=%u", g, left, top, width, rows);
	{
	NSString *pattern=@"";
	int x, y;
	for(y=0; y<rows; y++)
		{
		for(x=0; x<width; x++)
			{
			char bits=buffer[y*width+x];
			static char px[]=" .,;/+*#";
			pattern=[pattern stringByAppendingFormat:@"%c", px[(bits>>5)&7]];
			}
		pattern=[pattern stringByAppendingString:@"\n"];
		}
	NSLog(@"\n%@", pattern);
	}
#endif
	g->x=left;
	g->y=top;
	g->width=width;
	g->height=rows;
	pa.repeat=1;
	pixmap=XCreatePixmap(_display, root, g->width, g->height, 8);	// 8 bit only
	g->picture=XRenderCreatePicture(_display, pixmap,
									XRenderFindStandardFormat(_display, PictStandardA8),
									CPRepeat, &pa);
	image=XCreateImage(_display,
					   None,
					   8,			// depth
					   ZPixmap,
					   0,      // offset
					   objc_malloc(g->width*g->height),
					   g->width,
					   g->height,
					   8,
					   g->width);
	for(y=0; y<g->height; y++)
		{
		for(x=0; x<g->width; x++)
			{
			XPutPixel(image, x, y, *buffer++);
			}
		}
	gc=XCreateGC(_display, pixmap, 0, &gcValues);
	XPutImage(_display, pixmap, gc, image, 0, 0, 0, 0, g->width, g->height);
	XFreeGC(_display, gc);
	XDestroyImage(image);
	XFreePixmap(_display, pixmap);	// no explicit reference required
}

// FIXME: add LRU management
// maybe over all NSFonts (!)
// so that we can limit the total number of Pictures and Glyphs defined in the X Server
// FIXME: there should be a GLOBAL cache for all X11Font objects!
// keyed by [font fontName]+[font size], i.e. Postscript & size and maybe rotation
// so that allocating/releasing fonts does not mean glyph operations and reserve data in the server

- (_CachedGlyph) _pictureForGlyph:(NSGlyph) glyph;
{ // get Picture to render
	_CachedGlyph g;
	if(!_glyphCache || !(g=NSMapGet(_glyphCache, (void *) (NSUInteger)glyph)))
		{ // not found
			if(!_glyphCache)	// create map table
				_glyphCache=NSCreateMapTable(NSIntMapKeyCallBacks,
											 NSOwnedPointerMapValueCallBacks, 100);	// table should objc_free() on remove
			else if(NSCountMapTable(_glyphCache) > 200)
				; // handle LRU cleanup
			g=[self _defineGlyph:(NSGlyph) glyph];	// overwritten in NSFreeTypeFont.m
			if(g)
				NSMapInsert(_glyphCache, (void *) (NSUInteger) glyph, (void *) g);
		}
#if 0
	NSLog(@"font %p glyph %d -> %p", self, glyph, g);
#endif
	// handle LRU links
	return g;
}

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(NSUInteger) cnt inContext:(NSGraphicsContext *) ctxt matrix:(NSAffineTransform *) ctm;
{ // overwritten by NSFreeTypeFont.m
	NSLog(@"can't draw antialiased fonts");
}

// DEPRECATED SINCE 10.4 BECAUSE THIS DEPENDS ON CHARACTER ENCODING AND WRITING DIRECTION

- (CGFloat) widthOfString:(NSString *) string;
{ // get size from X11 font assuming no scaling
	if(_renderingMode == NSFontIntegerAdvancementsRenderingMode)
		{
		static XChar2b *buf;	// translation buffer (unichar -> XChar2b)
		static unsigned int buflen;
		unsigned int i;
		NSUInteger length=[string length];
		float width;
		SEL cai=@selector(characterAtIndex:);
		typedef unichar (*CAI)(id self, SEL _cmd, int i);
		CAI imp=(CAI)[string methodForSelector:cai];	// don't try to cache this! Different strings may have different implementations
#if 0
		NSLog(@"widthOfString:%@ font:%@", string, _state->_font);
#endif
		if(!buf || length > buflen)
			buf=(XChar2b *) objc_realloc(buf, sizeof(buf[0])*(buflen=(unsigned int)length+20));	// increase translation buffer if needed
		if(!_unscaledFontStruct)
			{
			_fontScale=10.0;
			[self _font];						// load font data with scaling (10)
			_unscaledFontStruct=_fontStruct;	// copy
			_fontStruct=NULL;					// recache if we finally need a different scaling
			}
		if(buflen < sizeof(buf[0])*length)
			buf=(XChar2b *) objc_realloc(buf, buflen+=sizeof(buf[0])*(length+20));	// increase buffer size
		for(i=0; i<length; i++)
			{
			unichar c=(*imp)(string, cai,i);
			buf[i].byte1=c>>8;
			buf[i].byte2=c;
			}
		width=XTextWidth16(_unscaledFontStruct, buf, (int) length);
#if 0
		NSLog(@"%@[%@] -> %f (C: %d)", self, string, width, XTextWidth(_fontStruct, [string cString], length));
#endif
		return width;	// return size of character box
		}
	else
		return [self _widthOfAntialisedString:string];
}

- (void) _finalize
{ // overwritten by FreeTypeFont
	return;
}

- (void) dealloc;
{
#if USE_XRENDER
	if(_glyphCache)
		{ // uncache and free all Pictures
			NSMapEnumerator e=NSEnumerateMapTable(_glyphCache);
			void *key;
			void *value;
			NSLog(@"should release glyph cache %@", self);
			while(NSNextMapEnumeratorPair(&e, &key, &value))
				{
				(NSGlyph) key;
				(_CachedGlyph *) value;
				// free value->picture
				// objc_free(value);
				}
		}
	//	if(_glyphSet)
	//	XRenderFreeGlyphSet(_display, _glyphSet);
#endif
	if(_fontStruct)
		XFreeFont(_display, _fontStruct);	// no longer needed
	if(_unscaledFontStruct)
		XFreeFont(_display, _unscaledFontStruct);	// no longer needed
	[self _finalize];
	[super dealloc];
}

@end

@implementation NSCursor (NSBackendOverride)

+ (id) allocWithZone:(NSZone *) z;
{
	return NSAllocateObject([_NSX11Cursor class], 0, z?z:NSDefaultMallocZone());
}

@end

@implementation _NSX11Cursor

- (Cursor) _cursor;
{
	if(!_cursor)
		{
		if(_image)
			{
#if USE_XRENDER
			[_image setCacheMode:NSImageCacheAlways];	// force caching
			[_image setCachedSeparately:YES];
			if(_hasRender)
				{
				NSCachedImageRep *rep=[_image _cachedImageRep];	// render to cache if needed
				_NSX11GraphicsContext *c=(_NSX11GraphicsContext *) [[rep window] graphicsContext];
				if(c)
					{
					[(NSCachedImageRep *) rep rect];
					_cursor=XRenderCreateCursor(_display, c->_picture, 0, 0);
					}
				}
			else
#endif
				{
				NSBitmapImageRep *bestRep =(NSBitmapImageRep *) [_image bestRepresentationForDevice:nil];	// where should we get the device description from??
				if(bestRep)
					{
#if 1
					NSLog(@"convert to PixmapCursor: %@", self);
					NSLog(@"  bestRep = %@", bestRep);
#endif
					Drawable root=RootWindowOfScreen(XScreenOfDisplay(_display, 0));
					int width=(int)[bestRep pixelsWide];
					int height=(int)[bestRep pixelsHigh];
					int x, y;
					XColor fg, bg;	// color for 1 and 0 bits resp.
					XGCValues attribs;
					Pixmap mask = XCreatePixmap(_display, root, width, height, 1);	// 1 bit draw/no draw (alpha)
					Pixmap bits = XCreatePixmap(_display, root, width, height, 1);	// 1 bit choose fg or bg;
					GC gc=XCreateGC(_display, mask, 0, &attribs);
					for(x=0; x<width; x++)
						{ // this loop is quite slow but we shouldn't change cursors very often
							for(y=0; y<height; y++)
								{ // fill pixmaps with cursor image
									NSUInteger planes[5]; // we assume RGBA
									BOOL alpha, white;
									[bestRep getPixel:planes atX:x y:(height-1)-y];
									white=299*planes[0]+587*planes[1]+114*planes[2] > 500*255;		// based on weighted intensity
									alpha=planes[3] > 128;
									XSetForeground(_display, gc, alpha?1:0);
									XDrawPoint(_display, mask, gc, x, y);
									XSetForeground(_display, gc, white?1:0);
									XDrawPoint(_display, bits, gc, x, y);
									if(white)
										; // average real color into fg color
									else
										; // average real color into bg color
								}
						}
					fg.red=65535;
					fg.green=65535;
					fg.blue=65535;
					bg.red=0;
					bg.green=0;
					bg.blue=0;
					// check _hotSpot to be >= 0 and <width/height
					_cursor = XCreatePixmapCursor(_display, bits, mask, &fg, &bg, _hotSpot.x, -_hotSpot.y);
					XFreeGC(_display, gc);
					XFreePixmap(_display, mask);
					XFreePixmap(_display, bits);
					}
				}
			}
		if(!_cursor)
			return None;	// did not initialize
		}
	return _cursor;
}

- (void) set;
{
#if 0
	NSLog(@"_setCursor:%@", self);
#endif
	// should we loop for all screens?
	// for(i=0; i<ScreenCount(_display); i++)
	XDefineCursor(_display, RootWindowOfScreen(XScreenOfDisplay(_display, 0)), [self _cursor]);
}

- (void) dealloc;
{
	if(_cursor)
		XFreeCursor(_display, _cursor);	// no longer needed
	[super dealloc];
}

@end

@implementation NSBezierPath (NSBackendOverride)

+ (id) allocWithZone:(NSZone *) z;
{
	return NSAllocateObject([_NSX11BezierPath class], 0, z?z:NSDefaultMallocZone());
}

@end

@implementation _NSX11BezierPath

static inline int compare_float(float a, float b)
{
	// can we speed up by comparing as a long int? IEEE floats are ordered properly if treated as a bitfield!
	if(a == b)
		return 0;
	return (a > b)?1:-1;
}

#ifdef __APPLE__
// for qsort_r()
static int tesselate_compare(void *elements, const void *idx1, const void *idx2)
{
	int cmp;
	int i1=*(int *) idx1;
	int i2=*(int *) idx2;
	PathElement *e1=((PathElement **)elements)[i1];
	PathElement *e2=((PathElement **)elements)[i2];
	cmp=compare_float(e1->points[0].y, e2->points[0].y);
	if(cmp == 0)
		cmp=compare_float(e1->points[0].x, e2->points[0].x);
	if(cmp == 0 && i1 != i2)	// same point, i.e. first and last in our polygon
		cmp=(i1 > i2)?1:-1;		// make sure that closepath comes after first move
	return cmp;
}
#else
extern void qsort3(void *const pbase, size_t total_elems, size_t size, int (*cmp)(id, id, void *), void *context);	// implemented in NSArray.m
static int tesselate_compare3(id idx1, id idx2, void *elements)
{
	int cmp;
	int i1=(int) idx1;	// we get passed elements from the pbase array
	int i2=(int) idx2;
	PathElement *e1=((PathElement **)elements)[i1];
	PathElement *e2=((PathElement **)elements)[i2];
	cmp=compare_float(e1->points[0].y, e2->points[0].y);
	if(cmp == 0)
		cmp=compare_float(e1->points[0].x, e2->points[0].x);
	if(cmp == 0 && i1 != i2)	// same point, i.e. first and last in our polygon
		cmp=(i1 > i2)?1:-1;		// make sure that closepath comes after first move
	return cmp;
}
#endif

- (void) _fill:(_NSX11GraphicsContext *) context color:(_NSX11Color *) color;

{ // based on Seidel's algorithm e.g. http://www.cs.unc.edu/~dm/CODE/GEM/chapter.html
	// should we correctly use Bentley-Ottman algorithm? http://geometryalgorithms.com/Archive/algorithm_0108/algorithm_0108.htm#Bentley-Ottmann%20Algorithm
	struct edge { int from, to; } *edges=NULL;	// current edge
	int nedges=0;
	int edgescapacity=0;
	int *bends;	// sorted array along the y axis
	NSInteger npoints=0;
	int i;
	NSPoint first=NSZeroPoint;
	// FIXME: use a different flag to indicate that we need recaching of the flattened path
	if((_bz.shouldRecalculateBounds && _flattenedPath) || !_bz.flat)
		{ // needs to (re)cache
			[_flattenedPath release];
			_flattenedPath=nil;
			[_strokedPath release];	// must be rebuilt
			_strokedPath=nil;
			_flattenedPath=(_NSX11BezierPath *)[[self bezierPathByFlatteningPath] retain];	// needs flattening first
		}
	if(_flattenedPath)
		{ // fill flattened version
			[_flattenedPath _fill:context color:color];
			return;
		}
	bends=(int *) objc_malloc(_count*sizeof(bends[0]));
	for(i=0; i<_count; i++)
		{ // fill sort array with indices of moveto, lineto, close
			PathElement *e=_bPath[i];
			if(i == 0 || e->type == NSMoveToBezierPathElement)
				first=e->points[0];
			else if(e->type == NSClosePathBezierPathElement)
				// FIXME: what if path is NOT closed?
				e->points[0]=first;	// make coordinate of first point known
			bends[i]=i;	// define initial index
		}
	npoints=_count;
#if __APPLE__	// if BSD compatible?
	qsort_r(bends, npoints, sizeof(bends[0]), _bPath, &tesselate_compare);	// sort along the y axis
#else
	qsort3(bends, npoints, sizeof(bends[0]), &tesselate_compare3, _bPath);
#endif
	for(i=0; i<npoints; i++)
		{ // process all edge points in sorted order
			int j, n;
			int y=bends[i];				// index of current point
			int pr=y-1, ne=y+1;			// previous and next in sequence
			BOOL any=NO;
			PathElement *e=_bPath[y];	// current point
			NSPoint trapezoid[4];	// bl, tl, br, tr - bl.y == br.y and tl.y == tr.y
#if 0
			NSLog(@"process %d: %@", bends[i], NSStringFromPoint(e->points[0]));
#endif
			if(e->type == NSClosePathBezierPathElement)
				{ // find matching moveTo as ne(xt) - use first point if we find none
					for(ne=y-1; ne > 0 && ((PathElement *) _bPath[ne])->type != NSMoveToBezierPathElement; ne--)
						if(((PathElement *) _bPath[ne-1])->type == NSClosePathBezierPathElement)
							break;	// close without move ends before next close
				}
			else if(e->type == NSMoveToBezierPathElement)
				{ // find matching closePath as pr(ev) - use last point if we find none
					for(pr=y+1; pr < npoints-1 && ((PathElement *) _bPath[pr])->type != NSClosePathBezierPathElement; pr++)
						if(((PathElement *) _bPath[pr+1])->type == NSMoveToBezierPathElement)
							break;	// move without close ends before next move
				}
			for(n=i+1; n<npoints; n++)
				{ // find index of nearest point in raising y direction
					if(bends[n] == pr || bends[n] == ne)
						break;	// found next edge
				}
			for(j=0; j<nedges; j++)
				{ // update edges or add/remove edges depending on current point
					if(edges[j].to == y)
						{ // found
							if(n < npoints)
								{ // a next edge was found, so move to next edge
									edges[j].from=y;
									edges[j].to=bends[n];
								}
							else
								{ // we are a termination point, remove this edge
									memmove(&edges[j], &edges[j+1], sizeof(edges[0])*(--nedges-j));
									j--;
								}
							any=YES;
						}
				}
			if(!any)
				{ // not found - we are an initial point - add edges to next and prev
					for(j=0; j<nedges; j++)
						{ // insert before nodes with larger x than e->points[0].x
							if((e->points[0].x-((PathElement *) _bPath[edges[j].from])->points[0].x)*
							   (((PathElement *) _bPath[edges[j].to])->points[0].y-((PathElement *) _bPath[edges[j].from])->points[0].y)
							   >
							   (e->points[0].y-((PathElement *) _bPath[edges[j].from])->points[0].y)*
							   (((PathElement *) _bPath[edges[j].to])->points[0].x-((PathElement *) _bPath[edges[j].from])->points[0].x)
							   )
								break;	// insert before since this one has a lower x coordinate on the y-level of the current point
						}
					nedges+=2;
					if(nedges >= edgescapacity)
						edges=(struct edge *) objc_realloc(edges, sizeof(edges[0])*(edgescapacity=2*edgescapacity+4));	// 4, 12, 28, 60, ...
					memmove(&edges[j+2], &edges[j], sizeof(edges[0])*(nedges-j-2));	// make room for two new edges
					edges[j].from=y;
					edges[j].to=pr;
					edges[j+1].from=y;
					edges[j+1].to=ne;
				}
#if 0
			{
			NSString *e=@"";
			for(j=0; j<nedges; j++)
				e=[e stringByAppendingFormat:@"%d-%d ", edges[j].from, edges[j].to];
			NSLog(@"edges: %@", e);
			}
#endif
			if(i+1 >= npoints)
				continue;	// no (more) edges to process
			trapezoid[0].y=((PathElement *) _bPath[y])->points[0].y;			// base level is current y coordinate
			trapezoid[1].y=((PathElement *) _bPath[bends[i+1]])->points[0].y;	// top level is next sorted y coordinate
			if(trapezoid[1].y - trapezoid[0].y < 1e-6)
				continue;	// immediately skip (nearly) zero height, i.e. horizontal edges
			trapezoid[2].y=trapezoid[0].y;										// same base level
			trapezoid[3].y=trapezoid[1].y;										// same top level
																				// FIXME: handle winding rule
			for(j=0; j<nedges; j+=2)
				{
				// CHECKME: XRenderCompositeTrapeziods can also calculate this based on integer variables!
				// could also handle multiple trapezoids in a single call
				// NOTE: it is not guaranteed that trapezoids[0/1] are the left and trapezoids[2/3] are on the right side
				NSPoint fm=((PathElement *) _bPath[edges[j].from])->points[0];
				NSPoint to=((PathElement *) _bPath[edges[j].to])->points[0];
				float slope=(to.x-fm.x)/(to.y-fm.y);	// can be 0.0 only for horizontal edges which have been ruled out before
				trapezoid[0].x=fm.x+slope*(trapezoid[0].y-fm.y);
				trapezoid[1].x=fm.x+slope*(trapezoid[1].y-fm.y);
				fm=((PathElement *) _bPath[edges[j+1].from])->points[0];
				to=((PathElement *) _bPath[edges[j+1].to])->points[0];
				slope=(to.x-fm.x)/(to.y-fm.y);
				trapezoid[2].x=fm.x+slope*(trapezoid[2].y-fm.y);
				trapezoid[3].x=fm.x+slope*(trapezoid[3].y-fm.y);
				/*
				 if you want to get triangles,
				 split the trapezoid along a diagonal into two triangles.
				 Or find the longer horizontal edge of each trapezoid,
				 split it by two and make 3 triangles
				 unless the shorter has zero width - then it is already a triangle
				 */

				[context _renderTrapezoid:trapezoid color:color];
				}
		}
	if(nedges > 0)
		NSLog(@"internal error - %d edges left over", nedges);
	objc_free(bends);
	if(edges)
		objc_free(edges);
}

- (void) _stroke:(_NSX11GraphicsContext *) context color:(_NSX11Color *) color
{
	// FIXME: use a different flag to indicate that we need recaching of the flattened path
	if((_bz.shouldRecalculateBounds && _flattenedPath) || !_bz.flat)
		{ // needs to (re)cache
			[_flattenedPath release];
			_flattenedPath=nil;
			[_strokedPath release];	// must be rebuilt
			_strokedPath=nil;
			_flattenedPath=(_NSX11BezierPath *)[[self bezierPathByFlatteningPath] retain];	// needs flattening first
		}
	if(_flattenedPath)
		{ // stroke flattened version
			[_flattenedPath _stroke:context color:color];
			return;
		}
	if(!_strokedPath)
		{

		// generate dashed rectangles handling joins etc. for the contour
		// Note: this is quite tricky since we have to handle any slope
		// And, making a line of thickness 3.0 means adding 1.5 to each direction
		// perpendicular to the line
		// So this needs some computing intense trigonometrical calculations!
		// Handling the joins means using arcs - which itself need flattening when being filled!
		// Dashing means summing up all lengths of line segments and to decide where to split them into disjoint segments
		// this at least requires to sum up distances sqrt(dx*dx+dy*dy) and then scale dx and dy

		/*
		 * if N is the unit normal vector on the line through P0, P1
		 * the four corners are P0+lineWidth/2*N, P0-lineWidth/2*N, P0+lineWidth/2*N, P0-lineWidth/2*N
		 *
		 * The line through the points is defined by
		 * - dy * x + dx * y = some constant
		 *
		 * therefore, N = (-dy, dx) / sqrt(dx*dx + dy*dy)
		 *
		 * so we can easily convert a stroke into a rect with given line width
		 *
		 * 1) having nice looking joins is more complex since we must merge two strokes in sequence
		 *    the outer part can be done by adding a circular segment
		 *    well, we must simply make the rect a little smaller so that they touch on one of the edges
		 *    and add a circle
		 *
		 * 2) having dashed lines is also more complex since we must split the rects into evenly distributed fragments
		 *    this may be quite simple: if we keep some float variable that says how much of the last dash goes to the
		 *    next fragment, we can walk along the line between P0 and P1 and define intermediate points that generate rects
		 *    one issue is how to handle closed lines elegantly if the last segment does not fit
		 */

		NSPoint pts[3];
		NSPoint coeff[4];
		NSPoint first_p, last_p=NSZeroPoint;
		int i;
		BOOL first = NO;
		NSLog(@"create stroke path");
		_strokedPath=(_NSX11BezierPath *)[[NSBezierPath alloc] init];
		for(i = 0; i < _count; i++)
			{
			NSBezierPathElement type=[self elementAtIndex: i associatedPoints: pts];
			switch(type)  {
				case NSMoveToBezierPathElement:
					[_strokedPath moveToPoint: pts[0]];
					first_p = last_p = pts[0];
					first = NO;
					break;
				case NSClosePathBezierPathElement:
				case NSLineToBezierPathElement:
				{
				float dx, dy;
				float nn;
				NSPoint p=NSZeroPoint;
				if (first)
					{ // NSMoveToBezierPathElement is missing
						first_p = last_p = pts[0];
						first = NO;
					}
				if(type == NSClosePathBezierPathElement)
					p = first_p;	// go back to first of this polygon
				else
					p = pts[0];
				dx=p.x-last_p.x;
				dy=last_p.y-p.y;
				nn=dx*dx + dy*dy;	// normalize
				if(nn >= 0.01)
					{ // ignore very short strokes
						nn=2.0*sqrt(nn);	// normalize
						if(_lineWidth > 0.0)
							nn /= _lineWidth;
						dx*=nn;
						dy*=nn;
						[_strokedPath moveToPoint:NSMakePoint(last_p.x-dy, last_p.y-dx)];
						[_strokedPath moveToPoint:NSMakePoint(last_p.x+dy, last_p.y+dx)];
						[_strokedPath moveToPoint:NSMakePoint(p.x+dy, p.y+dx)];
						[_strokedPath moveToPoint:NSMakePoint(p.x-dy, p.y-dy)];
						[_strokedPath closePath];	// make a closed rect
					}
				if(type == NSClosePathBezierPathElement)
					first = YES;	// start over
				break;
				}
				case NSCurveToBezierPathElement:
					NSAssert(NO, @"should have been flattened");
					break;
				default:
					break;
			}
			}
		}
	[_strokedPath _fill:context color:color];
}

- (void) setFlatness:(CGFloat)flatness
{
	_flatness = flatness;
	[_flattenedPath release];
	_flattenedPath=nil;
}

- (void) dealloc;
{
#if 0
	NSLog(@"dealloc %p flattened %p stroked %p", self, _flattenedPath, _strokedPath);
#endif
	[_flattenedPath release];
	[_strokedPath release];
	[super dealloc];
}

@end

@implementation NSShadow (NSBackendOverride)

- (void) set;
{
	// ignore
}

@end

// EOF
