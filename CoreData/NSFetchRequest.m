/* Implementation of the NSFetchRequest class for the GNUstep
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

/**
 * An object for storing details about managed object fetches.
 *
 * A fetch request records information on which objects to fetch
 * from an object context when the
 * -[NSManagedObjectContext executeFetchRequest:] method is invoked.
 *
 * You can easily assemble fetch requests with the help of the
 * DataBuilder application at project design-time, and later access
 * them at run-time through the managed object model.
 */
@implementation NSFetchRequest

- (void) dealloc
{
  TEST_RELEASE(_affectedStores);
  TEST_RELEASE(_entity);
  TEST_RELEASE(_predicate);

  [super dealloc];
}

/**
 * A shorthand method for quick initialization.
 */
- (id) _initWithAffectedStores: (NSArray *) affectedStores
                       entity: (NSEntityDescription *) entity
                   fetchLimit: (unsigned int) fetchLimit
                    predicate: (NSPredicate *) predicate
              sortDescriptors: (NSArray *) sortDescriptors
{
  if ((self = [self init]))
    {
      ASSIGN(_affectedStores, affectedStores);
      ASSIGN(_entity, entity);
      _fetchLimit = fetchLimit;
      ASSIGN(_predicate, predicate);
      ASSIGN(_sortDescriptors, sortDescriptors);

    }
	return self;
}

/**
 * Returns an array of stores on which this fetch will executed.
 */
- (NSArray *) affectedStores
{
  return _affectedStores;
}

/**
 * Sets the stores on which this fetch will be executed.
 */
- (void) setAffectedStores: (NSArray *) stores
{
  ASSIGN(_affectedStores, stores);
}

/**
 * Returns the entity of the fetch request. See also
 * -[NSFetchRequest setEntity:].
 */
- (NSEntityDescription *) entity
{
  return _entity;
}

/**
 * Sets the entity of the fetch request. If not `nil', objects must have
 * the given entity set in order to be fetched by this fetch request.
 */
- (void) setEntity: (NSEntityDescription *) entity
{
  ASSIGN(_entity, entity);
}

/**
 * Returns the fetch limit of the receiver. See also
 * -[NSFetchRequest setFetchLimit:].
 */
- (unsigned int) fetchLimit
{
  return _fetchLimit;
}

/**
 * Sets the fetch limit of the receiver.
 */
- (void) setFetchLimit: (unsigned int) aLimit
{
  _fetchLimit = aLimit;
}

/**
 * Returns the predicate of the receiver. See also
 * -[NSFetchRequest setPredicate:].
 */
- (NSPredicate *) predicate
{
  return _predicate;
}

/**
 * Sets the predicate of the receiver. If not `nil', objects must
 * evaluate to YES in order to be fetched by this fetch request.
 */
- (void) setPredicate: (NSPredicate *) predicate
{
  ASSIGN(_predicate, predicate);
}

/**
 * Returns the receiver's sort descriptors. See also
 * -[NSFetchRequest setSortDescriptors:].
 */
- (NSArray *) sortDescriptors
{
  return _sortDescriptors;
}

/**
 * Sets the sort descriptors of the receiver. If not `nil', after
 * the fetch, the fetched objects are sorted using these sort
 * descriptors.
 */
- (void) setSortDescriptors: (NSArray *) sortDescriptors
{
  ASSIGN(_sortDescriptors, sortDescriptors);
}

// NSCopying

- (id) copyWithZone: (NSZone *) zone
{
  return [[NSFetchRequest allocWithZone: zone]
    _initWithAffectedStores: _affectedStores
                    entity: _entity
                fetchLimit: _fetchLimit
                 predicate: _predicate
           sortDescriptors: _sortDescriptors];
}

// NSCoding

- (void) encodeWithCoder: (NSCoder *) coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _affectedStores forKey: @"AffectedStores"];
      [coder encodeObject: _entity forKey: @"Entity"];
      [coder encodeInt: _fetchLimit forKey: @"FetchLimit"];
      [coder encodeObject: _predicate forKey: @"Predicate"];
      [coder encodeObject: _sortDescriptors forKey: @"SortDescriptors"];
    }
  else
    {
      [coder encodeObject: _affectedStores];
      [coder encodeObject: _entity];
      [coder encodeValueOfObjCType: @encode(unsigned int) at: &_fetchLimit];
      [coder encodeObject: _predicate];
      [coder encodeObject: _sortDescriptors];
    }
}

- (id) initWithCoder: (NSCoder *) coder
{
	if ((self = [self init]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_affectedStores, [coder
            decodeObjectForKey: @"AffectedStores"]);
          ASSIGN(_entity, [coder decodeObjectForKey: @"Entity"]);
          _fetchLimit = [coder decodeIntForKey: @"FetchLimit"];
          ASSIGN(_predicate, [coder decodeObjectForKey: @"Predicate"]);
          ASSIGN(_sortDescriptors, [coder
            decodeObjectForKey: @"SortDescriptors"]);
        }
      else
        {
          ASSIGN(_affectedStores, [coder decodeObject]);
          ASSIGN(_entity, [coder decodeObject]);
          [coder decodeValueOfObjCType: @encode(unsigned int)
                                    at: &_fetchLimit];
          ASSIGN(_predicate, [coder decodeObject]);
          ASSIGN(_sortDescriptors, [coder decodeObject]);
        }

    }
	return self;
}

@end
