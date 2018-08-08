/*
	NSTextView.h
 
	much more sophisticated subclass of NSText that displays the glyphs laid out in one NSTextContainer and therefore
	allows for a text network (multiple views into one text storage, multiple containers).
 
	Copyright (C) 1996 Free Software Foundation, Inc.
 
	Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
	Date: August 1998
 
	Source by Daniel Bðhringer integrated into mySTEP gui
	by Felipe A. Rodriguez <far@ix.netcom.com> 
 
	Author:	H. N. Schaller <hns@computer.org>
	Date:	Jun 2006 - aligned with 10.4
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	13. December 2007 - aligned with 10.5
 
	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
 */

#ifndef _mySTEP_H_NSTextView
#define _mySTEP_H_NSTextView

#import <AppKit/NSText.h>
#import <AppKit/NSTextAttachment.h>
#import <AppKit/NSTextInputClient.h>
#import <AppKit/NSInputManager.h>
#import <AppKit/NSUserInterfaceValidation.h>
#import <AppKit/NSDragging.h>

@class NSTextContainer;
@class NSTextStorage;
@class NSLayoutManager;
@class NSRulerView;
@class NSRulerMarker;

typedef enum _NSSelectionGranularity 
{	
	NSSelectByCharacter = 0,
    NSSelectByWord      = 1,
    NSSelectByParagraph = 2,
} NSSelectionGranularity;

typedef enum _NSSelectionAffinity
{	
	NSSelectionAffinityUpstream   = 0,
    NSSelectionAffinityDownstream = 1,
} NSSelectionAffinity;

typedef enum _NSFindPanelAction
{
	NSFindPanelActionShowFindPanel = 1,
	NSFindPanelActionNext,
	NSFindPanelActionPrevious,
	NSFindPanelActionReplaceAll,
	NSFindPanelActionReplace,
	NSFindPanelActionReplaceAndFind,
	NSFindPanelActionSetFindString,
	NSFindPanelActionReplaceAllInSelection
} NSFindPanelAction;

extern NSString *NSAllRomanInputSourcesLocaleIdentifier; 

extern NSString *NSFindPanelSearchOptionsPboardType;
extern NSString *NSFindPanelCaseInsensitiveSearch;
extern NSString *NSFindPanelSubstringMatch;

enum {
	NSFindPanelSubstringMatchTypeContains = 0,
	NSFindPanelSubstringMatchTypeStartsWith = 1,
	NSFindPanelSubstringMatchTypeFullWord = 2,
	NSFindPanelSubstringMatchTypeEndsWith = 3
};
typedef NSUInteger NSFindPanelSubstringMatchType;

@interface NSTextView : NSText <NSTextInput,NSTextInputClient,NSUserInterfaceValidations>
{	
	NSTextContainer */*nonretained*/textContainer;
	NSColor *insertionPointColor;
	NSLayoutManager */*nonretained*/layoutManager;
	NSDictionary *linkTextAttributes;
	NSDictionary *markedTextAttributes;
	NSDictionary *selectedTextAttributes;
	NSMutableDictionary *typingAttributes; 
	NSParagraphStyle *defaultParagraphStyle;
	NSMutableArray *selectedRanges;	// ?
	NSRect _caretRect;
	NSRange _markedRange;
	NSSize textContainerInset;
	NSPoint textContainerOrigin;
	CGFloat _stableCursorColumn;			// current cursor x positon (used for moveDown: and moveUp:)

//	int spellCheckerDocumentTag;
	// the following should be a bitfield struct - but that saves only approx. 10 bytes per NSTextView...
	NSSelectionAffinity selectionAffinity;
	NSSelectionGranularity selectionGranularity;
	BOOL acceptsGlyphInfo;
	BOOL allowsDocumentBackgroundColorChange;
	BOOL allowsUndo;
	BOOL drawsBackground;
	BOOL isContinuousSpellCheckingEnabled;
	BOOL smartInsertDeleteEnabled;
	BOOL usesFindPanel;
	BOOL usesFontPanel;
	BOOL usesRuler;
	BOOL insertionPointIsOn;
}

