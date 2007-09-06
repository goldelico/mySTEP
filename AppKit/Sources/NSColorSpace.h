//
//  NSColorSpace.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSColorSpace
#define _mySTEP_H_NSColorSpace

#import <Foundation/Foundation.h>

typedef enum _NSColorSpaceModel
{
	NSUnknownColorSpaceModel,
	NSGrayColorSpaceModel,
	NSRGBColorSpaceModel,
	NSCMYKColorSpaceModel,
	NSLABColorSpaceModel,
	NSDeviceNColorSpaceModel
} NSColorSpaceModel;

@interface NSColorSpace : NSObject <NSCoding>
{
	NSColorSpaceModel colorSpaceModel;
}

+ (NSColorSpace *) deviceCMYKColorSpace;
+ (NSColorSpace *) deviceGrayColorSpace;
+ (NSColorSpace *) deviceRGBColorSpace;
+ (NSColorSpace *) genericCMYKColorSpace;
+ (NSColorSpace *) genericGrayColorSpace;
+ (NSColorSpace *) genericRGBColorSpace;

- (NSColorSpaceModel) colorSpaceModel;
- (void *) colorSyncProfile;
- (NSData *) ICCProfileData;
- (id) initWithColorSyncProfile:(void *) prof;
- (id) initWithICCProfileData:(NSData *) iccData;
- (NSString *) localizedName;
- (int) numberOfColorComponents;

@end

#endif /* _mySTEP_H_NSObjectController */
