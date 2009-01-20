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
#import "AppKit/NSView.h"
#import "NSAppKitPrivate.h"

@implementation NSToolbar

static NSMapTable *_toolbars;

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
	[_activeItems release];
	[_selectedItemIdentifier release];
	[super dealloc];
}

- (void) _changed;
{
	if(_toolbarView)
			{
				[_toolbarView layout];
				[[_toolbarView superview] layout];	// theme frame also needs new layout
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
	NSMutableArray *items=[NSMutableArray arrayWithCapacity:[_activeItems count]];
	NSEnumerator *e=[_activeItems objectEnumerator];
	NSToolbarItem *item;
	NSMutableDictionary *priorities=[NSMutableDictionary dictionaryWithCapacity:[_activeItems count]];
	while((item=[e nextObject]))
			{
				[items addObject:[item itemIdentifier]];
				if([item visibilityPriority] != NSToolbarItemVisibilityPriorityStandard)
					[priorities setObject:[NSArray arrayWithObject:[NSNumber numberWithInt:[item visibilityPriority]]] forKey:[item itemIdentifier]];
			}
	return [NSDictionary dictionaryWithObjectsAndKeys:
											[NSNumber numberWithInt:_displayMode], @"TB Display Mode",
											[NSNumber numberWithInt:_sizeMode], @"TB Icon Size Mode",
											[NSNumber numberWithInt:_isVisible], @"TB Is Shown",
											items, @"TB Item Identifiers",
											[NSNumber numberWithInt:_sizeMode], @"TB Size Mode",	// oops what is the difference?
											priorities, @"TB Visibility Priority Values",	// must be NSDictionary!
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
	// FIXME: correctly handle duplicates
	if(item)
			{
				// should compare by itentifier and not by object
				if(![item allowsDuplicatesInToolbar] && [_activeItems containsObject:item])
					return;	// duplicate
				// FIXME: send NSToolbarWillAddItemNotification
				[item _setToolbar:self];
				[_items addObject:item];
				[_activeItems addObject:item];
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
	[_activeItems removeObjectAtIndex:idx];
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
	if(!_activeItems)
		_activeItems=[[NSMutableArray alloc] initWithCapacity:[val count]];
	while((ident=[e nextObject]))
			{ // find item by identifier
				NSToolbarItem *item=[self _itemForIdentifier:ident];
				if(item)
						[_activeItems addObject:item];
			}
	val=[dict objectForKey: @"TB Visibility Priority Values"];
	e=[val keyEnumerator];	// should be NSDictionary...
	while((ident=[e nextObject]))
			{ // load priorities from user defaults
				int prio=[[[val objectForKey:ident] lastObject] intValue];
				[[self _itemForIdentifier:ident] setVisibilityPriority:prio];
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
	// FIXME: for really visible only, i.e. not for overflow menu?
	[_activeItems makeObjectsPerformSelector:@selector(validate)];
}

- (NSArray *) _activeItems; { return _activeItems; }

- (NSArray *) visibleItems;
{ // translate from identifiers
	// FIXME: items in the overflow menu are NOT considered visible!
	// This means the visibleItems method depends on the toobar to be
	// attached to the NSToolbarView and visibleItems is probably a method of the ToolbarView
	// and its current frame
	// or this method asks the NSToolbarView for each one of the _activeItems if it is visible or not
	// call NSIsEmptyRect([_toolbarView rectOfItem:idx]) to check visibility
	return _activeItems;
}

@end

@interface _NSToolbarSeparatorItemView : NSView
@end

@implementation _NSToolbarSeparatorItemView

- (BOOL) isOpaque; { return NO; }
- (void) mouseDown:(NSEvent *) event { return; }	// ignore
- (void) mouseDragged:(NSEvent *) event { return; }	// ignore
- (void) mouseUp:(NSEvent *) event { return; }	// ignore

- (void) drawRect:(NSRect) rect
{ // draw a separator line as high as we need
	// should be a dotted vertical line
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMidX(_bounds), NSMinY(_bounds)+1.0) toPoint:NSMakePoint(NSMidX(_bounds), NSMaxY(_bounds)-1.0)];
}

@end

@implementation NSToolbarItem

- (SEL) action; { return _action; }
- (BOOL) allowsDuplicatesInToolbar; { return _allowsDuplicatesInToolbar; } 
- (BOOL) autovalidates; { return _autovalidates; }
- (NSImage *) image; { return [_view respondToSelector:_cmd]?[_view image]:_image; }

- (id) initWithItemIdentifier:(NSString *) itemId; 
{
	if((self=[super init]))
			{
				NSBundle *appKitBundle=[NSBundle bundleForClass:[self class]];
				NSDictionary *builtinItems=[appKitBundle objectForInfoDictionaryKey:@"NSBuiltinToolbarItems"];
				NSDictionary *dict=[builtinItems objectForKey:itemId];
				_itemIdentifier=[itemId retain];
				if(dict)
						{ // initialize icon, label, action etc.
							id val;
#if 0
							NSLog(@"init item %@ with %@", itemId, dict);
#endif
							_builtin=YES;
							_label=[[dict objectForKey:@"Label"] retain];
							_paletteLabel=[[dict objectForKey:@"PaletteLabel"] retain];
							_toolTip=[[dict objectForKey:@"ToolTip"] retain];
							_allowsDuplicatesInToolbar=[[dict objectForKey:@"AllowsDuplicates"] boolValue];
							_canKeepVisible=![[dict objectForKey:@"CantKeepVisible"] boolValue];
							if([val=[dict objectForKey:@"MinSize"] length] > 0)
								_minSize=NSSizeFromString(val);
							if([val=[dict objectForKey:@"MaxSize"] length] > 0)
								_maxSize=NSSizeFromString(val);
							if([val=[dict objectForKey:@"Action"] length] > 0)
								_action=NSSelectorFromString(val);	// _target is nil, i.e. firstResponder
							if([val=[dict objectForKey:@"Icon"] length] > 0)
								_image=[NSImage imageNamed:val];
							if([val=[dict objectForKey:@"ViewClass"] length] > 0)
								_view=[[NSClassFromString(val) alloc] initWithFrame:NSZeroRect];
							// should allow to initialize targets
							if([_itemIdentifier isEqualToString:NSToolbarShowFontsItemIdentifier])
								_target=[NSFontManager sharedFontManager];	// is not member of the responder chain (or should it be?)
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
- (void) setAction:(SEL) sel; { if(!_builtin) _action=sel; }	// should we forward to the _view?
- (void) setAutovalidates:(BOOL) flag; { _autovalidates=flag; }
- (void) setEnabled:(BOOL) flag; { _isEnabled=flag; }	// should we forward to the _view?
- (void) setImage:(NSImage *) img; { if(!_builtin) { if([_view respondToSelector:_cmd]) [_view setImage:img]; else ASSIGN(_image, img); } }
- (void) setLabel:(NSString *) str; { if(!_builtin) ASSIGN(_label, str); }	// should we forward to the _view?
- (void) setMaxSize:(NSSize) size; { if(!_builtin) _maxSize=size; }
- (void) setMenuFormRepresentation:(NSMenuItem *) item; { NIMP; }
- (void) setMinSize:(NSSize) size; { if(!_builtin) _minSize=size; }
- (void) setPaletteLabel:(NSString *) label; { if(!_builtin) ASSIGN(_paletteLabel, label); }
- (void) setTag:(NSInteger) tag; { _tag=tag; }	// should we forward to the _view?
- (void) setTarget:(id) target; { if(!_builtin) _target=target; }	// should we forward to the _view?
- (void) _setToolbar:(NSToolbar *) view; { _toolbar=view; }
- (void) setToolTip:(NSString *) toolTip; { ASSIGN(_toolTip, toolTip); }	// should we forward to the _view?
- (void) setView:(NSView *) view; { if(!_builtin) ASSIGN(_view, view); }
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
