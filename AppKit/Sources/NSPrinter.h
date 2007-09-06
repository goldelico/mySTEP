/* 
   NSPrinter.h

   Class representing a printer's or printer model's capabilities.

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Authors:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: June 1997
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPrinter
#define _mySTEP_H_NSPrinter

#import <Foundation/NSCoder.h>
#import <Foundation/NSGeometry.h>

@class NSString;
@class NSArray;
@class NSDictionary;
@class NSMutableDictionary;

typedef enum _NSPrinterTableStatus {
	NSPrinterTableOK,
	NSPrinterTableNotFound,
	NSPrinterTableError
} NSPrinterTableStatus;

@interface NSPrinter : NSObject  <NSCoding>
{
	NSString *printerHost, *printerName, *printerNote, *printerType;
	int cacheAcceptsBinary, cacheOutputOrder;
	BOOL isRealPrinter;
}

+ (NSPrinter *) printerWithName:(NSString *)name;		// Find a printer
+ (NSPrinter *) printerWithType:(NSString *)type;
+ (NSArray *) printerNames;
+ (NSArray *) printerTypes;

- (NSString *) host;									// Printer Attributes
- (NSString *) name;
- (NSString *) note;
- (NSString *) type;

- (NSRect) imageRectForPaper:(NSString *)paperName;
- (NSSize) pageSizeForPaper:(NSString *)paperName;
- (BOOL) acceptsBinary;
- (BOOL) isColor;
- (BOOL) isFontAvailable:(NSString *)fontName;
- (BOOL) isOutputStackInReverseOrder;
- (int) languageLevel;
													// Query NSPrinter Tables 
- (BOOL)booleanForKey:(NSString *)key inTable:(NSString *)table;
- (NSDictionary *)deviceDescription;
- (float)floatForKey:(NSString *)key inTable:(NSString *)table;
- (int)intForKey:(NSString *)key inTable:(NSString *)table;
- (NSRect)rectForKey:(NSString *)key inTable:(NSString *)table;
- (NSSize)sizeForKey:(NSString *)key  inTable:(NSString *)table;
- (NSString *)stringForKey:(NSString *)key inTable:(NSString *)table;
- (NSArray *)stringListForKey:(NSString *)key inTable:(NSString *)table;
- (NSPrinterTableStatus)statusForTable:(NSString *)table;
- (BOOL)isKey:(NSString *)key inTable:(NSString *)table;

@end

#endif /* _mySTEP_H_NSPrinter */
