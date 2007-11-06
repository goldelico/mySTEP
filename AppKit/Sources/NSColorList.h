/* 
   NSColorList.h

   Manage named lists of NSColors.

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

#ifndef _mySTEP_H_NSColorList
#define _mySTEP_H_NSColorList

#import <Foundation/NSCoder.h>

@class NSString;
@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSMutableDictionary;
@class NSColor;

@interface NSColorList : NSObject  <NSCoding>
{
	NSString *list_name;
	NSString *file_name;
	NSMutableDictionary *color_list;
	NSMutableArray *color_list_keys;
	BOOL is_editable;
}

+ (NSArray *) availableColorLists;							// all color lists
+ (NSColorList *) colorListNamed:(NSString *) name;			// Access by Name

- (NSArray *) allKeys;										// Colors by Key
- (NSColor *) colorWithKey:(NSString *) key;
- (id) initWithName:(NSString *) name;
- (id) initWithName:(NSString *) name fromFile:(NSString *) path;
- (void) insertColor:(NSColor *) color key:(NSString *) key atIndex:(NSUInteger) location;
- (BOOL) isEditable;
- (NSString *) name;
- (void) removeColorWithKey:(NSString *) key;
- (void) removeFile;
- (void) setColor:(NSColor *) aColor forKey:(NSString *) key;
- (BOOL) writeToFile:(NSString *) path;						// archive

@end

extern NSString *NSColorListChangedNotification;			// Notifications

extern NSString *NSColorListIOException;					// Exceptions
extern NSString *NSColorListNotEditableException;

#endif /* _mySTEP_H_NSColorList */
