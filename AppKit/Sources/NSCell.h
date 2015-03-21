/* 
   NSCell.h

   Abstract cell class

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	22. October 2007  
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	6. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSCell
#define _mySTEP_H_NSCell

#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
#import <AppKit/AppKitDefines.h>
#import <AppKit/NSView.h>				// for NSFocusRingType
#import <AppKit/NSAttributedString.h>	// for drawing attributes
#import <AppKit/NSParagraphStyle.h>		// for NSWritingDirection
#import <AppKit/NSText.h>

@class NSString;
@class NSFormatter;
@class NSView;
@class NSFont;
@class NSMenu;

extern NSString *NSControlTintDidChangeNotification;

typedef NSUInteger NSCellType;

enum {
	NSNullCellType=0,
	NSTextCellType,
	NSImageCellType
};

enum {
    NSAnyType			 = 0,
    NSIntType			 = 1,
    NSPositiveIntType	 = 2,
    NSFloatType			 = 3,
    NSPositiveFloatType	 = 4,
    NSDoubleType		 = 5,
    NSPositiveDoubleType = 6,
	NSDateType			 = 7
};

typedef NSUInteger NSBackgroundStyle;

enum {
	NSBackgroundStyleLight = 0,
	NSBackgroundStyleDark,
	NSBackgroundStyleRaised,
	NSBackgroundStyleLowered
};

typedef NSUInteger NSControlTint;

enum {
	NSDefaultControlTint=0,
	NSBlueControlTint,
	NSGraphiteControlTint=6,
	NSClearControlTint
};

typedef NSUInteger NSControlSize;

enum {
	NSRegularControlSize=0,
	NSSmallControlSize,
	NSMiniControlSize
};

enum {
	NSCellHitNone = 0,
	NSCellHitContentArea = 1 << 0,
	NSCellHitEditableTextArea = 1 << 1,
	NSCellHitTrackableArea = 1 << 2,
};

typedef NSUInteger NSCellImagePosition;

enum {
	NSNoImage = 0,
	NSImageOnly,
	NSImageLeft,
	NSImageRight,
	NSImageBelow,
	NSImageAbove,
	NSImageOverlaps
};

typedef NSUInteger NSImageScaling;

enum {
	NSImageScaleProportionallyDown = 0,
	NSImageScaleAxesIndependently,
	NSImageScaleNone,
	NSImageScaleProportionallyUpOrDown
};

typedef NSUInteger NSCellStateValue;

enum {
	NSMixedState = -1,
	NSOffState   = 0,
	NSOnState    = 1
};

typedef NSUInteger NSCellAttribute;

enum {
	NSCellDisabled,
	NSCellState,
	NSPushInCell,
	NSCellEditable,
	NSChangeGrayCell,
	NSCellHighlighted,   
	NSCellLightsByContents,  
	NSCellLightsByGray,   
	NSChangeBackgroundCell,  
	NSCellLightsByBackground,  
	NSCellIsBordered,  
	NSCellHasOverlappingImage,  
	NSCellHasImageHorizontal,  
	NSCellHasImageOnLeftOrBottom, 
	NSCellChangesContents,  
	NSCellIsInsetButton,
	NSCellAllowsMixedState
};

enum {
	NSNoCellMask				= 0x00,
	NSContentsCellMask			= 0x01,
	NSPushInCellMask			= 0x02,
	NSChangeGrayCellMask		= 0x04,
	NSChangeBackgroundCellMask	= 0x08
};

@interface NSCell : NSObject  <NSCopying, NSCoding>
{
	@public
	id _contents;
	id _controlView;
	id _representedObject;
	NSMutableDictionary *_attribs;	// attribute dict
	// FIXME: the next 3 are stored in the attribs dict
//	NSColor *_textColor;	// NSForegroundColorAttributeName
//	NSFont *_font;	// NSFontAttributeName
//	NSMutableParagraphStyle *_style;	// NSParagraphStyleAttributeName
	NSFormatter *_formatter;
	NSMenu *_menu;
	id _placeholderString;
	struct __CellFlags {
		IBITFIELD(int, state, 2);	// mixed = -1
		UIBITFIELD(unsigned int, allowsMixed, 1);
		UIBITFIELD(unsigned int, highlighted, 1);
		UIBITFIELD(unsigned int, enabled, 1);
		UIBITFIELD(unsigned int, editable, 1);
		UIBITFIELD(unsigned int, bordered, 1);
		UIBITFIELD(unsigned int, bezeled, 1);
		UIBITFIELD(unsigned int, scrollable, 1);
		UIBITFIELD(unsigned int, selectable, 1);
		UIBITFIELD(unsigned int, continuous, 1);
		UIBITFIELD(unsigned int, actOnMouseDown, 1);
		UIBITFIELD(unsigned int, actOnMouseDragged, 1);
		UIBITFIELD(unsigned int, actOnMouseUp, 1);
		UIBITFIELD(unsigned int, floatAutorange, 1);
		TYPEDBITFIELD(NSCellType, type, 2);	
//		TYPEDBITFIELD(NSTextAlignment, alignment, 3);		// FIXME: move to _style
		TYPEDBITFIELD(NSCellImagePosition, imagePosition, 3);
		UIBITFIELD(unsigned int, editing, 1);
		UIBITFIELD(unsigned int, secure, 1);
		UIBITFIELD(unsigned int, drawsBackground, 1);
		UIBITFIELD(unsigned int, entryType, 3);
		UIBITFIELD(unsigned int, showsFirstResponder, 1);
		UIBITFIELD(unsigned int, refusesFirstResponder, 1);
		} _c;
	struct __CellFlags2 {
		UIBITFIELD(unsigned int, isLoaded, 1);	// for NSBrowserCell
		UIBITFIELD(unsigned int, isLeaf, 1);	// for NSBrowserCell
		TYPEDBITFIELD(NSControlSize, controlSize, 2);
		TYPEDBITFIELD(NSControlTint, controlTint, 3);
		TYPEDBITFIELD(NSFocusRingType, focusRingType, 2);
		UIBITFIELD(unsigned int, sendsActionOnEndEditing, 1);
		UIBITFIELD(unsigned int, importsGraphics, 1);
		UIBITFIELD(unsigned int, allowsEditingTextAttributes, 1);
		UIBITFIELD(unsigned int, allowsUndo, 1);
//		TYPEDBITFIELD(NSLineBreakMode, lineBreakMode, 3);		// FIXME: move to _style
		UIBITFIELD(unsigned int, verticallyCentered, 1);
		TYPEDBITFIELD(NSImageScaling, imageScaling, 2);
		} _d;
}

+ (NSFocusRingType) defaultFocusRingType;
+ (NSMenu *) defaultMenu;
+ (BOOL) prefersTrackingUntilMouseUp;					// Tracking the Mouse

- (BOOL) acceptsFirstResponder;
- (SEL) action;
- (NSTextAlignment) alignment;							// Text Attributes
- (BOOL) allowsEditingTextAttributes;
- (BOOL) allowsMixedState;								// allowed / not allowed
- (BOOL) allowsUndo;
- (NSAttributedString *) attributedStringValue;
- (NSBackgroundStyle) backgroundStyle;
- (NSWritingDirection) baseWritingDirection;
- (void) calcDrawInfo:(NSRect) aRect;					// Component sizes
- (int) cellAttribute:(NSCellAttribute) aParameter;		// Setting Parameters
- (NSSize) cellSize;
- (NSSize) cellSizeForBounds:(NSRect) aRect;
// inherited - (NSComparisonResult) compare:(id)otherCell;
- (BOOL) continueTracking:(NSPoint) lastPoint at:(NSPoint) currentPoint inView:(NSView *) controlView;
- (NSControlSize) controlSize;
- (NSControlTint) controlTint;
- (NSView *) controlView;
- (double) doubleValue;									// Get & Set Cell Value
- (NSRect) drawingRectForBounds:(NSRect) theRect;
- (void) drawInteriorWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (void) drawWithExpansionFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (void) drawWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (void) editWithFrame:(NSRect) aRect inView:(NSView *) controlView editor:(NSText *) textObject delegate:(id) anObject event:(NSEvent *) event; // Text Editing
- (void) endEditing:(NSText *) textObject;
- (int) entryType;										// Validating Input - DEPRECATED
- (NSRect) expansionFrameWithFrame:(NSRect) cellFrame inView:(NSView *) controlView;
- (float) floatValue;
- (NSFocusRingType) focusRingType;
- (NSFont *) font;
- (id) formatter;
- (void) getPeriodicDelay:(float *) delay interval:(float *) interval;
- (BOOL) hasValidObjectValue;
- (void) highlight:(BOOL) lit withFrame:(NSRect) cellFrame inView:(NSView *) controlView; // Drawing the cell
- (NSColor *) highlightColorWithFrame:(NSRect) frame inView:(NSView *) controlView;
- (NSUInteger) hitTestForEvent:(NSEvent *) event inRect:(NSRect) cellFrame ofView:(NSView *) view;
- (NSImage*) image;										// Setting the Image
- (NSRect) imageRectForBounds:(NSRect) theRect;
- (BOOL) importsGraphics;
- (id) initImageCell:(NSImage *) anImage;
- (id) initTextCell:(NSString *) aString;
- (NSInteger) integerValue;
- (NSBackgroundStyle) interiorBackgroundStyle;
- (int) intValue;
- (BOOL) isBezeled;										// Graphic Attributes
- (BOOL) isBordered;
- (BOOL) isContinuous;
- (BOOL) isEditable;
- (BOOL) isEnabled;										// Enable / Disable
- (BOOL) isEntryAcceptable:(NSString *) aString;
- (BOOL) isHighlighted;
- (BOOL) isOpaque;
- (BOOL) isScrollable;
- (BOOL) isSelectable;
- (NSString *) keyEquivalent;							// Keyboard Alternative
- (NSLineBreakMode) lineBreakMode;
- (NSMenu *) menu;
- (NSMenu *) menuForEvent:(NSEvent *) anEvent inRect:(NSRect) frame ofView:(NSView *) aView;
- (NSString *) mnemonic;
- (NSUInteger) mnemonicLocation;
- (NSInteger) mouseDownFlags;
- (NSInteger) nextState;
- (id) objectValue;
- (void) performClick:(id) sender;
- (NSImage *) preparedImage;
- (BOOL) refusesFirstResponder;
- (id) representedObject;								// Represent an Object
- (void) resetCursorRect:(NSRect) cellFrame inView:(NSView *) controlView;
- (void) selectWithFrame:(NSRect) aRect 
				  inView:(NSView *) controlView 
				  editor:(NSText *) textObject 
				delegate:(id) anObject 
				   start:(NSInteger) selStart 
				  length:(NSInteger) selLength;
- (NSInteger) sendActionOn:(NSInteger) mask;
- (BOOL) sendsActionOnEndEditing;
- (void) setAction:(SEL) selector;
- (void) setAlignment:(NSTextAlignment) mode;
- (void) setAllowsEditingTextAttributes:(BOOL) flag;
- (void) setAllowsMixedState:(BOOL) flag;
- (void) setAllowsUndo:(BOOL) flag;
- (void) setAttributedStringValue:(NSAttributedString *) string;
- (void) setBackgroundStyle:(NSBackgroundStyle) backgroundStyle;
- (void) setBaseWritingDirection:(NSWritingDirection) direction;
- (void) setBezeled:(BOOL) flag;
- (void) setBordered:(BOOL) flag;
- (void) setCellAttribute:(NSCellAttribute) aParameter to:(NSInteger) value;
- (void) setContinuous:(BOOL) flag;
- (void) setControlSize:(NSControlSize) size;
- (void) setControlTint:(NSControlTint) tint;
- (void) setControlView:(NSView *) view;
- (void) setDoubleValue:(double) aDouble;
- (void) setEditable:(BOOL) flag;
- (void) setEnabled:(BOOL) flag;
- (void) setEntryType:(int) aType;	// deprecated
- (void) setFloatingPointFormat:(BOOL) autoRange left:(NSUInteger) leftDigits right:(NSUInteger) rightDigits;			// Formatting Data 
- (void) setFloatValue:(float) aFloat;
- (void) setFocusRingType:(NSFocusRingType) type;
- (void) setFont:(NSFont *) fontObject;
- (void) setFormatter:(NSFormatter*) newFormatter;
- (void) setHighlighted:(BOOL) flag;
- (void) setImage:(NSImage *) anImage;
- (void) setImportsGraphics:(BOOL) flag;
- (void) setIntegerValue:(NSInteger) integer;
- (void) setIntValue:(int) anInt;
- (void) setLineBreakMode:(NSLineBreakMode) mode;
- (void) setMenu:(NSMenu *) menu;
- (void) setMnemonicLocation:(NSUInteger) location;
- (void) setNextState;
- (void) setObjectValue:(id <NSCopying>) anObject;
- (void) setRefusesFirstResponder:(BOOL) flag;
- (void) setRepresentedObject:(id) anObject;
- (void) setScrollable:(BOOL) flag;
- (void) setSelectable:(BOOL) flag;
- (void) setSendsActionOnEndEditing:(BOOL) flag;
- (void) setShowsFirstResponder:(BOOL) flag;
- (void) setState:(NSInteger) value;							// NSCell's State
- (void) setStringValue:(NSString *) aString;
- (void) setTag:(NSInteger) anInt;								// Assigning a Tag
- (void) setTarget:(id) anObject;
- (void) setTitle:(NSString *) aString;
- (void) setTitleWithMnemonic:(NSString *) aString;
- (void) setType:(NSCellType) aType;						// NSCell's Type
- (NSText *) setUpFieldEditorAttributes:(NSText *) textObject;
- (void) setWraps:(BOOL) flag;
- (BOOL) showsFirstResponder;
- (BOOL) startTrackingAt:(NSPoint) startPoint inView:(NSView*) controlView;
- (NSInteger) state;
- (void) stopTracking:(NSPoint) lastPoint at:(NSPoint) stopPoint inView:(NSView *) controlView mouseIsUp:(BOOL) flag;
- (NSString *) stringValue;
- (NSInteger) tag;
- (void) takeDoubleValueFrom:(id) sender;				// Cell Interaction
- (void) takeFloatValueFrom:(id) sender;
- (void) takeIntegerValueFrom:(id)sender;
- (void) takeIntValueFrom:(id) sender;
- (void) takeObjectValueFrom:(id) sender;
- (void) takeStringValueFrom:(id) sender;
- (id) target;
- (NSString *) title;
- (NSRect) titleRectForBounds:(NSRect) theRect;
- (BOOL) trackMouse:(NSEvent *) event inRect:(NSRect) cellFrame ofView:(NSView *) controlView untilMouseUp:(BOOL) flag;
- (NSCellType) type;
- (BOOL) wantsNotificationForMarkedText;
- (BOOL) wraps;

@end

#endif /* _mySTEP_H_NSCell */