+ (void) registerForServices;			// sent each time a view is initialized

- (NSArray *) acceptableDragTypes;
- (BOOL) acceptsGlyphInfo;
- (void) alignJustified:(id) sender;
- (NSArray *) allowedInputSourceLocales;
- (BOOL) allowsDocumentBackgroundColorChange;
- (BOOL) allowsImageEditing; 
- (BOOL) allowsUndo;
- (NSColor *) backgroundColor;
- (void) breakUndoCoalescing;
- (void) changeAttributes:(id) sender;
- (void) changeColor:(id) sender;
- (void) changeDocumentBackgroundColor:(id) sender;
- (NSUInteger) characterIndexForInsertionAtPoint:(NSPoint) pt; 
- (void) cleanUpAfterDragOperation;
- (void) clickedOnLink:(id) link atIndex:(NSUInteger) index;
- (void) complete:(id) sender;
- (NSArray *) completionsForPartialWordRange:(NSRange) range indexOfSelectedItem:(NSInteger *) index;
- (NSParagraphStyle *) defaultParagraphStyle;
- (id) delegate; // inherited from NSText
- (void) didChangeText;
- (BOOL) displaysLinkToolTips; 
- (NSImage *) dragImageForSelectionWithEvent:(NSEvent *) event
									  origin:(NSPointPointer) origin;
- (NSDragOperation) dragOperationForDraggingInfo:(id <NSDraggingInfo>) dragInfo
											type:(NSString *) type;
- (BOOL) dragSelectionWithEvent:(NSEvent *) event
						 offset:(NSSize) mouse
					  slideBack:(BOOL) flag;
- (void) drawInsertionPointInRect:(NSRect) rect
							color:(NSColor *) color
						 turnedOn:(BOOL) flag;
- (BOOL) drawsBackground;	// from NSText
- (void) drawViewBackgroundInRect:(NSRect) rect;
- (BOOL) importsGraphics;		// from NSText
- (id) initWithFrame:(NSRect) frameRect;
- (id) initWithFrame:(NSRect) frameRect textContainer:(NSTextContainer *) container;
- (void) insertCompletion:(NSString *) word
	  forPartialWordRange:(NSRange) range
				 movement:(NSInteger) movement
				  isFinal:(BOOL) flag;
- (NSColor *) insertionPointColor;
- (void) insertText:(id) string;
- (void) invalidateTextContainerOrigin;
- (BOOL) isAutomaticLinkDetectionEnabled; 
- (BOOL) isAutomaticQuoteSubstitutionEnabled; 
- (BOOL) isContinuousSpellCheckingEnabled;
- (BOOL) isEditable;		// from NSText
- (BOOL) isFieldEditor;	// from NSText
- (BOOL) isGrammarCheckingEnabled; 
- (BOOL) isRichText;	// from NSText
- (BOOL) isRulerVisible;	// from NSText
- (BOOL) isSelectable;	// from NSText
- (NSLayoutManager *) layoutManager;
- (NSDictionary *) linkTextAttributes;
- (void) loosenKerning:(id) sender;
- (void) lowerBaseline:(id) sender;
- (NSDictionary *) markedTextAttributes;
- (void) orderFrontLinkPanel:(id) sender;
- (void) orderFrontListPanel:(id) sender;
- (void) orderFrontSpacingPanel:(id) sender;
- (void) orderFrontTablePanel:(id) sender;
- (void) outline:(id) sender;
- (void) pasteAsPlainText:(id) sender;
- (void) pasteAsRichText:(id) sender;
- (void) performFindPanelAction:(id) sender;
- (NSString *) preferredPasteboardTypeFromArray:(NSArray *) available 
					 restrictedToTypesFromArray:(NSArray *) allowed;
