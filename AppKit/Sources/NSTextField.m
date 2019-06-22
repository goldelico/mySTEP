/* 
   NSTextField.m

   Text field control and cell classes

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSDictionary.h>

#import <AppKit/NSBezierPath.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSTextFieldCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSText.h>
#import <AppKit/NSTextStorage.h>

#import "NSAppKitPrivate.h"

#define CONTROL(notif_name) NSControl##notif_name##Notification

//*****************************************************************************
//
// 		NSTextFieldCell 
//
//*****************************************************************************

@implementation NSTextFieldCell

- (id) initTextCell:(NSString *)aString
{
	self=[super initTextCell:aString];
	if(self)
		{
		_c.editable = YES;
		_c.selectable = YES;
		_c.bordered = NO;
		_c.bezeled = YES;
		_c.scrollable = YES;
			[self setAlignment:NSLeftTextAlignment];
			_c.drawsBackground = NO;	// default to no background
			ASSIGN(_backgroundColor, [NSColor textBackgroundColor]); 
			[self _setTextColor:[NSColor textColor]];
		}
	return self;
}

- (void) dealloc
{
	[_backgroundColor release];
	[_placeholderString release];	// if any
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone;
{
	NSTextFieldCell *c = [super copyWithZone:zone];

	[c setBackgroundColor: _backgroundColor];
	[c setPlaceholderString: _placeholderString];
	[c _setTextColor: [self _textColor]];
	
	return c;
}

- (NSSize) cellSize
{
	NSFont *f;
	NSSize borderSize, s;

	if ([self isBordered])							// Determine border size
		borderSize = ([self isBezeled]) ? (NSSize){2,2} : (NSSize){1,1};
	else
		borderSize = NSZeroSize;

	f = [self font];							 	//  Get size of text with a little buffer space
	
	s=[[self stringValue] sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:f, NSFontAttributeName, nil]];
	s.width += 4 + 2 * borderSize.width;				// Add in border size
	s.height += 2 + 2 * borderSize.height;
	
	return s;
}

- (BOOL) isOpaque							{ return _c.drawsBackground;}
- (BOOL) drawsBackground					{ return _c.drawsBackground; }
- (NSTextFieldBezelStyle) bezelStyle;		{ return _bezelStyle; }
- (void) setDrawsBackground:(BOOL)flag		{ _c.drawsBackground = flag; }
- (void) setBackgroundColor:(NSColor*)color { ASSIGN(_backgroundColor, color); }
- (void) setBezelStyle:(NSTextFieldBezelStyle)style;	{ _bezelStyle=style; }
- (void) setTextColor:(NSColor*)aColor		{ [super _setTextColor:aColor]; }
- (NSColor *) backgroundColor				{ return _backgroundColor; }
- (NSColor *) textColor						{ return [super _textColor]; }
- (NSString *) placeholderString;			{ return ([_placeholderString isKindOfClass:[NSString class]])?_placeholderString:nil; }
- (void) setPlaceholderString:(NSString *) string; { ASSIGN(_placeholderString, string); }
- (NSAttributedString *) placeholderAttributedString;	{ return ([_placeholderString isKindOfClass:[NSAttributedString class]])?_placeholderString:nil; }
- (void) setPlaceholderAttributedString:(NSAttributedString *) string; { ASSIGN(_placeholderString, string); }

- (void) drawInteriorWithFrame:(NSRect)cellFrame
						inView:(NSView*)controlView
{
	if(_c.bezeled || _c.bordered) 
		{
		if(_bezelStyle == NSTextFieldRoundedBezel)
			cellFrame = NSInsetRect(cellFrame, 6, 2);
		else
			cellFrame = NSInsetRect(cellFrame, 1, 1);
		}
#if 0
	NSLog(@"-[super drawInteriorWithFrame:%@", NSStringFromRect(cellFrame));
#endif
	[super drawInteriorWithFrame:cellFrame inView:controlView];  // default (formatted) drawing method of NSCell
}

- (void) drawWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
#if 0
	NSLog(@"%@ drawWithFrame:%@", NSStringFromClass([self class]), NSStringFromRect(cellFrame));
	NSLog(@"editable=%@", _c.editable?@"YES":@"NO");
	NSLog(@"editing=%@", _c.editing?@"YES":@"NO");
	NSLog(@"bezeled=%@", _c.bezeled?@"YES":@"NO");
	NSLog(@"bordered=%@", _c.bordered?@"YES":@"NO");
	NSLog(@"drawsBackground=%@", _c.drawsBackground?@"YES":@"NO");
	NSLog(@"_backgroundColor=%@", _backgroundColor);
#endif
	if([self showsFirstResponder])
		{ // button is a first responder cell
		NSColor *y = [NSColor selectedControlColor];
		NSColor *c[] = {y, y, y, y};
		NSRect cellRing=NSInsetRect(cellFrame, -1, -1);	// draw around
		NSDrawColorTiledRects(cellRing,cellRing,[controlView isFlipped] ? BEZEL_EDGES_FLIPPED : BEZEL_EDGES_NORMAL,c,4);
			// NSSetFocusRingStyle();	// enlarges clipping area and sets focus ring style
			// NSFrameRect(cellFrame);	// fill
		}
	if(_c.bezeled)
		{
		if(_bezelStyle == NSTextFieldRoundedBezel)
			{
			NSGraphicsContext *ctxt=[NSGraphicsContext currentContext];
			NSBezierPath *p=[NSBezierPath _bezierPathWithRoundedBezelInRect:cellFrame vertical:NO];	// box with halfcircular rounded ends
			if(_c.drawsBackground)
				{
				[ctxt saveGraphicsState];
				[p addClip];	// clip to contour
				[_backgroundColor setFill];
				[p fill];		// fill with background color
				[ctxt restoreGraphicsState];
				}
			[[NSColor blackColor] setStroke];
			[p stroke];		// fill border
			}
		else
			{
			CGFloat grays[] = { NSWhite, NSWhite, NSDarkGray, NSDarkGray,
				NSLightGray, NSLightGray, NSBlack, NSBlack };
			NSRectEdge *edges = BEZEL_EDGES_NORMAL;
			if(_c.drawsBackground)
				{
				[_backgroundColor set];
				NSRectFill(cellFrame);	// fill
				}
			NSDrawTiledRects(cellFrame, cellFrame, edges, grays, 8);
			}
		}
	else
		{ // not bezeled
		if(_c.drawsBackground)
			{
#if 0
			NSLog(@"_backgroundColor=%@", _backgroundColor);
#endif
			[_backgroundColor set];
			NSRectFill(cellFrame);	// fill
			}
		if(_c.bordered)
			{ // but draw cell border if needed.
			[[NSColor blackColor] set];	// black frame
			NSFrameRect(cellFrame);
			}
		}
	if(_c.editing)
		return; // use editor to draw
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (BOOL) trackMouse:(NSEvent *)event inRect:(NSRect)cellFrame ofView:(NSView *)controlView untilMouseUp:(BOOL)untilMouseUp
{
#if 1
	NSLog(@"NSTextFieldCell trackMouse:");
#endif
	if([self isSelectable])
		{ // start editing
			// how does this work if we have no controlView like DOMHTMLInputElements in SWK?
			// FIXME: delegate:[self target]?	// for making <input> work in SWK
		[self editWithFrame:[self drawingRectForBounds:cellFrame] 			
					  inView:controlView				
					  editor:[[controlView window] fieldEditor:YES forObject:self]	
					delegate:controlView	// make our controlView receive text notifications
					   event:event];
		return YES;	// done
		}
	return [super trackMouse:event inRect:cellFrame ofView:controlView untilMouseUp:untilMouseUp];	// standard tracking
}

- (void) encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeObject: _backgroundColor];
	[aCoder encodeObject: [self textColor]];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
#if 0
	NSLog(@"%@ -[NSTextFieldCell initWithCoder:] %@", self, aDecoder);
#endif
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
			// done in NSCell:	_c.drawsBackground = [aDecoder decodeBoolObjectForKey:@"NSDrawsBackground"];
			[self setTextColor:[aDecoder decodeObjectForKey:@"NSTextColor"]];
		_backgroundColor = [[aDecoder decodeObjectForKey:@"NSBackgroundColor"] retain];
		_bezelStyle = [aDecoder decodeIntForKey:@"NSTextBezelStyle"];
		_delegate = [aDecoder decodeObjectForKey:@"NSDelegate"];
#if 0
		NSLog(@"editable=%@", _c.editable?@"YES":@"NO");
		NSLog(@"editing=%@", _c.editing?@"YES":@"NO");
		NSLog(@"bezeled=%@", _c.bezeled?@"YES":@"NO");
		NSLog(@"bordered=%@", _c.bordered?@"YES":@"NO");
		NSLog(@"drawsBackground=%@", _c.drawsBackground?@"YES":@"NO");
		NSLog(@"_backgroundColor=%@", _backgroundColor);
#endif
		return self;
		}
	_backgroundColor = [[aDecoder decodeObject] retain];
	[self setTextColor:[aDecoder decodeObject]];
	return self;
}

@end /* NSTextFieldCell */

