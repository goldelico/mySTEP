/*
	NSTextStorage.h

	NSTextStorage is a semi-abstract subclass of NSMutableAttributedString. It
	implements change management (beginEditing/endEditing), verification of
	attributes, delegate handling, and layout management notification. The one
	aspect it does not implement is the actual attributed string storage ---
	this is left up to the subclassers, which need to override the two
	NSMutableAttributedString primitives:

	- (void) replaceCharactersInRange:(NSRange)range  withString:(NSString *)str;
	- (void) setAttributes:(NSDictionary *)attrs range:(NSRange)range;

	These primitives should perform the change then call
	edited:range:changeInLength: to get everything else to happen.

	Copyright (C) 1996 Free Software Foundation, Inc.

	Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
	Date: August 1998

	Source by Daniel Bðhringer integrated into mySTEP gui
	by Felipe A. Rodriguez <far@ix.netcom.com>

	Author:	H. N. Schaller <hns@computer.org>
	Date:	Jun 2006 - aligned with 10.4

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	12. December 2007 - aligned with 10.5

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import <AppKit/NSStringDrawing.h>

@class NSColor;
@class NSFont;
@class NSLayoutManager;

enum
{
	NSTextStorageEditedAttributes = 1,
	NSTextStorageEditedCharacters = 2
};

@interface NSTextStorage : NSMutableAttributedString
{
#if __APPLE__
	NSMutableAttributedString *_concreteString;	// we are a semiconcrete subclass of a class cluster...
#endif
	NSMutableArray *_layoutManagers;
	id _delegate;
	NSRange _editedRange;
	NSRange _invalidatedRange;
	NSUInteger _editedMask;
	NSUInteger _changeInLength;
	NSUInteger _nestingCount;
	BOOL _fixesAttributesLazily;
}

- (void) addLayoutManager:(NSLayoutManager *) obj;
- (NSInteger) changeInLength;
- (id) delegate;
- (void) edited:(NSUInteger) editedMask
		  range:(NSRange) range
 changeInLength:(NSInteger) delta;
- (NSUInteger) editedMask;
- (NSRange) editedRange;
- (void) ensureAttributesAreFixedInRange:(NSRange) range;
- (BOOL) fixesAttributesLazily;
- (void) invalidateAttributesInRange:(NSRange) range;
- (NSArray *) layoutManagers;
- (void) processEditing;
- (void) removeLayoutManager:(NSLayoutManager *) obj;
- (void) setDelegate:(id) delegate;

@end

@interface NSTextStorage (NSTextStorageScripting)

- (NSArray *) attributeRuns;
- (NSArray *) characters;
- (NSFont *) font;
- (NSColor *) foregroundColor;
- (NSArray *) paragraphs;
- (void) setAttributeRuns:(NSArray *) attributeRuns;
- (void) setCharacters:(NSArray *) characters;
- (void) setFont:(NSFont *) font;
- (void) setForegroundColor:(NSColor *) color;
- (void) setParagraphs:(NSArray *) paragraphs;
- (void) setWords:(NSArray *) words;
- (NSArray *) words;

@end

@interface NSObject (NSTextStorageDelegate)

- (void) textStorageDidProcessEditing:(NSNotification *) notification;	/* Delegate can change the attributes */
- (void) textStorageWillProcessEditing:(NSNotification *) notification;	/* Delegate can change the characters or attributes */

@end

extern NSString *NSTextStorageDidProcessEditingNotification;
extern NSString *NSTextStorageWillProcessEditingNotification;

// EOF
