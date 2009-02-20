//
//  NSColorSpace.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSColorSpace.h>
#import "NSAppKitPrivate.h"

@implementation NSColorSpace

#define COLORSPACE(model) \
	static NSColorSpace *csp; \
	if(!csp) \
		csp=[[self alloc] _initWithColorSpaceModel:model]; \
	return csp;

+ (NSColorSpace *) deviceCMYKColorSpace; { COLORSPACE(NSCMYKColorSpaceModel); }
+ (NSColorSpace *) deviceGrayColorSpace; { COLORSPACE(NSGrayColorSpaceModel); }
+ (NSColorSpace *) deviceRGBColorSpace; { COLORSPACE(NSRGBColorSpaceModel); }
+ (NSColorSpace *) genericCMYKColorSpace; { COLORSPACE(NSCMYKColorSpaceModel); }
+ (NSColorSpace *) genericGrayColorSpace; { COLORSPACE(NSGrayColorSpaceModel); }
+ (NSColorSpace *) genericRGBColorSpace; { COLORSPACE(NSRGBColorSpaceModel); }

+ (NSColorSpace *) _colorSpaceWithName:(NSString *) name;
{
	if([name compare:@"Grayscale" options:NSCaseInsensitiveSearch]) return [self genericGrayColorSpace];
	if([name compare:@"RGB" options:NSCaseInsensitiveSearch]) return [self genericRGBColorSpace];
	if([name compare:@"CMYK" options:NSCaseInsensitiveSearch]) return [self genericCMYKColorSpace];
	return nil;
}

- (NSColorSpaceModel) colorSpaceModel;	{ return colorSpaceModel; }
- (void *) colorSyncProfile;			{ return NIMP; }
- (NSData *) ICCProfileData;			{ return NIMP; }
- (id) initWithColorSyncProfile:(void *) prof;		{ [self release]; return NIMP; }
- (id) initWithICCProfileData:(NSData *) iccData;	{ [self release]; return NIMP; }
- (id) _initWithColorSpaceModel:(NSColorSpaceModel) model;
{
	if((self=[super init]))
		{
		colorSpaceModel=model;
		}
	return self;
}

- (NSString *) localizedName;
{
	switch(colorSpaceModel)
		{
		default:
		case NSUnknownColorSpaceModel:	return @"unknown";
		case NSGrayColorSpaceModel:		return @"Grayscale";
		case NSRGBColorSpaceModel:		return @"RGB";
		case NSCMYKColorSpaceModel:		return @"CMYK";
		case NSLABColorSpaceModel:		return @"LAB";
		case NSDeviceNColorSpaceModel:	return @"DeviceN";
		}
}

- (int) numberOfColorComponents;	// plus alpha!
{
	switch(colorSpaceModel)
		{
		default:
		case NSUnknownColorSpaceModel:	return 0;
		case NSGrayColorSpaceModel:		return 1;
		case NSRGBColorSpaceModel:		return 3;
		case NSCMYKColorSpaceModel:		return 4;
		case NSLABColorSpaceModel:		return 3;	// FIXME
		case NSDeviceNColorSpaceModel:	return 3;	// FIXME
		}
}

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) aDecoder;
{
	if([aDecoder allowsKeyedCoding])
		return NIMP;
	return NIMP;
}

@end