//*****************************************************************************
//
// 		NSTextField 
//
//*****************************************************************************

// class variables
static Class __textFieldCellClass = Nil;

@implementation NSTextField

+ (void) initialize
{
	__textFieldCellClass = [NSTextFieldCell class];
}

+ (Class) cellClass							{ return __textFieldCellClass?__textFieldCellClass:[super cellClass]; }
+ (void) setCellClass:(Class)class			{ __textFieldCellClass = class; }

- (id) initWithFrame:(NSRect)frameRect
{
	self=[super initWithFrame:frameRect];
	if(self)
		{
//		[self setCell:[[[[self class] cellClass] new] autorelease]];	// allows to redefine cellClass in subclasses
		[_cell setState:1];	// FIXME: what is this good for???
		}
	return self;
}

- (BOOL) acceptsFirstMouse:(NSEvent *)theEvent { return [_cell isEditable]; } // yes, respond immediately on activation

- (BOOL) acceptsFirstResponder				{ return [_cell isSelectable] && [super acceptsFirstResponder]; }

- (BOOL) needsPanelToBecomeKey				{ return [_cell isEditable]; }

- (BOOL) isFlipped							{ return YES; }
- (BOOL) isEditable							{ return [_cell isEditable]; }
- (BOOL) isSelectable						{ return [_cell isSelectable]; }
- (void) setEditable:(BOOL)flag				{ [_cell setEditable:flag]; }
- (void) setSelectable:(BOOL)flag			{ [_cell setSelectable:flag]; }

