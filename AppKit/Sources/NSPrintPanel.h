/* 
   NSPrintPanel.h

   Standard panel to query users for info on a print job

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPrintPanel
#define _mySTEP_H_NSPrintPanel

#import <AppKit/NSPanel.h>

@class NSView;

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

@interface NSPrintPanel : NSObject
{
	NSView *_accessoryView;
	NSString *_jobStyleHint;
	BOOL done;
	BOOL success;
}

- (NSView *) accessoryView;
- (NSString *) jobStyleHint;
- (void) setAccessoryView:(NSView *)aView;				// Customize the Panel
- (void) setJobStyleHint:(NSString *)hint;

- (int) runModal;										// Run the Panel
- (void) beginSheetWithPrintInfo:(NSPrintInfo *) info modalForWindow:(NSWindow *) window delegate:(id) delegate didEndSelector:(SEL) sel contextInfo:(void *) context;

- (void) pickedButton:(id)sender;
- (void) pickedAllPages:(id)sender;						// Update Panel Display
- (void) pickedLayoutList:(id)sender;

- (void) updateFromPrintInfo;							// Communicate with the
- (void) finalWritePrintInfo;							// NSPrintInfo Object

@end

#endif /* _mySTEP_H_NSPrintPanel */
