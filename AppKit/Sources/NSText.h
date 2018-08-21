/* 
	NSText.h

	The text object

	Copyright (C) 1996 Free Software Foundation, Inc.

	Author: Scott Christley <scottc@net-community.com>
	Date:	1996

	Author: Felipe A. Rodriguez <far@ix.netcom.com>
	Date:	July 1998

	Author: Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
	Date:	August 1998
 
	Author:	H. N. Schaller <hns@computer.org>
	Date:	Jun 2006 - aligned with 10.4
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	12. December 2007 - aligned with 10.5 

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSText
#define _mySTEP_H_NSText

#import <Foundation/NSRange.h>

#import <AppKit/NSView.h>
#import <AppKit/NSSpellProtocol.h>
#import <AppKit/NSStringDrawing.h>

@class NSString;
@class NSData;
@class NSNotification;
@class NSMutableDictionary;
@class NSColor;
@class NSFont;
@class NSTextStorage;
@class NSAttributedString;

typedef enum _NSTextAlignment
{
	NSLeftTextAlignment			= 0,
	NSRightTextAlignment		= 1,
	NSCenterTextAlignment		= 2,
	NSJustifiedTextAlignment	= 3,
	NSNaturalTextAlignment		= 4
} NSTextAlignment;

enum _NSTextMovement
{
	NSIllegalTextMovement = 0x00,
	NSReturnTextMovement  = 0x10,
	NSTabTextMovement	  = 0x11,
	NSBacktabTextMovement = 0x12,
	NSLeftTextMovement	  = 0x13,
	NSRightTextMovement	  = 0x14,
	NSUpTextMovement	  = 0x15,
	NSDownTextMovement	  = 0x16,
	NSCancelTextMovement  = 0x17,
	NSOtherTextMovement   = 0x18
};	 	

typedef enum _NSWritingDirection
{
	NSWritingDirectionLeftToRight	= 0,
	NSWritingDirectionRightToLeft	= 1,
	NSWritingDirectionNatural		= -1,
} NSWritingDirection;

enum _NSCommonlyUsedUnicodeCharacters
{
	NSParagraphSeparatorCharacter	= 0x2029,
	NSLineSeparatorCharacter		= 0x2028,
	NSTabCharacter					= 0x0009,
	NSFormFeedCharacter				= 0x000c,
	NSNewlineCharacter				= 0x000a,
	NSCarriageReturnCharacter		= 0x000d,
	NSEnterCharacter				= 0x0003,
	NSBackspaceCharacter			= 0x0008,
	NSBackTabCharacter				= 0x0019,
	NSDeleteCharacter				= 0x007f 
}; 

@interface NSText : NSView <NSChangeSpelling, NSIgnoreMisspelledWords, NSCoding>
{											
	id _delegate;	// we are not a subclass of NSControl so we have to manage our own delegate!
	NSColor *_backgroundColor;
	NSFont *_font;	// insertion cursor font
	NSRange _selectedRange;		// current selection
	NSUInteger _anchor;		// for adding/removing selections
	NSTextStorage *textStorage;	// note: we don't provide direct accessors
//	NSMutableArray *lineLayoutInformation;	// one record for each line
//	NSMutableDictionary *typingAttributes; 
	NSInteger _spellCheckerDocumentTag;
	NSUInteger modifySelection[2];
	
	NSSize _minSize;
	NSSize _maxSize;
	NSWritingDirection _baseWritingDirection;

	struct __TextFlags {
		UIBITFIELD(unsigned int, isRichText, 1);
		UIBITFIELD(unsigned int, importsGraphics, 1);
		UIBITFIELD(unsigned int, usesFontPanel, 1);
		UIBITFIELD(unsigned int, horzResizable, 1);
		UIBITFIELD(unsigned int, vertResizable, 1);
		UIBITFIELD(unsigned int, editable, 1);
		UIBITFIELD(unsigned int, selectable, 1);
		UIBITFIELD(unsigned int, fieldEditor, 1);
		UIBITFIELD(unsigned int, drawsBackground, 1);
		UIBITFIELD(unsigned int, rulerVisible, 1);
		UIBITFIELD(unsigned int, secure, 1);	// used by NSSecureTextField
		TYPEDBITFIELD(NSTextAlignment, alignment, 3);
		UIBITFIELD(unsigned int, ownsTextStorage, 1);
		TYPEDBITFIELD(int, moveLeftRightEnd, 2);
		TYPEDBITFIELD(int, moveUpDownEnd, 2);
		UIBITFIELD(unsigned int, reserved, 14);
	} _tx;
}

- (void) alignCenter:(id) sender;
- (void) alignLeft:(id) sender;
- (NSTextAlignment) alignment;
- (void) alignRight:(id) sender;
- (NSColor *) backgroundColor;
- (NSWritingDirection) baseWritingDirection;
- (void) changeFont:(id) sender;
- (void) checkSpelling:(id) sender;						// Spelling
- (void) copy:(id) sender;
- (void) copyFont:(id) sender;
- (void) copyRuler:(id) sender;
- (void) cut:(id) sender;
- (id) delegate;
- (void) delete:(id) sender;
- (BOOL) drawsBackground;
- (NSFont *) font;
- (BOOL) importsGraphics;
- (BOOL) isEditable;
- (BOOL) isFieldEditor;
- (BOOL) isHorizontallyResizable;
- (BOOL) isRichText;
- (BOOL) isRulerVisible;								// Ruler
- (BOOL) isSelectable;
- (BOOL) isVerticallyResizable;
- (NSSize) maxSize;
- (NSSize) minSize;
- (void) paste:(id) sender;
- (void) pasteFont:(id) sender;
- (void) pasteRuler:(id) sender;
- (BOOL) readRTFDFromFile:(NSString *) path;
- (void) replaceCharactersInRange:(NSRange) range withRTF:(NSData *) rtfData;
- (void) replaceCharactersInRange:(NSRange) range withRTFD:(NSData *) rtfdData;
- (void) replaceCharactersInRange:(NSRange) range withString:(NSString *) aString;
- (NSData *) RTFDFromRange:(NSRange) range;
- (NSData *) RTFFromRange:(NSRange) range;
- (void) scrollRangeToVisible:(NSRange) range;			// Scrolling
- (void) selectAll:(id) sender;
- (NSRange) selectedRange;								// Selection
- (void) setAlignment:(NSTextAlignment) mode;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBaseWritingDirection:(NSWritingDirection) direct;
- (void) setDelegate:(id) anObject;						// Delegate
- (void) setDrawsBackground:(BOOL) flag;
- (void) setEditable:(BOOL) flag;
- (void) setFieldEditor:(BOOL) flag;						// Field Editor
- (void) setFont:(NSFont *) obj;
- (void) setFont:(NSFont *)font range:(NSRange) range;
- (void) setHorizontallyResizable:(BOOL) flag;
- (void) setImportsGraphics:(BOOL) flag;
- (void) setMaxSize:(NSSize) newMaxSize;
- (void) setMinSize:(NSSize) newMinSize;
- (void) setRichText:(BOOL) flag;
- (void) setSelectable:(BOOL) flag;
- (void) setSelectedRange:(NSRange) range;
- (void) setString:(NSString *) string;
- (void) setTextColor:(NSColor *) color;
- (void) setTextColor:(NSColor *) color range:(NSRange) range;
- (void) setUsesFontPanel:(BOOL) flag;
- (void) setVerticallyResizable:(BOOL) flag;
- (void) showGuessPanel:(id) sender;
- (void) sizeToFit;
- (NSString *) string;
- (void) subscript:(id) sender;
- (void) superscript:(id) sender;
- (NSColor *) textColor;
- (void) toggleRuler:(id) sender;
- (void) underline:(id) sender;
- (void) unscript:(id) sender;
- (BOOL) usesFontPanel;
- (BOOL) writeRTFDToFile:(NSString *) path atomically:(BOOL) flag;

@end

// Delegate methods

@interface NSObject (NSTextDelegate)

- (void) textDidBeginEditing:(NSNotification *) notification;
- (void) textDidChange:(NSNotification *) notification;
- (void) textDidEndEditing:(NSNotification *) notification;
- (BOOL) textShouldBeginEditing:(NSText *) textObject;
- (BOOL) textShouldEndEditing:(NSText *) textObject;

@end

// Notifications

extern NSString *NSTextDidBeginEditingNotification;
extern NSString *NSTextDidChangeNotification;
extern NSString *NSTextDidEndEditingNotification;
extern NSString *NSTextMovement;

#endif /* _mySTEP_H_NSText */
