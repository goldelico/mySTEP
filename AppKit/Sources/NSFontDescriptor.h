/*
 
  NSFontDescriptor.h
  mySTEP

  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
  Copyright (c) 2005 DSITRI.

  Author:	Fabian Spillner <fabian.spillner@gmail.com>
  Date:		8. November 2007 - aligned with 10.5 
 
  This file is part of the mySTEP Library and is provided
  under the terms of the GNU Library General Public License.

 
*/

#ifndef _mySTEP_H_NSFontDescriptor
#define _mySTEP_H_NSFontDescriptor

#import "AppKit/NSController.h"

@class NSString;
@class NSCoder;

typedef uint32_t NSFontSymbolicTraits;

typedef enum _NSFontFamilyClass
{
	NSFontUnknownClass = 0 << 28,
	NSFontOldStyleSerifsClass = 1 << 28,
	NSFontTransitionalSerifsClass = 2 << 28,
	NSFontModernSerifsClass = 3 << 28,
	NSFontClarendonSerifsClass = 4 << 28,
	NSFontSlabSerifsClass = 5 << 28,
	NSFontFreeformSerifsClass = 7 << 28,
	NSFontSansSerifClass = 8 << 28,
	NSFontOrnamentalsClass = 9 << 28,
	NSFontScriptsClass = 10 << 28,
	NSFontSymbolicClass = 12 << 28
} NSFontFamilyClass;

enum _NSFontTrait
{
	NSFontItalicTrait = 0x0001,
	NSFontBoldTrait = 0x0002,
	NSFontExpandedTrait = 0x0020,
	NSFontCondensedTrait = 0x0040,
	NSFontMonoSpaceTrait = 0x0400,
	NSFontVerticalTrait = 0x0800,
	NSFontUIOptimizedTrait = 0x1000
};

extern NSString *NSFontFamilyAttribute;
extern NSString *NSFontNameAttribute;
extern NSString *NSFontFaceAttribute;
extern NSString *NSFontSizeAttribute; 
extern NSString *NSFontVisibleNameAttribute; 
extern NSString *NSFontColorAttribute; // deprecated
extern NSString *NSFontMatrixAttribute;
extern NSString *NSFontVariationAttribute;
extern NSString *NSFontCharacterSetAttribute;
extern NSString *NSFontCascadeListAttribute;
extern NSString *NSFontTraitsAttribute;
extern NSString *NSFontFixedAdvanceAttribute;
extern NSString *NSFontFeatureSettingsAttribute; 

extern NSString *NSFontSymbolicTrait;
extern NSString *NSFontWeightTrait;
extern NSString *NSFontWidthTrait;
extern NSString *NSFontSlantTrait;

extern NSString *NSFontVariationAxisIdentifierKey;
extern NSString *NSFontVariationAxisMinimumValueKey;
extern NSString *NSFontVariationAxisMaximumValueKey;
extern NSString *NSFontVariationAxisDefaultValueKey;
extern NSString *NSFontVariationAxisNameKey;

extern NSString *NSFontFeatureTypeIdentifierKey;
extern NSString *NSFontFeatureSelectorIdentifierKey;

@interface NSFontDescriptor : NSObject <NSCoding>
{
	NSDictionary *_attributes;
}

+ (id) fontDescriptorWithFontAttributes:(NSDictionary *) attributes;
+ (id) fontDescriptorWithName:(NSString *) postscript matrix:(NSAffineTransform *) matrix;
+ (id) fontDescriptorWithName:(NSString *) postscript size:(CGFloat) size;

- (NSDictionary *) fontAttributes;
- (NSFontDescriptor *) fontDescriptorByAddingAttributes:(NSDictionary *) attributes;
- (NSFontDescriptor *) fontDescriptorWithFace:(NSString *) face;
- (NSFontDescriptor *) fontDescriptorWithFamily:(NSString *) family;
- (NSFontDescriptor *) fontDescriptorWithMatrix:(NSAffineTransform *) matrix;
- (NSFontDescriptor *) fontDescriptorWithSize:(CGFloat) size;
- (NSFontDescriptor *) fontDescriptorWithSymbolicTraits:(NSFontSymbolicTraits) traits;
- (id) initWithFontAttributes:(NSDictionary *) attributes;
- (NSArray *) matchingFontDescriptorsWithMandatoryKeys:(NSSet *) keys;
- (NSFontDescriptor *) matchingFontDescriptorWithMandatoryKeys:(NSSet *) keys;
- (NSAffineTransform *) matrix;
- (id) objectForKey:(NSString *) attribute;
- (CGFloat) pointSize;
- (NSString *) postscriptName;
- (NSFontSymbolicTraits) symbolicTraits;

@end

#endif /* _mySTEP_H_NSFontDescriptor */
