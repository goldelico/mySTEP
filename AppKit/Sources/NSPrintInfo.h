/* 
   NSPrintInfo.h

   Stores information used in printing

   Copyright (C) 1996,1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: July 1997
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	03. December 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPrintInfo
#define _mySTEP_H_NSPrintInfo

#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>

@class NSString;
@class NSDictionary;
@class NSMutableDictionary;

@class NSPrinter;

typedef enum _NSPrintingOrientation {
	NSPortraitOrientation,
	NSLandscapeOrientation
} NSPrintingOrientation;

typedef enum _NSPrintingPaginationMode {
	NSAutoPagination,
	NSFitPagination,
	NSClipPagination
} NSPrintingPaginationMode;


@interface NSPrintInfo : NSObject  <NSCoding>
{
	NSMutableDictionary *info;
}

+ (NSPrinter *) defaultPrinter; /* DEPRECATED */
+ (void) setDefaultPrinter:(NSPrinter *) printer; /* DEPRECATED */
+ (void) setSharedPrintInfo:(NSPrintInfo *) printInfo;
+ (NSPrintInfo *) sharedPrintInfo;
+ (NSSize) sizeForPaperName:(NSString *) name; /* DEPRECATED */

- (CGFloat) bottomMargin;
- (NSMutableDictionary *) dictionary;
- (NSPrintingPaginationMode) horizontalPagination;
- (NSRect) imageablePageBounds; 
- (id) initWithDictionary:(NSDictionary *) aDict;
- (BOOL) isHorizontallyCentered;
- (BOOL) isVerticallyCentered;
- (NSString *) jobDisposition;
- (CGFloat) leftMargin;
- (NSString *) localizedPaperName; 
- (NSPrintingOrientation) orientation;
- (NSString *) paperName;
- (NSSize) paperSize;
- (void *) PMPageFormat;
- (void *) PMPrintSession; 
- (void *) PMPrintSettings; 
- (NSPrinter *) printer;
- (NSMutableDictionary *) printSettings; 
- (CGFloat) rightMargin;
- (void) setBottomMargin:(CGFloat) value;
- (void) setHorizontallyCentered:(BOOL) flag;
- (void) setHorizontalPagination:(NSPrintingPaginationMode) mode;
- (void) setJobDisposition:(NSString *) disposition;
- (void) setLeftMargin:(CGFloat) value;
- (void) setOrientation:(NSPrintingOrientation) mode;
- (void) setPaperName:(NSString *) name;
- (void) setPaperSize:(NSSize) size;
- (void) setPrinter:(NSPrinter *) aPrinter;
- (void) setRightMargin:(CGFloat) value;
- (void) setTopMargin:(CGFloat) value;
- (void) setUpPrintOperationDefaultValues;
- (void) setVerticallyCentered:(BOOL) flag;
- (void) setVerticalPagination:(NSPrintingPaginationMode) mode;
- (CGFloat) topMargin;
- (void) updateFromPMPageFormat; 
- (void) updateFromPMPrintSettings; 
- (NSPrintingPaginationMode) verticalPagination;

@end

//
// Printing Information Dictionary Keys 
//
extern NSString *NSPrintAllPages;
extern NSString *NSPrintCopies;
extern NSString *NSPrintFaxCoverSheetName; /* DEPRECATED */
extern NSString *NSPrintFaxHighResolution; /* DEPRECATED */
extern NSString *NSPrintFaxModem; /* DEPRECATED */
extern NSString *NSPrintFaxReceiverNames; /* DEPRECATED */
extern NSString *NSPrintFaxReceiverNumbers; /* DEPRECATED */
extern NSString *NSPrintFaxReturnReceipt; /* DEPRECATED */
extern NSString *NSPrintFaxSendTime; /* DEPRECATED */
extern NSString *NSPrintFaxTrimPageEnds; /* DEPRECATED */
extern NSString *NSPrintFaxUseCoverSheet; /* DEPRECATED */
extern NSString *NSPrintFirstPage;
extern NSString *NSPrintJobDisposition;
extern NSString *NSPrintJobFeatures; /* DEPRECATED */
extern NSString *NSPrintLastPage;
extern NSString *NSPrintManualFeed; /* DEPRECATED */
extern NSString *NSPrintPackageException;
extern NSString *NSPrintPagesPerSheet; /* DEPRECATED */
extern NSString *NSPrintPaperFeed; /* DEPRECATED */
extern NSString *NSPrintPrinter;
extern NSString *NSPrintReversePageOrder;
extern NSString *NSPrintSavePath;
extern NSString *NSPrintPagesAcross; 
extern NSString *NSPrintPagesDown; 
extern NSString *NSPrintTime; 
extern NSString *NSPrintDetailedErrorReporting; 
extern NSString *NSPrintFaxNumber; 
extern NSString *NSPrintPrinterName; 

extern NSString *NSPrintPaperName;
extern NSString *NSPrintPaperSize;
extern NSString *NSPrintOrientation;
extern NSString *NSPrintScalingFactor;

extern NSString *NSPrintLeftMargin;
extern NSString *NSPrintRightMargin;
extern NSString *NSPrintTopMargin;
extern NSString *NSPrintBottomMargin;
extern NSString *NSPrintHorizontallyCentered;
extern NSString *NSPrintVerticallyCentered;
extern NSString *NSPrintHorizontalPagination;
extern NSString *NSPrintVerticalPagination;

extern NSString *NSPrintCancelJob;
extern NSString *NSPrintFaxJob; /* DEPRECATED */
extern NSString *NSPrintPreviewJob;
extern NSString *NSPrintSaveJob;
extern NSString *NSPrintSpoolJob;

#endif /* _mySTEP_H_NSPrintInfo */