- (void) raiseBaseline:(id) sender;
- (NSRange) rangeForUserCharacterAttributeChange;
- (NSRange) rangeForUserCompletion;
- (NSRange) rangeForUserParagraphAttributeChange;
- (NSRange) rangeForUserTextChange;
- (NSArray *) rangesForUserCharacterAttributeChange;
- (NSArray *) rangesForUserParagraphAttributeChange;
- (NSArray *) rangesForUserTextChange;
- (NSArray *) readablePasteboardTypes;
- (BOOL) readSelectionFromPasteboard:(NSPasteboard *) pboard;
- (BOOL) readSelectionFromPasteboard:(NSPasteboard *) pboard type:(NSString *) type;
- (void) replaceTextContainer:(NSTextContainer *) newContainer;
- (void) rulerView:(NSRulerView *) ruler didAddMarker:(NSRulerMarker *) marker;
- (void) rulerView:(NSRulerView *) ruler didMoveMarker:(NSRulerMarker *) marker;
- (void) rulerView:(NSRulerView *) ruler didRemoveMarker:(NSRulerMarker *) marker;
- (void) rulerView:(NSRulerView *) ruler handleMouseDown:(NSEvent *) event;
- (BOOL) rulerView:(NSRulerView *) ruler shouldAddMarker:(NSRulerMarker *) marker;
- (BOOL) rulerView:(NSRulerView *) ruler shouldMoveMarker:(NSRulerMarker *) marker;
- (BOOL) rulerView:(NSRulerView *) ruler shouldRemoveMarker:(NSRulerMarker *) marker;
- (CGFloat) rulerView:(NSRulerView *) ruler willAddMarker:(NSRulerMarker *) marker atLocation:(CGFloat) location;
- (CGFloat) rulerView:(NSRulerView *) ruler willMoveMarker:(NSRulerMarker *) marker toLocation:(CGFloat) location;
- (NSArray *) selectedRanges;
- (NSDictionary *) selectedTextAttributes;
- (NSSelectionAffinity) selectionAffinity;
- (NSSelectionGranularity) selectionGranularity;
- (NSRange) selectionRangeForProposedRange:(NSRange) proposed granularity:(NSSelectionGranularity) granularity;
- (void) setAcceptsGlyphInfo:(BOOL) flag;
- (void) setAlignment:(NSTextAlignment) alignment range:(NSRange) range;
- (void) setAllowedInputSourceLocales:(NSArray *) identifiers; 
- (void) setAllowsDocumentBackgroundColorChange:(BOOL) flag;
- (void) setAllowsImageEditing:(BOOL) flag;
- (void) setAllowsUndo:(BOOL) flag;
- (void) setAutomaticLinkDetectionEnabled:(BOOL) flag;
- (void) setAutomaticQuoteSubstitutionEnabled:(BOOL) flag;
- (void) setBackgroundColor:(NSColor *) color;
- (void) setBaseWritingDirection:(NSWritingDirection) direction range:(NSRange) range;
- (void) setConstrainedFrameSize:(NSSize) desiredSize;
- (void) setContinuousSpellCheckingEnabled:(BOOL) flag;
- (void) setDefaultParagraphStyle:(NSParagraphStyle *) style;
- (void) setDelegate:(id) delegate;		// from NSText
- (void) setDisplaysLinkToolTips:(BOOL) flag;
- (void) setDrawsBackground:(BOOL) flag;	// from NSText
- (void) setEditable:(BOOL) flag;	// from NSText
- (void) setFieldEditor:(BOOL) flag;	// from NSText
- (void) setGrammarCheckingEnabled:(BOOL) flag; 
- (void) setImportsGraphics:(BOOL) flag;	// from NSText
- (void) setInsertionPointColor:(NSColor *) colour;
- (void) setLinkTextAttributes:(NSDictionary *) attribs;
- (void) setMarkedTextAttributes:(NSDictionary *) attribs;
- (void) setNeedsDisplayInRect:(NSRect) rect avoidAdditionalLayout:(BOOL) flag;
- (void) setRichText:(BOOL) flag;	// from NSText
- (void) setRulerVisible:(BOOL) flag;	// from NSText
- (void) setSelectable:(BOOL) flag;	// from NSText
- (void) setSelectedRange:(NSRange) range;
- (void) setSelectedRange:(NSRange) range
				 affinity:(NSSelectionAffinity) affinity
		   stillSelecting:(BOOL) flag;
