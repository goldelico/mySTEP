/* Implementation of the NSRelationshipDescription class for the GNUstep
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

@implementation NSRelationshipDescription

- (void) dealloc
{
  TEST_RELEASE(_destinationEntity);

  [super dealloc];
}

- (NSEntityDescription *) destinationEntity
{
  return _destinationEntity;
}

- (void) setDestinationEntity: (NSEntityDescription *) entity
{
  [self _ensureEditableWithReason: _(@"Tried to set the destination "
                                    @"entity of a relationship "
                                    @"already in use")];
  ASSIGN(_destinationEntity, entity);

  // destroy the inverse relationship - we'll have to set it up anew
  if (_inverseRelationship != nil)
    [_inverseRelationship setInverseRelationship: nil];
  [self setInverseRelationship: nil];
}

- (NSRelationshipDescription *) inverseRelationship
{
  return _inverseRelationship;
}

- (void) setInverseRelationship: (NSRelationshipDescription *) relationship
{
  [self _ensureEditableWithReason: _(@"Tried to set the inverse "
                                    @"relationship of a relationship "
                                    @"already in use")];

  // make sure the destination entity contains the relationship
  if (relationship != nil &&
    ![[_destinationEntity properties] containsObject: relationship])
    {
      [NSException raise: NSInvalidArgumentException
                  format: _(@"Tried to set inverse relationship which is not in the destination entity.")];
    }

  _inverseRelationship = relationship;
}

- (NSDeleteRule) deleteRule
{
  return _deleteRule;
}

- (void) setDeleteRule: (NSDeleteRule) rule
{
  [self _ensureEditableWithReason: _(@"Tried to set the delete rule "
                                    @"of a relationship already in use")];
  _deleteRule = rule;
}

- (int) minCount
{
  return _minCount;
}

- (void) setMinCount: (int) aCount
{
  [self _ensureEditableWithReason: _(@"Tried to set minimum count "
                                    @"of a relationship already in use")];
  if (aCount > _maxCount)
    {
      [NSException raise: NSInvalidArgumentException
                  format: _(@"Tried to set minimum count of a relationship "
                            @"higher than it's maximum count")];
    }

  _minCount = aCount;
}

- (int) maxCount
{
  return _maxCount;
}

- (void) setMaxCount: (int) aCount
{
  [self _ensureEditableWithReason: @"Tried to set maximum count "
                                   @"of a relationship already in use."];
  if (aCount < _minCount)
    {
      [NSException raise: NSInvalidArgumentException
                  format: @"Tried to set maximum count of a relationship "
                          @"lower than it's minimum count."];
    }

  _maxCount = aCount;
}

- (BOOL) isToMany
{
  return (_maxCount > 1);
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  NSRelationshipDescription * relationship = [super copyWithZone: zone];

  [relationship setDestinationEntity: _destinationEntity];
  [relationship setInverseRelationship: _inverseRelationship];
  [relationship setDeleteRule: _deleteRule];
  [relationship setMaxCount: _maxCount];
  [relationship setMinCount: _minCount];

  return relationship;
}

// NSCoding

- (id) initWithCoder: (NSCoder *) coder
{
  if ((self = [super initWithCoder: coder]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_destinationEntity, [coder decodeObjectForKey:
            @"DestinationEntity"]);
          ASSIGN(_inverseRelationship, [coder decodeObjectForKey:
            @"InverseRelationship"]);

          _deleteRule = [coder decodeIntForKey: @"DeleteRule"];
          _minCount = [coder decodeIntForKey: @"MinCount"];
          _maxCount = [coder decodeIntForKey: @"MaxCount"];
        }
      else
        {
          ASSIGN(_destinationEntity, [coder decodeObject]);
          ASSIGN(_inverseRelationship, [coder decodeObject]);

          [coder decodeValueOfObjCType: @encode(typeof(_deleteRule))
                                    at: &_deleteRule];
          [coder decodeValueOfObjCType: @encode(typeof(_minCount))
                                    at: &_minCount];
          [coder decodeValueOfObjCType: @encode(typeof(_maxCount))
                                    at: &_maxCount];
        }
	}
      return self;
}

- (void) encodeWithCoder: (NSCoder *) coder
{
  [super encodeWithCoder: coder];
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _destinationEntity forKey: @"DestinationEntity"];
      [coder encodeObject: _inverseRelationship
                   forKey: @"InverseRelationship"];

      [coder encodeInt: _deleteRule forKey: @"DeleteRule"];
      [coder encodeInt: _minCount forKey: @"MinCount"];
      [coder encodeInt: _maxCount forKey: @"MaxCount"];
    }
  else
    {
      [coder encodeObject: _destinationEntity];
      [coder encodeObject: _inverseRelationship];

      [coder encodeValueOfObjCType: @encode(typeof(_deleteRule))
                                at: &_deleteRule];
      [coder encodeValueOfObjCType: @encode(typeof(_minCount))
                                at: &_minCount];
      [coder encodeValueOfObjCType: @encode(typeof(_maxCount))
                                at: &_maxCount];
    }
}

@end
