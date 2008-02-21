/*
   NSTextView.m

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   Source by Daniel Bðhringer integrated into mySTEP gui
   by Felipe A. Rodriguez <far@ix.netcom.com> 

   Complete rewrite
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <AppKit/NSApplication.h>	// NSModalPanelRunLoopMode
#import <AppKit/NSTextView.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSSpellChecker.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSCursor.h>

#define NOTE(notice_name) NSText##notice_name##Notification

@interface NSTextViewSharedData : NSObject <NSCoding>	// this is an internal class but we must be able to decode it from a TextView
{
	int flags;
	NSColor *backgroundColor;
	NSColor *insertionColor;
	NSParagraphStyle *defaultParagraphStyle;
	NSDictionary *linkAttributes;
	NSDictionary *markedAttributes;
	NSDictionary *selectedAttributes;
}
- (int) flags;
- (NSColor *) backgroundColor;
@end

// classes needed are: NSRulerView NSTextContainer NSLayoutManager

static NSCursor *__textCursor;
static NSTimer *__caretBlinkTimer = nil;
static NSCursor *__textCursor = nil;

@implementation NSTextView

	// Registers send and return types for the Services facility. This method 
	// is invoked automatically; you should never need to invoke it directly.

+ (void) registerForServices
{ 
	return; // does nothing for now
}

- (id) initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
	// FIXME: can we call [self initWithFrame] and still release everything?
	if((self=[super initWithFrame:frameRect]))	// this will create an owned textStorage
		{
		[textStorage release];
		_tx.ownsTextStorage=NO;
		[self setTextContainer:container];
		layoutManager=[container layoutManager];
		textStorage=[layoutManager textStorage];
		// other initialization
		insertionPointColor=[[NSColor blackColor] retain];
		}
	return self;
}

// This variant will create the text network  
// (textStorage, layoutManager, and a container).

- (id) initWithFrame:(NSRect)frameRect
{
	if((self=[super initWithFrame:frameRect]))	// this will create an owned textStorage
		{ // create simple text network
		layoutManager=[NSLayoutManager new];
		[layoutManager setTextStorage:textStorage];	// attach our text storage
		[textStorage addLayoutManager:layoutManager];	// this retains the layout manager
		textContainer=[[NSTextContainer alloc] initWithContainerSize:frameRect.size];
		[textContainer replaceLayoutManager:layoutManager];
		[textContainer setTextView:self];
		// FIXME: who reatins the textContainer?
// ???		[layoutManager release];
// ???		[textContainer release];
		// other initialization
		insertionPointColor=[[NSColor blackColor] retain];
		}
	return self;
}

- (void) dealloc;
{
	[super dealloc];
}

// The set method should not be called directly, but you might want to override it.
// Gets or sets the text container for this view.  Setting the text container marks the view as needing display.
// The text container calls the set method from its setTextView: method.

- (void) setTextContainer:(NSTextContainer *)container
{	
	textContainer=container;	// not retained!
	[self setNeedsDisplay:YES];
}

- (NSTextContainer*) textContainer			{ return textContainer; }

// This method should be used instead of the primitive -setTextContainer: 
// if you need to replace a view's text container with a new one leaving the rest of the web intact.
// This method deals with all the work of making sure the view doesn't get deallocated
// and removing the old container from the layoutManager and replacing it with the new one.

- (void) replaceTextContainer:(NSTextContainer *)newContainer
{ // do something to retain the web
	int idx;
	[self retain];	// just be sure
	idx=[[layoutManager textContainers] indexOfObject:textContainer];	// find current text container
	if(idx != NSNotFound)
		[layoutManager removeTextContainerAtIndex:idx];	// remove from layout manager
	else
		idx=0;	// first
	[textContainer setTextView:nil];		// unlink
	[newContainer setTextView:self];		// and link to us - will call our setTextContainer setter
	[layoutManager insertTextContainer:newContainer atIndex:idx];	// connect to the layout manager
	[self release];
}

// The textContianerInset determines the padding that the view provides around the container. 
// The container's origin will be inset by this amount from the bounds point {0,0} and padding 
// will be left to the right and below the container of the same amount. 
// This inset affects the view sizing in response to new layout and is used by the rectangular text
// containers when they track the view's frame dimensions.

- (void) setTextContainerInset:(NSSize)inset	{ textContainerInset = inset; }
- (NSSize) textContainerInset					{ return textContainerInset; }

// The container's origin in the view is determined from the current usage of the container, the
// container inset, and the view size.  textContainerOrigin returns this point.
// invalidateTextContainerOrigin is sent automatically whenever something changes that causes the
// origin to possibly move.  You usually do not need to call invalidate yourself. 

- (NSPoint) textContainerOrigin					{ return textContainerOrigin; }
- (void) invalidateTextContainerOrigin			{ NIMP }
- (NSLayoutManager*) layoutManager				{ return layoutManager; }
- (NSTextStorage*) textStorage					{ return textStorage; }

// Sets the frame size of the view to desiredSize 
// constrained within min and max size.
// this one is probably called when the layout manager needs more or less space in its text container

- (void) setConstrainedFrameSize:(NSSize)desiredSize		// Sizing methods
{
	NSSize newSize=_frame.size;
	newSize.width=MIN(MAX(desiredSize.width, _minSize.width), _maxSize.width);
	newSize.height=MIN(MAX(desiredSize.height, _minSize.height), _maxSize.height);
	if(!NSEqualSizes(_frame.size, newSize))
		{ // adjust to be between min and max size - may adjust the container depending on its tracking flags
		[self setFrameSize:newSize];
		[self setNeedsDisplay:YES];
		}
}

// New miscellaneous API above and beyond NSText

- (void) setAlignment:(NSTextAlignment)alignment range:(NSRange)range
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:alignment]
																		   forKey:@"TextAlignment"]
										 range:range];
}

- (void) pasteAsPlainText:sender
{
	NIMP
}

- (void) pasteAsRichText:sender
{
	NIMP
}

// New Font menu commands 

- (void) turnOffKerning:(id)sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
																		   forKey:NSKernAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) tightenKerning:(id)sender
{
	// FIXME: accumulate?
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
																		   forKey:NSKernAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) loosenKerning:(id)sender
{
	// FIXME: accumulate?
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
																		   forKey:NSKernAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useStandardKerning:(id)sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
																		   forKey:NSKernAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) turnOffLigatures:(id)sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]
																		   forKey:NSLigatureAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useStandardLigatures:(id)sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]
																		   forKey:NSLigatureAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useAllLigatures:(id)sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]
																		   forKey:NSLigatureAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) raiseBaseline:(id)sender
{
	// FIXME: accumulate?
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0]
																		   forKey:NSBaselineOffsetAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];	
}
- (void) lowerBaseline:(id)sender
{
	// FIXME: accumulate?
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:3.0]
																		   forKey:NSBaselineOffsetAttributeName]
										 range:[self rangeForUserCharacterAttributeChange]];	
}
															// Ruler support 

- (void) rulerView:(NSRulerView *)ruler didMoveMarker:(NSRulerMarker *)marker
{ NIMP
}
- (void) rulerView:(NSRulerView *)ruler didRemoveMarker:(NSRulerMarker *)marker
{ NIMP
}
- (void) rulerView:(NSRulerView *)ruler didAddMarker:(NSRulerMarker *)marker
{ NIMP
}
- (BOOL) rulerView:(NSRulerView *)ruler 
		 shouldMoveMarker:(NSRulerMarker *)marker
{ NIMP; return NO;
}
- (BOOL) rulerView:(NSRulerView *)ruler shouldAddMarker:(NSRulerMarker *)marker
{ NIMP; return NO;
}
- (float) rulerView:(NSRulerView *)ruler 
		  willMoveMarker:(NSRulerMarker *)marker 
		  toLocation:(float)location
{ NIMP; return 0.0;
}

- (BOOL) rulerView:(NSRulerView *)ruler 
		 shouldRemoveMarker:(NSRulerMarker *)marker
{ NIMP; return NO;
}

- (float) rulerView:(NSRulerView *)ruler 
		  willAddMarker:(NSRulerMarker *)marker 
		  atLocation:(float)location
{ NIMP; return 0.0;
}

- (void) rulerView:(NSRulerView *)ruler handleMouseDown:(NSEvent *)event
{ NIMP
}

// Fine display control

- (void) setNeedsDisplayInRect:(NSRect)rect avoidAdditionalLayout:(BOOL)flag
{
	if(!flag)
		{
		// do additional layout if needed
		}
	[super setNeedsDisplayInRect:rect];
}

// Especially for subclassers

- (void) updateRuler
{
	NIMP
}

- (void) updateFontPanel
{
	NIMP
}

// Selected/Marked range

- (void) setSelectedRange:(NSRange)charRange 
				 affinity:(NSSelectionAffinity)affinity 
				 stillSelecting:(BOOL)stillSelectingFlag
{
	[self setSelectedRange:charRange];
}

- (NSSelectionAffinity) selectionAffinity		{ return selectionAffinity; }
- (NSSelectionGranularity) selectionGranularity	{ return selectionGranularity;}

- (void) setSelectionGranularity:(NSSelectionGranularity)granularity
{	
	selectionGranularity = granularity;
}

- (void) setSelectedTextAttributes:(NSDictionary *) attribs { ASSIGN(selectedTextAttributes, attribs); }
- (NSDictionary*) selectedTextAttributes { return selectedTextAttributes; }
- (void) setLinkTextAttributes:(NSDictionary*) attribs { ASSIGN(linkTextAttributes, attribs); }
- (NSDictionary*) linkTextAttributes { return linkTextAttributes; }
- (void) setMarkedTextAttributes:(NSDictionary*) attribs { ASSIGN(markedTextAttributes, attribs); }
- (NSDictionary*) markedTextAttributes { return markedTextAttributes; }

- (BOOL) shouldDrawInsertionPoint;
{
	if(!_tx.editable)					return NO;
	if(_selectedRange.length > 0)		return NO;
	if(!_window)							return NO;
	if([_window firstResponder] != self)	return NO;
	return YES;
}

- (void) setInsertionPointColor:(NSColor *)color { ASSIGN(insertionPointColor, color); }
- (NSColor *)insertionPointColor				{ return insertionPointColor; }

// FIXME: if several texviews share the same layout manager, all views must blink the cursor!!

- (void) _blinkCaret:(NSTimer *) timer
{ // toggle the caret and trigger redraw
	NSRect r;
	insertionPointIsOn = !insertionPointIsOn;	// toggle state
	r=[self firstRectForCharacterRange:_selectedRange];	// should be cached!!!
	r.size.width=1.0;
	[self setNeedsDisplayInRect:r avoidAdditionalLayout:YES];	// this should redraw only the insertion point - if it is enabled		
}

- (void) updateInsertionPointStateAndRestartTimer:(BOOL) restartFlag
{ // does nothing if we should draw insertion point but have no restart
	// FIXME: the cursor rect should be calculated here and then just used to redraw the cursor
#if 0
	NSLog(@"updateInsertionPointStateAndRestartTimer");
#endif
	if([self shouldDrawInsertionPoint])
		{ // add to list
		if(restartFlag)
			{ // stop existing timer
			[__caretBlinkTimer invalidate];	// stop any existing timer - there is only one globally blinking cursor!
			__caretBlinkTimer=nil;
			}
		if(!__caretBlinkTimer)
			{ // no timer yet
			NSRunLoop *c = [NSRunLoop currentRunLoop];		
			__caretBlinkTimer = [NSTimer timerWithTimeInterval: 0.7
														target: self
													  selector: @selector(_blinkCaret:)
													  userInfo: nil
													   repeats: YES];		
			[c addTimer:__caretBlinkTimer forMode:NSDefaultRunLoopMode];
			[c addTimer:__caretBlinkTimer forMode:NSModalPanelRunLoopMode];
			insertionPointIsOn=NO;	// (re) start with cursor being on
			[self _blinkCaret:nil];	// and immediately show cursor
			}
		}
	else
		{ // stop timer
		[__caretBlinkTimer invalidate];	// stop any existing timer - there is only one globally blinking cursor!
		__caretBlinkTimer=nil;
		insertionPointIsOn=YES;		// end with cursor being off
		[self _blinkCaret:nil];	// and switch off cursor
		}
}

- (void) drawViewBackgroundInRect:(NSRect)rect
{
	if(_tx.drawsBackground)
		{
		[_backgroundColor set];
		NSRectFill(rect);
		}	
}

	// Other NSTextView methods
- (void) setRulerVisible:(BOOL)flag
{
	if([self isRulerVisible] != flag)
		[self toggleRuler:nil];
}

- (BOOL) usesRuler { return usesRuler; }

- (void) setUsesRuler:(BOOL)flag
{
	if(usesRuler == flag)
		return;	// unchanged
	usesRuler=flag;
	// adjust view
}

- (int) spellCheckerDocumentTag
{ 
	return _spellCheckerDocumentTag;	// from superclass
}

- (NSDictionary*) typingAttributes { return typingAttributes; }
- (void) setTypingAttributes:(NSDictionary *)attrs { ASSIGN(typingAttributes, attrs); }

- (BOOL) shouldChangeTextInRange:(NSRange)affectedCharRange 
		 replacementString:(NSString *)replacementString
{ NIMP; return NO;
}

- (void) didChangeText
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(DidChange) object:self];
	[self setNeedsDisplay:YES];
}		

- (NSRange) rangeForUserTextChange
{
	if(![self isRichText])
		return NSMakeRange(0, 123);	// full range
	return [self selectedRange];
}

- (NSRange) rangeForUserCharacterAttributeChange
{
	if(![self isRichText])
		return NSMakeRange(0, 123);	// full range
	return [self selectedRange];
}

- (NSRange) rangeForUserParagraphAttributeChange
{
	if(![self isRichText])
		return NSMakeRange(0, 123);	// full range
	return [self selectedRange];
}

//
// Smart copy/paste/delete support
//

- (BOOL) smartInsertDeleteEnabled		{ return smartInsertDeleteEnabled; }
- (void) setSmartInsertDeleteEnabled:(BOOL)flag { smartInsertDeleteEnabled=flag; }

- (NSRange) smartDeleteRangeForProposedRange:(NSRange)proposedCharRange
{ NIMP; return NSMakeRange(0, 0);
}

- (void) smartInsertForString:(NSString *)pasteString 
			  replacingRange:(NSRange)charRangeToReplace 
			  beforeString:(NSString **)beforeString 
			  afterString:(NSString **)afterString
{ NIMP;
}

- (void) setBaseWritingDirection:(NSWritingDirection) direction range:(NSRange) range;
{
	[textStorage setBaseWritingDirection:direction range:range];
}

- (unsigned int) draggingEntered:(id <NSDraggingInfo>)sender		// Dragging
{	
	return NSDragOperationGeneric;
}

- (unsigned int) draggingUpdated:(id <NSDraggingInfo>)sender
{	
	return NSDragOperationGeneric;
}

- (void) draggingExited:(id <NSDraggingInfo>)sender
{
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender
{	
	return YES;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender
{	
	return [self performPasteOperation:[sender draggingPasteboard]];
}

- (void) concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[_window endEditingFor:self];
}

- (NSArray*) acceptableDragTypes
{	
	NSMutableArray *ret = [NSMutableArray arrayWithObjects:NSStringPboardType, NSColorPboardType, nil];
	if(_tx.isRichText)			
		[ret addObject:NSRTFPboardType];
	if([self importsGraphics])		
		[ret addObject:NSRTFDPboardType];
	return ret;
}

- (void) updateDragTypeRegistration
{	
	[self registerForDraggedTypes:[self acceptableDragTypes]];
}

/*
 Sources/NSTextView.m:512: warning: method definition for `-writeSelectionToPasteboard:types:' not found
 Sources/NSTextView.m:512: warning: method definition for `-writeSelectionToPasteboard:type:' not found
 Sources/NSTextView.m:512: warning: method definition for `-writablePasteboardTypes' not found
 Sources/NSTextView.m:512: warning: method definition for `-validRequestorForSendType:returnType:' not found
 Sources/NSTextView.m:512: warning: method definition for `-usesFindPanel' not found
 Sources/NSTextView.m:512: warning: method definition for `-underline:' not found
 Sources/NSTextView.m:512: warning: method definition for `-toggleTraditionalCharacterShape:' not found
 Sources/NSTextView.m:512: warning: method definition for `-toggleContinuousSpellChecking:' not found
 Sources/NSTextView.m:512: warning: method definition for `-toggleBaseWritingDirection:' not found
 Sources/NSTextView.m:512: warning: method definition for `-stopSpeaking:' not found
 Sources/NSTextView.m:512: warning: method definition for `-startSpeaking:' not found
 Sources/NSTextView.m:512: warning: method definition for `-smartInsertBeforeStringForString:replacingRange:' not found
 Sources/NSTextView.m:512: warning: method definition for `-smartInsertAfterStringForString:replacingRange:' not found
 Sources/NSTextView.m:512: warning: method definition for `-shouldDrawInsertionPoint' not found
 Sources/NSTextView.m:512: warning: method definition for `-shouldChangeTextInRanges:replacementStrings:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setUsesFindPanel:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setSelectedRanges:affinity:stillSelecting:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setSelectedRanges:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setSelectedRange:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setLinkTextAttributes:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setDefaultParagraphStyle:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setContinuousSpellCheckingEnabled:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setBackgroundColor:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setAllowsUndo:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setAllowsDocumentBackgroundColorChange:' not found
 Sources/NSTextView.m:512: warning: method definition for `-setAcceptsGlyphInfo:' not found
 Sources/NSTextView.m:512: warning: method definition for `-selectionRangeForProposedRange:granularity:' not found
 Sources/NSTextView.m:512: warning: method definition for `-selectedRanges' not found
 Sources/NSTextView.m:512: warning: method definition for `-readSelectionFromPasteboard:type:' not found
 Sources/NSTextView.m:512: warning: method definition for `-readSelectionFromPasteboard:' not found
 Sources/NSTextView.m:512: warning: method definition for `-readablePasteboardTypes' not found
 Sources/NSTextView.m:512: warning: method definition for `-rangesForUserTextChange' not found
 Sources/NSTextView.m:512: warning: method definition for `-rangesForUserParagraphAttributeChange' not found
 Sources/NSTextView.m:512: warning: method definition for `-rangesForUserCharacterAttributeChange' not found
 Sources/NSTextView.m:512: warning: method definition for `-rangeForUserCompletion' not found
 Sources/NSTextView.m:512: warning: method definition for `-preferredPasteboardTypeFromArray:restrictedToTypesFromArray:' not found
 Sources/NSTextView.m:512: warning: method definition for `-performFindPanelAction:' not found
 Sources/NSTextView.m:512: warning: method definition for `-outline:' not found
 Sources/NSTextView.m:512: warning: method definition for `-orderFrontTablePanel:' not found
 Sources/NSTextView.m:512: warning: method definition for `-orderFrontSpacingPanel:' not found
 Sources/NSTextView.m:512: warning: method definition for `-orderFrontListPanel:' not found
 Sources/NSTextView.m:512: warning: method definition for `-orderFrontLinkPanel:' not found
 Sources/NSTextView.m:512: warning: method definition for `-linkTextAttributes' not found
 Sources/NSTextView.m:512: warning: method definition for `-isContinuousSpellCheckingEnabled' not found
 Sources/NSTextView.m:512: warning: method definition for `-insertText:' not found
 Sources/NSTextView.m:512: warning: method definition for `-insertCompletion:forPartialWordRange:movement:isFinal:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragSelectionWithEvent:offset:slideBack:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragOperationForDraggingInfo:type:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragImageForSelectionWithEvent:origin:' not found
 Sources/NSTextView.m:512: warning: method definition for `-defaultParagraphStyle' not found
 Sources/NSTextView.m:512: warning: method definition for `-completionsForPartialWordRange:indexOfSelectedItem:' not found
 Sources/NSTextView.m:512: warning: method definition for `-complete:' not found
 Sources/NSTextView.m:512: warning: method definition for `-clickedOnLink:atIndex:' not found
 call textView:clickedOnLink:atIndex: if available
 if NO -> next responder
 if not available call textView:clickedOnLink:
 Sources/NSTextView.m:512: warning: method definition for `-cleanUpAfterDragOperation' not found
 Sources/NSTextView.m:512: warning: method definition for `-changeDocumentBackgroundColor:' not found
 Sources/NSTextView.m:512: warning: method definition for `-changeColor:' not found
 Sources/NSTextView.m:512: warning: method definition for `-changeAttributes:' not found
 Sources/NSTextView.m:512: warning: method definition for `-breakUndoCoalescing' not found
 Sources/NSTextView.m:512: warning: method definition for `-allowsUndo' not found
 Sources/NSTextView.m:512: warning: method definition for `-allowsDocumentBackgroundColorChange' not found
 Sources/NSTextView.m:512: warning: method definition for `-alignJustified:' not found
 Sources/NSTextView.m:512: warning: method definition for `-acceptsGlyphInfo' not found
 Sources/NSTextView.m:512: warning: incomplete implementation of class `NSTextView'
*/

