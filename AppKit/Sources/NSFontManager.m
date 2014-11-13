/* 
NSFontManager.m
 
 Manages system and user fonts
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:  Scott Christley <scottc@net-community.com>
 Date:	1996
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSException.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSString.h>
#import <Foundation/NSSet.h>

#import <AppKit/AppKit.h>
#import "NSAppKitPrivate.h"

//
// Class variables
//

static NSFontPanel *__fontPanel = nil;
static NSFontManager *__sharedFontManager = nil;
static Class __fontPanelClass = Nil;
static Class __fontManagerClass = Nil;
static NSString *__fontCollections = nil;

#define FONT_COLLECTION(name) [[__fontCollections stringByAppendingPathComponent:(name)] stringByAppendingPathExtension:@"collection"]

@implementation NSFontManager

+ (void) initialize
{
	if (self == [NSFontManager class])
		{
		NSDebugLog(@"Initialize NSFontManager class\n");
		__fontManagerClass = self;
		__fontPanelClass = [NSFontPanel class];
		__fontCollections = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library/FontCollections"] retain];
		}
}

+ (void) setFontManagerFactory:(Class)class		{ __fontManagerClass = class; }
+ (void) setFontPanelFactory:(Class)class		{ __fontPanelClass = class; }

+ (NSFontManager *) sharedFontManager
{
	if (!__sharedFontManager)
		__sharedFontManager = [__fontManagerClass new];
	return __sharedFontManager;
}

- (id) init
{
	if((self = [super init]))
		{
		_action = @selector(changeFont:);
		_storedTag = NSNoFontChangeAction;
		}
	return self;
}

- (void) dealloc;
{
	[_fontMenu release];
	[_selectedFont release];
	[super dealloc];
}

//
// Converting Fonts
// FIXME: use NSFontDescriptor
//

- (NSDictionary *) convertAttributes:(NSDictionary *) attributes;
{
	NSMutableDictionary *r;
	NSFont *f=[attributes objectForKey:NSFontAttributeName];
	if(!f)
		return attributes;	// no font specified
	f=[self convertFont:f];
	if(!f)
		return attributes;	// can't convert
	r=[attributes mutableCopy];
	[r setObject:f forKey:NSFontAttributeName];	// change
	return [r autorelease];
}

- (NSFont*) convertFont: (NSFont*)fontObject
{
	NSFont *newFont = fontObject;
	unsigned int i;
	float size;
	float sizes[] = { 4.0, 6.0, 8.0, 9.0, 10.0, 11.0, 12.0, 13.0, 14.0, 16.0, 18.0, 24.0, 36.0, 48.0, 64.0 };
	if (!fontObject)
		return nil;
	switch (_storedTag)
		{
		case NSNoFontChangeAction: 
			break;
		case NSViaPanelFontAction: 
			if (__fontPanel)
				newFont = [__fontPanel panelConvertFont: fontObject];
			break;
		case NSAddTraitFontAction: 
			newFont = [self convertFont: fontObject toHaveTrait: _trait];
			break;
		case NSRemoveTraitFontAction: 
			newFont = [self convertFont: fontObject toNotHaveTrait: _trait];
			break;
		case NSSizeUpFontAction: 
			size = [fontObject pointSize];
			for (i = 0; i < sizeof(sizes)/sizeof(float); i++)
				{
				if (sizes[i] > size)
					{
					size = sizes[i];
					break;
					}
				}
				newFont = [self convertFont: fontObject toSize: size];
			break;
		case NSSizeDownFontAction: 
			size = [fontObject pointSize];
			for (i = sizeof(sizes)/sizeof(float); i > 0; i--)
				{
				if (sizes[i-1] < size)
					{
					size = sizes[i-1];
					break;
					}
				}
				newFont = [self convertFont: fontObject toSize: size];
			break;
		case NSHeavierFontAction: 
			newFont = [self convertWeight: YES ofFont: fontObject]; 
			break;
		case NSLighterFontAction: 
			newFont = [self convertWeight: NO ofFont: fontObject]; 
			break;
		}	
	return newFont;
}

- (NSFont*) convertFont: (NSFont *)fontObject toFamily: (NSString *)family
{
	if ([family isEqualToString: [fontObject familyName]])
		return fontObject; // If already of that family then just return it
	else
		{ // Else convert it
		NSFont *newFont;
		NSFontTraitMask trait = [self traitsOfFont: fontObject];
		int weight = [self weightOfFont: fontObject];
		float size = [fontObject pointSize];
		
		newFont = [self fontWithFamily: family traits: trait weight: weight size: size];
		if (newFont == nil)
			return fontObject;	// can't convert
		else 
			return newFont;
		}
}

- (NSFont*) convertFont: (NSFont*)fontObject toFace: (NSString*)typeface
{
	NSFont *newFont;
	// This conversion just retains the point size
	if ([[fontObject fontName] isEqualToString: typeface])
		return fontObject;
	newFont = [NSFont fontWithName: typeface size: [fontObject pointSize]];
	if (newFont == nil)
		return fontObject;
	else 
		return newFont;
}

- (NSFont*) convertFont: (NSFont*)fontObject toHaveTrait: (NSFontTraitMask)trait
{
	NSFontTraitMask t = [self traitsOfFont: fontObject];
	if (t & trait)
		return fontObject;	// If we already have that trait then just return it
	if (trait == NSUnboldFontMask)
		return [self convertFont: fontObject toNotHaveTrait: NSBoldFontMask];
	if (trait == NSUnitalicFontMask)
		return [self convertFont: fontObject toNotHaveTrait: NSItalicFontMask];
	else
		{ // Else convert it
		NSFont *newFont;
		int weight = [self weightOfFont: fontObject];
		float size = [fontObject pointSize];
		NSString *family = [fontObject familyName];
		// We cannot reuse the weight in a bold
		if (trait == NSBoldFontMask)
			weight = 9;
		t = t | trait;
		newFont = [self fontWithFamily: family traits: t weight: weight size: size];
		if (!newFont)
			return fontObject;
		else 
			return newFont;
		}
}

- (NSFont*) convertFont: (NSFont*)fontObject toNotHaveTrait: (NSFontTraitMask)trait
{
	NSFontTraitMask t = [self traitsOfFont: fontObject];
	// This is a bit strange but is stated in the specification
	if (trait & NSUnboldFontMask)
		trait = (trait | NSBoldFontMask) & ~NSUnboldFontMask;
	if (trait & NSUnitalicFontMask)
		trait = (trait | NSItalicFontMask) & ~NSUnitalicFontMask;
	if (!(t & trait))
		{
		// If already do not have that trait then just return it
		return fontObject;
		}
	else
		{
		// Else convert it
		NSFont *newFont;		
		int weight = [self weightOfFont: fontObject];
		float size = [fontObject pointSize];
		NSString *family = [fontObject familyName];
		// We cannot reuse the weight in an unbold
		if (trait & NSBoldFontMask)
			weight = 5;
		t &= ~trait;
		newFont = [self fontWithFamily: family traits: t weight: weight size: size];
		if (!newFont)
			return fontObject;
		else 
			return newFont;
		}
}

- (NSFont*) convertFont: (NSFont*)fontObject toSize: (CGFloat)size
{
	if ([fontObject pointSize] == size)
		{
		// If already that size then just return it
		return fontObject;
		}
	else
		{
		// Else convert it
		NSFont *newFont;		
		newFont = [NSFont fontWithName: [fontObject fontName] size: size];
		if (!newFont)
			return fontObject;
		else 
			return newFont;
		}
}

- (NSFont*) convertWeight: (BOOL)upFlag ofFont: (NSFont*)fontObject
{
	NSFont *newFont = nil;
	NSString *fontName = nil;
	NSFontTraitMask trait = [self traitsOfFont: fontObject];
	float size = [fontObject pointSize];
	NSString *family = [fontObject familyName];
	int w = [self weightOfFont: fontObject];
	// We check what weights we have for this family. We must
	// also check to see if that font has the correct traits!
	NSArray *fontDefs = [self availableMembersOfFontFamily: family];	
	if (upFlag)
		{
		unsigned int i;
		// The documentation is a bit unclear about the range of weights
		// sometimes it says 0 to 9 and sometimes 0 to 15
		int next_w = 15;		
		for (i = 0; i < [fontDefs count]; i++)
			{
			NSArray *fontDef = [fontDefs objectAtIndex: i];
			int w1 = [[fontDef objectAtIndex: 2] intValue];
			if (w1 > w && w1 < next_w && 
				[[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
				{
				next_w = w1;
				fontName = [fontDef objectAtIndex: 0];
				}
			}
		if (!fontName)
			{
			// Not found, try again with changed trait
			trait |= NSBoldFontMask;			
			for (i = 0; i < [fontDefs count]; i++)
				{ 
				NSArray *fontDef = [fontDefs objectAtIndex: i];
				int w1 = [[fontDef objectAtIndex: 2] intValue];
				if (w1 > w && w1 < next_w && 
					[[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
					{
					next_w = w1;
					fontName = [fontDef objectAtIndex: 0];
					}
				}
			}
		}
	else
		{
		unsigned int i;
		int next_w = 0;
		for (i = 0; i < [fontDefs count]; i++)
			{
			NSArray *fontDef = [fontDefs objectAtIndex: i];
			int w1 = [[fontDef objectAtIndex: 2] intValue];
			if (w1 < w && w1 > next_w
				&& [[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
				{
				next_w = w1;
				fontName = [fontDef objectAtIndex: 0];
				}
			}
		if (fontName == nil)
			{
			// Not found, try again with changed trait
			trait &= ~NSBoldFontMask;
			for (i = 0; i < [fontDefs count]; i++)
				{
				NSArray *fontDef = [fontDefs objectAtIndex: i];
				int w1 = [[fontDef objectAtIndex: 2] intValue];
				if (w1 < w && w1 > next_w
					&& [[fontDef objectAtIndex: 3] unsignedIntValue] == trait)
					{
					next_w = w1;
					fontName = [fontDef objectAtIndex: 0];
					}
				}
			}
		}
	if (fontName)
		newFont = [NSFont fontWithName: fontName size: size];
	if (!newFont)
		return fontObject;
	else 
		return newFont;
}

- (NSFontAction) currentFontAction;
{
	return _storedTag;
}

- (NSFontTraitMask) convertFontTraits:(NSFontTraitMask) fontTraits;
{
	NIMP;
	return fontTraits;
}

// FIXME: can we use NSFontDescriptor to find matchingDescriptors?

- (NSFont *) fontWithFamily:(NSString *)family
					 traits:(NSFontTraitMask)traits
					 weight:(int)weight
					   size:(CGFloat)size
{
	NSArray *fontDefs = [self availableMembersOfFontFamily: family];
	unsigned int i;	
	//NSLog(@"Searching font %@: %i: %i size %.0f", family, weight, traits, size);
	// First do an exact match search
	for (i = 0; i < [fontDefs count]; i++)
		{
		NSArray *fontDef = [fontDefs objectAtIndex: i];		
		//NSLog(@"Testing font %@: %i: %i", [fontDef objectAtIndex: 0], 
		//          [[fontDef objectAtIndex: 2] intValue], 
		//          [[fontDef objectAtIndex: 3] unsignedIntValue]);  
		if (([[fontDef objectAtIndex: 2] intValue] == weight) &&
			([[fontDef objectAtIndex: 3] unsignedIntValue] == traits))
			{
			return [NSFont fontWithName: [fontDef objectAtIndex: 0] size: size];
			}
		}
	// Try to find something close
	traits &= ~(NSNonStandardCharacterSetFontMask | NSFixedPitchFontMask);
	if (traits & NSBoldFontMask)
		{
		//NSLog(@"Trying ignore weights for bold font");
		for (i = 0; i < [fontDefs count]; i++)
			{
			NSArray *fontDef = [fontDefs objectAtIndex: i];
			NSFontTraitMask t = [[fontDef objectAtIndex: 3] unsignedIntValue];			
			t &= ~(NSNonStandardCharacterSetFontMask | NSFixedPitchFontMask);
			if (t == traits)
				{
				//NSLog(@"Found font");
				return [NSFont fontWithName: [fontDef objectAtIndex: 0] size: size];
				}
			}
		}  
	if (weight == 5 || weight == 6)
		{
		//NSLog(@"Trying alternate non-bold weights for non-bold font");
		for (i = 0; i < [fontDefs count]; i++)
			{
			NSArray *fontDef = [fontDefs objectAtIndex: i];
			NSFontTraitMask t = [[fontDef objectAtIndex: 3] unsignedIntValue];			
			t &= ~(NSNonStandardCharacterSetFontMask | NSFixedPitchFontMask);
			if ((([[fontDef objectAtIndex: 2] intValue] == 5) ||
				 ([[fontDef objectAtIndex: 2] intValue] == 6)) &&
				(t == traits))
				{
				//NSLog(@"Found font");
				return [NSFont fontWithName: [fontDef objectAtIndex: 0] size: size];
				}
			}
		}
	NSLog(@"Invalid font request: fontWithFamily:%@ traits:%08x weight:%d size:%f", family, traits, weight, size);
	return nil;
}

- (NSFontPanel *) fontPanel:(BOOL) create
{
	if([NSFontPanel sharedFontPanelExists] || create)
		return [NSFontPanel sharedFontPanel];	// exists or create...
	return nil;
}

- (BOOL) isEnabled								{ return [__fontPanel isEnabled]; }
- (BOOL) isMultiple								{ return _multiple; }
- (NSFont *) selectedFont						{ return _selectedFont; }

- (void) setEnabled:(BOOL)flag
{
	int i;
	if (_fontMenu)
		{ // enable all font menu items
		for (i = 0; i < [_fontMenu numberOfItems]; i++)
			[[_fontMenu itemAtIndex: i] setEnabled: flag];
		}
	[__fontPanel setEnabled: flag];
}

- (void) setFontMenu:(NSMenu *)newMenu			{ ASSIGN(_fontMenu, newMenu); }

- (NSMenu *) fontMenu:(BOOL)create
{
	if (create && !_fontMenu)
		{ // create a default font menu (unless we load one from a NIB file)
		NSMenuItem *menuItem;		
		_fontMenu = [NSMenu new];		// As the font menu is stored in a instance variable we dont autorelease it
		[_fontMenu setTitle: @"Font Menu"];
		// First an entry to start the font panel
		menuItem = [_fontMenu addItemWithTitle: @"Show Fonts"
										action: @selector(orderFrontFontPanel:)
								 keyEquivalent: @"T"];
		[menuItem setTarget: self];
		
		// Entry for bold
		menuItem = [_fontMenu addItemWithTitle: @"Bold"
										action: @selector(addFontTrait:)
								 keyEquivalent: nil];
		[menuItem setTag: NSBoldFontMask];
		[menuItem setTarget: self];
		
		// Entry for italic
		menuItem = [_fontMenu addItemWithTitle: @"Italic"
										action: @selector(addFontTrait:)
								 keyEquivalent: nil];
		[menuItem setTag: NSItalicFontMask];
		[menuItem setTarget: self];
		
		// Entry to increase weight
		menuItem = [_fontMenu addItemWithTitle: @"Heavier"
										action: @selector(modifyFont:)
								 keyEquivalent: nil];
		[menuItem setTag: NSHeavierFontAction];
		[menuItem setTarget: self];
		
		// Entry to decrease weight
		menuItem = [_fontMenu addItemWithTitle: @"Lighter"
										action: @selector(modifyFont:)
								 keyEquivalent: nil];
		[menuItem setTag: NSLighterFontAction];
		[menuItem setTarget: self];
		
		// Entry to increase size
		menuItem = [_fontMenu addItemWithTitle: @"Larger"
										action: @selector(modifyFont:)
								 keyEquivalent: nil];
		[menuItem setTag: NSSizeUpFontAction];
		[menuItem setTarget: self];
		
		// Entry to decrease size
		menuItem = [_fontMenu addItemWithTitle: @"Smaller"
										action: @selector(modifyFont:)
								 keyEquivalent: nil];
		[menuItem setTag: NSSizeDownFontAction];
		[menuItem setTarget: self];
		}
	return _fontMenu;
}

- (int) weightOfFont:(NSFont *)fontObject
{
	NSDictionary *attrs=[[fontObject fontDescriptor] fontAttributes];
	id weight=[[attrs objectForKey:NSFontTraitsAttribute] objectForKey:NSFontWeightTrait];
	if(weight)
		return (int)(4.5*[weight floatValue]+5.0);	// map -1.0 .. 1.0 to 0 .. 9
	return 5;
}

- (NSFontTraitMask) traitsOfFont:(NSFont *)fontObject
{
	NSDictionary *attrs=[[fontObject fontDescriptor] fontAttributes];
	return [[[attrs objectForKey:NSFontTraitsAttribute] objectForKey:NSFontSymbolicTrait] unsignedIntValue];
}

// Target / Action

- (void) setAction:(SEL)aSelector				{ _action = aSelector; }
- (SEL) action									{ return _action; }
- (void) setTarget:(id) target;					{ _target = target; }
- (id) target;									{ return _target; }

- (BOOL) sendAction
{
	if (_action)
		return [NSApp sendAction: _action to: nil from: self];
	return NO;
}

- (id) delegate									{ return _delegate; }
- (void) setDelegate:(id)anObject				{ _delegate = anObject; }

- (void) addFontTrait: (id)sender
{
	_storedTag = NSAddTraitFontAction;
	_trait = [sender tag];
	[self sendAction];	
	if (_selectedFont)
		{ // We update our own selected font
		NSFont	*newFont = [self convertFont: _selectedFont];		
		if (newFont != nil)
			[self setSelectedFont: newFont isMultiple: _multiple];
		}
}

- (void) removeFontTrait: (id)sender
{
	_storedTag = NSRemoveTraitFontAction;
	_trait = [sender tag];
	[self sendAction];
	if (_selectedFont)
		{ // We update our own selected font
		NSFont	*newFont = [self convertFont: _selectedFont];		
		if (newFont != nil)
			[self setSelectedFont: newFont isMultiple: _multiple];
		}
}

- (void) modifyFont: (id)sender
{
	_storedTag = [sender tag];
	[self sendAction];
	if (_selectedFont)
		{ // We update our own selected font
		NSFont	*newFont = [self convertFont: _selectedFont];		
		if (newFont != nil)
			[self setSelectedFont: newFont isMultiple: _multiple];
		}
}

- (void) modifyFontViaPanel: (id)sender
{
	_storedTag = NSViaPanelFontAction;
	[self sendAction];
	if (_selectedFont)
		{ // We update our own selected font
		NSFont	*newFont = [self convertFont: _selectedFont];		
		if (newFont != nil)
			[self setSelectedFont: newFont isMultiple: _multiple];
		}
}

- (NSArray *) availableMembersOfFontFamily:(NSString *) family;
{
	static NSMutableDictionary *cache;
	NSMutableArray *r=[cache objectForKey:family];
	if(!r)
		{
		NSFontDescriptor *fd=[NSFontDescriptor fontDescriptorWithFontAttributes:[NSDictionary dictionaryWithObject:family forKey:NSFontFamilyAttribute]];
		NSEnumerator *e=[[fd matchingFontDescriptorsWithMandatoryKeys:[NSSet setWithObject:NSFontFamilyAttribute]] objectEnumerator];
		r=[NSMutableArray arrayWithCapacity:20];
#if 0
		NSLog(@"NSFontManager availableMembersOfFontFamily %@", family);
#endif
		// FIXME: sort 1. narrowest to widest - 2. lightest to boldest - 3. plain to italic).
	
		while((fd=[e nextObject]))
			{ // get unique families from fonts and return in specific format
			NSDictionary *attribs=[fd fontAttributes];
			NSArray *a=[NSArray arrayWithObjects:
				[attribs objectForKey:NSFontNameAttribute],
				[attribs objectForKey:NSFontFaceAttribute],
				[[attribs objectForKey:NSFontTraitsAttribute] objectForKey:NSFontWeightTrait],		// weight
				[[attribs objectForKey:NSFontTraitsAttribute] objectForKey:NSFontSymbolicTrait],	// traits
				nil];
			[r addObject:a];
			}
		if(!cache)
			cache=[[NSMutableDictionary alloc] initWithCapacity:10];
		[cache setObject:r forKey:family];
#if 0
		NSLog(@"=> %@", r);
#endif
		}
	return r;
}

- (NSArray *) availableFontNamesMatchingFontDescriptor:(NSFontDescriptor *) descriptor;
{
	NSArray *mfd=[descriptor matchingFontDescriptorsWithMandatoryKeys:[NSSet setWithArray:[[descriptor fontAttributes] allKeys]]];
	NSEnumerator *e=[mfd objectEnumerator];
	NSMutableArray *r=[[NSMutableArray alloc] initWithCapacity:50];
	NSFontDescriptor *fd;
#if 0
	NSLog(@"NSFontManager availableFontNamesMatchingFontDescriptor: %@ => %@", descriptor, mfd);
#endif
	while((fd=[e nextObject]))
		{ // get unique font names
		NSString *family=[[fd fontAttributes] objectForKey:NSFontFamilyAttribute];
		if(![r containsObject:family])
			[r addObject:family];	// new family
		}
	return [r autorelease];
}

- (NSArray *) availableFonts
{
	static NSArray *cache;
	if(!cache)
		cache=[[self availableFontNamesMatchingFontDescriptor:[NSFontDescriptor fontDescriptorWithFontAttributes:[NSDictionary dictionary]]] retain];	// all
	return cache;
}

- (NSArray *) availableFontFamilies;
{
	static NSMutableArray *r;
	NSFontDescriptor *fd=[NSFontDescriptor fontDescriptorWithFontAttributes:nil];
	NSSet *empty=[[NSSet new] autorelease];	// gcc 2.95.3 confuses -(void) set and +(NSSet *) set
	NSArray *mfd=[fd matchingFontDescriptorsWithMandatoryKeys:empty];
	NSEnumerator *e=[mfd objectEnumerator];
	if(!r)
		{ // first call
		r=[[NSMutableArray alloc] initWithCapacity:50];
		while((fd=[e nextObject]))
			{ // get unique families from fonts
			NSString *family=[[fd fontAttributes] objectForKey:NSFontFamilyAttribute];
			if(![r containsObject:family])
				[r addObject:family];	// new family
			}
#if 0
		NSLog(@"NSFontManager availableFontFamilies => %@", r);
#endif
		}
	return r;
}

- (NSArray *) availableFontNamesWithTraits:(NSFontTraitMask) mask;
{
	unsigned int i, j;
	NSArray *fontFamilies = [self availableFontFamilies];
	NSMutableArray *fontNames = [NSMutableArray array];
	NSFontTraitMask traits;
	for (i = 0; i < [fontFamilies count]; i++)
		{
		NSArray *fontDefs = [self availableMembersOfFontFamily:[fontFamilies objectAtIndex: i]];
		for (j = 0; j < [fontDefs count]; j++)
			{
			NSArray	*fontDef = [fontDefs objectAtIndex: j];
			traits = [[fontDef objectAtIndex: 3] unsignedIntValue];
			// Check if the font has exactly the given mask
			if (traits == mask)
				[fontNames addObject: [fontDef objectAtIndex: 0]];
			}
		}
	return fontNames;
}

- (BOOL) fontNamed: (NSString*)typeface hasTraits: (NSFontTraitMask)fontTraitMask
{
	// TODO: This method is implemented very slow, but I dont 
	// see any use for it, so why change it?
	unsigned int i, j;
	NSArray *fontFamilies = [self availableFontFamilies];
	NSFontTraitMask traits;  
	for (i = 0; i < [fontFamilies count]; i++)
		{
		NSArray *fontDefs = [self availableMembersOfFontFamily:[fontFamilies objectAtIndex: i]];
		for (j = 0; j < [fontDefs count]; j++)
			{
			NSArray *fontDef = [fontDefs objectAtIndex: j];
			if ([[fontDef objectAtIndex: 0] isEqualToString: typeface])
				{
				traits = [[fontDef objectAtIndex: 3] unsignedIntValue];
				// FIXME: This is not exactly the right condition
				if ((traits & fontTraitMask) == fontTraitMask)
					return YES;
				else
					return NO;
				}
			}
		}
	return NO;
}

- (NSString *) localizedNameForFamily:(NSString *) family face:(NSString *) face;
{
	return [NSString stringWithFormat: @"%@-%@", family, face];
}

- (void) orderFrontFontPanel:(id) sender; { [[self fontPanel:YES] orderFront:sender]; }
- (void) orderFrontStylesPanel:(id) sender; { [[self fontPanel:YES] orderFront:sender]; }

- (void) setSelectedAttributes:(NSDictionary *) attributes isMultiple:(BOOL) flag;
{
	[__fontPanel _setPanelAttributes: attributes isMultiple: flag];	// private methods
}

- (void) setSelectedFont:(NSFont *) fontObject isMultiple:(BOOL) flag
{
	if (_selectedFont == fontObject && flag == _multiple)
		return;
	_multiple = flag;
	ASSIGN(_selectedFont, fontObject);
	[__fontPanel setPanelFont: fontObject isMultiple: flag];
	if (_fontMenu)
		{
		NSMenuItem *menuItem;
		NSFontTraitMask trait = [self traitsOfFont: fontObject];
		
		/*
		 * FIXME: We should check if that trait is available
		 * We keep the tag, to mark the item
		 */
		if (trait & NSItalicFontMask)
			{
			menuItem = [_fontMenu itemWithTag: NSItalicFontMask];
			if (menuItem)
				{
				[menuItem setTitle: @"Unitalic"];
				[menuItem setAction: @selector(removeFontTrait:)];
				}
			}
		else
			{
			menuItem = [_fontMenu itemWithTag: NSItalicFontMask];
			if (menuItem)
				{
				[menuItem setTitle: @"Italic"];
				[menuItem setAction: @selector(addFontTrait:)];
				}
			}
		
		if (trait & NSBoldFontMask)
			{
			menuItem = [_fontMenu itemWithTag: NSBoldFontMask];
			if (menuItem)
				{
				[menuItem setTitle: @"Unbold"];
				[menuItem setAction: @selector(removeFontTrait:)];
				}
			}
		else
			{
			menuItem = [_fontMenu itemWithTag: NSBoldFontMask];
			if (menuItem)
				{
				[menuItem setTitle: @"Bold"];
				[menuItem setAction: @selector(addFontTrait:)];
				}
			}		
		// TODO Update the rest of the font menu to reflect this font
		}
}

