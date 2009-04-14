/*
   NSTextContainerAndStorage.m

   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jun 2006

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <AppKit/NSTextAttachment.h>
#import <AppKit/NSTextContainer.h>
#import <AppKit/NSTextStorage.h>
#import <AppKit/NSLayoutManager.h>
#import <AppKit/NSTextView.h>
#import <AppKit/NSFileWrapper.h>

@implementation NSTextContainer

- (NSSize) containerSize; { return size; }
- (BOOL) containsPoint:(NSPoint) point; { NIMP; return NO; }
- (BOOL) heightTracksTextView; { return heightTracksTextView; }

- (id) initWithContainerSize:(NSSize) sz;
{
	if((self=[super init]))
		{
		size=sz;
		}
	return self;
}

- (void) dealloc;
{
	[self setTextView:nil];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: size %@", NSStringFromClass(isa), NSStringFromSize(size)];
}

- (BOOL) isSimpleRectangularTextContainer; { return YES; }
- (NSLayoutManager *) layoutManager; { return layoutManager; }
- (float) lineFragmentPadding; { return lineFragmentPadding; }

- (NSRect) lineFragmentRectForProposedRect:(NSRect) proposedRect
			 sweepDirection:(NSLineSweepDirection) sweepDirection
			 movementDirection:(NSLineMovementDirection) movementDirection
			 remainingRect:(NSRect *) remainingRect;
{
	NIMP;
	return NSZeroRect;
}

- (void) replaceLayoutManager:(NSLayoutManager *) newLayoutManager;
{
	int idx;
	[self retain];	// just be sure
	idx=[[layoutManager textContainers] indexOfObject:self];	// find us int the list of text container
	if(idx != NSNotFound)
		[layoutManager removeTextContainerAtIndex:idx];			// remove us from our old layout manager
	[self setLayoutManager:newLayoutManager];
	[layoutManager insertTextContainer:self atIndex:idx];	// connect to the new layout manager
	[self release];
}

- (void) setContainerSize:(NSSize) sz; { size=sz; }
- (void) setHeightTracksTextView:(BOOL) flag; { heightTracksTextView=flag; }
- (void) setLayoutManager:(NSLayoutManager *) lm; { layoutManager=lm; }
- (void) setLineFragmentPadding:(float) pad; { lineFragmentPadding=pad; }

- (void) _track:(NSNotification *) n;
{
	NSRect frame=[textView frame];
	NSSize inset=[textView textContainerInset];
	NSSize newSize=size;
	if(widthTracksTextView)
		newSize.width=frame.size.width-2.0*inset.width;
	if(heightTracksTextView)
		newSize.height=frame.size.height-2.0*inset.height;
	if(!NSEqualSizes(size, newSize))
		{
		size=newSize;
		// notify layout manager to invalidate the glyph layout
		}
}

- (void) setTextView:(NSTextView *) tv;
{
	NSNotificationCenter *nc;
	if(textView == tv)
		return;
	nc=[NSNotificationCenter defaultCenter];
	[nc removeObserver:self name:NSViewFrameDidChangeNotification object:textView];
	[textView setTextContainer:nil];
	ASSIGN(textView, tv);
	[textView setTextContainer:self];
	[nc addObserver:self selector:@selector(_track:) name:NSViewFrameDidChangeNotification object:textView];
	if(textView)
		[self _track:nil];
}

- (void) setWidthTracksTextView:(BOOL) flag; { widthTracksTextView=flag; }
- (NSTextView *) textView; { return textView; }
- (BOOL) widthTracksTextView; { return widthTracksTextView; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	int tcFlags=[coder decodeInt32ForKey:@"NSTCFlags"];
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
#define WIDTHTRACKS ((tcFlags&0x01)!=0)
	widthTracksTextView=WIDTHTRACKS;
#define HEIGHTTRACKS ((tcFlags&0x02)!=0)
	heightTracksTextView=HEIGHTTRACKS;
	size.height=[coder decodeFloatForKey:@"NSHeight"];
	size.width=[coder decodeFloatForKey:@"NSWidth"];
	layoutManager=[coder decodeObjectForKey:@"NSLayoutManager"];
	[self setTextView:[coder decodeObjectForKey:@"NSTextView"]];
#if 0
	NSLog(@"%@ done", self);
#endif
	return self;
}

@end

@implementation NSTextStorage

- (id) init;
{
	if((self=[super init]))
		{
#if __APPLE__
		_concreteString=[NSMutableAttributedString new];
#endif
		_layoutManagers=[NSMutableArray new];
		}
	return self;
}

- (id) initWithAttributedString:(NSAttributedString *) str;
{
#if __APPLE__
	if((self=[super init]))
		{
		_concreteString=[[NSMutableAttributedString alloc] initWithAttributedString:str];
		_layoutManagers=[NSMutableArray new];
		}
#else
	if((self=[super initWithAttributedString:str]))
		{
		_layoutManagers=[NSMutableArray new];
		}
#endif
	return self;
}

- (void) dealloc;
{
#if 1
	NSLog(@"dealloc NSTextStorage %p: %@", self, self);
#endif
#if __APPLE__
	[_concreteString release];
#endif
	[_layoutManagers release];
	[self setDelegate:nil];
	[super dealloc];
}

- (void) addLayoutManager:(NSLayoutManager *)lm; { [_layoutManagers addObject:lm]; [lm setTextStorage:self]; }

- (int) changeInLength;
{
	return _changeInLength;
}

- (id) delegate; { return _delegate; }

- (void) edited:(unsigned)editedMask 
		  range:(NSRange)range 
 changeInLength:(int)delta;
{
	// accumulate changeInLength
	NIMP;
	[self processEditing];
}

- (void) beginEditing;
{
}

- (void) endEditing;
{
//	[self fixAttributesInRange:editedRange];
// inform NSLayoutManager(s)
}

- (unsigned int) editedMask; { return _editedMask; }

- (NSRange) editedRange; { return _editedRange; }

- (void) ensureAttributesAreFixedInRange:(NSRange)range;
{
	NIMP;
}

- (BOOL) fixesAttributesLazily; { return _fixesAttributesLazily; }

- (void) invalidateAttributesInRange:(NSRange)range;
{
	NIMP;
}

- (NSArray *) layoutManagers; { return _layoutManagers; }

- (void) processEditing;
{
	NSEnumerator *e=[_layoutManagers objectEnumerator];
	NSLayoutManager *lm;
	NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
	[nc postNotificationName:NSTextStorageWillProcessEditingNotification object:self];
	// do something???
	[nc postNotificationName:NSTextStorageDidProcessEditingNotification object:self];
	while((lm=[e nextObject]))
		[lm textStorage:self edited:0 range:_editedRange changeInLength:_changeInLength invalidatedRange:NSMakeRange(0, 0)];
}

- (void) removeLayoutManager:(NSLayoutManager *)obj; { [obj setTextStorage:nil]; [_layoutManagers removeObject:obj]; }

- (void) setDelegate:(id)obj;
{
	if(_delegate)
		; // disconnect notifications
	_delegate=obj;
	if(_delegate)
		; // connect notifications
}

- (NSArray *) attributeRuns; { return NIMP; }
- (NSArray *) characters; { return NIMP; }
- (NSFont *) font; { return NIMP; }
- (NSColor *) foregroundColor; { return NIMP; }
- (NSArray *) paragraphs; { return [[self string] componentsSeparatedByString:@"\n"]; }
- (void) setAttributeRuns:(NSArray *)attributeRuns; { NIMP; return; }
- (void) setCharacters:(NSArray *)characters; { NIMP; return; }
- (void) setFont:(NSFont *)font; { NIMP; return; }
- (void) setForegroundColor:(NSColor *)color; { NIMP; return; }
- (void) setParagraphs:(NSArray *)paragraphs; { NIMP; return; }
- (void) setWords:(NSArray *)words; { NIMP; return; }
- (NSArray *) words; { return NIMP; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
	[super encodeWithCoder:coder];
}

- (id) initWithCoder:(NSCoder *) coder;
{
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
	NSLog(@"NSAttributes=%@", [coder decodeObjectForKey:@"NSAttributes"]);
	NSLog(@"NSString=%@", [coder decodeObjectForKey:@"NSString"]);
	NSLog(@"NSAttributeInfo=%@", [coder decodeObjectForKey:@"NSAttributeInfo"]);	// is NSData(!)
	NSLog(@"NSDelegate=%@", [coder decodeObjectForKey:@"NSDelegate"]);
#endif
#if __APPLE__
	_concreteString=[[NSMutableAttributedString alloc] initWithCoder:coder];
#else
	self=[super initWithCoder:coder];	// we are a real subclass of NSMutableAttributedString
#if 1
	NSLog(@"FIXME: doesn't unarchive textStorage's attributes properly");
	// FIXME: these should be decoded in NSAttributedString!
	[coder decodeObjectForKey:@"NSAttributes"];	// this is an array of attribute runs
	[coder decodeObjectForKey:@"NSAttributeInfo"];	// NSAttributeInfo is most probably a list of ranges where the attributes apply (unless it is for the full range)
#endif
#endif
	[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
#if 0
	NSLog(@"%@ done", self);
#endif
	return self;
}

#if __APPLE__

// reimplement NSMutableAttributedString methods as wrappers for concreteString since we are a semiconcrete subclass of Apple's foundation

- (NSString *) string;
{
	// we might cache since this is called pretty often
	return [_concreteString string];
}

- (NSMutableString *) mutableString;
{
	// CHECKME: is this a copy or the original??? And, Attributes are moved front/back if we insert/delete through NSMutableString methods?
	// we might cache since this is called pretty often
	return [_concreteString mutableString];
}

- (NSDictionary *) attributesAtIndex:(unsigned) index effectiveRange:(NSRangePointer) range
{
	NSDictionary *d;
	//	return [_concreteString attributesAtIndex:index effectiveRange:range];
	NS_DURING
		d=[_concreteString attributesAtIndex:index effectiveRange:range];
	NS_HANDLER
		NSLog(@"exception %@ for %@", localException, NSStringFromClass([self class]));
		NSLog(@"concrete string %@", _concreteString);
		NSLog(@"concrete string length %u", [_concreteString length]);
		NSLog(@"index %d", index);
		d=nil;
	NS_ENDHANDLER
	return d;
}

- (NSDictionary *) attributesAtIndex:(unsigned) index longestEffectiveRange:(NSRangePointer) longest inRange:(NSRange) range
{
	NSDictionary *d;
	//	return [_concreteString attributesAtIndex:index longestEffectiveRange:longest inRange:range];
	NS_DURING
		d=[_concreteString attributesAtIndex:index longestEffectiveRange:longest inRange:range];
	NS_HANDLER
		NSLog(@"exception %@ for %@", localException, NSStringFromClass([self class]));
		NSLog(@"concrete string %@", _concreteString);
		NSLog(@"concrete string length %u", [_concreteString length]);
		NSLog(@"index %d", index);
		d=nil;
	NS_ENDHANDLER
	return d;
}
#endif

//// FIXME: this is called in SWK when we update the attributed string
//// and it should at least make the NSTextView resize so that scrollbars are displayed properly

- (void) replaceCharactersInRange:(NSRange) rng withAttributedString:(NSAttributedString *) str
{
	NSEnumerator *e;
	NSLayoutManager *lm;
#if __APPLE__
	[_concreteString replaceCharactersInRange:rng withAttributedString:str];
#else
	[super replaceCharactersInRange:rng withAttributedString:str];
#endif
	e=[_layoutManagers objectEnumerator];
	while((lm=[e nextObject]))
		[lm textStorage:self edited:0 range:rng changeInLength:0 invalidatedRange:NSMakeRange(0, [str length])];
}

- (void) replaceCharactersInRange:(NSRange) rng withString:(NSString *) str
{
	NSEnumerator *e;
	NSLayoutManager *lm;
#if __APPLE__
	[_concreteString replaceCharactersInRange:rng withString:str];
#else
	[super replaceCharactersInRange:rng withString:str];
#endif
	e=[_layoutManagers objectEnumerator];
	while((lm=[e nextObject]))
		[lm textStorage:self edited:0 range:rng changeInLength:0 invalidatedRange:NSMakeRange(0, [str length])];
}

- (void) setAttributedString:(NSAttributedString *) str;
{
	NSEnumerator *e;
	NSLayoutManager *lm;
	unsigned prevLen=[self length];
#if __APPLE__
	if(_concreteString == str)
		return;	// no change
	[_concreteString release];
	_concreteString=[str retain];
#else
	[super setAttributedString:str];
#endif
	e=[_layoutManagers objectEnumerator];
	while((lm=[e nextObject]))
		[lm textStorage:self edited:0 range:NSMakeRange(0, prevLen) changeInLength:0 invalidatedRange:NSMakeRange(0, [str length])];
}

- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
	NSEnumerator *e;
	NSLayoutManager *lm;
#if __APPLE__
	[_concreteString setAttributes:attributes range:aRange];
#else
	[super setAttributes:attributes range:aRange];
#endif
	e=[_layoutManagers objectEnumerator];
	while((lm=[e nextObject]))
		[lm textStorage:self edited:0 range:aRange changeInLength:0 invalidatedRange:aRange];
}

@end

NSString *NSTextStorageDidProcessEditingNotification=@"NSTextStorageDidProcessEditingNotification";
NSString *NSTextStorageWillProcessEditingNotification=@"NSTextStorageWillProcessEditingNotification";

@implementation NSTextAttachment

- (id <NSTextAttachmentCell>) attachmentCell; { return _cell; }

- (NSFileWrapper *) fileWrapper; { return _fileWrapper; }

- (id) initWithFileWrapper:(NSFileWrapper *) fileWrapper;
{
	if((self=[super init]))
		{
		_fileWrapper=[fileWrapper retain];
		}
	return self;
}

- (void) dealloc;
{
	[_cell release];
	[_fileWrapper release];
	[super dealloc];
}

- (void) setAttachmentCell:(id <NSTextAttachmentCell>) cell;
{
	ASSIGN(_cell, cell);
	_flags.cellWasExplicitlySet=YES;
}

- (void) setFileWrapper:(NSFileWrapper *) fileWrapper;
{
	ASSIGN(_fileWrapper, fileWrapper);
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	_fileWrapper=[[coder decodeObjectForKey:@"NSFileWrapper"] retain];
	_cell=[[coder decodeObjectForKey:@"NSCell"] retain];
	return self;
}

@end

@implementation NSTextAttachmentCell

- (NSTextAttachment *) attachment; { return _attachment; }

- (NSPoint) cellBaselineOffset; { return NSZeroPoint; }

- (NSRect) cellFrameForTextContainer:(NSTextContainer *) container
								proposedLineFragment:(NSRect) fragment
											 glyphPosition:(NSPoint) pos
											characterIndex:(unsigned) index;
{
	return (NSRect){ NSZeroPoint, [self cellSize] };
}

- (NSSize) cellSize; { return NSMakeSize(50.0, 50.0); }

- (void) drawWithFrame:(NSRect)cellFrame
								inView:(NSView *)controlView;
{
}

- (void) drawWithFrame:(NSRect)cellFrame
								inView:(NSView *)controlView
				characterIndex:(unsigned) index;
{
}

- (void) drawWithFrame:(NSRect)cellFrame
								inView:(NSView *)controlView
				characterIndex:(unsigned) index
				 layoutManager:(NSLayoutManager *) manager;
{
}

- (void) highlight:(BOOL)flag
				 withFrame:(NSRect)cellFrame
						inView:(NSView *)controlTextView;
{
}

- (void) setAttachment:(NSTextAttachment *)anObject;
{
	_attachment=anObject;
}

- (BOOL) trackMouse:(NSEvent *)event 
						 inRect:(NSRect)cellFrame 
						 ofView:(NSView *)controlTextView 
   atCharacterIndex:(unsigned) index
			 untilMouseUp:(BOOL)flag;
{
	/*
	 sends e.g.
	 textView:doubleClickedOnCell:inRect:
	 textView:clickedOnCell:inRect:
	 textView:draggedCell:inRect:event:
	 */
	return NO;
}

