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

- (void) _track:(NSNotification *) n;
{
	NSRect frame=[textView frame];
	NSSize inset=[textView textContainerInset];
	NSSize newSize=size;
	if(widthTracksTextView)
		newSize.width=frame.size.width-2.0*inset.width;
	if(heightTracksTextView)
		newSize.height=frame.size.height-2.0*inset.height;
	[self setContainerSize:newSize];
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

- (void) setContainerSize:(NSSize) sz;
{
	if(!NSEqualSizes(size, sz))
		{
		size=sz;
#if 0
		NSLog(@"adjusted %@", self);
#endif
		// notify layout manager to invalidate the glyph layout
		}
}

- (void) setHeightTracksTextView:(BOOL) flag; { heightTracksTextView=flag; }
- (void) setLayoutManager:(NSLayoutManager *) lm; { layoutManager=lm; }
- (void) setLineFragmentPadding:(float) pad; { lineFragmentPadding=pad; }

- (void) setTextView:(NSTextView *) tv;
{
	NSNotificationCenter *nc;
	if(textView == tv)
		return;
	nc=[NSNotificationCenter defaultCenter];
	if(textView)
		{ // disconnect from text view
			[textView setPostsFrameChangedNotifications:NO];	// no need to notify any more...
			[textView setTextContainer:nil];
			[nc removeObserver:self name:NSViewFrameDidChangeNotification object:textView];
			[textView release];
			textView=nil;
		}
	if(tv)
		{ // connect to text view
			textView=[tv retain];
			[textView setTextContainer:self];
			[textView setPostsFrameChangedNotifications:YES];	// should notify...
			[nc addObserver:self selector:@selector(_track:) name:NSViewFrameDidChangeNotification object:textView];
			[self _track:nil];	// initial "notification"
		}
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
	return [self initWithString:@""];
}

- (id) initWithString:(NSString *) str
{
	return [self initWithString:str attributes:nil];
}

- (id) initWithString:(NSString *) str attributes:(NSDictionary *) attr
{
#if __APPLE__
	if((self=[super init]))
		{
		_concreteString=[[NSMutableAttributedString alloc] initWithString:str attributes:attr];
		_layoutManagers=[NSMutableArray new];
		}
#else
	if((self=[super initWithString:str attributes:attr]))
		{
		_layoutManagers=[NSMutableArray new];
		}
#endif
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
	[self setDelegate:nil];
#if __APPLE__
	[_concreteString release];
#endif
	[_layoutManagers release];
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
	if(_nestingCount == 0)
		{
		_editedMask = editedMask;
		_editedRange = range;
		_changeInLength = delta;
		[self processEditing];		
		}
	else
		{
		_editedMask |= editedMask;
		_editedRange.location = MIN(_editedRange.location, range.location);
		_editedRange.length = MAX(NSMaxRange(_editedRange), NSMaxRange(range))-_editedRange.location;
		_changeInLength += delta;
		}
}

- (void) beginEditing;
{
	if(_nestingCount == 0)
		{
		_editedMask = 0;
		_editedRange = (NSRange) { 0, 0 };
		_changeInLength = 0;
		}
	_nestingCount++;
}

- (void) endEditing;
{
	if(_nestingCount)
		NSLog(@"unbalanced endEditing");
	else
		_nestingCount--;
	[self fixAttributesInRange:_editedRange];
	[self processEditing];
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
	if(!_fixesAttributesLazily)
		[self fixAttributesInRange:_editedRange];
	[nc postNotificationName:NSTextStorageDidProcessEditingNotification object:self];
	while((lm=[e nextObject]))
		[lm textStorage:self
				 edited:_editedMask
				  range:_editedRange	// FIXME: this should be the new range!?!
		 changeInLength:_changeInLength
	   invalidatedRange:_editedRange];	// FIXME: this should be the range where attributes were fixed
}

- (void) removeLayoutManager:(NSLayoutManager *)obj; { [obj setTextStorage:nil]; [_layoutManagers removeObject:obj]; }

- (void) setDelegate:(id)obj;
{
	NSNotificationCenter *nc=[NSNotificationCenter defaultCenter];
	if(_delegate)
		{ // disconnect delegate
			[nc removeObserver:obj name:NSTextStorageDidProcessEditingNotification object:self];
			[nc removeObserver:obj name:NSTextStorageWillProcessEditingNotification object:self];
		}
	_delegate=obj;
	if(_delegate)
		{ // connect delegate
			[nc addObserver:obj selector:@selector(textStorageDidProcessEditing:) name:NSTextStorageDidProcessEditingNotification object:self];
			[nc addObserver:obj selector:@selector(textStorageWillProcessEditing:) name:NSTextStorageWillProcessEditingNotification object:self];
		}
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
#endif
	if(self)
		{
		_layoutManagers=[NSMutableArray new];
		[self setDelegate:[coder decodeObjectForKey:@"NSDelegate"]];
		}
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
#if __APPLE__
	[_concreteString replaceCharactersInRange:rng withAttributedString:str];
#else
	[super replaceCharactersInRange:rng withAttributedString:str];
#endif
	[self edited:NSTextStorageEditedCharacters|NSTextStorageEditedAttributes range:rng changeInLength:[str length]-rng.length];
}

- (void) replaceCharactersInRange:(NSRange) rng withString:(NSString *) str
{
#if __APPLE__
	[_concreteString replaceCharactersInRange:rng withString:str];
#else
	[super replaceCharactersInRange:rng withString:str];
#endif
	[self edited:NSTextStorageEditedCharacters range:rng changeInLength:[str length]-rng.length];
}

- (void) setAttributedString:(NSAttributedString *) str;
{
	unsigned prevLen=[self length];
#if __APPLE__
	if(_concreteString == str)
		return;	// no change
	[_concreteString release];
	_concreteString=[str mutableCopy];	// may be immutable...
#else
	[super setAttributedString:str];
#endif
	[self edited:NSTextStorageEditedCharacters|NSTextStorageEditedAttributes range:NSMakeRange(0, prevLen) changeInLength:[str length]-prevLen];
}

- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
#if __APPLE__
	[_concreteString setAttributes:attributes range:aRange];
#else
	[super setAttributes:attributes range:aRange];
#endif
	[self edited:NSTextStorageEditedAttributes range:aRange changeInLength:0];
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
