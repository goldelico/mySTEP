/* 
 NSText.m
 
 The text class. It is directly working on its NSTextStorage and does not use a NSLayoutManager and/or NSTextContainer.
 Therefore, it has limited functionality compared to its subclass NSTextView. E.g.
 - less precise text manipulating methods
 - can't format and handle lines of different font
 
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
#import <AppKit/NSClipView.h>
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
{ // called by color panel
	// how can we change the background color?
	// probably we can decode the sender
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
	NSRange rng=[self selectedRange];
	if(rng.length > 0)
		{
		NSAttributedString *str=[textStorage attributedSubstringFromRange:rng];
		[[NSPasteboard generalPasteboard] setString:[str string] forType:NSStringPboardType];
		}
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
	[self copy:sender];
	[self deleteBackward:sender];
}

- (id) delegate;							{ return _delegate; }

- (void) delete:(id)sender;
{
	[self deleteBackward:sender];
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
	NSPasteboard *pb=[NSPasteboard generalPasteboard];
	// FIXME: NSAttributedString
	// NSRTFPboardType?
	NSString *paste=[pb stringForType:NSStringPboardType];	// get string to paste
	[self insertText:paste];
}

- (void) pasteAsPlainText:(id) sender
{
	NSPasteboard *pb=[NSPasteboard generalPasteboard];
	NSString *paste=[pb stringForType:NSStringPboardType];	// get string to paste
	[self insertText:paste];
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
	[self scrollRectToVisible:NSZeroRect];	// should be the line rect
}

- (void) selectAll:(id)sender;				{ [self setSelectedRange:NSMakeRange(0, [textStorage length])]; }
- (NSRange) selectedRange					{ return _selectedRange; }

- (void) setAlignment:(NSTextAlignment)mode
{
	if([textStorage length] == 0)
		return;
	// range should be full document if we are not richt text
	NSRange rng=_selectedRange;
	NSMutableParagraphStyle *p=[textStorage attribute:NSParagraphStyleAttributeName atIndex:rng.location effectiveRange:NULL];
	if(!p) p=(NSMutableParagraphStyle *) [self defaultParagraphStyle];
	if(![p isKindOfClass:[NSMutableParagraphStyle class]]) p=[[p mutableCopy] autorelease];	// make mutable
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
	if(!p) p=(NSMutableParagraphStyle *) [self defaultParagraphStyle];
	if(![p isKindOfClass:[NSMutableParagraphStyle class]]) p=[[p mutableCopy] autorelease];	// make mutable
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

/*
 * the following 3 setters are modelled to fulfill our SenTests.
 * but is it really identical?
 * Depends on unknown test coverage...
 */

- (void) setMaxSize:(NSSize)newMaxSize;
{ // keep minSize smaller than maxSize and frame size as large as maxSize (if resizable)
	NSSize ofsz=[self frame].size, nfsz=ofsz;
#if 1
	NSLog(@"setMax=%@", NSStringFromSize(newMaxSize));
	NSLog(@"  omin=%@", NSStringFromSize(_minSize));
	NSLog(@"  ofsz=%@", NSStringFromSize(ofsz));
	NSLog(@"  omax=%@", NSStringFromSize(_maxSize));
#define P(x) NSLog(x)
#else
#define P(x) 0
#endif
	if(_tx.horzResizable && newMaxSize.width < ofsz.width)
		P(@"ha"), nfsz.width=newMaxSize.width;
	if(newMaxSize.width >= _minSize.width)
		P(@"hb"), _maxSize.width=newMaxSize.width;
	else
		P(@"hc"), _maxSize.width=nfsz.width;
	if(newMaxSize.width < _minSize.width)
		P(@"hd"), _minSize.width=newMaxSize.width;
	if(nfsz.width < _minSize.width)
		P(@"he"), _minSize.width=nfsz.width;
	if(_tx.vertResizable && newMaxSize.height < ofsz.height)
		P(@"va"), nfsz.height=newMaxSize.height;
	if(newMaxSize.height >= _minSize.height)
		P(@"vb"), _maxSize.height=newMaxSize.height;
	else
		P(@"vc"), _maxSize.height=nfsz.height;
	if(newMaxSize.height < _minSize.height)
		P(@"vd"), _minSize.height=newMaxSize.height;
	if(nfsz.height < _minSize.height)
		P(@"ve"), _minSize.height=nfsz.height;
#if 1
	NSLog(@"  nmin=%@", NSStringFromSize(_minSize));
	NSLog(@"  nfsz=%@", NSStringFromSize(nfsz));
	NSLog(@"  nmax=%@", NSStringFromSize(_maxSize));
#undef P
#endif
	if(!NSEqualSizes(nfsz, ofsz))
		{
		[super setFrameSize:nfsz];
		[self setBoundsSize:nfsz];	// will not be updated automatically if we are enclosed in a NSClipView (and have custom bounds)
		}
}

