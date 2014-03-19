/* 
   NSMenu.m

   Menu classes

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    July 1998
   Modified:  H. Nikolaus Schaller <hns@computer.org>
   Date:    2003-2005 
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/NSCoder.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSString.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSEnumerator.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSException.h>

#define _mySTEP_H_NSMenuItem	// don't load definition because we have our own

#import <AppKit/NSMenu.h>
#import <AppKit/NSScreen.h>
#import <AppKit/NSMatrix.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWindow.h>
#import <AppKit/NSEvent.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSMenu.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSButton.h>

NSString *NSMenuDidAddItemNotification=@"NSMenuDidAddItemNotification";
NSString *NSMenuDidChangeItemNotification=@"NSMenuDidChangeItemNotification";
NSString *NSMenuDidRemoveItemNotification=@"NSMenuDidRemoveItemNotification";

//*****************************************************************************
//
// 		NSMenuItem 
//
//*****************************************************************************

#import <AppKit/NSButtonCell.h>

// This class is based on NSButtonCell to avoid a lot of duplicate code
// But this is not externally known in the official interface!

// Class variables
static BOOL __userKeyEquivalents = YES;

@interface NSMenuItem : NSButtonCell  /* <NSMenuItem> */
{
	//	NSMenu *_menu;		// the supermenu we belong to (defined by NSCell)
	NSMenu	*_submenu;
	NSImage *_offStateImage;
	NSImage *_onStateImage;
	NSImage *_mixedStateImage;
	NSAttributedString *_attributedTitle;
	NSString *_toolTip;
	unsigned _mnemonicLocation;
	BOOL _isAlternate;
}

	// the following methods are defined in NSMenuItem protocol but not in NSButtonCell

+ (NSMenuItem *) separatorItem;
+ (void) setUsesUserKeyEquivalents:(BOOL)flag;
+ (BOOL) usesUserKeyEquivalents;
- (BOOL) isSeparatorItem;
- (BOOL) hasSubmenu;
- (NSMenu *) submenu;
- (void) setSubmenu:(NSMenu *) menu;
- (NSImage *) mixedStateImage;
- (NSImage *) offStateImage;
- (NSImage *) onStateImage;
- (void) setMixedStateImage:(NSImage *) image;
- (void) setOffStateImage:(NSImage *) image;
- (void) setOnStateImage:(NSImage *) image;
- (NSString*) userKeyEquivalent;
- (NSString*) userKeyEquivalentModifier;

	// private methods

- (void) _changed;
- (void) setMenu:(NSMenu *) menu;		// the menu we belong to
+ (NSMenuItem *) _menuItemWithTitle:(NSString*)aString
							    action:(SEL)aSelector
						 keyEquivalent:(NSString*)charCode;

@end

// due to the implementation trick we need to implement/override only those
// methods that differ from NSButtonCell/NSActionCell/NSCell

#import "NSAppKitPrivate.h"

@implementation NSMenuItem

- (void) _changed;
{ // notify all the menus we belong to about this change
#if 0
	NSLog(@"NSMenuItem %@ changed", [self title]);
#endif
	[_menu itemChanged:self];	// notify menu
}

- (void) setMenu:(NSMenu *) menu;
{ // define the menu we belong to (different from the superclass, this is not retained to avoid a retain-circle!)
	NSAssert((menu == nil || _menu == nil), @"NSMenuItem already belongs to an NSMenu");
	_menu=menu;
}

+ (void) setUsesUserKeyEquivalents:(BOOL)flag  { __userKeyEquivalents = flag; }
+ (BOOL) usesUserKeyEquivalents				   { return __userKeyEquivalents; }

+ (NSMenuItem *) _menuItemWithTitle:(NSString*)aString
							    action:(SEL)aSelector
							    keyEquivalent:(NSString*)charCode
{
	NSMenuItem *menuCell = [[self new] autorelease];
	[menuCell setTitle:aString];
	[menuCell setAction:aSelector];
	if(charCode)
		[menuCell setKeyEquivalent:charCode];
#if 0
	NSLog(@"_menuItemWithTitle %@ - count %d", menuCell, [menuCell retainCount]);
#endif
	return menuCell;
}

