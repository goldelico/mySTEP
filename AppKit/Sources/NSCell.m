/* 
   NSCell.m

   Abstract cell class

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    August 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSString.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSFormatter.h>
#import <Foundation/NSNotification.h>

#import <AppKit/NSApplication.h>
#import <AppKit/NSAttributedString.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSView.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSControl.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSColor.h>
#import <AppKit/NSMenu.h>

#import "NSAppKitPrivate.h"

// Class variables
static NSFont *__defaultFont = nil;
static NSColor *__borderedBackgroundColor = nil;
static NSCursor *__textCursor = nil;

@implementation NSCell

+ (void) initialize
{
	if (self == [NSCell class])
		{
		__defaultFont = [[NSFont userFontOfSize:0] retain];
		__borderedBackgroundColor = [[NSColor controlBackgroundColor] retain];
		__textCursor = [[NSCursor IBeamCursor] retain];
		}
}

+ (BOOL) prefersTrackingUntilMouseUp		{ return NO; }

+ (NSFocusRingType) defaultFocusRingType	{ return NSFocusRingTypeDefault; }

- (id) init									{ return [self initTextCell:@""]; } // default init as text cell

- (id) initImageCell:(NSImage*)anImage
{
	if((self=[super init]))
		{
		_c.enabled = YES;
		[self sendActionOn:NSLeftMouseUpMask];
		ASSIGN(_menu, [isa defaultMenu]);	// set default context menu
		[self setImage:anImage];	// makes us an NSImageCell
		}
	return self;
}

- (id) initTextCell:(NSString*)aString
{
#if 0
	if(sizeof(_c) != 4)
		{
		NSLog(@"warning: sizeof(_c) is %d", sizeof(_c));
		abort();
		}
#endif
	if((self=[super init]))
		{
		_c.enabled = YES;
		_c.alignment = NSCenterTextAlignment;
		_c.floatAutorange = YES;
		[self sendActionOn:NSLeftMouseUpMask];
		ASSIGN(_menu, [isa defaultMenu]);	// set default context menu
		_c.type = NSNullCellType;		// force initialization as NSTextCellType (incl. font & textColor)
		[self setType:NSTextCellType];	// make us a text cell which should assign default font and color
		ASSIGN(_contents, aString);
		}
	return self;
}

- (void) dealloc
{
	[self setObjectValue:nil];
	[self setRepresentedObject:nil];
	[_textColor release];
	[self setFont:nil];
	[self setFormatter:nil];
	[self setTitle:nil];	
	[self setMenu:nil];	
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone
{
	NSCell *c = [isa allocWithZone:zone];	// makes a real copy

	c->_contents = [_contents copyWithZone:zone];
	c->_controlView = _controlView;
	c->_representedObject = [_representedObject retain];
	c->_textColor = [_textColor retain];
	c->_font = [_font retain];
	c->_formatter = [_formatter retain];
	c->_title = [_title retain];
	c->_menu = [_menu retain];
	c->_placeholderString = [_placeholderString retain];	
	c->_c = _c;
	c->_d = _d;
	
	return c;
}

- (NSString *) description;
{
	NSMutableString *a=[NSMutableString stringWithFormat:@"%@: state=%d\n", NSStringFromClass([self class]), _c.state];
	switch(_c.type) { case NSTextCellType:  [a appendString:@"NSTextCellType\n"]; break;
					  case NSImageCellType: [a appendString:@"NSImageCellType\n"]; break;
					  case NSNullCellType:  [a appendString:@"NSNullCellType\n"]; break; }
	if(_c.highlighted) [a appendString:@"highlighted\n"];
	if(_c.enabled) [a appendString:@"enabled\n"];
	if(_c.editable) [a appendString:@"editable\n"];
	if(_c.selectable) [a appendString:@"selectable\n"];
	if(_c.bordered) [a appendString:@"bordered\n"];
	if(_c.bezeled) [a appendString:@"bezeled\n"];
	if(_c.scrollable) [a appendString:@"scrollable\n"];
	if(_c.editing) [a appendString:@"editing\n"];
	if(_c.secure) [a appendString:@"secure\n"];
	if(_c.drawsBackground) [a appendString:@"drawsBackground\n"];
	if(_c.allowsMixed) [a appendString:@"allowsMixed\n"];
	[a appendFormat:@"title=%@\n", _title];
	[a appendFormat:@"font=%@\n", _font];
	[a appendFormat:@"textColor=%@\n", _textColor];
	[a appendFormat:@"controlView=%@\n", _controlView];
	[a appendFormat:@"formatter=%@\n", _formatter];
	[a appendFormat:@"representedObject=%@\n", _representedObject];
	[a appendFormat:@"objectValue=%@", _contents];
	return a;
}

- (void) calcDrawInfo:(NSRect)aRect			{ SUBCLASS }		// implemented by subclass

- (NSSize) cellSize
{
	NSSize m;
	if(_c.type == NSTextCellType && _font)
		{
		if([_contents isKindOfClass:[NSAttributedString class]])
			m=[_contents size];
		else
			m = [_contents sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:_font, NSFontAttributeName, nil]];
		}
	else if (_c.type == NSImageCellType && _contents != nil)
		m = [_contents size];
	else
		m = NSZeroSize;

	if(_c.bordered)
		return (NSSize){m.width+10, m.height+10};
	if(_c.bezeled)
		return (NSSize){m.width+12, m.height+12};
	return (NSSize){m.width+8, m.height+8};					// neither
}

- (NSSize) cellSizeForBounds:(NSRect)aRect			// cell component sizes
{
	// trim to width of content
	return aRect.size;
}

- (NSRect) drawingRectForBounds:(NSRect)rect		// return rect within which
{													// cell draws itself (Inset
	if(_c.bordered)									// on all sides to account
		return NSInsetRect(rect, 1, 1);				// for cell's border type)
	if(_c.bezeled)
		return NSInsetRect(rect, 2, 2);
	return rect;
}

- (NSRect) imageRectForBounds:(NSRect)theRect
{
	return NSZeroRect;
}

- (NSRect) titleRectForBounds:(NSRect)theRect
{
	return NSZeroRect;
}

- (void) setImage:(NSImage *)anImage
{
	if(anImage)
		[self setType:NSImageCellType];
	ASSIGN(_contents, anImage); 
}

- (NSImage*) image							{ return _c.type==NSImageCellType?_contents:nil; }
- (NSCellType) type							{ return (_c.type==NSImageCellType&&_contents==nil)?NSNullCellType:_c.type; }

- (void) setType:(NSCellType)aType
{
	if(_c.type == aType)
		return; // we already have that type
	_c.type=aType;  // prevent recursion
#if 0
	NSLog(@"%@ setType %d", self, aType);
#endif
	switch(aType)
		{
		case NSImageCellType:
		case NSNullCellType:
			[self setImage:nil];
			break;
		case NSTextCellType:
			[self setTitle:@"Button"];
			if(!_textColor)
				_textColor = [[NSColor controlTextColor] retain];	// default
			if(!_font)
				_font = [__defaultFont retain];
#if 0
			NSLog(@"textColor=%@ font=%@", _textColor, _font);
#endif
			break;
	// default: raise exception?
		}
}

- (void) setState:(int)value				{ _c.state = (value>0?NSOnState:((value<0 && _c.allowsMixed)?NSMixedState:NSOffState)); }
- (void) setNextState;						{ [self setState:[self nextState]]; }
- (int) state								{ return _c.state; }
- (int) nextState
{
	if(_c.state < 0)	return NSOffState;
	if(_c.state == 0)	return NSOnState;
	return _c.allowsMixed?NSMixedState:NSOffState;
}
- (void) setAllowsMixedState:(BOOL)flag		{ _c.allowsMixed = flag; [self setState:_c.state]; }
- (BOOL) allowsMixedState;					{ return _c.allowsMixed; }
- (void) setEnabled:(BOOL)flag				{ _c.enabled = flag; }
- (BOOL) isEnabled							{ return _c.enabled; }
- (BOOL) acceptsFirstResponder				{ return _c.enabled && !_c.refusesFirstResponder; }														
- (BOOL) hasValidObjectValue				{ return YES; }
- (void) setFormatter:(NSFormatter*)fm		{ ASSIGN(_formatter, fm); }
- (id) formatter							{ return _formatter; }
- (id) representedObject					{ return _representedObject; }
- (void) setRepresentedObject:(id)o			{ ASSIGN(_representedObject, o); }
- (NSString *) title						{ return _title; }
- (void) setTitle:(NSString *)title			{ ASSIGN(_title, title); }
+ (NSMenu *) defaultMenu;					{ return nil; }
- (NSMenu *) menu							{ return _menu; }
- (void) setMenu:(NSMenu *)menu				{ ASSIGN(_menu, menu); }
- (void) setTitleWithMnemonic:(NSString *)aString; { [self setTitle:aString]; }
- (id) objectValue							{ return _contents; }

- (NSMenu *) menuForEvent:(NSEvent *) event inRect:(NSRect) rect ofView:(NSView *) view
{
	NSMenu *m=[self menu];	// if we have an individual menu
	if(!m)
		m=[view menuForEvent:event];
	return m;
}

- (NSString *) stringValue;
{ // try to format as NSString
	NSString *string;				// string
	NSDictionary *attribs;
	NSAttributedString *astring;	// or attributed string to draw
	[self _getFormattedString:&string withAttribs:&attribs orAttributedString:&astring ignorePlaceholder:YES];
	if(astring)
		return [astring string];
	return string;
}

- (NSAttributedString *) attributedStringValue
{ // try to format as NSAttributedString
	NSString *string;				// string
	NSDictionary *attribs;
	NSAttributedString *astring;	// or attributed string to draw
	[self _getFormattedString:&string withAttribs:&attribs orAttributedString:&astring ignorePlaceholder:YES];
	if(astring)
		return astring;	// directly returns an attributed string
	return [[[NSAttributedString alloc] initWithString:string attributes:attribs] autorelease];
}

- (double) doubleValue						{ return [_contents doubleValue]; }
- (float) floatValue;						{ return [_contents floatValue]; }
- (int) intValue							{ return [_contents intValue]; }

- (void) setObjectValue:(id <NSCopying>)anObject
{
#if 0
	NSLog(@"%@ setObjectValue:%@ (_contents=%@)", self, anObject, _contents);
#endif
	if(anObject == _contents)
		return;	// needn't do anything
	if(_c.editing)
		[_controlView abortEditing];
	if(anObject && _c.type != NSTextCellType)
		[self setType:NSTextCellType];	// make us a text cell
	[_contents autorelease];
	_contents=[anObject copyWithZone:NULL];	// save a copy
#if 0
	NSLog(@"%@ setObjectValue done:", self);
#endif
}

- (void) setDoubleValue:(double)aDouble
{
	[self setObjectValue:[NSNumber numberWithDouble:aDouble]];
}

- (void) setFloatValue:(float)aFloat
{
	[self setObjectValue:[NSNumber numberWithFloat:aFloat]];
}

- (void) setIntValue:(int)anInt
{
	[self setObjectValue:[NSNumber numberWithInt:anInt]];
}

- (void) setStringValue:(NSString*)aString
{
	if([_contents isKindOfClass:[NSString class]] && [_contents isEqualToString:aString])
		return;	// no change
	[self setObjectValue:aString];
}

- (void) setAttributedStringValue:(NSAttributedString*)aString
{
	[self setObjectValue:aString];
}

- (void) takeDoubleValueFrom:(id)sender						// Cell Interaction
{
	[self setObjectValue:[NSNumber numberWithDouble:[sender doubleValue]]];
}

- (void) takeFloatValueFrom:(id)sender
{
	[self setObjectValue:[NSNumber numberWithFloat:[sender floatValue]]];
}

- (void) takeIntValueFrom:(id)sender
{
	[self setObjectValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (void) takeStringValueFrom:(id)sender
{
	[self setObjectValue:[sender stringValue]];
}

- (void) takeObjectValueFrom:(id)sender
{
	[self setObjectValue:[sender objectValue]];
}
														// Text Attributes 
- (void) setFloatingPointFormat:(BOOL)autoRange
						   left:(unsigned int)leftDigits
						   right:(unsigned int)rightDigits
{
	_c.floatAutorange = autoRange;					// FIX ME create formatter 
}													// if needed and set format

- (NSTextAlignment) alignment					{ return _c.alignment; }
- (void) setAlignment:(NSTextAlignment)mode		{ _c.alignment = mode; }
- (void) setScrollable:(BOOL)flag				{ _c.scrollable = flag; }
- (void) setWraps:(BOOL)flag					{ NIMP }
- (BOOL) isScrollable							{ return _c.scrollable; }
- (BOOL) wraps									{ return NO; }
- (NSFont*) font								{ return _font; }

- (void) setFont:(NSFont*)fontObject
{
	ASSIGN(_font, ((fontObject) ? fontObject : __defaultFont));
}

- (BOOL) isEditable						{ return _c.editable && !_c.editing; }
- (BOOL) isSelectable					{ return _c.selectable && !_c.editing;}

- (void) setEditable:(BOOL)flag
{
	if ((_c.editable = flag))							// If cell is editable
		_c.selectable = flag;							// it is selectable 
}														

- (void) setSelectable:(BOOL)flag
{
	if (!(_c.selectable = flag))						// If cell is not 
		_c.editable = NO;								// selectable then it's 
}														// not editable

- (NSText*) setUpFieldEditorAttributes:(NSText*)textObject
{ // make the field editor imitate the cell as good as possible - note: the field editor is shared for all cells in a window
	if(_c.enabled && _textColor)
		[textObject setTextColor:_textColor];
	else
		[textObject setTextColor:[NSColor disabledControlTextColor]];
	[textObject setEditable:_c.editable];	// editable always sets selectable
	if(!_c.editable)
		[textObject setSelectable:_c.selectable];	// pass on selectable flag
	[textObject setFont:_font];
	[textObject setAlignment:_c.alignment];
	// FIXME: we should check for attributed string value and set rich text...
	[textObject setRichText:NO];
	[textObject setString:[self stringValue]];
#if 0
	NSLog(@"textObject setString:%@", [self stringValue]);
#endif
	[textObject setFocusRingType:NSFocusRingTypeExterior];

	if(_c.drawsBackground)
		{
		[textObject setBackgroundColor:[(id)self backgroundColor]];
		[textObject setDrawsBackground:YES];
		}
	else if(_c.bezeled)
		{
		[textObject setBackgroundColor:[NSColor controlBackgroundColor]];
		[textObject setDrawsBackground:YES];
		}
	else if(_c.bordered && __borderedBackgroundColor)
		{
		[textObject setBackgroundColor:__borderedBackgroundColor];
		[textObject setDrawsBackground:YES];
		}
	else
		[textObject setDrawsBackground:NO];
	return textObject;
}

- (void) editWithFrame:(NSRect)aRect 					// edit the cell's text
				inView:(NSView*)controlView				// using the fieldEditor
				editor:(NSText*)textObject				// s/b called only from 
				delegate:(id)anObject					// a mouseDown
				event:(NSEvent*)event
{
	if(_c.type != NSTextCellType || _c.editing)
		return;

	[self selectWithFrame:aRect				
		  inView:controlView	 		
		  editor:textObject	 		
		  delegate:anObject
		  start:(int)0	 
		  length:(int)0];

	[textObject mouseDown:event];
}
											// editing is complete, remove the
- (void) endEditing:(NSText*)textObject		// text obj	acting as field	editor	
{											// from window's view heirarchy
	NSView *v;
	NSRect r;

	NSLog(@"endEditing %@", self);

	[textObject retain];	// we still need it later - but doesn't this leak???
	if(_c.scrollable)
		{
		NSClipView *c = (NSClipView *) [textObject superview];

		v = [c superview];
		r = [c frame];
		[c retain];	
		[c removeFromSuperview];	
		}
	else
		{
		v = [textObject superview];
		r = [textObject frame];
		[textObject removeFromSuperview];	
		}				
	[textObject setDelegate:nil];	// no longer create notifications
	
// FIXME: shouldn't we copy the text value back to the cell here?
	
//	[textObject release];	// can we release here?
	_c.editing = NO;
	[v displayRect:r];
}

- (void) selectWithFrame:(NSRect)aRect					// similar to editWith-
				  inView:(NSView*)controlView	 		// Frame method but can
				  editor:(NSText*)textObject	 		// be called from more
				  delegate:(id)anObject	 				// than just mouseDown
				  start:(int)selStart	 
				  length:(int)selLength
{
	if(controlView && textObject && _font && _c.type == NSTextCellType)
		{
		NSWindow *w;
		NSClipView *controlSuperView;
#if 1
		NSLog(@"NSCell -selectWithFrame: %@", self);
		NSLog(@"	current window=%@", [textObject window]);
		NSLog(@"	current firstResponder=%@", [[textObject window] firstResponder]);
#endif
		// make sure previous field edit is not in use
		if((w = [textObject window]))
			[w makeFirstResponder:w];
#if 0
		NSLog(@"	new firstResponder=%@", [[textObject window] firstResponder]);
#endif		
		controlSuperView = (NSClipView *)[textObject superview];
		if(controlSuperView && (![controlSuperView isKindOfClass:[NSClipView class]]))
			controlSuperView = nil;	// text object is not embedded in a clip view
		if(controlSuperView)
			{
#if 1
			NSLog(@"	%@ setNeedsDisplayInRect:%@", controlSuperView, NSStringFromRect([textObject frame]));
#endif
			[controlSuperView setNeedsDisplayInRect:[textObject frame]];	// make previous superview redisplay cell
			}
		// now set up new field editor
		_controlView = controlView;
		if(_c.scrollable)
			[textObject setFrame:(NSRect){{0,1},aRect.size}];
		else
			{
			if(controlSuperView)
				[controlSuperView setDocumentView:nil];
			[textObject setFrame:NSOffsetRect(aRect, 1.0, -1.0)];	// adjust so that it really overlaps
			}
	
		[textObject setDelegate:anObject];
		[self setUpFieldEditorAttributes:textObject];
		[textObject setSelectedRange:(NSRange){selStart, selLength}];
	
		if(_c.scrollable)
			{ // if we are scrollable, put us in a clipview
			if(!controlSuperView)
				{
				controlSuperView = [[[NSClipView alloc] initWithFrame:aRect] autorelease];
				[controlSuperView setDocumentView:textObject];
				}
			else
				{
				[controlSuperView setBoundsOrigin:NSZeroPoint];
				[controlSuperView setFrame:aRect];
				}
			[controlView addSubview:controlSuperView];
			[textObject sizeToFit];
			}
		else
			[controlView addSubview:textObject];
		[[controlView window] makeFirstResponder:textObject];	// make the field editor the first responder
		_c.editing = YES;	// now consider the cell as editing
		[controlView setNeedsDisplayInRect:aRect];	// and redisplay new NSText (over the cell)
		}
	else
		NSLog(@"invalid selectWithFrame:... for %@", self);
#if 1
	NSLog(@"NSCell -selectWithFrame: done");
#endif
}

- (int) entryType								{ return _c.entryType; }
- (void) setEntryType:(int)aType				{ _c.entryType = MAX(aType,7);}
- (BOOL) isEntryAcceptable:(NSString *)aString 	{ return YES; }
- (BOOL) isBezeled								{ return _c.bezeled; }
- (BOOL) isBordered								{ return _c.bordered; }
- (BOOL) isOpaque								{ return _c.bezeled; }  // default implementation
// mutually exclusive
- (void) setBezeled:(BOOL)flag					{ _c.bezeled = flag; _c.bordered=NO; }
- (void) setBordered:(BOOL)flag					{ _c.bordered = flag; _c.bezeled=NO; }

- (int) cellAttribute:(NSCellAttribute)aParameter
{
	switch (aParameter)									// FIX ME unfinished
		{
		case NSCellDisabled:	return (int)_c.enabled;
		case NSCellIsBordered:	return (int)_c.bordered;
		case NSCellHighlighted:	return (int)_c.highlighted;
		case NSCellState:		return (int)_c.state;
		case NSCellEditable:	return (int)_c.editable;
		default:				return -1;
		}
}

- (void) setCellAttribute:(NSCellAttribute)aParameter to:(int)value
{
	switch (aParameter)
		{
		case NSCellDisabled:	_c.enabled = (BOOL)value;		break;
		case NSCellIsBordered:	_c.bordered = (BOOL)value; _c.bezeled=NO;		break;
		case NSCellHighlighted:	_c.highlighted = (BOOL)value;	break;
		case NSCellState:		_c.state = (BOOL)value;			break;
		case NSCellEditable:	_c.editable = _c.selectable = (BOOL)value;
		default:
			break;
		}
}

- (void) highlight:(BOOL)lit							// Drawing the cell
		 withFrame:(NSRect)cellFrame						
		 inView:(NSView *)controlView					
{
	_c.highlighted = lit;
	[self drawWithFrame:cellFrame inView:controlView];
}										

- (void) drawWithFrame:(NSRect)cellFrame
				inView:(NSView*)controlView
{
	NSDebugLog (@"NSCell drawWithFrame:inView:");
	_controlView = controlView;							// last view drawn in

	if(_c.bezeled) 
		{
#if 0
		NSLog(@"bezeled");
#endif
		NSDrawWhiteBezel(cellFrame, cellFrame);
		}
	else if(_c.bordered)
		{
#if 0
		NSLog(@"bordered");
#endif
		if(_c.drawsBackground)
			{
			[__borderedBackgroundColor set];
			NSRectFill(cellFrame);
			}
		[[NSColor blackColor] set];
		NSFrameRect(cellFrame);
		}
	if(_c.editing)
		return;
	[self drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void) _getFormattedString:(NSString **) string withAttribs:(NSDictionary **) attribs orAttributedString:(NSAttributedString **) astring ignorePlaceholder:(BOOL) flag;	// whichever is more convenient
{ // get whatever you have
#if 0
	NSLog(@"_getFormattedString...");
#endif
	*attribs=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		((_c.enabled && _textColor) ? _textColor : [NSColor disabledControlTextColor]),	NSForegroundColorAttributeName,
		_font, NSFontAttributeName,
		nil];
	*string=nil;
	*astring=nil;
#if 0
	NSLog(@"attribs=%@", *attribs);
	NSLog(@"string=%@", *string);
	NSLog(@"astring=%@", *astring);
	NSLog(@"_formatter=%@", _formatter);
	NSLog(@"_contents=%@", _contents);
	NSLog(@"_contents class=%@", [_contents class]);
#endif	
	if(_formatter)
		{
		if([_formatter respondsToSelector:@selector(attributedStringForObjectValue:withDefaultAttributes:)])
			*astring=[_formatter attributedStringForObjectValue:_contents withDefaultAttributes:*attribs];
		if(*astring == nil)
			*string=[_formatter stringForObjectValue:_contents];
		}
	else if([_contents isKindOfClass:[NSAttributedString class]])
		*astring=_contents;   // as is
	else
		*string=[_contents description];
#if 0
	NSLog(@"attribs=%@", *attribs);
	NSLog(@"string=%@", *string);
	NSLog(@"astring=%@", *astring);
#endif	
	if(_c.secure)   // set by NSSecureTextField
		{
		if(*astring)
			{
			*string=[@"" stringByPaddingToLength:[*astring length] withString:@"*" startingAtIndex:0]; // replace with sequence of *
			*astring=nil;
			}
		else
			*string=[@"" stringByPaddingToLength:[*string length] withString:@"*" startingAtIndex:0]; // replace with sequence of *
		}
#if 0
	NSLog(@"attribs=%@", *attribs);
	NSLog(@"string=%@", *string);
	NSLog(@"astring=%@", *astring);
#endif	
	if(!flag && _placeholderString && [*astring length] == 0 && [*string length] == 0)
		{ // substitute placeholder
		if([_placeholderString isKindOfClass:[NSAttributedString class]])
			{ // we have an attributed placeholder
			*astring=_placeholderString;
			*string=nil;
			}
		else
			{
			*string=_placeholderString;
			*astring=nil;
			[(NSMutableDictionary *)(*attribs) setObject:[NSColor lightGrayColor] forKey:NSForegroundColorAttributeName];
			}
		}
#if 0
	NSLog(@"string=%@ attribs=%@ astring=%@", *string, *attribs, *astring);
#endif
}

- (void) drawInteriorWithFrame:(NSRect)frame inView:(NSView*)controlView
{
#if 0
	NSLog(@"%@ drawInteriorWithFrame:%@ inView:%@", self, NSStringFromRect(frame), controlView);
#endif
	if(!_contents)
		return;
	if(_c.bezeled) 
		frame=NSInsetRect(frame, 2, 2);	// fit within bezel
	else if(_c.bezeled) 
		frame=NSInsetRect(frame, 1, 1);	// fit within border
	if(_c.type == NSTextCellType)
		{
		NSString *string;				// string
		NSMutableDictionary *_attribs;
		NSAttributedString *astring;	// or attributed string to draw
		NSSize size;
		[self _getFormattedString:&string withAttribs:&_attribs orAttributedString:&astring ignorePlaceholder:NO];
#if 0
		NSLog(@"NSCell drawInterior string=%@ astring=%@ attribs=%@ _textColor=%@", string, astring, _attribs, _textColor);
#endif	
		if(astring)
			size=[astring size]; // determine bounding box of text
		else
			size=[string sizeWithAttributes:_attribs];
		frame.origin.x += 2;	// add left&right spacing
		frame.size.width -= 4;
		switch(_c.alignment) 					// Determine x position of text
			{
			case NSJustifiedTextAlignment:
				// set required kerning/spacing
			case NSLeftTextAlignment:
			case NSNaturalTextAlignment:
				break;
			case NSRightTextAlignment:
				frame.origin.x += NSWidth(frame) - size.width;
				break;
			case NSCenterTextAlignment:
				frame.origin.x += (NSWidth(frame) - size.width) / 2;
				break;
			}
		if(_d.verticallyCentered)
			{
			if([controlView isFlipped])
				frame.origin.y += (NSHeight(frame) - size.height) / 2;
			else
				frame.origin.y -= (NSHeight(frame) - size.height) / 2;
			}
#if 0
		NSLog(@"inFrame %@", NSStringFromRect(frame));
#endif
		if(astring)
			[astring drawInRect:frame];
		else
			[string drawInRect:frame withAttributes:_attribs];
		return;
		}
	
	if(_c.type == NSImageCellType)
		{ // render image cell
		NSSize size = [(NSImage *)_contents size];
		NSCompositingOperation op = (_c.highlighted) ? NSCompositeHighlight 
													 : NSCompositeSourceOver;
		// always center
		frame.origin.x += (NSWidth(frame) - size.width) / 2;
		frame.origin.y += (NSHeight(frame) - size.height) / 2;
		[_contents compositeToPoint:frame.origin operation:op];	  
		}
}

- (NSView *) controlView						{ return _controlView; }
- (void) setControlView:(NSView *) view;		{ _controlView=view; }
- (BOOL) isHighlighted							{ return _c.highlighted; }
- (void) setHighlighted:(BOOL)flag				{ _c.highlighted = flag; /* force redraw??? */ }
- (BOOL) isContinuous							{ return _c.continuous; }
- (void) setContinuous:(BOOL)flag				{ _c.continuous = flag; }
- (void) setTag:(int)anInt						{ SUBCLASS; }
- (int) tag										{ return -1; }
- (void) setTarget:(id)anObject					{ SUBCLASS; }
- (id) target									{ return nil; }
- (SEL) action									{ return NULL; }
- (void) setAction:(SEL) selector;				{ SUBCLASS; }
- (NSControlSize) controlSize					{ return _d.controlSize; }
- (void) setControlSize:(NSControlSize)sz		{ _d.controlSize = sz; }
- (NSControlTint) controlTint					{ return _d.controlTint; }
- (void) setControlTint:(NSControlTint)ti		{ _d.controlTint = ti; }
- (NSFocusRingType) focusRingType;				{ return _d.focusRingType; }
- (void) setFocusRingType:(NSFocusRingType) type; { _d.focusRingType = type; }

