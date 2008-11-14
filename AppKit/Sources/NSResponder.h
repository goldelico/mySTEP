/* 
   NSResponder.h

   Abstract base class of command and event processing

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jul 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	04. December 2007 - aligned with 10.5 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSResponder
#define _mySTEP_H_NSResponder

#import <Foundation/NSCoder.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSInterfaceStyle.h>
#import <AppKit/NSNibDeclarations.h>

@class NSError;
@class NSWindow;
@class NSString;
@class NSEvent;
@class NSMenu;
@class NSUndoManager;
@class NSArray;

@interface NSResponder : NSObject  <NSCoding>
{
	NSResponder *_nextResponder;
	NSMenu *_menu;
	NSInterfaceStyle _interfaceStyle;	// defaults to NSNoInterfaceStyle
}

- (BOOL) acceptsFirstResponder;								// First responder
- (BOOL) becomeFirstResponder;
- (void) cancelOperation:(id) sender;
- (void) capitalizeWord:(id) sender;
- (void) centerSelectionInVisibleArea:(id) sender;
- (void) changeCaseOfLetter:(id) sender;
- (void) complete:(id) sender;
- (void) cursorUpdate:(NSEvent *) evt;
- (void) deleteBackward:(id) sender;
- (void) deleteBackwardByDecomposingPreviousCharacter:(id) sender;
- (void) deleteForward:(id) sender;
- (void) deleteToBeginningOfLine:(id) sender;
- (void) deleteToBeginningOfParagraph:(id) sender;
- (void) deleteToEndOfLine:(id) sender;
- (void) deleteToEndOfParagraph:(id) sender;
- (void) deleteToMark:(id) sender;
- (void) deleteWordBackward:(id) sender;
- (void) deleteWordForward:(id) sender;
- (void) doCommandBySelector:(SEL) aSelector;
- (void) flagsChanged:(NSEvent *) event;						// Forward messages
- (void) flushBufferedKeyEvents;
- (unsigned long long) gestureEventMask;
- (void) helpRequested:(NSEvent *) event;
- (void) indent:(id) sender;
- (void) insertBacktab:(id) sender;
- (void) insertContainerBreak:(id) sender;	// NSTextView inserts 0x000c
- (void) insertLineBreak:(id) sender;		// NSTextView inserts 0x2028
- (void) insertNewline:(id) sender;
- (void) insertNewlineIgnoringFieldEditor:(id) sender;
- (void) insertParagraphSeparator:(id) sender;
- (void) insertTab:(id) sender;
- (void) insertTabIgnoringFieldEditor:(id) sender;
- (void) insertText:(id) aString;
- (NSInterfaceStyle) interfaceStyle;
- (void) interpretKeyEvents:(NSArray *) eventArray;
- (void) keyDown:(NSEvent *) event;
- (void) keyUp:(NSEvent *) event;
- (void) lowercaseWord:(id) sender;
- (NSMenu *) menu;
- (void) mouseDown:(NSEvent *) event;
- (void) mouseDragged:(NSEvent *) event;
- (void) mouseEntered:(NSEvent *) event;
- (void) mouseExited:(NSEvent *) event;
- (void) mouseMoved:(NSEvent *) event;
- (void) mouseUp:(NSEvent *) event;
- (void) moveBackward:(id) sender;
- (void) moveBackwardAndModifySelection:(id) sender;
- (void) moveDown:(id) sender;
- (void) moveDownAndModifySelection:(id) sender;
- (void) moveForward:(id) sender;
- (void) moveForwardAndModifySelection:(id) sender;
- (void) moveLeft:(id) sender;
- (void) moveLeftAndModifySelection:(id) sender;
- (void) moveRight:(id) sender;
- (void) moveRightAndModifySelection:(id) sender;
- (void) moveToBeginningOfDocument:(id) sender;
- (void) moveToBeginningOfLine:(id) sender;
- (void) moveToBeginningOfParagraph:(id) sender;
- (void) moveToEndOfDocument:(id) sender;
- (void) moveToEndOfLine:(id) sender;
- (void) moveToEndOfParagraph:(id) sender;
- (void) moveUp:(id) sender;
- (void) moveUpAndModifySelection:(id) sender;
- (void) moveWordBackward:(id) sender;
- (void) moveWordBackwardAndModifySelection:(id) sender;
- (void) moveWordForward:(id) sender;
- (void) moveWordForwardAndModifySelection:(id) sender;
- (void) moveWordLeft:(id) sender;
- (void) moveWordLeftAndModifySelection:(id) sender;
- (void) moveWordRight:(id) sender;
- (void) moveWordRightAndModifySelection:(id) sender;
- (NSResponder *) nextResponder;							// Next responder
- (void) noResponderFor:(SEL) eventSelector;
- (void) otherMouseDown:(NSEvent *) event;
- (void) otherMouseDragged:(NSEvent *) event;
- (void) otherMouseUp:(NSEvent *) event;
- (void) pageDown:(id) sender;
- (void) pageUp:(id) sender;
- (BOOL) performKeyEquivalent:(NSEvent *) event;				// Event processing
- (BOOL) performMnemonic:(NSString *) string;
- (BOOL) presentError:(NSError *) error;
- (void) presentError:(NSError *) error
	   modalForWindow:(NSWindow *) window
			 delegate:(id) delegate
   didPresentSelector:(SEL) sel
		  contextInfo:(void *) context;
- (BOOL) resignFirstResponder;
- (void) rightMouseDown:(NSEvent *) event;
- (void) rightMouseDragged:(NSEvent *) event;
- (void) rightMouseUp:(NSEvent *) event;
- (void) scrollLineDown:(id) sender;
- (void) scrollLineUp:(id) sender;
- (void) scrollPageDown:(id) sender;
- (void) scrollPageUp:(id) sender;
- (void) scrollWheel:(NSEvent *) event;
- (void) selectAll:(id) sender;
- (void) selectLine:(id) sender;
- (void) selectParagraph:(id) sender;
- (void) selectToMark:(id) sender;
- (void) selectWord:(id) sender;
- (void) setGestureEventMask:(unsigned long long) mask;
- (void) setInterfaceStyle:(NSInterfaceStyle) style;
- (void) setMark:(id) sender;
- (void) setMenu:(NSMenu *) aMenu;
- (void) setNextResponder:(NSResponder *) aResponder;
- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent;
- (void) showContextHelp:(id) sender;
- (void) swapWithMark:(id) sender;
- (void) tabletPoint:(NSEvent *) event;
- (void) tabletProximity:(NSEvent *) event;
- (void) transpose:(id) sender;
- (void) transposeWords:(id) sender;
- (BOOL) tryToPerform:(SEL) anAction with:(id) anObject;
- (NSUndoManager *) undoManager;
- (void) uppercaseWord:(id) sender;
- (id) validRequestorForSendType:(NSString *) typeSent		// Services menu
					  returnType:(NSString *) typeReturned;
- (NSError *) willPresentError:(NSError *) error;
- (void) yank:(id) sender;

// new gesture events as described by http://cocoadex.com/2008/02/nsevent-modifications-swipe-ro.html
- (void) magnifyWithEvent:(NSEvent *) event;
- (void) rotateWithEvent:(NSEvent *) event;
- (void) swipeWithEvent:(NSEvent *) event;
- (void) beginGestureWithEvent:(NSEvent *) event;
- (void) endGestureWithEvent:(NSEvent *) event;

@end

#endif /* _mySTEP_H_NSResponder */
