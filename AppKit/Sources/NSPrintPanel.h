/* 
   NSPrintPanel.h

   Standard panel to query users for info on a print job

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	03. December 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPrintPanel
#define _mySTEP_H_NSPrintPanel

#import <Foundation/NSObject.h>

@class NSView, NSWindow, NSViewController;

extern NSString *NSPrintPanelAccessorySummaryItemNameKey;
extern NSString *NSPrintPanelAccessorySummaryItemDescriptionKey;

@protocol NSPrintPanelAccessorizing
- (NSSet *) keyPathsForValuesAffectingPreview;
- (NSArray *) localizedSummaryItems;
@end

/* NOT IN API - OpenSTEP? */

enum {
	NSPPSaveButton,
	NSPPPreviewButton,
	NSFaxButton,
	NSPPTitleField,
	NSPPImageButton,
	NSPPNameTitle,
	NSPPNameField,
	NSPPNoteTitle,
	NSPPNoteField,
	NSPPStatusTitle,
	NSPPStatusField,
	NSPPCopiesField,
	NSPPPageChoiceMatrix,
	NSPPPageRangeFrom,
	NSPPPageRangeTo,
	NSPPScaleField,
	NSPPOptionsButton,
	NSPPPaperFeedButton,
	NSPPLayoutButton
};

extern NSString *NSPrintPhotoJobStyleHint;

enum {
	NSPrintPanelShowsCopies = 0x01,
	NSPrintPanelShowsPageRange = 0x02,
	NSPrintPanelShowsPaperSize = 0x04,
	NSPrintPanelShowsOrientation = 0x08,
	NSPrintPanelShowsScaling = 0x10,
	NSPrintPanelShowsPageSetupAccessory = 0x100,
	NSPrintPanelShowsPreview = 0x20000
};
typedef NSInteger NSPrintPanelOptions;

@interface NSPrintPanel : NSObject
{
	NSView *_accessoryView;
	NSString *_jobStyleHint;
	BOOL pdone;
	BOOL psuccess;
}

+ (NSPrintPanel *) printPanel; 

- (NSArray *) accessoryControllers; 
- (NSView *) accessoryView;
- (void) addAccessoryController:(NSViewController <NSPrintPanelAccessorizing> *) accessContr; 
- (void) beginSheetWithPrintInfo:(NSPrintInfo *) info 
				  modalForWindow:(NSWindow *) window 
						delegate:(id) delegate 
				  didEndSelector:(SEL) sel 
					 contextInfo:(void *) context;
- (NSString *) defaultButtonTitle; 
- (void) finalWritePrintInfo;
- (NSString *) helpAnchor; 
- (NSString *) jobStyleHint;
- (NSPrintPanelOptions) options; 
- (void) pickedAllPages:(id) sender; /* DEPRECATED */
- (void) pickedButton:(id) sender; /* DEPRECATED */
- (void) pickedLayoutList:(id) sender; /* DEPRECATED */
- (NSPrintInfo *) printInfo; 
- (void) removeAccessoryController:(NSViewController <NSPrintPanelAccessorizing> *) accessContr; 
- (NSInteger) runModal;
- (NSInteger) runModalWithPrintInfo:(NSPrintInfo *) info; 
- (void) setAccessoryView:(NSView *) aView; /* DEPRECATED */
- (void) setDefaultButtonTitle:(NSString *) title; 
- (void) setHelpAnchor:(NSString *) help; 
- (void) setJobStyleHint:(NSString *) hint;
- (void) setOptions:(NSPrintPanelOptions) opts; 
- (void) updateFromPrintInfo;

@end

#endif /* _mySTEP_H_NSPrintPanel */
