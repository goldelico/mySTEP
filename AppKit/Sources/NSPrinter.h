/* 
   NSPrinter.h

   Class representing a printer's or printer model's capabilities.

   Copyright (C) 1996, 1997 Free Software Foundation, Inc.

   Authors:  Simon Frankau <sgf@frankau.demon.co.uk>
   Date: June 1997
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	03. December 2007 - aligned with 10.5 
   
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

+ (NSArray *) printerNames;
+ (NSArray *) printerTypes;
+ (NSPrinter *) printerWithName:(NSString *) name;
+ (NSPrinter *) printerWithName:(NSString *) name 
						 domain:(NSString *) domain 
			 includeUnavailable:(BOOL) flag;
+ (NSPrinter *) printerWithType:(NSString *) type;

- (BOOL) acceptsBinary;
- (BOOL) booleanForKey:(NSString *) key inTable:(NSString *) table;
- (NSDictionary *) deviceDescription;
- (NSString *) domain; 
- (float) floatForKey:(NSString *) key inTable:(NSString *) table;
- (NSString *) host;
- (NSRect) imageRectForPaper:(NSString *) paperName;
- (int) intForKey:(NSString *) key inTable:(NSString *) table;
- (BOOL) isColor; /* DEPRECATED */
- (BOOL) isFontAvailable:(NSString *) fontName; /* DEPRECATED */
- (BOOL) isKey:(NSString *) key inTable:(NSString *) table;
- (BOOL) isOutputStackInReverseOrder; /* DEPRECATED */
- (NSInteger) languageLevel;
- (NSString *) name;
- (NSString *) note; /* DEPRECATED */
- (NSSize) pageSizeForPaper:(NSString *) paperName;
- (NSRect) rectForKey:(NSString *) key inTable:(NSString *) table;
- (NSSize) sizeForKey:(NSString *) key  inTable:(NSString *) table;
- (NSPrinterTableStatus) statusForTable:(NSString *) table;
- (NSString *) stringForKey:(NSString *) key inTable:(NSString *) table;
- (NSArray *) stringListForKey:(NSString *) key inTable:(NSString *) table;
- (NSString *) type;

@end

#endif /* _mySTEP_H_NSPrinter */