- (id) init
{
	self=[super init];  // init NSButtonCell
	if(self)
		{
		[self setAlignment:NSLeftTextAlignment];
		[self setOnStateImage:nil]; // set checkmark
		[self setMixedStateImage:nil]; // set horizontal line
		}
	return self;
}

- (id) initWithTitle:(NSString *) title action:(SEL) act keyEquivalent:(NSString *) key;
{
	self=[self init];
	if(self)
		{
		[self setTitle:title];
		[self setAction:act];
		[self setKeyEquivalent:key];
		}
	return self;
}

- (void) dealloc
{
#if 0
	NSLog (@"NSMenuItem '%@' dealloc", [self title]);
#endif
	_menu=nil;			// we have not retained, so don't use pointer any more by superclass or the following calls
	[self setTarget:nil];	// releases submenu
	[self setOffStateImage:nil];
	[self setOnStateImage:nil];
	[self setMixedStateImage:nil];
	[_toolTip release];
#if 0
	NSLog (@"NSMenuItem '%@' [super dealloc]", [self title]);
#endif
	[super dealloc];	// this will call setMenu:nil and setTitle:nil which will try to send change notifications
#if 0
	NSLog (@"NSMenuItem [super dealloc] done");
#endif
}

- (NSString *) description;
{
	NSMutableString *s=[NSMutableString stringWithFormat:@"%@: %@ -> [%@ %@]", 
							NSStringFromClass([self class]), 
							[self title]?[self title]:@"---",
							[self target] != self?[self target]:@"self",
							NSStringFromSelector([self action])
						];
#if 0
	if([self hasSubmenu])
		[s appendFormat:@" - %@", [self submenu]];
#endif
	return s;
}

- (id) copyWithZone:(NSZone *) z
{
	NSMenuItem *copy = [super copyWithZone:z];			// copy NSButton components
	if ([self hasSubmenu])
		{												// recursive call to
		[copy setSubmenu:[self submenu]];				// link to same submenu (makes the copy the new super-menu!!!)
		[copy setHighlighted:NO];
		}
	else
		[copy setTarget:[self target]];	
	copy->_isAlternate=_isAlternate;
	// copy any other items
	return copy;
}

- (BOOL) isEnabled	{ return [self hasSubmenu] || [super isEnabled]; }

// setter methods that change the visual representation must generate a change notification

- (BOOL) isAlternate;				{ return _isAlternate; }
- (void) setAlternate:(BOOL) flag;	{ _isAlternate=flag; [self _changed]; }
// setAttributedTitle
- (void) setEnabled:(BOOL) flag;	{ if(flag == [self isEnabled]) return; [super setEnabled:flag]; [self _changed]; }
- (void) setImage:(NSImage *) i;	{ [super setImage:i]; [self _changed]; }
// setIndentationLevel
// setKeyEquivalent
// - (void) setKeyEquivalentModifierMask:(unsigned int) mask
- (void) setMixedStateImage:(NSImage *) image;  { ASSIGN(_mixedStateImage, image); [self _changed]; }
// - (void) setMnemonicLocation:(unsigned) location
- (void) setOffStateImage:(NSImage *) image;	{ ASSIGN(_offStateImage, image); [self _changed]; }
- (void) setOnStateImage:(NSImage *) image;		{ ASSIGN(_onStateImage, image); [self _changed]; }
- (void) setRepresentedObject:(id) o;			{ [super setRepresentedObject:o]; [self _changed]; }
- (void) setState:(int) val;		{ if(val == [self state]) return; [super setState:val]; [self _changed]; }
- (void) setTitle:(NSString *) s;	{ if(s && [s isEqualToString:[self title]]) return; [super setTitle:s]; [self _changed]; }
- (NSAttributedString *) attributedTitle	{ return _attributedTitle; }
- (void) setAttributedTitle:(NSAttributedString *) s;	{ ASSIGN(_attributedTitle, s); [self _changed]; }
- (void) setTitleWithMnemonic:(NSString *) s;   { [super setTitleWithMnemonic:s]; [self _changed]; }

