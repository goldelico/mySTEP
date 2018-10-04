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

// managing coordinate transformation matrix

- (NSAffineTransform *) _getCTM;
- (void) _setCTM:(NSAffineTransform *) atm;
- (void) _concatCTM:(NSAffineTransform *) atm;

// stroking and filling paths

- (void) _stroke:(NSBezierPath *) path;
- (void) _fill:(NSBezierPath *) path;
- (void) _addClip:(NSBezierPath *) path reset:(BOOL) flag;

// fonts and drawing

- (void) _beginText;						// PDF: BT (clears matrix)

- (void) _setFont:(NSFont *) font;			// PDF: font size TF (explicit)

- (void) _setTextPosition:(NSPoint) pos;	// PDF: x y Td
- (void) _setTM:(NSAffineTransform *) tm;	// PDF: a b c d e f Tm
- (void) _setLeading:(CGFloat) val;			// PDF: v TL
- (void) _setCharSpace:(CGFloat) val;		// PDF: v Tc
- (void) _setHorizontalScale:(CGFloat) val;	// PDF: v Tz
- (void) _setWordSpace:(CGFloat) val;		// PDF: v Tw
- (void) _setBaseline:(CGFloat) val;		// PDF: v Ts
- (void) _newLine:(NSPoint) pos;			// PDF: x y TD
- (void) _newLine;							// PDF: T*

- (void) _drawGlyphs:(NSGlyph *) glyphs count:(NSUInteger) cnt;	// (string) Tj

- (void) _endText;							// PDF: ET

// compositing bitmap images

- (void) _setFraction:(CGFloat) fraction;		// compositing fraction

- (BOOL) _draw:(NSImageRep *) rep;	// composite using current CTM, current compositingOp & fraction etc.

- (void) _copyBits:(void *) srcGstate fromRect:(NSRect) srcRect toPoint:(NSPoint) destPoint;

// handle page breaks

- (void) _beginPage:(NSString *) title;
- (void) _endPage;

// methods for display devices only - should we make this a formal protocol?

// managing the window

- (NSInteger) _windowNumber;		// get the window number
- (int) _windowTitleHeight;	// amount added by window manager for window title in screen pixels
- (void) _setBackingType:(NSBackingStoreType) type;
- (void) _map;		// map the window
- (void) _unmap;	// unmap the window
- (void) _miniaturize;
- (void) _deminiaturize;
- (void) _orderWindow:(NSWindowOrderingMode) place relativeTo:(NSInteger) otherWin;
- (void) _makeKeyWindow;	// attract keyboard focus
- (BOOL) _isKeyWindow;		// if we have keyboard focus
- (NSRect) _frame;			// get current frame as on screen (might have been moved by window manager)
- (NSRect) _clipBox;		// get current clipbox
- (NSInteger) _getLevelOfWindowNumber:(NSInteger) windowNum;		// query level of any window (even if not managed by us)
- (void) _setLevel:(NSInteger) level andStyle:(NSInteger) mask;		// set window level and style mask property
- (void) _setOrigin:(NSPoint) point;		// just move
- (void) _setOriginAndSize:(NSRect) frame;	// usually, this means moving and resizing
- (void) _setTitle:(NSString *) string;		// same as _beginPage???
- (void) _setDocumentEdited:(BOOL) flag;	// mark doc as edited

// reading from screen

- (NSColor *) _readPixel:(NSPoint) location;	// read from current drawable
-  (void) _initBitmap:(NSBitmapImageRep *) bitmap withFocusedViewRect:(NSRect) rect;

// handling input devices

// - (NSPoint) _mouseLocationOutsideOfEventStream;

@end

@interface NSScreen (NSBackend)
+ (NSInteger) _systemWindowListForContext:(NSInteger) context size:(NSInteger) size list:(NSInteger *) list;	// list may be NULL, return # of entries copied
- (BOOL) _hasWindowManager;	// there is a window manager...
- (int) _windowTitleHeight;
- (void) _sendEvent:(NSEvent *) event;
- (void) _grabKey:(NSInteger) keycode;
- (NSInteger) _keyWindowNumber;
- (NSPoint) _mouseLocation;
@end

@interface NSApplication (NSBackend)
- (NSWindow*) windowWithWindowNumber:(NSInteger)num;
- (NSArray *) windows;
@end

@interface NSWindow (NSBackendCallbacks)	// called from the backend
- (void) _setFrame:(NSRect) rect;	// if changed externaly
@end

@interface NSFont (NSBackend)
- (NSGlyph) _glyphForCharacter:(unichar) c;
- (NSSize) _kerningBetweenGlyph:(NSGlyph) left andGlyph:(NSGlyph) right;
- (CGFloat) _widthOfAntialisedString:(NSString *) string;	// deprecated!
@end

@interface NSFontDescriptor (NSBackend)
+ (NSArray *) _matchingFontDescriptorsWithAttributes:(NSDictionary *) attributes mandatoryKeys:(NSSet *) keys limit:(NSUInteger) limit; // this is the core font search engine that knows about font directories
+ (NSDictionary *) _fonts;									// read font cache from disk
+ (void) _writeFonts;										// write font cache to disk
+ (void) _addFontWithAttributes:(NSDictionary *) record;	// add a font attributes record to the font cache
+ (NSString *) _loadFontsFromFile:(NSString *) path;		// add fonts found in this file - ignore if we can't really load; returns the Family name
+ (void) _findFonts;										// search through all font directories
@end

#endif	// _mySTEP_Backend
