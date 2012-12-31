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
- (NSColor *) insertionPointColor;
- (NSParagraphStyle *) defaultParagraphStyle;
- (NSDictionary *) linkTextAttributes;
- (NSDictionary *) markedTextAttributes;
- (NSDictionary *) selectedTextAttributes;
@end

// classes needed are: NSRulerView NSTextContainer NSLayoutManager

static NSTimer *__caretBlinkTimer = nil;
static NSCursor *__textCursor = nil;

@implementation NSTextView

// Registers send and return types for the Services facility. This method 
// is invoked automatically; you should never need to invoke it directly.

+ (void) registerForServices
{ 
	return; // does nothing for now
}

+ (void) initialize
{
	__textCursor = [[NSCursor IBeamCursor] retain];
}

- (id) initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
	textContainer=container;	// preinitialize to skip some initializations
	if((self=[self initWithFrame:frameRect]))
		{
		NSAssert(textContainer && layoutManager && textStorage, @"needs text system");
		}
	return self;
}

// This variant will create the text network  
// (textStorage, layoutManager, and a container).

- (id) initWithFrame:(NSRect)frameRect
{
	NSTextContainer *tc=textContainer;	// notify if we want a non-owned textStorage
	NSLayoutManager *lm=[textContainer layoutManager]; // preinitialize
	textStorage=[lm textStorage];				
	if((self=[super initWithFrame:frameRect]))	// the original values may be lost if we receive a proxy here
		{ // create simple text network
			if(tc)
				{ // don't create the default if called from initWithCoder
					textContainer=tc;
					layoutManager=lm;
					textStorage=[layoutManager textStorage];	// non-owned textStorage				
					[textContainer setTextView:self];	// this tries to track container size...
				}
			else
				{
				layoutManager=[NSLayoutManager new];
				textContainer=[[NSTextContainer alloc] initWithContainerSize:frameRect.size];
				[layoutManager addTextContainer:textContainer];
				[textContainer release];	// LayoutManager retains TextContainer
				[textStorage addLayoutManager:layoutManager];
				[layoutManager release];	// LayoutManager retains LayoutManager (and self retains textStorage)
				NSAssert(textContainer && layoutManager && textStorage, @"needs text system");
				}
			insertionPointColor=[[NSColor blackColor] retain];
			defaultParagraphStyle=[[NSParagraphStyle defaultParagraphStyle] retain];
			[self _updateTypingAttributes];
		}
	return self;
}

- (void) dealloc;
{
	[insertionPointColor release];
	[defaultParagraphStyle release];
	[linkTextAttributes release];
	[markedTextAttributes release];
	[selectedTextAttributes release];
	[super dealloc];
}

// The set method should not be called directly, but you might want to override it.
// Gets or sets the text container for this view.  Setting the text container marks the view as needing display.
// The text container calls this set method from its setTextView: method.

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
	if(textContainer == newContainer)
		return;	// not really changed
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

// New miscellaneous API beyond NSText

// Sets the frame size of the view to desiredSize 
// constrained within min and max size.
// this one is probably called when the layout manager needs more or less space in its text container
// or by sizeToFit

- (void) setConstrainedFrameSize:(NSSize) desiredSize
{ // size to desired size if within limits and resizable
	NSSize newSize=_frame.size;
#if 1
	NSLog(@"setConstrainedFrameSize %@: %@", NSStringFromSize(desiredSize), self);
#endif
	if(!_tx.horzResizable)
		newSize.width=_frame.size.width;	// don't fit to text, i.e. keep frame as it is
	else
		newSize.width=MAX(MIN(desiredSize.width, _maxSize.width), _minSize.width);
	if(!_tx.vertResizable)
		newSize.height=_frame.size.height;	// don't fit to text, i.e. keep frame as it is
	else
		newSize.height=MAX(MIN(desiredSize.height, _maxSize.height), _minSize.height);
#if 1
	NSLog(@"newSize=%@", NSStringFromSize(newSize));
#endif
	[self setFrameSize:newSize];	// this should adjust the container depending on its tracking flags
	[self setBoundsSize:newSize];	// will not be updated automatically if we are enclosed in a NSClipView (custom bounds)
	[self setNeedsDisplay:YES];
#if 1
	NSLog(@"container=%@", [self textContainer]);
#endif
}

