/* 
   NSSearchField.h

   Secure Text field control class for data entry

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author: H. Nikolaus Schaller <hns@computer.org>
   Date: Dec 2004
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	05. December 2007 - aligned with 10.5   
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSSearchField
#define _mySTEP_H_NSSearchField

#import <AppKit/NSTextField.h>

@interface NSSearchField : NSTextField

- (NSString *) recentsAutosaveName;
- (NSArray *) recentSearches;
- (void) setRecentsAutosaveName:(NSString *) name;
- (void) setRecentSearches:(NSArray *) searches;

@end

#endif /* _mySTEP_H_NSSearchField */
