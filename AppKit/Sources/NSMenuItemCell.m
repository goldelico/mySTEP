//
//  MenuItemCell.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Mar 29 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

/* FIXME:

should be made a real subclass of NSButtonCell
setting appropriate attributes (incl. Font) in -init so that it behaves as a menu item
then, use super's (new in OS X 10.4):
- (void)drawImage:(NSImage*)image withFrame:(NSRect)frame inView:(NSView*)controlView
- (void)drawTitle:(NSAttributedString*)title withFrame:(NSRect)frame inView:(NSView*)controlView
to draw its components
- (void)calcSize not only calculates the size but also fetches all info (images, title) needed from the menuItem
doing this is a little tricky because this needs to change the button background color depending on highlight&enabled state
and menu item state is not the same as cell highlighting...

Finally, NSPopUpButtonCell can be a real subclass of NSMenuItemCell

	also setting appropriate attributes (incl. Font) in -init so that it looks like a menu item
	but [super setTitle:...] can still be used

*/

#import <AppKit/NSMenuItemCell.h>
#import <AppKit/NSMenuItem.h>
#import <AppKit/NSMenuView.h>
// #import <AppKit/NSBezierPath.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSStatusBar.h>
#import <AppKit/NSStatusItem.h>
#import "NSAppKitPrivate.h"

#define ARROW_WIDTH		6.0
#define ARROW_PAD		2.0		// to right border
#define ARROW_HEIGHT	(2.0*3.0/4.0*ARROW_WIDTH)	// make triangular

@interface NSMenuItemCell (Private)
// FIXME: why is this a mutable string?
- (NSMutableAttributedString *) _keyEquivalentAttributedString;
- (NSImage *) _stateImage;
- (NSColor *) _textColor;
- (NSAttributedString *) _titleAttributedString;
@end

@implementation NSMenuItemCell

// overridden

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ in %@ representing item %@ size %@", 
		NSStringFromClass([self class]),
		@"menuView", [menuItem title], 
		NSStringFromSize(size)];
}

- (void) dealloc;
{
#if 0
	NSLog(@"NSMenuItemCell dealloc %@", self);
#endif
	[menuItem release];
	[super dealloc];
}

- (BOOL) showsFirstResponder; { return NO; }

- (void) drawInteriorWithFrame:(NSRect) frame inView:(NSView *) view;
{ // main interface for drawing
#if 0
	NSLog(@"drawInteriorWithFrame:%@ - %@", NSStringFromRect(frame), self);
#endif
	if(!needsDisplay)
		return;	// ignore and postpone sizing
	if(needsSizing)
		[self calcSize];
	[self drawBorderAndBackgroundWithFrame:frame inView:view];			// draw the background
	if(menuItem && [menuItem isSeparatorItem])
		[self drawSeparatorItemWithFrame:frame inView:view];
	else
		{
		if(imageWidth != 0.0)
			[self drawImageWithFrame:frame inView:view];				// draw the image
		if(titleWidth != 0.0)
			[self drawTitleWithFrame:frame inView:view];				// draw the title
		if(stateImageWidth != 0.0)
			[self drawStateImageWithFrame:frame inView:view];			// checked/unchecked
		if(keyEquivalentWidth != 0.0)
			[self drawKeyEquivalentWithFrame:frame inView:view];		// draw the key equivalent or the submenu arrow
		}
	needsDisplay=NO;
}

- (id) init	{ return [self initTextCell:@"MenuItem"]; }

- (id) initTextCell:(NSString *) text;
{
#if 0
	NSLog(@"NSMenuItemCell init");
#endif
	self=[super initTextCell:text];	// this is NSButtonCell's init
	if(self)
		{
#if FUTURE
		/// nonono: images should be part of NSMenuItem!
		_alternateImage=(NSImage *) [[NSButtonImageSource alloc] initWithName:@"NSMenuItem"];
		// [self setShowsBorderOnlyWhileMouseInside:YES];
		// [self setAlignment:NSLeftTextAlignment];
		// [self setTitle:@"-uninitialized-"];
#endif
		[self setButtonType:NSMomentaryPushInButton];
		[self setImagePosition:NSImageLeft];
		[self setHighlightsBy:NSChangeGrayCellMask];
		[self setShowsStateBy:NSContentsCellMask];
		[self setAllowsMixedState:YES];
		[self setNeedsSizing:YES];
		[self setNeedsDisplay:YES];
		}
	return self;
}

