/* 
   NSAttributedString.h

   AppKit extensions to NSAttributedString

   Copyright (C) 2001 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    Oct 2001
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	19. October 2007 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSAttributedStringAdditions
#define _mySTEP_H_NSAttributedStringAdditions

#import <Foundation/NSAttributedString.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSText.h>
#import <AppKit/NSParagraphStyle.h>

@class NSFileWrapper, NSError, NSTextBlock, NSTextList, NSTextTable;

enum _NSUnderlineStyle
{
	NSUnderlineStyleNone		= 0x00,
	NSUnderlineStyleSingle		= 0x01,
	NSUnderlineStyleThick		= 0x02,
	NSUnderlineStyleDouble		= 0x09
};

enum _NSUnderlinePattern
{
	NSUnderlinePatternSolid			= 0x0000,
	NSUnderlinePatternDot			= 0x0100,
	NSUnderlinePatternDash			= 0x0200,
	NSUnderlinePatternDashDot		= 0x0300,
	NSUnderlinePatternDashDotDot	= 0x0400
};

// global NSString attribute names used in ascessing  
// the respective property in a text attributes 
// dictionary.  If the key is not in the dictionary 	
// a default value is assumed 

extern NSString *NSAttachmentAttributeName;         // NSTextAttachment, nil	 
extern NSString *NSBackgroundColorAttributeName;	// NSColor, nil	
extern NSString *NSBaselineOffsetAttributeName;  	// NSNumber float, 0 points 
extern NSString *NSCursorAttributeName;
extern NSString *NSExpansionAttributeName;
extern NSString *NSFontAttributeName;    			// NSFont, Helvetica 12
extern NSString *NSForegroundColorAttributeName; 	// NSColor, blackColor
extern NSString *NSKernAttributeName;				// NSNumber float, 0
extern NSString *NSLigatureAttributeName;			// NSNumber int, 1 
extern NSString *NSLinkAttributeName;
extern NSString *NSObliquenessAttributeName;
extern NSString *NSParagraphStyleAttributeName;	 	// defaultParagraphStyle
extern NSString *NSShadowAttributeName;
extern NSString *NSStrikethroughColorAttributeName;
extern NSString *NSStrikethroughStyleAttributeName;
extern NSString *NSStrokeColorAttributeName;
extern NSString *NSStrokeWidthAttributeName;
extern NSString *NSSuperscriptAttributeName;      	// NSNumber int, 0		 
extern NSString *NSToolTipAttributeName;
extern NSString *NSUnderlineColorAttributeName;
extern NSString *NSUnderlineStyleAttributeName;   	// NSNumber int, 0 no line 	 

enum // FIXME: this enum is DEPRECATED since 10.3
{
	NSNoUnderlineStyle,
    NSSingleUnderlineStyle = 1,				// NSUnderlineStyleAttributeName
	NSUnderlineStrikethroughMask
};

// for generic import

extern NSString *NSPaperSizeDocumentAttribute;
extern NSString *NSLeftMarginDocumentAttribute;
extern NSString *NSRightMarginDocumentAttribute;
extern NSString *NSTopMarginDocumentAttribute;
extern NSString *NSBottomMarginDocumentAttribute;
extern NSString *NSHyphenationFactorDocumentAttribute;
extern NSString *NSDocumentTypeDocumentAttribute;
extern NSString *NSCharacterEncodingDocumentAttribute;
extern NSString *NSViewSizeDocumentAttribute;
extern NSString *NSViewZoomDocumentAttribute;
extern NSString *NSViewModeDocumentAttribute;
extern NSString *NSBackgroundColorDocumentAttribute;
extern NSString *NSCocoaVersionDocumentAttribute;
extern NSString *NSReadOnlyDocumentAttribute;
extern NSString *NSConvertedDocumentAttribute;
extern NSString *NSDefaultTabIntervalDocumentAttribute;
extern NSString *NSTitleDocumentAttribute;
extern NSString *NSCompanyDocumentAttribute;
extern NSString *NSCopyrightDocumentAttribute;
extern NSString *NSSubjectDocumentAttribute;
extern NSString *NSAuthorDocumentAttribute;
extern NSString *NSKeywordsDocumentAttribute;
extern NSString *NSCommentDocumentAttribute;
extern NSString *NSEditorDocumentAttribute;
extern NSString *NSCreationTimeDocumentAttribute;
extern NSString *NSModificationTimeDocumentAttribute;

// DocumentType values

extern NSString *NSPlainTextDocumentType;
extern NSString *NSRTFTextDocumentType;
extern NSString *NSRTFDTextDocumentType;
extern NSString *NSMacSimpleTextDocumentType;
extern NSString *NSHTMLTextDocumentType;
extern NSString *NSDocFormatTextDocumentType;
extern NSString *NSWordMLTextDocumentType;

// for HTML export

extern NSString *NSExcludedElementsDocumentAttribute;
extern NSString *NSTextEncodingNameDocumentAttribute;
extern NSString *NSPrefixSpacesDocumentAttribute;

// for HTML import

extern NSString *NSBaseURLDocumentOption;
extern NSString *NSCharacterEncodingDocumentOption;
extern NSString *NSDefaultAttributesDocumentOption;
extern NSString *NSDocumentTypeDocumentOption;
extern NSString *NSTextEncodingNameDocumentOption;
extern NSString *NSTextSizeMultiplierDocumentOption;
extern NSString *NSTimeoutDocumentOption;
extern NSString *NSWebPreferencesDocumentOption;
extern NSString *NSWebResourceLoadDelegateDocumentOption;

// special attributes

extern NSString *NSCharacterShapeAttributeName;
extern NSString *NSGlyphInfoAttributeName;

extern const unsigned NSUnderlineByWordMask;

// RTF/D init methods return a dictionary by ref describing doc
// attributes if dict param is not NULL.

// RTF/D create methods can take an optional dict describing doc wide 
// attributes to write out.  Current attributes are @"PaperSize", 
// @"LeftMargin", @"RightMargin", @"TopMargin", @"BottomMargin", and 
// @"HyphenationFactor".  
// First of these is an NSSize (NSValue) others are floats (NSNumber). 

@interface NSAttributedString (NSAttributedStringAdditions)

//+ (NSAttributedString *) attributedStringWithAttachment:(NSTextAttachment *)attach; // Problem, parse error
+ (NSArray *) textFileTypes;
+ (NSArray *) textPasteboardTypes;
+ (NSArray *) textUnfilteredFileTypes;
+ (NSArray *) textUnfilteredPasteboardTypes;

- (NSRect)boundingRectWithSize:(NSSize)size options:(NSStringDrawingOptions)opts;
- (BOOL) containsAttachments;
- (NSData *) dataFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs error:(NSError **) error;
- (NSData *) docFormatFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs;
- (NSRange) doubleClickAtIndex:(unsigned) location;
- (void)drawAtPoint:(NSPoint) pt;
- (void)drawInRect:(NSRect) rect;
- (void)drawWithRect:(NSRect) rect options:(NSStringDrawingOptions) opts;
- (NSFileWrapper *) fileWrapperFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs error:(NSError **) error;
- (NSDictionary *) fontAttributesInRange:(NSRange) range;	// filter attribs
- (id) initWithData:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
- (id) initWithDocFormat:(NSData *) data documentAttributes:(NSDictionary **) attrs;
- (id) initWithHTML:(NSData *) data baseURL:(NSURL *) url documentAttributes:(NSDictionary **) attrs;
- (id) initWithHTML:(NSData *) data documentAttributes:(NSDictionary **) attrs;
- (id) initWithHTML:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs;
- (id) initWithPath:(NSString *) path documentAttributes:(NSDictionary **) attrs;	// with file URL
- (id) initWithRTF:(NSData *) data documentAttributes:(NSDictionary **) attrs;
- (id) initWithRTFD:(NSData *) data documentAttributes:(NSDictionary **) attrs;
- (id) initWithRTFDFileWrapper:(NSFileWrapper *) fileWrapper documentAttributes:(NSDictionary **) attrs;
- (id) initWithURL:(NSURL *) url documentAttributes:(NSDictionary **) attrs;
- (id) initWithURL:(NSURL *) url options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
- (NSRange) itemNumberInTextList:(NSTextList *) textList atIndex:(unsigned) loc;
- (unsigned) lineBreakBeforeIndex:(unsigned) loc withinRange:(NSRange) range;
- (unsigned) lineBreakByHyphenatingBeforeIndex:(unsigned) loc withinRange:(NSRange) range;
- (unsigned) nextWordFromIndex:(unsigned) loc forward:(BOOL) isForward;
- (NSRange) rangeOfTextBlock:(NSTextBlock *) textBlock atIndex:(unsigned) loc;
- (NSRange) rangeOfTextList:(NSTextList *) textList atIndex:(unsigned) loc;
- (NSRange) rangeOfTextTable:(NSTextTable *) textTable atIndex:(unsigned) loc;
- (NSFileWrapper *) RTFDFileWrapperFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs;
- (NSData *) RTFDFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs;
- (NSData *) RTFFromRange:(NSRange) range documentAttributes:(NSDictionary *) attrs;
- (NSDictionary *) rulerAttributesInRange:(NSRange) range;
- (NSSize)size;

@end

extern NSString *NSCharacterEncodingDocumentOption;
extern NSString *NSBaseURLDocumentOption;
extern NSString *NSDefaultAttributesDocumentOption;
extern NSString *NSDocumentTypeDocumentOption;

extern NSString *NSTextEncodingNameDocumentOption;
extern NSString *NSTimeoutDocumentOption;
extern NSString *NSWebPreferencesDocumentOption;
extern NSString *NSWebResourceLoadDelegateDocumentOption;
extern NSString *NSTextSizeMultiplierDocumentOption;

@interface NSMutableAttributedString (NSMutableAttributedStringAdditions)

- (void) applyFontTraits:(NSFontTraitMask) traitMask range:(NSRange) range;
- (void) fixAttachmentAttributeInRange:(NSRange) range;
- (void) fixAttributesInRange:(NSRange) range;		// master fix method
- (void) fixFontAttributeInRange:(NSRange) range;
- (void) fixParagraphStyleAttributeInRange:(NSRange) range;
- (BOOL) readFromData:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs;
- (BOOL) readFromData:(NSData *) data options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
- (BOOL) readFromURL:(NSURL *) url options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs;
- (BOOL) readFromURL:(NSURL *) url options:(NSDictionary *) opts documentAttributes:(NSDictionary **) attrs error:(NSError **) error;
- (void) setAlignment:(NSTextAlignment) align range:(NSRange) range;
- (void) setBaseWritingDirection:(NSWritingDirection) direction range:(NSRange) range;
- (void) subscriptRange:(NSRange) range;
- (void) superscriptRange:(NSRange) range;
- (void) unscriptRange:(NSRange) range; 			// Undo previous superscripting
- (void) updateAttachmentsFromPath:(NSString *) path;

@end

#endif /* _mySTEP_H_NSAttributedStringAdditions */