- (NSArray *) collectionNames;
{
	NSArray *files=[[NSFileManager defaultManager] directoryContentsAtPath:__fontCollections];
	NSEnumerator *e=[files objectEnumerator];
	NSMutableArray *r=[NSMutableArray arrayWithCapacity:[files count]+1];
	NSString *c;
	[r addObject:@"All Fonts"];
	while((c=[e nextObject]))
		{
		if(![c hasSuffix:@".collection"])
			continue;
		// should sort
		// maybe, we should read the file to get a visible string?
		[r addObject:[[c lastPathComponent] stringByDeletingPathExtension]];
		}
	return r;
}

- (NSArray *) fontDescriptorsInCollection:(NSString *) collection;
{
	/* z.B.
	{
		NSFontFaceAttribute = Regular; 
		NSFontFamilyAttribute = Arial; 
		NSFontNameAttribute = ArialMT; 
		NSFontTraitsAttribute = 16777228; 
		NSFontWeightAttribute = 5; 
	}
	*/
	// should we check for "All Fonts"?
	NSArray *a=[_localCollections objectForKey:collection];
	if(a)
		return a;	// found
					// try to load from file
	return [NSArray array];	// unknown
}

- (BOOL) addCollection:(NSString *) name options:(int) options;
{
	if(options & NSFontCollectionApplicationOnlyMask)
		{ // create local collection
		[_localCollections setObject:[NSMutableArray arrayWithCapacity:10] forKey:name];
		return YES;
		}
	else
		{
		// create empty collection file
		// create directory if not available
		}
	return NO;
}