- (void) setMinSize:(NSSize)newMinSize;
{ // keep maxSize larger than minSize and frame size larger than minSize (if resizable)
	NSSize ofsz=[self frame].size, nfsz=ofsz;
#if 1
	NSLog(@"setMin=%@", NSStringFromSize(newMinSize));
	NSLog(@"  omin=%@", NSStringFromSize(_minSize));
	NSLog(@"  ofsz=%@", NSStringFromSize(ofsz));
	NSLog(@"  omax=%@", NSStringFromSize(_maxSize));
#define P(x) NSLog(x)
#else
#define P(x) 0
#endif
	if(_tx.horzResizable && fabs(newMinSize.width) > ofsz.width)
		P(@"ha"), nfsz.width=fabs(newMinSize.width);
//	else if(newMinSize.width <= _maxSize.width)
//		P(@"hb"), _minSize.width=newMinSize.width;
	if(newMinSize.width <= _maxSize.width)
		P(@"hc"), _minSize.width=newMinSize.width;
	else
		P(@"hd"), _minSize.width=nfsz.width;
	if(newMinSize.width > _maxSize.width)
		P(@"he"), _maxSize.width=newMinSize.width;
	if(_tx.vertResizable && fabs(newMinSize.height) > ofsz.height)
		P(@"va"), nfsz.height=fabs(newMinSize.height);
//	else if(newMinSize.height <= _maxSize.height)
//		P(@"vb"), _minSize.height=newMinSize.height;
	if(newMinSize.height <= _maxSize.height)
		P(@"vc"), _minSize.height=newMinSize.height;
	else
		P(@"vd"), _minSize.height=nfsz.height;
	if(newMinSize.height > _maxSize.height)
		P(@"ve"), _maxSize.height=newMinSize.height;
#if 1
	NSLog(@"  nmin=%@", NSStringFromSize(_minSize));
	NSLog(@"  nfsz=%@", NSStringFromSize(nfsz));
	NSLog(@"  nmax=%@", NSStringFromSize(_maxSize));
#undef P
#endif
	if(!NSEqualSizes(nfsz, ofsz))
		{
		[super setFrameSize:nfsz];
		[self setBoundsSize:nfsz];	// will not be updated automatically if we are enclosed in a NSClipView (and have custom bounds)
		}
}