- (int) sendActionOn:(int)mask
{
	unsigned int previousMask = 0;

	previousMask |= _c.continuous ? NSPeriodicMask : 0;
	previousMask |= _c.actOnMouseDown ? NSLeftMouseDownMask : 0;
	previousMask |= _c.actOnMouseUp ? NSLeftMouseUpMask : 0;
	previousMask |= _c.actOnMouseDragged ? NSLeftMouseDraggedMask : 0;

	_c.continuous = (mask & NSPeriodicMask) != 0;
	_c.actOnMouseDown = (mask & NSLeftMouseDownMask) != 0;
	_c.actOnMouseDragged = (mask & NSLeftMouseDraggedMask) != 0;
	_c.actOnMouseUp = (mask & NSLeftMouseUpMask) != 0;

	return previousMask;
}

- (void) performClick:(id)sender
{
	id target;
	SEL action;
	NSView *v=_controlView?_controlView:sender;
	NSRect b=[v bounds];	// we should have a better algorithm - i.e. ask the control for our exact rect
	NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:0.3];
	[self setHighlighted:YES];
	[v setNeedsDisplayInRect:b];
#if 0
	NSLog(@"%@ performClick for view %@", self, v);
#endif
	if((action = [self action]))
		{
		NS_DURING
			target = [self target];	// might go to first responder (target=nil)
#if 0
			NSLog(@"action=%@", NSStringFromSelector(action));
			NSLog(@"target=%@", target);
#endif
			[(NSControl *) v sendAction:action to:target];
		NS_HANDLER
			{
#if 0
				NSLog(@"%@ performClick exception %@", self, localException);
#endif
				[NSApp nextEventMatchingMask:0						// never match events
								   untilDate:limit					// just delay
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:NO];
				[self setHighlighted:NO];
				[v setNeedsDisplayInRect:b];
				[localException raise];	// re-raise on next level
			}
		NS_ENDHANDLER
		}