- (BOOL) removeCollection:(NSString *) collection;
{
	if([_localCollections objectForKey:collection])
		{
		[_localCollections removeObjectForKey:collection];
		return YES;
		}
	return [[NSFileManager defaultManager] removeFileAtPath:FONT_COLLECTION(collection) handler:nil]; // else remove file if it exists
}

- (void) addFontDescriptors:(NSArray *) descriptors toCollection:(NSString *) collection;
{
	NSMutableArray *a=[_localCollections objectForKey:collection];
	if(a)
		[a addObjectsFromArray:descriptors];
	else
		{ // load from file
		  // modify
		  // write back
		}
}

- (void) removeFontDescriptor:(NSFontDescriptor *) descriptor fromCollection:(NSString *) collection;
{
	NSMutableArray *a=[_localCollections objectForKey:collection];
	if(a)
		[a removeObject:descriptor];
	else
		{ // load from file
		  // modify
		  // write back
		}
}

@end /* NSFontManager */

//*****************************************************************************
//
// 		NSFontPanel 
//
//*****************************************************************************

// load the NIB file
// the File Owner is NSApplication
// load our header file to IB
// make a NSPanel
// set the Custom Class of the panel to our class
// connect the outlets of our NSPanel (subclass) as required

@implementation NSFontPanel

