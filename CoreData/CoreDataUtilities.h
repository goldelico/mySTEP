/* Declarations of utility functions for the GNUstep Core Data framework.
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

#ifndef _CoreDataUtilities_h_
#define _CoreDataUtilities_h_

@class NSError, NSString;

/**
 * If ``ptr'' is not NULL, sets ``error'' into it.
 *
 * This is used in many places when an error pointer is to be set
 * if it is not NULL.
 */
static inline void
SetNonNullError (NSError ** ptr, NSError * error)
{
  if (ptr != NULL)
    {
      *ptr = error;
    }
}

/**
 * Tests whether an object is matched by a fetch request.
 *
 * @arg object The object which to test.
 * @arg fetchRequest The fetch request which to perform the match against.
 *
 * @return YES if the object matches the fetch request's criteria, NO
 * otherwise.
 */
static inline BOOL
ObjectMatchedByFetchRequest (NSManagedObject * object,
                             NSFetchRequest * fetchRequest)
{
  NSEntityDescription * entity = [fetchRequest entity];
  NSPredicate * predicate = [fetchRequest predicate];
  NSArray * affectedStores = [fetchRequest affectedStores];

  if (entity != nil)
    {
      if ([[object entity] isEqual: entity] == NO)
        {
          return NO;
        }
    }

  if (predicate != nil)
    {
      if ([predicate evaluateWithObject: object] == NO)
        {
          return NO;
        }
    }

  if (affectedStores != nil)
    {
      if ([affectedStores containsObject: [[object objectID]
        persistentStore]] == NO)
        {
          return NO;
        }
    }

  return YES;
}

#endif // _CoreDataUtilities_h_
