/*
	NSTokenFieldCell.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	13. December 2007 - aligned with 10.5  
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTokenFieldCell
#define _mySTEP_H_NSTokenFieldCell

#import "AppKit/NSTextFieldCell.h"

typedef NSUInteger NSTokenStyle;

enum
{
	NSDefaultTokenStyle,
	NSPlainTextTokenStyle,
	NSRoundedTokenStyle
};

@interface NSTokenFieldCell : NSTextFieldCell
{
	NSCharacterSet *_tokenizingCharacterSet;
	NSTimeInterval _completionDelay;
	NSTokenStyle _tokenStyle;
}

+ (NSTimeInterval) defaultCompletionDelay;
+ (NSCharacterSet *) defaultTokenizingCharacterSet;

- (NSTimeInterval) completionDelay;
- (id) delegate;
- (void) setCompletionDelay:(NSTimeInterval) delay;
- (void) setDelegate:(id) obj;
- (void) setTokenizingCharacterSet:(NSCharacterSet *) set;
- (void) setTokenStyle:(NSTokenStyle) style;
- (NSCharacterSet *) tokenizingCharacterSet;
- (NSTokenStyle) tokenStyle;

@end

@interface NSObject (NSTokenFieldDelegate)

- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell 
	 completionsForSubstring:(NSString *) substring 
				indexOfToken:(NSInteger) index 
		 indexOfSelectedItem:(NSInteger *) selected;
- (NSString *) tokenFieldCell:(NSTokenFieldCell *) cell 
			   displayStringForRepresentedObject:(id) obj;
- (NSString *) tokenFieldCell:(NSTokenFieldCell *) cell 
			   editingStringForRepresentedObject:(id) obj;
- (BOOL) tokenFieldCell:(NSTokenFieldCell *) cell 
		 hasMenuForRepresentedObject:(id) obj;
- (NSMenu *) tokenFieldCell:(NSTokenFieldCell *) cell 
			 menuForRepresentedObject:(id) obj;
- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell 
			  readFromPasteboard:(NSPasteboard *) pboard;
- (id) tokenFieldCell:(NSTokenFieldCell *) cell 
	   representedObjectForEditingString:(NSString *) string;
- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell 
			shouldAddObjects:(NSArray *) tokens 
					 atIndex:(NSUInteger) index;
- (NSTokenStyle) tokenFieldCell:(NSTokenFieldCell *) cell 
	  styleForRepresentedObject:(id) obj;
- (BOOL) tokenFieldCell:(NSTokenFieldCell *) cell 
writeRepresentedObjects:(NSArray *) objects 
		   toPasteboard:(NSPasteboard *) pboard;

@end

#endif /* _mySTEP_H_NSTokenFieldCell */