- (void) setFrameSize:(NSSize)newSize	// is called from setFrame:
{ // enlarge min/maxSize window to cover this size
	NSSize ofsz=[self frame].size, nfsz=newSize;
#if 0
	NSLog(@"setFrameSize: %@", NSStringFromSize(newSize));
	NSLog(@"  omin: %@", NSStringFromSize(_minSize));
	NSLog(@"  ofsz:  %@", NSStringFromSize(ofsz));
	NSLog(@"  omax: %@", NSStringFromSize(_maxSize));
#define P(x) NSLog(x)
#else
#define P(x) 0
#endif
	// this are very strange rules but proven by UnitTests
	if(newSize.width < _minSize.width)
		P(@"ha"), _minSize.width = newSize.width;
	else if(newSize.width > _maxSize.width)
		P(@"ha1"), _maxSize.width = newSize.width;	// if we can't adjust frame size we have to increase max
	if(_tx.horzResizable && newSize.height != ofsz.height)
		P(@"hb"), nfsz.width=fabs(_minSize.width);	// force reset width
	else if(newSize.width > _maxSize.width)
		P(@"hc"), _maxSize.width = newSize.width;
	if(newSize.height < _minSize.height)
		P(@"va"), _minSize.height = newSize.height;
	else if(newSize.height > _maxSize.height)
		// not symmetrical! Maybe we are missing some special cases
		// e.g.  _maxSize.height=(condition)?newSize.width:ofsz.width
		P(@"va1"), _maxSize.height=ofsz.height;
	if(_tx.vertResizable && newSize.width != ofsz.width)
		P(@"vb"), nfsz.height=fabs(_minSize.height);
	else if(newSize.height > _maxSize.height)
		P(@"vc"), _maxSize.height=newSize.height;
#if 0
	NSLog(@"  nmin: %@", NSStringFromSize(_minSize));
	NSLog(@"  nfsz: %@", NSStringFromSize(nfsz));
	NSLog(@"  nmax: %@", NSStringFromSize(_maxSize));
#undef P
#endif
	if(!NSEqualSizes(nfsz, ofsz))
		{
		[super setFrameSize:nfsz];
		[self setBoundsSize:nfsz];	// will not be updated automatically if we are enclosed in a NSClipView (and have custom bounds)
		}
}

- (void) viewDidMoveToSuperview
{ // adjust to superview dimensions if it is a NSClipView
	if([[self superview] isKindOfClass:[NSClipView class]])
		{ // enlarge minSize and frameSize
			NSSize sz=[[self superview] frame].size;
			// it appears that either one (not both) is called but the rules are not clear
			[self setMinSize:sz];
//			[self setFrameSize:sz];
		}
}

- (void) setRichText:(BOOL)flag
{	
	if(_tx.isRichText == flag)
		return;
	_tx.isRichText=flag;
	// do other modifications (apply attributes at index 0 to full textStorage)
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
	_anchor=NSNotFound;	// no anchor (yet)
	_tx.moveLeftRightEnd=0;
	_tx.moveUpDownEnd=0;
#if 0
	NSLog(@"setSelectedRange=%@", NSStringFromRange(_selectedRange));
#endif
#if 0
	NSLog(@"  text=%@", textStorage);
#endif
}

- (void) setString:(NSString *)string;
{
	_tx.isRichText=NO;
	// make sure to keep the formatting of the old first character
	[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:string];
	[self setSelectedRange:NSMakeRange([string length], 0)];	// move to end of string
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
	NSRect rect=(NSRect) { NSZeroPoint, [textStorage size] };	// ask the text storage for the unbound size
#if 0
	NSLog(@"sizeToFit %@", self);
	NSLog(@"  rect=%@", NSStringFromRect(rect));
	NSLog(@"  min=%@", NSStringFromSize(_minSize));
	NSLog(@"  max=%@", NSStringFromSize(_maxSize));
#endif
	if(!_tx.horzResizable)
		rect.size.width=_frame.size.width;	// don't resize horizontally
	if(!_tx.vertResizable)
		rect.size.height=_frame.size.height;	// don't resize vertically
	rect=NSUnionRect(rect, (NSRect) { NSZeroPoint, _minSize });
	rect=NSIntersectionRect(rect, (NSRect) { NSZeroPoint, _maxSize });
	[self setFrame:rect];	// adjust to be between min and max size
}

