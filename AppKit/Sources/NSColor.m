/* 
   NSColor.m

   NSColor, NSColorList -- Color management classes

   Copyright (C) 1996, 1998 Free Software Foundation, Inc.

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSEnumerator.h>

#import <AppKit/NSColor.h>
#import <AppKit/NSColorSpace.h>
#import <AppKit/NSColorList.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSView.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSImage.h>

#import "NSAppKitPrivate.h"
#import "NSBackendPrivate.h"

// Class variables
static BOOL _ignoresAlpha = YES;		// application wide default

static NSColorList *_systemColors = nil;
static NSMutableDictionary *_colorStrings = nil;

NSString *NSSystemColorsDidChangeNotification =
			@"NSSystemColorsDidChangeNotification";


//*****************************************************************************
//
// 		NSColor 
//
//*****************************************************************************

void GSConvertRGBtoHSB(struct RGB_Color rgb, struct HSB_Color *hsb);
void GSConvertHSBtoRGB(struct HSB_Color hsb, struct RGB_Color *rgb);

// FIXME: should assert _colorPatternImage == nil

#define NEEDRGB() 	if(!_color.rgb) { GSConvertHSBtoRGB(_hsb, &_rgb); _color.rgb = YES; }
#define NEEDHSB() 	if(!_color.hsb) { GSConvertRGBtoHSB(_rgb, &_hsb); _color.hsb = YES; }
#define NEEDCMYK()	NIMP
#define NEEDWHITE()	NIMP

@implementation NSColor

+ (NSColor*) _systemColorWithName:(NSString*)name
{
	NSColor	*color = nil;
	NSString *rep;
#if 0
	NSLog(@"NSColor _systemColorWithName:%@", name);
#endif
	if ((rep = [_colorStrings objectForKey: name]) == nil)
		NSLog(@"Request for unknown system color - '%@'\n", name);
	else
		{
		const char *str = [rep cString];
		float r, g, b;

		if(sscanf(str, "%f %f %f", &r, &g, &b) != 3)
			NSLog(@"System color '%@' has bad string rep: '%@'\n", name, rep);
		else
			if((color = [self colorWithCalibratedRed:r green:g blue:b alpha:1.0]))
				[_systemColors setColor:color forKey:name];
		}

	return color;
}

+ (void) _defaultsDidChange:(NSNotification*)notification
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSEnumerator *enumerator = [_colorStrings keyEnumerator];
	NSString *key;										// enumerate the names of
	BOOL didChange = NO;								// the system colors and 
														// for any in the ddb check
#if 0
	NSLog(@"NSColor _defaultsDidChange");
#endif
	while ((key = [enumerator nextObject]) != nil)	// if current string value
		{											// differs from old.  If it
		NSString *def = [defs stringForKey: key];	// does update color string
													// dictionary and if color
#if 0
		NSLog(@"NSColor stringForKey:%@ -> %@", key, def);
#endif
		if (def != nil)								// exists update system
			{										// color list to contain it
			NSString *old = [_colorStrings objectForKey: key];
			
			if ([def isEqualToString: old] == NO)
				{			
				didChange = YES;					// ddb differs from old val
				[_colorStrings setObject:def forKey:key];
				if (([_systemColors colorWithKey: key]) != nil)
					[NSColor _systemColorWithName: key];
				}
			}
		}
	
	if (didChange)
		[[NSNotificationCenter defaultCenter] postNotificationName:NSSystemColorsDidChangeNotification 
															object: nil];
}

+ (void) initialize
{ // Set up a dictionary containing the names
#if 0
	NSLog(@"NSColor initialize: %@", NSStringFromClass([self class]));
#endif
	if(self == [NSColor class])	// of all the system colors as keys with
		{							// colors in string format as values.
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		NSString *white = 	  @"1.0 1.0 1.0";
		NSString *lightGray = @".667 .667 .667";
		NSString *black =	  @"0.0 0.0 0.0";
		NSString *gray =	  @".5 .5 .5";
#if 0
		NSLog(@"NSColor initialize 00: %@", nc);
#endif
		// FIXME: we should read that from a resource file in AppKit.framework
		_colorStrings = [[NSMutableDictionary dictionaryWithObjectsAndKeys:
			white,				@"controlBackgroundColor",
			white,				@"controlColor",
			@"0.91 0.91 0.91",	@"controlHighlightColor",
			white,				@"controlLightHighlightColor",
			@"0.57 0.57 0.57",	@"controlShadowColor",
			black,				@"controlDarkShadowColor",
			black,				@"controlTextColor",
			@"0.53 0.53 0.53",	@"disabledControlTextColor",
			gray,				@"gridColor",
			@"0.60 0.75 0.98",	@"headerColor",
			black,				@"headerTextColor",
			white,				@"highlightColor",
			@"0.60 0.60 0.73",	@"knobColor",
			white,				@"scrollBarColor",
			@"0.60 0.75 0.98",  @"selectedControlColor",
			black,				@"selectedControlTextColor",
			@"0.16 0.40 0.80",	@"selectedMenuItemColor",
			white,				@"selectedMenuItemTextColor",
			@"0.70 0.85 0.98",	@"selectedTextBackgroundColor",
			black,				@"selectedTextColor",
			@"0.40 0.40 0.60",  @"selectedKnobColor",
			black,				@"shadowColor",
			white,				@"textBackgroundColor",
			black,				@"textColor",
			@"0.95 0.95 0.95",	@"windowBackgroundColor",
			lightGray,			@"windowFrameColor",
			black,				@"windowFrameTextColor",
			
			black,					@"black",
			@"0.333, 0.333, 0.333",	@"darkGray",
			@"0.5, 0.5, 0.5",		@"gray",
			lightGray,				@"lightGray",
			white,					@"white",
			@"0.0, 0.0, 1.0",		@"blue",
			@"0.6, 0.4, 0.2",		@"brown",
			@"0.0, 1.0, 1.0",		@"cyan",
			@"0.0, 1.0, 0.0",		@"green",
			@"1.0, 0.0, 1.0",		@"magenta",
			@"1.0, 0.5, 0.0",		@"orange",
			@"0.5, 0.0, 0.5",		@"purple",
			@"1.0, 0.0, 0.0",		@"red",
			@"1.0, 1.0, 0.0",		@"yellow",
			nil] retain];			// Set up default system colors list
#if 0
		NSLog(@"NSColor initialize 0: %@", _colorStrings);
#endif
		_systemColors = [[NSColorList alloc] initWithName: @"System"];
													// ensure user defaults are  
#if 0
		NSLog(@"NSColor initialize 1");
#endif
		[NSUserDefaults standardUserDefaults];		// loaded, then use them
#if 0
		NSLog(@"NSColor initialize 2");
#endif
		[self _defaultsDidChange: nil];				// and watch for changes.
#if 0
		NSLog(@"NSColor initialize 3");
#endif
		[nc addObserver:self
			selector:@selector(_defaultsDidChange:)
			name:NSUserDefaultsDidChangeNotification
			object:nil];
		}
#if 0
	NSLog(@"NSColor initialize done");
#endif
}
													// create an NSColor from
+ (NSColor*) colorWithCalibratedHue:(float)hue		// component values
						 saturation:(float)saturation	
						 brightness:(float)brightness
						 alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSCalibratedRGBColorSpace;
		c->_color.hsb = YES;
		c->_hsb.hue = hue < 0 || hue > 1 ? 0 : hue;
		c->_hsb.saturation = saturation < 0 || saturation > 1 ? 0 : saturation;
		c->_hsb.brightness = brightness < 0 || brightness > 1 ? 0 : brightness;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
	return c;
}

+ (NSColor*) colorWithCalibratedRed:(float)red
			      			  green:(float)green
			       			  blue:(float)blue
			      			  alpha:(float)alpha
{
	NSColor *c;
#if 0
	NSLog(@"NSColor colorWithCalibratedRed...");
#endif
	c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSCalibratedRGBColorSpace;
		c->_color.rgb = YES;
		c->_rgb.red = red < 0 || red > 1 ? 0 : red;
		c->_rgb.green = green < 0 || green > 1 ? 0 : green;
		c->_rgb.blue = blue < 0 || blue > 1 ? 0 : blue;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
#if 0
	NSLog(@"NSColor colorWithCalibratedRed... -> %@", c);
#endif
	return c;
}

+ (NSColor*) colorWithCalibratedWhite:(float)white 
								alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSCalibratedRGBColorSpace;
		c->_color.rgb = YES;
		c->_rgb.red = c->_rgb.green = c->_rgb.blue = white < 0 || white > 1 ? 0 : white;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
	return c;
}

+ (NSColor*) colorWithCatalogName:(NSString*)listName
						colorName:(NSString*)colorName
{
	NSColor *c;
#if 0
	NSLog(@"NSColor colorWithCatalogName:%@ colorName:%@", listName, colorName);
#endif
	if(![listName isEqualToString:@"System"])
		return nil;
	c=[self _systemColorWithName:colorName];
#if 0
	NSLog(@"NSColor colorWithCatalogName:%@ colorName:%@ -> %@", listName, colorName, c);
#endif
	return c;
}

+ (NSColor*) colorWithDeviceCyan:(float)cyan
						 magenta:(float)magenta
						 yellow:(float)yellow
						 black:(float)black
						 alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSDeviceCMYKColorSpace;
		c->_cmyk.cyan = cyan < 0 || cyan > 1 ? 0 : cyan;
		c->_cmyk.magenta = magenta < 0 || magenta > 1 ? 0 : magenta;
		c->_cmyk.yellow = yellow < 0 || yellow > 1 ? 0 : yellow;
		c->_cmyk.black = black < 0 || black > 1 ? 0 : black;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
	return c;
}

+ (NSColor*) colorWithDeviceHue:(float)hue
		     		 saturation:(float)saturation
		     		 brightness:(float)brightness
			  		 alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSDeviceRGBColorSpace;
		c->_color.hsb = YES;
		c->_hsb.hue = hue < 0 || hue > 1 ? 0 : hue;
		c->_hsb.saturation = saturation < 0 || saturation > 1 ? 0 : saturation;
		c->_hsb.brightness = brightness < 0 || brightness > 1 ? 0 : brightness;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
	return c;
}

+ (NSColor*) colorWithDeviceRed:(float)red
			  			  green:(float)green
			   			  blue:(float)blue
			  			  alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSDeviceRGBColorSpace;
		c->_color.rgb = YES;
		c->_rgb.red = red < 0 || red > 1 ? 0 : red;
		c->_rgb.green = green < 0 || green > 1 ? 0 : green;
		c->_rgb.blue = blue < 0 || blue > 1 ? 0 : blue;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		//	RGB2HSB(c);
		}
	return c;
}

+ (NSColor*) colorWithDeviceWhite:(float)white alpha:(float)alpha
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSDeviceWhiteColorSpace;
		c->_white = white < 0 || white > 1 ? 0 : white;
		c->_alpha = alpha < 0 || alpha > 1 ? 0 : alpha;
		}
	return c;
}

+ (NSColor*) colorWithPatternImage:(NSImage *)image;
{
	NSColor *c = [[[NSColor alloc] init] autorelease];
	if(c)
		{
		c->_colorspaceName = NSPatternImageColorSpace;
		[c->_colorPatternImage autorelease];
		c->_colorPatternImage = [[image copy] retain];	// save a copy
		}
	return c;
}

- (NSImage*) patternImage;
{
	if(!_colorPatternImage || ![_colorspaceName isEqualToString:NSPatternImageColorSpace])
		[NSException raise:NSColorListNotEditableException format: @"Color has no pattern image"];
	return _colorPatternImage;
}

+ (BOOL) ignoresAlpha					{ return _ignoresAlpha; }
+ (void) setIgnoresAlpha:(BOOL)flag		{ _ignoresAlpha = flag; }

// Predefined NSColors (cached)

#define COLOR(R,G,B,A)	static NSColor *c; return c?c:(c=[[NSColor colorWithCalibratedRed:R green:G blue:B alpha:A] retain])	// simple caching system
#define CLR()			static NSColor *c; return c?c:(c=[[NSColor colorWithCatalogName:@"System" colorName:NSStringFromSelector(_cmd)] retain])	// simple caching system

+ (NSColor*) blackColor					{ COLOR(0.0, 0.0, 0.0, 1.0); }
+ (NSColor*) darkGrayColor				{ COLOR(0.33, 0.33, 0.33, 1.0); }
+ (NSColor*) grayColor					{ COLOR(0.5, 0.5, 0.5, 1.0); }
+ (NSColor*) whiteColor					{ COLOR(1.0, 1.0, 1.0, 1.0); }
+ (NSColor*) clearColor					{ COLOR(0.0, 0.0, 0.0, 0.0); }
+ (NSColor*) lightGrayColor				{ COLOR(0.67, 0.67, 0.67, 1.0); }
+ (NSColor*) blueColor					{ COLOR(0.0, 0.0, 1.0, 1.0); }
+ (NSColor*) brownColor					{ COLOR(0.6, 0.4, 0.2, 1.0); }
+ (NSColor*) cyanColor					{ COLOR(0.0, 1.0, 1.0, 1.0); }
+ (NSColor*) greenColor					{ COLOR(0.0, 1.0, 0.0, 1.0); }
+ (NSColor*) magentaColor				{ COLOR(1.0, 0.0, 1.0, 1.0); }
+ (NSColor*) orangeColor				{ COLOR(1.0, 0.5, 0.0, 1.0); }
+ (NSColor*) purpleColor				{ COLOR(0.5, 0.0, 0.5, 1.0); }
+ (NSColor*) redColor					{ COLOR(1.0, 0.0, 0.0, 1.0); }
+ (NSColor*) yellowColor				{ COLOR(1.0, 1.0, 0.0, 1.0); }

+ (NSColor*) controlBackgroundColor		{ CLR(); }
+ (NSColor*) controlColor				{ CLR(); }
+ (NSColor*) controlHighlightColor		{ CLR(); }
+ (NSColor*) controlLightHighlightColor	{ CLR(); }
+ (NSColor*) controlShadowColor			{ CLR(); }
+ (NSColor*) controlDarkShadowColor		{ CLR(); }
+ (NSColor*) controlTextColor			{ CLR(); }
+ (NSColor*) disabledControlTextColor	{ CLR(); }
+ (NSColor*) gridColor					{ CLR(); }
+ (NSColor*) headerColor				{ CLR(); }
+ (NSColor*) headerTextColor			{ CLR(); }
+ (NSColor*) highlightColor				{ CLR(); }
+ (NSColor*) knobColor					{ CLR(); }
+ (NSColor*) scrollBarColor				{ CLR(); }
+ (NSColor*) selectedControlColor		{ CLR(); }
+ (NSColor*) selectedControlTextColor	{ CLR(); }
+ (NSColor*) selectedMenuItemColor		{ CLR(); }
+ (NSColor*) selectedMenuItemTextColor	{ CLR(); }
+ (NSColor*) selectedTextBackgroundColor { CLR();}
+ (NSColor*) selectedTextColor			{ CLR(); }
+ (NSColor*) selectedKnobColor			{ CLR(); }
+ (NSColor*) shadowColor				{ CLR(); }
+ (NSColor*) textBackgroundColor		{ CLR(); }
+ (NSColor*) textColor					{ CLR(); }
+ (NSColor*) windowBackgroundColor		{ CLR(); }  // should be a NSPatternColor
+ (NSColor*) windowFrameColor			{ CLR(); }
+ (NSColor*) windowFrameTextColor		{ CLR(); }
+ (NSColor*) secondarySelectedControlColor			{ CLR(); }
+ (NSColor*) keyboardFocusIndicatorColor			{ CLR(); }
+ (NSColor*) alternateSelectedControlTextColor		{ CLR(); }
+ (NSColor*) alternateSelectedControlColor			{ CLR(); }

+ (NSArray *) controlAlternatingRowBackgroundColors
{ // can be overwritten to provide a different list
	static NSArray *ca;
	if(!ca)
		ca=[[NSArray alloc] initWithObjects:
			[NSColor controlBackgroundColor], 
			[NSColor colorWithCalibratedRed:0.92 green:0.95 blue:0.99 alpha:1.0],
			nil];
	return ca;
}

+ (NSControlTint) currentControlTint;
{
	return NSBlueControlTint;	// should be made a system setting
	// and should post a NSControlTintDidChangeNotification if needed
}
 
+ (NSColor *) colorWithColorSpace:(NSColorSpace *) space
					   components:(const float *) comp
							count:(int) number;
{
	return NIMP;
}
				
+ (NSColor *) colorForControlTint:(NSControlTint) tint;
{
	switch(tint)
		{
		default:
		case NSDefaultControlTint: return [self colorForControlTint:[self currentControlTint]];
		case NSBlueControlTint:
		case NSGraphiteControlTint:
		case NSClearControlTint:
			return [NSColor blueColor];
		}
}

+ (NSColor*) colorFromPasteboard:(NSPasteboard*)pasteBoard
{															
	NSData *d = [pasteBoard dataForType: NSColorPboardType];	// Copy and Pasting
	return (d) ? [NSUnarchiver unarchiveObjectWithData: d] : nil;
}

- (id) init
{
	if((self=[super init]))
		{
		_colorspaceName = @"";
		_catalogName = @"";
		_colorName = @"";
		_colorPatternImage=nil;
		}
	return self;
}

- (void) dealloc
{
	[_colorspaceName release];
	[_catalogName release];
	[_colorName release];
	[_colorPatternImage release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone		{ return [self retain]; }

- (void) set							{ [[NSGraphicsContext currentContext] _setColor:self]; }	
- (void) setFill						{ [[NSGraphicsContext currentContext] _setFillColor:self]; }	
- (void) setStroke						{ [[NSGraphicsContext currentContext] _setStrokeColor:self]; }	

- (void) drawSwatchInRect:(NSRect)rect	
{
	// we should override for a pattern color
	float alpha;
	if(NSIsEmptyRect(rect))
		return;
	alpha=[self alphaComponent];
	if(alpha != 1.0)
		{ // is not completely opaque
		NSBezierPath *p=[NSBezierPath new];
		[p moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
		[p lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
		[p lineToPoint:NSMakePoint(NSMinX(rect), NSMaxY(rect))];
		[[NSColor blackColor] setFill];
		[p fill];	// black triangle
		[p removeAllPoints];
		[p moveToPoint:NSMakePoint(NSMinX(rect), NSMinY(rect))];
		[p lineToPoint:NSMakePoint(NSMaxX(rect), NSMaxY(rect))];
		[p lineToPoint:NSMakePoint(NSMaxX(rect), NSMinY(rect))];
		[[NSColor whiteColor] setFill];
		[p fill];	// white triangle
		[p release];
		}
	if(alpha > 0.0)
		{ // not completely transparent
		[self set];
		NSRectFill(rect);	// overlay with current color
		}
}

- (NSString*) description
{
	NSMutableString	*desc;

//	NSAssert(_colorspaceName != nil, NSInternalInconsistencyException);
											// a simple RGB color without alpha
	if (_colorspaceName == NSCalibratedRGBColorSpace && _alpha == 1.0)
    	return [NSString stringWithFormat: @"\"R:%f G:%f B:%f\"",
							_rgb.red, _rgb.green, _rgb.blue];
 
						// For more complex color values we encode information
						// in a dictionary format with meaningful keys.
	desc = [NSMutableString stringWithCapacity: 128];
	[desc appendFormat: @"{ ColorSpace = \"%@\";", _colorspaceName];

	if (_colorspaceName == NSDeviceWhiteColorSpace
			|| (_colorspaceName == NSCalibratedWhiteColorSpace)
			|| (_colorspaceName == NSDeviceBlackColorSpace)
			|| (_colorspaceName == NSCalibratedBlackColorSpace))
      	[desc appendFormat: @" W = \"%f\";", _white];

	if (_color.rgb)
		{
		[desc appendFormat: @" R = \"%f\";", _rgb.red];
		[desc appendFormat: @" G = \"%f\";", _rgb.green];
		[desc appendFormat: @" B = \"%f\";", _rgb.blue];
		}
	if (_color.hsb)
		{
		[desc appendFormat: @" H = \"%f\";", _hsb.hue];
		[desc appendFormat: @" S = \"%f\";", _hsb.saturation];
		[desc appendFormat: @" B = \"%f\";", _hsb.brightness];
		}

	if (_colorspaceName == NSDeviceCMYKColorSpace)
		{
		[desc appendFormat: @" C = \"%f\";", _cmyk.cyan];
		[desc appendFormat: @" M = \"%f\";", _cmyk.magenta];
		[desc appendFormat: @" Y = \"%f\";", _cmyk.yellow];
		[desc appendFormat: @" K = \"%f\";", _cmyk.black];
		}

	if (_colorspaceName == NSNamedColorSpace)
		{
		[desc appendFormat: @" Catalog = \"%@\";", _catalogName];
		[desc appendFormat: @" Color = \"%@\";", _colorName];
		}

	if(_ignoresAlpha)
		[desc appendFormat: @" ignores Alpha = \"%f\"; }", _alpha];
	else
		[desc appendFormat: @" Alpha = \"%f\"; }", _alpha];

	return desc;
}

- (void) getCyan:(float*)cyan					// Access components as a set
		 magenta:(float*)magenta
	 	 yellow:(float*)yellow					// If ptr is NULL value is not
	  	 black:(float*)black					// set.  Asking for values not
	  	 alpha:(float*)alpha					// in current colorspace gets
{												// bogus values
	NEEDCMYK();
	if (cyan)
		*cyan = _cmyk.cyan;
	if (magenta)
		*magenta = _cmyk.magenta;
	if (yellow)
		*yellow = _cmyk.yellow;
	if (black)
		*black = _cmyk.black;
	if (alpha)
		*alpha = _alpha;
}

- (void) getHue:(float*)hue
		 saturation:(float*)saturation
		 brightness:(float*)brightness
		 alpha:(float*)alpha
{
	NEEDHSB();
	if (hue)
		*hue = _hsb.hue;
	if (saturation)
		*saturation = _hsb.saturation;
	if (brightness)
		*brightness = _hsb.brightness;
	if (alpha)
		*alpha = _alpha;
}

- (void) getRed:(float*)red 
		 green:(float*)green 
		 blue:(float*)blue
		 alpha:(float*)alpha
{
	NEEDRGB();
	if (red)
		*red = _rgb.red;
	if (green)
		*green = _rgb.green;
	if (blue)
		*blue = _rgb.blue;
	if (alpha)
		*alpha = _alpha;
}

- (void) getWhite:(float*)white alpha:(float*)alpha
{
	NEEDWHITE();
	if (white)
		*white = _white;
	if (alpha)
		*alpha = _alpha;
}
														// Access Components
- (float) alphaComponent				{ return _alpha; }
- (float) blackComponent				{ NEEDCMYK(); return _cmyk.black; }
- (float) blueComponent					{ NEEDRGB(); return _rgb.blue; }
- (float) brightnessComponent			{ NEEDHSB(); return _hsb.brightness; }
- (float) cyanComponent					{ NEEDCMYK(); return _cmyk.cyan; }
- (float) greenComponent				{ NEEDRGB(); return _rgb.green; }
- (float) hueComponent					{ NEEDHSB(); return _hsb.hue; }
- (float) magentaComponent				{ NEEDCMYK(); return _cmyk.magenta; }
- (float) redComponent					{ NEEDRGB(); return _rgb.red; }
- (float) saturationComponent			{ NEEDHSB(); return _hsb.saturation; }
- (float) whiteComponent				{ NEEDWHITE(); return _white; }
- (float) yellowComponent				{ NEEDCMYK(); return _cmyk.yellow; }
- (NSString*) catalogNameComponent		{ return _catalogName; }
- (NSString*) colorNameComponent		{ return _colorName; }
- (NSString*) colorSpaceName			{ return _colorspaceName; }

- (NSString*) localizedCatalogNameComponent
{
	return _catalogName;											// FIX ME
}

- (NSString*) localizedColorNameComponent
{
	return _colorName;												// FIX ME
}

- (NSColor*) colorUsingColorSpaceName:(NSString*)colorSpace
{		
	// FIXME: add calibration functions

	if (colorSpace == nil)								// Convert color spaces 
		colorSpace = NSCalibratedRGBColorSpace;

	if ([colorSpace isEqualToString: _colorspaceName])
		return self;	// no change

	if (_colorspaceName == NSNamedColorSpace)
		{ // try to convert
		NSColor *c=[NSColor colorWithCatalogName:_catalogName colorName:_colorName];
		if([c colorSpaceName] == NSNamedColorSpace)
			return nil;	// just returns a named object again...
		return [c colorUsingColorSpaceName:colorSpace];
		}
	if (_colorspaceName == NSCustomColorSpace)
		return nil;

	if ([colorSpace isEqualToString: NSCalibratedRGBColorSpace]
			|| [colorSpace isEqualToString: NSDeviceRGBColorSpace])
		{ // convert to RGB
		NSColor	*c;

		if (_colorspaceName == NSCalibratedRGBColorSpace
				|| _colorspaceName == NSDeviceRGBColorSpace)
			return self;

		c = [[[NSColor alloc] init] autorelease];		// Convert to RGB color

		if (_colorspaceName == NSDeviceCMYKColorSpace)
			{													// CMYK to RGB
			if (_cmyk.black == 0)
				{
				c->_rgb.red = 1 - _cmyk.cyan;
				c->_rgb.green = 1 - _cmyk.magenta;
				c->_rgb.blue = 1 - _cmyk.yellow;
				}
			else if (_cmyk.black == 1)
				c->_rgb.red = c->_rgb.green = c->_rgb.blue = 0;
			else
				{
				double l = _cmyk.cyan;
				double m = _cmyk.magenta;
				double y = _cmyk.yellow;
				double white = 1 - _cmyk.black;
				
				c->_rgb.red = (l > white ? 0 : white - l);
				c->_rgb.green = (m > white ? 0 : white - m);
				c->_rgb.blue = (y > white ? 0 : white - y);
				}		}
		// White to RGB
		if ((_colorspaceName == NSCalibratedWhiteColorSpace)
			|| (_colorspaceName == NSDeviceWhiteColorSpace)
			|| (_colorspaceName == NSDeviceBlackColorSpace)
			|| (_colorspaceName == NSCalibratedBlackColorSpace))
			c->_rgb.red = c->_rgb.green = c->_rgb.blue = _white;
		
		c->_colorspaceName = NSCalibratedRGBColorSpace;
		c->_color.rgb = YES;

	  	return c;
		}

	if ([colorSpace isEqualToString: NSCalibratedWhiteColorSpace]
			|| [colorSpace isEqualToString: NSDeviceWhiteColorSpace])
		{
		NSColor	*c;

		if (_colorspaceName == NSCalibratedWhiteColorSpace
				|| _colorspaceName == NSDeviceWhiteColorSpace)
			return self;

		c = [[[NSColor alloc] init] autorelease];		// Convert to white clr

		if ((_colorspaceName == NSCalibratedRGBColorSpace)		// RGB to white
				|| (_colorspaceName == NSDeviceRGBColorSpace))
			{
			NEEDRGB();
			c->_white = (_rgb.red + _rgb.green + _rgb.blue) / 3;
			}

		if ((_colorspaceName == NSCalibratedBlackColorSpace)	// black to wht
				|| (_colorspaceName == NSDeviceBlackColorSpace))
			c->_white = 1.0 - _white;

		if (_colorspaceName == NSDeviceCMYKColorSpace)			// CMYK to wht
			{
			c = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
			c->_white = (c->_rgb.red + c->_rgb.green + c->_rgb.blue) / 3.0;
			}

		c->_colorspaceName = NSCalibratedWhiteColorSpace;

	  	return c;
		}

	if ([colorSpace isEqualToString: NSCalibratedBlackColorSpace]
			|| [colorSpace isEqualToString: NSDeviceBlackColorSpace])
		{
		NSColor	*c;

		if (_colorspaceName == NSCalibratedBlackColorSpace
				|| _colorspaceName == NSDeviceBlackColorSpace)
			return self;

		c = [self colorUsingColorSpaceName:NSCalibratedWhiteColorSpace];
		c->_white = 1.0 - _white;

	  	return c;
		}
													// FIX ME convert to CMYK
//	if ([colorSpace isEqualToString: NSDeviceCMYKColorSpace])

	return nil;
}

- (NSColor*) colorUsingColorSpaceName:(NSString*)colorSpace
							   device:(NSDictionary*)deviceDescription
{
	return [self colorUsingColorSpaceName:colorSpace];
}

- (NSColor*) blendedColorWithFraction:(float)fraction 
							  ofColor:(NSColor*)aColor
{
	NSColor	*color = self;									// Blending the Color
	NSColor	*other = aColor;
	float mr, mg, mb, or, og, ob, r, g, b;

	if ((_colorspaceName != NSCalibratedRGBColorSpace)
			&& (_colorspaceName != NSDeviceRGBColorSpace))
		color = [self colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if ((aColor->_colorspaceName != NSCalibratedRGBColorSpace)
			&& (aColor->_colorspaceName != NSDeviceRGBColorSpace))
		other = [aColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];

	if (color == nil || other == nil)
		return nil;

	[color getRed: &mr green: &mg blue: &mb alpha:NULL];
	[other getRed: &or green: &og blue: &ob alpha:NULL];
	r = fraction * mr + (1 - fraction) * or;
	g = fraction * mg + (1 - fraction) * og;
	b = fraction * mb + (1 - fraction) * ob;

	return [NSColor colorWithCalibratedRed: r green: g blue: b alpha: 1.0];
}

- (NSColor*) colorWithAlphaComponent:(float)alpha
{
	NSColor *c=[isa alloc];	// make a copy
	if(c)
		{ // make a "mutable" copy
		c->_colorspaceName=[_colorspaceName retain];
		c->_catalogName=[_catalogName retain];
		c->_colorName=[_catalogName retain];
		c->_colorPatternImage=[_catalogName retain];
		c->_rgb=_rgb;
		c->_cmyk=_cmyk;
		c->_hsb=_hsb;
		c->_white=_white;
		c->_color=_color;
		if(alpha < 0)
			c->_alpha = 0.0;
		else if(alpha > 1.0)
			c->_alpha=1.0;
		else
			c->_alpha=alpha;
		}
	return [c autorelease];
}

- (NSColor*) highlightWithLevel:(float)level
{
	return [self blendedColorWithFraction: level 
				 ofColor: [NSColor highlightColor]];
}

- (NSColor*) shadowWithLevel:(float)level
{
	return [self blendedColorWithFraction:level ofColor:[NSColor shadowColor]];
}

- (void) writeToPasteboard:(NSPasteboard*)pasteBoard	// Copy / Paste
{
	NSData *d = [NSArchiver archivedDataWithRootObject: self];
	if(d)
		[pasteBoard setData: d forType: NSColorPboardType];
}

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{																
	// FIXME: we should encode the rgb&hsb flags
	[aCoder encodeValueOfObjCType: "f" at: &_rgb.red];
	[aCoder encodeValueOfObjCType: "f" at: &_rgb.green];
	[aCoder encodeValueOfObjCType: "f" at: &_rgb.blue];
	[aCoder encodeValueOfObjCType: "f" at: &_alpha];
	[aCoder encodeObject: _colorspaceName];
	[aCoder encodeObject: _catalogName];
	[aCoder encodeObject: _colorName];
	[aCoder encodeValueOfObjCType: "f" at: &_cmyk.cyan];
	[aCoder encodeValueOfObjCType: "f" at: &_cmyk.magenta];
	[aCoder encodeValueOfObjCType: "f" at: &_cmyk.yellow];
	[aCoder encodeValueOfObjCType: "f" at: &_cmyk.black];
	[aCoder encodeValueOfObjCType: "f" at: &_hsb.hue];
	[aCoder encodeValueOfObjCType: "f" at: &_hsb.saturation];
	[aCoder encodeValueOfObjCType: "f" at: &_hsb.brightness];
	[aCoder encodeValueOfObjCType: "f" at: &_white];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at: &_color];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if(![aDecoder allowsKeyedCoding])
		{
		// FIXME: we should decode the rgb&hsb flags
		[aDecoder decodeValueOfObjCType: "f" at: &_rgb.red];
		[aDecoder decodeValueOfObjCType: "f" at: &_rgb.green];
		[aDecoder decodeValueOfObjCType: "f" at: &_rgb.blue];
		[aDecoder decodeValueOfObjCType: "f" at: &_alpha];
		_colorspaceName = [[aDecoder decodeObject] retain];
		_catalogName = [[aDecoder decodeObject] retain];
		_colorName = [[aDecoder decodeObject] retain];
		[aDecoder decodeValueOfObjCType: "f" at: &_cmyk.cyan];
		[aDecoder decodeValueOfObjCType: "f" at: &_cmyk.magenta];
		[aDecoder decodeValueOfObjCType: "f" at: &_cmyk.yellow];
		[aDecoder decodeValueOfObjCType: "f" at: &_cmyk.black];
		[aDecoder decodeValueOfObjCType: "f" at: &_hsb.hue];
		[aDecoder decodeValueOfObjCType: "f" at: &_hsb.saturation];
		[aDecoder decodeValueOfObjCType: "f" at: &_hsb.brightness];
		[aDecoder decodeValueOfObjCType: "f" at: &_white];
		[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_color];
		}
	else
		{
#if 0
		NSLog(@"%@ initWithCoder:%@", NSStringFromClass([self class]), aDecoder);
		NSLog(@"NSColorSpace=%d", [aDecoder decodeIntForKey:@"NSColorSpace"]);
		NSLog(@"NSColor=%@", [aDecoder decodeObjectForKey:@"NSColor"]);	// is this a subcolor or alternate color?
#endif
#if 1	// reference once for NSKeyedArchiver debugging
		[aDecoder decodeObjectForKey:@"NSColor"];
#endif
		switch([aDecoder decodeIntForKey:@"NSColorSpace"])
			{
			case 6:	// Catalog
				{
					NSColor *c=[isa colorWithCatalogName:[aDecoder decodeObjectForKey:@"NSCatalogName"] colorName:[aDecoder decodeObjectForKey:@"NSColorName"]];
					if(!c)
						{
						NSLog(@"substitute %@/%@", [aDecoder decodeObjectForKey:@"NSCatalogName"], [aDecoder decodeObjectForKey:@"NSColorName"]);
						c=[aDecoder decodeObjectForKey:@"NSColor"];	// try to substitute if not in catalog
						}
					[self release];
#if 0
					NSLog(@"initWithCoder -> %@", c);
#endif
					return [c retain];
				}
			case 3:	// Gray
				{
					NSColor *c;
					unsigned int len;
					float white=0.0, alpha=1.0;
					char *s=(char *)[aDecoder decodeBytesForKey:@"NSWhite" returnedLength:&len];
					if(s)
						sscanf(s, "%f %f", &white, &alpha);
					else
						NSLog(@"NSColor initWithCoder: can't decode NSWhite (%@)", aDecoder);
					c=[isa colorWithCalibratedWhite:white alpha:alpha];
					[self release];
#if 0
					NSLog(@"initWithCoder -> %@", c);
#endif
					return [c retain];
				}
			case 2:	// RGB
			case 1:	// RGB
				{
					NSColor *c;
					unsigned int len;
					float red=0.0, green=0.0, blue=0.0, alpha=1.0;
					char *s=(char *)[aDecoder decodeBytesForKey:@"NSRGB" returnedLength:&len];
					if(s)
						sscanf(s, "%f %f %f %f", &red, &green, &blue, &alpha);	// alpha might be missing
					else
						NSLog(@"NSColor initWithCoder: can't decode NSRGB (%@)", aDecoder);
					c=[isa colorWithCalibratedRed:red green:green blue:blue alpha:alpha];
					[self release];
#if 0
					NSLog(@"initWithCoder -> %@", c);
#endif
					return [c retain];
				}
			default:
				NSLog(@"unimplemented initWithCoder: for color space model %d (coder=%@)", [aDecoder decodeIntForKey:@"NSColorSpace"], aDecoder);
				[self autorelease];
				return [[isa grayColor] retain];
			}
		}
	return self;
}

- (int) numberOfComponents;
{
	return [[self colorSpace] numberOfColorComponents];
}

- (void) getComponents:(float *) components;
{
	NIMP;
}

- (NSColor *) colorUsingColorSpace:(NSColorSpace *)space;
{
	return [self colorUsingColorSpaceName:[space localizedName]];
}

- (NSColorSpace *) colorSpace;
{
	return NIMP;
}

@end /* NSColor */

