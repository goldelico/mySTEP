/*
   NSGraphics.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	February 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSGraphics
#define _mySTEP_H_NSGraphics

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>

#import <AppKit/NSImage.h>

@class NSString;
@class NSColor;

typedef enum _NSBackingStoreType
{ // Backing Store Types
	NSBackingStoreRetained	  = 0,		// draw directly to screen where visible; use buffer for obscured areas
	NSBackingStoreNonretained = 1,		// all drawing is rendered into a  buffer and then flushed
	NSBackingStoreBuffered	  = 2		// all drawing is rendered into a display buffer and then flushed
} NSBackingStoreType;

typedef enum _NSFocusRingType
{
	NSFocusRingTypeDefault=0,
	NSFocusRingTypeNone,
	NSFocusRingTypeExterior
} NSFocusRingType;

typedef enum _NSFocusRingPlacement
{
    NSFocusRingOnly=0,
    NSFocusRingBelow,
    NSFocusRingAbove
} NSFocusRingPlacement;

typedef enum _NSAnimationEffect
{
	NSAnimationEffectDisappearingItemDefault=0,
	NSAnimationEffectPoof=10
} NSAnimationEffect;

typedef int NSWindowDepth;

extern NSString *NSCalibratedWhiteColorSpace;			// Colorspace Names
extern NSString *NSCalibratedBlackColorSpace;
extern NSString *NSCalibratedRGBColorSpace;
extern NSString *NSDeviceWhiteColorSpace;
extern NSString *NSDeviceBlackColorSpace;
extern NSString *NSDeviceRGBColorSpace;
extern NSString *NSDeviceCMYKColorSpace;
extern NSString *NSNamedColorSpace;
extern NSString *NSPatternImageColorSpace;
extern NSString *NSCustomColorSpace;

extern NSString *NSDeviceBitsPerSample;
extern NSString *NSDeviceColorSpaceName;
extern NSString *NSDeviceIsPrinter;
extern NSString *NSDeviceIsScreen;
extern NSString *NSDeviceResolution;					// Device Dict Keys
extern NSString *NSDeviceSize;

extern const float NSWhite;
extern const float NSLightGray;
extern const float NSDarkGray;
extern const float NSBlack;

// Functions (alphabetically sorted)

void NSBeep(void);										// Play System Beep
void NSCopyBits(NSInteger srcGstate, NSRect srcRect, NSPoint destPoint);
void NSCountWindows(NSInteger *count);
void NSCountWindowsForContext(NSInteger context, NSInteger *count);			// for a specific application
void NSDisableScreenUpdates(void);
void NSDottedFrameRect(NSRect aRect);
void NSDrawBitmap(NSRect rect,							// Bitmap Images
                  NSInteger pixelsWide,
                  NSInteger pixelsHigh,
                  NSInteger bitsPerSample,
                  NSInteger samplesPerPixel,
                  NSInteger bitsPerPixel,
                  NSInteger bytesPerRow, 
                  BOOL isPlanar,
                  BOOL hasAlpha, 
                  NSString *colorSpaceName, 
                  const unsigned char *const data[5]);
void NSDrawButton(NSRect aRect, NSRect clipRect);
NSRect NSDrawColorTiledRects(NSRect boundsRect,
							 NSRect clipRect,
							 const NSRectEdge *sides,
							 NSColor **colors,
							 NSInteger count);
void NSDrawDarkBezel(NSRect aRect, NSRect clipRect);
void NSDrawGrayBezel(NSRect aRect, NSRect clipRect);
void NSDrawGroove(NSRect aRect, NSRect clipRect);
void NSDrawLightBezel(NSRect aRect, NSRect clipRect);
NSRect NSDrawTiledRects(NSRect boundsRect,				// Rect draw primitives
						NSRect clipRect, 
						const NSRectEdge *sides, 
						const CGFloat *grays, 
						NSInteger count);
void NSDrawWhiteBezel(NSRect aRect, NSRect clipRect);
void NSDrawWindowBackground(NSRect aRect);
void NSEnableScreenUpdates(void);
void NSEraseRect(NSRect aRect);
void NSFrameRect(NSRect aRect);
void NSFrameRectWithWidth(NSRect aRect, CGFloat frameWidth);
void NSFrameRectWithWidthUsingOperation(NSRect r,
										CGFloat w,
										NSCompositingOperation op);
NSInteger NSGetWindowServerMemory(NSInteger context, NSInteger *virtualMemory, NSInteger *windowBackingMemory, NSString **windowDumpStream);
void NSHighlightRect(NSRect aRect);
NSColor *NSReadPixel(NSPoint location);					// Read pixel color
void NSRectClip(NSRect aRect);
void NSRectClipList(const NSRect *rects, NSInteger count);
void NSRectFill(NSRect aRect);
void NSRectFillList(const NSRect *rects, NSInteger count);
void NSRectFillListUsingOperation(const NSRect *rects,
								  NSInteger count,
								  NSCompositingOperation op);
void NSRectFillListWithColors(const NSRect *rects, NSColor **colors, NSInteger count);
void NSRectFillListWithColorsUsingOperation(const NSRect *rects,
											NSColor **colors,
											NSInteger num,
											NSCompositingOperation op);
void NSRectFillListWithGrays(const NSRect *rects, const CGFloat *grays, NSInteger count);
void NSRectFillUsingOperation(NSRect aRect, NSCompositingOperation op);
void NSSetFocusRingStyle(NSFocusRingPlacement placement);
void NSShowAnimationEffect(NSAnimationEffect animationEffect,
						   NSPoint centerLocation,
						   NSSize size,
						   id animationDelegate,
						   SEL didEndSelector,
						   void *contextInfo);
void NSWindowList(NSInteger size, NSInteger list[]);
void NSWindowListForContext(NSInteger context, NSInteger size, NSInteger list[]);  // for a specific application

// window depth

const NSWindowDepth *NSAvailableWindowDepths(void);		// Color Space Info
NSWindowDepth NSBestDepth(NSString *colorSpace, 
						  int bitsPerSample,
						  int bitsPerPixel, 
						  BOOL planar,
						  BOOL *exactMatch);
NSInteger NSBitsPerPixelFromDepth(NSWindowDepth depth);
NSInteger NSBitsPerSampleFromDepth(NSWindowDepth depth);
NSString *NSColorSpaceFromDepth(NSWindowDepth depth);
NSInteger NSNumberOfColorComponents(NSString *colorSpaceName);
BOOL NSPlanarFromDepth(NSWindowDepth depth);

#endif /* _mySTEP_H_NSGraphics */