- (NSString *) keyEquivalent
{
	if (__userKeyEquivalents)
		return [self userKeyEquivalent];
	return [super keyEquivalent];
}

- (NSString *) userKeyEquivalent
{
	NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
	NSString *userKeyEquivalent = [[[defs persistentDomainForName:NSGlobalDomain]
									  objectForKey:@"NSCommandKeys"]
									  objectForKey:[self title]];

	if (!userKeyEquivalent)
		userKeyEquivalent = [super keyEquivalent];
	return userKeyEquivalent;
}

- (void) setTarget:(id) anObject								// Target / Action
{
	[_submenu release];
	_submenu=nil;	// if we have a target...
	[super setTarget:anObject];		// store in NSActionCell's target
	[self _changed];
}

- (BOOL) hasSubmenu;				{ return _submenu != nil; }
- (NSMenu *) submenu;				{ return _submenu?_submenu:nil; };
- (id) target;						{ return _submenu?nil:[super target]; };
- (void) setSubmenu:(NSMenu *) m;	{ ASSIGN(_submenu, m); [m setSupermenu:_menu]; }	// we must be attached to set a Supermenu

+ (NSMenuItem *) separatorItem;
{ // create separator item
	NSMenuItem *i=[[[self alloc] init] autorelease];
	[i setTitle:nil];   // no title
#if 0
	NSLog(@"Separator item %@ created - isSeparatorItem=%d", i, [i isSeparatorItem]);
#endif
	return i;
}

- (BOOL) isSeparatorItem; { return ![super title]; }	// nil title (instead of @"") - should also check for image (?)

- (NSImage *) offStateImage; { return _offStateImage; }
- (NSImage *) onStateImage; { return _onStateImage; }
- (NSImage *) mixedStateImage; { return _mixedStateImage; }
- (NSString *) userKeyEquivalentModifier; { NIMP; return @""; }

- (void) encodeWithCoder:(NSCoder*) coder
{
	NIMP
}

- (id) initWithCoder:(NSCoder*) coder
{ // NOTE: we are implemented as a subclass of NSButtonCell but archived as subclass of NSObject - therefore we should not call [super initWithCoder] and have to decode all keys directly
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#if 0
	NSLog(@"superclass %@", NSStringFromClass([self superclass]));
	NSLog(@"super class %@", NSStringFromClass([super class]));
#endif
#endif
	if([coder allowsKeyedCoding])
		{ // initialize, then submenus and finally supermenu
		self=[self initWithTitle:[coder decodeObjectForKey:@"NSTitle"]
						  action:NSSelectorFromString([coder decodeObjectForKey:@"NSAction"])
				   keyEquivalent:[coder decodeObjectForKey:@"NSKeyEquiv"]];
		if([coder decodeBoolForKey:@"NSIsSeparator"])
			[self setTitle:nil];   // has nil title (there is an empty one in the NIB)
		_keyEquivalentModifierMask=[coder decodeIntForKey:@"NSKeyEquivModMask"];
		_mnemonicLocation=[coder decodeIntForKey:@"NSMnemonicLoc"]; // position of the underlined character
		_toolTip=[[coder decodeObjectForKey:@"NSToolTip"] retain];
		_onStateImage=[[coder decodeObjectForKey:@"NSOnImage"] retain];
		_mixedStateImage=[[coder decodeObjectForKey:@"NSMixedImage"] retain];
		_offStateImage=[[coder decodeObjectForKey:@"NSImage"] retain];	// try NSImage
		_isAlternate=[coder decodeIntForKey:@"NSIsAlternate"];
		_attributedTitle=[[coder decodeObjectForKey:@"NSAttributedTitle"] retain];
		// FIXME
		[coder decodeBoolForKey:@"NSIsHidden"];
		[coder decodeObjectForKey:@"NSAlternateAttributedTitle"];
		// END_FIXME
		tag=[coder decodeIntForKey:@"NSTag"];
		[self setFont:[coder decodeObjectForKey:@"NSFont"]];
		[super setEnabled:[coder decodeBoolForKey:@"NSIsDisabled"]];
		[self setState:[coder decodeIntForKey:@"NSState"]];
		[self setTarget:[coder decodeObjectForKey:@"NSTarget"]];	// not all menus are connected by connectors...
		[self setSubmenu:[coder decodeObjectForKey:@"NSSubmenu"]];	// attach any submenu we are controlling
		[coder decodeObjectForKey:@"NSMenu"];	// decode supermenu - this might recursively initialize!
#if 0
		NSLog(@"initializedWithCoder: %@", self);
#endif
		return self;
		}
	return NIMP;
}