- (NSString *) string;
{
	return [textStorage string];
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
	NSTextStorage *ts=textStorage;
#if 0
	NSLog(@"%@ initWithFrame:%@", NSStringFromClass([self class]), NSStringFromRect(f));
#endif
	if((self=[super initWithFrame:f]))
		{ // this initialization will be used for a Field Editor but is also called from initWithCoder!
			if(ts)
				{
				textStorage=ts;
				_tx.ownsTextStorage=NO;	// some subclass initWithFrame has already initialized the textStorage
				}
			else
				{
				textStorage=[NSTextStorage new];	// provide empty default text storage
				_tx.ownsTextStorage=YES;			// that we own
				_tx.isRichText=NO;
				}
			_spellCheckerDocumentTag=[NSSpellChecker uniqueSpellDocumentTag];
			_tx.alignment = NSLeftTextAlignment;
			_tx.editable = YES;
			_tx.selectable = YES;
			_tx.vertResizable = YES;
			_tx.drawsBackground = YES;
			_backgroundColor=[[NSColor textBackgroundColor] retain];
			_minSize = f.size;	// as defined by frame
			_maxSize = (NSSize){_minSize.width, 1e+07};
			_font=[[NSFont userFontOfSize:12] retain];
			_selectedRange=NSMakeRange(0,0);	// don't call setSelectedRange here which may have side effects in subclasses
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
	// FIXME: this should have been done through processEditing if we have a text storage
	rng.location+=[(NSString *) text length];	// advance selection
	rng.length=0;
	[self setSelectedRange:rng];
}

- (NSUInteger) characterIndexForPoint:(NSPoint) pnt;
{
	return NSNotFound;	// i.e. outside of all characters
}

- (void) resetCursorRects
{
	if([self isSelectable])
		[self addCursorRect:[self bounds] cursor:[NSCursor IBeamCursor]];	
}

- (void) mouseDown:(NSEvent *)event
{ // simple mouse down mechanism
	NSRange rng=_selectedRange;	// current selected range
	NSEvent *lastMouseEvent=nil;
#if 1
	NSLog(@"%@ mouseDown: %@", NSStringFromClass([self class]), event);
#endif
	// save modifiers of first event
	if([event clickCount] > 1)
		{ // depending on click count, extend selection at this position and then do standard tracking
			NSPoint p=[self convertPoint:[event locationInWindow] fromView:nil];
			NSUInteger pos=[self characterIndexForPoint:p];
			// FIXME
		}
	while([event type] != NSLeftMouseUp)	// loop outside until mouse goes up 
		{
		NSPoint p;
		// NSUInteger pos=[self characterIndexForPoint:p];
		NSUInteger pos=0;
#if 0
		NSLog(@"NSControl mouseDown point=%@", NSStringFromPoint(p));
#endif
		if([event type] == NSPeriodic)
			{
			event=lastMouseEvent;	// repeat
			continue;			
			}
		p=[self convertPoint:[event locationInWindow] fromView:nil];
		if([event type] == NSLeftMouseDragged)
			{
			[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
			lastMouseEvent=event;
			}
		// handle click on NSTextAttachments
		if(NSLocationInRange(pos, _selectedRange))
			{ // in current range we already hit the current selection it is a potential drag&drop
				rng=_selectedRange;
			}
		else if(1) // no modifier
			rng=NSMakeRange(pos, 0);	// set cursor to location where we did click
		else if(0) // shift key
			rng=NSUnionRange(_selectedRange, NSMakeRange(pos, 0));	// extend
		if([event type] == NSLeftMouseDragged)
			{ // moved
				[NSApp discardEventsMatchingMask:NSLeftMouseDraggedMask beforeEvent:nil];	// discard all further movements queued up so far
				if([self autoscroll:event])
					{ // repeat autoscroll
						if(!lastMouseEvent)
							[NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
						lastMouseEvent=event;					
					}
				else
					{
					if(lastMouseEvent) [NSEvent stopPeriodicEvents];
					lastMouseEvent=nil;
					}
			}
		[self setSelectedRange:rng];
		event = [NSApp nextEventMatchingMask:GSTrackingLoopMask
								   untilDate:[NSDate distantFuture]						// get next event
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
  		}
	if(lastMouseEvent) [NSEvent stopPeriodicEvents];
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
		// and on Cocoa, [NSApp sendEvent:] is called for *every* event
		NSMutableArray *events=[NSMutableArray arrayWithObject:event];
#if 1
		NSLog(@"%@ keyDown: %@", NSStringFromClass([self class]), event);
#endif
#if 0	// does this work?
		while((event = [NSApp nextEventMatchingMask:NSKeyDownMask|NSKeyUpMask|NSFlagsChangedMask
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
					default:	// any other event (should not happen)
						[NSApp postEvent:event atStart:YES];	// requeue
						break;
				}
				break;
			}
#endif
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
		rng.location--;	// delete the character before the selection
		rng.length=1;
		}
	[self replaceCharactersInRange:rng withString:@""];	// remove
	rng.length=0;
	[self setSelectedRange:rng];
}

- (void) _handleFieldEditorMovement:(int) move
{ // post field editor notification
	if(_delegate && [_delegate respondsToSelector:@selector(textShouldEndEditing:)]
	   && ![_delegate textShouldEndEditing:self])
		return;	// not accepted
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:NOTE(DidEndEditing) 
								   object:self
								 userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:move] forKey:NSTextMovement]]];
}

