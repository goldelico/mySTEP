/* Implementation of the NSPropertyDescription class for the GNUstep
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

@implementation NSPropertyDescription

- (void) dealloc
{
  TEST_RELEASE(_name);
  TEST_RELEASE(_userInfo);
  TEST_RELEASE(_validationPredicates);
  TEST_RELEASE(_validationWarnings);

  [super dealloc];
}

- (NSString *) name
{
  return _name;
}

- (void) setName: (NSString *) aName
{
  [self _ensureEditableWithReason: @"Tried to set name of a property "
                                   @"already in use."];
  ASSIGN(_name, aName);
}

- (NSEntityDescription *) entity
{
  return _entity;
}

- (BOOL) isOptional
{
  return _optional;
}

- (void) setOptional: (BOOL) flag
{
  [self _ensureEditableWithReason: @"Tried to optionality of a property "
                                   @"already in use."];
  _optional = flag;
}

- (BOOL) isTransient
{
  return _transient;
}

- (void) setTransient: (BOOL) flag
{
  [self _ensureEditableWithReason: @"Tried to set transient-ness of a"
                                   @" property already in use."];
  _transient = flag;
}

- (NSDictionary *) userInfo
{
  return _userInfo;
}

- (void) setUserInfo: (NSDictionary *) userInfo
{
  [self _ensureEditableWithReason: @"Tried to set user info of a property "
                                   @"already in use."];
  ASSIGN(_userInfo, userInfo);
}

- (NSArray *) validationPredicates
{
  return _validationPredicates;
}

- (NSArray *) validationWarnings
{
  return _validationWarnings;
}

- (void) setValidationPredicates: (NSArray *) someValidationPredicates
          withValidationWarnings: (NSArray *) someValidationWarnings
{
  [self _ensureEditableWithReason: @"Tried to set validation predicates and "
                                   @"validation warnings of a property "
                                   @"already in use."];
  ASSIGN(_validationPredicates, someValidationPredicates);
  ASSIGN(_validationWarnings, someValidationWarnings);
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  NSPropertyDescription * property;

  property = [NSPropertyDescription new];
  [property setName: _name];
  [property setOptional: _optional];
  [property setTransient: _transient];
  [property setUserInfo: _userInfo];
  [property setValidationPredicates: _validationPredicates
             withValidationWarnings: _validationWarnings];

  return property;
}

// NSCoding

- (id) initWithCoder: (NSCoder *) coder
{
	if ((self = [super init]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_name, [coder decodeObjectForKey: @"Name"]);
          ASSIGN(_userInfo, [coder decodeObjectForKey: @"UserInfo"]);
          ASSIGN(_validationPredicates, [coder decodeObjectForKey:
            @"ValidationPredicates"]);
          ASSIGN(_validationWarnings, [coder decodeObjectForKey:
            @"ValidationPredicates"]);

          _entity = [coder decodeObjectForKey: @"Entity"];

          _optional = [coder decodeBoolForKey: @"Optional"];
          _transient = [coder decodeBoolForKey: @"Transient"];
        }
      else
        {
          ASSIGN(_name, [coder decodeObject]);
          ASSIGN(_userInfo, [coder decodeObject]);
          ASSIGN(_validationPredicates, [coder decodeObject]);
          ASSIGN(_validationWarnings, [coder decodeObject]);

          _entity = [coder decodeObject];

          [coder decodeValueOfObjCType: @encode(typeof(_optional))
                                    at: &_optional];
          [coder decodeValueOfObjCType: @encode(typeof(_transient))
                                    at: &_transient];
        }
	}
      return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _name forKey: @"Name"];
      [coder encodeObject: _userInfo forKey: @"UserInfo"];
      [coder encodeObject: _validationPredicates
                   forKey: @"ValidationPredicates"];
      [coder encodeObject: _validationWarnings
                   forKey: @"ValidationWarnings"];

      [coder encodeObject: _entity forKey: @"Entity"];

      [coder encodeBool: _optional forKey: @"Optional"];
      [coder encodeBool: _transient forKey: @"Transient"];
    }
  else
    {
      [coder encodeObject: _name];
      [coder encodeObject: _userInfo];
      [coder encodeObject: _validationPredicates];
      [coder encodeObject: _validationWarnings];

      [coder encodeObject: _entity];

      [coder encodeValueOfObjCType: @encode(typeof(_optional))
                                at: &_optional];
      [coder encodeValueOfObjCType: @encode(typeof(_transient))
                                at: &_transient];
    }
}

@end

@implementation NSPropertyDescription (GSCoreDataPrivate)

/**
 * Sets the inverse weak relationship from the receiver to it's
 * owning entity.
 */
- (void) _setEntity: (NSEntityDescription *) entity
{
  _entity = entity;
}

/**
 * Raises an exception if the property's entity is associated with a
 * managed object model which is already in use by a persistent
 * store coordinator. In other words, it ensures that the property
 * can be edited. The `reason' argument is the reason set in the exception.
 * It can passed unlocalized - this method will localize it. This is
 * for efficiency.
 */
- (void) _ensureEditableWithReason: (NSString *) reason
{
  NSManagedObjectModel * model;

  model = [_entity managedObjectModel];
  if (model != nil && [model _isEditable] == NO)
    {
      [NSException raise: NSGenericException format: _(reason)];
    }
}

@end
