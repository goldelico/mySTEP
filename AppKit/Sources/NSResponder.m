/* 
   NSResponder.m

   Abstract basis of command and event processing

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSCoder.h>
#import <Foundation/NSString.h>

#import <AppKit/NSResponder.h>
#import <AppKit/NSGraphics.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSScreen.h>

#import "NSAppKitPrivate.h"

@implementation NSResponder

- (void) dealloc;
{
	[_menu release];
	[super dealloc];
}

- (NSResponder *) nextResponder							{ return _nextResponder; }
- (void) setNextResponder:(NSResponder *)aResponder		{ _nextResponder = aResponder; }
- (BOOL) acceptsFirstResponder					{ return NO; }
- (BOOL) becomeFirstResponder					{ return YES; }
- (BOOL) resignFirstResponder					{ return YES; }
- (BOOL) performKeyEquivalent:(NSEvent*)event	{ return NO; }

- (BOOL) tryToPerform:(SEL)anAction with:anObject
{													
	if (![self respondsToSelector:anAction])
		{					 							// if we can't perform
		if (!_nextResponder)							// action see if the
			return NO;									// next responder can

		return [_nextResponder tryToPerform:anAction with:anObject];
		}												// else we can perform 
														// action and do so
	[self performSelector:anAction withObject:anObject];

	return YES;
}

- (void) doCommandBySelector:(SEL) sel;
{
	if([self respondsToSelector:sel])
		[self performSelector:sel withObject:nil];
	else if(_nextResponder)
		[_nextResponder doCommandBySelector:sel];	// pass down
	else
		[self noResponderFor:sel];
}

- (void) flagsChanged:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder flagsChanged:event];
	else
		[self noResponderFor:_cmd];
}

- (void) helpRequested:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder helpRequested:event];
	else
		[self noResponderFor:_cmd];
}

- (void) insertText:(id) aString
{
	if(_nextResponder)
		[_nextResponder insertText:aString];
	else
		[self noResponderFor:_cmd];
}

- (void) _interpretKeyEvents:(NSArray *) events inMappingTable:(NSDictionary *) mapping
{
	NSEnumerator *e=[events objectEnumerator];
	NSEvent *event;
	while((event=[e nextObject]))
		{
			// if userDefaults "NSQuotedKeystrokeBinding" found (default ctl-q) -> pass next character unbound
		unsigned int flags=[event modifierFlags];
			// the order of these flags appears to be fixed: http://www.erasetotheleft.com/post/mac-os-x-key-bindings/
		NSString *chars=[NSString stringWithFormat:@"%@%@%@%@%@%@%@",
										 flags&NSControlKeyMask?@"^":@"",
										 flags&NSShiftKeyMask?@"$":@"",
										 flags&NSAlternateKeyMask?@"~":@"",
										 flags&NSCommandKeyMask?@"@":@"",
										 flags&NSNumericPadKeyMask?@"#":@"",
										 flags&NSFunctionKeyMask?@"*":@"",	// unknown if this is compatible
							[event charactersIgnoringModifiers]];
		id sel;
		NSEnumerator *f;
		sel=[mapping objectForKey:chars];
		if(!sel)
			sel=[NSArray arrayWithObjects:@"insertText:", chars, nil];	// default
		else if([sel isKindOfClass:[NSDictionary class]])
			{ // submapping
				// FIXME: what do we do if we have not received enough events, i.e. [[e allObjects] length] == 0
			[self _interpretKeyEvents:[e allObjects] inMappingTable:sel];	// recursively try to interpret with remaining events
			break;	// done
			}
		else if([sel isKindOfClass:[NSString class]])
			sel=[NSArray arrayWithObject:sel];
		f=[sel objectEnumerator];
		while((sel=[f nextObject]))
			{ // process all array components in sequence
				if([sel hasSuffix:@":"])
						{ // appears to be a valid entry
							if([sel isEqualToString:@"insertText:"])
								[self insertText:[f nextObject]]; // handle special case
							else
								[self doCommandBySelector:NSSelectorFromString(sel)];
						}
			}
		}
}

- (void) interpretKeyEvents:(NSArray *) eventArray
{
	static NSDictionary *_keyMapping;
	if(!_keyMapping)
		{ // initialize table - according to http://www.erasetotheleft.com/post/mac-os-x-key-bindings/
			NSDictionary *dict;
			_keyMapping=[[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"StandardKeyBinding" ofType:@"dict"]];	// load standard binding
			// FIXME: use system method to get file path(s) to search through
			dict=[NSDictionary dictionaryWithContentsOfFile:@"/Library/KeyBindings/DefaultKeyBinding.dict"];
			if(dict)
				[(NSMutableDictionary *) _keyMapping addEntriesFromDictionary:dict];
			dict=[NSDictionary dictionaryWithContentsOfFile:@"/Library/KeyBindings/DefaultKeyBinding.dict"];
			if(dict)
				[(NSMutableDictionary *) _keyMapping addEntriesFromDictionary:dict];
		}
	[self _interpretKeyEvents:eventArray inMappingTable:_keyMapping];
}

- (void) keyDown:(NSEvent *)event
{
	if(_nextResponder)
		[_nextResponder keyDown:event];
	else
		[self noResponderFor:_cmd];
}

- (void) keyUp:(NSEvent *)event
{
	if(_nextResponder)
		[_nextResponder keyUp:event];
	else
		[self noResponderFor:_cmd];
}

- (void) scrollWheel:(NSEvent *)event
{
	if(_nextResponder)
		[_nextResponder scrollWheel:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseDown:(NSEvent *)event
{
	if(_nextResponder)
		[_nextResponder mouseDown:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseDragged:(NSEvent *)event
{
	if(_nextResponder)
		[_nextResponder mouseDragged:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseEntered:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder mouseEntered:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseExited:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder mouseExited:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseMoved:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder mouseMoved:event];
	else
		[self noResponderFor:_cmd];
}

- (void) mouseUp:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder mouseUp:event];
	else
		[self noResponderFor:_cmd];
}

- (void) noResponderFor:(SEL)eventSelector
{
#if 1
	NSLog(@"%@: noResponderFor %@", NSStringFromClass(isa), NSStringFromSelector(eventSelector));
#endif
	if(eventSelector == @selector(keyDown:))
		NSBeep();									// beep if key down event
}

- (void) rightMouseDown:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder rightMouseDown:event];
	else
		[self noResponderFor:_cmd];
}

- (void) rightMouseDragged:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder rightMouseDragged:event];
	else
		[self noResponderFor:_cmd];
}

- (void) rightMouseUp:(NSEvent *)event
{
	if (_nextResponder)
		[_nextResponder rightMouseUp:event];
	else
		[self noResponderFor:_cmd];
}
														// Services menu
- (id) validRequestorForSendType:(NSString *)typeSent
					  returnType:(NSString *)typeReturned
{
	if (_nextResponder)
		return [_nextResponder validRequestorForSendType:typeSent
							   returnType:typeReturned];
	return nil;
}

- (void) encodeWithCoder:(NSCoder *) aCoder							// NSCoding protocol
{
	[aCoder encodeConditionalObject:_nextResponder];
	[aCoder encodeConditionalObject:_menu];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if([aDecoder allowsKeyedCoding])
		{
		_nextResponder = [[aDecoder decodeObjectForKey:@"NSNextResponder"] retain];
		_menu = [[aDecoder decodeObjectForKey:@"NSMenu"] retain];
		}
	else
		{
		_nextResponder = [[aDecoder decodeObject] retain];
		_menu = [[aDecoder decodeObject] retain];
		}
	return self;
}

- (NSInterfaceStyle) interfaceStyle;
{ // style determines rescaling/moving of windows and behaviour of menus
	if(_interfaceStyle == NSNoInterfaceStyle)
		{
		NSScreen *menuScreen=[[NSScreen screens] objectAtIndex:0];
		NSRect f=[menuScreen _menuBarFrame];
		if(f.origin.y == 0.0)
			_interfaceStyle=NSPDAInterfaceStyle;	// bottom line menu, i.e. small PDA
		else
			_interfaceStyle=NSMacintoshInterfaceStyle;
		}
#if 0
	NSLog(@"interface style = %0x", _interfaceStyle);
#endif
	return _interfaceStyle;
}

- (void) setInterfaceStyle:(NSInterfaceStyle) style;
{
	NIMP;
}

- (BOOL) shouldBeTreatedAsInkEvent:(NSEvent *) theEvent; { return NO; }	// default has no ink-anywhere

- (NSMenu *) menu;	{ return _menu; }
- (void) setMenu:(NSMenu *)aMenu;	{ [_menu autorelease]; _menu=[aMenu retain]; }
- (BOOL) performMnemonic:(NSString *)string; { return NO; }

// predefine abstract methods

#define ACTION(NAME) -(void) NAME:(id)sender { SUBCLASS; }

ACTION(cancelOperation)
ACTION(capitalizeWord)
ACTION(centerSelectionInVisibleArea)
ACTION(changeCaseOfLetter)
ACTION(complete)
ACTION(deleteBackward)
ACTION(deleteBackwardByDecomposingPreviousCharacter)
ACTION(deleteForward)
ACTION(deleteToBeginningOfLine)
ACTION(deleteToBeginningOfParagraph)
ACTION(deleteToEndOfLine)
ACTION(deleteToEndOfParagraph)
ACTION(deleteToMark)
ACTION(deleteWordBackward)
ACTION(deleteWordForward)
ACTION(indent)
ACTION(insertBacktab)
ACTION(insertContainerBreak)	// NSTextView inserts 0x000c
ACTION(insertLineBreak)		// NSTextView inserts 0x2028
ACTION(insertNewline)
ACTION(insertNewlineIgnoringFieldEditor)
ACTION(insertParagraphSeparator)
ACTION(insertTab)
ACTION(insertTabIgnoringFieldEditor)
ACTION(lowercaseWord)
ACTION(moveBackward)
ACTION(moveBackwardAndModifySelection)
ACTION(moveDown)
ACTION(moveDownAndModifySelection)
ACTION(moveForward)
ACTION(moveForwardAndModifySelection)
ACTION(moveLeft)
ACTION(moveLeftAndModifySelection)
ACTION(moveRight)
ACTION(moveRightAndModifySelection)
ACTION(moveToBeginningOfDocument)
ACTION(moveToBeginningOfLine)
ACTION(moveToBeginningOfParagraph)
ACTION(moveToEndOfDocument)
ACTION(moveToEndOfLine)
ACTION(moveToEndOfParagraph)
ACTION(moveUp)
ACTION(moveUpAndModifySelection)
ACTION(moveWordBackward)
ACTION(moveWordBackwardAndModifySelection)
ACTION(moveWordForward)
ACTION(moveWordForwardAndModifySelection)
ACTION(moveWordLeft)
ACTION(moveWordLeftAndModifySelection)
ACTION(moveWordRight)
ACTION(moveWordRightAndModifySelection)
ACTION(pageDown)
ACTION(pageUp)
ACTION(scrollLineDown)
ACTION(scrollLineUp)
ACTION(scrollPageDown)
ACTION(scrollPageUp)
ACTION(selectAll)
ACTION(selectLine)
ACTION(selectParagraph)
ACTION(selectToMark)
ACTION(selectWord)
ACTION(setMark)
ACTION(showContextHelp)
ACTION(swapWithMark)
ACTION(transpose)
ACTION(transposeWords)
ACTION(uppercaseWord)
ACTION(yank)

@end /* NSResponder */
