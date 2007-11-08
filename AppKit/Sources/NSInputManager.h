/*
	NSInputManager.h	
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.

	Author:	H. N. Schaller <hns@computer.org>
	Date:	Jun 2006 - aligned with 10.4
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	8. November 2007 - aligned with 10.5  

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSInputManager
#define _mySTEP_H_NSInputManager

#import "AppKit/NSController.h"

@class NSInputServer;

@protocol NSTextInput

- (NSAttributedString *) attributedSubstringFromRange:(NSRange) range;
- (NSUInteger) characterIndexForPoint:(NSPoint) point;
- (NSInteger) conversationIdentifier;
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

+ (NSInputManager *) currentInputManager;
+ (void) cycleToNextInputLanguage:(id) sender; // deprecated
+ (void) cycleToNextInputServerInLanguage:(id) sender; // deprecated

- (BOOL) handleMouseEvent:(NSEvent *) event;
- (NSImage *) image; // deprecated
- (NSInputManager *) initWithName:(NSString *)name host:(NSString *) host; 
- (NSString *) language; 
- (NSString *) localizedInputManagerName; 
- (void) markedTextAbandoned:(id) cli; 
- (void) markedTextSelectionChanged:(NSRange) sel client:(id) cli; 
- (NSInputServer *) server; // deprecated
- (BOOL) wantsToDelayTextChangeNotifications; 
- (BOOL) wantsToHandleMouseEvents; 
- (BOOL) wantsToInterpretAllKeystrokes; 

@end

#endif /* _mySTEP_H_NSInputManager */
