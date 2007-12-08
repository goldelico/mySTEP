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
	idx=[[layoutManager textContainers] indexOfObject:self];	// find current text container
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

- (void) setTextView:(NSTextView *) tv;
{
	[textView setTextContainer:nil]; ASSIGN(textView, tv);
	[textView setTextContainer:self];
	// make us track size changes of the text view frame
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
#define HEIGHTTRACKS ((tcFlags&0x01)!=0)
	heightTracksTextView=HEIGHTTRACKS;
#define WIDTHTRACKS ((tcFlags&0x02)!=0)
	widthTracksTextView=WIDTHTRACKS;
	layoutManager=[coder decodeObjectForKey:@"NSLayoutManager"];
	textView=[[coder decodeObjectForKey:@"NSTextView"] retain];
	size.height=[coder decodeFloatForKey:@"NSHeight"];
	size.width=[coder decodeFloatForKey:@"NSWidth"];
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
		concreteString=[NSMutableAttributedString new];
#endif
		layoutManagers=[NSMutableArray new];
		}
	return self;
}

- (id) initWithAttributedString:(NSAttributedString *) str;
{
#if __APPLE__
	if((self=[super init]))
		{
		concreteString=[[NSMutableAttributedString alloc] initWithAttributedString:str];
		layoutManagers=[NSMutableArray new];
		}
#else
	if((self=[super initWithAttributedString:str]))
		{
		layoutManagers=[NSMutableArray new];
		}
#endif
	return self;
}

- (void) dealloc;
{
	NSLog(@"dealloc %p: %@", self, self);
#if __APPLE__
	[concreteString release];
#endif
	[layoutManagers release];
	[self setDelegate:nil];
	[super dealloc];
}

- (void) addLayoutManager:(NSLayoutManager *)lm; { [layoutManagers addObject:lm]; [lm setTextStorage:self]; }
- (int) changeInLength; { NIMP; return 0; }	// FIXME: send a delegate and/or layout manager message
- (id) delegate; { return delegate; }

- (void) edited:(unsigned)editedMask 
		  range:(NSRange)range 
 changeInLength:(int)delta;
{
	if(delta != 0)
		[self changeInLength];
	NIMP;
}

- (void) beginEditing;
{
}

- (void) endEditing;
{
//	[self fixAttributesInRange:editedRange];
// inform NSLayoutManager(s)
		[self changeInLength];
}

- (unsigned int) editedMask; { NIMP; return 0; }
- (NSRange) editedRange; { return editedRange; }
- (void) ensureAttributesAreFixedInRange:(NSRange)range;
{
	NIMP;
}

- (BOOL) fixesAttributesLazily; { return fixesAttributesLazily; }

- (void) invalidateAttributesInRange:(NSRange)range;
{
	NIMP;
}

- (NSArray *) layoutManagers; { return layoutManagers; }
- (void) processEditing;
{
	NIMP;
	return;
}

- (void) removeLayoutManager:(NSLayoutManager *)obj; { [obj setTextStorage:nil]; [layoutManagers removeObject:obj]; }

- (void) setDelegate:(id)obj;
{
	if(delegate)
		; // disconnect notifications
	delegate=obj;
	if(delegate)
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
	concreteString=[[NSMutableAttributedString alloc] initWithCoder:coder];
#else
	self=[super initWithCoder:coder];	// we are a real subclass of NSMutableAttributedString
	NSLog(@"FIXME: doesn't unarchive textStorage's attributes properly");
	// FIXME: these should be decoded in NSAttributedString!
	[coder decodeObjectForKey:@"NSAttributes"];	// this is an array of attribute runs
	[coder decodeObjectForKey:@"NSAttributeInfo"];	// NSAttributeInfo is most probably a list of ranges where the attributes apply (unless it is for the full range)
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
	return [concreteString string];
}

- (NSMutableString *) mutableString;
{
	// we might cache since this is called pretty often
	return [concreteString mutableString];
}

- (void) replaceCharactersInRange:(NSRange) rng withAttributedString:(NSAttributedString *) str
{
	return [concreteString replaceCharactersInRange:rng withAttributedString:str];
}

- (void) replaceCharactersInRange:(NSRange) rng withString:(NSString *) str
{
	return [concreteString replaceCharactersInRange:rng withString:str];
}

- (NSDictionary *) attributesAtIndex:(unsigned) index effectiveRange:(NSRangePointer) range
{
	NSDictionary *d;
//	return [concreteString attributesAtIndex:index effectiveRange:range];
	NS_DURING
		d=[concreteString attributesAtIndex:index effectiveRange:range];
	NS_HANDLER
		NSLog(@"exception for %@", self);
		NSLog(@"concrete string %@", concreteString);
		NSLog(@"concrete string length %u", [concreteString length]);
		NSLog(@"index %d", index);
		d=nil;
	NS_ENDHANDLER
	return d;
}

- (NSDictionary *) attributesAtIndex:(unsigned) index longestEffectiveRange:(NSRangePointer) longest inRange:(NSRange) range
{
	NSDictionary *d;
	//	return [concreteString attributesAtIndex:index longestEffectiveRange:longest inRange:range];
	NS_DURING
		d=[concreteString attributesAtIndex:index longestEffectiveRange:longest inRange:range];
	NS_HANDLER
		NSLog(@"exception for %@", self);
		NSLog(@"concrete string %@", concreteString);
		NSLog(@"concrete string length %u", [concreteString length]);
		NSLog(@"index %d", index);
		d=nil;
	NS_ENDHANDLER
	return d;
}

- (void) setAttributedString:(NSAttributedString *) str;
{
	[str retain];
	[concreteString setAttributedString:str];
	[str release];
}

- (void) setAttributes:(NSDictionary *)attributes range:(NSRange)aRange
{
	[concreteString setAttributes:attributes range:aRange];
}

#endif

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