- (void) cancelOperation:(id) sender
{ // should be bound to ESC key?
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
		// can't implement here since we don't know about pixel coordinates
		NIMP;
}

- (void) moveDown:(id) sender
{
	if(_tx.fieldEditor)
		[self _handleFieldEditorMovement:NSDownTextMovement];
	else
		// should go down one line in same column
		// can't implement here since we don't know about pixel coordinates
		NIMP;
}

- (void) moveRight:(id) sender
{
	NSRange rng=_selectedRange;
	if(NO && _tx.fieldEditor)
		{
		[self _handleFieldEditorMovement:NSRightTextMovement];
		return;
		}
	if(_anchor != NSNotFound)
		{ // anchor defined
		if(rng.location < _anchor)
			rng.location++, rng.length--;	// selection starts before anchor - move left end
		else if(NSMaxRange(rng) < [textStorage length])
			rng.length++;	// selection starts at or after anchor - move right end
		}
	else if(_selectedRange.length > 0)
		rng.location+=rng.length, rng.length=0;	// reduce selection to right end
	else if(_selectedRange.location < [textStorage length])
		rng.location++, rng.length=0;
	[self setSelectedRange:rng];	// really move right
}

// there are two locations:
// a) anchor
// b) moving position
// 1: if there is no anchor, take left or right end of initial selection (and stable position!)
// 2: result is range between anchor and moving position
//
// 3: there is a single anchor!
//
// 4: when is it changed? by clicking on a position, not by cursor movements
//
// after double-clicking on a word, the stable cursor is always the left end of the initial selection
// if shift-extending after drag-selection by mouse, both the anchor and stable cursor are defined according to rule 1: (!)
//
// since cursor stability is implemented in NSTextView subclass through [self setSelectedRange] we should call it only once
// stable cursor column is also defined by any action that inserts/deletes characters and by clicking
// i.e. it is only NOT changed by simple movements

- (void) moveRightAndModifySelection:(id) sender
{
#if 1
	NSUInteger anchor;
	if(_anchor == NSNotFound) _anchor=_selectedRange.location;	// initialize anchor
	anchor=_anchor;	// save
	[self moveRight:nil];
	_anchor=anchor;
#else
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
#endif
}

- (void) moveForwardAndModifySelection:(id) sender
{
	// check for writing direction
	[self moveRightAndModifySelection:sender];
}

- (void) moveToEndOfLine:(id) sender
{
	NSLog(@"should move selection to end of line");
}

- (void) moveLeft:(id) sender
{
	NSRange rng=_selectedRange;
	if(NO && _tx.fieldEditor)
		{
		[self _handleFieldEditorMovement:NSLeftTextMovement];
		return;
		}
	if(_anchor != NSNotFound)
		{ // anchor defined
			if(NSMaxRange(rng) > _anchor)
				rng.length--;	// selection ends after anchor - move right end (reduce selection)
			else if(rng.location > 0)
				rng.location--, rng.length++;	// selection ends at anchor - move left end (extend selection)
		}
	else if(_selectedRange.length > 0)
		rng.length=0;	// reduce selection to left end
	else if(_selectedRange.location > 0)
		rng.location--, rng.length=0;
	[self setSelectedRange:rng];	// really move left
}

- (void) moveLeftAndModifySelection:(id) sender
{
#if 1
	NSUInteger anchor;
	if(_anchor == NSNotFound) _anchor=NSMaxRange(_selectedRange);	// initialize anchor
	anchor=_anchor;	// save
	[self moveLeft:nil];
	_anchor=anchor;	// restore
#else
	// FIXME: base on moveLeft, i.e. save current selection, move left and merge/reduce depending on _tx.moveLeftRightEnd or !_tx.moveLeftRightEnd
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
#endif
}