// overridden superclass(es) methods

+ (void) initialize
{
	__textCursor = [[NSCursor IBeamCursor] retain];
}

- (BOOL) becomeFirstResponder
{	
	// FIXME: check if we change the layout manager from previous
	
	if(![super becomeFirstResponder])
		return NO;
	[self updateInsertionPointStateAndRestartTimer:YES];	// start blinking
	//	reason=NSCancelTextMovement;	// set default reason
	return YES;
}

- (BOOL) resignFirstResponder
{
	// FIXME: special case if we share the layout manager
	[__caretBlinkTimer invalidate];
	__caretBlinkTimer=nil;
	[self updateInsertionPointStateAndRestartTimer:NO];	// stop blinking
	return [super resignFirstResponder];
}

- (void) sizeToFit;
{
	NSSize size=[textStorage size];	// get bounding box with unlimited size
	if(!_tx.horzResizable)
		size.width=_frame.size.width;	// don't fit to text, i.e. keep frame
	if(!_tx.vertResizable)
		size.height=_frame.size.height;	// don't fit to text, i.e. keep frame
	if(!NSEqualSizes(size, _frame.size))
		{ // really resizing
		[self setConstrainedFrameSize:size];	// may also resize the text container
		size=[layoutManager usedRectForTextContainer:textContainer].size;	// get bounding box with resized text container
		[textContainer setContainerSize:size];
		}
}