- (NSSize) cellSize;
{ // return size
	if(needsSizing)
		[self calcSize];
#if 0
	NSLog(@"cellSize=%@", NSStringFromSize(size));
#endif
	return size;
}

- (NSImage *) _stateImage;
{ // get state image depending on menuItem
	switch([menuItem state]) {
		case NSOffState:
		default:			return [menuItem offStateImage]?:[NSImage imageNamed:@"NSMenuUnchecked"];
		case NSMixedState:	return [menuItem mixedStateImage]?:[NSImage imageNamed:@"NSMenuMixedState"];
		case NSOnState:		return [menuItem onStateImage]?:[NSImage imageNamed:@"NSMenuCheckmark"];
		}
}

- (NSColor *) _textColor;
{ // get text color to use
	if([self isHighlighted])
		return [NSColor selectedMenuItemTextColor];	// white letters on blue
	if([menuItem isEnabled])
		return [NSColor controlTextColor];			// standard control text color
	else
		return [NSColor disabledControlTextColor];	// is disabled
}

- (NSAttributedString *) _titleAttributedString;
{ // get attributed string
	NSAttributedString *s;
	NSRange r;
#if 0
	NSLog(@"get attributed titleString (%@)", [menuItem title]);
#endif
	if([[menuItem representedObject] respondsToSelector:@selector(attributedTitle)])
		s=[[menuItem representedObject] attributedTitle];	// status item...
	else if(!(s=[menuItem attributedTitle]))
		{ // convert standard title
		s=[[NSMutableAttributedString alloc] initWithString:([[menuItem title] length]>0?[menuItem title]:@" ")]; // at least one character wide
		r=NSMakeRange(0, [s length]);
#if 0
		NSLog(@"range=%@", NSStringFromRange(r));
#endif
		if(r.length)
			{ // apply menu font and color
			NSFont *f=[(NSControl *) _controlView font];
			[(NSMutableAttributedString *) s addAttribute:NSForegroundColorAttributeName value:[self _textColor] range:r];
			if(f)
				[(NSMutableAttributedString *) s addAttribute:NSFontAttributeName value:f range:r];
			}
		[s autorelease];
		}
#if 0
	NSLog(@"titleString=%@", [s string]);
#endif
	return s;
}

- (NSMutableAttributedString *) _keyEquivalentAttributedString;
{ // get attributed string
	NSString *e;
	NSUInteger m;
	NSMutableAttributedString *s;
	NSString *key=[menuItem keyEquivalent];
	NSString *lcKey=[key lowercaseString];
	NSString *ucKey=[key uppercaseString];
	NSRange r;
	BOOL shift;
	if([key length] == 0 || [(NSMenuView *) _controlView isHorizontal])
		return [[[NSMutableAttributedString alloc] initWithString:@""] autorelease]; // no shortcut defined and never display on horizontal menus
	m=[menuItem keyEquivalentModifierMask]; // get mask
	shift=(m&NSShiftKeyMask);	// mask is set (Function keys only)
#if 0
	NSLog(@"get attributed keyEquivalentAttributedString for %@", [menuItem keyEquivalent]);
	NSLog(@"get attributed keyEquivalentModifierMask=%x", m);
#endif
#if 0
	// translate \r, \b, etc. to printable Unicode characters like ⎋⏏⌫
	if([key isEqualToString:@"\\r"])
		key=@"RET";
	else if([key isEqualToString:@"\\e"])
		key=@"ESC";
	else if([key isEqualToString:@"\\d"])
		key=@"⌫";
	// handle function keys
	else
		shift |= ![key isEqualToString:lcKey];	// is a upper case string
	e=[NSString stringWithFormat:@"%@%@%@%@%@",
			(m&NSControlKeyMask)?@"⌃":@"",
		  (m&NSAlternateKeyMask)?@"⌥":@"",
						   shift?@"⌂":@"",
			(m&NSCommandKeyMask)?@"⌘":@"",
		 ucKey];
#else
	if([key isEqualToString:@"\\r"])
		key=@"RET";
	else if([key isEqualToString:@"\\e"])
		key=@"ESC";
	else if([key isEqualToString:@"\\d"])
		key=@"DEL";
	// handle function keys
	else
		shift |= ![key isEqualToString:lcKey];	// is a upper case string
	e=[NSString stringWithFormat:@"%@%@%@%@%@",
	   (m&NSControlKeyMask)?@"^":@"",
	 (m&NSAlternateKeyMask)?@"+":@"",
					  shift?@"/":@"",
	   (m&NSCommandKeyMask)?@"#":@"",
		 ucKey];
#endif
	s=[[[NSMutableAttributedString alloc] initWithString:e] autorelease];
	r=NSMakeRange(0, [s length]);
#if 0
	NSLog(@"range=%@", NSStringFromRange(r));
#endif
	[s addAttribute:NSForegroundColorAttributeName value:[self _textColor] range:r];
	if(_controlView)
		[s addAttribute:NSFontAttributeName value:[(NSControl *) _controlView font] range:r];
#if 0
	NSLog(@"keyEquivalentAttributedString=%@", [s string]);
#endif
	return s;
}

