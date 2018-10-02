/* 
   NSButtonCell.h

   Button cell class for NSButton

   Copyright (C) 1996 Free Software Foundation, Inc.

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

#ifndef _mySTEP_H_NSButtonCell
#define _mySTEP_H_NSButtonCell

#import <AppKit/NSActionCell.h>

@class NSFont;
@class NSSound;
@class NSAttributedTitle;

typedef NSUInteger NSButtonType;

enum {	// plese don't change order! setButtonType: isn't compatible otherwise
	NSMomentaryLightButton=0,
	NSPushOnPushOffButton=1,
	NSToggleButton=2,
	NSSwitchButton=3,
	NSRadioButton=4,
	NSMomentaryChangeButton=5,
	NSOnOffButton=6,
	NSMomentaryPushInButton=7,
	NSAcceleratorButton=8,	// since 10.10.3
	NSMultiLevelAcceleratorButton=9,	// since 10.10.3
	NSMomentaryPushButton=NSMomentaryLightButton,
	NSMomentaryLight=NSMomentaryPushInButton
};

typedef NSUInteger NSBezelStyle;

enum {		// Name in IB
	_NSTraditionalBezelStyle=0,
	NSRoundedBezelStyle=1,			// Push Button
	NSRegularSquareBezelStyle,		// Rounded Bevel Button
	NSThickSquareBezelStyle,		// -
	NSThickerSquareBezelStyle,		// -
	NSDisclosureBezelStyle=5,		// Disclosure Button
	NSShadowlessSquareBezelStyle=6,	// Square Button
	NSCircularBezelStyle=7,			// Round Button
	NSTexturedSquareBezelStyle=8,	// Square Textured Button
	NSHelpButtonBezelStyle=9,		// Help Button
	NSSmallSquareBezelStyle=10,		// Small Square Button
	NSTexturedRoundBezelStyle=11,	// Round Textured Button
	NSRoundRectBezelStyle=12,		// -
	NSRecessedBezelStyle=13,		// -
	NSRoundedDisclosureBezelStyle=14,	// -
	NSBezelStyleInline=15				// since 10.7
};

typedef NSUInteger NSGradientType;

enum {
	NSGradientNone=0,
	NSGradientConcaveWeak,
	NSGradientConcaveStrong,
	NSGradientConvexWeak,
	NSGradientConvexStrong
};

@interface NSButtonCell : NSActionCell  <NSCopying, NSCoding>
{
	NSImage *_normalImage;
	NSImage *_alternateImage;
	NSImage *_mixedImage;
	NSString *_alternateTitle;
	NSString *_keyEquivalent;
	NSFont *_keyEquivalentFont;
	NSColor *_backgroundColor;
	NSImage *_image;	// image that is currently drawn (FIXME: should not be an iVar)
	id _title;
	NSUInteger _keyEquivalentModifierMask;
	NSUInteger _highlightMask;
	NSUInteger _stateMask;
	float _periodicDelay;
	float _periodicInterval;
	NSButtonType _buttonType;	// saved internally
	NSBezelStyle _bezelStyle;
	NSImageScaling _imageScaling;
	BOOL _transparent;
	BOOL _dimsWhenDisabled;
}

- (NSImage *) alternateImage;								// Images
- (NSString *) alternateMnemonic;
- (NSUInteger) alternateMnemonicLocation;
- (NSString *) alternateTitle;								// Titles
- (NSAttributedString *) attributedAlternateTitle;
- (NSAttributedString *) attributedTitle;
- (NSColor *) backgroundColor;
- (NSBezelStyle) bezelStyle;
- (void) drawBezelWithFrame:(NSRect) frame inView:(NSView *) control;
- (void) drawImage:(NSImage *) image withFrame:(NSRect) frame inView:(NSView *) control;
- (void) drawTitle:(NSAttributedString *) title withFrame:(NSRect) frame inView:(NSView *) control;
- (void) getPeriodicDelay:(float *)delay interval:(float *) interval;
- (NSGradientType) gradientType;
- (NSInteger) highlightsBy;
- (BOOL) imageDimsWhenDisabled;
- (NSCellImagePosition) imagePosition;
- (NSImageScaling) imageScaling;
// inherited - (BOOL) isOpaque;										// -> NSCell
- (BOOL) isTransparent;										// Graphic Attribs
// inherited - (NSString *) keyEquivalent;							// -> NSCell
- (NSFont *) keyEquivalentFont;
- (NSUInteger) keyEquivalentModifierMask;
- (void) mouseEntered:(NSEvent *) event;
- (void) mouseExited:(NSEvent *) event;
// inherited - (void) performClick:(id)sender;						// -> NSCell
- (void) setAlternateImage:(NSImage *) anImage;
- (void) setAlternateMnemonicLocation:(NSUInteger) location;
- (void) setAlternateTitle:(NSString *) aString;
- (void) setAlternateTitleWithMnemonic:(NSString *) aString;
- (void) setAttributedAlternateTitle:(NSAttributedString *) aString;
- (void) setAttributedTitle:(NSAttributedString *) aString;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBezelStyle:(NSBezelStyle) style;
- (void) setButtonType:(NSButtonType) aType;
// - (void) setFont:(NSFont *)fontObject;   // -> NSFont & NSActionCell
- (void) setGradientType:(NSGradientType) type;
- (void) setHighlightsBy:(NSInteger) aType;
- (void) setImageDimsWhenDisabled:(BOOL) flag;
- (void) setImagePosition:(NSCellImagePosition) aPosition;
- (void) setImageScaling:(NSImageScaling) scale;
- (void) setKeyEquivalent:(NSString *) aKeyEquivalent;
- (void) setKeyEquivalentFont:(NSFont *) fontObj;
- (void) setKeyEquivalentFont:(NSString *) fontName size:(CGFloat) fontSize;
- (void) setKeyEquivalentModifierMask:(NSUInteger) mask;
- (void) setPeriodicDelay:(float)delay interval:(float) interval;
- (void) setShowsBorderOnlyWhileMouseInside:(BOOL) flag;
- (void) setShowsStateBy:(NSInteger) aType;
- (void) setSound:(NSSound *) aSound;
- (void) setTitle:(NSString *) aString;
// inherited - (void) setTitleWithMnemonic:(NSString *)aString;		// -> NSCell
- (void) setTransparent:(BOOL) flag;
- (BOOL) showsBorderOnlyWhileMouseInside;
- (NSInteger) showsStateBy;
- (NSSound *)sound;
// inherited - (NSString *) title;									// -> NSCell

@end

#endif /* _mySTEP_H_NSButtonCell */
