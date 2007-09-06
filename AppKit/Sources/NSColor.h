/* 
   NSColor.h

   Color class interface

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
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
		float red;
		float green;
		float blue;
		} _rgb;
	
	struct CMYK_Color
		{
		float cyan;
		float magenta;
		float yellow;
		float black;
		} _cmyk;
	
	struct HSB_Color
		{
		float hue;
		float saturation;
		float brightness;
		} _hsb;

	float _white;
	float _alpha;
	
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
+ (NSColor *) colorFromPasteboard:(NSPasteboard *)pasteBoard;
+ (NSColor *) colorWithCalibratedHue:(float)hue
						  saturation:(float)saturation
						  brightness:(float)brightness
							   alpha:(float)alpha;
+ (NSColor *) colorWithCalibratedRed:(float)red
							   green:(float)green
								blue:(float)blue
							   alpha:(float)alpha;
+ (NSColor *) colorWithCalibratedWhite:(float)white
								 alpha:(float)alpha;
+ (NSColor *) colorWithCatalogName:(NSString *)listName
						 colorName:(NSString *)colorName;
// + (NSColor *) colorWithCIColor:(CIColor *) color;
+ (NSColor *) colorWithColorSpace:(NSColorSpace *) space
					   components:(const float *) comp
							count:(int) number;
+ (NSColor *) colorWithDeviceCyan:(float)cyan
						  magenta:(float)magenta
						   yellow:(float)yellow
							black:(float)black
							alpha:(float)alpha;
+ (NSColor *) colorWithDeviceHue:(float)hue
					  saturation:(float)saturation
					  brightness:(float)brightness
						   alpha:(float)alpha;
+ (NSColor *) colorWithDeviceRed:(float)red
						   green:(float)green
							blue:(float)blue
						   alpha:(float)alpha;
+ (NSColor *) colorWithDeviceWhite:(float)white
							 alpha:(float)alpha;
+ (NSColor *) colorWithPatternImage:(NSImage *)image;
+ (NSArray *) controlAlternatingRowBackgroundColors;
+ (NSColor *) controlBackgroundColor;					// System colors
+ (NSColor *) controlColor;
+ (NSColor *) controlDarkShadowColor;
+ (NSColor *) controlHighlightColor;
+ (NSColor *) controlLightHighlightColor;
+ (NSColor *) controlShadowColor;
+ (NSColor *) controlDarkShadowColor;
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
+ (void) setIgnoresAlpha:(BOOL)flag;
+ (NSColor *) shadowColor;
+ (NSColor *) textBackgroundColor;
+ (NSColor *) textColor;
+ (NSColor *) whiteColor;
+ (NSColor *) windowBackgroundColor;
+ (NSColor *) windowFrameColor;
+ (NSColor *) windowFrameTextColor;
+ (NSColor *) yellowColor;

- (float) alphaComponent;								// Access Components
- (float) blackComponent;
- (NSColor *) blendedColorWithFraction:(float)fraction	// Change the color
							  ofColor:(NSColor *)aColor;
- (float) blueComponent;
- (float) brightnessComponent;
- (NSString *) catalogNameComponent;
- (NSString *) colorNameComponent;
- (NSColorSpace *) colorSpace;
- (NSString *) colorSpaceName;
- (NSColor *) colorUsingColorSpace:(NSColorSpace *)space;
- (NSColor *) colorUsingColorSpaceName:(NSString *)colorSpace;
- (NSColor *) colorUsingColorSpaceName:(NSString *)colorSpace
								device:(NSDictionary *)deviceDescription;
- (NSColor *) colorWithAlphaComponent:(float)alpha;
- (float) cyanComponent;
- (void) drawSwatchInRect:(NSRect)rect;					// Drawing with color
- (void) getComponents:(float *) components;
- (void) getCyan:(float *)cyan							// Access Component Set
		 magenta:(float *)magenta
		  yellow:(float *)yellow
		   black:(float *)black
		   alpha:(float *)alpha;
- (void) getHue:(float *)hue
	 saturation:(float *)saturation
	 brightness:(float *)brightness
		  alpha:(float *)alpha;
- (void) getRed:(float *)red
		  green:(float *)green
		   blue:(float *)blue
		  alpha:(float *)alpha;
- (void) getWhite:(float *)white alpha:(float *)alpha;
- (float) greenComponent;
- (NSColor *) highlightWithLevel:(float)level;
- (float) hueComponent;
- (NSString *) localizedCatalogNameComponent;
- (NSString *) localizedColorNameComponent;
- (float) magentaComponent;
- (int) numberOfComponents;
- (NSImage *) patternImage;
- (float) redComponent;
- (float) saturationComponent;
- (void) set;
- (void) setFill;
- (void) setStroke;
- (NSColor *) shadowWithLevel:(float)level;
- (float) whiteComponent;
- (void) writeToPasteboard:(NSPasteboard *)pasteBoard;	// Copy / Paste
- (float) yellowComponent;

@end

extern NSString	*NSSystemColorsDidChangeNotification;

#endif /* _mySTEP_H_NSColor */
