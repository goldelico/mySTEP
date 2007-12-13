/*
	NSTokenField.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	13. December 2007 - aligned with 10.5 
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTokenField
#define _mySTEP_H_NSTokenField

#import "AppKit/NSTextField.h"
#import "AppKit/NSTokenFieldCell.h"

@interface NSTokenField : NSTextField
{
}

+ (NSTimeInterval) defaultCompletionDelay; 
+ (NSCharacterSet *) defaultTokenizingCharacterSet; 

- (NSTimeInterval) completionDelay; 
- (void) setCompletionDelay:(NSTimeInterval) interval; 
- (void) setTokenizingCharacterSet:(NSCharacterSet *) charset; 
- (void) setTokenStyle:(NSTokenStyle) tokenStyle; 
- (NSCharacterSet *) tokenizingCharacterSet; 
- (NSTokenStyle) tokenStyle; 

@end

@interface NSTokenField (NSTokenFieldDelegate)

- (NSArray *) tokenField:(NSTokenField *) tokenField 
 completionsForSubstring:(NSString *) substr 
			indexOfToken:(NSInteger) tokenIdx 
	 indexOfSelectedItem:(NSInteger *) selectedIdx; 
- (NSString *) tokenField:(NSTokenField *) tokenField 
			   displayStringForRepresentedObject:(id) repObject; 
- (NSString *) tokenField:(NSTokenField *) tokenField 
			   editingStringForRepresentedObject:(id) repObject; 
- (BOOL) tokenField:(NSTokenField *) tokenField 
		 hasMenuForRepresentedObject:(id) repObject; 
- (NSMenu *) tokenField:(NSTokenField *) tokenField 
			 menuForRepresentedObject:(id) repObject; 
- (NSArray *) tokenField:(NSTokenField *) tokenField 
	  readFromPasteboard:(NSPasteboard *) pasteboard; 
- (id) tokenField:(NSTokenField *) tokenField 
	   representedObjectForEditingString:(NSString *) str; 
- (NSArray *) tokenField:(NSTokenField *) tokenField 
		shouldAddObjects:(NSArray *) objects 
				 atIndex:(NSUInteger) idx; 
- (NSTokenStyle) tokenField:(NSTokenField *) tokenField 
  styleForRepresentedObject:(id) repObject; 
- (BOOL) tokenField:(NSTokenField *) tokenField 
		 writeRepresentedObjects:(NSArray *) repObjects 
	   toPasteboard:(NSPasteboard *) pasteboard; 

@end

#endif /* _mySTEP_H_NSTokenField */