- (void) sizeToFit;
{
	NSSize size=NSZeroSize;
#if 1
	NSLog(@"sizeToFit: %@", self);
#endif
	if([textStorage length] > 0)
		{ // get bounding box assuming given or unlimited size
			NSRange rng;
			[textContainer setContainerSize:NSMakeSize((_tx.horzResizable?FLT_MAX:_frame.size.width), (_tx.vertResizable?FLT_MAX:_frame.size.height))];
			rng=[layoutManager glyphRangeForTextContainer:textContainer];
			size=[layoutManager boundingRectForGlyphRange:rng inTextContainer:textContainer].size;
		}
	[self setConstrainedFrameSize:size];	// try to adjust
#if 0
	if(!NSEqualSizes([textContainer containerSize], size))
		{
		NSLog(@"fit %@ is %@", NSStringFromSize(size), textContainer);
		NSLog(@"different sizes");
		}
#endif
}

- (void) setAlignment:(NSTextAlignment)alignment range:(NSRange)range
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:alignment]
														   forKey:@"TextAlignment"]
						 range:range];
}

- (void) pasteAsPlainText:(id) sender
{
	// remove attributes from paste buffer
	NIMP
}

- (void) pasteAsRichText:(id) sender
{
	// paste
	NIMP
}

// New Font menu commands 

- (void) turnOffKerning:(id) sender
{
	if([self shouldChangeTextInRange:[self rangeForUserCharacterAttributeChange] replacementString:nil])
		{
		[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
															   forKey:NSKernAttributeName]
							 range:[self rangeForUserCharacterAttributeChange]];
		[self didChangeText];
		}
}

- (void) tightenKerning:(id) sender
{
	if([self shouldChangeTextInRange:[self rangeForUserCharacterAttributeChange] replacementString:nil])
		{
		[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
															   forKey:NSKernAttributeName]
							 range:[self rangeForUserCharacterAttributeChange]];
		[self didChangeText];
		}
}

- (void) loosenKerning:(id) sender
{
	// FIXME: accumulate?
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
														   forKey:NSKernAttributeName]
						 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useStandardKerning:(id) sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.0]
														   forKey:NSKernAttributeName]
						 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) turnOffLigatures:(id) sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:0]
														   forKey:NSLigatureAttributeName]
						 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useStandardLigatures:(id) sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]
														   forKey:NSLigatureAttributeName]
						 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) useAllLigatures:(id) sender
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]
														   forKey:NSLigatureAttributeName]
						 range:[self rangeForUserCharacterAttributeChange]];
}

- (void) raiseBaseline:(id) sender
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
	// if the rect is visible, ensure glyph&layout generation
	// if not, it may trigger background layout - this may split the text storage into chunks and perform delayed
	if(!flag)
		{
		// do additional layout if needed
		}
#if 0
	NSLog(@"NSTextView setNeedsDisplayInRect:%@", NSStringFromRect(rect));
	if([[self superview] isKindOfClass:[NSClipView class]])
		NSLog(@"child of clipView: %@", textStorage);
#endif
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

- (NSSelectionAffinity) selectionAffinity		{ return selectionAffinity; }
- (NSSelectionGranularity) selectionGranularity	{ return selectionGranularity;}

- (void) setSelectionGranularity:(NSSelectionGranularity)granularity
{	
	selectionGranularity = granularity;
}

