/* Implementation of the NSAttributeDescription class for the GNUstep
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

#import "CoreDataHeaders.h"

@implementation NSAttributeDescription

- (NSAttributeType) attributeType
{
  return _attributeType;
}

- (void) setAttributeType: (NSAttributeType) type
{
  [self _ensureEditableWithReason: @"Tried to set the type of an attribute "
                                   @"already in use."];
  _attributeType = type;
}

- (NSString *) attributeValueClassName
{
	switch(_attributeType)
		{
		case NSUndefinedAttributeType: return @"NSNull";
		case NSInteger16AttributeType: return @"NSNumber";
		case NSInteger32AttributeType: return @"NSNumber";
		case NSInteger64AttributeType: return @"NSNumber";
		case NSDecimalAttributeType: return @"NSDecimalNumber";
		case NSDoubleAttributeType: return @"NSNumber";
		case NSFloatAttributeType: return @"NSNumber";
		case NSStringAttributeType: return @"NSString";
		case NSBooleanAttributeType: return @"NSNumber";
		case NSDateAttributeType: return @"NSDate";
		case NSBinaryDataAttributeType: return @"NSData";
		}
	return nil;
}

- (id) defaultValue
{
  return _defaultValue;
}

- (void) setDefaultValue: (id) aValue
{
  [self _ensureEditableWithReason: @"Tried to set the default value for "
                                   @"an attribute already in use."];

  ASSIGN(_defaultValue, aValue);
}

// NSCoding

- (id) initWithCoder: (NSCoder *) coder
{
  if ((self = [super initWithCoder: coder]))
    {
      if ([coder allowsKeyedCoding])
        {
          _attributeType = [coder decodeIntForKey: @"AttributeType"];
 //         ASSIGN(_attributeValueClassName, [coder decodeObjectForKey:
  //          @"AttributeValueClassName"]);
          ASSIGN(_defaultValue, [coder decodeObjectForKey: @"DefaultValue"]);
        }
      else
        {
          [coder decodeValueOfObjCType: @encode(int) at: &_attributeType];
  //        ASSIGN(_attributeValueClassName, [coder decodeObject]);
          ASSIGN(_defaultValue, [coder decodeObject]);
        }

    }
	return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [super encodeWithCoder: coder];

  if ([coder allowsKeyedCoding])
    {
      [coder encodeInt: _attributeType forKey: @"AttributeType"];
  //    [coder encodeObject: _attributeValueClassName
  //               forKey: @"AttributeValueClassName"];
      [coder encodeObject: _defaultValue forKey: @"DefaultValue"];
    }
  else
    {
      [coder encodeValueOfObjCType: @encode(int) at: &_attributeType];
  //    [coder encodeObject: _attributeValueClassName];
      [coder encodeObject: _defaultValue];
    }
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  NSAttributeDescription * attr = [super copyWithZone: zone];

  [attr setAttributeType: _attributeType];
//  [attr setAttributeValueClassName: _attributeValueClassName];
  [attr setDefaultValue: _defaultValue];

  return attr;
}

@end
