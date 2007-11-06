/* 
   NSColorPanel.h

   System generic color panel

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007  
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSColorPanel
#define _mySTEP_H_NSColorPanel

#import <AppKit/NSPanel.h>

enum
{
	NSColorPanelGrayModeMask			=0x0001,
	NSColorPanelRGBModeMask				=0x0002,
	NSColorPanelCMYKModeMask			=0x0004,
	NSColorPanelHSBModeMask				=0x0008,
	NSColorPanelCustomPaletteModeMask	=0x0010,
	NSColorPanelColorListModeMask		=0x0020,
	NSColorPanelWheelModeMask			=0x0040,
	NSColorPanelCrayonModeMask			=0x0080,
	NSColorPanelAllModesMask			=0x0100
};

typedef NSInteger NSColorPanelMode;

enum {
	NSNoModeColorPanel             = -1,
	NSGrayModeColorPanel            = 0,
	NSRGBModeColorPanel             = 1,
	NSCMYKModeColorPanel            = 2,
	NSHSBModeColorPanel             = 3,
	NSCustomPaletteModeColorPanel   = 4,
	NSColorListModeColorPanel       = 5,
	NSWheelModeColorPanel           = 6,
	NSCrayonModeColorPanel          = 7
};

enum
{
	NSGrayModeColorPanel,
	NSRGBModeColorPanel,
	NSCMYKModeColorPanel,
	NSHSBModeColorPanel,
	NSCustomPaletteModeColorPanel,
	NSColorListModeColorPanel,
	NSWheelModeColorPanel,
	NSCrayonModeColorPanel
};

@class NSView;
@class NSColorList;
@class NSColorWell;
@class NSEvent;
@class NSTabView;
@class NSSlider;
@class NSMatrix;
@class NSImageView;
@class NSTextField;

@interface NSColorPanel : NSPanel  <NSCoding>
{
	IBOutlet NSTabView *_colorTabs;
	IBOutlet NSColorWell *_colorWell;
	/* general */
	IBOutlet NSTextField *_html;
	IBOutlet NSTextField *_alpha;
	IBOutlet NSSlider *_alphaSlider;
	/* RGB panel */
	IBOutlet NSSlider *_redSlider;
	IBOutlet NSSlider *_greenSlider;
	IBOutlet NSSlider *_blueSlider;
	IBOutlet NSTextField *_red;
	IBOutlet NSTextField *_green;
	IBOutlet NSTextField *_blue;
	/* Crayons */
	IBOutlet NSMatrix *_crayons;
	/* Color Wheel */
	IBOutlet NSImageView *_colorWheel;
	IBOutlet NSSlider *_brightnessSlider;
	IBOutlet NSTextField *_brightness;
	/* */
	NSView *_accessoryView;
	NSColorList *_colorList;
	id _target;
	SEL _action;
	int _mode;
	BOOL _isContinuous;
	BOOL _showsAlpha;
}

+ (BOOL) dragColor:(NSColor *) aColor withEvent:(NSEvent *) anEvent fromView:(NSView *) sourceView;	// Color
+ (void) setPickerMask:(NSUInteger) mask;							// Configuration
+ (void) setPickerMode:(NSColorPanelMode) mode;
+ (NSColorPanel *) sharedColorPanel;						// shared instance
+ (BOOL) sharedColorPanelExists;

- (NSView *) accessoryView;
- (CGFloat) alpha;
- (void) attachColorList:(NSColorList *) aColorList;			// Color List
- (NSColor *) color;
- (void) detachColorList:(NSColorList *) aColorList;
- (BOOL) isContinuous;
- (NSColorPanelMode) mode;
- (void) setAccessoryView:(NSView *) aView;
- (void) setAction:(SEL) aSelector;
- (void) setColor:(NSColor *) aColor;
- (void) setContinuous:(BOOL) flag;
- (void) setMode:(NSColorPanelMode) mode;
- (void) setShowsAlpha:(BOOL) flag;
- (void) setTarget:(id) anObject;
- (BOOL) showsAlpha;

@end

@interface NSResponder (NSColorPanelDelegate)
- (void) changeColor:(id) sender;
@end

extern NSString *NSColorPanelColorChangedNotification;		// Notifications

#endif /* _mySTEP_H_NSColorPanel */