- (void) setDefaultParagraphStyle:(NSParagraphStyle *) style { ASSIGN(defaultParagraphStyle, style); }
- (NSParagraphStyle *) defaultParagraphStyle { return defaultParagraphStyle; }
- (void) setSelectedTextAttributes:(NSDictionary *) attribs { ASSIGN(selectedTextAttributes, attribs); }
- (NSDictionary *) selectedTextAttributes { return selectedTextAttributes; }
- (void) setLinkTextAttributes:(NSDictionary*) attribs { ASSIGN(linkTextAttributes, attribs); }
- (NSDictionary *) linkTextAttributes { return linkTextAttributes; }
- (void) setMarkedTextAttributes:(NSDictionary*) attribs { ASSIGN(markedTextAttributes, attribs); }
- (NSDictionary *) markedTextAttributes { return markedTextAttributes; }

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
// use -NSWindow cacheImageInRect and restoreCachedImage to handle cursor blinking

- (NSRect) _caretRect
{
	if(NSIsEmptyRect(_caretRect))
		{
		_caretRect=[self firstRectForCharacterRange:_selectedRange];
		_caretRect.origin.x+=1.0;
		_caretRect.size.width=1.0;
		}
	return _caretRect;
}

- (void) _blinkCaret:(NSTimer *) timer
{ // toggle the caret and trigger redraw
#if 0
	NSLog(@"_blinkCaret %@", NSStringFromRect([self _caretRect]));
#endif
	insertionPointIsOn = !insertionPointIsOn;	// toggle state
	[self setNeedsDisplayInRect:[self _caretRect] avoidAdditionalLayout:YES];	// this should redraw only the insertion point - if it is enabled		
}

- (void) updateInsertionPointStateAndRestartTimer:(BOOL) restartFlag
{ // does nothing if we should draw insertion point but have no restart
	// FIXME: the cursor rect should be calculated here and then just used to redraw the cursor
#if 0
	NSLog(@"updateInsertionPointStateAndRestartTimer");
#endif
	if(!NSIsEmptyRect(_caretRect))
		[self setNeedsDisplayInRect:_caretRect avoidAdditionalLayout:YES];	// update previous rect
	_caretRect=NSZeroRect;	// determine new rect as soon as needed
	if([self shouldDrawInsertionPoint])
		{ // add to list
			if(restartFlag)
				{ // stop existing timer
					[__caretBlinkTimer invalidate];	// stop any existing timer - there is only one globally blinking cursor!
					__caretBlinkTimer=nil;
				}
			if(!__caretBlinkTimer)
				{ // no timer yet
					NSRunLoop *rl = [NSRunLoop currentRunLoop];		
					__caretBlinkTimer = [NSTimer timerWithTimeInterval: 0.6
																target: self
															  selector: @selector(_blinkCaret:)
															  userInfo: nil
															   repeats: YES];		
					[rl addTimer:__caretBlinkTimer forMode:NSDefaultRunLoopMode];
					[rl addTimer:__caretBlinkTimer forMode:NSModalPanelRunLoopMode];
					insertionPointIsOn=NO;	// (re) start with cursor being on
					[self _blinkCaret:nil];	// and immediately show cursor
				}
		}
	else
		{ // stop timer
			[__caretBlinkTimer invalidate];	// stop any existing timer - there is only one globally blinking cursor!
			__caretBlinkTimer=nil;
		}
}

- (void) drawViewBackgroundInRect:(NSRect)rect
{
	if(_tx.drawsBackground)
		{
		[_backgroundColor set];
		NSRectFill(rect);
		}
#if 1	// show container outline
	[[NSColor redColor] set];
	NSFrameRect((NSRect) { textContainerOrigin, [textContainer containerSize] } );
#endif
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

- (void) _updateTypingAttributes;
{
	NSDictionary *attribs;
	unsigned int length=[textStorage length];
	if(_selectedRange.location < length)
		attribs=[textStorage attributesAtIndex:_selectedRange.location effectiveRange:NULL];
	else
		{ // cursor is at end of string
		if(length > 0)
			attribs=[textStorage attributesAtIndex:_selectedRange.location-1 effectiveRange:NULL];	// continue with last format
		else
			attribs=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont userFontOfSize:0.0], NSFontAttributeName, nil];	// set default typing attributes		
		}
	[self setTypingAttributes:attribs];	// reset from first selected character	
}