- (void) setSelectedRanges:(NSArray *) ranges;
- (void) setSelectedRanges:(NSArray *) ranges
				  affinity:(NSSelectionAffinity) affinity
			stillSelecting:(BOOL) flag;
- (void) setSelectedTextAttributes:(NSDictionary *) attribs;
- (void) setSelectionGranularity:(NSSelectionGranularity) granularity;
- (void) setSmartInsertDeleteEnabled:(BOOL) flag;
- (void) setSpellingState:(NSInteger) val range:(NSRange) range; 
- (void) setTextContainer:(NSTextContainer *) container;
- (void) setTextContainerInset:(NSSize) inset;
- (void) setTypingAttributes:(NSDictionary *) attribs;
- (void) setUsesFindPanel:(BOOL) flag;
- (void) setUsesFontPanel:(BOOL) flag;	// from NSText
- (void) setUsesRuler:(BOOL) flag;
- (BOOL) shouldChangeTextInRange:(NSRange) range
			   replacementString:(NSString *) string;
- (BOOL) shouldChangeTextInRanges:(NSArray *) ranges
			   replacementStrings:(NSArray *) strings;
- (BOOL) shouldDrawInsertionPoint;
- (void) showFindIndicatorForRange:(NSRange) range; 
- (NSRange) smartDeleteRangeForProposedRange:(NSRange) range;
- (NSString *) smartInsertAfterStringForString:(NSString *) string replacingRange:(NSRange) range;
- (NSString *) smartInsertBeforeStringForString:(NSString *) string replacingRange:(NSRange) range;
- (BOOL) smartInsertDeleteEnabled;
- (void) smartInsertForString:(NSString *) string
			   replacingRange:(NSRange) range
				 beforeString:(NSString **) before
				  afterString:(NSString **) after;
- (NSInteger) spellCheckerDocumentTag;
- (void) startSpeaking:(id) sender;
- (void) stopSpeaking:(id) sender;
- (NSTextContainer *) textContainer;
- (NSSize) textContainerInset;
- (NSPoint) textContainerOrigin;
- (NSTextStorage *) textStorage;
- (void) tightenKerning:(id) sender;
- (void) toggleAutomaticLinkDetection:(id) sender; 
- (void) toggleAutomaticQuoteSubstitution:(id) sender; 
- (void) toggleBaseWritingDirection:(id) sender;
- (void) toggleContinuousSpellChecking:(id) sender;
- (void) toggleGrammarChecking:(id) sender; 
- (void) toggleSmartInsertDelete:(id) sender; 
- (void) toggleTraditionalCharacterShape:(id) sender;
- (void) turnOffKerning:(id) sender;
- (void) turnOffLigatures:(id) sender;
- (NSDictionary *) typingAttributes;
// inherited - (void) underline:(id) sender;
- (void) updateDragTypeRegistration;
- (void) updateFontPanel;
- (void) updateInsertionPointStateAndRestartTimer:(BOOL) flag;
- (void) updateRuler;
- (void) useAllLigatures:(id) sender;
- (BOOL) usesFindPanel;
- (BOOL) usesFontPanel;	// from NSText
- (BOOL) usesRuler;
- (void) useStandardKerning:(id) sender;
- (void) useStandardLigatures:(id) sender;
- (id) validRequestorForSendType:(NSString *) sendType returnType:(NSString *) returnType;
- (NSArray *) writablePasteboardTypes;
- (BOOL) writeSelectionToPasteboard:(NSPasteboard *) pboard type:(NSString *) type;
- (BOOL) writeSelectionToPasteboard:(NSPasteboard *) pboard types:(NSArray *) type;

@end


