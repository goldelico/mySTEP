/* 
   NSFontPanel.h

   Standard panel for selecting and previewing fonts.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Oct 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSFontPanel
#define _mySTEP_H_NSFontPanel

#import <AppKit/NSPanel.h>

@class NSFont;
@class NSView;
@class NSBrowser;
@class NSSearchField;
@class NSPopUpButton;
@class NSComboBox;
@class NSStepper;

enum {
	NSFPPreviewButton,
	NSFPRevertButton,
	NSFPSetButton,
	NSFPPreviewField,
	NSFPSizeField,
	NSFPSizeTitle,
	NSFPCurrentField
};

@interface NSFontPanel : NSPanel <NSCoding>
{
	NSFont *_panelFont;
	NSView *_accessoryView;
	IBOutlet NSPopUpButton *systemFontSelector;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSComboBox *sizeSelector;
	IBOutlet NSStepper *sizeStepper;
	IBOutlet NSBrowser *browser;
	NSArray *families;	// after filtering by search field
}

- (IBAction) _selectSystemFont:(id) sender;
- (IBAction) _searchFont:(id) sender;
- (IBAction) _selectSize:(id) sender;
- (IBAction) _stepperAction:(id) sender;
- (IBAction) _singleClick:(id) sender;

+ (NSFontPanel *) sharedFontPanel;
+ (BOOL) sharedFontPanelExists;

- (NSView *) accessoryView;
- (BOOL) isEnabled;
- (NSFont *) panelConvertFont:(NSFont *) fontObject;
- (void) reloadDefaultFontFamilies;
- (void) setAccessoryView:(NSView *) aView;
- (void) setEnabled:(BOOL) flag;
- (void) setPanelFont:(NSFont *) fontObject isMultiple:(BOOL) flag;
- (BOOL) worksWhenModal;

@end

enum
{
	NSFontPanelFaceModeMask = 1 << 0,
	NSFontPanelSizeModeMask = 1 << 1,
	NSFontPanelCollectionModeMask = 1 << 2,
	NSFontPanelUnderlineEffectModeMask = 1<<8,
	NSFontPanelStrikethroughEffectModeMask = 1<<9,
	NSFontPanelTextColorEffectModeMask = 1<< 10,
	NSFontPanelDocumentColorEffectModeMask = 1<<11,
	NSFontPanelShadowEffectModeMask = 1<<12,
	NSFontPanelAllEffectsModeMask = 0xfff00,
	NSFontPanelStandardModesMask = 0xffff,
	NSFontPanelAllModesMask = 0xffffffff
};

// ?? who is the delegate providing this method to shape which elements are visible ??

@protocol NSFontPanelValidation

- (unsigned int) validModesForFontPanel:(NSFontPanel *) fontPanel;

@end

#endif /* _mySTEP_H_NSFontPanel */