//*****************************************************************************
//
// 		NSColorList 
//
//*****************************************************************************

// Class variables
static NSMutableArray *_availableColorLists;
static NSLock *_colorListLock;

@implementation NSColorList

+ (void) initialize
{
#if 0
	NSLog(@"NSColorList initialize");
#endif
	if(self == [NSColorList class])
		{
		_availableColorLists = [NSMutableArray new];	 // color lists array
		_colorListLock = [[NSLock alloc] init];			 // And its access lock
		}
}

+ (NSArray*) availableColorLists
{
NSArray *a;
														// Serialize access to 
	[_colorListLock lock];								// color list
	a = [[[NSArray alloc] initWithArray: _availableColorLists] autorelease];
	[_colorListLock unlock];
	
	return a;
}

+ (NSColorList*) colorListNamed:(NSString*)name
{
int i, count;
NSColorList* color = nil;
														// Serialize access to 
	[_colorListLock lock];								// color list
	for (i = 0, count = [_availableColorLists  count]; i < count; i++) 		
		{
		color = [_availableColorLists  objectAtIndex:i];
		if ([name compare:[color name]] == NSOrderedSame)
			break;
		}
	[_colorListLock unlock];

	return (i == count) ? nil : color;
}

- (NSDictionary*) _colorListDictionary		{ return color_list; }

