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
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSButtonCell
#define _mySTEP_H_NSButtonCell

#import <AppKit/NSActionCell.h>

@class NSFont;
@class NSSound;
@class NSAttributedTitle;

typedef enum _NSButtonType {	// plese don't change order! setButtonType: isn't compatible otherwise
	NSMomentaryLightButton=0,
	NSPushOnPushOffButton,
	NSToggleButton,
	NSSwitchButton,
	NSRadioButton,
	NSMomentaryChangeButton,
	NSOnOffButton,
	NSMomentaryPushInButton
} NSButtonType;

typedef enum _NSBezelStyle {		// Name in IB
	_NSTraditionalBezelStyle=0,
	NSRoundedBezelStyle=1,			// Push Button
	NSRegularSquareBezelStyle,		// Rounded Bevel Button
	NSThickSquareBezelStyle,		// -
	NSThickerSquareBezelStyle,		// -
	NSDisclosureBezelStyle,			// Disclosure Button
	NSShadowlessSquareBezelStyle,	// Square Button
	NSCircularBezelStyle,			// Round Button
	NSTexturedSquareBezelStyle,		// Square Textured Button
	NSHelpButtonBezelStyle,			// Help Button
	NSSmallSquareBezelStyle,		// Small Square Button
	NSTexturedRoundBezelStyle,		// Round Textured Button
	NSRoundRectBezelStyle,			// -
	NSRecessedBezelStyle,			// -
	NSRoundedDisclosureBezelStyle	// -
} NSBezelStyle;

typedef enum _NSGradientType {
	NSGradientNone=0,
	NSGradientConcaveWeak,
	NSGradientConcaveStrong,
	NSGradientConvexWeak,
	NSGradientConvexStrong
} NSGradientType;

@interface NSButtonCell : NSActionCell  <NSCopying, NSCoding>
{
	NSImage *_normalImage;
	NSImage *_alternateImage;
	NSImage *_mixedImage;
	NSString *_alternateTitle;
	NSString *_keyEquivalent;
	NSAttributedString *_attributedTitle;
	NSAttributedString *_attributedAlternateTitle;
	NSFont *_keyEquivalentFont;
	NSColor *_backgroundColor;
	NSImage *_image;	// image that is currently drawn (FIXME: should not be an iVar)
	unsigned int _keyEquivalentModifierMask;
	unsigned int _highlightMask;
	unsigned int _stateMask;
    float _periodicDelay;
    float _periodicInterval;
	NSButtonType _buttonType;	// saved internally
	NSBezelStyle _bezelStyle;
	BOOL _transparent;
	BOOL _dimsWhenDisabled;
}

- (NSImage *) alternateImage;								// Images
- (NSString *) alternateMnemonic;
- (unsigned) alternateMnemonicLocation;
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
- (int) highlightsBy;
- (BOOL) imageDimsWhenDisabled;
- (NSCellImagePosition) imagePosition;
// inherited - (BOOL) isOpaque;										// -> NSCell
- (BOOL) isTransparent;										// Graphic Attribs
// inherited - (NSString *) keyEquivalent;							// -> NSCell
- (NSFont *) keyEquivalentFont;
- (unsigned int) keyEquivalentModifierMask;
- (void) mouseEntered:(NSEvent *) event;
- (void) mouseExited:(NSEvent *) event;
// inherited - (void) performClick:(id)sender;						// -> NSCell
- (void) setAlternateImage:(NSImage *) anImage;
- (void) setAlternateMnemonicLocation:(unsigned) location;
- (void) setAlternateTitle:(NSString *) aString;
- (void) setAlternateTitleWithMnemonic:(NSString *) aString;
- (void) setAttributedAlternateTitle:(NSAttributedString *) aString;
- (void) setAttributedTitle:(NSAttributedString *) aString;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBezelStyle:(NSBezelStyle) style;
- (void) setButtonType:(NSButtonType) aType;
// - (void) setFont:(NSFont *)fontObject;   // -> NSFont & NSActionCell
- (void) setGradientType:(NSGradientType) type;
- (void) setHighlightsBy:(int) aType;
- (void) setImageDimsWhenDisabled:(BOOL) flag;
- (void) setImagePosition:(NSCellImagePosition) aPosition;
- (void) setKeyEquivalent:(NSString *) aKeyEquivalent;
- (void) setKeyEquivalentFont:(NSFont *) fontObj;
- (void) setKeyEquivalentFont:(NSString *) fontName size:(float) fontSize;
- (void) setKeyEquivalentModifierMask:(unsigned int) mask;
- (void) setPeriodicDelay:(float)delay interval:(float) interval;
- (void) setShowsBorderOnlyWhileMouseInside:(BOOL) flag;
- (void) setShowsStateBy:(int) aType;
- (void) setSound:(NSSound *) aSound;
// inherited - (void) setTitle:(NSString *)aString;					// -> NSCell
// inherited - (void) setTitleWithMnemonic:(NSString *)aString;		// -> NSCell
- (void) setTransparent:(BOOL) flag;
- (BOOL) showsBorderOnlyWhileMouseInside;
- (int) showsStateBy;
- (NSSound *)sound;
// inherited - (NSString *) title;									// -> NSCell

@end

#endif /* _mySTEP_H_NSButtonCell */
