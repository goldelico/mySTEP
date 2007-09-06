/* 
   NSFontManager.h

   Manages system and user fonts

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date:	1996
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Oct 2006 - aligned with 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSFontManager
#define _mySTEP_H_NSFontManager

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

@interface NSFontManager : NSObject
{
	id _delegate;
	SEL _action;
	NSFont *_selectedFont;
	NSDictionary *_selectedAttributes;
  NSMenu *_fontMenu;
  NSFontTraitMask _trait;
	NSMutableDictionary *_localCollections;
  int _storedTag;
  BOOL _multiple;

	NSDictionary *_collections;	// each one contains an array of font descriptors
	NSArray *fontsList;
}

+ (void) setFontManagerFactory:(Class)classId;
+ (void) setFontPanelFactory:(Class)classId;
+ (NSFontManager *) sharedFontManager;

- (SEL) action;
- (BOOL) addCollection:(NSString *) name options:(int) options;
- (void) addFontDescriptors:(NSArray *) descriptors toCollection:(NSString *) collection;
- (void) addFontTrait:(id) sender;
- (NSArray *) availableFontFamilies;
- (NSArray *) availableFontNamesMatchingFontDescriptor:(NSFontDescriptor *) descriptor;
- (NSArray *) availableFontNamesWithTraits:(NSFontTraitMask) mask;
- (NSArray *) availableFonts;
- (NSArray *) availableMembersOfFontFamily:(NSString *) family;
- (NSArray *) collectionNames;
- (NSDictionary *) convertAttributes:(NSDictionary *) attributes;
- (NSFont *) convertFont:(NSFont *)fontObject;		// Convert Fonts
- (NSFont *) convertFont:(NSFont *)fontObject toFace:(NSString *)typeface;
- (NSFont *) convertFont:(NSFont *)fontObject toFamily:(NSString *)family;
- (NSFont *) convertFont:(NSFont *)fontObject
			 toHaveTrait:(NSFontTraitMask)trait;
- (NSFont *) convertFont:(NSFont *)fontObject
			 toNotHaveTrait:(NSFontTraitMask)trait;
- (NSFont *) convertFont:(NSFont *)fontObject toSize:(float)size;
- (NSFont *) convertWeight:(BOOL)upFlag ofFont:(NSFont *)fontObject;
- (id) delegate;
- (NSArray *) fontDescriptorsInCollection:(NSString *) collection;
- (NSMenu *) fontMenu:(BOOL)create;
- (BOOL) fontNamed:(NSString *) typeface hasTraits:(NSFontTraitMask) mask;
- (NSFontPanel *) fontPanel:(BOOL)create;
- (NSFont *) fontWithFamily:(NSString *)family
					 traits:(NSFontTraitMask)traits
					 weight:(int)weight
					 size:(float)size;
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
- (void) setAction:(SEL)aSelector;
- (void) setDelegate:(id)anObject;
- (void) setEnabled:(BOOL)flag;
- (void) setFontMenu:(NSMenu *)newMenu;
- (void) setSelectedAttributes:(NSDictionary *) attributes isMultiple:(BOOL) flag;
- (void) setSelectedFont:(NSFont *)fontObject isMultiple:(BOOL)flag;
- (NSFontTraitMask) traitsOfFont:(NSFont *)fontObject;
- (int) weightOfFont:(NSFont *)fontObject;

@end

@interface NSObject (NSFontManagerDelegate)

- (void) changeFont:(id) sender;
- (BOOL) fontManager:(id) sender willIncludeFont:(NSString *) fontName;	// not called (deprecated)

@end

#endif /* _mySTEP_H_NSFontManager */
