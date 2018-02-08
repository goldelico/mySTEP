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
	_NSX11Color *_fillColor;
	_NSX11Color *_strokeColor;
	// NSShadow *_shadow;			// current shadow
	// rendering intent;
	// CGFloat _globalAlpha;
	// ?image interpolation quality
	// ?antialiasing
	// ?compositing operation
} _NSX11GraphicsState;

@interface _NSX11GraphicsContext : NSGraphicsContext
{ // describes one output window
	NSRect _windowRect;					// window in NSScreen coords (required to flip window coordinates and to clip composite operations)
	XRectangle _dirty;					// dirty area
	GC _neutralGC;						// this is a GC with neutral image processing options
	_NSX11Screen *_nsscreen;			// cached pointer from NSWindow
	NSAffineTransform *_textMatrix;
	NSAffineTransform *_textLineMatrix;
	CGFloat _characterSpace;				// PDF text parameters
	CGFloat _wordSpace;
	CGFloat _horizontalScale;
	CGFloat _leading;
	CGFloat _rise;						// current baseline
	int _textRenderMode;
 @public
	Window _realWindow;					// may be the same or different from _graphicsPort for double buffered windows
	XRectangle _xRect;					// X11 rectangle of the window
#define _state ((_NSX11GraphicsState *) _graphicsState)		// our graphics state
	CGFloat _scale;						// our scaling factor
	CGFloat _fraction;					// compositing fraction
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
	Picture _picture;	// 1x1 pixels picture with repeat flag
	void *_colorData;
}
- (Picture) _pictureForColor;
- (unsigned long) _pixelForScreen:(Screen *) scr;
@end

typedef struct _CachedGlyph
	{ // this is one entry in our own GlyphSet using cached Pictures (so that we can rotate glyphs by the standard transforms)
		Picture picture;
		int x, y;
		unsigned width, height;
	} *_CachedGlyph;

@interface _NSX11Font : NSFont
{
	XFontStruct *_unscaledFontStruct;	// cached font struct for scale=1.0
	XFontStruct *_fontStruct;			// a second font struct cache if we have a different font scale
	void *_backendPrivate;
//	GlyphSet _glyphSet;					// associated glyph set
	// GlyphCache should be a global cache based on [font name], [font size] or matrix
	NSMapTable *_glyphCache;			// maps NSGlyph to struct _CachedGlyph
	CGFloat _fontScale;					// scaling factor used
}

- (void) _setScale:(CGFloat) scale;		// set font scaling factor
- (XFontStruct *) _font;				// X11 bitmap font

- (void) _drawAntialisedGlyphs:(NSGlyph *) glyphs count:(NSUInteger) cnt inContext:(NSGraphicsContext *) ctxt matrix:(NSAffineTransform *) ctm;

- (_CachedGlyph) _pictureForGlyph:(NSGlyph) glyph;	// get cached Picture to render
// - (GlyphSet) _glyphSet;
- (void) _addGlyph:(NSGlyph) glyph bitmap:(char *) buffer x:(int) left y:(int) top width:(unsigned) width height:(unsigned) rows;

@end

@interface _NSX11Cursor : NSCursor
{
	Cursor _cursor;
}
- (Cursor) _cursor;
@end

@interface _NSX11BezierPath : NSBezierPath
{
	_NSX11BezierPath *_flattenedPath;	// flattened version
	_NSX11BezierPath *_strokedPath;		// stroked outline
}
- (void) _fill:(_NSX11GraphicsContext *) context color:(_NSX11Color *) color;
- (void) _stroke:(_NSX11GraphicsContext *) context color:(_NSX11Color *) color;
@end

#endif /* _mySTEP_H_NSX11GraphicsContext */
