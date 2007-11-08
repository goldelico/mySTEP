/*
	NSColorSpace.h
    mySTEP
  
    Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
    Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner
    Date:	22. October 2007  
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	6. November 2007 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSColorSpace
#define _mySTEP_H_NSColorSpace

#import <Foundation/Foundation.h>

typedef NSInteger NSColorSpaceModel;
typedef struct CGColorSpace *CGColorSpaceRef; // should be definied in CGColorspace.h

enum
{
	NSUnknownColorSpaceModel = -1,
	NSGrayColorSpaceModel,
	NSRGBColorSpaceModel,
	NSCMYKColorSpaceModel,
	NSLABColorSpaceModel,
	NSDeviceNColorSpaceModel,
	NSIndexedColorSpaceModel,
	NSPatternColorSpaceModel
};

@interface NSColorSpace : NSObject <NSCoding>
{
	NSColorSpaceModel colorSpaceModel;
}

+ (NSColorSpace *) adobeRGB1998ColorSpace;
+ (NSColorSpace *) deviceCMYKColorSpace;
+ (NSColorSpace *) deviceGrayColorSpace;
+ (NSColorSpace *) deviceRGBColorSpace;
+ (NSColorSpace *) genericCMYKColorSpace;
+ (NSColorSpace *) genericGrayColorSpace;
+ (NSColorSpace *) genericRGBColorSpace;
+ (NSColorSpace *) sRGBColorSpace;

- (CGColorSpaceRef) CGColorSpace;
- (NSColorSpaceModel) colorSpaceModel;
- (void *) colorSyncProfile;
- (NSData *) ICCProfileData;
- (id) initWithCGColorSpace:(CGColorSpaceRef) colorSpace;
- (id) initWithColorSyncProfile:(void *) prof;
- (id) initWithICCProfileData:(NSData *) iccData;
- (NSString *) localizedName;
- (NSInteger) numberOfColorComponents;

@end

#endif /* _mySTEP_H_NSObjectController */