// we can't get that from a NSMenuItem although it is implemented as a subclass of NSButtonCell

- (NSString *) stringValue; { abort(); return NIMP; }
- (BOOL) boolValue; { NIMP; return NO; }
- (int) intValue; { NIMP; return 0; }
- (float) floatValue; { NIMP; return 0.0; }
- (double) doubleValue; { NIMP; return 0.0; }

@end

//*****************************************************************************
//
// 		NSMenu 
//
//*****************************************************************************

// CLass variables

@implementation NSMenu

+ (NSZone *) menuZone;					{ return NSDefaultMallocZone(); }

+ (void) popUpContextMenu:(NSMenu *) menu withEvent:(NSEvent *) event forView:(NSView *) view;
{ // open with default font
	[self popUpContextMenu:menu withEvent:event forView:view withFont:nil];
}

+ (void) popUpContextMenu:(NSMenu *) menu withEvent:(NSEvent *) event forView:(NSView *) view withFont:(NSFont *) font;
{
	SUBCLASS;	// overwritten as category in NSMenuView
}

+ (BOOL) menuBarVisible;
{
	// should ask systemUIServer
	return YES;
}

+ (void) setMenuBarVisible:(BOOL) flag;
{
	// should ask the systemUIServer for doing that for us
	// and show/hide our own menu bar(s) in NSApplication
	// [NSApplication _setMenuBarVisible:flag];
}

+ (void) setMenuZone:(NSZone *) zone;   { return; /* ignored */ }

- (id) init
{
	return [self initWithTitle:[[NSProcessInfo processInfo] processName]];
}

- (id) initWithTitle:(NSString*)aTitle
{
	if((self=[super init]))
		{
		ASSIGN(_title, aTitle);
		_mn.menuChangedMessagesEnabled = YES;
		_mn.autoenablesItems = YES;
		_menuItems = [[NSMutableArray arrayWithCapacity:5] retain];
		}
	return self;
}

- (void) dealloc
{
	NSDebugLog (@"NSMenu '%@' dealloc", _title);
	_mn.menuChangedMessagesEnabled=NO;
	while([_menuItems count] > 0)
		[self removeItemAtIndex:0];	// clean up
	[_menuItems release];
	[_title release];
	[super dealloc];
}

- (NSString *) _longDescription;
{ // incl. menu items and submenus
	return [NSString stringWithFormat:@"%@ %08x: %@ -> %@",
		NSStringFromClass([self class]), self,
		[self title], _menuItems];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@ %08x: %@", 
		NSStringFromClass([self class]), self, [self title]];
}

- (id) copyWithZone:(NSZone *) z
{
	NSMenu *copy = [isa allocWithZone:z];
	copy->_title = [_title copyWithZone:z];
	copy->_menuItems = [_menuItems copyWithZone:z];
	return copy;
}

- (CGFloat) menuBarHeight; 
{
	if(self == [NSApp mainMenu])
		return [isa menuBarHeight];
	return 0.0;
}

- (void) addItem:(NSMenuItem *) item
{
#if 0
	NSLog(@"a addItem %@ - count %d", item, [item retainCount]);
#endif
	_mn.menuHasChanged = YES;
	[_menuItems addObject:item];	// append
	[(NSMenuItem *) item setMenu:self];
	[[item submenu] setSupermenu:self]; // attach (submenu may be nil)
	if(_mn.menuChangedMessagesEnabled)
		[[NSNotificationCenter defaultCenter]
				postNotificationName:NSMenuDidAddItemNotification
							  object:self
							userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[_menuItems count]-1]   // has already been added to itemArray
																 forKey:@"NSMenuItemIndex"]];