- (id) initWithName:(NSString*)name
{
	[super init];
														// Initialize instance
	list_name = [name retain];							// variables
	color_list = [NSMutableDictionary new];
	color_list_keys = [NSMutableArray new];
	is_editable = YES;
	file_name = @"";
														// Add to global list 
	[_colorListLock lock];								// of colors
	[_availableColorLists addObject: self];
	[_colorListLock unlock];
	
	return self;
}

- (id) initWithName:(NSString*)name fromFile:(NSString*)path
{
id cl;										// path s/b absolute, name s/b file
											// name minus '.clr' extension. nil
	if(path == nil)							// path indicates no init from file
		return [self initWithName:name];

	[super init];							

	list_name = [name retain];
														// Unarchive color list
	cl = [NSUnarchiver unarchiveObjectWithFile:(file_name = [path retain])];
														// Copy the color list 
	is_editable = [cl isEditable];						// elements to self
	color_list = [NSMutableDictionary alloc];
	[color_list initWithDictionary: [cl _colorListDictionary]];
	color_list_keys = [NSMutableArray alloc];
	[color_list_keys initWithArray: [cl allKeys]];
	
	[cl release];
	
	[_colorListLock lock];								// Add to global list 
	[_availableColorLists  addObject: self];			// of colors
	[_colorListLock unlock];
	
	return self;
}

