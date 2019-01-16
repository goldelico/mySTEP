/*
    NSAttributeDescriptionUtilities.h

    Utility inline functions for manipulating an NSAttributeDescription.

    Copyright (C) 2005  Saso Kiselkov

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
*/

#import <Foundation/NSString.h>
#import <Foundation/NSBundle.h>
#import <CoreData/NSAttributeDescription.h>

static inline NSString * StringFromAttributeType(NSAttributeType type)
{
  switch (type)
    {
    case NSUndefinedAttributeType:
      return _(@"undef");
    case NSInteger16AttributeType:
      return _(@"int16");
    case NSInteger32AttributeType:
      return _(@"int32");
    case NSInteger64AttributeType:
      return _(@"int64");
    case NSDecimalAttributeType:
      return _(@"decimal");
    case NSDoubleAttributeType:
      return _(@"double");
    case NSFloatAttributeType:
      return _(@"float");
    case NSStringAttributeType:
      return _(@"string");
    case NSBooleanAttributeType:
      return _(@"bool");
    case NSDateAttributeType:
      return _(@"date");
    case NSBinaryDataAttributeType:
      return _(@"data");
    }

  return nil;
}