// initial sizing after initWithCoder

- (void) viewDidMoveToSuperview; { [self sizeToFit]; }
- (void) viewDidMoveToWindow; { [self sizeToFit]; }

- (void) setNeedsDisplayInRect:(NSRect)rect
{ // override as documented
	[self setNeedsDisplayInRect:rect avoidAdditionalLayout:NO];
}

- (void) drawInsertionPointInRect:(NSRect) rect color:(NSColor *) color turnedOn:(BOOL) flag
{
	NSRect r=[self firstRectForCharacterRange:_selectedRange];
	r.origin.x+=1.0;
	r.size.width=1.0;
	if(NSIntersectsRect(r, rect))
		{
		if(!flag)
			color=_backgroundColor;
		[color setFill];
		NSRectFill(r);
		}
}

- (void) drawRect:(NSRect)rect
{
	NSRange range;
	NSRect r;
	if(!layoutManager)
		return;

	// FIXME: we should ask the backend for for the current clipped rect so that we draw only glyphs we really need to draw
	
	[self drawViewBackgroundInRect:rect];
	range=[layoutManager glyphRangeForTextContainer:textContainer];
#if 0
	NSLog(@"NSTextView drawRect %@", NSStringFromRect(rect));
#endif
	
	[layoutManager drawBackgroundForGlyphRange:range atPoint:textContainerOrigin];
	
	if(_selectedRange.length > 0)
		{ // draw selection range background
		r=[layoutManager boundingRectForGlyphRange:_selectedRange inTextContainer:textContainer];
		if(NSIntersectsRect(r, rect))
			{
			[[NSColor selectedTextBackgroundColor] set];
			// FIXME: this is correct only for single lines...
			NSRectFill(r);
			}
		}
	[layoutManager drawGlyphsForGlyphRange:range atPoint:textContainerOrigin];
	if([self shouldDrawInsertionPoint])
		[self drawInsertionPointInRect:rect color:insertionPointColor turnedOn:insertionPointIsOn];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
	if((self=[super initWithCoder:coder]))
		{ // this will have called initWithFrame: so we have to replace the text system
		NSTextViewSharedData *shared;
		int tvFlags=[coder decodeInt32ForKey:@"NSTVFlags"];
#if 0
		NSLog(@"TVFlags=%d", tvFlags);
#endif
		[self replaceTextContainer:[coder decodeObjectForKey:@"NSTextContainer"]];	// this decodes the layoutManager and the textStorage
#if 0
		NSLog(@"textContainer=%@", textContainer);
#endif
		ASSIGN(layoutManager, [textContainer layoutManager]);	// store a retained reference so that we become the owner
#if 0
		NSLog(@"layoutManager=%@", layoutManager);
#endif
		ASSIGN(textStorage, [layoutManager textStorage]);	// an empty one had already been assigned by superclass
#if 0
		NSLog(@"textStorage=%@", textStorage);
#endif
		shared=[coder decodeObjectForKey:@"NSSharedData"];
		if(shared)
			{
			int flags=[shared flags];
			[self setBackgroundColor:[shared backgroundColor]];
			_tx.selectable = ((0x02 & flags) != 0);
			[self setEditable:((0x01 & flags) != 0)];	// will also set selectable
			_tx.isRichText = ((0x04 & flags) != 0);
			_tx.importsGraphics = ((0x08 & flags) != 0);
			//		  _tf.is_field_editor = ((0x10 & flags) > 0);
			_tx.usesFontPanel = ((0x20 & flags) > 0);
			_tx.rulerVisible = ((0x40 & flags) > 0);
			//		  _tf.uses_ruler = ((0x100 & flags) > 0);
			_tx.drawsBackground = ((0x800 & flags) != 0);
			smartInsertDeleteEnabled = ((0x2000000 & flags) != 0);
				//		  _tf.allows_undo = ((0x40000000 & flags) > 0);	  
				/*	[dest setInsertionPointColor:insertionColor];
				[dest setDefaultParagraphStyle:defaultParagraphStyle];
				[dest setLinkTextAttributes:linkAttributes];
				[dest setMarkedTextAttributes:markedAttributes];
				[dest setSelectedTextAttributes:selectedAttributes];
				*/
			}
		// probably from tvFlags...
		//	[dest setVerticallyResizable:YES];
		//	[dest setHorizontallyResizable:YES];

		}
	return self;
}