#if 0
	NSLog(@"performClick: wait for event(s)");
#endif
	[NSApp nextEventMatchingMask:0						// never match events
					   untilDate:limit					// just delay
						  inMode:NSEventTrackingRunLoopMode 
						 dequeue:NO];
#if 0
	NSLog(@"performClick: done");
#endif
	[self setHighlighted:NO];
	[v setNeedsDisplayInRect:b];
#if 0
	NSLog(@"v=%@", v);
#endif
}

- (unsigned int) keyEquivalentModifierMask;
{
	return 0; // default implementation - should not match any key
}

- (NSString*) keyEquivalent								// Keyboard Alternative				
{
	return @""; // default implementation - should not match any key
}

- (int) mouseDownFlags
{
	return 0;
}

- (void) getPeriodicDelay:(float*)delay interval:(float*)interval
{
	*delay = 0.2;
	*interval = 0.2;
}

- (BOOL) startTrackingAt:(NSPoint)startPoint
				  inView:(NSView*)control
{ // If point is in view start tracking
	return _c.continuous || _c.actOnMouseDragged;
}

- (BOOL) continueTracking:(NSPoint)lastPoint			// Tracking the Mouse
					   at:(NSPoint)currentPoint
				   inView:(NSView *)controlView
{
	return _c.continuous || _c.actOnMouseDragged;
}