- (void) dealloc
{
	[list_name release];
	[color_list release];
	[color_list_keys release];
	[super dealloc];
}

- (NSString*) name							{ return list_name; }
- (BOOL) isEditable							{ return is_editable; }

- (NSArray*) allKeys
{
	return [[[NSArray alloc] initWithArray: color_list_keys] autorelease];
}

- (NSColor*) colorWithKey:(NSString*)key
{
NSColor *color = [color_list objectForKey: key];
#if 0
	NSLog(@"NSColorList colorWithKey:%@", key);
#endif
	return (!color) ? [NSColor _systemColorWithName:key] : color;
}

- (void) insertColor:(NSColor*)color
				 key:(NSString*)key
				 atIndex:(unsigned)location
{
	if (!is_editable)								// Are we even editable?
		[NSException raise: NSColorListIOException
					 format: @"Color list cannot be edited"];

	[color_list setObject: color forKey: key];					// add color
	[color_list_keys removeObject: key];
	[color_list_keys insertObject: key atIndex: location];
														   // post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:NSColorListChangedNotification object: self];
}

- (void) removeColorWithKey:(NSString*)key
{
	if (!is_editable)								// Are we even editable?
		[NSException raise: NSColorListNotEditableException
					 format: @"Color list cannot be edited"];

	[color_list removeObjectForKey: key];
	[color_list_keys removeObject: key];
														   // post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:NSColorListChangedNotification object: self];
}