- (void) mouseDown:(NSEvent *) event
{ // run a text selection tracking loop
	NSRange rng;	// current selected range
	
	// FIXME: characterIndexForPoint may return NSNotFound
	// FIXME: handle _tx.selectable/_tx.editable

#if 1
	NSLog(@"NSTextView mouseDown");
#endif
	// save modifiers of first event
	if([event clickCount] > 1)
		{ // depending on click count, extend selection at this position and then do standard tracking
		NSPoint p=[self convertPoint:[event locationInWindow] fromView:nil];
		unsigned int pos=[self characterIndexForPoint:p];
		}
	while([event type] != NSLeftMouseUp)	// loop outside until mouse goes up 
		{
		NSPoint p=[self convertPoint:[event locationInWindow] fromView:nil];
		unsigned int pos=[self characterIndexForPoint:p];
#if 0
		NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
		if(NSLocationInRange(pos, _selectedRange))
			{ // in current range we already hit the current selection it is a potential drag&drop
			rng=_selectedRange;
			}
		else if(1) // no modifier
			rng=NSMakeRange(pos, 0);	// set cursor to location where we did click
		else if(0) // shift key
			rng=NSUnionRange(_selectedRange, NSMakeRange(pos, 0));	// extend
		// FIXME: handle [self selectionGranularity]
		[self setSelectedRange:rng affinity:[self selectionAffinity] stillSelecting:YES];	// this should call setNeedsDisplay!
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
		
  		}
	[self setSelectedRange:rng affinity:[self selectionAffinity] stillSelecting:NO];	// finally update selection
#if 1
	NSLog(@"NSTextView mouseDown up");
#endif	
}