- (void) stopTracking:(NSPoint)lastPoint				// Implemented by subs
				   at:(NSPoint)stopPoint
			   inView:(NSView *)controlView
			mouseIsUp:(BOOL)flag				
{
	return;	// nothing to do
}

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)untilMouseUp
{
	NSPoint point=[controlView convertPoint:[event locationInWindow] fromView:nil];
	NSPoint first_point=point;
	NSPoint last_point=point;
	id target = [self target];
	SEL action = [self action];
	// FIXME: shouldn't we use [controlView menuForEvent:event]; and have that overriden in NSControl/NSMatrix (but not NSTableView!)
	NSMenu *contextMenu=[self menuForEvent:event inRect:cellFrame ofView:controlView];	// if we have a context menu, pop it up after approx. 0.5 seconds without movement
	NSDate *expiration;
	// FIXME: mask should probably depend on which mouse went down in event!
	unsigned int mask = NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSLeftMouseDownMask | NSMouseMovedMask | NSLeftMouseUpMask;
	NSEvent *mousedown=event;
	BOOL mouseWentUp = NO;
	BOOL tracking;
	if(_c.continuous)	// (sub)cell class wants periodic tracking
		{ // enable periodic events
		float delay, interval;
		[self getPeriodicDelay:&delay interval:&interval];
		[NSEvent startPeriodicEventsAfterDelay:delay withPeriod:interval];
		mask |= NSPeriodicMask;
		}
	tracking=[self startTrackingAt:point inView:controlView];
	if(_c.actOnMouseDown && action)
		[(NSControl*)controlView sendAction:action to:target];	// do this after starttracking (which may update the cell)
	if(contextMenu)	// setup a timeout that tracks that the cursor is not moved and pops up the context menu
		{
#if 0
		NSLog(@"NSCell handle context menu");
#endif
		expiration=[NSDate dateWithTimeIntervalSinceNow:0.8];
		}
	else
		expiration=[NSDate distantFuture];
	
	while(YES)
		{ // Get next mouse event until a mouse up is obtained
#if 1
		NSLog(@"expiration=%@", expiration);
#endif
		event = [NSApp nextEventMatchingMask:mask 
								   untilDate:expiration
									  inMode:NSEventTrackingRunLoopMode 
									 dequeue:YES];
#if 1
		NSLog(@"event=%@", event);
#endif
		if(!event)
			{ // no matching event, i.e. timed out
#if 1
			NSLog(@"pop up context menu: %@", contextMenu);
#endif
			if((mask & NSPeriodicMask) != 0)
				[NSEvent stopPeriodicEvents];	// was still tracking
			
			// we could start some animation (rotating circle like Maemo) while checking for the final popup...
			// FIXME: define correct popup position
			// FIXME: a popup menu should have some shadow or a border so that it can be distinguished from the background
			
			[self stopTracking:last_point
							at:point
						inView:controlView
					 mouseIsUp:NO];
			[NSMenu popUpContextMenu:contextMenu withEvent:mousedown forView:controlView];	// show the popup menu
			return YES;	// exit tracking loop(s)
			}
#if 1
		NSLog(@"NSCell trackMouse: event=%@", event);
#endif
		switch([event type])
			{
			case NSPeriodic:
				{ // send periodic action while tracking (e.g. for a slider)
					if(action)
						[(NSControl*)controlView sendAction:action to:target];
					continue;
				}
			case NSLeftMouseUp:					// Did mouse go up?
				{
					mouseWentUp = YES;
					break;	// break loop
				}
			case NSLeftMouseDragged:
				{ // pointer has moved
					last_point=point;
					point = [controlView convertPoint:[event locationInWindow] fromView:nil];
					if(fabs(point.x-first_point.x)+fabs(point.y-first_point.y) > 5.0)
					   expiration=[NSDate distantFuture];	// if pointer has been moved too far, disable context menu detection
#if 1
					NSLog(@"NSCell trackMouse: pointIsInCell=%@", [controlView mouse:point inRect:cellFrame]?@"YES":@"NO");
#endif
					if(!untilMouseUp && ![controlView mouse:point inRect:cellFrame]) // we did leave the cell
						break;	// break loop when leaving the frame box
					if(_c.actOnMouseDragged)
						{ // send action while tracking (e.g. for a slider)
						if(action)
							[(NSControl*)controlView sendAction:action to:target];
						}
					if(tracking && ![self continueTracking:last_point at:point inView:controlView])
						tracking=NO;	// cell no longer wants to receive any more tracking calls
					continue;
				}
				// scroll wheel?
			default:
				continue;	// ignore all others and continue loop
			}
		break;	// break in switch also breaks the while loop
		}
	if((mask & NSPeriodicMask) != 0)
		[NSEvent stopPeriodicEvents];					// was still tracking
	[self stopTracking:last_point 						// Stop tracking mouse
					at:point
				inView:controlView
			 mouseIsUp:mouseWentUp];
	if(_c.actOnMouseUp && action && mouseWentUp)
		[(NSControl*)controlView sendAction:action to:target];
	return mouseWentUp;
}													

