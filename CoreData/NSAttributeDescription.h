/* Interface of the NSAttributeDescription class for the GNUstep
   Core Data framework.
   Copyright (C) 2005 Free Software Foundation, Inc.

   Written by:  Saso Kiselkov <diablos@manga.sk>
   Date: August 2005

   This file is part of the GNUstep Core Data framework.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with this library; if not, write to the Free
   Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#ifndef _NSAttributeDescription_h_
#define _NSAttributeDescription_h_

#import <CoreData/NSPropertyDescription.h>

typedef enum {
        NSUndefinedAttributeType = 0,
        NSInteger16AttributeType = 100,
        NSInteger32AttributeType = 200,
        NSInteger64AttributeType = 300,
        NSDecimalAttributeType = 400,
        NSDoubleAttributeType = 500,
        NSFloatAttributeType = 600,
        NSStringAttributeType = 700,
        NSBooleanAttributeType = 800,
        NSDateAttributeType = 900,
        NSBinaryDataAttributeType = 1000
} NSAttributeType;

@class NSString;

@interface NSAttributeDescription : NSPropertyDescription
{
  NSAttributeType _attributeType;
  id _defaultValue;
}

// Getting and setting the attribute type.
- (NSAttributeType) attributeType;
- (NSString *) attributeValueClassName;
- (id) defaultValue;
- (void) setAttributeType: (NSAttributeType) anAttributeType;
- (void) setDefaultValue: (id) aValue;

// Getting and setting the default value.

@end

#endif // _NSAttributeDescription_h_