- (void) selectText:(id)sender
{
	NSText *t;

	if(!_window)
		return;

	[_cell selectWithFrame:[_cell drawingRectForBounds:_bounds]
		   inView:self
		   editor:(t = [_window fieldEditor:YES forObject:_cell])
		   delegate:self
		   start:(int)0
		   length:[[_cell stringValue] length]];

//	[window makeFirstResponder: t];
}

- (NSColor*) textColor						{ return [_cell textColor]; }
- (NSColor*) backgroundColor				{ return [_cell backgroundColor]; }
- (void) setTextColor:(NSColor*)aColor		{ [_cell setTextColor:aColor]; }
- (void) setBackgroundColor:(NSColor*)clr	{ [_cell setBackgroundColor:clr];}
- (void) setDrawsBackground:(BOOL)flag		{ [_cell setDrawsBackground:flag];}
- (BOOL) drawsBackground					{ return [_cell drawsBackground]; }
- (BOOL) isBezeled							{ return [_cell isBezeled]; }
- (BOOL) isBordered							{ return [_cell isBordered]; }
- (BOOL) isOpaque							{ return [_cell isOpaque]; }
- (void) setBezeled:(BOOL)flag				{ [_cell setBezeled:flag]; }
- (void) setBordered:(BOOL)flag				{ [_cell setBordered:flag]; }
- (id) delegate								{ return _delegate; }
- (void) setDelegate:(id)anObject			{ [super setDelegate:anObject]; }

// Field editor's delegate methods called when editing - delegate is registered to the notification center

- (void) textDidBeginEditing:(NSNotification *)aNotification
{
#if 1
	NSLog(@" NSTextField %@ %@", NSStringFromSelector(_cmd), aNotification);
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidBeginEditing) object: self];
#if 1
	NSLog(@" NSTextField %@ posted", CONTROL(TextDidBeginEditing));			
#endif
}

