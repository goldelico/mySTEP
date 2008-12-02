/*
	NSTextAttachment.h
 
	Classes to represent text attachments.
 
	NSTextAttachment is used to represent text attachments. When inline, 
	text attachments appear as the value of the NSAttachmentAttributeName 
	attached to the special character NSAttachmentCharacter.
 
	NSTextAttachment uses an object obeying the NSTextAttachmentCell 
	protocol to get input from the user and to display an image.
 
	NSTextAttachmentCell is a simple subclass of NSCell which provides 
	the NSTextAttachment protocol.
 
	Copyright (C) 1996 Free Software Foundation, Inc.
 
	Author: Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
	Date:	August 1998
 
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
#import <AppKit/NSCell.h>
#import <AppKit/NSStringDrawing.h>

@class NSFileWrapper;
@class NSTextAttachment;
@class NSLayoutManager;
@class NSTextContainer;
@class NSEvent;

enum
{
    NSAttachmentCharacter = 0xfffc	/* To denote attachments. */
};

/* 
These are the only methods required of cells in text attachments... 
The default NSCell class implements most of these; the NSTextAttachmentCell class is a subclass 
which implements all and provides some additional functionality. 
 */

@protocol NSTextAttachmentCell <NSObject>

- (NSTextAttachment *) attachment;
- (NSPoint) cellBaselineOffset;
- (NSRect) cellFrameForTextContainer:(NSTextContainer *) container
				proposedLineFragment:(NSRect) fragment
					   glyphPosition:(NSPoint) pos
					  characterIndex:(NSUInteger) index;
- (NSSize) cellSize;
- (void) drawWithFrame:(NSRect) cellFrame
				inView:(NSView *) controlView;
- (void) drawWithFrame:(NSRect) cellFrame
				inView:(NSView *) controlView
		characterIndex:(NSUInteger) index;
- (void) drawWithFrame:(NSRect) cellFrame
				inView:(NSView *) controlView
		characterIndex:(NSUInteger) index
		 layoutManager:(NSLayoutManager *) manager;
- (void) highlight:(BOOL) flag
		 withFrame:(NSRect) cellFrame
			inView:(NSView *) controlView;
- (void) setAttachment:(NSTextAttachment *) anObject;
- (BOOL) trackMouse:(NSEvent *) event 
			 inRect:(NSRect) cellFrame 
			 ofView:(NSView *) controlTextView 
   atCharacterIndex:(NSUInteger) index
	   untilMouseUp:(BOOL) flag;
- (BOOL) trackMouse:(NSEvent *) event 
			 inRect:(NSRect) cellFrame 
			 ofView:(NSView *) controlTextView 
	   untilMouseUp:(BOOL) flag;
- (BOOL) wantsToTrackMouse;
- (BOOL) wantsToTrackMouseForEvent:(NSEvent *) event
							inRect:(NSRect) rect
							ofView:(NSView *) controlView
				  atCharacterIndex:(NSUInteger) index;

@end

/* 

Simple class to provide basic attachment cell functionality. 
By default this class causes NSTextView to send out delegate messages 
when the attachment is clicked on or dragged. */

@interface NSTextAttachmentCell : NSCell <NSTextAttachmentCell> 
{
	NSTextAttachment *_attachment;
}
@end


@interface NSTextAttachment : NSObject  <NSCoding>
{
    NSFileWrapper *_fileWrapper;		// Model
    id <NSTextAttachmentCell> _cell;	// View
    struct {
        unsigned int cellWasExplicitlySet:1;
        unsigned int reserved:7;
    } _flags;
}

- (id <NSTextAttachmentCell>) attachmentCell;
- (NSFileWrapper *) fileWrapper;
- (id) initWithFileWrapper:(NSFileWrapper *) fileWrapper;
- (void) setAttachmentCell:(id <NSTextAttachmentCell>) cell;
- (void) setFileWrapper:(NSFileWrapper *) fileWrapper;

@end

/* 
Convenience for creating an attributed string with an attachment 
 */

@interface NSAttributedString (NSAttributedStringAttachmentConveniences)

+ (NSAttributedString *) attributedStringWithAttachment:(NSTextAttachment *) attachment;

@end

@interface NSMutableAttributedString (NSMutableAttributedStringAttachmentConveniences)

- (void) updateAttachmentsFromPath:(NSString *) path;

@end
