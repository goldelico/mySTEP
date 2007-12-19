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
#import "NSApplication.h"
#import "NSAttributedString.h"
#import "NSBezierPath.h"
#import "NSColor.h"
#import "NSCursor.h"
#import "NSFont.h"
#import "NSGraphics.h"
#import "NSGraphicsContext.h"
#import "NSImage.h"
#import "NSScreen.h"
#import "NSWindow.h"
#import "NSPasteboard.h"

#if 1	// all windows are borderless, i.e. the frontend draws the title bar and manages windows directly
#define WINDOW_MANAGER_TITLE_HEIGHT 0
#else
#define WINDOW_MANAGER_TITLE_HEIGHT 23	// number of pixels added by window manager - the content view is moved down by that amount
#endif

#if __linux__	// this is needed for Sharp Zaurus (only) to detect the hinge status
#include <sys/ioctl.h>
#define SCRCTL_GET_ROTATION 0x413c
#endif

static BOOL _doubleBufferering=YES;	// DISABLED until we have solved all the setNeedsDisplay issues...

#pragma mark Class variables

static Display *_display;		// we can currently manage only one Display - but multiple Screens

static Atom _stateAtom;
static Atom _protocolsAtom;
static Atom _deleteWindowAtom;
static Atom _windowDecorAtom;

static NSArray *_XRunloopModes;	// runloop modes to handle X11 events