#if 0
	NSLog(@"b addItem %@ - count %d", item, [item retainCount]);
#endif
}

- (NSMenuItem *) addItemWithTitle:(NSString*)aString
							  action:(SEL)aSelector
							  keyEquivalent:(NSString*)charCode
{
	id m = [NSMenuItem _menuItemWithTitle:aString
						action:aSelector
						keyEquivalent:charCode];
	[self addItem:m];
	return m;
}

- (void) insertItem:(NSMenuItem *) item atIndex:(int) index;
{
	_mn.menuHasChanged = YES;							// menu needs update
	[_menuItems insertObject:item atIndex:index];
	[(NSMenuItem *) item setMenu:self];
	[[item submenu] setSupermenu:self]; // (re-)attach
	if(_mn.menuChangedMessagesEnabled)
		[[NSNotificationCenter defaultCenter]
			postNotificationName:NSMenuDidAddItemNotification 
						  object:self
						userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index]
															 forKey:@"NSMenuItemIndex"]];
}

- (NSMenuItem *) insertItemWithTitle:(NSString*)aString
								 action:(SEL)aSelector
			 					 keyEquivalent:(NSString*)charCode
			       				 atIndex:(int)index
{
	id m = [NSMenuItem _menuItemWithTitle:aString
								   action:aSelector
							keyEquivalent:charCode];
	[self insertItem:m atIndex:index];
	return m;
}

- (void) removeItem:(NSMenuItem *)item;
{
	int row = [_menuItems indexOfObject:item];
	if (row == NSNotFound)
		return; // not part of this menu
	[self removeItemAtIndex:row];
}

- (void) removeItemAtIndex:(int) index;
{
	NSMenuItem *item=[self itemAtIndex:index];
#if 0
	NSLog(@"a removeItem %@ - count %d", item, [item retainCount]);
#endif
	[(NSMenuItem *) item setMenu:nil];		// I am no longer wishing to get notified about item changes
	[[item submenu] setSupermenu:nil];		// detach
#if 0
	NSLog(@"b removeItem %@ - count %d", item, [item retainCount]);
#endif
	[_menuItems removeObjectAtIndex:index];	// this should finally release/dealloc the item, so do it last!
#if 0
	NSLog(@"c removeItem done");
#endif
	if(_mn.menuChangedMessagesEnabled)
		[[NSNotificationCenter defaultCenter]
				postNotificationName:NSMenuDidRemoveItemNotification
							  object:self
							userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:index]
																 forKey:@"NSMenuItemIndex"]];
	_mn.menuHasChanged = YES;							// menu needs update (maybe later)
}

- (void) itemChanged:(NSMenuItem *)anItem
{ // we are notified by the NSMenuItem
	if(_mn.menuChangedMessagesEnabled)
		{
		int row=[_menuItems indexOfObject:anItem];
		if(row == NSNotFound)
			return; // not part of this menu
#if 0
		NSLog(@"itemChanged notification");
#endif
		[[NSNotificationCenter defaultCenter] postNotificationName:NSMenuDidChangeItemNotification
															object:self
														  userInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:row] forKey:@"NSMenuItemIndex"]];
		}
	_mn.menuHasChanged = YES;	// menu needs update (maybe later)
}

- (NSMenuItem *) itemWithTag:(int)aTag
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	while((m = [e nextObject]))
		if([m tag] == aTag)
			return m;
	return nil;
}

- (NSMenuItem *) itemWithTitle:(NSString*)aString
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	while((m = [e nextObject]))
		if([[m title] isEqualToString:aString])
			return m;
	return nil;
}

- (int) indexOfItem:(NSMenuItem *) item;
{
	unsigned int idx=[_menuItems indexOfObject:item];
	if(idx != NSNotFound)
		return idx;
	return -1;
}

- (int) indexOfItemWithRepresentedObject:(id) object;
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	int i=0;
	for(; (m = [e nextObject]); i++)
		if([m representedObject] == object)
			return i;
	return -1;  // not found
}

- (int) indexOfItemWithSubmenu:(NSMenu *) submenu;
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	int i=0;
	for(; (m = [e nextObject]); i++)
		if([m submenu] == submenu)
			return i;
	return -1;  // not found
}

