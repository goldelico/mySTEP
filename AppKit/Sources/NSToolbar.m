/*
 NSToolbar.h
 mySTEP
 
 Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
 Copyright (c) 2005-2008 DSITRI.
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
*/

#import "AppKit/NSToolbar.h"
#import "AppKit/NSToolbarItem.h"
#import "AppKit/NSToolbarItemGroup.h"
#import "NSAppKitPrivate.h"

@implementation NSToolbar

static NSHashTable *_toolbars;

- (id) initWithIdentifier:(NSString *) str; 
{
	// check in _toolbars if we already have one with this identifier
	// if yes, [self release] and return the existing one (retained)
	if((self=[super init]))
			{
				_identifier=[str retain];
				_displayMode=NSToolbarDisplayModeDefault;
				_sizeMode=NSToolbarSizeModeDefault;
			}
	// add to _toolbars
	return self;
}

- (void) dealloc
{
	// remove from _toolbars (if present)
	[_customizationPalette release];
	[_items release];
	[_visibleItems release];
	[_selectedItemIdentifier release];
	[super dealloc];
}

- (void) _changed;
{
	if(_toolbarView)
			{
				[_toolbarView layout];
				if(_autosavesConfiguration)
						{
							NSUserDefaults *ud=[NSUserDefaults standardUserDefaults];
							[ud setObject:[self configurationDictionary] forKey:[NSString stringWithFormat:@"NSToolbar Configuration %@", _identifier]];
						}
			}
}

- (void) _setToolbarView:(NSToolbarView *) view;
{ // becomes visible the first time
	NSDictionary *dict=[[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"NSToolbar Configuration %@", _identifier]];
	_toolbarView=view;	// weak reference since we are retained by the view
	[self setConfigurationFromDictionary:dict];	// interpret the configuration
}

- (NSToolbarView *) _toolbarView; { return _toolbarView; }

- (NSToolbarItem *) _itemForIdentifier:(NSString *) ident;
{
	NSEnumerator *f=[[self items] objectEnumerator];
	NSToolbarItem *item;
	while((item=[f nextObject]))
			{
				if([[item itemIdentifier] isEqualToString:ident])
					return item;
			}
	return nil;
}

- (BOOL) allowsUserCustomization; { return _allowsUserCustomization; }
- (BOOL) autosavesConfiguration;  { return _autosavesConfiguration; }

- (NSDictionary *) configurationDictionary;
{
	NSMutableArray *items=[NSMutableArray arrayWithCapacity:[_visibleItems count]];
	NSEnumerator *e=[_visibleItems objectEnumerator];
	NSToolbarItem *item;
	while((item=[e nextObject]))
		[items addObject:[item itemIdentifier]];
	return [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInt:_displayMode], @"TB Display Mode",
											[NSNumber numberWithInt:_sizeMode], @"TB Icon Size Mode",
											[NSNumber numberWithInt:_isVisible], @"TB Is Shown",
											items, @"TB Item Identifiers",
											[NSNumber numberWithInt:_sizeMode], @"TB Size Mode",	// oops what is the difference?
											[NSDictionary dictionary], @"TB Visibility Priority Values",	// should be NSDictionary!
											nil];
}

- (BOOL) customizationPaletteIsRunning; { return _customizationPalette != nil; }
- (id) delegate; { return _delegate; }
- (NSToolbarDisplayMode) displayMode; { return _displayMode; }
- (NSString *) identifier; { return _identifier; }

- (void) insertItemWithItemIdentifier:(NSString *) itemId atIndex:(NSInteger) idx;
{
	NSToolbarItem *item;
	// find by identifier in all known items?
	item=[_delegate toolbar:self itemForItemIdentifier:itemId willBeInsertedIntoToolbar:YES];	// delegate will configure the item
	if(item)
			{
				// send NSToolbarWillAddItemNotification
				[item _setToolbar:self];
				[_items addObject:item];
				[_visibleItems addObject:item];
				[self _changed];
			}
}

- (BOOL) isVisible; { return _isVisible; }

- (NSArray *) items;
{
	if(!_items)
			{ // create items array
				NSEnumerator *e=[[_delegate toolbarAllowedItemIdentifiers:self] objectEnumerator];
				NSString *ident;
				_items=[[NSMutableArray alloc] initWithCapacity:10];
				while((ident=[e nextObject]))
						{ // create toolbar items as needed
							NSToolbarItem *item=[_delegate toolbar:self itemForItemIdentifier:ident willBeInsertedIntoToolbar:YES];	// delegate will configure the item
							[_items addObject:item];
						}
			}
	return _items;
}