- (void) awakeFromNib;
{
#if 1
	NSLog(@"NSFontPanel - awake from NIB");
#endif
	__fontPanel=self;
	[__fontPanel setWorksWhenModal:YES];
	[self reloadDefaultFontFamilies];
}

+ (BOOL) sharedFontPanelExists; { return __fontPanel != nil; }

+ (NSFontPanel *) sharedFontPanel
{
	if ((!__fontPanel) && ![NSBundle loadNibNamed:@"FontPanel" owner:NSApp])	// looks for FontPanel in ressources of NSApp's bundle
		[NSException raise: NSInternalInconsistencyException 
								format: @"Unable to open font panel model file."];
	[__fontPanel center];
	return __fontPanel;
}

+ (id) alloc
{ 
	return __fontPanel ? __fontPanel : (__fontPanel = (NSFontPanel *) NSAllocateObject(self, 0, NSDefaultMallocZone())); 
}

- (void) dealloc;
{
	[_families release];
	[_accessoryView release];
	[super dealloc];
}

- (void) _notify;
{
	[[NSApp targetForAction:@selector(changeFont:)] changeFont:self];	// send to the first responder
}

// Hm - there is no methods like -setPanelFont: to setup attributes (text, background, underlining style)?
// Well, there should be a separate StylePanel!