#if OLD
Window __xKeyWindowNeedsFocus = None;			// xWindow waiting to be focusd
extern Window __xAppTileWindow;
#endif

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
	switch(img->depth)
		{
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

inline static struct RGBA8 Pixel2RGBA8(int depth, unsigned int pixel)
{ // get RGBA8
	struct RGBA8 dest;
	// apply calibration curves/tables - we can read the tables from a file on the first call!
	switch(depth)
		{
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
	unsigned short F, G;
	switch(compositingOperation)
		{ // based on http://www.cs.wisc.edu/~schenney/courses/cs559-s2001/lectures/lecture-8-online.ppt
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
			F=dest->A, G=0;
			dest->R=(F*src->R)>>8;
			dest->G=(F*src->G)>>8;
			dest->B=(F*src->B)>>8;
			dest->A=(F*src->A)>>8;
			break;
		case NSCompositeSourceOut:
			F=255-dest->A, G=0;
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
			F=0, G=src->A;
			dest->R=(G*dest->R)>>8;
			dest->G=(G*dest->G)>>8;
			dest->B=(G*dest->B)>>8;
			dest->A=(G*dest->A)>>8;
			break;
		case NSCompositeDestinationOut:
			F=0, G=255-src->A;
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

static inline void XIntersect(XRectangle *result, XRectangle *with)
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

static inline void XUnion(XRectangle *result, XRectangle with)
{
#if 0
	NSLog(@"XUnion: %@ %@", NSStringFromXRect(*result), NSStringFromXRect(with));
#endif
	if(result->width == 0)
		result->x=with.x, result->width=with.width;	// first point
	else
		{
		if(with.x+with.width > result->x+result->width)
			result->width=with.x+with.width-result->x;			// extend to the right
		if(with.x < result->x)
			result->width+=result->x-with.x, result->x=with.x;	// extend to the left
		}
	if(result->height == 0)
		result->y=with.y, result->height=with.height;	// first point
	else
		{
		if(with.y+with.height > result->y+result->height)
			result->height=with.y+with.height-result->y;		// extend to the top
		if(with.y < result->y)
			result->height+=result->y-with.y, result->y=with.y;	// extend to the bottom
		}
#if 0
	NSLog(@"result: %@", NSStringFromXRect(*result));
#endif
}

static inline int _isDoubleBuffered(_NSX11GraphicsContext *win)
{
	return (((Window) win->_graphicsPort) != win->_realWindow);
}

static inline void _setDirtyRect(_NSX11GraphicsContext *win, int x, int y, unsigned width, unsigned height)
{ // enlarge dirty area for double buffer
	// FIXME: limit dirty area to clipping box!
	if(_isDoubleBuffered(win))
		XUnion(&win->_dirty, (XRectangle){x, y, width, height});
}

static inline void _setDirtyPoints(_NSX11GraphicsContext *win, XPoint *points, int npoints)
{
	// FIXME: limit dirty area to clipping box!
	if(_isDoubleBuffered(win))
		{
		int n=npoints;
		while(n-->0)
			XUnion(&win->_dirty, (XRectangle){points[n].x, points[n].y, 1, 1});
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
	GSAttributes attrs;
	NSRect frame;
	int styleMask;
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
	_xRect.height=NSMinY(_windowRect)-NSMaxY(_windowRect);	// _windowRect.size.heigh is negative (!)
	if(_xRect.width == 0) _xRect.width=48;
	if(_xRect.height == 0) _xRect.height=49;
#if 0
	NSLog(@"XCreateWindow(%@)", NSStringFromXRect(_xRect));	// _windowRect.size.heigh is negative
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
	self=[self _initWithGraphicsPort:(void *) win];
	if(backingType ==  NSBackingStoreBuffered && _doubleBufferering)
		{ // allocate a backing store buffer pixmap for our window
		XWindowAttributes attrs;
		XGetWindowAttributes(_display, win, &attrs);
		_graphicsPort=(void *) XCreatePixmap(_display, _realWindow, _xRect.width, _xRect.height, attrs.depth);
#if 0
		XCopyArea(_display,
				  _realWindow,
				  (Window) _graphicsPort, 
				  _state->_gc,
				  0, 0,
				  _xRect.width, _xRect.height,
				  0, 0);			// copy window background
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
	if((styleMask & NSClosableWindowMask))			// if window has close, button inform WM 
		XSetWMProtocols(_display, _realWindow, &_deleteWindowAtom, 1);
	attrs.window_level = [window level];
	attrs.flags = GSWindowStyleAttr|GSWindowLevelAttr;
	attrs.window_style = (styleMask & GSAllWindowMask);		// set WindowMaker WM
	XChangeProperty(_display, _realWindow, _windowDecorAtom, _windowDecorAtom,		// window style hints
					32, PropModeReplace, (unsigned char *)&attrs,
					sizeof(GSAttributes)/sizeof(CARD32));
	XFree(wm_hints);
	return self;
}

- (id) _initWithGraphicsPort:(void *) port;
{ // port should be the X11 Window *
#if 0
	NSLog(@"_NSX11GraphicsContext _initWithGraphicsPort:%@", attributes);
#endif
#if FIXME
	// get NSScreen/screen from port (Window *)
	_nsscreen=[window screen];
	// FIXME: read window size from screen!
	//	_windowRect=frame;
	// e.g. get size hints
#endif
	_graphicsPort=port;	// _window is a typed alias for _graphicsPort
	_realWindow=(Window) port;	// default is unbuffered
	_windowNum=(int) (_graphicsPort);	// we should get a system-wide unique integer (slot #) from the window list/level manager
	_scale=_nsscreen->_screenScale; 
	[self saveGraphicsState];	// initialize graphics state with transformations, GC etc. - don't use anything which depends on graphics state before here!
	XSelectInput(_display, _realWindow,
				 ExposureMask | KeyPressMask | 
				 KeyReleaseMask | ButtonPressMask | 
				 ButtonReleaseMask | ButtonMotionMask | 
				 StructureNotifyMask | PointerMotionMask | 
				 EnterWindowMask | LeaveWindowMask | 
				 FocusChangeMask | PropertyChangeMask | 
				 ColormapChangeMask | KeymapStateMask | 
				 VisibilityChangeMask);
	// query server for extensions
	return self;
}

- (void) dealloc
{
#if 1
	NSLog(@"NSWindow dealloc in backend: %@", self);
#endif
	if(_isDoubleBuffered(self))
		XFreePixmap(_display, (Pixmap) _graphicsPort);
	if(_realWindow)
		{
		NSMapRemove(__WindowNumToNSWindow, (void *) _windowNum);	// Remove X11 Window to NSWindows mapping
		XDestroyWindow(_display, _realWindow);						// Destroy the X Window
		XFlush(_display);
		}
	// here we could check if we were the last window and XDestroyWindow(_display, xAppRootWindow); XCloseDisplay(_display);
	[super dealloc];
}

- (BOOL) isDrawingToScreen	{ return YES; }

#pragma mark PDFOperators

- (void) _setColor:(NSColor *) color;
{
	unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
	NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
	XSetBackground(_display, _state->_gc, pixel);
	XSetForeground(_display, _state->_gc, pixel);
}

- (void) _setFillColor:(NSColor *) color;
{
	unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
	NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
	XSetBackground(_display, _state->_gc, pixel);
	XSetForeground(_display, _state->_gc, pixel);
}

- (void) _setStrokeColor:(NSColor *) color;
{
	unsigned long pixel=[(_NSX11Color *)color _pixelForScreen:_nsscreen->_screen];
#if 0
	NSLog(@"_setColor -> pixel=%08x", pixel);
#endif
	XSetForeground(_display, _state->_gc, pixel);
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
	[_state->_ctm prependTransform:atm];
#if 0
	NSLog(@"_setCTM -> %@", _state->_ctm);
#endif
}

- (void) _concatCTM:(NSAffineTransform *) atm;
{
	[_state->_ctm prependTransform:atm];
#if 0
	NSLog(@"_concatCTM -> %@", _state->_ctm);
#endif
}

- (void) _setCompositing
{
	XGCValues values;
	switch(_compositingOperation)
		{
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
	unsigned element;	// current element being expanded
	unsigned elements;	// number of elements in path
	XPoint *points;		// points array
	XPoint lastpoint;
	int npoints;		// number of entries in array
	unsigned capacity;	// how many elements are allocated
} PointsForPathState;

static inline void addPoint(PointsForPathState *state, NSPoint point)
{
	XPoint pnt;
	if(state->npoints >= state->capacity)
		state->points=(XPoint *) objc_realloc(state->points, sizeof(state->points[0])*(state->capacity=2*state->capacity+5));	// make more room
	pnt.x=point.x;		// convert to integer
	pnt.y=point.y;
	if(state->npoints == 0 || pnt.x != state->lastpoint.x || pnt.y != state->lastpoint.y)
		{ // first or really different
		state->lastpoint=pnt;
		state->points[state->npoints++]=pnt;	// store point
		}
#if 0
	else
		NSLog(@"addPoint duplicate ignored:(%d, %d)", pnt.x, pnt.y);
#endif
#if 0
	NSLog(@"addPoint:(%d, %d)", (int) point.x, (int) point.y);
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
	NSPoint first, current, next;
	NSBezierPathElement element;
	if(state->element == 0)
		state->elements=[state->path elementCount];	// initialize
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
		switch(element)
			{
			case NSMoveToBezierPathElement:
				current=first=[_state->_ctm transformPoint:points[0]];
				addPoint(state, current);
				break;
			case NSLineToBezierPathElement:
				next=[_state->_ctm transformPoint:points[0]];
				addPoint(state, next);
				current=next;
				break;
			case NSCurveToBezierPathElement:
				{
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
#endif
					// FIXME: we should adjust the step size to the size of the path
					for(t=0.1; t<=0.9; t+=0.1)
						{ // very simple and slow approximation
						float t1=(1.0-t);
						float t12=t1*t1;
						float t13=t1*t12;
						float t2=t*t;
						float t3=t*t2;
						NSPoint pnt;
						pnt.x=p0.x*t13+3.0*(p1.x*t*t12+p2.x*t2*t1)+p3.x*t3;
						pnt.y=p0.y*t13+3.0*(p1.y*t*t12+p2.y*t2*t1)+p3.y*t3;
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
				region=XPolygonRegion(state.points, state.npoints, [path windingRule] == NSNonZeroWindingRule?WindingRule:EvenOddRule);
			}
		else
			NSLog(@"can't handle complex winding rules"); // else  FIXME: build the Union or intersection of both (depending on winding rule)
		}
	return region;
}

- (void) _stroke:(NSBezierPath *) path;
{
	PointsForPathState state={ path };	// initializes other struct components with 0
	float *pattern=NULL;	// FIXME: who is owner of this data? and who takes care not to overflow?
	int count;
	float phase;
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
	if(count)
		{
		char dash_list[count];	// FIXME: this can overflow stack! => security risk by bad PDF files
		int i;
		for(i = 0; i < count; i++)
			dash_list[i] = (char) pattern[i];		
		XSetDashes(_display, _state->_gc, phase, dash_list, count);
		}
	while([self _pointsForPath:&state])
		{
#if 0
		NSLog(@"npoints=%d", state.npoints);
#endif
		XDrawLines(_display, ((Window) _graphicsPort), _state->_gc, state.points, state.npoints, CoordModeOrigin);
		_setDirtyPoints(self, state.points, state.npoints);
		}
}

- (void) _fill:(NSBezierPath *) path;
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

- (void) _setClip:(NSBezierPath *) path;
{
#if 0
	NSLog(@"_setClip");
#endif
	if(_state->_clip)
		XDestroyRegion(_state->_clip);	// delete previous
	_state->_clip=[self _regionFromPath:path];
	// check for Rect region
	XSetRegion(_display, _state->_gc, _state->_clip);
#if 0
	{
		XRectangle box;
		XClipBox(_state->_clip, &box);
		NSLog(@"_setClip box=((%d,%d),(%d,%d))", box.x, box.y, box.width, box.height);
	}
#endif
}

- (void) _addClip:(NSBezierPath *) path;
{
	Region r;
#if 0
	NSLog(@"_addClip");
#endif
	r=[self _regionFromPath:path];
	if(_state->_clip)
		{
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
	else
		_state->_clip=r;	// first call
	XSetRegion(_display, _state->_gc, _state->_clip);
#if 0
	{
		XRectangle box;
		XClipBox(_state->_clip, &box);
		NSLog(@"         box=%@", NSStringFromXRect(box));
	}
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

- (void) _setFont:(NSFont *) font;
{
	if(!font || font == _state->_font)
		return;	// change only if needed
	[_state->_font release];
	_state->_font=[font retain];
}

- (void) _beginText;
{
	// FIXME: we could postpone using the CTM until we really draw text
	_cursor=[_state->_ctm transformPoint:NSZeroPoint];	// start at (0,0)
	_baseline=0;
}

- (void) _endText; { return; }

- (void) _setTextPosition:(NSPoint) pos;
{ // PDF: x y Td
  // FIXME: we could postpone the CTM until we really draw text
	_cursor=[_state->_ctm transformPoint:pos];
#if 0
	NSLog(@"_setTextPosition %@ -> %@", NSStringFromPoint(pos), NSStringFromPoint(_cursor));
#endif
}

- (void) _setLeading:(float) lead;
{ // PDF: x TL
	NIMP;
}

// FIXME: this does not properly handle rotated coords and newline

- (void) _newLine;
{ // PDF: T*
	NIMP;
}

// we need a command to set x-pos (only)

- (void) _setBaseline:(float) val;
{
	_baseline=val;
}

// FIXME:
// does not handle rotation
// ignores CTM scaling (mostly!)

- (void) _drawGlyphBitmap:(unsigned char *) buffer x:(int) x y:(int) y width:(unsigned) width height:(unsigned) height;
{ // paint to screen
	// we could also (re)use an NSBitmapImageRep and fill it appropriately by alpha/rgb
	// the bitmap is a grey level bitmap - so how do we colorize?
	// how do we handle compositing?
	XImage *img;
	int screen_number=XScreenNumberOfScreen(_nsscreen->_screen);
	int pxx, pxy;
	XGCValues values;
	BOOL mustFetch;
	struct RGBA8 stroke;
	x+=_cursor.x;	// relative to cursor position
	y+=_cursor.y;
#if 0
	NSLog(@"_drawGlyphBitmap");
	NSLog(@"size={%d %d}", width, height);
	NSLog(@"font=%@", _state->_font);
#endif
	// CHECKME: does the compositing operation apply to text drawing?
//	mustFetch=_compositingOperation != NSCompositeClear && _compositingOperation != NSCompositeCopy &&
//		_compositingOperation != NSCompositeSourceIn && _compositingOperation != NSCompositeSourceOut;
	mustFetch=YES;
	if(mustFetch)
		{ // we must really fetch the current image from our context
			// FIXME: this is quite slow even if we have double buffering!
		img=XGetImage(_display, ((Window) _graphicsPort),
						x, y, width, height,
						AllPlanes, ZPixmap);
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
		return;	// can't allocate or fetch
	XGetGCValues(_display, _state->_gc, GCForeground | GCBackground, &values);
	stroke = Pixel2RGBA8(img->depth, values.foreground);	// translate 565 or 888 color to RGBA8
	for(pxy=0; pxy<height; pxy++)
		{ // composite all pixels
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
	XPutImage(_display, ((Window) _graphicsPort), _state->_gc, img, 0, 0, x, y, width, height);	
	_setDirtyRect(self, x, y, width, height);
	XDestroyImage(img);
}

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt;
{
	BACKEND;	// overwritten in NSFreeType.m
}

- (void) _drawGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt;	// (string) Tj
{
	static XChar2b *buf;	// translation buffer (NSGlyph -> XChar2b)
	static unsigned int buflen;
	unsigned int i;
	XFontStruct *font;
#if 0
	NSLog(@"NSString: _drawGlyphs:%p count:%u font:%@", glyphs, cnt, _state->_font);
#endif
	if([_state->_font renderingMode] == NSFontIntegerAdvancementsRenderingMode)
		{ // use the basic X11 bitmap font rendering services
		[_state->_font _setScale:_scale];
		font=[_state->_font _font];
		XSetFont(_display, _state->_gc, font->fid);	// set font-ID in GC
													// set any other attributes
		[self _setCompositing];	// use X11 compositing
#if 0
		{
			XRectangle box;
			XClipBox(_state->_clip, &box);
			NSLog(@"draw %u glyphs at (%d,%d) clip=%@", cnt, (int)_cursor.x, (int)(_cursor.y-_baseline+font->ascent+1), NSStringFromXRect(box));
		}
#endif
		if(!buf || cnt > buflen)
			buf=(XChar2b *) objc_realloc(buf, sizeof(buf[0])*(buflen=cnt+20));	// increase translation buffer if needed
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
					  _cursor.x, (int)(_cursor.y-_baseline+font->ascent+1),	// X11 defines y as the character baseline
																			// NOTE:
																			// XChar2b is a struct which may be 4 bytes locally depending on struct alignment rules!
																			// But here it appears to work since Xlib appears to assume that there are 2*length bytes to send to the server
					  buf,
					  cnt);		// Unicode drawing
		if(sizeof(XChar2b) != 2)
			{ // fix subtle bug when struct alignment rules of the compiler make XChar2b larger than 2 bytes
			for(i=0; i<cnt; i++)
				{ 
				NSGlyph g=glyphs[i];
				buf[i].byte1=g>>8;
				buf[i].byte2=g;
				}
			}
		_setDirtyRect(self,
					  _cursor.x, _cursor.y,
					  XTextWidth16(font, buf, cnt),
					  font->ascent + font->descent);	// we need to ask XTextString16 for the line width!
		}
	else
		{ // use Freetype
		[_state->_font _drawAntialisedGlyphs:glyphs count:cnt inContext:self];
		}
}

- (void) _beginPage:(NSString *) title;
{ // can we (mis-)use that as setTitle???
	return;
}

- (void) _endPage; { return; }

- (void) _setFraction:(float) fraction;
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
	NSString *csp;
	int bytesPerRow;
	BOOL hasAlpha;
	BOOL isPlanar;
	float width, height;	// source image width&height
	unsigned char *imagePlanes[5];
	NSPoint origin;
	XRectangle box;			// relevant subarea to draw to
	NSRect scanRect;		// dest on screen in X11 coords
	BOOL isFlipped;
	BOOL calibrated;
	NSAffineTransform *atm;	// projection from X11 window-relative to bitmap coordinates
	NSAffineTransformStruct atms;
	XRectangle xScanRect;	// on X11 where XImage is coming from
	XImage *img;
	int x, y;				// current position within XImage
	NSPoint pnt;			// current pixel in bitmap
	unsigned short fract=256.0*_fraction+0.5;
	XGCValues values;
	BOOL mustFetch;
	if(fract > 256)
		fract=256;	// limit
	/*
	 * check if we can draw
	 */
	if(!rep)	// could check for NSBitmapImageRep
		{
		NSLog(@"_draw: nil representation!");
		// raise exception
		return NO;
		}
	hasAlpha=[rep hasAlpha];
	isPlanar=[(NSBitmapImageRep *) rep isPlanar];
	bytesPerRow=[(NSBitmapImageRep *) rep bytesPerRow];
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
	origin=[_state->_ctm transformPoint:NSZeroPoint];	// determine real drawing origin in X11 coordinates
	scanRect=[_state->_ctm _boundingRectForTransformedRect:unitSquare];	// get bounding box for transformed unit square
#if 0
	NSLog(@"_draw: %@", rep);
	NSLog(@"context %@", self);
	NSLog(@"window number %d", _windowNum);
	NSLog(@"window %@", [NSWindow _windowForNumber:_windowNum]);
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
	XClipBox(_state->_clip, &box);	// clip as defined by drawing code
	// FIXME: clip by screen rect (if window is partially offscreen)
	/*
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
	NSLog(@"  clip box=%@", NSStringFromXRect(box));
#endif
	XIntersect(&xScanRect, &box);
#if 0
	NSLog(@"  final scan box=%@", NSStringFromXRect(xScanRect));
#endif
	if(xScanRect.width == 0 || xScanRect.height == 0)
		return YES;	// empty
	/*
	 * calculate reverse projection from XImage pixel coordinate to bitmap coordinate
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

	// FIXME: make more general function - (BOOL) _render:(struct RGB8 (*)(int x, int y, void *context)) sampler xScanRect:(XRect) scanRect context:(void *) context  
	
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
		//		NS_DURING
		{
			// FIXME: this is quite slow even if we have double buffering!
#if 0
			NSLog(@"XGetImage(%d, %d, %u, %u)", xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
#endif
			img=XGetImage(_display, ((Window) _graphicsPort),
						  xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height,
						  AllPlanes, ZPixmap);
#if 0
			NSLog(@"got %p", img);
#endif
		}
		//		NS_HANDLER
		//			NSLog(@"_composite: could not fetch current screen contents due to %@", [localException reason]);
		//			img=nil;	// ignore for now
		//		NS_ENDHANDLER
		}
	else
		{ // we can simply create a new rectangular image and don't use anything existing
		int screen_number=XScreenNumberOfScreen(_nsscreen->_screen);
#if 0
		NSLog(@"XCreateImage(%u, %u)", xScanRect.width, xScanRect.height);
#endif
		// FIXME: can we reuse this?
		img=XCreateImage(_display, DefaultVisual(_display, screen_number), DefaultDepth(_display, screen_number),
						 ZPixmap, 0, NULL,
						 xScanRect.width, xScanRect.height,
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
		NSLog(@"could not XGetImage or XCreateImage");
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
	XFillRectangle(_display, ((Window) _graphicsPort), _state->_gc, xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
#endif
	/*
	 * draw by scanning lines
	 */
	for(y=0; y<img->height; y++)
		{
		struct RGBA8 src={0,0,0,255}, dest={0,0,0,255};	// initialize
		// FIXME: we must adjust x&y if we have clipped, i.e. x&y are not aligned with the dest origin
		pnt.x=/*atms.m11*(0)+*/ -atms.m12*(y)+atms.tX;	// first point of this scan line
		pnt.y=/*atms.m21*(0)+*/ atms.m22*(y)+atms.tY;
		for(x=0; x<img->width; x++, pnt.x+=atms.m11, pnt.y-=atms.m21)
			{
			if(mustFetch)
				dest=XGetRGBA8(img, x, y);	// get current image value
			if(_compositingOperation != NSCompositeClear)
				{ // get smoothed RGBA from bitmap
				// we should pipeline this through core-image like filter modules
				switch(_imageInterpolation)
					{
					case NSImageInterpolationDefault:	// default is same as low
					case NSImageInterpolationLow:
						// FIXME: here we should inter/extrapolate adjacent source points
					case NSImageInterpolationHigh:
						// FIXME: here we should inter/extrapolate adjacent source points
					case NSImageInterpolationNone:
						{
							// should interpolate several pixels
							src=getPixel((int) pnt.x, (int) pnt.y, width, height,
										 /*
										  int bitsPerSample,
										  int samplesPerPixel,
										  int bitsPerPixel,
										  */
										 bytesPerRow,
										 isPlanar, hasAlpha,
										 imagePlanes);
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
	NSLog(@"XPutImage(%d, %d, %u, %u)", xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
#endif	
	values.function=GXcopy;
	XChangeGC(_display, _state->_gc, GCFunction, &values);	// use X11 copy compositing
	XPutImage(_display, ((Window) _graphicsPort), _state->_gc, img, 0, 0, xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
	XDestroyImage(img);
	_setDirtyRect(self, xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
#if 0
	[[NSColor redColor] set];	// will change _gc
	XDrawRectangle(_display, ((Window) _graphicsPort), _state->_gc, xScanRect.x, xScanRect.y, xScanRect.width, xScanRect.height);
#endif
	return YES;
}

// FIXME: this uses the current translated composition operation!!!

- (void) _copyBits:(void *) srcGstate fromRect:(NSRect) srcRect toPoint:(NSPoint) destPoint;
{ // copy srcRect using CTM from (_NSX11GraphicsState *) srcGstate to destPoint transformed by current CTM
	srcRect.origin=[((_NSX11GraphicsState *) srcGstate)->_ctm transformPoint:srcRect.origin];
	srcRect.size=[((_NSX11GraphicsState *) srcGstate)->_ctm transformSize:srcRect.size];
	destPoint=[_state->_ctm transformPoint:destPoint];
#if 1
	NSLog(@"_copyBits from %@ to %@", NSStringFromRect(srcRect), NSStringFromPoint(destPoint));
#endif
	XCopyArea(_display,
			  (Window) (((_NSGraphicsState *) srcGstate)->_context->_graphicsPort),	// source window/bitmap
			  ((Window) _graphicsPort), _state->_gc,
			  srcRect.origin.x, srcRect.origin.y,
			  srcRect.size.width, /*-*/srcRect.size.height,
			  destPoint.x, destPoint.y);
	_setDirtyRect(self, destPoint.x, destPoint.y, srcRect.size.width, srcRect.size.height);
}

#pragma mark WindowControl

- (void) _setCursor:(NSCursor *) cursor;
{
#if 0
	NSLog(@"_setCursor:%@", cursor);
#endif
	XDefineCursor(_display, _realWindow, [(_NSX11Cursor *) cursor _cursor]);
}

- (int) _windowNumber; { return _windowNum; }

	// FIXME: NSWindow frontend should identify the otherWin from the global window list

- (void) _orderWindow:(NSWindowOrderingMode) place relativeTo:(int) otherWin;
{
	XWindowChanges values;
#if 0
	NSLog(@"_orderWindow:%02x relativeTo:%d", place, otherWin);
#endif
	if([[NSWindow _windowForNumber:_windowNum] isMiniaturized])	// FIXME: used as special trick not to really map the window during init
		return;
	switch(place)
		{
		case NSWindowOut:
			XUnmapWindow(_display, _realWindow);
			break;
		case NSWindowAbove:
			XMapWindow(_display, _realWindow);	// if not yet
			values.sibling=otherWin;		// 0 will order front
			values.stack_mode=Above;
			XConfigureWindow(_display, _realWindow, CWStackMode, &values);
			break;
		case NSWindowBelow:
			XMapWindow(_display, _realWindow);	// if not yet
			values.sibling=otherWin;		// 0 will order back
			values.stack_mode=Below;
			XConfigureWindow(_display, _realWindow, CWStackMode, &values);
			break;
		}
	// save (new) level so that we can order other windows accordingly
	// maybe we should use a window property to store the level?
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
			{
			XWindowAttributes attrs;
	#if 1
			NSLog(@"resize backing store buffer");
	#endif
			XGetWindowAttributes(_display, _realWindow, &attrs);
			XFreePixmap(_display, (Pixmap) _graphicsPort);
			_graphicsPort=(void *) XCreatePixmap(_display, _realWindow, _xRect.width, _xRect.height, attrs.depth);
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
	const char *newTitle = [string cString];	// UTF8String??
	XStringListToTextProperty((char**) &newTitle, 1, &windowName);
	XSetWMName(_display, _realWindow, &windowName);
	XSetWMIconName(_display, _realWindow, &windowName);
	// XStoreName???
}

- (void) _setLevel:(int) level;
{ // note: it is the task of NSWindow to call this only if setLevel really changes the level
#if 1
	NSLog(@"setLevel of window %d", level);
#endif
	/*
	 attrs.window_level = [window level];
	 attrs.flags = GSWindowStyleAttr|GSWindowLevelAttr;
	 attrs.window_style = (styleMask & GSAllWindowMask);
	 XChangeProperty(_display, _realWindow, _windowDecorAtom, _windowDecorAtom,		// window style hints
					 32, PropModeReplace, (unsigned char *)&attrs,
					 sizeof(GSAttributes)/sizeof(CARD32));
	 */
}

- (void) _makeKeyWindow;
{
	XSetInputFocus(_display, _realWindow, RevertToNone, CurrentTime);
}

- (NSRect) _frame;
{ // get current frame as on screen (might have been moved by window manager)
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
	XClipBox(_state->_clip, &box);
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
	_NSX11GraphicsState *new=(_NSX11GraphicsState *) objc_malloc(sizeof(*new));
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
#if 0
			{
				XRectangle box;
				XClipBox(_state->_clip, &box);
				NSLog(@"copy clip box=%@", NSStringFromXRect(box));
			}
#endif
			}
		else
			new->_clip=NULL;	// not clipped
		}
	else
		{ // alloc
		new->_ctm=nil;		// no initial screen transformation (set by first lockFocus)
		new->_clip=NULL;	// not clipped
		new->_font=nil;
		}
	return (_NSGraphicsState *) new;
}

- (void) restoreGraphicsState;
{
	if(!_graphicsState)
		return;
	if(_state->_ctm)
		[_state->_ctm release];
	if(_state->_clip)
		XDestroyRegion(_state->_clip);
	if(_state->_gc)
		XFreeGC(_display, _state->_gc);
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
{
	XImage *img;
	struct RGBA8 pix;
	NSColor *c;
	location=[_state->_ctm transformPoint:location];
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
	img=XGetImage(_display, _realWindow,
				  rect.origin.x, rect.origin.y, rect.size.width, -rect.size.height,
				  AllPlanes, ZPixmap);
	// FIXME: copy pixels to bitmap
	XDestroyImage(img);
}

- (void) flushGraphics;
{
#if 0
	NSLog(@"X11 flushGraphics");
#endif
	if(_isDoubleBuffered(self) && _dirty.width > 0 && _dirty.height > 0)
		{ // copy dirty area (if any) from back to front buffer
		static GC neutralGC;	// this is a GC with neutral image processing options
#if 1
		NSLog(@"flushing backing store buffer: %@", NSStringFromXRect(_dirty));
#endif
		if(!neutralGC)
			neutralGC=XCreateGC(_display, (Window) _graphicsPort, 0, NULL);	// create a default GC
		XCopyArea(_display,
				  ((Window) _graphicsPort), 
				  _realWindow,
				  neutralGC,
				  _dirty.x, _dirty.y,
				  _dirty.width, _dirty.height,
				  _dirty.x, _dirty.y);
		_dirty=(XRectangle){ 0, 0, 0, 0 };	// clear
		}
	XFlush(_display);
}

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
	
	switch(keysym)
		{
		case XK_Return:
		case XK_KP_Enter:
		case XK_Linefeed:
			return '\r';
		case XK_Tab:
			return '\t';
		case XK_space:
			return ' ';
		}
	if ((keysym >= XK_F1) && (keysym <= XK_F35)) 			// if a function
		{													// key was pressed
		*eventModFlags |= NSFunctionKeyMask; 
		switch(keysym)	// FIXME: why not use keysym here??
			{
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
	else 
		{
		switch(keysym) 
			{
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
		
		if(keyCode)
			*eventModFlags |= NSFunctionKeyMask;
		else
			{ // other keys to handle
			if ((keysym == XK_Shift_L) || (keysym == XK_Shift_R))
				*eventModFlags |= NSFunctionKeyMask | NSShiftKeyMask; 
			else if ((keysym == XK_Control_L) || (keysym == XK_Control_R))
				*eventModFlags |= NSFunctionKeyMask | NSControlKeyMask; 
			else if ((keysym == XK_Alt_R) || (keysym == XK_Meta_R))
				*eventModFlags |= NSAlternateKeyMask;
			else if ((keysym == XK_Alt_L) || (keysym == XK_Meta_L))
				*eventModFlags |= NSCommandKeyMask | NSAlternateKeyMask; 
			else if ((keysym == XK_Mode_switch))
				*eventModFlags |= NSCommandKeyMask | NSAlternateKeyMask; 
			}
		}
	
	if ((keysym > XK_KP_Space) && (keysym < XK_KP_9)) 		// If the key press
		{													// originated from
		*eventModFlags |= NSNumericPadKeyMask;				// the key pad
		
		switch(keysym) 
			{
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
		{ NULL} };
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
	NSLog(@"  sequence: %u:%u", LastKnownRequestProcessed(display), NextRequest(display));
	if(requests[i].name)
		NSLog(@"  request: %u:%u %s(%u).%u", requests[i].name, error_event->request_code, error_event->minor_code);
	else
		NSLog(@"  request: %u.%u", error_event->request_code, error_event->minor_code);
    NSLog(@"  resource: %lu", error_event->resourceid);
	if(error_event->request_code == 73)
		return;
#if 1
	*((long *) 1)=0;	// force SEGFAULT to ease debugging by writing a core dump
	abort();
#endif
	[NSException raise:NSGenericException format:@"X11 Internal Error"];	
}  /* X11ErrorHandler */

@implementation NSGraphicsContext (NSBackendOverride)

+ (NSGraphicsContext *) graphicsContextWithGraphicsPort:(void *) port flipped:(BOOL) flipped;
{
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

+ (int) _getLevelOfWindowNumber:(int) windowNum;
{ // even if it is not a NSWindow
	Atom actual_type_return;
	int actual_format_return;
	unsigned long nitems_return;
	unsigned long bytes_after_return;
	unsigned char *prop_return;
	int level;
	Display *_display;
#if 1
	NSLog(@"getLevel of window %d", windowNum);
#endif
	
	return 0;
	
	if(!XGetWindowProperty(_display, (Window) windowNum, _windowDecorAtom, 0, 0, False, _windowDecorAtom, 
						   &actual_type_return, &actual_format_return, &nitems_return, &bytes_after_return, &prop_return))
		return 0;
	level=((GSAttributes *) prop_return)->window_level;
	XFree(prop_return);
#if 1
	NSLog(@"  = %d", level);
#endif
	return level;
}

+ (NSWindow *) _windowForNumber:(int) windowNum;
{
#if 0
	NSLog(@"_windowForNumber %d -> %@", windowNum, NSMapGet(__WindowNumToNSWindow, (void *) windowNum));
#endif
	return NSMapGet(__WindowNumToNSWindow, (void *) windowNum);
}

+ (NSArray *) _windowList;
{ // get all NSWindows of this application
#if COMPLEX
	int count;
	int context=getpid();	// filter only our windows!
	NSCountWindowsForContext(context, &count);
	if(count)
		{
		int list[count];	// get window numbers
		NSMutableArray *a=[NSMutableArray arrayWithCapacity:count];
		NSWindowList(context, count, list);
		for(i=0; i<count; i++)
			[a addObject:NSMapGet(__WindowNumToNSWindow, (void *) list[i]);	// translate to NSWindows
				return a;
		}
return nil;
#endif
if(__WindowNumToNSWindow)
return NSAllMapTableValues(__WindowNumToNSWindow);		// all windows we currently know by window number
return nil;
}

@end

@implementation NSScreen (NSBackendOverride)

+ (void) initialize;	// called when looking at the first screen
{
	[_NSX11Screen class];
}

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

+ (int) _windowListForContext:(int) context size:(int) size list:(int *) list;	// list may be NULL, return # of entries copied
{ // get window numbers from front to back
	int i, j, s;
	Window *children;	// list of children
	unsigned int nchildren;
	// this mus be a) fast, b) front2back, c) allow for easy access to the window level, d) returns internal window numbers and not NSWindows e) for potentially ALL applications
	// where can we get that from? a) from the Xserver, b) from a local shared file (per NSScreen), c) from a property attached to the Sceen and/or the Windows (WM_HINTS?)
#if OLD
	///
	/// the task is to fill with up to size window number (front to back)
	/// and filtered by context (pid?) if that is != 0
	///
	/*
	 or do we use a shared file to store window levels and stacking order?
	 struct XLevel {
		 unsigned long nextToBack;
		 long context;	// pid()
		 long level;
		 Window window;
	 };
	 
	 XQueryTree approach must fail since it does not return appropriate stacking order for child windows with different parent!!!
	 
	 */
#endif
	for(s=0; s<ScreenCount(_display); s++)
		{
#if 1
		NSLog(@"XQueryTree");
#endif
		if(!XQueryTree(_display, RootWindowOfScreen(XScreenOfDisplay(_display, s)), NULL, NULL, &children, &nchildren))
			return 0;	// failed
#if 1
		NSLog(@"  nchildren= %d", nchildren);
#endif
		for(i=nchildren-1, j=0; i>0; i--)
			{
			if(context != 0 && 0 /* not equal */)
				{
				// what is context? A client ID? A process ID?
				continue;	// skip since it is owned by a different application
				}
			if(list)
				{
				if(j >= size)
					break;	// done
				list[j++]=(int) children[i];	// get windows in front2back order (i.e. reverse) and translate to window numbers
				}
			}
		XFree(children);
		}
	return i;
}

@end

@implementation _NSX11Screen

static NSDictionary *_x11settings;

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
	NSFileHandle *fh;
	NSUserDefaults *def=[[[NSUserDefaults alloc] initWithUser:@"root"] autorelease];
#if 1
	NSLog(@"NSScreen backend +initialize");
	//	system("export;/usr/X11R6/bin/xeyes&");
#endif
	_x11settings=[[def persistentDomainForName:@"com.quantumstep.X11"] retain];
	if([def boolForKey:@"NoNSBackingStoreBuffered"])
		_doubleBufferering=NO;
#if 1
	NSLog(@"%@", _doubleBufferering?@"backing store is buffered":@"directly to X11");
#endif
#if 0
	XInitThreads();	// make us thread-safe
#endif
	if((_display=XOpenDisplay(NULL)) == NULL) 		// connect to X server based on DISPLAY variable
		[NSException raise:NSGenericException format:@"Unable to connect to X server"];
	XSetErrorHandler((XErrorHandler)X11ErrorHandler);
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
										 // Well, this keeps the UI responsive if DO is multi-threaded but might als lead to strange synchronization issues (nested runloops)
		NSConnectionReplyMode,
#endif
		NSModalPanelRunLoopMode,
		NSEventTrackingRunLoopMode,
		nil];
	[fh waitForDataInBackgroundAndNotifyForModes:_XRunloopModes];
    if(XInternAtoms(_display, atomNames, sizeof(atomNames)/sizeof(atomNames[0]), False, atoms) == 0)
		[NSException raise: NSGenericException format:@"XInternAtoms()"];
    _stateAtom = atoms[0];
    _protocolsAtom = atoms[1];
    _deleteWindowAtom = atoms[2];
    _windowDecorAtom = atoms[3];
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

- (float) userSpaceScaleFactor;
{ // get dots per point	
	static float factor;
	if(factor <= 0.01)
		{
		factor=[[_x11settings objectForKey:@"userSpaceScaleFactor"] floatValue];
		if(factor <= 0.01) factor=1.0;
		}
	return factor;	// read from user settings
#if 0	
	NSSize dpi=[[[self deviceDescription] objectForKey:NSDeviceResolution] sizeValue];
	return (dpi.width+dpi.height)/144;	// take average for 72dpi
#endif
}

- (NSDictionary *) deviceDescription;
{
	if(!_device)
		{ // (re)load resolution
		BOOL changed=NO;
		NSSize size, resolution;
		_screenScale=[[_x11settings objectForKey:@"systemSpaceScaleFactor"] floatValue];
#if 0
		NSLog(@"system space scale factor=%lf", _screenScale);
#endif
		if(_screenScale <= 0.01) _screenScale=1.0;
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
#if __APPLE__
		size.height-=[self _windowTitleHeight]/_screenScale;	// subtract menu bar of X11 server from frame
#endif
#if 0
		NSLog(@"_screen2X11=%@", (NSAffineTransform *) _screen2X11);
#endif
#if __linux__
		if(XDisplayString(_display)[0] == ':' ||
		   strncmp(XDisplayString(_display), "localhost:", 10) == 0)
			{ // local server
			static int fd=-1;
			int r;
			if(fd < 0)
				fd=open("/dev/apm_bios", O_RDWR|O_NONBLOCK);
			if(fd < 0)
				NSLog(@"Failed to open /dev/apm_bios");
			else
				{
				r=ioctl(fd, SCRCTL_GET_ROTATION);
#if 1
				NSLog(@"hinge state=%d", r);
#endif
				switch(r)
					{
					case -1:
						break;	// unsupported ioctl
					default:
						NSLog(@"unknown hinge state %d", r);
						break;
					case 3:	// Case Closed
						break;
					case 2:	// Case open & portrait
						{ // swap x and y
						  // what if we should now apply a different scaling factor?
							{ unsigned xh=_xRect.width; _xRect.width=_xRect.height; _xRect.height=xh; }
							{ float h=size.height; size.height=size.width; size.width=h; }
							{ float h=resolution.height; resolution.height=resolution.width; resolution.width=h; }
							[(NSAffineTransform *) _screen2X11 rotateByDegrees:90.0];
							break;
						}
					case 0:	// Case open & landscape
						break;
					}
				}
			// setup a timer to verify/update the deviceDescription every now and then
			}
		else
			{
			size.height-=[self _windowTitleHeight]/_screenScale;	// subtract menu bar of X11 server from frame
			}
#endif
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
			{
			[[NSNotificationCenter defaultCenter] postNotificationName:NSApplicationDidChangeScreenParametersNotification
																object:NSApp];
			}
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

- (int) _keyWindowNumber;
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

// FIXME: should translate mouse locations by CTM to account for screen rotation through CTM!

#define X11toScreen(record) (windowScale != 1.0?NSMakePoint(record.x/windowScale, (windowHeight-record.y)/windowScale):NSMakePoint(record.x, windowHeight-record.y))
#define X11toTimestamp(record) ((NSTimeInterval)(record.time*0.001))

+ (void) _handleNewEvents;
{
	int count;
	while((count = XPending(_display)) > 0)		// while X events are pending
		{
#if 0
		fprintf(stderr,"_NSX11GraphicsContext ((XPending count = %d): \n", count);
#endif
		while(count-- > 0)
			{	// loop and grab all events
			static Window lastXWin=None;		// last window (cache key)
			static int windowNumber;			// number of lastXWin
			static int windowHeight;			// attributes of lastXWin (signed so that we can calculate windowHeight-y and return negative coordinates)
			static float windowScale;			// scaling factor
			static NSWindow *window=nil;		// associated NSWindow of lastXWin
			static NSEvent *lastMotionEvent=nil;
			static Time timeOfLastClick = 0;
			static int clickCount = 1;
			NSEventType type;
			Window thisXWin;				// window of this event
			XEvent xe;
			NSEvent *e = nil;	// resulting event
			XNextEvent(_display, &xe);
			switch(xe.type)
				{ // extract window from event
				case ButtonPress:
				case ButtonRelease:
					thisXWin=xe.xbutton.window;
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
			if(thisXWin != lastXWin)						
				{ // update cached references to window and prepare for translation
				window=NSMapGet(__WindowNumToNSWindow, (void *) thisXWin);
				if(!window)
					{ // FIXME: if a window is closed, it might be removed from this list but events might be pending!
					NSLog(@"*** event from unknown Window (%d). Ignored.", (long) thisXWin);
					NSLog(@"Window list: %@", NSAllMapTableValues(__WindowNumToNSWindow));
					continue;	// ignore events
					}
				else
					{
					_NSX11GraphicsContext *ctxt=(_NSX11GraphicsContext *)[window graphicsContext];
					windowNumber=[window windowNumber];
					windowHeight=ctxt->_xRect.height;
					windowScale=ctxt->_scale;
					}
				lastXWin=thisXWin;
				}
			// we could post the raw X-event as an NSNotification so that we could build a window manager...
			switch(xe.type)
				{										// mouse button events
				case ButtonPress:
					{
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
						switch (xe.xbutton.button)
							{
							case Button4:
								type = NSScrollWheel;
								pressure = (float)clickCount;
								break;								
							case Button5:
								type = NSScrollWheel;
								pressure = -(float)clickCount;
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
												context:self
											eventNumber:xe.xbutton.serial
											 clickCount:clickCount
											   pressure:pressure];
						break;
					}					
				case ButtonRelease:
					{
						NSDebugLog(@"ButtonRelease");
						if(xe.xbutton.button == Button1)
							type=NSLeftMouseUp;
						else if(xe.xbutton.button == Button3)
							type=NSRightMouseUp;
						else
							type=NSOtherMouseUp;
						e = [NSEvent mouseEventWithType:type		// create NSEvent	
											   location:X11toScreen(xe.xbutton)
										  modifierFlags:__modFlags
											  timestamp:X11toTimestamp(xe.xbutton)
										   windowNumber:windowNumber
												context:self
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
						[window performClose:self];
						}									// to close window
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
#if FIXME
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
						[window _setFrame:f];
						}
						if(xe.xconfigure.window == lastXWin)
							{
							// xFrame = [w xFrame];
							xFrame = (NSRect){{(float)xe.xconfigure.x,
								(float)xe.xconfigure.y},
								{(float)xe.xconfigure.width,
									(float)xe.xconfigure.height}};
							}
						break;								
#endif
				case ConfigureRequest:					// same as ConfigureNotify but we get this event
					NSDebugLog(@"ConfigureRequest\n");	// before the change has 
					break;								// actually occurred 					
				case CreateNotify:						// a window has been
					NSDebugLog(@"CreateNotify\n");		// created
					break;
				case DestroyNotify:						// a window has been
					NSLog(@"DestroyNotify\n");			// Destroyed
					break;
				case EnterNotify:						// when the pointer
					NSDebugLog(@"EnterNotify\n");		// enters a window
					break;					
				case LeaveNotify:						// when the pointer 
					NSDebugLog(@"LeaveNotify\n");		// leaves a window
					break;
				case Expose:
					{
						_NSX11GraphicsContext *ctxt=(_NSX11GraphicsContext *)[window graphicsContext];
						if(_isDoubleBuffered(ctxt))
							{ // copy from backing store
							_setDirtyRect(ctxt, xe.xexpose.x, xe.xexpose.y, xe.xexpose.width, xe.xexpose.height);	// flush at least the exposed area
							// FIXME: we should set up a timer or so to handle multiple expose events with a single flush!
							[ctxt flushGraphics];	// plus anything else we need to flush anyway
							}
						else
							{ // queue up an expose event
							NSSize sz;
							if(windowScale != 1.0)
								sz=NSMakeSize(xe.xexpose.width/windowScale+0.5, xe.xexpose.height/windowScale+0.5);
							else
								sz=NSMakeSize(xe.xexpose.width, xe.xexpose.height);
#if 1
							NSLog(@"not double buffered expose %@ -> %@", window,
								//  NSStringFromXRect(xe.xexpose),
								  NSStringFromSize(sz));
#endif
							e = [NSEvent otherEventWithType:NSAppKitDefined
												   location:X11toScreen(xe.xexpose)
											  modifierFlags:0
												  timestamp:0
											   windowNumber:windowNumber
													context:self
													subtype:NSWindowExposedEventType
													  data1:sz.width
													  data2:sz.height];	// truncated to (int)
							}
						break;
					}
				case FocusIn:							
					{ // keyboard focus entered one of our windows - take this a a hint from the WindowManager to bring us to the front
						NSLog(@"FocusIn 1: %d\n", xe.xfocus.detail);
#if OLD
						// NotifyAncestor			0
						// NotifyVirtual			1
						// NotifyInferior			2
						// NotifyNonlinear			3
						// NotifyNonlinearVirtual	4
						// NotifyPointer			5
						// NotifyPointerRoot		6
						// NotifyDetailNone			7
	//					[NSApp activateIgnoringOtherApps:YES];	// user has clicked: bring our application windows and menus to front
	//					[window makeKey];
						if(xe.xfocus.detail == NotifyAncestor)
							{
							//				if (![[[NSApp mainMenu] _menuWindow] isVisible])
							//					[[NSApp mainMenu] display];
							}
						else if(xe.xfocus.detail == NotifyNonlinear
								&& __xKeyWindowNeedsFocus == None)
							{ // create fake mouse dn
							NSLog(@"FocusIn 2");
							e = [NSEvent otherEventWithType:NSAppKitDefined
												   location:NSZeroPoint
											  modifierFlags:0
												  timestamp:(NSTimeInterval)0
											   windowNumber:windowNumber
													context:self
													subtype:NSApplicationActivatedEventType
													  data1:0
													  data2:0];
							}
#endif
						break;
					}
				case FocusOut:
					{ // keyboard focus has left one of our windows
						NSDebugLog(@"FocusOut");
#if OLD
						e = [NSEvent otherEventWithType:NSAppKitDefined
											   location:NSZeroPoint
										  modifierFlags:0
											  timestamp:(NSTimeInterval)0
										   windowNumber:windowNumber
												context:self
												subtype:NSApplicationDeactivatedEventType
												  data1:0
												  data2:0];
#endif
#if FIXME
						if(xe.xfocus.detail == NotifyAncestor)	// what does this mean?
							{
							NSLog(@"FocusOut 1");
							[w xFrame];
							XFlush(_display);
							if([w xGrabMouse] == GrabSuccess)
								[w xReleaseMouse];
							else
								{
								NSWindow *k = [NSApp keyWindow];
								
								if((w == k && [k isVisible]) || !k)
									[[NSApp mainMenu] close];	// parent titlebar is moving the window
								}
							}
						else
							{
							Window xfw;
							int r;
							// check if focus is in one of our windows
							XGetInputFocus(_display, &xfw, &r);
							if(!(w = XRWindowWithXWindow(xfw)))
								{
								NSLog(@"FocusOut 3");
								//							[NSApp deactivate];
								}
							}
						if(__xKeyWindowNeedsFocus == xe.xfocus.window)
							__xKeyWindowNeedsFocus = None;
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
				case KeyRelease:						// a key has been released
#if 1
					NSLog(@"Process key event");
#endif
					{
						NSEventType eventType=(xe.type == KeyPress)?NSKeyDown:NSKeyUp;
						char buf[256];
						KeySym ksym;
						NSString *keys = @"";
						unsigned short keyCode = 0;
						unsigned mflags;
						unsigned int count = XLookupString(&xe.xkey, buf, sizeof(buf), &ksym, NULL);						
						buf[MIN(count, sizeof(buf)-1)] = '\0'; // Terminate string properly
#if 1
						NSLog(@"xKeyEvent: xkey.state=%d keycode=%d keysym=%s", xe.xkey.state, xe.xkey.keycode, XKeysymToString(ksym));
#endif						
						mflags = xKeyModifierFlags(xe.xkey.state);		// decode modifier flags
						if((keyCode = xKeyCode(&xe, ksym, &mflags)) != 0 || count != 0)
							{
							keys = [NSString stringWithCString:buf];	// key has a code
							__modFlags=mflags;		// may also be modified
							}
						else
							{ // if we have neither a keyCode nor characters we have just changed a modifier Key
							if(eventType == NSKeyUp)
								__modFlags &= ~mflags;	// just reset flags defined by this key
							else
								__modFlags=mflags;	// if modified
							eventType=NSFlagsChanged;
							}
						e= [NSEvent keyEventWithType:eventType
											location:NSZeroPoint
									   modifierFlags:__modFlags
										   timestamp:X11toTimestamp(xe.xkey)
										windowNumber:windowNumber
											 context:self
										  characters:keys
						 charactersIgnoringModifiers:[keys lowercaseString]		// FIX ME?
										   isARepeat:NO	// any idea how to FIXME? - maybe comparing time stamp and keycode with previous key event
											 keyCode:keyCode];
#if 1
						NSLog(@"xKeyEvent: %@", e);
#endif
						break;
					}
						
					case KeymapNotify:						// reports the state of the
						NSDebugLog(@"KeymapNotify");		// keyboard when pointer or
						break;								// focus enters a window
						
					case MapNotify:							// when a window changes
						NSDebugLog(@"MapNotify");			// state from ummapped to
															// mapped or vice versa
						[window _setIsVisible:YES];
						break;								 
						
					case UnmapNotify:						// find the NSWindow and
						NSDebugLog(@"UnmapNotify\n");		// inform it that it is no
															// longer visible
						[window _setIsVisible:NO];
						break;
						
					case MapRequest:						// like MapNotify but
						NSDebugLog(@"MapRequest\n");		// occurs before the
						break;								// request is carried out
						
					case MappingNotify:						// keyboard or mouse   
						NSDebugLog(@"MappingNotify\n");		// mapping has been changed
						break;								// by another client
						
					case MotionNotify:
						{ // the mouse has moved
							NSDebugLog(@"MotionNotify");
							if(xe.xmotion.state & Button1Mask)		
								type = NSLeftMouseDragged;	
							else if(xe.xmotion.state & Button3Mask)		
								type = NSRightMouseDragged;	
							else if(xe.xmotion.state & Button2Mask)		
								type = NSOtherMouseDragged;	
							else
								type = NSMouseMoved;	// not pressed
#if 0
							if(lastMotionEvent &&
							   [NSApp _eventIsQueued:lastMotionEvent])
								{
								NSLog(@"motion event still in queue: %@", lastMotionEvent);
								}
#endif
							if(lastMotionEvent &&
							   [NSApp _eventIsQueued:lastMotionEvent] &&	// must come first because event may already have been relesed/deallocated
							   [lastMotionEvent type] == type)
								{ // replace/update if last motion event which is still unprocessed in queue
								typedef struct _NSEvent_t { @defs(NSEvent) } _NSEvent;
								_NSEvent *a = (_NSEvent *)lastMotionEvent;	// this allows to access iVars directly
#if 0
								NSLog(@"update last motion event");
#endif
								a->location_point=X11toScreen(xe.xmotion);
								a->modifier_flags=__modFlags;
								a->event_time=X11toTimestamp(xe.xmotion);
								a->event_data.mouse.event_num=xe.xmotion.serial;
								break;
								}
							e = [NSEvent mouseEventWithType:type		// create NSEvent
												   location:X11toScreen(xe.xmotion)
											  modifierFlags:__modFlags
												  timestamp:X11toTimestamp(xe.xmotion)
											   windowNumber:windowNumber
													context:self
												eventNumber:xe.xmotion.serial
												 clickCount:1
												   pressure:1.0];
							lastMotionEvent = e;
#if 0
							NSLog(@"MotionNotify e=%@", e);
#endif
							break;
						}
					case PropertyNotify:
						{ // a window property has changed or been deleted
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
									[window miniaturize:self];
								else if(*data == NormalState)
									[window deminiaturize:self];
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
#if FIXME
						if(__xAppTileWindow == xe.xreparent.window)
							{ // WM reparenting appicon
							_wAppTileWindow = xe.xreparent.parent;
							//	[window xSetFrameFromXContentRect: [window xFrame]];
							XSelectInput(_display, _wAppTileWindow, StructureNotifyMask);
							// FIXME: should this be an NSNotification?
							}
#endif
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
													context:self
													subtype:0
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
						case VisibilityNotify:						// window's visibility 
							NSDebugLog(@"VisibilityNotify");		// has changed
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
	switch(type)
		{
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
	event.window=[e windowNumber];	// use 1 == InputFocus
	win=[NSWindow _windowForNumber:event.window];	// try to find
	ctxt=(_NSX11GraphicsContext *) [win graphicsContext];
	if(!win)
		{ // we don't know the window...
		// ???
		}
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
	event.state = [e modifierFlags];	
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
			NSLog(@"Unable to allocate color %@ for X11 Screen %08x", color, scr);
			return 0;
			}
		}
	return ((XColor *) _colorData)->pixel;
}

- (void) dealloc;
{
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
				[self release];
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

- (void) _setScale:(float) scale;
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
		if((_fontStruct = XLoadQueryFont(_display, [xf cString])))	// Load X font
			return _fontStruct;
		xWeight="*";	// try any weight
		xf=[NSString stringWithFormat: @"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
			xFoundry, xFamily, xWeight, xSlant, xWidth, xStyle,
			xPixel, xPoint, xXDPI, xYDPI, xSpacing, xAverage,
			xRegistry, xEncoding];
#if 1
		NSLog(@"try %@", xf);
#endif
		if((_fontStruct = XLoadQueryFont(_display, [xf cString])))	// Load X font
			return _fontStruct;
		xFamily="*";	// try any family
		xf=[NSString stringWithFormat: @"-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s-%s",
			xFoundry, xFamily, xWeight, xSlant, xWidth, xStyle,
			xPixel, xPoint, xXDPI, xYDPI, xSpacing, xAverage,
			xRegistry, xEncoding];
#if 1
		NSLog(@"try %@", xf);
#endif
		if((_fontStruct = XLoadQueryFont(_display, [xf cString])))	// Load X font
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

// GET RID OF THIS SINCE IT DEPENDEND ON CHARACTER ENCODING

- (NSSize) _sizeOfAntialisedString:(NSString *) string;
{ // overwritten in Freetype.m
	BACKEND;
	return NSZeroSize;
}

- (NSSize) _sizeOfString:(NSString *) string;
{ // get size from X11 font assuming no scaling
	if(_renderingMode == NSFontIntegerAdvancementsRenderingMode)
		{
		static XChar2b *buf;	// translation buffer (unichar -> XChar2b)
		static unsigned int buflen;
		unsigned int i;
		unsigned length=[string length];
		NSSize size;
		SEL cai=@selector(characterAtIndex:);
		typedef unichar (*CAI)(id self, SEL _cmd, int i);
		CAI imp=(CAI)[string methodForSelector:cai];	// don't try to cache this! Different strings may have different implementations
#if 0
		NSLog(@"_sizeOfString:%@ font:%@", string, _state->_font);
#endif
		if(!buf || length > buflen)
			buf=(XChar2b *) objc_realloc(buf, sizeof(buf[0])*(buflen=length+20));	// increase translation buffer if needed
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
		size=NSMakeSize(XTextWidth16(_unscaledFontStruct, buf, length),
						(((XFontStruct *)_unscaledFontStruct)->ascent + ((XFontStruct *)_unscaledFontStruct)->descent));	// character box
#if 0
		NSLog(@"%@[%@] -> %@ (C: %d)", self, string, NSStringFromSize(size), XTextWidth(_fontStruct, [string cString], length));
#endif
		return size;	// return size of character box
		}
	else
		return [self _sizeOfAntialisedString:string];
}

- (void) _finalize
{ // overwritten by FreeTypeFont
	return;
}

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt;
{ // overwritten by FreeTypeFont
	NSLog(@"can't draw antialiased fonts");
}

- (void) dealloc;
{
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
#if FIXME
			// we should lockFocus on a Pixmap and call _draw:bestRep
			NSBitmapImageRep *bestRep = [_image bestRepresentationForDevice:nil];	// get device description??
			Pixmap mask = (Pixmap)[bestRep xPixmapMask];
			Pixmap bits = (Pixmap)[bestRep xPixmapBitmap];
			_cursor = XCreatePixmapCursor(_display, bits, mask, &fg, &bg, _hotSpot.x, _hotSpot.y);
#endif
			}
		if(!_cursor)
			return None;	// did not initialize
		}
	return _cursor;
}

- (void) dealloc;
{
	if(_cursor)
		XFreeCursor(_display, _cursor);	// no longer needed
	[super dealloc];
}

@end

// EOF