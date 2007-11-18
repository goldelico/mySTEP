//
//  NSBackend.h
//  mySTEP
//
//  Private drawing primitive interface between AppKit and Backend
//
//  optimized to generate PDF and to handle an X11 backend
//
//  Created by Dr. H. Nikolaus Schaller on Thu Jan 05 2006.
//  Copyright (c) 2006 DSITRI. All rights reserved.
//

#ifndef _mySTEP_Backend
#define _mySTEP_Backend

#import <Foundation/Foundation.h>
#import "NSAppKitPrivate.h"
#import "NSGraphicsContext.h"
#import "NSStringDrawing.h"
#import "NSShadow.h"
#import "NSWindow.h"		// window ordering mode etc.
#import "NSScreen.h"


@class NSAffineTransform;
@class NSBezierPath;
@class NSColor;
@class NSCursor;
@class NSEvent;
@class NSImage;
@class NSImageRep;
@class NSScreen;

@interface NSGraphicsContext (NSBackend)

// standard

- (void) flushGraphics;
- (void) restoreGraphicsState;
- (void) saveGraphicsState;

// managing color

- (void) _setColor:(NSColor *) color;
- (void) _setFillColor:(NSColor *) color;
- (void) _setStrokeColor:(NSColor *) color;

// window appearance

- (void) _setShadow:(NSShadow *) shadow;
- (void) _setShape:(NSBezierPath *) path;

// managing coordinate trransformation matrix

- (void) _setCTM:(NSAffineTransform *) atm;
- (void) _concatCTM:(NSAffineTransform *) atm;

// stroking and filling paths

- (void) _stroke:(NSBezierPath *) path;
- (void) _fill:(NSBezierPath *) path;
- (void) _setClip:(NSBezierPath *) path;
- (void) _addClip:(NSBezierPath *) path;

// fonts and drawing

- (void) _setFont:(NSFont *) font;			// PDF: font size TF (explicit)
- (void) _beginText;						// PDF: BT (clears matrix)
- (void) _setTextPosition:(NSPoint) pos;	// PDF: x y Td (?)
- (void) _moveByX:(float) x andY:(float) y setLead:(BOOL) flag;	// PDF: (optional -y TL) x y Td
- (void) _setTM:(NSAffineTransform *) tm;	// PDF: a b c d e f Tm
- (void) _newLine;							// PDF: T*
- (void) _setLeading:(float) val;			// PDF: v TL
- (void) _setCharSpace:(float) val;			// PDF: v Tc
- (void) _setScale:(float) val;				// PDF: v Tz
- (void) _setWordSpace:(float) val;			// PDF: v Tw
- (void) _setBaseline:(float) val;			// PDF: v Ts

// FIXME: should not use _string but _drawGlyphs

- (void) _string:(NSString *) string;		// (string) Tj
- (void) _drawGlyphs:(NSGlyph *) glyphs count:(unsigned) cnt;	// (string) Tj

- (void) _endText;							// PDF: ET

// compositing bitmap images

- (void) _setFraction:(float) fraction;		// compositing fraction

- (BOOL) _draw:(NSImageRep *) rep;	// composite into unit square using current CTM, current compositingOp & fraction etc.

- (void) _copyBits:(void *) srcGstate fromRect:(NSRect) srcRect toPoint:(NSPoint) destPoint;

// handle page breaks

- (void) _beginPage:(NSString *) title;
- (void) _endPage;

// methods for display devices only - should we make this a formal protocol?

// managing the window

- (int) _windowNumber;		// get the window number
- (int) _windowTitleHeight;	// amount added by window manager for window title
- (int) _windowListForContext:(int) context size:(int) size list:(int []) list;
- (void) _setBackingType:(NSBackingStoreType) type;
- (void) _map;		// map the window
- (void) _unmap;	// unmap the window
- (void) _miniaturize;
- (void) _deminiaturize;
- (void) _orderWindow:(NSWindowOrderingMode) place relativeTo:(int) otherWin;
- (void) _makeKeyWindow;	// attract keyboard focus
- (BOOL) _isKeyWindow;		// if we have keyboard focus
- (NSRect) _frame;			// get current frame as on screen (might have been moved by window manager)
- (void) _setLevel:(int) level;				// set level property
- (void) _setOrigin:(NSPoint) point;		// just move
- (void) _setOriginAndSize:(NSRect) frame;	// usually, this means moving and resizing
- (void) _setTitle:(NSString *) string;		// same as _beginPage???
- (void) _setDocumentEdited:(BOOL) flag;	// mark doc as edited

// managing the cursor

- (void) _setCursor:(NSCursor *) cursor;	// select as current cursor

// reading from screen

- (NSColor *) _readPixel:(NSPoint) location;	// read from current drawable
-  (void) _initBitmap:(NSBitmapImageRep *) bitmap withFocusedViewRect:(NSRect) rect;

// handling input devices

- (NSPoint) _mouseLocationOutsideOfEventStream;

@end

@interface NSScreen (NSBackend)
- (BOOL) _hasWindowManager;	// there is a window manager...
- (int) _windowTitleHeight;
- (void) _sendEvent:(NSEvent *) event;
- (void) _grabKey:(int) keycode;
- (int) _keyWindowNumber;
@end

@interface NSWindow (NSBackend)
+ (int) _windowListForContext:(int) context size:(int) size list:(int *) list;	// list may be NULL, return # of entries copied
+ (int) _getLevelOfWindowNumber:(int) windowNum;
+ (NSWindow *) _windowForNumber:(int) windowNum;
@end

@interface NSWindow (NSBackendCallbacks)	// called from the backend
- (void) _setFrame:(NSRect) rect;	// if changed externaly
@end

@interface NSFont (NSBackend)
- (NSSize) _sizeOfString:(NSString *) string;	// query bounding box
@end

#endif	// _mySTEP_Backend