- (void) _notifyAttributes;
{
	[[NSApp targetForAction:@selector(changeAttributes:)] changeFont:self];	// send to the first responder
}

- (void) reloadDefaultFontFamilies;
{
	// FIXME: rebuild menu for systemFontSelector
	[_families release];
	_families=nil;
	[_browser reloadColumn:0];
}

- (NSFont *) panelConvertFont:(NSFont *)fontObject
{
	int font=[_browser selectedRowInColumn:0];
	int face=[_browser selectedRowInColumn:1];
	if(font >= 0 && face >= 0)
		{
		NSFontManager *fm=[NSFontManager sharedFontManager];
		NSArray *attribs=[_fonts objectAtIndex:face];
		NSFont *f=[fm convertFont:fontObject toFamily:[attribs objectAtIndex:0]];
		NSString *size;
		f=[fm convertFont:f toFace:[attribs objectAtIndex:1]];
		// weight
		f=[fm convertFont:f toHaveTrait:[[attribs objectAtIndex:3] intValue]];
		size=[_sizeSelector stringValue];
		if([size length] > 0)
			f=[fm convertFont:f toSize:[size floatValue]];
		if(f)
			return f;
		}
	return fontObject;	// could not convert
}

- (void) _setPanelAttributes:(NSDictionary *) attributes isMultiple:(BOOL) multiple
{ // text color, background color, underline color&style, strikethrough color&style, super/subscript, kerning, etc.
}