- (void) removeItemAtIndex:(NSInteger) idx;
{
	[_visibleItems removeObjectAtIndex:idx];
	// post NSToolbarDidRemoveItemNotification
 [self _changed];
}

- (void) runCustomizationPalette:(id) sender; 
{
	if(!_allowsUserCustomization)
		return;	// ignore
	// create and show palette
}

- (NSString *) selectedItemIdentifier; { return _selectedItemIdentifier; }
- (void) setAllowsUserCustomization:(BOOL) flag; { _allowsUserCustomization=flag; }
- (void) setAutosavesConfiguration:(BOOL) flag; { _autosavesConfiguration=flag; }

- (void) setConfigurationFromDictionary:(NSDictionary *) dict;
{
	id val;
	NSEnumerator *e;
	NSString *ident;
	if((val=[dict objectForKey:@"TB Display Mode"]))
		_displayMode=[val intValue];
	if((val=[dict objectForKey:@"TB Size Mode"]))
		_sizeMode=[val intValue];
	if((val=[dict objectForKey:@"TB Is Shown"]))
		_isVisible=[val boolValue];	// make visible
	if(!(val=[dict objectForKey:@"TB Item Identifiers"]))
			val=[_delegate toolbarDefaultItemIdentifiers:self];	// (re)set to default
	e=[val objectEnumerator];
	if(!_visibleItems)
		_visibleItems=[[NSMutableArray alloc] initWithCapacity:[val count]];
	while((ident=[e nextObject]))
			{ // find item by identifier
				NSToolbarItem *item=[self _itemForIdentifier:ident];
				if(item)
						[_visibleItems addObject:item];
			}
	if(!dict)
		[self _changed];	// save default settings
}

- (void) setDelegate:(id) delegate;
{
	if(delegate && !([delegate respondsToSelector:@selector(toolbarAllowedItemIdentifiers:)] &&
									[delegate respondsToSelector:@selector(toolbarDefaultItemIdentifiers:)] &&
									[delegate respondsToSelector:@selector(toolbar:itemForItemIdentifier:willBeInsertedIntoToolbar:)]
										))
		{
		NSLog(@"*** delegate does not respond to required NSToolbar delegate methods: %@", delegate);
		return;
	}
	_delegate=delegate;
	// also set as delgate for NSToolbarWillAddItemNotification and NSToolbarDidRemoveItemNotification
}

- (void) setDisplayMode:(NSToolbarDisplayMode) mode; { _displayMode=mode; [self _changed]; }
- (void) setSelectedItemIdentifier:(NSString *) itemId; { ASSIGN(_selectedItemIdentifier, itemId); [self _changed]; }
- (void) setShowsBaselineSeparator:(BOOL) flag; { _showsBaselineSeparator=flag; [self _changed]; }
- (void) setSizeMode:(NSToolbarSizeMode) mode; { _sizeMode=mode; [self _changed]; }
- (void) setVisible:(BOOL) flag; { _isVisible=flag; [self _changed]; [[_toolbarView superview] layout]; }
- (BOOL) showsBaselineSeparator; { return _showsBaselineSeparator; }
- (NSToolbarSizeMode) sizeMode; { return _sizeMode; }

- (void) validateVisibleItems;
{
	[_items makeObjectsPerformSelector:@selector(validate)];
}

- (NSArray *) visibleItems;
{ // translate from identifiers
	// we should have separate items if we have multiple items with same identifier!
	return _visibleItems;
}

@end

@implementation NSToolbarItem

- (SEL) action; { return _action; }
- (BOOL) allowsDuplicatesInToolbar; { return _allowsDuplicatesInToolbar; } 
- (BOOL) autovalidates; { return _autovalidates; }
- (NSImage *) image; { return _image; }