- (void) moveBackwardAndModifySelection:(id) sender
{
	[self moveLeftAndModifySelection:sender];
}

- (void) moveToBeginningOfLine:(id) sender
{
	NSLog(@"should move selection to beginning of line");
}

- (void) moveDownAndModifySelection:(id) sender
{
#if 1
	NSUInteger anchor;
	if(_anchor == NSNotFound) _anchor=_selectedRange.location;	// initialize anchor
	anchor=_anchor;	// save
	[self moveDown:nil];
	_anchor=anchor;
#else
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
#endif
}

- (void) moveUpAndModifySelection:(id) sender
{
#if 1
	NSUInteger anchor;
	if(_anchor == NSNotFound) _anchor=NSMaxRange(_selectedRange);	// initialize anchor
	anchor=_anchor;	// save
	[self moveUp:nil];
	// set selected range from anchor and range
	_anchor=anchor;
#else
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
#endif
}

- (BOOL) acceptsFirstResponder					{ return _tx.selectable; }
- (BOOL) needsPanelToBecomeKey					{ return _tx.editable; }
- (BOOL) acceptsFirstMouse:(NSEvent *)event		{ return _tx.fieldEditor; }

- (BOOL) becomeFirstResponder
{	
#if 1
	NSLog(@"becomeFirstResponer: %@", self);
#endif
	if(!_tx.selectable) 
		return NO;	// if not selectable
	if(_tx.editable)
		{ // really editing - not only selecting
			if(_delegate && [_delegate respondsToSelector:@selector(textShouldBeginEditing:)]
			   && ![_delegate textShouldBeginEditing:self])
				return NO;	// delegate did a veto
			// FIXME: doc says that it should only be sent by the first change to distinguish click from change!
			[[NSNotificationCenter defaultCenter] postNotification:[NSNotification notificationWithName:NOTE(DidBeginEditing) object:self]];
		}
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSOrderFrontCharacterPalette"])
		[NSApp orderFrontCharacterPalette:self];	// automatically show keyboard if automatism is enabld
	return YES;
}

- (BOOL) resignFirstResponder
{
	if(_tx.editable)
		[self _handleFieldEditorMovement:NSCancelTextMovement];
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"NSOrderFrontCharacterPalette"])
		[NSApp _orderOutCharacterPalette:self];	// automatically hide keyboard if automatism is enabled
	return YES;
}

- (BOOL) validateMenuItem:(NSMenuItem *)menuItem
{
	NSString *sel=NSStringFromSelector([menuItem action]);
	if([sel isEqualToString:@"paste:"])
		return [self isEditable] && NO /* anything to paste */;
	if([sel isEqualToString:@"pasteAsPlainText:"])
		return [self isEditable] && NO /* anything to paste */;
	if([sel isEqualToString:@"pasteAsRichText:"])
		return [self isEditable] && NO /* anything to paste */;
	if([sel isEqualToString:@"cut:"])
		return [self isEditable] && _selectedRange.length > 0;
	if([sel isEqualToString:@"delete:"])
		return [self isEditable] && _selectedRange.length > 0;
	if([sel isEqualToString:@"copy:"])
		return _selectedRange.length > 0;	// if there anything to copy
	return YES;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 1
	NSLog(@"[NSText] %@ initWithCoder: %@", self, coder);
#endif
	if((self=[super initWithCoder:coder]))	// calls our initWithFrame
		{
		[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
		_minSize=[coder decodeSizeForKey:@"NSMinize"];	// NB: this is a bug in Apple IB: key should be @"NSMinSize" - beware of changes by Apple
		_maxSize=[coder decodeSizeForKey:@"NSMaxSize"];
#if 1
		NSLog(@"minSize=%@", NSStringFromSize(_minSize));
		NSLog(@"maxSize=%@", NSStringFromSize(_maxSize));
#endif
		}
	return self;
}

@end

@implementation NSText (NSPrivate)

- (BOOL) _isSecure								{ return _tx.secure; }
- (void) _setSecure:(BOOL)flag					{ _tx.secure = flag; }
- (NSTextStorage *) _textStorage;				{ return textStorage; }		// the private text storage

@end