- (void) setPanelFont:(NSFont *) fontObject isMultiple:(BOOL) multiple	
{
	unsigned int mask=NSFontPanelStandardModesMask;
	id target=[NSApp targetForAction:@selector(validModesForFontPanel:)];
	if(target)
		mask=[target validModesForFontPanel:self];

	NSLog(@"setPanelFont: %@", fontObject);
	
	if(multiple)
		{
		[self setEnabled:NO];
		[_sizeSelector setStringValue:@"Multiple"];
		// deselect all in browser
		}
	else
		{
		// [browser selectItem:[fontObject familyName] inColumn:0];
		// ditto for font face
		[_sizeSelector setStringValue:[NSString stringWithFormat:@"%f", [fontObject pointSize]]];
		// check if we match a system font and update the popup button
		}
	
	[_sizeSelector setHidden:(mask&NSFontPanelSizeModeMask) == 0];
	[_sizeStepper setHidden:(mask&NSFontPanelSizeModeMask) == 0];
	/* FIXME: hide/unhide other components
		NSFontPanelFaceModeMask
		NSFontPanelCollectionModeMask
		NSFontPanelUnderlineEffectModeMask
		NSFontPanelStrikethroughEffectModeMask
		NSFontPanelTextColorEffectModeMask
		NSFontPanelDocumentColorEffectModeMask
		NSFontPanelShadowEffectModeMask
	*/	
}