- (void) setColor:(NSColor*)aColor forKey:(NSString*)key
{
	if (!is_editable)								// Are we even editable?
		[NSException raise: NSColorListNotEditableException
					 format: @"Color list cannot be edited"];

	[color_list setObject: aColor forKey: key];
													// Add to list if doesn't 
	if (![color_list_keys containsObject: key])		// already exist
		[color_list_keys addObject: key];
														   // post notification
	[[NSNotificationCenter defaultCenter] postNotificationName:NSColorListChangedNotification object: self];
}

- (BOOL) writeToFile:(NSString*)path					// FIX ME not to spec
{														// Archive to the file
	return [NSArchiver archiveRootObject:self toFile:path];
}

- (void) removeFile
{								// FIX ME Tell NSWorkspace to remove the file
	[_colorListLock lock];								// Remove from global
	[_availableColorLists  removeObject: self];			// list of colors
	[_colorListLock unlock];
}

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{
	[aCoder encodeObject: list_name];
	[aCoder encodeObject: color_list];
	[aCoder encodeObject: color_list_keys];
	[aCoder encodeValueOfObjCType:@encode(BOOL) at: &is_editable];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		return self;
		}
	list_name = [[aDecoder decodeObject] retain];
	color_list = [[aDecoder decodeObject] retain];
	color_list_keys = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType:@encode(BOOL) at: &is_editable];
	
	return self;
}

