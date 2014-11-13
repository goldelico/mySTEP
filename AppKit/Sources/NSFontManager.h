/* 
   NSFontManager.h

   Manages system and user fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:	1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Oct 2006 - aligned with 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSFontManager
#define _mySTEP_H_NSFontManager

#import <Foundation/NSGeometry.h>
#import <Foundation/NSObject.h>

@class NSString;
@class NSArray;
@class NSMutableDictionary;

@class NSFont;
@class NSMenu;
@class NSFontPanel;
@class NSFontDescriptor;

enum _NSFontManagerAddCollectionOptions
{
	NSFontCollectionApplicationOnlyMask = 1 << 0
};

typedef unsigned int NSFontTraitMask;

enum _NSFontTraits
{
	NSItalicFontMask = 1,
	NSBoldFontMask = 2,
	NSUnboldFontMask = 4,
	NSNonStandardCharacterSetFontMask = 8,
	NSNarrowFontMask = 16,
	NSExpandedFontMask = 32,
	NSCondensedFontMask = 64,
	NSSmallCapsFontMask = 128,
	NSPosterFontMask = 256,
	NSCompressedFontMask = 512,
	NSFixedPitchFontMask = 1024,
	NSUnitalicFontMask = 1<<24
};

typedef enum _NSFontAction 
{
	NSNoFontChangeAction = 0,
	NSViaPanelFontAction = 1,
	NSAddTraitFontAction = 2,
	NSSizeUpFontAction = 3,
	NSSizeDownFontAction = 4,
	NSHeavierFontAction = 5,
	NSLighterFontAction = 6,
	NSRemoveTraitFontAction = 7
} NSFontAction;

@interface NSFontManager : NSObject
{
	id _delegate;
	id _target;
	SEL _action;
	NSFont *_selectedFont;
	NSDictionary *_selectedAttributes;
	NSMenu *_fontMenu;
	NSMutableDictionary *_localCollections;
	NSFontTraitMask _trait;
	NSDictionary *_collections;	// each one contains an array of font descriptors
	NSArray *fontsList;
	NSFontAction _storedTag;
	BOOL _multiple;
}

+ (void) setFontManagerFactory:(Class) classId;
+ (void) setFontPanelFactory:(Class) classId;
+ (NSFontManager *) sharedFontManager;

- (SEL) action;
- (BOOL) addCollection:(NSString *) name options:(NSInteger) options;
- (void) addFontDescriptors:(NSArray *) descriptors toCollection:(NSString *) collection;
- (void) addFontTrait:(id) sender;
- (NSArray *) availableFontFamilies;
- (NSArray *) availableFontNamesMatchingFontDescriptor:(NSFontDescriptor *) descriptor;
- (NSArray *) availableFontNamesWithTraits:(NSFontTraitMask) mask;
- (NSArray *) availableFonts;
- (NSArray *) availableMembersOfFontFamily:(NSString *) family;
- (NSArray *) collectionNames;
- (NSDictionary *) convertAttributes:(NSDictionary *) attributes;
- (NSFont *) convertFont:(NSFont *) fontObject;		// Convert Fonts
- (NSFont *) convertFont:(NSFont *) fontObject toFace:(NSString *) typeface;
- (NSFont *) convertFont:(NSFont *) fontObject toFamily:(NSString *) family;
- (NSFont *) convertFont:(NSFont *) fontObject toHaveTrait:(NSFontTraitMask) trait;
- (NSFont *) convertFont:(NSFont *) fontObject toNotHaveTrait:(NSFontTraitMask) trait;
- (NSFont *) convertFont:(NSFont *) fontObject toSize:(CGFloat) size;
- (NSFontTraitMask) convertFontTraits:(NSFontTraitMask) fontTraits;
- (NSFont *) convertWeight:(BOOL) upFlag ofFont:(NSFont *) fontObject;
- (NSFontAction) currentFontAction;
- (id) delegate;
- (NSArray *) fontDescriptorsInCollection:(NSString *) collection;
- (NSMenu *) fontMenu:(BOOL) create;
- (BOOL) fontNamed:(NSString *) typeface hasTraits:(NSFontTraitMask) mask;
- (NSFontPanel *) fontPanel:(BOOL) create;
- (NSFont *) fontWithFamily:(NSString *) family
					 traits:(NSFontTraitMask) traits
					 weight:(NSInteger) weight
					   size:(CGFloat) size;
- (BOOL) isEnabled;
- (BOOL) isMultiple;
- (NSString *) localizedNameForFamily:(NSString *) family face:(NSString *) face;
- (void) modifyFont:(id) sender;
- (void) modifyFontViaPanel:(id) sender;
- (void) orderFrontFontPanel:(id) sender;
- (void) orderFrontStylesPanel:(id) sender;
- (BOOL) removeCollection:(NSString *) collection;
- (void) removeFontDescriptor:(NSFontDescriptor *) descriptor fromCollection:(NSString *) collection;
- (void) removeFontTrait:(id) sender;
- (NSFont *) selectedFont;
- (BOOL) sendAction;
- (void) setAction:(SEL) aSelector;
- (void) setDelegate:(id) anObject;
- (void) setEnabled:(BOOL) flag;
- (void) setFontMenu:(NSMenu *) newMenu;
- (void) setSelectedAttributes:(NSDictionary *) attributes isMultiple:(BOOL) flag;
- (void) setSelectedFont:(NSFont *) fontObject isMultiple:(BOOL) flag;
- (void) setTarget:(id) target;
- (id) target;
- (NSFontTraitMask) traitsOfFont:(NSFont *) fontObject;
- (int) weightOfFont:(NSFont *) fontObject;

@end

@interface NSObject (NSFontManagerDelegate)

- (void) changeFont:(id) sender;
- (BOOL) fontManager:(id) sender willIncludeFont:(NSString *) fontName;	// not called (deprecated)

@end

#endif /* _mySTEP_H_NSFontManager */
