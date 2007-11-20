/* 
   NSPageLayout.h

   Standard panel for querying user about page layout info

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	14. November 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPageLayout
#define _mySTEP_H_NSPageLayout

#import <AppKit/NSPanel.h>

@class NSPrintInfo;
@class NSView;
@class NSViewController; 

// ????
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

@interface NSPageLayout : NSObject
{
}

+ (NSPageLayout *) pageLayout;

- (NSArray *) accessoryControllers; 
- (NSView *) accessoryView; /* DEPRECATED */
- (void) addAccessoryController:(NSViewController *) accContr; 
- (void) beginSheetWithPrintInfo:(NSPrintInfo *) pInfo 
				  modalForWindow:(NSWindow *) window 
						delegate:(id) delegate 
				  didEndSelector:(SEL) sel 
					 contextInfo:(void *) context;
- (void) convertOldFactor:(float *) old /* DEPRECATED */
				newFactor:(float *) new;
- (void) pickedButton:(id) sender; /* DEPRECATED */
- (void) pickedOrientation:(id) sender; /* DEPRECATED */
- (void) pickedPaperSize:(id) sender; /* DEPRECATED */
- (void) pickedUnits:(id) sender; /* DEPRECATED */
- (NSPrintInfo *) printInfo;
- (void) readPrintInfo; /* DEPRECATED */
- (void) removeAccessoryController:(NSViewController *) accContr; 
- (NSInteger) runModal;
- (NSInteger) runModalWithPrintInfo:(NSPrintInfo *) pInfo;
- (void) setAccessoryView:(NSView *) aView;
- (void) writePrintInfo; /* DEPRECATED */

@end

#endif /* _mySTEP_H_NSPageLayout */