- (void) resetCursorRect:(NSRect)cellFrame				// Managing the Cursor
				  inView:(NSView *)controlView
{
	if(_c.type == NSTextCellType && _c.selectable&& !_c.editing)
		[controlView addCursorRect:cellFrame cursor:__textCursor];
}

- (void) setShowsFirstResponder:(BOOL)flag;	{ _c.showsFirstResponder = flag; }
- (BOOL) showsFirstResponder;				{ return _c.showsFirstResponder; }
- (void) setRefusesFirstResponder:(BOOL)flag; { _c.refusesFirstResponder = flag; }
- (BOOL) refusesFirstResponder;				{ return _c.refusesFirstResponder; }

- (NSComparisonResult) compare:(id)otherCell			// Compare NSCell's
{
	return (self == otherCell) ? 1 : 0;
}

- (NSArray *) accessibilityAttributeNames { return [NSArray array]; }

- (void) encodeWithCoder:(NSCoder *) aCoder						// NSCoding protocol
{
	[aCoder encodeObject:_contents];
	[aCoder encodeObject:_font];
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at:&_c];   // warning!! works with real bitfields only!!
	[aCoder encodeValueOfObjCType:@encode(unsigned int) at:&_d];
	[aCoder encodeConditionalObject:_controlView];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
#if 0
	NSLog(@"NSCell initWithCoder");