- (BOOL) acceptsFirstResponder		{ return NO; }		// never ever...

// new methods

- (void) calcSize;
{
	// FIXME: we should check MenuItem and delegate etc. only here
	// and copy everthing to our superclass NSButtonCell (i.e. setTitle, setImage, setAlterateImage, _setMixedImage, setState)
	
	NSAttributedString *as;
	BOOL isHorizontal;
	CGFloat horizontalEdgePadding;
#if 0
	NSLog(@"%@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
#endif
	if(!needsSizing)
		return;
#if FUTURE
	_isSeparator=[menuItem isSeparatorItem];
	if(!_isSeparator)
		{
		[super setAlternateImage:[menuItem offStateImage]];
		[super setImage:[menuItem onStateImage]];
		[super _setMixedImage:[menuItem mixedStateImage]];
		[super setTitle:[self _titleAttributedString]];
		[super setEnabled:[menuItem _validate]];
		}
	else
		[super setTitle:@""];
#endif	
#if 0
	NSLog(@"menuItem celltype=%lu", (unsigned long)[self type]);
	NSLog(@"menuItem isSeparatorItem=%d", [menuItem isSeparatorItem]);
#endif
	needsSizing=NO;	// break recursion triggered by [_controlView keyEquivalentOffset] below
	isHorizontal=[(NSMenuView *) _controlView isHorizontal];
	horizontalEdgePadding=[(NSMenuView *) _controlView horizontalEdgePadding];
	as=[self _titleAttributedString];
	if(as)
		{
		size=[as size];	// title size/height determines everything
#if 0
		NSLog(@"menuItem %@ size=%@", [as string], NSStringFromSize(size));
#endif
		}
	else
		size=NSMakeSize(0.0, 10.0);	// no title but needs some height
	if([menuItem isSeparatorItem])
		size.height*=0.8;		// reduce size of separator items to 80% - title should be an empty string and size being determined by font
	titleWidth=size.width;		// determine by text length
#if 0
	NSLog(@"%@.cellSize=%@", [menuItem title], NSStringFromSize(size));
#endif
	stateImageWidth=0.0;
	if(!isHorizontal)
		{ // vertical menu has state image, key equivalents, submenu arrow
		int i;
#if 0
		NSLog(@"calcSize vertical");
		NSLog(@"_keyEquivalentAttributedString=%@", [self _keyEquivalentAttributedString]);
#endif
		if([menuItem hasSubmenu])
			keyEquivalentWidth=ARROW_WIDTH+ARROW_PAD; 	// room for submenu arrow
		else
			{
			as=[self _keyEquivalentAttributedString];
			if(as)
				keyEquivalentWidth=[as size].width;
			else
				keyEquivalentWidth=0.0;	// no key equivalent
#if 0
			NSLog(@"as=%@ size=%@ keyEquivalentWidth=%lf", as, NSStringFromSize([as size]), keyEquivalentWidth);
#endif
			}
		for(i=0; i<3; i++)
			{ // get maximum size of all three state images
			NSImage *img;
			switch(i)
				{
				case 0:	img=[menuItem offStateImage]; break;
				case 1:	img=[menuItem onStateImage]; break;
				case 2:	img=[menuItem mixedStateImage]; break;
				default: continue;
				}
			if(img)
				{ // image exists - enlarge
				NSSize s=[img size];
#if 0
				NSLog(@"%d s=%@ img=%@", i, NSStringFromSize(s), img);
#endif
				stateImageWidth=MAX(stateImageWidth, s.width);
				size.height=MAX(size.height, s.height);	// enlarge cell to maximum height
				}
			}
#if 0
			NSLog(@"%@.cellSize=%@", [menuItem title], NSStringFromSize(size));
#endif
		}
	else
		{ // horizontal menu
#if 0
		NSLog(@"calcSize horizontal");
#endif
		size.height=[_controlView frame].size.height;	// full menu bar height
		keyEquivalentWidth=0.0;		// not required
		stateImageWidth=0.0;		// not required
		}
	if([menuItem image])
		{ // has explicit menu item image
		NSSize s;
#if 0
		NSLog(@"NSMenuItem image: %@", [menuItem image]);
#endif
		s=[[menuItem image] size];
#if 0
		NSLog(@"NSMenuItem image size=%@", NSStringFromSize(s));
#endif
		imageWidth=s.width;			// full image width
		if(!isHorizontal)
			size.height=MAX(size.height, s.height);	// enlarge cell height by item image
		}
	else
		imageWidth=0.0;			// no image
	size.width+=2.0*horizontalEdgePadding;	// left and right padding
	if(stateImageWidth > 0)
		size.width+=horizontalEdgePadding+stateImageWidth;
	if(imageWidth > 0)
		size.width+=horizontalEdgePadding+imageWidth;
	if(keyEquivalentWidth > 0)
		size.width+=horizontalEdgePadding+keyEquivalentWidth;
	if(isHorizontal && [[menuItem representedObject] respondsToSelector:@selector(length)])
		{ // may be a status item - override width if it is specified
		CGFloat len=[((NSStatusItem *) [menuItem representedObject]) length];	// get length
#if 0
		NSLog(@"NSMenuItemCell %@ representedObject %@ length=%f", menuItem, [menuItem representedObject], len);
#endif
		if(len == NSSquareStatusItemLength)
			{ // determine by enclosing view's height (if possible)
			size.width=[_controlView frame].size.height;	// make it square
			}
		else if(len >= 0.0)
			{ // override fixed width
			size.width=rintf(len); // round to nearest integer
#if 0
			NSLog(@"fixed width: %@", NSStringFromSize(size));
#endif
			}
		if(size.width < imageWidth)
			imageWidth=size.width, titleWidth=0.0;	// shrink
		else if(size.width < imageWidth+horizontalEdgePadding+titleWidth)
			{
			titleWidth=size.width-imageWidth-horizontalEdgePadding;
			if(titleWidth < 0)
				titleWidth=0.0;
			}
		}
	size.height+=4.0;		// leave some vertical spacing
#if 0
	NSLog(@"calcSize done: %@", self);
#endif
}

- (void) drawBorderAndBackgroundWithFrame:(NSRect) frame inView:(NSView *) view;
{ // fill (highlighted) background
#if 0
	NSLog(@"%@ drawBorderAndBackgroundWithFrame:%@ isHighlighted=%d", self, NSStringFromRect(frame), [self isHighlighted]);
#endif
	if([[menuItem representedObject] respondsToSelector:@selector(drawMenuBackground:)])	// old NSMenuExtra (where do we have this method from???)
		[[menuItem representedObject] drawMenuBackground:[self isHighlighted]];
	else if([[menuItem representedObject] respondsToSelector:@selector(drawStatusBarBackgroundInRect:withHighlight:)])	// official
		[[menuItem representedObject] drawStatusBarBackgroundInRect:frame withHighlight:[self isHighlighted]];
	else
		{
		[[self isHighlighted]?[NSColor selectedMenuItemColor]:[NSColor windowBackgroundColor] set];
		NSRectFill(frame);
		}
}

// FIXME: should somehow use drawImage:withFrame:inView: (NSButtonCell)

- (void) drawImageWithFrame:(NSRect) frame inView:(NSView *) view;
{
	NSImage *i=[menuItem image];
	if(!i)
		return;	// no image
	frame=[self imageRectForBounds:frame];	// translate
#if 0
	NSLog(@"frame:%@\nimage=%@", NSStringFromRect(frame), i);
#endif
	[self _drawImage:i withFrame:frame inView:view];
}

- (void) drawKeyEquivalentWithFrame:(NSRect) frame inView:(NSView *) view;
{
	NSAttributedString *as;
	NSSize s;
#if 0
	NSLog(@"drawKeyEquivalentWithFrame:%@ keyequiv==%@", NSStringFromRect(frame), [self _keyEquivalentAttributedString]);
#endif
	if(keyEquivalentWidth == 0.0)
		return; // don't draw
	frame=[self keyEquivalentRectForBounds:frame];	// translate
	if(_controlView && [menuItem hasSubmenu])
		{ // draw right aligned arrow for submenus
		static NSImage *__branchImage;
#if 0
		NSBezierPath *b=[NSBezierPath bezierPath];
		//	NSLog(@"draw arrow in frame %@", NSStringFromRect(frame));
		[[self _textColor] set];
		[b moveToPoint:NSMakePoint(frame.origin.x+frame.size.width-ARROW_WIDTH-ARROW_PAD, frame.origin.y+(frame.size.height-ARROW_HEIGHT)/2.0)];
		[b lineToPoint:NSMakePoint(frame.origin.x+frame.size.width-ARROW_PAD, frame.origin.y+(frame.size.height+0.0)/2.0)];
		[b lineToPoint:NSMakePoint(frame.origin.x+frame.size.width-ARROW_WIDTH-ARROW_PAD, frame.origin.y+(frame.size.height+ARROW_HEIGHT)/2.0)];
		[b closePath];
		[b fill];	// draw arrow at the end
#endif
		if(!__branchImage)
			__branchImage = [[NSImage imageNamed: @"GSSubmenuArrow"] retain];
			[self _drawImage:__branchImage withFrame:frame inView:view];
			//		[__branchImage compositeToPoint:NSMakePoint(frame.origin.x+frame.size.width-[__branchImage size].width, frame.origin.y+6.0)
			//				  operation:NSCompositeHighlight];
		return;		// suppress key equivalent (even if present!)
		}
	as=[self _keyEquivalentAttributedString];
	s=[as size];
	frame.origin.x+=frame.size.width-s.width;
	frame.size.width=s.width;	// align right
	frame.origin.y += (frame.size.height-s.height)/2.0;	// center
	[as drawInRect:frame];
}

- (void) drawSeparatorItemWithFrame:(NSRect) frame inView:(NSView *) view;
{
#if 0	// could use some style setting
	[[self _textColor] set];
	if([(NSMenuView *) _controlView isHorizontal])
		{ // draw vertical line centered in frame
		NSDrawRect(NSMakeRect(frame.origin.x+frame.size.width/2.0, frame.origin.y, 1.0, frame.size.height));
		}
	else
		{ // draw horizontal line centered in frame
		NSDrawRect(NSMakeRect(frame.origin.x, frame.origin.y+frame.size.height/2.0, frame.size.width, 1.0));
		}
#endif
}

- (void) drawStateImageWithFrame:(NSRect) frame inView:(NSView *) view;
{
	NSImage *i=[self _stateImage];  // current state image
	if(!i || stateImageWidth == 0.0)
		return;	// empty or don't draw or use default?
	frame=[self stateImageRectForBounds:frame];	// translate
#if 0
	NSLog(@"frame:%@\nstateImage=%@", NSStringFromRect(frame), i);
#endif
	[self _drawImage:i withFrame:frame inView:view];
	//	[i compositeToPoint:frame.origin operation:NSCompositeHighlight];
}

- (void) drawTitleWithFrame:(NSRect) frame inView:(NSView *) view;
{
#if NEW
	// must implement/override titleRectForBounds in NSButtonCell
	[self drawTitle:[self _titleAttributedString] withFrame:frame inView:view];
#endif
	NSRect r=[self titleRectForBounds:frame];
	NSAttributedString *ts=[self _titleAttributedString];
#if 0
	NSLog(@"drawTitleWithFrame:%@->%@ - title=%@", NSStringFromRect(frame), NSStringFromRect(r), [[self _titleAttributedString] string]);
#endif
	[ts drawInRect:r];	// start at top left
}

- (NSRect) imageRectForBounds:(NSRect) frame;
{
	if(needsSizing)
		[self calcSize];
	frame.origin.x+=[(NSMenuView *) _controlView imageAndTitleOffset];		// starts right of state image
	// FIXME: should keep aspect ratio!!!
	frame.size.width=imageWidth;						// use this size
	return NSInsetRect(frame, 0, 2);
}

- (CGFloat) imageWidth;
{
	if(needsSizing)
		[self calcSize];
	return imageWidth;
}

- (BOOL) isHighlighted; { return [super isHighlighted]; }

- (NSRect) keyEquivalentRectForBounds:(NSRect) frame;
{
	if(needsSizing)
		[self calcSize];
	frame.origin.x+=[(NSMenuView *) _controlView keyEquivalentOffset];	// starts right of text
	frame.size.width=[(NSMenuView *) _controlView keyEquivalentWidth];	// use this size
	return frame;
}

- (CGFloat) keyEquivalentWidth;
{
	if(needsSizing)
		[self calcSize];
	return keyEquivalentWidth;
}

- (NSMenuItem *) menuItem;	{ return menuItem; }
- (NSMenuView *) menuView;	{ return (NSMenuView *) _controlView; }
- (BOOL) needsDisplay;		{ return needsDisplay; }
- (BOOL) needsSizing;		{ return needsSizing; }

- (void) setHighlighted:(BOOL) flag;
{
#if 0
	NSLog(@"setHighlighted:%d", flag);
#endif
	[super setHighlighted:flag];
	needsDisplay=YES;
}

- (void) setMenuItem:(NSMenuItem *) item;
{
	ASSIGN(menuItem, item);
	needsSizing=YES;
	needsDisplay=YES;
}

- (void) setMenuView:(NSMenuView *) mV;
{
	_controlView=mV;	// not retained - would otherwise create retained-pointer-loop with NSMenuView's _cells array
	needsSizing=YES;
	needsDisplay=YES;
}

- (void) setNeedsDisplay:(BOOL) flag;
{
#if 0
	NSLog(@"setNeedsDisplay %@", self);
#endif
	needsDisplay=flag;
}

- (void) setNeedsSizing:(BOOL) flag;
{
#if 0
	NSLog(@"setNeedsSizing %@", self);
#endif
	needsSizing=flag;
}

#if 0
- (void) calcDrawInfo:(NSRect) frame;
{ // recalculate size
	NSLog(@"calcDrawInfo %@", NSStringFromRect(frame));
	needsSizing=YES;
}
#endif

- (NSRect) stateImageRectForBounds:(NSRect) frame;
{
	if(needsSizing)
		[self calcSize];
	frame.origin.x+=[(NSMenuView *) _controlView stateImageOffset];	// starts right of state image
	frame.size.width=MIN(frame.size.width, [(NSMenuView *) _controlView stateImageWidth]);	// use this size
	return NSInsetRect(frame, 2, 2);
}

- (CGFloat) stateImageWidth;
{
	if(needsSizing)
		[self calcSize];
#if 0
	NSLog(@"cell siw: %lf", stateImageWidth);
#endif
	return stateImageWidth;
}

- (NSRect) titleRectForBounds:(NSRect) frame;
{
	if(needsSizing)
		[self calcSize];
	frame.origin.x+=[(NSMenuView *) _controlView imageAndTitleOffset]+(imageWidth > 0.0?[(NSMenuView *) _controlView horizontalEdgePadding]+imageWidth:0.0);	// starts right of image
	frame.size.width=titleWidth;	// use titleWidth
	frame.origin.y += [(NSMenuView *) _controlView isHorizontal]?8.0:4.0;	// margin from top
#if 0
	NSLog(@"view i&t.w=%lf, iw=%f", [(NSMenuView *) _controlView imageAndTitleWidth], imageWidth);
#endif
	return frame;
}

- (CGFloat) titleWidth;
{
	if(needsSizing)
		[self calcSize];
#if 0
	NSLog(@"cell tw: %lf", titleWidth);
#endif
	return titleWidth;
}

- (NSInteger) tag								{ return tag; }
- (void) setTag:(NSInteger)anInt				{ tag = anInt; }

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if(![aDecoder allowsKeyedCoding])
		return NIMP;
	menuItem = [[aDecoder decodeObjectForKey:@"NSMenuItem"] retain];
	[menuItem setOffStateImage:[aDecoder decodeObjectForKey:@"NSOffImage"]];
	[menuItem setMixedStateImage:[aDecoder decodeObjectForKey:@"NSMixedImage"]];
	[menuItem setOnStateImage:[aDecoder decodeObjectForKey:@"NSOnImage"]];
	return self;
}

@end