- (int) indexOfItemWithTag:(int) tag;
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	int i=0;
	for(; (m = [e nextObject]); i++)
		if([m tag] == tag)
			return i;
	return -1;  // not found
}

- (int) indexOfItemWithTarget:(id) target andAction:(SEL) action;
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *item;
	int i=0;
	for(; (item = [e nextObject]); i++)
		{
#if 0
		NSLog(@"item=%@", item);
		NSLog(@"check %@ %@=%@", [item title], [item target], target);
#endif
		if([item target] != target)
			continue;	// no match
#if 0
		NSLog(@"check %@=%@", NSStringFromSelector([item action]), NSStringFromSelector(action));
#endif
		if(!action || ([item action] && sel_isEqual([item action], action)))
			return i;	// first with matching target or the one matching action
		}
	return -1;  // not found
}

- (int) indexOfItemWithTitle:(NSString *) title;
{
	NSEnumerator *e = [_menuItems objectEnumerator];
	NSMenuItem *m;
	int i=0;
	for(; (m = [e nextObject]); i++)
		if([[m title] isEqualToString:title])
			return i;
	return -1;  // not found
}

- (void) setTitle:(NSString*)aTitle; { ASSIGN(_title, aTitle); [self sizeToFit]; }
- (NSString*) title							{ return _title; }

- (void) submenuAction:(id)sender			{ NIMP }		// item's that open submenu
- (NSArray *) itemArray						{ return _menuItems; }
- (int) numberOfItems;						{ return [[self itemArray] count]; }
- (NSMenuItem *) itemAtIndex:(int) index;	{ return [[self itemArray] objectAtIndex:index]; }
- (NSMenu *) attachedMenu;					{ return _attachedMenu; }
- (NSMenu *) supermenu;						{ return _supermenu; }
- (void) setSupermenu:(NSMenu *) menu;		{ _supermenu=menu; }	// does not retain!!!
- (id) delegate;							{ return _delegate; }

- (void) setDelegate:(id) delegate;
{ // does not retain!!!
	if(delegate && ![delegate respondsToSelector:@selector(menuNeedsUpdate:)])
		NSLog(@"NSMenu delegate does not respond to menuNeedsUpdate:");
	_delegate=delegate;
}

- (id) menuRepresentation;					{ return _menuRepresentation; }

- (void) setMenuRepresentation:(id) r;
{ // r should be the NSMenuView - not retained!
	_menuRepresentation=r;
#if 0
	NSLog(@"%@ setMenuRep: %@", self, r);
#endif
}

- (id) contextMenuRepresentation;			{ return _contextMenuRepresentation; }
- (void) setContextMenuRepresentation:(id) r;   { _contextMenuRepresentation=r; }	// does not retain!!!
- (id) tearOffMenuRepresentation;			{ return _tearOffMenuRepresentation; }
- (void) setTearOffMenuRepresentation:(id) r;   { _tearOffMenuRepresentation=r; }	// does not retain!!!
- (BOOL) autoenablesItems					{ return _mn.autoenablesItems;}
- (void) setAutoenablesItems:(BOOL)flag		{ _mn.autoenablesItems = flag;}
- (BOOL) isTornOff							{ return _mn.isTornOff; }

- (BOOL) isAttached		
{ 
	return (_supermenu) && [_supermenu attachedMenu] == self;
}

- (NSPoint) locationForSubmenu:(NSMenu*)aSubmenu
{
//	NSRect f = [window frame];
//	NSRect submenuFrame = (aSubmenu) ? [aSubmenu->window frame] : NSZeroRect;
  //	return (NSPoint){NSMaxX(f) + 1, NSMaxY(f) - NSHeight(submenuFrame)};
	NIMP;
	return NSZeroPoint;
}

