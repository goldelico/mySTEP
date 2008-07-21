/*
    NSPropertyList.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Mon Jul 14 2003.
    Copyright (c) 2003 DSITRI.

  	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSPROPERTYLIST_H
#define mySTEP_NSPROPERTYLIST_H

#import <Foundation/NSObject.h>

@class NSData, NSString;

typedef enum _NSPropertyListMutabilityOptions
{
	NSPropertyListImmutable=0,
	NSPropertyListMutableContainers,
	NSPropertyListMutableContainersAndLeaves
} NSPropertyListMutabilityOptions;

typedef enum _NSPropertyListFormat
{
	NSPropertyListStringFileFormat=-2,	// extension: StringFile format
	NSPropertyListAnyFormat=-1,			// extension: try to determine format
	NSPropertyListXMLFormat_v1_0,		// tried first when NSPropertyListAnyFormat is specified because most probable
	NSPropertyListOpenStepFormat,		// second probable
	NSPropertyListBinaryFormat_v1_0		// third probable
} NSPropertyListFormat;

@interface NSPropertyListSerialization : NSObject

+ (NSData *) dataFromPropertyList:(id) plist
						   format:(NSPropertyListFormat) format
				 errorDescription:(NSString **) errorString;	// NOTE: this string is NOT autoreleased!
+ (BOOL) propertyList:(id) plist
	 isValidForFormat:(NSPropertyListFormat) format;
+ (id) propertyListFromData:(NSData *) data
		   mutabilityOption:(NSPropertyListMutabilityOptions) opt
					 format:(NSPropertyListFormat *) format
		   errorDescription:(NSString **) errorString;	// NOTE: this string is NOT autoreleased!

@end

#endif mySTEP_NSPROPERTYLIST_H
