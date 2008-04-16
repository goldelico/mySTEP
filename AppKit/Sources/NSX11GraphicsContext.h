/* 
 NSX11GraphicsContext.h
 
 X11 Backend Graphics Context class.  Conceptually, instances of 
 this subclass encapsulate a single X Window object
  
 Author:	H. N. Schaller <hns@computer.org>
 Date:	Jan 2006 - completely reworked

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#ifndef _mySTEP_H_NSX11GraphicsContext
#define _mySTEP_H_NSX11GraphicsContext

#include <X11/keysym.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/cursorfont.h>
#define BOOL XWINDOWSBOOL							// prevent X windows BOOL
#include <X11/Xmd.h>								// warning
#undef BOOL
#include <X11/extensions/shape.h>

#if 1 // RENDER
#include <X11/extensions/Xrender.h>
#endif

#define Cursor QDCursor				// conflicting between QuickDraw and X11
#define Picture QuickDrawPicture	// conflicting between QuickDraw and XRender
#import <Foundation/Foundation.h>
#undef Cursor
#undef Picture

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"
#import "NSColor.h"
#import "NSFont.h"
#import "NSScreen.h"

@class _NSX11Screen;
@class _NSX11Font;
@class _NSX11Color;
@class _NSX11Cursor;

typedef struct _NSX11GraphicsState
{ // saved graphics state
	_NSGraphicsState _super;		// inherited
	NSAffineTransform *_ctm;		// current transformation matrix (transforms directly to X11)
	GC _gc;							// current context (line width, foreground color, fill rule, font etc.)
	Region _clip;					// current clipping path
	XRectangle _clipBox;			// current clippig box
	_NSX11Font *_font;				// current font
	XRenderColor _fillColor;
	XRenderColor _strokeColor;
	// NSShadow *_shadow;			// current shadow
	// rendering intent;
	// float _globalAlpha;
	// ?image interpolation quality
	// ?antialiasing
	// ?compositing operation
} _NSX11GraphicsState;

@interface _NSX11GraphicsContext : NSGraphicsContext
{ // describes one output window
	NSRect _windowRect;					// window in NSScreen coords (required to flip window coordinates and to clip composite operations)
	XRectangle _dirty;					// dirty area
	_NSX11Screen *_nsscreen;			// cached pointer from NSWindow
	NSAffineTransform *_textMatrix;
	NSAffineTransform *_textLineMatrix;
	float _characterSpace;				// PDF text parameters
	float _wordSpace;
	float _horizontalScale;
	float _leading;
	float _rise;						// current baseline
 @public
	Window _realWindow;					// may be the same or different from _graphicsPort for double buffered windows
	XRectangle _xRect;					// X11 rectangle of the window
#define _state ((_NSX11GraphicsState *) _graphicsState)		// our graphics state
	float _scale;						// our scaling factor
	float _fraction;					// compositing fraction
	int _windowNum;						// window number
	Picture _picture;					// window supports render extension
}

- (id) _initWithGraphicsPort:(void *) port;
- (id) _initWithAttributes:(NSDictionary *) attributes;

@end

@interface _NSX11Screen : NSScreen
{
@public
	Screen *_screen;
	XRectangle _xRect;
	NSAffineTransform *_screen2X11;
	NSAffineTransform *_X112screen;
	float _screenScale;
}
+ (void) _handleNewEvents;	// synchronously check for new events
- (NSAffineTransform *) _X112screen;
@end

@interface _NSX11Color : NSColor
{
	Screen *_screen;
	void *_colorData;
}
- (unsigned long) _pixelForScreen:(Screen *) scr;
@end

@interface _NSX11Font : NSFont
{
	XFontStruct *_unscaledFontStruct;	// cached font struct for scale=1.0
	XFontStruct *_fontStruct;			// a second font struct cache if we have a different font scale
	float _fontScale;					// scaling factor used
	void *_backendPrivate;
}

- (void) _setScale:(float) scale;		// set font scaling factor
- (XFontStruct *) _font;				// X11 bitmap font

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt inContext:(NSGraphicsContext *) ctxt matrix:(NSAffineTransform *) ctm;

@end

@interface _NSX11Cursor : NSCursor
{
	Cursor _cursor;
}
- (Cursor) _cursor;
@end

#endif /* _mySTEP_H_NSX11GraphicsContext */