@end

@implementation NSTextView (NSUserInterfaceValidation)

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) item;
{
	return YES;
}

@end

@implementation NSTextView (NSTextInput)

/*
Sources/NSTextView.m:512: warning: method definition for `-validAttributesForMarkedText' not found
Sources/NSTextView.m:512: warning: method definition for `-setMarkedText:selectedRange:' not found
Sources/NSTextView.m:512: warning: method definition for `-selectedRange' not found
Sources/NSTextView.m:512: warning: method definition for `-insertText:' not found
Sources/NSTextView.m:512: warning: method definition for `-firstRectForCharacterRange:' not found
Sources/NSTextView.m:512: warning: method definition for `-doCommandBySelector:' not found
Sources/NSTextView.m:512: warning: method definition for `-conversationIdentifier' not found
Sources/NSTextView.m:512: warning: method definition for `-characterIndexForPoint:' not found
Sources/NSTextView.m:512: warning: class `NSTextView' does not fully implement the `NSTextInput' protocol
*/

- (NSAttributedString *) attributedSubstringFromRange:(NSRange) range
{
	return [[self textStorage] attributedSubstringFromRange:range];
}

- (NSRect) firstRectForCharacterRange:(NSRange) range
{
	// FIXME
	range=NSMakeRange(0, [[self textStorage] length]);
	return [layoutManager boundingRectForGlyphRange:range inTextContainer:textContainer];
}