- (BOOL) worksWhenModal								{ return YES; }

- (BOOL) isEnabled									{ return [_sizeSelector isEnabled]; }

	// should be made available through a NSSplitView

- (NSView *) accessoryView;							{ return _accessoryView; }
- (void) setAccessoryView:(NSView *)aView			{ ASSIGN(_accessoryView, aView); }

- (void) setEnabled:(BOOL)flag
{
	[_systemFontSelector setEnabled:flag];
	[_sizeSelector setEnabled:flag];
	[_sizeStepper setEnabled:flag];
	[_browser setEnabled:flag];
}

// NSCoding protocol

- (void) encodeWithCoder:(NSCoder *) aCoder
{
	[super encodeWithCoder:aCoder];
}

- (id) initWithCoder:(NSCoder *) aDecoder
{
	self=[super initWithCoder:aDecoder];
	if([aDecoder allowsKeyedCoding])
		return self;
	return self;
}

- (IBAction) _searchFont:(id) sender;
{
#if 1
	NSLog(@"search font");
#endif
	[_families release];
	_families=nil;	// this makes us filter the families
	[_browser reloadColumn:0];
}

- (IBAction) _singleClick:(id) sender;
{
	NSLog(@"single click font");
	// call delegate action
}

- (IBAction) _selectSystemFont:(id) sender;
{
	NSFont *f=nil;
	// get selected system font object
	[self setPanelFont:f isMultiple:NO];
	[self _notify];
}

