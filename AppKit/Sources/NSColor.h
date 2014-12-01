/* 
   NSColor.h

   Color class interface

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSColor
#define _mySTEP_H_NSColor

#import <Foundation/Foundation.h>
#import <AppKit/NSCell.h>	// NSControlTint

@class NSColorSpace;
@class NSPasteboard;
@class NSImage;

@interface NSColor : NSObject  <NSCoding, NSCopying>
{
	NSString *_colorspaceName;
	NSString *_catalogName;
	NSString *_colorName;
	NSImage *_colorPatternImage;
	
	struct RGB_Color
		{
		CGFloat red;
		CGFloat green;
		CGFloat blue;
		} _rgb;
	
	struct CMYK_Color
		{
		CGFloat cyan;
		CGFloat magenta;
		CGFloat yellow;
		CGFloat black;
		} _cmyk;
	
	struct HSB_Color
		{
		CGFloat hue;
		CGFloat saturation;
		CGFloat brightness;
		} _hsb;

	CGFloat _white;
	CGFloat _alpha;
	
	struct __ColorFlags {
		unsigned int rgb:1;			// if rgb data is valid
		unsigned int cmyk:1;		// etc.
		unsigned int hsb:1;
		unsigned int white:1;
		unsigned int reserved:3;
		unsigned int calibrated:1;
		} _color;
}

+ (NSColor *) alternateSelectedControlColor;
+ (NSColor *) alternateSelectedControlTextColor;
+ (NSColor *) blackColor;								// Predefined colors
+ (NSColor *) blueColor;
+ (NSColor *) brownColor;
+ (NSColor *) clearColor;
+ (NSColor *) colorForControlTint:(NSControlTint) tint;
+ (NSColor *) colorFromPasteboard:(NSPasteboard *) pasteBoard;
+ (NSColor *) colorWithCalibratedHue:(CGFloat) hue
						  saturation:(CGFloat) saturation
						  brightness:(CGFloat) brightness
							   alpha:(CGFloat) alpha;
+ (NSColor *) colorWithCalibratedRed:(CGFloat) red
							   green:(CGFloat) green
								blue:(CGFloat) blue
							   alpha:(CGFloat) alpha;
+ (NSColor *) colorWithCalibratedWhite:(CGFloat) white
								 alpha:(CGFloat) alpha;
+ (NSColor *) colorWithCatalogName:(NSString *) listName
						 colorName:(NSString *) colorName;
//+ (NSColor *) colorWithCIColor:(CIColor *) color;
+ (NSColor *) colorWithColorSpace:(NSColorSpace *) space
					   components:(const CGFloat *) comp
							count:(NSInteger) number;
+ (NSColor *) colorWithDeviceCyan:(CGFloat) cyan
						  magenta:(CGFloat) magenta
						   yellow:(CGFloat) yellow
							black:(CGFloat) black
							alpha:(CGFloat) alpha;
+ (NSColor *) colorWithDeviceHue:(CGFloat) hue
					  saturation:(CGFloat) saturation
					  brightness:(CGFloat) brightness
						   alpha:(CGFloat) alpha;
+ (NSColor *) colorWithDeviceRed:(CGFloat) red
						   green:(CGFloat) green
							blue:(CGFloat) blue
						   alpha:(CGFloat) alpha;
+ (NSColor *) colorWithDeviceWhite:(CGFloat) white
							 alpha:(CGFloat) alpha;
+ (NSColor *) colorWithPatternImage:(NSImage *) image;
+ (NSArray *) controlAlternatingRowBackgroundColors;
+ (NSColor *) controlBackgroundColor;					// System colors
+ (NSColor *) controlColor;
+ (NSColor *) controlDarkShadowColor;
+ (NSColor *) controlHighlightColor;
+ (NSColor *) controlLightHighlightColor;
+ (NSColor *) controlShadowColor;
+ (NSColor *) controlTextColor;
+ (NSControlTint) currentControlTint;
+ (NSColor *) cyanColor;
+ (NSColor *) darkGrayColor;
+ (NSColor *) disabledControlTextColor;
+ (NSColor *) grayColor;
+ (NSColor *) greenColor;
+ (NSColor *) gridColor;
+ (NSColor *) headerColor;
+ (NSColor *) headerTextColor;
+ (NSColor *) highlightColor;
+ (BOOL) ignoresAlpha;									// Ignore Alpha
+ (NSColor *) keyboardFocusIndicatorColor;
+ (NSColor *) knobColor;
+ (NSColor *) lightGrayColor;
+ (NSColor *) magentaColor;
+ (NSColor *) orangeColor;
+ (NSColor *) purpleColor;
+ (NSColor *) redColor;
+ (NSColor *) scrollBarColor;
+ (NSColor *) secondarySelectedControlColor;
+ (NSColor *) selectedControlColor;
+ (NSColor *) selectedControlTextColor;
+ (NSColor *) selectedKnobColor;
+ (NSColor *) selectedMenuItemColor;
+ (NSColor *) selectedMenuItemTextColor;
+ (NSColor *) selectedTextBackgroundColor;
+ (NSColor *) selectedTextColor;
+ (void) setIgnoresAlpha:(BOOL) flag;
+ (NSColor *) shadowColor;
+ (NSColor *) textBackgroundColor;
+ (NSColor *) textColor;
+ (NSColor *) whiteColor;
+ (NSColor *) windowBackgroundColor;
+ (NSColor *) windowFrameColor;
+ (NSColor *) windowFrameTextColor;
+ (NSColor *) yellowColor;

- (CGFloat) alphaComponent;								// Access Components
- (CGFloat) blackComponent;
- (NSColor *) blendedColorWithFraction:(CGFloat) fraction	// Change the color
							   ofColor:(NSColor *) aColor;
- (CGFloat) blueComponent;
- (CGFloat) brightnessComponent;
- (NSString *) catalogNameComponent;
- (NSString *) colorNameComponent;
- (NSColorSpace *) colorSpace;
- (NSString *) colorSpaceName;
- (NSColor *) colorUsingColorSpace:(NSColorSpace *) space;
- (NSColor *) colorUsingColorSpaceName:(NSString *) colorSpace;
- (NSColor *) colorUsingColorSpaceName:(NSString *) colorSpace
								device:(NSDictionary *) deviceDescription;
- (NSColor *) colorWithAlphaComponent:(CGFloat) alpha;
- (CGFloat) cyanComponent;
- (void) drawSwatchInRect:(NSRect) rect;					// Drawing with color
- (void) getComponents:(CGFloat *) components;
- (void) getCyan:(CGFloat *) cyan							// Access Component Set
		 magenta:(CGFloat *) magenta
		  yellow:(CGFloat *) yellow
		   black:(CGFloat *) black
		   alpha:(CGFloat *) alpha;
- (void) getHue:(CGFloat *) hue
	 saturation:(CGFloat *) saturation
	 brightness:(CGFloat *) brightness
		  alpha:(CGFloat *) alpha;
- (void) getRed:(CGFloat *) red
		  green:(CGFloat *) green
		   blue:(CGFloat *) blue
		  alpha:(CGFloat *) alpha;
- (void) getWhite:(CGFloat *) white alpha:(CGFloat *) alpha;
- (CGFloat) greenComponent;
- (NSColor *) highlightWithLevel:(CGFloat) level;
- (CGFloat) hueComponent;
- (NSString *) localizedCatalogNameComponent;
- (NSString *) localizedColorNameComponent;
- (CGFloat) magentaComponent;
- (NSInteger) numberOfComponents;
- (NSImage *) patternImage;
- (CGFloat) redComponent;
- (CGFloat) saturationComponent;
- (void) set;
- (void) setFill;
- (void) setStroke;
- (NSColor *) shadowWithLevel:(CGFloat) level;
- (CGFloat) whiteComponent;
- (void) writeToPasteboard:(NSPasteboard *) pasteBoard;	// Copy / Paste
- (CGFloat) yellowComponent;

@end

extern NSString	*NSSystemColorsDidChangeNotification;

#endif /* _mySTEP_H_NSColor */