- (BOOL) trackMouse:(NSEvent *)event 
						 inRect:(NSRect)cellFrame 
						 ofView:(NSView *)controlTextView 
			 untilMouseUp:(BOOL)flag;
{
	return [self trackMouse:event 
									 inRect:cellFrame 
									 ofView:controlTextView 
				 atCharacterIndex:NSNotFound
						 untilMouseUp:flag];
}

- (BOOL) wantsToTrackMouse; { return YES; }

- (BOOL) wantsToTrackMouseForEvent:(NSEvent *) event
														inRect:(NSRect) rect
														ofView:(NSView *) controlView
									atCharacterIndex:(unsigned) index;
{
	return YES;
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	if((self=[super initWithCoder:coder]))
		{
		_attachment=[[coder decodeObjectForKey:@"NSTextAttachment"] retain];
		}
	return self;
}

@end

@implementation NSAttributedString (NSAttributedStringAttachmentConveniences)

+ (NSAttributedString *) attributedStringWithAttachment:(NSTextAttachment *)attachment;
{
	static NSString *str;
	static unichar c=NSAttachmentCharacter;
	if(!str)
		str=[[NSString alloc] initWithCharacters:&c length:1];
	return [[[self alloc] initWithString:str attributes:[NSDictionary dictionaryWithObject:attachment forKey:NSAttachmentAttributeName]] autorelease];
}

@end

@implementation NSMutableAttributedString (NSMutableAttributedStringAttachmentConveniences)

- (void) updateAttachmentsFromPath:(NSString *)path;
{
	NIMP;
}

@end
