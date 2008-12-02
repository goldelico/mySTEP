/*  
    Interface for NSClassDescription for GNUStep
    Copyright (C) 2000 Free Software Foundation, Inc.

    Written by:  Richard Frith-Macdonald <rfm@gnu.org>
    Date:	2000
   
    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	20. April 2008 - aligned with 10.5

    This file is part of the GNUstep Base Library.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.
   
    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.
   
    You should have received a copy of the GNU Library General Public
    License along with this library; if not, write to the Free
    Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111 USA.
*/ 

#ifndef __NSClassDescription_h_GNUSTEP_BASE_INCLUDE
#define __NSClassDescription_h_GNUSTEP_BASE_INCLUDE

#import <Foundation/NSObject.h>
#import <Foundation/NSException.h>

@class NSArray;
@class NSDictionary;
@class NSString;

NSString *const NSClassDescriptionNeededForClassNotification;

@interface NSClassDescription : NSObject

+ (NSClassDescription *) classDescriptionForClass:(Class) aClass;
+ (void) invalidateClassDescriptionCache;
+ (void) registerClassDescription:(NSClassDescription *) aDescription
			             forClass:(Class) aClass;

- (NSArray *) attributeKeys;
- (NSString *) inverseForRelationshipKey:(NSString *) aKey;
- (NSArray *) toManyRelationshipKeys;
- (NSArray *) toOneRelationshipKeys;

@end

@interface NSObject (NSClassDescriptionPrimitives)

- (NSArray *) attributeKeys;
- (NSClassDescription *) classDescription;
- (NSString *) inverseForRelationshipKey:(NSString *) aKey;
- (NSArray *) toManyRelationshipKeys;
- (NSArray *) toOneRelationshipKeys;

@end

#endif
