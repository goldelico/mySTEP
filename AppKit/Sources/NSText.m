/* 
   NSText.m

   The text class. It is directly working on its NSTextStorage and does not use a NSLayoutManager and/or NSTextContainer.
   Therefore, it has limited functionality compared to its subclass NSTextView. E.g.
	 - less precise text manipulating methods
 
   NSTextView adds a text network and adds more sophisticated editing commands. Note: Interface Builder can create NSTextView only.

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006 - aligned with 10.4
  
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSArchiver.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRange.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSScanner.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSAutoreleasePool.h>

#import <AppKit/NSButton.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSText.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSFileWrapper.h>
#import <AppKit/NSFontPanel.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSSpellChecker.h>
#import <AppKit/NSDragging.h>
#import <AppKit/NSStringDrawing.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSTextView.h>	// defines NSSelectionGranularity

#import "NSAppKitPrivate.h"

#define NOTE(notice_name) NSText##notice_name##Notification

NSString *NSTextMovement=@"NSTextMovement";

#if JUST_AN_IDEA

// FIXME: this is not yet used!!!

@interface _NSTextLineLayoutInformation
{ // there is one record per text line
	_NSTextLineLayoutInformation *prev, *next;	// linked list
	NSTextStorage *textStorage;
	NSParagraphStyle *paragraphStyle;	// paragraph style (e.g. left/right alignment etc.)
	NSRect lineFrame;					// frame rect
	NSRange characterRange;				// range of characters of this line
	BOOL isValid;
}

- (NSTextStorage *) textStorage;
- (NSParagraphStyle *) paragraphStyle;
- (NSRect) lineFrame;
- (NSRange) characterRange;
- (BOOL) isValid;
- (void) sizeToFit;

- (NSRange) charactersForRect:(NSRect) rect;	// find relevant character positions
- (void) drawInRect:(NSRect) rect;	// draw relevant lines
- (void) invalidateCharactersInRange:(NSRange) range;	// invalidate line info

@end

@implementation _NSTextLineLayoutInformation

- (NSTextStorage *) textStorage; { return textStorage; }
- (NSParagraphStyle *) paragraphStyle; { return paragraphStyle; }
- (NSRect) lineFrame; { return lineFrame; }
- (NSRange) characterRange; { return characterRange; }
- (BOOL) isValid; { return isValid; }

- (void) sizeToFit;
{ // determine size and adjust lines above/below as needed
}

- (NSRange) charactersForRect:(NSRect) rect;
{ // find relevant character positions in array of _NSTextLineLayoutInformation records
	_NSTextLineLayoutInformation *i=self;
	NSRange rng;
	while(prev)
		{ // find first intersecting lines in rect above myself
		if(!i->isValid)
			[i sizeToFit];
		if(!NSIntersectsRect(i->lineFrame, rect))
			break;
		i=i->prev;
		}
	rng.location=i->characterRange.location;	// account for horizontal position!
	while(i)
		{
		if(!i->isValid)
			[i sizeToFit];
		if(!NSIntersectsRect(i->lineFrame, rect))
			break;
		i=i->next;
		}
	// set rng.length based on horiz. position
	return rng;
}

- (void) drawInRect:(NSRect) rect;
{ // draw relevant lines that intersect the rect
	_NSTextLineLayoutInformation *i=self;
	// clip to rect
	while(prev)
		{ // find first intersecting lines in rect above myself
		if(!i->isValid)
			[i sizeToFit];
		if(!NSIntersectsRect(i->lineFrame, rect))
			break;
		i=i->prev;
		}
	while(i)
		{ // draw lines as long as they are within rect
		if(!i->isValid)
			[i sizeToFit];
		if(!NSIntersectsRect(i->lineFrame, rect))
			break;
		[[textStorage attributedSubstringFromRange:i->characterRange] drawInRect:i->lineFrame];
		i=i->next;
		}
}

- (void) invalidateCharactersInRange:(NSRange) range;
{ // invalidate line info
	// find first relevant line
}

@end

#endif

@implementation NSText

- (NSParagraphStyle *) defaultParagraphStyle { return [NSParagraphStyle defaultParagraphStyle]; }	// inofficial - overwritten in NSTextView

- (void) alignCenter:(id)sender;
{
	[self setAlignment:NSCenterTextAlignment];
}

- (void) alignLeft:(id)sender;
{
	[self setAlignment:NSLeftTextAlignment];
}

- (void) alignRight:(id)sender;
{
	[self setAlignment:NSRightTextAlignment];
}

- (NSTextAlignment) alignment
{
	if(_tx.isRichText)
		return [[textStorage attribute:NSParagraphStyleAttributeName atIndex:0 effectiveRange:NULL] alignment];	// first paragraph
	return _tx.alignment;
}

- (NSColor*) backgroundColor				{ return _backgroundColor; }

- (NSWritingDirection) baseWritingDirection;{ return _baseWritingDirection; }

- (void) changeColor:(id)sender;
{ // color panel
	// how can we change the background color?
	[self setTextColor:[sender color]];
}

- (void) changeFont:(id)sender;
{ // font panel
	NSRange rng=_tx.isRichText?_selectedRange:NSMakeRange(0, [textStorage length]);
	NSRange effectiveRange=rng;
	if(!_tx.usesFontPanel)
		return;
	while(effectiveRange.location < NSMaxRange(rng))
			{ // loop over all segments we get
				NSFont *font=[textStorage attribute:NSFontAttributeName atIndex:effectiveRange.location effectiveRange:&effectiveRange];
				if(font)
						{
							font=[sender convertFont:font];	// convert through font panel
							if(font)
								[textStorage addAttribute:NSFontAttributeName value:font range:effectiveRange];
						}
				effectiveRange.location=NSMaxRange(effectiveRange);	// go to next range
			}
}

- (void) changeSpelling:(id)sender;
{
	[self insertText:[[(NSControl*)sender selectedCell] stringValue]];
}

- (void) checkSpelling:(id)sender;						// Spelling
{
	int wordCount;
    NSRange range=[[NSSpellChecker sharedSpellChecker]
				checkSpellingOfString:[textStorage string]
						   startingAt:NSMaxRange(_selectedRange)
							 language:nil
								 wrap:NO
			   inSpellDocumentWithTag:_spellCheckerDocumentTag
							wordCount:&wordCount];
	if(range.length) 
		[self setSelectedRange:range];
	else 
		NSBeep();
}

- (void) copy:(id)sender;
{
	NIMP;
}

- (void) copyFont:(id)sender;
{
	NIMP;
}

- (void) copyRuler:(id)sender;
{
	NIMP;
}

- (void) cut:(id)sender;
{
	NIMP;
}

- (id) delegate;							{ return _delegate; }

- (void) delete:(id)sender;
{
	NIMP;
}

- (BOOL) drawsBackground					{ return _tx.drawsBackground; }

- (NSFont *) font;
{
	return _font;	// should be the font of the insertion point
}

- (void) ignoreSpelling:(id)sender
{
    [[NSSpellChecker sharedSpellChecker]
					ignoreWord:[[sender selectedCell] stringValue]
		inSpellDocumentWithTag:_spellCheckerDocumentTag];
}

- (BOOL) importsGraphics					{ return _tx.importsGraphics; }
- (BOOL) isEditable							{ return _tx.editable; }
- (BOOL) isFieldEditor;						{ return _tx.fieldEditor; }
- (BOOL) isHorizontallyResizable;			{ return _tx.horzResizable; }
- (BOOL) isRichText							{ return _tx.isRichText; }
- (BOOL) isRulerVisible						{ return _tx.rulerVisible; }
- (BOOL) isSelectable						{ return _tx.selectable; }
- (BOOL) isVerticallyResizable;				{ return _tx.vertResizable; }
- (NSSize) maxSize;							{ return _maxSize; }
- (NSSize) minSize;							{ return _minSize; }

- (void) paste:(id)sender;
{
	NIMP;
}

- (void) pasteFont:(id)sender;
{
	NIMP;
}

- (void) pasteRuler:(id)sender;
{
	NIMP;
}

- (BOOL) readRTFDFromFile:(NSString *)path;
{
	NSAttributedString *as;
	NSDictionary *docAttributes;
	as=[[NSAttributedString alloc] initWithPath:path documentAttributes:&docAttributes];
	if(as)
		{
		[textStorage setAttributedString:as];
		[as release];
		return YES;
		}
	return NO;
}

- (void) replaceCharactersInRange:(NSRange)range withRTF:(NSData *)rtfData;
{
	NIMP;
}

- (void) replaceCharactersInRange:(NSRange)range withRTFD:(NSData *)rtfdData;
{
	// read into new attributed string and replace...: withAttributedString:
	NIMP;
}

- (void) replaceCharactersInRange:(NSRange)range withString:(NSString*) aString;
{
	if(_tx.isRichText)
		{
			NSAttributedString *a=[[NSAttributedString alloc] initWithString:aString attributes:[NSDictionary dictionaryWithObject:_font forKey:NSFontAttributeName]];
			[textStorage replaceCharactersInRange:range withAttributedString:a];
			[a release];
		}
	else
		[textStorage replaceCharactersInRange:range withString:aString];
	[self setNeedsDisplay:YES];
}

- (NSData*) RTFDFromRange:(NSRange) range; { return [textStorage RTFDFromRange:range documentAttributes:nil]; }
- (NSData*) RTFFromRange:(NSRange) range; { return [textStorage RTFFromRange:range documentAttributes:nil]; }

- (void) scrollRangeToVisible:(NSRange) range;
{
	NIMP;
}

- (void) selectAll:(id)sender;				{ _selectedRange=NSMakeRange(0, [textStorage length]); }
- (NSRange) selectedRange					{ return _selectedRange; }

- (void) setAlignment:(NSTextAlignment)mode
{
	if([textStorage length] == 0)
		return;
	// range should be full document if we are not richt text
	NSRange rng=_selectedRange;
	NSMutableParagraphStyle *p=[textStorage attribute:NSParagraphStyleAttributeName atIndex:rng.location effectiveRange:NULL];
	if(!p) p=[[[self defaultParagraphStyle] mutableCopy] autorelease];
	[p setAlignment:mode];
	[textStorage addAttribute:NSParagraphStyleAttributeName value:p range:rng];
	_tx.alignment = mode; 
}

- (void) setBackgroundColor:(NSColor*)color { ASSIGN(_backgroundColor,color); }

- (void) setBaseWritingDirection:(NSWritingDirection) direct;
{
	if([textStorage length] == 0)
		return;
	// range should be full document if we are not richt text
	NSRange rng=_selectedRange;
	NSMutableParagraphStyle *p=[textStorage attribute:NSParagraphStyleAttributeName atIndex:rng.location effectiveRange:NULL];
	if(!p) p=[[[self defaultParagraphStyle] mutableCopy] autorelease];
	[p setBaseWritingDirection:direct];
	[textStorage addAttribute:NSParagraphStyleAttributeName value:p range:rng];
	_baseWritingDirection=direct;
}

- (void) setDelegate:(id)anObject;
{ // make the delegate observe our notifications
	NSNotificationCenter *n;
	
	if(_delegate == anObject)
		return;	// unchanged
	
#define IGNORE_(notif_name) [n removeObserver:_delegate \
name:NSText##notif_name##Notification \
object:self]
	
	n = [NSNotificationCenter defaultCenter];
	if (_delegate)
			{
				IGNORE_(DidEndEditing);
				IGNORE_(DidBeginEditing);
				IGNORE_(DidChange);
			}
	
	ASSIGN(_delegate, anObject);
	if(anObject)
			{
#define OBSERVE_(notif_name) \
if ([_delegate respondsToSelector:@selector(text##notif_name:)]) \
[n addObserver:_delegate \
selector:@selector(text##notif_name:) \
name:NSText##notif_name##Notification \
object:self]
				
				OBSERVE_(DidEndEditing);
				OBSERVE_(DidBeginEditing);
				OBSERVE_(DidChange);
			}
}

- (void) setDrawsBackground:(BOOL)flag		{ _tx.drawsBackground = flag; }

- (void) setEditable:(BOOL)flag
{	
	if ((_tx.editable = flag)) 
		_tx.selectable = YES;					// If we are editable then we are selectable
}

- (void) setFieldEditor:(BOOL)flag;
{
	if((_tx.fieldEditor=flag))
		{
		_tx.horzResizable = YES;
		_tx.vertResizable = NO;
		}
}

- (void) setFont:(NSFont *)obj;
{
	ASSIGN(_font, obj);
	if(!_tx.isRichText)
		[self setFont:obj range:NSMakeRange(0, [textStorage length])];	// change for whole document
	else
		[self setFont:obj range:_selectedRange];	// change for selection
}

- (void) setFont:(NSFont *)font range:(NSRange)range;
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName] range:range];
	[self setNeedsDisplay:YES];
}

- (void) setHorizontallyResizable:(BOOL)flag;	{ _tx.horzResizable=flag; }

- (void) setImportsGraphics:(BOOL)flag
{	
	_tx.importsGraphics = flag;
}

- (void) setMaxSize:(NSSize)newMaxSize;		{ _maxSize=newMaxSize; }
- (void) setMinSize:(NSSize)newMinSize;		{ _minSize=newMinSize; }

- (void) setRichText:(BOOL)flag
{	
	if(_tx.isRichText == flag)
		return;
	_tx.isRichText=flag;
	// do other modifications
}

- (void) setSelectable:(BOOL)flag
{	
	if (!(_tx.selectable = flag)) 
		_tx.editable = NO;						// If we are not selectable 
}												// then we must not be editable

- (void) setSelectedRange:(NSRange)range;
{
	if(!NSEqualRanges(_selectedRange, range))
			{
				// FIXME: setNeedsDisplayInRect: of previous selection
				_selectedRange=range;
				// setNeedsDisplayInRect: of new selection
				[self setNeedsDisplay:YES];	// update display of selection
			}
	_tx.moveLeftRightEnd=0;
	_tx.moveUpDownEnd=0;
#if 1
	NSLog(@"setSelectedRange=%@", NSStringFromRange(_selectedRange));
	NSLog(@"  text=%@", textStorage);
#endif
}

- (void) setString:(NSString *)string;
{
	_tx.isRichText=NO;
	// make sure to keep the formatting of the old first character
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:string];
	[self setSelectedRange:NSMakeRange([string length], 0)];	// to end of string
	_string=nil;	// clear cache
}

- (void) setTextColor:(NSColor*)color;
{
	[self setTextColor:color range:NSMakeRange(0, [textStorage length])];
}

- (void) setTextColor:(NSColor*)color range:(NSRange)range;
{
	if(color)
		[textStorage addAttribute:NSForegroundColorAttributeName value:color range:range];
	else
		[textStorage removeAttribute:NSForegroundColorAttributeName range:range];
	[self setNeedsDisplay:YES];
}

- (void) setUsesFontPanel:(BOOL)flag		{ _tx.usesFontPanel = flag; }
- (void) setVerticallyResizable:(BOOL)flag;	{ _tx.vertResizable=flag; }

- (void) showGuessPanel:(id)sender;
{
	[[[NSSpellChecker sharedSpellChecker] spellingPanel] makeKeyAndOrderFront:sender];
}

- (void) sizeToFit;
{
	NSRect rect=(NSRect) { NSZeroPoint, [textStorage size] };	// ask the text storage for the size
	if(!_tx.horzResizable)
		rect.size.width=_bounds.size.width;	// don't resize horizontally
	if(!_tx.vertResizable)
		rect.size.height=_bounds.size.height;	// don't resize vertically
	rect=NSUnionRect(rect, (NSRect) { NSZeroPoint, _minSize });
	rect=NSIntersectionRect(rect, (NSRect) { NSZeroPoint, _maxSize });
	[self setFrame:rect];	// adjust to be between min and max size
}

- (NSString *) string;
{
	if(!_string)
		{
		_string=[textStorage string];
		// strip out any text attachment characters!
		}
	return _string;
}

- (void) subscript:(id)sender;
{
	if(!_tx.isRichText)
		return;
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:1]
													forKey:NSSuperscriptAttributeName]
				  range:_selectedRange];
	[self setNeedsDisplay:YES];
}

- (void) superscript:(id)sender;
{
	if(!_tx.isRichText)
		return;
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:-1]
													forKey:NSSuperscriptAttributeName]
				  range:_selectedRange];
	[self setNeedsDisplay:YES];
}

- (NSColor *) textColor;
{
	// get of first character or insertion point
	return NIMP;
}

- (void) toggleRuler:(id)sender
{
	_tx.rulerVisible = !_tx.rulerVisible;
}

- (void) underline:(id)sender;
{
	if(!_tx.isRichText)
		return;
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:NSUnderlineStyleSingle]
													forKey:NSUnderlineStyleAttributeName]
				  range:_selectedRange];
	[self setNeedsDisplay:YES];
}

- (void) unscript:(id)sender;
{
	if(!_tx.isRichText)
		return;
	[textStorage removeAttribute:NSUnderlineStyleAttributeName 
						  range:_selectedRange];
	// typingAttributes is only known in NSTextView!
//	[[self typingAttributes] removeObjectForKey:NSUnderlineStyleAttributeName];
	[self setNeedsDisplay:YES];
}

- (BOOL) usesFontPanel						{ return _tx.usesFontPanel; }

- (BOOL) writeRTFDToFile:(NSString *)path atomically:(BOOL)flag;
{
	return [[self RTFDFromRange:NSMakeRange(0, [textStorage length])] writeToFile:path atomically:flag]; 
}

// overridden methods

+ (void) initialize
{
	if (self == [NSText class])
		{
		NSArray	*r = [NSArray arrayWithObjects: NSStringPboardType, nil];
		NSArray	*s = [NSArray arrayWithObjects: NSStringPboardType, nil];
		[NSApp registerServicesMenuSendTypes:s returnTypes:r];
		}
}

- (id) initWithFrame:(NSRect) f
{
#if 0
	NSLog(@"%@ initWithFrame:%@", NSStringFromClass([self class]), NSStringFromRect(f));
#endif
	if((self=[super initWithFrame:f]))
		{ // this initialization will be used for a Field Editor
		_spellCheckerDocumentTag=[NSSpellChecker uniqueSpellDocumentTag];
		textStorage=[NSTextStorage new];	// provide empty default text storage
		_tx.ownsTextStorage=YES;			// that we own
		_tx.alignment = NSLeftTextAlignment;
		_tx.editable = YES;
//		_tx.isRichText = NO;				// default
		_tx.selectable = YES;
		_tx.vertResizable = YES;
		_tx.drawsBackground = YES;
		_backgroundColor=[[NSColor textBackgroundColor] retain];
		_minSize = (NSSize){5, 15};
		_maxSize = (NSSize){HUGE,HUGE};
			_font=[[NSFont userFontOfSize:12] retain];
		[self setString:@""];	// this will set rich text to NO
		[self setSelectedRange:NSMakeRange(0,0)];
		}
	return self;
}

- (void) dealloc;
{
	if(_tx.ownsTextStorage)
		[textStorage release];
	[_backgroundColor release];
	[_font release];
	[_delegate release];	// has been ASSIGNed
//	[_string release];
	[super dealloc];
}

- (BOOL) isFlipped 							{ return YES; }
- (BOOL) isOpaque							{ return _tx.drawsBackground; }

- (void) drawRect:(NSRect)rect
{ // default drawing within frame bounds using string drawing additions (and no typesetter/layout manager) - overridden in NSTextView
	if(_tx.drawsBackground)
		{
		[_backgroundColor set];
		NSRectFill(rect);
		}
#if 0
	NSLog(@"NSText drawRect with %@", textStorage);
#endif
	// draw selection or simple line cursor
	[textStorage drawInRect:_bounds];
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return (id)self == (id)[[self window] firstResponder]; }

- (void) insertText:(id) text;
{
	NSRange rng=[self selectedRange];
#if 1
	NSLog(@"insertText: %@", text);
#endif
	if([text isKindOfClass:[NSString class]])
		[self replaceCharactersInRange:rng withString:text];
	else
		[textStorage replaceCharactersInRange:rng withAttributedString:text];
	rng.location+=[(NSString *) text length];	// advance selection
	rng.length=0;
	[self setSelectedRange:rng];
}

- (unsigned int) characterIndexForPoint:(NSPoint) pnt;
{
	return NSNotFound;	// i.e. outside of all characters
}

- (void) mouseDown:(NSEvent *)event
{ // simple mouse down mechanism
	NSRange rng;	// current selected range
#if 1
	NSLog(@"%@ mouseDown: %@", NSStringFromClass(isa), event);
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
				// unsigned int pos=[self characterIndexForPoint:p];
				unsigned int pos=0;
#if 0
				NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
				// handle click on NSTextAttachments
				if(NSLocationInRange(pos, _selectedRange))
						{ // in current range we already hit the current selection it is a potential drag&drop
							rng=_selectedRange;
						}
				else if(1) // no modifier
					rng=NSMakeRange(pos, 0);	// set cursor to location where we did click
				else if(0) // shift key
					rng=NSUnionRange(_selectedRange, NSMakeRange(pos, 0));	// extend
				[self setSelectedRange:rng];
				event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
																	 untilDate:[NSDate distantFuture]						// get next event
																			inMode:NSEventTrackingRunLoopMode 
																		 dequeue:YES];
				
  		}
	[self setSelectedRange:rng];	// finally update selection
#if 1
	NSLog(@"NSText mouseDown up");
#endif	
}

- (void) keyDown:(NSEvent *)event
{ // default action (last responder)
	if(_tx.editable)
			{
				// FIXME: shouldn't this be done in NSWindow?
				// and handle keyboard shortcuts there?
				NSMutableArray *events=[NSMutableArray arrayWithObject:event];
#if 1
				NSLog(@"%@ keyDown: %@", NSStringFromClass(isa), event);
#endif
				while((event = [NSApp nextEventMatchingMask:NSAnyEventMask
																					untilDate:nil	// don't wait
																						 inMode:NSEventTrackingRunLoopMode 
																						dequeue:YES]))
						{ // collect all queued keyboard events - and stop collecting if any other event is found
							switch([event type])
								{
									case NSKeyDown:
										[events addObject:event];	// queue them up
										continue;
									case NSKeyUp:
									case NSFlagsChanged:
										continue;
									default:	// any other event
										[NSApp postEvent:event atStart:YES];	// requeue
										break;
								}
							break;
						}
				[self interpretKeyEvents:events];
			}
	else
		[super keyDown:event];
}

// keyboard actions

- (void) deleteBackward:(id) sender;
{
	NSRange rng=[self selectedRange];
	if(rng.length == 0)
			{
				if(rng.location == 0)
					return;	// ignore at beginning of text
				rng.location--;
				rng.length=1;
			}
	[self replaceCharactersInRange:rng withString:@""];	// remove
	rng.length=0;
	[self setSelectedRange:rng];
}

- (void) _handleFieldEditorMovement:(int) move
{ // post field editor notification
	[[NSNotificationCenter defaultCenter] postNotification:
		[NSNotification notificationWithName:NOTE(DidEndEditing) 
																	object:self
																userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:move] forKey:NSTextMovement]]];
}

- (void) cancelOperation:(id) sender
{ // bound to ESC key?
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSCancelTextMovement];
	// insert ESC?
}

- (void) insertNewlineIgnoringFieldEditor:(id) sender
{
	[self insertText:@"\n"];	// new paragraph
}

- (void) insertNewline:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSReturnTextMovement];
	else
		[self insertNewlineIgnoringFieldEditor:sender];
}

- (void) insertTabIgnoringFieldEditor:(id) sender
{
	[self insertText:@"\t"];	// new tab
}

- (void) insertTab:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSTabTextMovement];
	else
		[self insertTabIgnoringFieldEditor:sender];
}

- (void) insertBackTab:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSBacktabTextMovement];
	else
		[self insertText:@">back tab<"];	// new backtab
}

- (void) moveUp:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSUpTextMovement];
	else
	// should go up one line in same column
		NIMP;
}

- (void) moveDown:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSDownTextMovement];
	else
	// should go down one line in same column
		NIMP;
}

- (void) moveRight:(id) sender
{
	if(NO && _tx.fieldEditor)
			{
				[self _handleFieldEditorMovement:NSRightTextMovement];
				return;
			}
	if(NSMaxRange(_selectedRange) < [textStorage length])
		[self setSelectedRange:NSMakeRange(NSMaxRange(_selectedRange)+1, 0)];
}

// same for top&down but use separate flags - can share left&right

- (void) moveRightAndModifySelection:(id) sender
{
	int saved;
	if(_tx.moveLeftRightEnd == 0)
			{
				modifySelection[0]=_selectedRange.location;
				modifySelection[1]=NSMaxRange(_selectedRange);
				_tx.moveLeftRightEnd=2;	// modify right end...
			}
	if(modifySelection[_tx.moveLeftRightEnd-1] < [textStorage length])
		(modifySelection[_tx.moveLeftRightEnd-1])++;
	saved=_tx.moveLeftRightEnd;
	[self setSelectedRange:NSUnionRange(NSMakeRange(modifySelection[0], 0), NSMakeRange(modifySelection[1], 0))];	// sets _tx.moveLeftRightEnd=0;
	_tx.moveLeftRightEnd=saved;
}

- (void) moveForwardAndModifySelection:(id) sender
{
	// check for writing direction
	[self moveRightAndModifySelection:sender];
}

- (void) moveLeft:(id) sender
{
	if(NO && _tx.fieldEditor)
			{
				[self _handleFieldEditorMovement:NSLeftTextMovement];
				return;
			}
	if(_selectedRange.location > 0)
		[self setSelectedRange:NSMakeRange(_selectedRange.location-1, 0)];
}

- (void) moveLeftAndModifySelection:(id) sender
{
	int saved;
	if(_tx.moveLeftRightEnd == 0)
		{
				modifySelection[0]=_selectedRange.location;
				modifySelection[1]=NSMaxRange(_selectedRange);
				_tx.moveLeftRightEnd=1;	// modify left end
		}
	if(modifySelection[_tx.moveLeftRightEnd-1] > 0)
		(modifySelection[_tx.moveLeftRightEnd-1])--;
	saved=_tx.moveLeftRightEnd;
	[self setSelectedRange:NSUnionRange(NSMakeRange(modifySelection[0], 0), NSMakeRange(modifySelection[1], 0))];	// sets _tx.moveLeftRightEnd=0;
	_tx.moveLeftRightEnd=saved;
}

- (void) moveBackwardAndModifySelection:(id) sender
{
	[self moveLeftAndModifySelection:sender];
}

- (void) moveDownAndModifySelection:(id) sender
{
	int saved;
	if(_tx.moveUpDownEnd == 0)
			{
				modifySelection[0]=_selectedRange.location;
				modifySelection[1]=NSMaxRange(_selectedRange);
				_tx.moveUpDownEnd=2;	// modify bottom end
			}
	if(modifySelection[_tx.moveUpDownEnd-1] < [textStorage length])
		(modifySelection[_tx.moveUpDownEnd-1])++;	// should move one line down!
	saved=_tx.moveUpDownEnd;
	[self setSelectedRange:NSUnionRange(NSMakeRange(modifySelection[0], 0), NSMakeRange(modifySelection[1], 0))];	// sets _tx.moveUpDownEnd=0;
	_tx.moveUpDownEnd=saved;
}

- (void) moveUpAndModifySelection:(id) sender
{
	int saved;
	if(_tx.moveUpDownEnd == 0)
			{
				modifySelection[0]=_selectedRange.location;
				modifySelection[1]=NSMaxRange(_selectedRange);
				_tx.moveUpDownEnd=1;	// modify top end
			}
	if(modifySelection[_tx.moveUpDownEnd-1] > 0)
		(modifySelection[_tx.moveUpDownEnd-1])--;	// should move one line up
	saved=_tx.moveUpDownEnd;
	[self setSelectedRange:NSUnionRange(NSMakeRange(modifySelection[0], 0), NSMakeRange(modifySelection[1], 0))];	// sets _tx.moveLeftRightEnd=0;
	_tx.moveUpDownEnd=saved;
}

- (BOOL) acceptsFirstResponder					{ return _tx.selectable; }
- (BOOL) needsPanelToBecomeKey					{ return _tx.editable; }
- (BOOL) acceptsFirstMouse:(NSEvent *)event		{ return _tx.fieldEditor; }

- (BOOL) becomeFirstResponder
{	
	if(!_tx.editable) 
		return NO;	
	if(_delegate && [_delegate respondsToSelector:@selector(textShouldBeginEditing:)]
		&& ![_delegate textShouldBeginEditing:self])
		return NO;	// delegate did a veto
	// FIXME: doc says that it should only be sent if there is the first change!
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:NOTE(DidBeginEditing) object:self]];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSOrderFrontCharacterPalette"])
		[NSApp orderFrontCharacterPalette:self];	// automatically show keyboard if automatism is enabld
	return YES;
}

- (BOOL) resignFirstResponder
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSCancelTextMovement];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSOrderFrontCharacterPalette"])
		[NSApp _orderOutCharacterPalette:self];	// automatically hide keyboard if automatism is enabled
	return [super resignFirstResponder];
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"[NSText] %@ initWithCoder: %@", self, coder);
#endif
	if((self=[super initWithCoder:coder]))
		{
		int tvFlags=[coder decodeInt32ForKey:@"NSTVFlags"];	// do we have these in NSText or NSTextView?

		
		_spellCheckerDocumentTag=[NSSpellChecker uniqueSpellDocumentTag];
		textStorage=[NSTextStorage new];	// provide empty default text storage
		
		// FIXME: decode from tvFlags!
		
		_tx.ownsTextStorage=YES;			// that we own
		_tx.alignment = NSLeftTextAlignment;
		_tx.editable = YES;
		_tx.isRichText = NO;				// default
		_tx.selectable = YES;
		_tx.vertResizable = YES;
		_tx.drawsBackground = YES;
		_backgroundColor=[[NSColor textBackgroundColor] retain];
		[self setString:@""];	// will set rich text to NO
		[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
		_minSize=[coder decodeSizeForKey:@"NSMinize"];	// NB: this is a bug in Apple IB: key should be @"NSMinSize" - beware of changes by Apple
		_maxSize=[coder decodeSizeForKey:@"NSMaxSize"];
		}
	return self;
}

@end

@implementation NSText (NSPrivate)

- (BOOL) _isSecure								{ return _tx.secure; }
- (void) _setSecure:(BOOL)flag					{ _tx.secure = flag; }
- (NSTextStorage *) _textStorage;				{ return textStorage; }		// the private text storage

@end
