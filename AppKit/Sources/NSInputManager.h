//
//  NSInputManager.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//	Author:	H. N. Schaller <hns@computer.org>
//	Date:	Jun 2006 - aligned with 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSInputManager
#define _mySTEP_H_NSInputManager

#import "AppKit/NSController.h"

@protocol NSTextInput

- (NSAttributedString *) attributedSubstringFromRange:(NSRange) range;
- (unsigned int) characterIndexForPoint:(NSPoint) point;
- (long) conversationIdentifier;
- (void) doCommandBySelector:(SEL) selector;
- (NSRect) firstRectForCharacterRange:(NSRange) range;
- (BOOL) hasMarkedText;
- (void) insertText:(id) string;
- (NSRange) markedRange;
- (NSRange) selectedRange;
- (void) setMarkedText:(id) string selectedRange:(NSRange) range;
- (void) unmarkText;
- (NSArray *) validAttributesForMarkedText;

@end

@interface NSInputManager : NSObject <NSTextInput>
{
}

@end

#endif /* _mySTEP_H_NSInputManager */