- (void) update
{												
	int i;				// if we have a torn off copy 
						// and self is not torn off
//	NSDebugLog(@"NSMenu update: %@", [self title]);
	if(_mn.autoenablesItems)
		{
#if 0
		NSLog(@"NSMenu update (%@)", [self title]);
#endif
		if(_mn.hasTornOffMenu && !_mn.isTornOff)	// update the torn off menu
			[tornOffMenu update];
		//	NSDebugLog(@"NSMenu update 2");
		_mn.menuChangedMessagesEnabled = NO;		// Temp disable menu auto display
		for (i = 0; i < [self numberOfItems]; i++)
			{ // warning!!! a validator might change the menu cells array by adding/removing cells - therefore compare dynamically to numberOfItems
			NSMenuItem *item = [_menuItems objectAtIndex:i];
			SEL action = [item action];
			NSObject *validator = nil;
			BOOL wasEnabled;
			BOOL shouldBeEnabled;		
			if([item hasSubmenu])					// recursively update submenu items if any
				{
#if 0
				NSLog(@"submenu update %@", [item submenu]);
#endif
				[[item submenu] update];
				continue;
				}
			wasEnabled = [item isEnabled];
#if 0
			NSLog(@"find validator for action %@", NSStringFromSelector(action));
#endif
			if(!action)
				validator=nil;  // nil action - will disable
			else
				{ // check target if defined or responder chain
				validator = [item target];
				if(!validator || ![validator respondsToSelector:action])
					validator=[NSApp targetForAction:action];	// go through responder chain
				}
#if 0
			NSLog(@"validator for action %@ = %@", NSStringFromSelector(action), validator);
#endif
			if(validator != nil)
				{ 
#if 0
				NSLog(@"check if validator=%@ conforms to protocol NSMenuValidation", validator);
#endif
				if([validator respondsToSelector:@selector(validateMenuItem:)])
					{
#if 0
					NSLog(@"%@ supports @protocol(validateMenuItem)", validator);
#endif
					shouldBeEnabled = [validator validateMenuItem:item];
					}
				else
					{
#if 0
					NSLog(@"%@ does not support @protocol(validateMenuItem)", validator);
#endif
					shouldBeEnabled = YES;  // default
					}
				}
			else
				shouldBeEnabled = NO;
#if 0
			NSLog(@"validator=%@ shouldBeEnabled=%d", validator, shouldBeEnabled);
#endif
			if(shouldBeEnabled != wasEnabled)
				{ // changed
				[item setEnabled:shouldBeEnabled];	// really changed
				}
			}
		_mn.menuChangedMessagesEnabled = YES;		// Reenable displaying of menus
		}
	if(_mn.menuHasChanged)						// resize NSMenuView if menu has been changed
		[self sizeToFit];
}

- (void) performActionForItemAtIndex:(int)index;
{
	SEL action;
	id target;
	NSMenuItem *item=[_menuItems objectAtIndex:index];
	if(![item isEnabled])
		return;
	NSLog(@"perform: \"%@\" for cell title", [item title]);
	NSLog(@"target: [%@ %@%@]", [item target], NSStringFromSelector([item action]), item);
	action = [item action];
	// Search the target
	if((target = [item target]))
		{
		if(![target respondsToSelector:action])
			return; // target is defined explicitly but does not respond
		}
	else
		target=[NSApp targetForAction:action];	// get first responder
	NSLog(@"targetForAction = %@", target);
	NS_DURING
		[target performSelector:action withObject:item];	// find proper responder
	NS_HANDLER
		NSLog(@"Exception for Menu Item action method: %@", [localException reason]);
	NS_ENDHANDLER
}

- (BOOL) performKeyEquivalent:(NSEvent*)event
{
	int i, count = [_menuItems count];
	for(i = 0; i < count; i++)
		{
		NSMenuItem *item = [_menuItems objectAtIndex:i];
		NSString *key;
		unsigned int modifiers;
		if([item hasSubmenu])
			return [[item submenu] performKeyEquivalent:event]; // event should been handled by a cell in submenu	
		if(![item isEnabled])
			continue;
		key = [event charactersIgnoringModifiers];
		modifiers=[event modifierFlags] & (NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask | NSShiftKeyMask);
#if 0
		NSLog(@"check %x == %x and %@ == %@", [item keyEquivalentModifierMask], modifiers, [item keyEquivalent], key);
#endif
		if(([item keyEquivalentModifierMask] == modifiers) && [[item keyEquivalent] isEqualToString:key]) 
			{ // required modifier is present
			[self performActionForItemAtIndex:i];
			return YES;
			}
		}
	return NO;	// not handled by this menu (hierarchy)
}