- (BOOL) shouldChangeTextInRange:(NSRange)affectedCharRange 
			   replacementString:(NSString *)replacementString
{
	if(![self isEditable])
		return NO;
	if(![_delegate textShouldBeginEditing:self])
		return NO;
	if(![_delegate textView:self shouldChangeTextInRange:affectedCharRange replacementString:replacementString])
		return NO;
	return YES;
}

- (void) didChangeText
{
	[[NSNotificationCenter defaultCenter] postNotificationName:NOTE(DidChange) object:self];
	[self setNeedsDisplay:YES];
}		

- (NSRange) rangeForUserTextChange
{
	if(![self isRichText])
		return NSMakeRange(0, [textStorage length]);	// full range
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

- (void) setImportsGraphics:(BOOL)flag
{	
	[super setImportsGraphics:flag];
	[self updateDragTypeRegistration];
}

- (void) setRichText:(BOOL)flag
{	
	[super setRichText:flag];
	[self updateDragTypeRegistration];
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
 Sources/NSTextView.m:512: warning: method definition for `-setContinuousSpellCheckingEnabled:' not found
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
 Sources/NSTextView.m:512: warning: method definition for `-insertCompletion:forPartialWordRange:movement:isFinal:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragSelectionWithEvent:offset:slideBack:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragOperationForDraggingInfo:type:' not found
 Sources/NSTextView.m:512: warning: method definition for `-dragImageForSelectionWithEvent:origin:' not found
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

- (BOOL) becomeFirstResponder
{	
	// FIXME: check if we change the layout manager from previous
	
	if(![super becomeFirstResponder])
		return NO;
	return YES;
}

- (BOOL) resignFirstResponder
{
	BOOL flag;
	// FIXME: handle special case if we share the layout manager...
	// in fact we should blink as long as there are any layoutmnagers with first responder textviews
	flag=[super resignFirstResponder];
	[self updateInsertionPointStateAndRestartTimer:NO];	// will switch off cursor if we did have one
	return flag;
}

// initial sizing after initWithCoder

- (void) viewDidMoveToSuperview; { [self sizeToFit]; }
- (void) viewDidMoveToWindow; { [self sizeToFit]; }

- (void) setNeedsDisplayInRect:(NSRect)rect
{ // override as documented
#if 1
	if(_frame.size.height == 0)
		NSLog(@"height became 0!");
#endif
	[self setNeedsDisplayInRect:rect avoidAdditionalLayout:NO];
}

- (void) drawInsertionPointInRect:(NSRect) rect color:(NSColor *) color turnedOn:(BOOL) flag
{ // rect is 1 pixel wide and max. font size high
	if(!flag)
		return;	// default cursor draws transparent background
	[color setFill];
	NSRectFill(rect);	// or color
}

- (void) drawRect:(NSRect)rect
{
	NSRange range;
	if(!layoutManager)
		return;
	range=[layoutManager glyphRangeForBoundingRectWithoutAdditionalLayout:rect inTextContainer:textContainer];
#if 0
	NSLog(@"NSTextView drawRect %@", NSStringFromRect(rect));
	NSLog(@"         glyphRange %@", NSStringFromRange(range));
#endif
	[self drawViewBackgroundInRect:rect];
	[layoutManager drawBackgroundForGlyphRange:range atPoint:textContainerOrigin];
	[layoutManager drawGlyphsForGlyphRange:range atPoint:textContainerOrigin];
	if([self shouldDrawInsertionPoint])
		{
		NSRect r=[self _caretRect];
		if(NSIntersectsRect(r, rect))
			[self drawInsertionPointInRect:r color:insertionPointColor turnedOn:insertionPointIsOn];
		}
#if 0
	if(!NSEqualSizes(_bounds.size, _frame.size))
		NSLog(@"bound/frame error");
#endif
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[super encodeWithCoder:coder];
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 1
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
	NSTextContainer *tc=[coder decodeObjectForKey:@"NSTextContainer"];	// this also decodes the layoutManager and the textStorage - but does not retain them as needed!
	textContainer=tc;	// notify initWithFrame to create no default text system
#if 1
	NSLog(@"textContainer=%@", textContainer);
#endif
	if((self=[super initWithCoder:coder]))
		{ // this will have called initWithFrame:
			NSTextViewSharedData *shared;
			int tvFlags=[coder decodeInt32ForKey:@"NSTVFlags"];	// do we have these in NSText or NSTextView?
			textContainer=tc;
			layoutManager=[textContainer layoutManager];	// layoutManager retains textContainer
#if 1
			NSLog(@"layoutManager=%@", layoutManager);
#endif
			textStorage=[[layoutManager textStorage] retain];
			_tx.ownsTextStorage=YES;			// that we now own
			NSAssert(textContainer && layoutManager && textStorage, @"needs text system");
#if 1
			NSLog(@"NSTVFlags=%08x", tvFlags);
			_tx.horzResizable=NO;
			_tx.vertResizable=YES;
			NSLog(@"textStorage=%@", textStorage);
			if([[textStorage string] hasPrefix:@"This"])
				NSLog(@"This");
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
				// _tf.is_field_editor = ((0x10 & flags) > 0);
				_tx.usesFontPanel = ((0x20 & flags) > 0);
				_tx.rulerVisible = ((0x40 & flags) > 0);
				// _tf.uses_ruler = ((0x100 & flags) > 0);
				_tx.drawsBackground = ((0x800 & flags) != 0);
				smartInsertDeleteEnabled = ((0x2000000 & flags) != 0);
				// _tf.allows_undo = ((0x40000000 & flags) > 0);	  
				[self setInsertionPointColor:[shared insertionPointColor]];
				[self setDefaultParagraphStyle:[shared defaultParagraphStyle]];
				[self setLinkTextAttributes:[shared linkTextAttributes]];
				[self setMarkedTextAttributes:[shared markedTextAttributes]];
				[self setSelectedTextAttributes:[shared selectedTextAttributes]];
				}
		}
#if 1
	NSLog(@"  self: %@", self);
#endif
	return self;
}

// FIXME: this method should expect SCREEN coordinates!!!
// FIXME: handle multiple text containers?

- (unsigned int) characterIndexForPoint:(NSPoint) pnt;
{
	float fraction;
	unsigned int gindex=[layoutManager glyphIndexForPoint:pnt inTextContainer:textContainer fractionOfDistanceThroughGlyph:&fraction];
	if(fraction > 0.5)
		gindex++;
	return [layoutManager characterIndexForGlyphAtIndex:gindex];	// convert to character index
}

- (void) insertText:(id) text;
{
	NSRange rng=[self selectedRange];
#if 1
	NSLog(@"insertText: %@", text);
#endif
	if([self shouldChangeTextInRange:rng replacementString:text])
		{
		NSDictionary *attribs=[typingAttributes retain];
		[self replaceCharactersInRange:rng withString:text];
		[self setAttributes:attribs range:rng];
		[attribs release];
		[self didChangeText];
		}
}

- (void) mouseDown:(NSEvent *) event
{ // run a text selection tracking loop
	NSRange initialRange;	// initial range (for extending selection)
	NSRange rng;					// current selected range
	unsigned int modifiers=[event modifierFlags];
	if(!_tx.selectable)
		return;	// ignore
	
	// handle ruler view
	
#if 1
	NSLog(@"NSTextView mouseDown");
#endif
	while(YES)	// loop outside until mouse goes up 
		{
		NSPoint p=[self convertPoint:[event locationInWindow] fromView:nil];
		// FIXME: this method expects SCREEN coordinates!
		unsigned int pos=[self characterIndexForPoint:p];	// convert to character index
#if 1
		NSLog(@"NSTextView mouseDown point=%@ pos=%d", NSStringFromPoint(p), pos);
#endif
		if([event type] == NSLeftMouseDown)
			{
			if([event clickCount] > 1 && NSLocationInRange(pos, _selectedRange))
				{ // in current range; we already hit the current selection -> it is a potential drag&drop
#if 1
					NSLog(@"multiclick %d", [event clickCount]);
#endif
					[self setSelectionGranularity:NSSelectByWord];
					rng=_selectedRange;	// default: unchanged
					switch([event clickCount]) {
						case 2:	// select word
							rng=[textStorage doubleClickAtIndex:pos];
							break;
						case 3: // select line
						case 4:	// select paragraph
						{
						NSString *str=[textStorage string];
						unsigned length=[str length];
						
						// FIXME: this is *wrong* lineBreakBeforeIndex returns a proposed position where a line break could be inserted (e.g. a space or puncuation).
						
						rng.location=[textStorage lineBreakBeforeIndex:pos withinRange:NSMakeRange(0, length)];
						rng.length=[str rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\n"] options:0 range:NSMakeRange(pos, length-pos)].location;
						if(rng.length == NSNotFound)
							rng.length = length-rng.location;
						else
							rng.length = rng.length-rng.location;
						}
						default:
							break;
					}
				}
			else if(modifiers&NSCommandKeyMask) // shift key
				rng=_selectedRange;
			else if(modifiers&NSShiftKeyMask) // shift key
				rng=NSUnionRange(_selectedRange, NSMakeRange(pos, 0));	// extend selection
			else
				{
				rng=NSMakeRange(pos, 0);	// default: set cursor to location where we did click
				if(pos < [textStorage length] && [[textStorage string] characterAtIndex:pos] == NSAttachmentCharacter)
					{ // click on text attachment
						NSTextAttachment *attachment=[textStorage attribute:NSAttachmentAttributeName atIndex:pos effectiveRange:NULL];
						id <NSTextAttachmentCell> cell=[attachment attachmentCell];
						if([cell wantsToTrackMouse])
							{
							NSRect rect=NSZeroRect;	// determine cell rect
							if([cell wantsToTrackMouseForEvent:event inRect:rect ofView:self atCharacterIndex:pos])
								{
								while([event type] != NSLeftMouseUp)
									{ // loop until mouse goes up
										if([cell trackMouse:event inRect:rect ofView:self atCharacterIndex:pos untilMouseUp:NO])
											break;	// tracking is done
										event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
																   untilDate:[NSDate distantFuture]						// get next event
																	  inMode:NSEventTrackingRunLoopMode 
																	 dequeue:YES];
									}
								return;
								}
							}
					}
				}
			initialRange=rng;
			}
		else
			{ // moved or up
				[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
				rng=NSUnionRange(initialRange, NSMakeRange(pos, 0));	// extend initial selection
			}
		if([event type] == NSLeftMouseUp)
			break;	// done with loop
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

- (void) setSelectedRange:(NSRange) range affinity:(NSSelectionAffinity) affinity stillSelecting:(BOOL) flag;
{
	if(_selectedRange.location == range.location && _selectedRange.length == range.length)
		return;	// no change
	[super setSelectedRange:range];
	if(!flag && layoutManager)
		{
		NSFont *attribs;
		[self updateInsertionPointStateAndRestartTimer:YES];	// will call _caretRect
		[self _updateTypingAttributes];
		_stableCursorColumn=_caretRect.origin.x;
		// send NSTextViewDidChangeSelectionNotification
		}
}

- (void) setSelectedRange:(NSRange)range;
{
	[self setSelectedRange:range affinity:NSSelectByCharacter stillSelecting:NO];
}

// override to guarantee stable cursor columns

- (void) moveUp:(id) sender
{
	if(_tx.fieldEditor)
		[super moveUp:sender];	// specific handling defined there
	else
		{
		float cx=_stableCursorColumn;	// save for cursor stability
		NSPoint p=NSMakePoint(cx, NSMinY([self _caretRect])-1.0);	// get new cursor position
		// FIXME: this method expects SCREEN coordinates!
		unsigned int pos=[self characterIndexForPoint:p];		// will go to start of document of p.y is negative
		if(pos != NSNotFound)
			[self setSelectedRange:NSMakeRange(pos, 0)];
		_stableCursorColumn=cx;	// restore for a sequence of moveUp/moveDown
		}
}

- (void) moveDown:(id) sender
{
	if(_tx.fieldEditor)
		[super moveUp:sender];	// specific handling defined there
	else
		{
		float cx=_stableCursorColumn;	// save for cursor stability
		NSPoint p=NSMakePoint(cx, NSMaxY([self _caretRect])+1.0);	// get new cursor position
		// FIXME: this method expects SCREEN coordinates!
		unsigned int pos=[self characterIndexForPoint:p];		// will go to end of document if p.y is beyond end of document
		if(pos != NSNotFound)
			[self setSelectedRange:NSMakeRange(pos, 0)];
		_stableCursorColumn=cx;	// restore for a sequence of moveUp/moveDown
		}
}

#if 0
#pragma mark NSUserInterfaceValidation
// NSUserInterfaceValidation

- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) item;
{
	return YES;
}
#endif

#pragma mark NSTextInputClient
// NSTextInputClient protocol

- (NSAttributedString *) attributedSubstringFromRange:(NSRange) range
{
	range=NSIntersectionRange(range, NSMakeRange(0, [[self textStorage] length]));
	if(range.length == 0)
		return nil;
	return [[self textStorage] attributedSubstringFromRange:range];
}

- (NSRect) firstRectForCharacterRange:(NSRange) range
{
	return [self firstRectForCharacterRange:range actualRange:NULL];
}

- (NSRect) firstRectForCharacterRange:(NSRange) range actualRange:(NSRangePointer) actual
{
	unsigned cnt;
	NSRectArray	r=[layoutManager rectArrayForGlyphRange:range withinSelectedGlyphRange:range inTextContainer:textContainer rectCount:&cnt];
	NSAssert(cnt > 0, @"zero count");
	return r[0];	// first
}

- (void) scrollRangeToVisible:(NSRange) range;
{
	[self scrollRectToVisible:[self firstRectForCharacterRange:range]];
}

- (BOOL) hasMarkedText; { return _markedRange.length > 0; }
- (NSRange) markedRange { return _markedRange; }
- (NSRange) selectedRange { return _selectedRange; }
- (void) unmarkText; { _markedRange=NSMakeRange(0, 0); /* redisplay */ }

- (NSInteger) conversationIdentifier
{
	return [[self textStorage] hash];
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
	// linkAttributes components are
	// NSUnderline -> NSNumber
	// NSCursor -> NSCursor (NSCursorType -> NSNumber, NSHotSpot -> NSString {8,-8})
	// NSColor -> NSColor
	linkAttributes=[[coder decodeObjectForKey:@"NSLinkAttributes"] retain];
	// NSBackgroundColor -> NSColor, NSColor -> NSColor
	markedAttributes=[[coder decodeObjectForKey:@"NSMarkedAttributes"] retain];
	selectedAttributes=[[coder decodeObjectForKey:@"NSSelectedAttributes"] retain];
	// FIXME:
	[coder decodeInt32ForKey:@"NSTextCheckingTypes"];
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
- (NSColor *) insertionPointColor { return insertionColor; }
- (NSParagraphStyle *) defaultParagraphStyle { return defaultParagraphStyle; }
- (NSDictionary *) linkTextAttributes { return linkAttributes; }
- (NSDictionary *) markedTextAttributes { return markedAttributes; }
- (NSDictionary *) selectedTextAttributes { return selectedAttributes; }

@end
