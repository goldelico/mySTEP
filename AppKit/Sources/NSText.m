/* 
   NSText.m

   The text class. It is directly working on its NSTextStorage and does not use a NSLayoutManager and/or NSTextContainer.
   Therefore, it has limited functionality compared to its subclass NSTextView. E.g.
   - does not handle most NSParagraphStyle attributes
   - less text manipulating methods
 
   NSTextView adds a text network and adds more sophisticated editing commands. Note: Interface Builder can be create NSTextView only.

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
#import <AppKit/NSTextView.h>	// to define NSSelectionGranularity

#import "NSAppKitPrivate.h"

#define NOTE(notice_name) NSText##notice_name##Notification

NSString *NSTextMovement=@"NSTextMovement";

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
{ // draw relevant lines
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

@implementation NSText

- (void) alignCenter:(id)sender;
{
	// change paragraph style for selection
}

- (void) alignLeft:(id)sender;
{
	// change paragraph style for selection
}

- (void) alignRight:(id)sender;
{
	// change paragraph style for selection
}

- (NSTextAlignment) alignment				{ return _tx.alignment; }
- (NSColor*) backgroundColor				{ return _backgroundColor; }
- (NSWritingDirection) baseWritingDirection;{ return _baseWritingDirection; }

- (void) changeFont:(id)sender;
{
	if(!_tx.usesFontPanel)
		return;
	// [self setFont: ];
}

- (void) changeSpelling:(id)sender;
{
	[self insertText:[[(NSControl*)sender selectedCell] stringValue]];
}

- (void) checkSpelling:(id)sender;						// Spelling
{
	int wordCount;
    NSRange range=[[NSSpellChecker sharedSpellChecker]
				checkSpellingOfString:[self string]
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

- (NSFont*) font;
{
	return NIMP;
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
		// convert to attributed string with current typing attributed and ... withAttributedString
		[textStorage replaceCharactersInRange:range withString:aString];
		}
	else
		[textStorage replaceCharactersInRange:range withString:aString];
	[self setNeedsDisplay:YES];
}

- (NSData*) RTFDFromRange:(NSRange)range; { return [textStorage RTFDFromRange:range documentAttributes:nil]; }
- (NSData*) RTFFromRange:(NSRange)range; { return [textStorage RTFFromRange:range documentAttributes:nil]; }

- (void) scrollRangeToVisible:(NSRange)range;
{
	NIMP;
}

- (void) selectAll:(id)sender;				{ _selectedRange=NSMakeRange(0, [[self string] length]); }
- (NSRange) selectedRange					{ return _selectedRange; }
- (void) setAlignment:(NSTextAlignment)mode	{ _tx.alignment = mode; }
- (void) setBackgroundColor:(NSColor*)color { ASSIGN(_backgroundColor,color); }
- (void) setBaseWritingDirection:(NSWritingDirection) direct; { _baseWritingDirection=direct; }

- (void) setDelegate:(id)anObject;
{
	_delegate=anObject;
}

- (void) setDrawsBackground:(BOOL)flag		{ _tx.drawsBackground = flag; }

- (void) setEditable:(BOOL)flag
{	
	if ((_tx.editable = flag)) 
		_tx.selectable = YES;					// If we are editable then 
}												// we are selectable

- (void) setFieldEditor:(BOOL)flag;
{
	if((_tx.fieldEditor=flag))
		{
		_tx.horzResizable = YES;
		_tx.vertResizable = NO;
		}
}

- (void) setFont:(NSFont*)obj;				{ [self setFont:obj range:NSMakeRange(0, [[self string] length])]; }

- (void) setFont:(NSFont*)font range:(NSRange)range;
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName] range:range];
	[self setNeedsDisplay:YES];
}

- (void) setHorizontallyResizable:(BOOL)flag;	{ _tx.horzResizable=flag; }

- (void) setImportsGraphics:(BOOL)flag
{	
	_tx.importsGraphics = flag;
	[self updateDragTypeRegistration];
}

- (void) setMaxSize:(NSSize)newMaxSize;		{ _maxSize=newMaxSize; }
- (void) setMinSize:(NSSize)newMinSize;		{ _minSize=newMinSize; }

- (void) setRichText:(BOOL)flag
{	
	if(_tx.isRichText == flag)
		return;
	_tx.isRichText=flag;
	[self updateDragTypeRegistration];
}

- (void) setSelectable:(BOOL)flag
{	
	if (!(_tx.selectable = flag)) 
		_tx.editable = NO;						// If we are not selectable 
}												// then we must not be editable

- (void) setSelectedRange:(NSRange)range;
{
	_selectedRange=range;
	[self setNeedsDisplay:YES];	// update display of selection
}

- (void) setString:(NSString *)string;
{
	// FIXME: should this reset the richText flag?
	// make sure to keep the formatting of the old first character
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:string];
	[self setSelectedRange:NSMakeRange([string length], 0)];	// to end of string
	_string=nil;	// clear cache
}

- (void) setTextColor:(NSColor*)color;		{ [self setTextColor:color range:NSMakeRange(0, [[self string] length])]; }

- (void) setTextColor:(NSColor*)color range:(NSRange)range;
{
	[textStorage setAttributes:[NSDictionary dictionaryWithObject:color forKey:NSForegroundColorAttributeName]
				  range:range];
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
	// NIMP;
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
	[[self typingAttributes] removeObjectForKey:NSUnderlineStyleAttributeName];
	[self setNeedsDisplay:YES];
}

- (BOOL) usesFontPanel						{ return _tx.usesFontPanel; }

- (BOOL) writeRTFDToFile:(NSString *)path atomically:(BOOL)flag;
{
	return [[self RTFDFromRange:NSMakeRange(0, [[self string] length])] writeToFile:path atomically:flag]; 
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
		{
		_spellCheckerDocumentTag=[NSSpellChecker uniqueSpellDocumentTag];
		textStorage=[NSTextStorage new];	// provide empty default text storage
		_tx.ownsTextStorage=YES;			// that we own
		_tx.alignment = NSLeftTextAlignment;
		_tx.editable = YES;
		_tx.isRichText = NO;				// default
		_tx.selectable = YES;
		_tx.vertResizable = YES;
		_tx.drawsBackground = YES;
		_backgroundColor=[[NSColor textBackgroundColor] retain];
		_minSize = (NSSize){5, 15};
		_maxSize = (NSSize){HUGE,HUGE};		
		[self setString:@"NSText"];	// will set rich text to NO
		[self setSelectedRange:NSMakeRange(0,0)];
		}
	return self;
}

- (void) dealloc;
{
	if(_tx.ownsTextStorage)
		[textStorage release];
	[super dealloc];
}

- (BOOL) isFlipped 							{ return YES; }
- (BOOL) isOpaque							{ return _tx.drawsBackground; }

- (void) drawRect:(NSRect)rect
{ // default drawing within frame bounds using string drawing additions (and no typesetter/layout manager)
	if(_tx.drawsBackground)
		{
		[_backgroundColor set];
		NSRectFill(rect);
		}
#if 0
	NSLog(@"NSText drawRect with %@", textStorage);
#endif
	// draw selection or simple line cursor
	[textStorage drawInRect:bounds];
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return (id)self == (id)[[self window] firstResponder]; }

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

- (void) insertText:(NSString *) text;
{
	NSRange rng=[self selectedRange];
	[self replaceCharactersInRange:rng withString:text];
	rng.location+=[text length];
	rng.length=0;
	[self setSelectedRange:rng];
}

- (void) insertNewline:(id) sender
{
	NSEvent *event = [NSApp currentEvent];
	if([event keyCode] == 76)
		[self insertText:@"\n"];	// new paragraph
	else
		[self insertText:@"\n"];	// new line
}

- (void) keyDown:(NSEvent *)event
{ // default action (last responder) - here we should interpret keyboard shortcuts
	NSLog(@"%@ keyDown: %@", NSStringFromClass(isa), event);
	// we could try to de-queue sequences of key events
	[self interpretKeyEvents:[NSArray arrayWithObject:event]];
}

- (void) interpretKeyEvents:(NSArray *) events;
{
	if(_tx.fieldEditor)
		{
		// handle return, escape, tab, arrow keys differently
		}
	[super interpretKeyEvents:events];
}

- (void) mouseDown:(NSEvent *)event
{
	NSLog(@"%@ mouseDown: %@", NSStringFromClass(isa), event);
	// handle mouse down for selection
}

- (BOOL) acceptsFirstResponder					{ return _tx.selectable; }
- (BOOL) acceptsFirstMouse:(NSEvent *)event		{ return _tx.fieldEditor; }

- (BOOL) becomeFirstResponder
{	
	if(!_tx.editable) 
		return NO;	
	if(_delegate && [_delegate respondsToSelector:@selector(textShouldBeginEditing:)]
		&& ![_delegate textShouldBeginEditing:self])
		return NO;	// delegate did a veto
//	
//	if((__caretBlinkTimer == nil) && (_selectedRange.length == 0))
//		[self _startCaretBlinkTimer];
//	reason=NSCancelTextMovement;	// set default reason
	[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:NOTE(DidBeginEditing) object:self]];
	return YES;
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
		_tx.ownsTextStorage=YES;			// that we own
		_tx.alignment = NSLeftTextAlignment;
		_tx.editable = YES;
		_tx.isRichText = NO;				// default
		_tx.selectable = YES;
		_tx.vertResizable = YES;
		_tx.drawsBackground = YES;
		_backgroundColor=[[NSColor textBackgroundColor] retain];
		[self setString:@"NSText"];	// will set rich text to NO
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
