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
#import <AppKit/NSTextView.h>
#import <AppKit/NSTextStorage.h>

#import "NSAppKitPrivate.h"

// Class variables
static NSFont *__defaultFont = nil;
static NSColor *__borderedBackgroundColor = nil;

@implementation NSCell

+ (void) initialize
{
	if (self == [NSCell class])
		{
		__defaultFont = [[NSFont userFontOfSize:0] retain];
		NSAssert(__defaultFont, @"get default font");	// we can't operate without one
		__borderedBackgroundColor = [[NSColor controlBackgroundColor] retain];
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
		ASSIGN(_menu, [[self class] defaultMenu]);	// set default context menu
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
		_c.floatAutorange = YES;
		_attribs=[[NSMutableDictionary alloc] initWithCapacity:5];
		[_attribs setObject:[[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease] forKey:NSParagraphStyleAttributeName];
		[self setAlignment:NSCenterTextAlignment];
		[self sendActionOn:NSLeftMouseUpMask];
		ASSIGN(_menu, [[self class] defaultMenu]);	// set default context menu
		_c.type = NSNullCellType;		// force initialization as NSTextCellType (incl. font & textColor)
		[self setType:NSTextCellType];	// make us a text cell which should assign default font and color
		ASSIGN(_contents, aString);
		_d.verticallyCentered=YES;	// default
		}
	return self;
}

- (void) dealloc
{
	[self setObjectValue:nil];
	[self setRepresentedObject:nil];
	[self setFormatter:nil];
	[self setMenu:nil];	
	[_attribs release];
	[super dealloc];
}

- (id) copyWithZone:(NSZone *) zone
{
	NSCell *c = [[self class] allocWithZone:zone];	// makes a real copy
	
	c->_contents = [_contents copyWithZone:zone];
	c->_controlView = _controlView;
	c->_representedObject = [_representedObject retain];
	c->_attribs = [_attribs mutableCopyWithZone:zone];
	c->_formatter = [_formatter retain];
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
	[a appendFormat:@"attribs=%@\n", _attribs];
	[a appendFormat:@"controlView=%@\n", _controlView];
	[a appendFormat:@"formatter=%@\n", _formatter];
	[a appendFormat:@"representedObject=%@\n", _representedObject];
	[a appendFormat:@"objectValue=%@", _contents];
	return a;
}

- (void) calcDrawInfo:(NSRect)aRect			{ return; }		// can be overridden by subclass

- (NSSize) cellSize
{
	NSSize m;
	// Font should depend on _d.controlSize!
	if(_c.type == NSTextCellType && _attribs)
		{
		if([_contents isKindOfClass:[NSAttributedString class]])
			m=[_contents size];
		else
			m=[_contents sizeWithAttributes:_attribs];
		m.width += 4.0;
		}
	else if (_c.type == NSImageCellType && _contents != nil)
		m=[_contents size];
	else
		m=NSZeroSize;
	
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
{ // cell draws itself (Inset on all sides to account for cell's border type)
	if(_c.bordered)
		return NSInsetRect(rect, 1, 1);
	if(_c.bezeled)
		return NSInsetRect(rect, 2, 2);
	return rect;
}

- (NSRect) imageRectForBounds:(NSRect)theRect
{
	theRect=NSInsetRect(theRect, 2, 2);
	return theRect;
}

- (NSRect) titleRectForBounds:(NSRect)theRect
{
	if(_c.type == NSTextCellType)
		theRect=NSInsetRect(theRect, 2, 1);
	return theRect;
}

- (void) setImage:(NSImage *)anImage
{
	if(_contents == anImage)
		return;
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
	_c.type=(unsigned int) aType;  // prevent recursion
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
		// FIXME: move some special initializations here
		[_attribs setObject:[NSColor controlTextColor] forKey:NSForegroundColorAttributeName];
		[_attribs setObject:__defaultFont forKey:NSFontAttributeName];
		break;
		// default: raise exception?
	}
}

- (void) setState:(NSInteger)value
{
	_c.state = (value>0?NSOnState:((value<0 && _c.allowsMixed)?NSMixedState:NSOffState));
}

- (void) setNextState;						{ [self setState:[self nextState]]; }
- (NSInteger) state								{ return _c.state; }
- (NSInteger) nextState
{
	if(_c.state < 0)	return NSOnState;	// Mixed -> On
	if(_c.state > 0)	return NSOffState;	// On -> Off
	return _c.allowsMixed?NSMixedState:NSOnState;	// Off -> Mixed or On
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
- (NSString *) title						{ return [self stringValue]; }
- (void) setTitle:(NSString *)title			{ [self setStringValue:title]; }
+ (NSMenu *) defaultMenu;					{ return nil; }
- (NSMenu *) menu							{ return _menu; }
- (void) setMenu:(NSMenu *)menu				{ ASSIGN(_menu, menu); }
- (id) objectValue							{ return _contents; }

- (NSMenu *) menuForEvent:(NSEvent *) event inRect:(NSRect) rect ofView:(NSView *) view
{
	NSMenu *m=[self menu];	// if we have an individual menu
	if(!m)
		m=[view menuForEvent:event];
	return m;
}

// CHECKME/FIXME - according to documentation this is NOT the formatted value but documentation is a little inconsistent here

- (void) setTitleWithMnemonic:(NSString *)aString; { [self setTitle:aString]; }

- (NSString *) stringValue;
{ // try to format as NSString
	return [[self _getFormattedStringIgnorePlaceholder:YES] string];
}

- (NSAttributedString *) attributedStringValue
{ // try to format as NSAttributedString
	return [self _getFormattedStringIgnorePlaceholder:YES];
}

- (double) doubleValue						{ return _contents?[_contents doubleValue]:0.0; }
- (float) floatValue;						{ return _contents?[_contents floatValue]:0.0; }
- (int) intValue							{ return [_contents intValue]; }

// FIXME: the formatter should be applied when setting the object - not when drawing!!!

- (void) setObjectValue:(id <NSCopying>)anObject
{
#if 0
	NSLog(@"%@ setObjectValue:%@ (_contents=%@)", self, anObject, _contents);
#endif
	if(anObject == _contents)
		return;	// needn't do anything
	[_contents release];	// we can release
	_contents=nil;
	if(_c.type == NSTextCellType)
		_contents=[anObject copyWithZone:NULL];	// save a copy (of a mutable string)
	else
		{ // image cell
			if(anObject && ![(id <NSObject>) anObject isKindOfClass:[NSImage class]])
				NSLog(@"setObjectValue not an NSImage %@", anObject); 
			_contents=[(NSObject *) anObject retain];	// copying an NSImage objectValue (e.g. the result of a TableView's dataSource) would cause a lot of trouble if it is not yet valid...
		}
#if 0
	NSLog(@"%@ setObjectValue done:", self);
#endif
	if(_c.editing)
		{ // update field editor to new value
			NSTextView *textObject=(NSTextView *) [[[self controlView] window] fieldEditor:NO forObject:[self controlView]];
			[[textObject textStorage] setAttributedString:[self attributedStringValue]];	// copy attributed string from cell to be edited
			//		[textObject setSelectedRange:(NSRange){selStart, selLength}];
			return;
		}
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
	if(aString && _c.type != NSTextCellType)
		[self setType:NSTextCellType];	// make us a text cell
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
	if(sender)
		[self setObjectValue:[NSNumber numberWithDouble:[sender doubleValue]]];
}

- (void) takeFloatValueFrom:(id)sender
{
	if(sender)
		[self setObjectValue:[NSNumber numberWithFloat:[sender floatValue]]];
}

- (void) takeIntValueFrom:(id)sender
{
	if(sender)
		[self setObjectValue:[NSNumber numberWithInt:[sender intValue]]];
}

- (void) takeStringValueFrom:(id)sender
{
	if(sender)
		[self setObjectValue:[sender stringValue]];
}

- (void) takeObjectValueFrom:(id)sender
{
	if(sender)
		[self setObjectValue:[sender objectValue]];
}

// Text Attributes 
- (void) setFloatingPointFormat:(BOOL)autoRange
						   left:(NSUInteger)leftDigits
						  right:(NSUInteger)rightDigits
{
	_c.floatAutorange = autoRange;					// FIX ME create formatter 
}													// if needed and set format

- (NSTextAlignment) alignment					{ return [[_attribs objectForKey:NSParagraphStyleAttributeName] alignment]; }
- (NSWritingDirection) baseWritingDirection				{ return [[_attribs objectForKey:NSParagraphStyleAttributeName] baseWritingDirection]; }
- (NSLineBreakMode) lineBreakMode					{ return [[_attribs objectForKey:NSParagraphStyleAttributeName] lineBreakMode]; }
- (void) setAlignment:(NSTextAlignment)mode		{ [[_attribs objectForKey:NSParagraphStyleAttributeName] setAlignment:mode]; }
- (void) setBaseWritingDirection:(NSWritingDirection)dir		{ [[_attribs objectForKey:NSParagraphStyleAttributeName] setBaseWritingDirection:dir]; }
- (void) setLineBreakMode:(NSLineBreakMode) mode; { [[_attribs objectForKey:NSParagraphStyleAttributeName] setLineBreakMode:mode]; }
- (void) setScrollable:(BOOL)flag				{ _c.scrollable = flag; }

- (void) setWraps:(BOOL)flag
{
	if(flag)
		{
		[self setLineBreakMode:NSLineBreakByWordWrapping];
		[self setScrollable:NO];
		}
	else  
		[self setLineBreakMode:NSLineBreakByClipping];
}

- (BOOL) isScrollable							{ return _c.scrollable; }
- (BOOL) wraps									{ switch([self lineBreakMode]) { case NSLineBreakByWordWrapping: case NSLineBreakByCharWrapping: return YES; default: return NO; } }
- (NSColor *) _textColor;						{ return [_attribs objectForKey:NSForegroundColorAttributeName]; }
- (void) _setTextColor:(NSColor *) textColor; { [_attribs setObject:textColor forKey:NSForegroundColorAttributeName]; }

- (NSFont *) font								{ return [_attribs objectForKey:NSFontAttributeName]; }

- (void) setFont:(NSFont*)fontObject
{
	if(fontObject)
		[_attribs setObject:fontObject forKey:NSFontAttributeName];
	else
		[_attribs removeObjectForKey:NSFontAttributeName];
}

- (BOOL) isEditable						{ return _c.editable; }
- (BOOL) isSelectable					{ return _c.selectable; }

- (void) setEditable:(BOOL)flag
{
	if ((_c.editable = flag))							// If cell is editable
		_c.selectable = flag;							// it is selectable 
}														

- (void) setSelectable:(BOOL)flag
{
	if (!(_c.selectable = flag))
		_c.editable = NO;								// If cell is not selectable then it's not editable
}

- (NSText *) setUpFieldEditorAttributes:(NSText *)textObject
{ // make the field editor imitate the cell as good as possible - note: the field editor is shared for all cells in a window
	[textObject setEditable:[self isEditable]];		// copy editable/selectable status to field editor
	[textObject setSelectable:[self isSelectable]];
	[textObject setBaseWritingDirection:[self baseWritingDirection]];
	[textObject setAlignment:[self alignment]];
	[textObject setImportsGraphics:NO];
	[textObject setRichText:YES];	// ? only if the object has an attributedStringValue! and if the NSText responds to -textStorage
	[textObject setUsesFontPanel:[textObject isRichText]];
	// FIXME: set other attributes of NSTextView
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
	
	[textObject mouseDown:event];	// NOTE: this will track until mouse goes up!
}

- (void) endEditing:(NSText *) textObject
{ // editing is complete, remove the text obj acting as field editor from window's view hierarchy
	NSView *v;
	NSRect r;
#if 1
	NSLog(@"endEditing %@", self);
#endif
	if([textObject respondsToSelector:@selector(textStorage)])
		[self setAttributedStringValue:[(NSTextView *) textObject textStorage]];
	else
		[self setStringValue:[textObject string]];
	[textObject setDelegate:nil];	// no longer send notifications
	_c.editing = NO;	// we may still be first responder - so suppress sending field editor notifications during resignFirstResponder
	if(_c.scrollable)
		{ // we did have an encapsulating clip view
			NSClipView *c = (NSClipView *) [textObject superview];
			v = [c superview];
			r = [c frame];
			[[c retain] autorelease];	// don't dealloc immedialtey
			[c removeFromSuperview];
		}
	else
		{
		v = [textObject superview];
		r = [textObject frame];
		[textObject removeFromSuperview];	
		}				
	[v setNeedsDisplayInRect:r];
}

- (void) selectWithFrame:(NSRect)aRect					// similar to editWith-
				  inView:(NSView*)controlView			// Frame method but can
				  editor:(NSText*)textObject			// be called from more
				delegate:(id)anObject	 				// than just mouseDown
				   start:(NSInteger)selStart
				  length:(NSInteger)selLength
{
	NSAssert(!_c.editing, @"still editing");
	if(controlView && textObject && _c.type == NSTextCellType)
		{
		NSWindow *w;
		NSClipView *controlSuperView;
#if 1
		NSLog(@"NSCell -selectWithFrame: %@", self);
		NSLog(@"	current window=%@", [textObject window]);

		// FIXME: superview may have become a dangling pointer!!!?

		NSLog(@"	current superview=%@", [textObject superview]);
		NSLog(@"	current firstResponder=%@", [[textObject window] firstResponder]);
#endif
		// make sure previous field editor is not in use
		if((w = [textObject window]))
			[w makeFirstResponder:w];
#if 0
		NSLog(@"	new firstResponder=%@", [[textObject window] firstResponder]);
#endif	
		controlSuperView = (NSClipView *)[textObject superview];
		if(controlSuperView && (![controlSuperView isKindOfClass:[NSClipView class]]))
			controlSuperView = nil;	// text object is not embedded in a clip view
		[textObject setDelegate:anObject];
		if([textObject respondsToSelector:@selector(textStorage)])
			[[(NSTextView *) textObject textStorage] setAttributedString:[self attributedStringValue]];	// copy attributed string from cell to be edited
		else
			[textObject setString:[self stringValue]];	// copy simple string from cell to be edited
		[textObject setSelectedRange:(NSRange){selStart, selLength}];
		[self setUpFieldEditorAttributes:textObject];
		
		if(_c.scrollable)
			{ // if we are scrollable, put us in a clipview
				[textObject setHorizontallyResizable:YES];	// don't adjust width to content rect
				[textObject setVerticallyResizable:NO];	// and not for height (i.e. keep as large as the cell we are editing)
				[textObject setFrame:(NSRect){{0,1},aRect.size}];
				if(!controlSuperView)
					{ // insert into new clipview
						controlSuperView = [[[NSClipView alloc] initWithFrame:aRect] autorelease];
						[controlSuperView setDocumentView:textObject];	// indirectly does [textObject sizeToFit]
					}
				else
					{ // update the clipview
						[controlSuperView setBoundsOrigin:NSZeroPoint];
						[controlSuperView setFrame:aRect];
						[textObject sizeToFit];
					}
				[controlView addSubview:controlSuperView];
			}
		else
			{ // remove us from any clip view
				if(controlSuperView)
					{
					[controlSuperView setDocumentView:nil];	// if we had been scrollable
					[controlSuperView removeFromSuperview];	// give up the clipview
					}
				[textObject setHorizontallyResizable:NO];	// keep as wide as the cell
				[textObject setVerticallyResizable:YES];	// adjust height if needed
				[textObject setFrame:NSOffsetRect(aRect, 1.0, -1.0)];	// adjust so that it really overlaps
				[controlView addSubview:textObject];
			}
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
- (void) setBezeled:(BOOL)flag					{ if((_c.bezeled = flag)) _c.bordered=NO; }
- (void) setBordered:(BOOL)flag					{ if((_c.bordered = flag)) _c.bezeled=NO; }

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

- (void) setCellAttribute:(NSCellAttribute)aParameter to:(NSInteger)value
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
	[self setControlView:controlView];
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

// FIXME: the formatter should be applied once when setting the object - not when drawing!???

- (NSAttributedString *) _getFormattedStringIgnorePlaceholder:(BOOL) flag;	// whichever is more convenient
{ // get whatever you have
	NSInteger length;
	NSAttributedString *string=nil;
#if 0
	NSLog(@"_getFormattedString...");
#endif
	NSDictionary *attribs=_attribs;	// set default
	if(!_c.enabled)
		{ // replace by disabledControlTextColor
			attribs=[[_attribs mutableCopy] autorelease];	// copy attributes
			[(NSMutableDictionary *) attribs setObject:[NSColor disabledControlTextColor] forKey:NSForegroundColorAttributeName];
		}
#if 0
	NSLog(@"attribs=%@", attribs);
	NSLog(@"_formatter=%@", _formatter);
	NSLog(@"_contents=%@", _contents);
	NSLog(@"_contents class=%@", [_contents class]);
#endif
	// FIXME: what happens if _contents is nil?
	if(_formatter)
		{
		if([_formatter respondsToSelector:@selector(attributedStringForObjectValue:withDefaultAttributes:)])
			string=[_formatter attributedStringForObjectValue:_contents withDefaultAttributes:attribs];
		if(string == nil)
			{
			NSString *fstring=[_formatter stringForObjectValue:_contents];
			if(!fstring)	// was't able to apply formatter
				fstring=_contents;
			string=[[[NSAttributedString alloc] initWithString:fstring attributes:attribs] autorelease];
			}
		}
	else if([_contents isKindOfClass:[NSAttributedString class]])
		string=_contents;   // is already an attributed string
	else
		string=[[[NSAttributedString alloc] initWithString:_contents?[_contents description]:@"(nil)" attributes:attribs] autorelease];
#if 0
	NSLog(@"string=%@", string);
#endif
	length=[string length];
	if(length > 0)
		{
		if(_c.secure)   // set by NSSecureTextField
			{
			string=[string mutableCopy];
			[(NSMutableAttributedString *) string replaceCharactersInRange:NSMakeRange(0, length) withString:[@"" stringByPaddingToLength:length withString:@"*" startingAtIndex:0]];	// replace with sequence of *
			[string autorelease];
			}
		}
	else if(!flag && _placeholderString)
		{ // substitute placeholder
			if([_placeholderString isKindOfClass:[NSAttributedString class]])
				string=_placeholderString;	// we already have an attributed placeholder
			else
				{
				string=[[[NSMutableAttributedString alloc] initWithString:_placeholderString attributes:attribs] autorelease];
				[(NSMutableAttributedString *) string addAttribute:NSForegroundColorAttributeName value:[NSColor disabledControlTextColor] range:NSMakeRange(0, [string length])];
				}
		}
#if 0
	NSLog(@"string=%@", string);
#endif
	return string;
}

// FIXME: shouldn't there be a version where imageScaling, imagePosition etc. is passed as a parameter?

- (void) _drawImage:(NSImage *) image withFrame:(NSRect) rect inView:(NSView *) controlView;
{
	NSCompositingOperation op = (_c.highlighted) ? NSCompositeHighlight : NSCompositeSourceOver;
	float fraction=(_c.highlighted?0.8:1.0);
#if 1	// new
	NSSize imageSize = [image size];
	if(_d.imageScaling != NSImageScaleNone)
		{
		NSSize isz;
		// hm... how/when do we apply this?
		isz=rect.size;
		if(_d.imageScaling == NSImageScaleAxesIndependently)
			imageSize=isz;
		else
			{ // proportionally
				float factor=MIN(isz.width/imageSize.width, isz.height/imageSize.height);
				if(_d.imageScaling != NSImageScaleProportionallyDown || factor < 1.0)
					{ // scale down image
						imageSize.width*=factor;
						imageSize.height*=factor;
					}
			}
		// [img setScalesWhenResized:YES];
		// [img setSize:imageSize];	// rescale
		}
	switch(_c.imagePosition) { // NSButtonCell - image relative to text
		case NSImageOnly:			// draw image only - centered
		case NSImageOverlaps:		// draw title over the centered image
			rect.origin.x += (NSWidth(rect) - imageSize.width)/2;
			rect.origin.y += (NSHeight(rect) - imageSize.height)/2;
			break;
		case NSImageLeft:								// draw image to the left of title
			rect.origin.x += 4;
			rect.origin.y += (NSHeight(rect) - imageSize.height)/2;
			break;
		case NSImageRight:								// draw image to the right of the title
			rect.origin.x += (NSWidth(rect) - imageSize.width) - 4;
			rect.origin.y += (NSHeight(rect) - imageSize.height)/2;
			break;
		case NSImageAbove:								// draw image above the title
			if(![controlView isFlipped])
				{
				rect.origin.x += (NSWidth(rect) - imageSize.width)/2;
				rect.origin.y += 4;
				}
			else
				{
				rect.origin.x += (NSWidth(rect) - imageSize.width)/2;
				rect.origin.y += (NSHeight(rect) - imageSize.height) - 4;
				}
			break;
		case NSImageBelow:								// draw image below the title
			if(![controlView isFlipped])
				{
				rect.origin.x += (NSWidth(rect) - imageSize.width)/2;
				rect.origin.y += (NSHeight(rect) - imageSize.height) - 4;
				}
			else
				{
				rect.origin.x += (NSWidth(rect) - imageSize.width)/2;
				rect.origin.y += 4;
				}
		break;
	}
	rect.size=imageSize;
#endif
	if([controlView isFlipped])
		{
		// FIXME: it appears as if we have to update the CTM here to revert flipping...
		// alternatively we can temporarily toggle the isFlipped state of the image
		BOOL flipped=[image isFlipped];
		[image setFlipped:!flipped];
		[image drawInRect:rect fromRect:NSZeroRect operation:op fraction:fraction];
		[image setFlipped:flipped];
		}
	else
		[image drawInRect:rect fromRect:NSZeroRect operation:op fraction:fraction];
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
		NSAttributedString *astring=[self _getFormattedStringIgnorePlaceholder:NO];
#if 0
		NSLog(@"NSCell drawInterior astring=%@", astring);
#endif
		if(_d.verticallyCentered)
			{ // vertically center
				NSSize size=[astring size]; // determine bounding box of text
				if([controlView isFlipped])
					frame.origin.y += (NSHeight(frame) - size.height) / 2;
				else
					frame.origin.y -= (NSHeight(frame) - size.height) / 2;
			}
#if 0
		NSLog(@"inFrame %@", NSStringFromRect(frame));
#endif
		[astring drawInRect:frame];
		return;
		}
	
	if(_c.type == NSImageCellType)
		{ // render image cell into the given frame
			[self _drawImage:_contents withFrame:frame inView:controlView];
		}
}

- (NSView *) controlView						{ return _controlView; }
- (void) setControlView:(NSView *) view;		{ _controlView=view; }
- (BOOL) isHighlighted							{ return _c.highlighted; }
- (void) setHighlighted:(BOOL)flag				{ _c.highlighted = flag; /* force redraw - if changed??? */ }
- (BOOL) isContinuous							{ return _c.continuous; }
- (void) setContinuous:(BOOL)flag				{ _c.continuous = flag; }
- (void) setTag:(NSInteger)anInt						{ SUBCLASS; }
- (NSInteger) tag										{ return -1; }
- (void) setTarget:(id)anObject					{ SUBCLASS; }
- (id) target									{ return nil; }
- (SEL) action									{ return NULL; }
- (void) setAction:(SEL) selector;				{ SUBCLASS; }
- (NSControlSize) controlSize					{ return _d.controlSize; }
- (void) setControlSize:(NSControlSize)sz		{ _d.controlSize = (unsigned int) sz; }
- (NSControlTint) controlTint					{ return _d.controlTint; }
- (void) setControlTint:(NSControlTint)ti		{ _d.controlTint = (unsigned int) ti; }
- (NSFocusRingType) focusRingType;				{ return _d.focusRingType; }
- (void) setFocusRingType:(NSFocusRingType) type; { _d.focusRingType = type; }

- (NSInteger) sendActionOn:(NSInteger)mask
{
	NSInteger previousMask = 0;
	
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

- (BOOL) _sendActionFrom:(NSView *) from
{ // based on stack trace
#if 0
	NSLog(@"_sendActionFrom: %@", from);
#endif
	if([from respondsToSelector:@selector(sendAction:to:)])
		return [(NSControl *) from sendAction:[self action] to:[self target]];
	return [NSApp sendAction:[self action] to:[self target] from:from];
}

- (void) performClick:(id)sender
{
	NSView *v=_controlView?_controlView:sender;
	NSRect b=[v bounds];	// we should have a better algorithm - i.e. ask the control for our exact rect
	NSDate *limit=[NSDate dateWithTimeIntervalSinceNow:0.3];
	[self setHighlighted:YES];
	[v setNeedsDisplayInRect:b];
#if 0
	NSLog(@"%@ performClick for view %@", self, v);
#endif
	if([self action])
		{
		NS_DURING
			[self _sendActionFrom:v];
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

- (NSUInteger) keyEquivalentModifierMask;
{
	return 0; // default implementation - should not match any key
}

- (NSString*) keyEquivalent								// Keyboard Alternative				
{
	return @""; // default implementation - should not match any key
}

- (NSInteger) mouseDownFlags
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

- (BOOL) _trackLongPress:(NSEvent *)event
				  inRect:(NSRect)cellFrame
				  ofView:(NSView *)controlView
			   lastPoint:(NSPoint) last_point
				 atPoint:(NSPoint) point
{
	NSMenu *contextMenu=[self menuForEvent:event inRect:cellFrame ofView:controlView];	// if we have a context menu, pop it up after approx. 0.5 seconds without movement
	if(!contextMenu)
		return NO;	// continue standard tracking
#if 0
	NSLog(@"NSCell pop up context menu: %@", contextMenu);
#endif
	if(_c.continuous)
		[NSEvent stopPeriodicEvents];	// was still tracking
	
	// we could start some animation (rotating circle like Maemo) while checking for the final popup...
	// FIXME: define correct popup position
	// FIXME: a popup menu should have some shadow or a border so that it can be distinguished from the background
	
	[self stopTracking:last_point
					at:point
				inView:controlView
			 mouseIsUp:NO];
	[NSMenu popUpContextMenu:contextMenu withEvent:event forView:controlView];	// show the popup menu
	return YES;	// exit tracking loop(s)
}

- (BOOL) trackMouse:(NSEvent *)event
			 inRect:(NSRect)cellFrame
			 ofView:(NSView *)controlView
	   untilMouseUp:(BOOL)untilMouseUp
{
	NSPoint point=[controlView convertPoint:[event locationInWindow] fromView:nil];
	NSPoint first_point=point;
	NSPoint last_point=point;
	SEL action = [self action];
	// FIXME: shouldn't we use [controlView menuForEvent:event]; and have that overriden in NSControl/NSMatrix (but not NSTableView!)
	NSDate *expiration;
	// FIXME: mask should probably depend on which mouse went down in event!
	NSUInteger mask = NSLeftMouseDraggedMask | NSRightMouseDraggedMask | NSLeftMouseDownMask | NSMouseMovedMask | NSLeftMouseUpMask;
	BOOL mouseWentUp = NO;
	NSEvent *mouseDownEvent=event;
	BOOL tracking;
	if(![self isEnabled])
		return NO;
	if(_c.continuous)	// (sub)cell class wants periodic tracking
		{ // enable periodic events
			float delay, interval;
			[self getPeriodicDelay:&delay interval:&interval];
			[NSEvent startPeriodicEventsAfterDelay:delay withPeriod:interval];
			mask |= NSPeriodicMask;
		}
	// FIXME: this does not pass the cellFrame to e.g. a NSSliderCell!
	tracking=[self startTrackingAt:point inView:controlView];
	if(_c.actOnMouseDown && action)
		[self _sendActionFrom:controlView];	// do this after starttracking (which may update the cell)
	expiration=[NSDate dateWithTimeIntervalSinceNow:0.8];
	// FIXME: ctrl-click should immediately _trackLongPress
	while(YES)
		{ // Get next mouse event until a mouse up is obtained
#if 0
			NSLog(@"NSCell expiration=%@", expiration);
#endif
			event = [NSApp nextEventMatchingMask:mask 
									   untilDate:expiration
										  inMode:NSEventTrackingRunLoopMode 
										 dequeue:YES];
#if 0
			NSLog(@"NSCell event=%@", event);
#endif
			if(!event)
				{ // no matching event, i.e. timed out
					if([self _trackLongPress:mouseDownEvent inRect:cellFrame ofView:controlView lastPoint:last_point atPoint:point])
						return YES;	// mouse went up
					expiration=[NSDate distantFuture];
					continue;
				}
#if 0
			NSLog(@"NSCell trackMouse: event=%@", event);
#endif
			switch([event type])
			{
				case NSPeriodic: { // send periodic action while tracking (e.g. for a slider)
					if(action)
						[self _sendActionFrom:controlView];
					continue;
				}
				case NSLeftMouseUp: { // Did mouse go up?
					mouseWentUp = YES;
					break;	// break loop
				}
				case NSLeftMouseDragged: { // pointer has moved
					last_point=point;
					point = [controlView convertPoint:[event locationInWindow] fromView:nil];
					if(fabs(point.x-first_point.x)+fabs(point.y-first_point.y) > 5.0)
						expiration=[NSDate distantFuture];	// if pointer has been moved too far, disable context menu detection
#if 0
					NSLog(@"NSCell trackMouse: pointIsInCell=%@", [controlView mouse:point inRect:cellFrame]?@"YES":@"NO");
#endif
					if(!untilMouseUp && ![controlView mouse:point inRect:cellFrame]) // we did leave the cell
						break;	// break loop when leaving the frame box
					if(_c.actOnMouseDragged)
						{ // send action while tracking (e.g. for a slider)
							if(action)
								[self _sendActionFrom:controlView];
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
	[self stopTracking:last_point						// Stop tracking mouse
					at:point
				inView:controlView
			 mouseIsUp:mouseWentUp];
	if(_c.actOnMouseUp && action && mouseWentUp)
		[self _sendActionFrom:controlView];
	return mouseWentUp;
}													

- (void) resetCursorRect:(NSRect)cellFrame				// Managing the Cursor
				  inView:(NSView *)controlView
{
	if(_c.type == NSTextCellType && _c.selectable && !_c.editing)
		[controlView addCursorRect:cellFrame cursor:[NSCursor IBeamCursor]];
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
	[aCoder encodeObject:[self font]];
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
		[self setLineBreakMode:LINEBREAKMODE];
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
		[self setAlignment:ALIGNMENT];
#define REFUSESFIRSTRESPONDER ((cellflags2&0x00010000)!=0)
		_c.refusesFirstResponder=REFUSESFIRSTRESPONDER;
#define ALLOWSUNDO ((cellflags2&0x00004000)==0)
		_d.allowsUndo=ALLOWSUNDO;
#define ALLOWSMIXEDSTATE ((cellflags2&0x01000000)!=0)
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
		if([aDecoder containsValueForKey:@"NSScale"])
			_d.imageScaling=[aDecoder decodeIntForKey:@"NSScale"];	// NSButtonCell
		else
			_d.imageScaling=NSScaleNone;
		
		_placeholderString=[[aDecoder decodeObjectForKey:@"NSPlaceholderString"] retain];
		[self setFont:[aDecoder decodeObjectForKey:@"NSSupport"]];		// font
		_menu=[[aDecoder decodeObjectForKey:@"NSMenu"] retain];
		if([aDecoder containsValueForKey:@"NSTextColor"])
			[self _setTextColor:[aDecoder decodeObjectForKey:@"NSTextColor"]];
		_formatter=[[aDecoder decodeObjectForKey:@"NSFormatter"] retain];
		if([aDecoder containsValueForKey:@"NSState"])
			_c.state = [aDecoder decodeIntForKey:@"NSState"];	// overwrite state
		if([aDecoder containsValueForKey:@"NSContents"])
			[self setTitle:[aDecoder decodeObjectForKey:@"NSContents"]];		// define sets title for buttons and stringValue for standard cells
		[aDecoder decodeObjectForKey:@"NSAccessibilityOverriddenAttributes"];	// just reference - should save and merge with superclass
		_controlView=[aDecoder decodeObjectForKey:@"NSControlView"];		// might be a class-swapped object!
#if 0
		NSLog(@"%@ initWithCoder:%@", self, aDecoder);
		NSLog(@"  NSCellFlags=%08x", [aDecoder decodeIntForKey:@"NSCellFlags"]);
		NSLog(@"  NSCellFlags2=%08x", [aDecoder decodeIntForKey:@"NSCellFlags2"]);
		NSLog(@"  textColor=%@", _textColor);
		NSLog(@"  drawsbackground=%d", _c.drawsBackground);
		NSLog(@"  alignment=%d", _c.alignment);
		NSLog(@"  state=%d", _c.state);
		NSLog(@"  contents=%@", _contents);
#endif
		return self;
		}
	_contents = [[aDecoder decodeObject] retain];
	[self setFont:[aDecoder decodeObject]];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_c];
	[aDecoder decodeValueOfObjCType:@encode(unsigned int) at: &_d];
	_controlView = [aDecoder decodeObject];
	
	return self;
}

@end