- (id) initWithItemIdentifier:(NSString *) itemId; 
{
	if((self=[super init]))
			{
				NSDictionary *dict=[[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"NSBuiltinToolbarItems"] objectForKey:itemId];
				_itemIdentifier=[itemId retain];
				if(dict)
						{ // initialize icon, label, action etc.
#if 1
							NSLog(@"init item %@ with %@", itemId, dict);
#endif
							_label=[[dict objectForKey:@"Label"] retain];
							_paletteLabel=[[dict objectForKey:@"PaletteLabel"] retain];
							_toolTip=[[dict objectForKey:@"ToolTip"] retain];
							_allowsDuplicatesInToolbar=[[dict objectForKey:@"AllowsDuplicates"] boolValue];
							if([[dict objectForKey:@"MinSize"] length] > 0)
								_minSize=NSSizeFromString([dict objectForKey:@"MinSize"]);
							if([[dict objectForKey:@"MaxSize"] length] > 0)
								_maxSize=NSSizeFromString([dict objectForKey:@"MaxSize"]);
							if([[dict objectForKey:@"Action"] length] > 0)
								_action=NSSelectorFromString([dict objectForKey:@"Action"]);	// _target is nil, i.e. firstResponder
						}
			}
	return self;
}

- (void) dealloc;
{
	[_itemIdentifier release];
	[_image release];
	[_label release];
	[_paletteLabel release];
	[_toolTip release];
	[_view release];
	[super dealloc];
}

- (BOOL) isEnabled; { return _isEnabled; }
- (NSString *) itemIdentifier; { return _itemIdentifier; }
- (NSString *) label; { return _label; }
- (NSSize) maxSize; { return _maxSize; }
- (NSMenuItem *) menuFormRepresentation; { return _menuFormRepresentation; }
- (NSSize) minSize; { return _minSize; }
- (NSString *) paletteLabel; { return _paletteLabel; }
- (void) setAction:(SEL) sel; { _action=sel; }
- (void) setAutovalidates:(BOOL) flag; { _autovalidates=flag; }
- (void) setEnabled:(BOOL) flag; { _isEnabled=flag; }
- (void) setImage:(NSImage *) img; { ASSIGN(_image, img); }
- (void) setLabel:(NSString *) str; { ASSIGN(_label, str); }
- (void) setMaxSize:(NSSize) size; { _maxSize=size; }
- (void) setMenuFormRepresentation:(NSMenuItem *) item; { NIMP; }
- (void) setMinSize:(NSSize) size; { _minSize=size; }
- (void) setPaletteLabel:(NSString *) label; { ASSIGN(_paletteLabel, label); }
- (void) setTag:(NSInteger) tag; { _tag=tag; }
- (void) setTarget:(id) target; { _target=target; }
- (void) _setToolbar:(NSToolbar *) view; { _toolbar=view; }
- (void) setToolTip:(NSString *) toolTip; { ASSIGN(_toolTip, toolTip); }
- (void) setView:(NSView *) view; { ASSIGN(_view, view); }
- (void) setVisibilityPriority:(NSInteger) priority; { _visibilityPriority=priority; }
- (NSInteger) tag; { return _tag; }
- (id) target; { return _target; }
- (NSToolbar *) toolbar; { return _toolbar; }
- (NSString *) toolTip; { return _toolTip; }

- (void) validate;
{
	id target=[NSApp targetForAction:_action to:_target from:self];
	if([target respondsToSelector:@selector(validateToolbarItem:)])
		[self setEnabled:[target validateToolbarItem:self]];
	else
		[self setEnabled:YES];
}

- (NSView *) view; { return _view; }
- (NSInteger) visibilityPriority; { return _visibilityPriority; }

NSString *NSToolbarSeparatorItemIdentifier=@"NSToolbarSeparatorItem";
NSString *NSToolbarSpaceItemIdentifier=@"NSToolbarSpaceItem";
NSString *NSToolbarFlexibleSpaceItemIdentifier=@"NSToolbarFlexibleSpaceItem";
NSString *NSToolbarShowColorsItemIdentifier=@"NSToolbarShowColorsItem";
NSString *NSToolbarShowFontsItemIdentifier=@"NSToolbarShowFontsItem";
NSString *NSToolbarCustomizeToolbarItemIdentifier=@"NSToolbarCustomizeToolbarItem";
NSString *NSToolbarPrintItemIdentifier=@"NSToolbarPrintItem";

@end

@implementation NSToolbarItemGroup

- (void) setSubitems:(NSArray *) items; { ASSIGN(_subitems, items); }
- (NSArray *) subitems; { return _subitems; }

@end