- (void) setMenuChangedMessagesEnabled:(BOOL)flag
{
	_mn.menuChangedMessagesEnabled = flag;
	if(flag && _mn.menuHasChanged)
		{
#if 0
		NSLog(@"make %@ catch up menuChangedMessages", _menuRepresentation);
#endif
		[_menuRepresentation setMenu:self]; // notify NSMenuView to rebuild NSMenuItemCells list to match menu
		}
}

- (BOOL) menuChangedMessagesEnabled
{
	return _mn.menuChangedMessagesEnabled;
}

- (void) sizeToFit
{
#if 0
	NSLog(@"NSMenu sizeToFit: %@", self);
#endif
	if(_menuRepresentation)
		{
		[_menuRepresentation sizeToFit];	// if we have a representation
		// _mn.menuHasChanged = NO;
		}
}

- (void) setSubmenu:(NSMenu*) aMenu forItem:(NSMenuItem *) anItem
{
	[anItem setSubmenu:aMenu];
	[anItem setAction:@selector(submenuAction:)];
	if([aMenu supermenu])
		;	// raise exception???
	if(aMenu)
		[aMenu setSupermenu:self];  // set myself as the supermenu of all items
	_mn.menuHasChanged = YES;
	if(_mn.menuChangedMessagesEnabled)
		[self sizeToFit];
}

- (void) helpRequested:(NSEvent *) event; { NIMP }

- (void) encodeWithCoder:(NSCoder*) coder
{
	NIMP
}

- (id) initWithCoder:(NSCoder*) coder
{
#if 0
	NSLog(@"%@ initWithCoder", NSStringFromClass([self class]));
#endif
	if([coder allowsKeyedCoding])
		{ 
		NSString *name;
		NSEnumerator *e;
		NSMenuItem *i;
		self=[self initWithTitle:[coder decodeObjectForKey:@"NSTitle"]];
		menuFont=[coder decodeObjectForKey:@"NSMenuFont"];	// new in 10.6
		name=[coder decodeObjectForKey:@"NSName"];
		e=[[coder decodeObjectForKey:@"NSMenuItems"] objectEnumerator];	// decode items
		while((i=[e nextObject]))
			[self addItem:i];	// add menu items
		if([name length] > 0)
			{
#if 0
			NSLog(@"menu (name=%@): %@", name, self);
#endif
			if([name isEqualToString:@"_NSMainMenu"])
				[[NSApplication sharedApplication] setMainMenu:self];
			else if([name isEqualToString:@"_NSAppleMenu"])
				[[NSApplication sharedApplication] _setAppleMenu:self];	// FIXME: what if that is decoded before the mainmenu?
			else if([name isEqualToString:@"_NSServicesMenu"])
				[[NSApplication sharedApplication] setServicesMenu:self];
			else if([name isEqualToString:@"_NSWindowsMenu"])
				[[NSApplication sharedApplication] setWindowsMenu:self];
			else if([name isEqualToString:@"_NSFontMenu"])
				[[NSFontManager sharedFontManager] setFontMenu:self];
			else if([name isEqualToString:@"_NSRecentDocumentsMenu"])
				[[NSDocumentController sharedDocumentController] _setOpenRecentMenu:self];
			else if([name isEqualToString:@"_NSOpenDocumentsMenu"])
				[[NSDocumentController sharedDocumentController] _setOpenRecentMenu:self];
			else
				NSLog(@"unknown menu (name=%@): %@", name, self);
			}
		if(_mn.menuHasChanged)		// resize if menu has been changed
			[self sizeToFit];
#if 0
		NSLog(@"initializedWithCoder: %@", [self _longDescription]);
#endif
		return self;
		}
	return NIMP;
}

/* 10.5

 '-showsStateColumn' not found
 '-setShowsStateColumn:' not found
 '-highlightedItem' not found
 '-cancelTracking' not found
*/

@end /* NSMenu */
