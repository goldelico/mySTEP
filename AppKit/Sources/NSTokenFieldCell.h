//
//  NSTokenFieldCell.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSTokenFieldCell
#define _mySTEP_H_NSTokenFieldCell

#import "AppKit/NSTextFieldCell.h"

typedef enum _NSTokenStyle
{
	NSDefaultTokenStyle,
	NSPlainTextTokenStyle,
	NSRoundedTokenStyle
} NSTokenStyle;

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

- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell completionsForSubstring:(NSString *) substring indexOfToken:(int) index indexOfSelectedItem:(int *) selected;
- (NSString *) tokenFieldCell:(NSTokenFieldCell *) cell displayStringForRepresentedObject:(id) obj;
- (NSString *) tokenFieldCell:(NSTokenFieldCell *) cell editingStringForRepresentedObject:(id) obj;
- (BOOL) tokenFieldCell:(NSTokenFieldCell *) cell hasMenuForRepresentedObject:(id) obj;
- (NSMenu *) tokenFieldCell:(NSTokenFieldCell *) cell menuForRepresentedObject:(id) obj;
- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell readFromPasteboard:(NSPasteboard *) pboard;
- (id) tokenFieldCell:(NSTokenFieldCell *) cell representedObjectForEditingString:(NSString *) string;
- (NSArray *) tokenFieldCell:(NSTokenFieldCell *) cell shouldAddObjects:(NSArray *) tokens atIndex:(unsigned) index;
- (NSTokenStyle) tokenFieldCell:(NSTokenFieldCell *) cell styleForRepresentedObject:(id) obj;
- (BOOL) tokenFieldCell:(NSTokenFieldCell *) cell writeRepresentedObjects:(NSArray *) objects toPasteboard:(NSPasteboard *) pboard;

@end

#endif /* _mySTEP_H_NSTokenFieldCell */