@end /* NSColorList */


void GSConvertHSBtoRGB(struct HSB_Color hsb, struct RGB_Color *rgb)
{
    if (hsb.saturation == 0.0) 
		rgb->red = rgb->green = rgb->blue = hsb.brightness;
	else
		{
		// FIXME: this appears to be an approximation
		int h = ((unsigned short)(360.0*hsb.hue)) % 360;
		int s = 256*hsb.saturation;
		int v = 256*hsb.brightness;
		int i = h / 60;
		int f = h % 60;
		int p = (v * (256 - s)) / 256;
		int q = (v * (256 - s * f / 60)) / 256;
		int t = (v * (256 - s * (60 - f) / 60)) / 256;

		switch (i) 
			{ // let's hope the compiler optimizes the constant float expression...
			case 0: rgb->red = v*(1.0/256); rgb->green = t*(1.0/256); rgb->blue = p*(1.0/256); break;
			case 1: rgb->red = q*(1.0/256); rgb->green = v*(1.0/256); rgb->blue = p*(1.0/256); break;
			case 2: rgb->red = p*(1.0/256); rgb->green = v*(1.0/256); rgb->blue = t*(1.0/256); break;
			case 3: rgb->red = p*(1.0/256); rgb->green = q*(1.0/256); rgb->blue = v*(1.0/256); break;
			case 4: rgb->red = t*(1.0/256); rgb->green = p*(1.0/256); rgb->blue = v*(1.0/256); break;
			case 5: rgb->red = v*(1.0/256); rgb->green = p*(1.0/256); rgb->blue = q*(1.0/256); break;
		}	}
}

void GSConvertRGBtoHSB(struct RGB_Color rgb, struct HSB_Color *hsb)
{
	float min = MIN(MIN(rgb.red, rgb.green), rgb.blue);
	float max = MAX(MAX(rgb.red, rgb.green), rgb.blue);
	float diff= max - min;
	if(diff < 0.003)
		hsb->hue=0.0;	// undefined;
	else
		{
		float r = (max - rgb.red)/diff;
		float g = (max - rgb.green)/diff;
		float b = (max - rgb.blue)/diff;
		if(r == max)
			hsb->hue = (60.0/360.0)*(b - g);
		else if(g == max)
			hsb->hue = (1.0/3.0) + (60.0/360.0)*(r - b);
		else if(b == max)
			hsb->hue = (2.0/3.0) + (60.0/360.0)*(g - r);
		if(hsb->hue < 0)
			hsb->hue+=1.0;
		}
	if(max < 0.003)
		hsb->saturation=0.0;
	else
		hsb->saturation = diff / max;
	hsb->brightness = max;
}

// EOF