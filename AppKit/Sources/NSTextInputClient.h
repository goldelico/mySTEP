/*
	NSTextInputClient.h	
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Apr 15 2009.
	Copyright (c) 2005 DSITRI.

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSTextInputClient
#define _mySTEP_H_NSTextInputClient

// NOTE: there is some overlap with @protocl NSTextInput

@protocol NSTextInputClient

- (NSAttributedString *) attributedString;
- (NSAttributedString *) attributedSubstringForProposedRange:(NSRange) range actualRange:(NSRangePointer) actual;
- (CGFloat) baselineDeltaForCharacterAtIndex:(NSUInteger) idx;
- (NSUInteger) characterIndexForPoint:(NSPoint) point;
- (void) doCommandBySelector:(SEL) selector;
- (NSRect) firstRectForCharacterRange:(NSRange) range actualRange:(NSRangePointer) actual;
- (CGFloat) fractionOfDistanceThroughGlyphForPoint:(NSPoint) point;
- (BOOL) hasMarkedText;
- (void) insertText:(id) string replacementRange:(NSRange) range;
- (NSRange) markedRange;
- (NSRange) selectedRange;
- (void) setMarkedText:(id) string selectedRange:(NSRange) range replacementRange:(NSRange) repRange;
- (void) unmarkText;
- (NSArray *) validAttributesForMarkedText;
- (NSInteger) windowLevel;

@end

#endif /* _mySTEP_H_NSTextInputClient */