- (BOOL) hasMarkedText; { return _markedRange.length > 0; }
- (NSRange) markedRange { return _markedRange; }
- (NSRange) selectedRange { return _selectedRange; }
- (void) unmarkText; { _markedRange=NSMakeRange(0, 0); /* redisplay */ }

- (unsigned int) characterIndexForPoint:(NSPoint) pnt;
{
	return NSNotFound;	// i.e. outside of all characters
}

@end

@implementation NSTextViewSharedData	// this is an internal class but we must be able to decode it from a TextView

- (void) encodeWithCoder:(NSCoder *) coder;
{
//	[super encodeWithCoder:coder];	// derived from NSObject
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
//	if((self=[super initWithCoder:coder]))	// derived from NSObject
		{
			flags=[coder decodeInt32ForKey:@"NSFlags"];
			backgroundColor=[[coder decodeObjectForKey:@"NSBackgroundColor"] retain];
			insertionColor=[[coder decodeObjectForKey:@"NSInsertionColor"] retain];
			defaultParagraphStyle=[[coder decodeObjectForKey:@"NSDefaultParagraphStyle"] retain];
			// FIXME: appears to have problems with decoding components of NSDictionary (returning nil)
			linkAttributes=[[coder decodeObjectForKey:@"NSLinkAttributes"] retain];
			markedAttributes=[[coder decodeObjectForKey:@"NSMarkedAttributes"] retain];
			selectedAttributes=[[coder decodeObjectForKey:@"NSSelectedAttributes"] retain];
		}
	return self;
}

- (void) dealloc;
{
	[backgroundColor release];
	[insertionColor release];
	[defaultParagraphStyle release];
	[linkAttributes release];
	[markedAttributes release];
	[selectedAttributes release];
	[super dealloc];
}

- (int) flags; { return flags; }
- (NSColor *) backgroundColor { return backgroundColor; }

@end
