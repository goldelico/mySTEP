/* 
   NSPageLayout.h

   Standard panel for querying user about page layout info

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPageLayout
#define _mySTEP_H_NSPageLayout

#import <AppKit/NSPanel.h>

@class NSPrintInfo;
@class NSView;

enum {
  NSPLImageButton,
  NSPLTitleField,
  NSPLPaperNameButton,
  NSPLUnitsButton,
  NSPLWidthForm,
  NSPLHeightForm,
  NSPLOrientationMatrix,
  NSPLCancelButton,
  NSPLOKButton 
};

// FIXME: should be NSObject and have no NSCoding!

@interface NSPageLayout : NSPanel  <NSCoding>
{
}

+ (NSPageLayout *) pageLayout;

- (int) runModal;											// Run the Panel
- (int) runModalWithPrintInfo:(NSPrintInfo *)pInfo;

- (NSView *) accessoryView;									// Customize Panel
- (void) setAccessoryView:(NSView *)aView;

//
// Updating the Panel's Display 
//
- (void)convertOldFactor:(float *)old
	       newFactor:(float *)new;
- (void)pickedButton:(id)sender;
- (void)pickedOrientation:(id)sender;
- (void)pickedPaperSize:(id)sender;
- (void)pickedUnits:(id)sender;

//
// Communicating with the NSPrintInfo Object 
//
- (NSPrintInfo *) printInfo;
- (void) readPrintInfo;
- (void) writePrintInfo;

@end

#endif /* _mySTEP_H_NSPageLayout */
