/* 
   NSPrintInfo.h

   Stores information used in printing

   Copyright (C) 1996,1997 Free Software Foundation, Inc.

   Author:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: July 1997
   
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

+ (NSPrintInfo *) sharedPrintInfo;
+ (void) setSharedPrintInfo:(NSPrintInfo *)printInfo;

- (id) initWithDictionary:(NSDictionary *)aDict;

//
// Managing the Printing Rectangle 
//
+ (NSSize) sizeForPaperName:(NSString *)name;
- (float) bottomMargin;
- (float) leftMargin;
- (NSPrintingOrientation) orientation;
- (NSString *) paperName;
- (NSSize) paperSize;
- (float) rightMargin;
- (void) setBottomMargin:(float)value;
- (void) setLeftMargin:(float)value;
- (void) setOrientation:(NSPrintingOrientation)mode;
- (void) setPaperName:(NSString *)name;
- (void) setPaperSize:(NSSize)size;
- (void) setRightMargin:(float)value;
- (void) setTopMargin:(float)value;
- (float)topMargin;

//
// Pagination 
//
- (NSPrintingPaginationMode) horizontalPagination;
- (void) setHorizontalPagination:(NSPrintingPaginationMode)mode;
- (void) setVerticalPagination:(NSPrintingPaginationMode)mode;
- (NSPrintingPaginationMode) verticalPagination;

//
// Positioning the Image on the Page 
//
- (BOOL) isHorizontallyCentered;
- (BOOL) isVerticallyCentered;
- (void) setHorizontallyCentered:(BOOL)flag;
- (void) setVerticallyCentered:(BOOL)flag;

//
// Specifying the Printer 
//
+ (NSPrinter*) defaultPrinter;
+ (void) setDefaultPrinter:(NSPrinter *)printer;
- (NSPrinter*) printer;
- (void) setPrinter:(NSPrinter *)aPrinter;

//
// Controlling Printing
//
- (NSString*) jobDisposition;
- (void) setJobDisposition:(NSString *)disposition;
- (void) setUpPrintOperationDefaultValues;

//
// Accessing the NSPrintInfo Object's Dictionary 
//
- (NSMutableDictionary*) dictionary;

@end

//
// Printing Information Dictionary Keys 
//
extern NSString *NSPrintAllPages;
extern NSString *NSPrintBottomMargin;
extern NSString *NSPrintCopies;
extern NSString *NSPrintFaxCoverSheetName;
extern NSString *NSPrintFaxHighResolution;
extern NSString *NSPrintFaxModem;
extern NSString *NSPrintFaxReceiverNames;
extern NSString *NSPrintFaxReceiverNumbers;
extern NSString *NSPrintFaxReturnReceipt;
extern NSString *NSPrintFaxSendTime;
extern NSString *NSPrintFaxTrimPageEnds;
extern NSString *NSPrintFaxUseCoverSheet;
extern NSString *NSPrintFirstPage;
extern NSString *NSPrintHorizontalPagination;
extern NSString *NSPrintHorizontallyCentered;
extern NSString *NSPrintJobDisposition;
extern NSString *NSPrintJobFeatures;
extern NSString *NSPrintLastPage;
extern NSString *NSPrintLeftMargin;
extern NSString *NSPrintManualFeed;
extern NSString *NSPrintOrientation;
extern NSString *NSPrintPackageException;
extern NSString *NSPrintPagesPerSheet;
extern NSString *NSPrintPaperFeed;
extern NSString *NSPrintPaperName;
extern NSString *NSPrintPaperSize;
extern NSString *NSPrintPrinter;
extern NSString *NSPrintReversePageOrder;
extern NSString *NSPrintRightMargin;
extern NSString *NSPrintSavePath;
extern NSString *NSPrintScalingFactor;
extern NSString *NSPrintTopMargin;
extern NSString *NSPrintVerticalPagination;
extern NSString *NSPrintVerticallyCentered;

//
// Print Job Disposition Values 
//
extern NSString *NSPrintCancelJob;
extern NSString *NSPrintFaxJob;
extern NSString *NSPrintPreviewJob;
extern NSString *NSPrintSaveJob;
extern NSString *NSPrintSpoolJob;

#endif /* _mySTEP_H_NSPrintInfo */