- (void) textDidChange:(NSNotification *)aNotification
{
#if 1
	NSLog(@" NSTextField %@ %@", NSStringFromSelector(_cmd), aNotification);
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidChange) object: self];
#if 1
	NSLog(@" NSTextField %@ posted", CONTROL(TextDidChange));
#endif
}

- (void) textDidEndEditing:(NSNotification *)aNotification
{
	// FIXME: do the left/right arrow keys always send this notification with NSLeftTextMovement etc.
	// FIXME: can it be ignored? i.e. by NOT calling endEditing? And does the cursor move in this case?
	
	NSNumber *code;
#if 1
	NSLog(@" NSTextField %@ %@", NSStringFromSelector(_cmd), aNotification);
#endif
//	if(![_cell isEntryAcceptable: [aTextObject string]])
//		return;	// ignore
#if 1
	NSLog(@" NSTextField will post %@", CONTROL(TextDidEndEditing));
#endif
	[[NSNotificationCenter defaultCenter] postNotificationName:CONTROL(TextDidEndEditing) object: self];
#if 1
	NSLog(@" NSTextField %@ posted", CONTROL(TextDidEndEditing));
#endif
	// end editing of cell (should validate and set new cell value)
	[_cell endEditing:[aNotification object]];
	
	if((code = [[aNotification userInfo] objectForKey:NSTextMovement]))
		{
		switch([code intValue])
			{
			case NSReturnTextMovement:
				if(![self sendAction:[self action] to:[self target]])
					{ // if this fails:
					  //  [self performKeyEquivalent:event] --- ???
					  // if this fails:
					  //  select text
					}
				break;
			case NSTabTextMovement:
				[_window selectKeyViewFollowingView:self];
				break;
			case NSBacktabTextMovement:
				[_window selectKeyViewPrecedingView:self];
					break;
			case NSIllegalTextMovement:
				break;
			}
		}
}

- (BOOL) textShouldBeginEditing:(NSText *)textObject
{
#if 1
	NSLog(@" NSTextField %@ %@", NSStringFromSelector(_cmd), textObject);
#endif
	if(![self isEditable])
		return NO;
#if 1
	NSLog(@" NSTextField delegate=%@", _delegate);
#endif
	if([_delegate respondsToSelector:@selector(control:textShouldBeginEditing:)])
		{
#if 1
		NSLog(@" NSTextField delegate responds to control:textShouldBeginEditing:");
#endif
		return [_delegate control:self textShouldBeginEditing:textObject];
		}
	return YES;
}

- (BOOL) textShouldEndEditing:(NSText*)aTextObject
{ // handle validation
#if 1
	NSLog(@" NSTextField %@ %@", NSStringFromSelector(_cmd), aTextObject);
#endif
	if(![_window isKeyWindow])
		return NO;

	if(_cell && [_cell isEntryAcceptable: [aTextObject string]])
		{
		if (_delegate && [_delegate respondsToSelector:@selector(control:textShouldEndEditing:)])
			{
			if(![_delegate control:self textShouldEndEditing:aTextObject])
				{
				NSBeep();
				return NO;
				}
			}
		return YES;
		}

	NSBeep();											// entry is not valid
//	[[_cell target] performSelector:_errorAction withObject:self];
	[aTextObject setString:[_cell stringValue]];	// reset cell to original string

	return NO;
}

- (void) resetCursorRects								// Manage the cursor
{
	if([self isSelectable])
		[self addCursorRect:_bounds cursor:[NSCursor IBeamCursor]];
}

- (void) encodeWithCoder:(NSCoder *)aCoder						// NSCoding protocol
{
	[super encodeWithCoder:aCoder];
	
	[aCoder encodeConditionalObject:_delegate];
//	[aCoder encodeValueOfObjCType:@encode(SEL) at:&_errorAction];
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		{
		// delegate?
		[aDecoder decodeObjectForKey:@"NSTextFieldAlignmentRectInsetsVersion"];
		return self;
		}
	_delegate = [[aDecoder decodeObject] retain];
//	[aDecoder decodeValueOfObjCType:@encode(SEL) at:&_errorAction];
	
	return self;
}

// - (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return [self isEditable]; }	// start inking only if editable

@end /* NSTextField */