#endif
	self=[self init];
	if([aDecoder allowsKeyedCoding])
		{
		long cellflags=[aDecoder decodeInt32ForKey:@"NSCellFlags"];
		long cellflags2=[aDecoder decodeInt32ForKey:@"NSCellFlags2"];

#define STATE ((cellflags&0x80000000)!=0)
		_c.state=STATE;
#define HIGHLIGHTED ((cellflags&0x40000000)!=0)
		_c.highlighted=HIGHLIGHTED;
#define ENABLED ((cellflags&0x20000000)==0)		// or NSEnabled???
		_c.enabled=ENABLED;
#define EDITABLE ((cellflags&0x10000000)!=0)
		_c.editable=EDITABLE;
#define CELLTYPE ((cellflags&0x0c000000)>>26)
		_c.type=CELLTYPE;
#define BORDERED ((cellflags&0x00800000)!=0)
		_c.bordered=BORDERED;
#define BEZELED ((cellflags&0x00400000)!=0)
		_c.bezeled=BEZELED;
#define SELECTABLE ((cellflags&0x00200000)!=0)
		_c.selectable=SELECTABLE;
#define SCROLLABLE ((cellflags&0x00100000)!=0)
		_c.scrollable=SCROLLABLE;
#define CONTINUOUS ((cellflags&0x00080000)!=0)
		_c.continuous=CONTINUOUS;
#define ACTDOWN ((cellflags&0x00040000)!=0)
		_c.actOnMouseDown=ACTDOWN;
#define LEAF ((cellflags&0x00020000)!=0)
		_d.isLeaf=LEAF;
#define LINEBREAKMODE ((cellflags&0x00007000)>>12)
		_d.lineBreakMode=LINEBREAKMODE;
#define ACTDRAG ((cellflags&0x00000100)!=0)
		_c.actOnMouseDragged=ACTDRAG;
#define LOADED ((cellflags&0x00000080)!=0)
		_d.isLoaded=LOADED;
#define ACTUP ((cellflags&0x00000020)==0)
		_c.actOnMouseUp=ACTUP;
#define SHOWSFIRSTRESPONDER ((cellflags&0x00000004)!=0)
		_c.showsFirstResponder=SHOWSFIRSTRESPONDER;
#define FOCUSRINGTYPE ((cellflags&0x00000003)>>0)
		_d.focusRingType=FOCUSRINGTYPE;
		
#define ALLOWSEDITINGTEXTATTRIBS ((cellflags2&0x20000000)!=0)
		_d.allowsEditingTextAttributes=ALLOWSEDITINGTEXTATTRIBS;
#define IMPORTSGRAPHICS ((cellflags2&0x10000000)!=0)	// does not match bitfield definitions but works
		_d.importsGraphics=IMPORTSGRAPHICS;
#define ALIGNMENT ((cellflags2&0x1c000000)>>26)
		_c.alignment=ALIGNMENT;
#define REFUSESFIRSTRESPONDER ((cellflags2&0x00010000)!=0)
		_c.refusesFirstResponder=REFUSESFIRSTRESPONDER;
#define ALLOWSUNDO ((cellflags2&0x00004000)==0)
		_d.allowsUndo=ALLOWSUNDO;
#define ALLOWSMIXEDSTATE ((cellflags2&0x00001000)!=0)
		_c.allowsMixed=ALLOWSMIXEDSTATE;
#define MIXEDSTATE ((cellflags2&0x00000800)!=0)
		if(_c.allowsMixed && MIXEDSTATE) _c.state=NSMixedState;	// overwrite state
#define SENDSACTIONONEDITING ((cellflags2&0x00000400)!=0)
		_d.sendsActionOnEndEditing=SENDSACTIONONEDITING;
#define CONTROLTINT ((cellflags2&0x000000e0)>>5)
		_d.controlTint=CONTROLTINT;
#if HOWITSHOULDBE
#define CONTROLSIZE ((cellflags2&0x00000018)>>3)
		_d.controlSize=CONTROLSIZE;
#endif
#ifndef HOWITWORKS
#define CONTROLSIZE ((cellflags2&0x000e0000)>>17)
		_d.controlSize=CONTROLSIZE;
#endif
		_c.drawsBackground = [aDecoder decodeBoolForKey:@"NSDrawsBackground"];
		
		// _c.imagePosition=?	// defined for/by ButtonCell
		// _c.entryType=?;
				
		_placeholderString=[[aDecoder decodeObjectForKey:@"NSPlaceholderString"] retain];
		_title=[[aDecoder decodeObjectForKey:@"NSTitle"] retain];		// title string
		_font=[[aDecoder decodeObjectForKey:@"NSSupport"] retain];		// font
		_menu=[[aDecoder decodeObjectForKey:@"NSMenu"] retain];
		_textColor=[[aDecoder decodeObjectForKey:@"NSTextColor"] retain];
		_formatter=[[aDecoder decodeObjectForKey:@"NSFormatter"] retain];
		if([aDecoder containsValueForKey:@"NSState"])
			_c.state = [aDecoder decodeIntForKey:@"NSState"];	// overwrite state
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder);
		NSLog(@"  NSCellFlags=%08x", [aDecoder decodeIntForKey:@"NSCellFlags"]);
		NSLog(@"  NSCellFlags2=%08x", [aDecoder decodeIntForKey:@"NSCellFlags2"]);
		NSLog(@"  textColor=%@", _textColor);
		NSLog(@"  drawsbackground=%d", _c.drawsBackground);
		NSLog(@"  alignment=%d", _c.alignment);
		NSLog(@"  state=%d", _c.state);
#endif
		[aDecoder decodeObjectForKey:@"NSAccessibilityOverriddenAttributes"];	// just reference - should save and merge with superclass
		/*_controlView=*/[aDecoder decodeObjectForKey:@"NSControlView"];		// might be a class-swapped object! - don't initialize until we draw for the first time
		_contents=[[aDecoder decodeObjectForKey:@"NSContents"] retain];	// contents object
		return self;
		}
	_contents = [[aDecoder decodeObject] retain];
	_font = [[aDecoder decodeObject] retain];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_c];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_d];
	_controlView = [aDecoder decodeObject];

	return self;
}

@end