- (IBAction) _selectSize:(id) sender;
{
	// validate
	[self _notify];
}

- (IBAction) _stepperAction:(id) sender;
{
	// select next size level
	[self _notify];
}

// CHECKME: is this the same as singleClick where we can ask for clickedColumn???

- (BOOL) browser:(NSBrowser *)sender selectRow:(int) row inColumn:(int) column
{
	switch(column)
		{
		case 0:
			[_fonts release];
			_fonts=nil;
			[_browser reloadColumn:1];
			break;
		case 1:
			[self _notify];
			break;
		}
	return YES;
}

- (int) browser:(NSBrowser *) sender numberOfRowsInColumn:(int) column
{
	int selected=[sender selectedRowInColumn:0];
	if(!_families)
		{ // load families
		_families=[[NSFontManager sharedFontManager] availableFontFamilies];
		// filter by [searchField stringValue]
		_families=[_families sortedArrayUsingSelector:@selector(compare:)];
		[_families retain];
#if 1
		NSLog(@"families = %@", _families);
#endif
		}
	if(!_fonts && selected >= 0)
		{
		_fonts=[[NSFontManager sharedFontManager] availableMembersOfFontFamily:[_families objectAtIndex:selected]];
		[_fonts retain];
#if 1
		NSLog(@"faces = %@", _fonts);
#endif
		}
	switch(column)
		{
		case 0:
			return [_families count];
		case 1:
			return [_fonts count];	// faces of selected family
		}
	return 0;
}

- (void) browser:(NSBrowser *)sender willDisplayCell:(id) cell atRow:(int) row column:(int) column
{
	switch(column)
		{
		// we could have a third level (ususally invisible) to select font collection
		case 0:
			{
			[cell setStringValue:[_families objectAtIndex:row]];
			[cell setLeaf:NO];
			return;
			}
		case 1:
			{
			NSString *face=[[_fonts objectAtIndex:row] objectAtIndex:1];	// NSFontFaceAttribute
			if([face length] == 0)
				face=@"Regular";
			[cell setStringValue:face];
			[cell setLeaf:YES];
			return;
			}
		}
}

@end /* NSFontPanel */