@interface NSObject (NSTextViewDelegate)		// Note all delegation messages come from the first textView

- (void) textView:(NSTextView *) textView 
	clickedOnCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) cellFrame;
- (void) textView:(NSTextView *) textView 
	clickedOnCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) cellFrame
		  atIndex:(NSUInteger) index;
- (void) textView:(NSTextView *) textView 
	clickedOnLink:(id) link; /* DEPRECATED */
- (BOOL) textView:(NSTextView *) textView 
	clickedOnLink:(id) link
		  atIndex:(NSUInteger) index;
- (NSArray *) textView:(NSTextView *) textView
		   completions:(NSArray *) words
   forPartialWordRange:(NSRange) range
		 indexOfSelectedItem:(NSInteger *) index;
- (BOOL) textView:(NSTextView *) textView 
		 doCommandBySelector:(SEL) commandSelector;
- (void) textView:(NSTextView *) textView 
		 doubleClickedOnCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) cellFrame; /* DEPRECATED */
- (void) textView:(NSTextView *) textView 
		 doubleClickedOnCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) cellFrame
		  atIndex:(NSUInteger) index;
- (void) textView:(NSTextView *) view 
	  draggedCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) rect
			event:(NSEvent *) event; /* DEPRECATED */
- (void) textView:(NSTextView *) view 
	  draggedCell:(id <NSTextAttachmentCell>) cell 
		   inRect:(NSRect) rect
			event:(NSEvent *) event
		  atIndex:(NSUInteger) index;
- (BOOL) textView:(NSTextView *) textView 
	     shouldChangeTextInRange:(NSRange) affectedCharRange 
	     replacementString:(NSString *) replacementString;
- (BOOL) textView:(NSTextView *) textView 
		 shouldChangeTextInRanges:(NSArray *) affectedCharRange 
		 replacementStrings:(NSArray *) replacementString;
- (NSDictionary *) textView:(NSTextView *) textView 
		 shouldChangeTypingAttributes:(NSDictionary *) oldAttribs 
		 toAttributes:(NSDictionary *) newAttribs;
- (NSInteger) textView:(NSTextView *) textView 
shouldSetSpellingState:(NSInteger) val 
				 range:(NSRange) charRange; 
- (NSRange) textView:(NSTextView *) textView 
			willChangeSelectionFromCharacterRange:(NSRange) oldSelectedCharRange 
	toCharacterRange:(NSRange) newSelectedCharRange;
- (NSRange) textView:(NSTextView *) textView 
			willChangeSelectionFromCharacterRanges:(NSArray *) oldSelectedCharRanges 
			toCharacterRanges:(NSArray *) newSelectedCharRanges;
- (NSString *) textView:(NSTextView *) textView
	 willDisplayToolTip:(NSString *) tooltip
	forCharacterAtIndex:(NSUInteger) index;
- (NSArray *) textView:(NSTextView *) textView
			  writablePasteboardTypesForCell:(id <NSTextAttachmentCell>) cell
			   atIndex:(NSUInteger) index;
- (BOOL) textView:(NSTextView *) textView
		writeCell:(id <NSTextAttachmentCell>) cell
		  atIndex:(NSUInteger) index
	 toPasteboard:(NSPasteboard *) pboard
			 type:(NSString *) type;

- (void) textViewDidChangeSelection:(NSNotification *) notification;
- (void) textViewDidChangeTypingAttributes:(NSNotification *) notification;
- (NSUndoManager *) undoManagerForTextView:(NSTextView *) textView;

// deprecated? private?
- (BOOL) textView:(NSTextView *) view shouldHandleEvent:(NSEvent *) event;
- (void) textView:(NSTextView *) view didHandleEvent:(NSEvent *) event;

@end

extern NSString *NSTextViewDidChangeSelectionNotification;
extern NSString *NSTextViewWillChangeNotifyingTextViewNotification;
extern NSString *NSTextViewDidChangeTypingAttributesNotification;

#endif /* _mySTEP_H_NSTextView */
