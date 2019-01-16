/* Interface of the NSFetchRequest class for the GNUstep
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

#ifndef _NSFetchRequest_h_
#define _NSFetchRequest_h_

#import <Foundation/NSObject.h>

@class NSArray, NSPredicate;
@class NSEntityDescription;

@interface NSFetchRequest : NSObject <NSCopying, NSCoding>
{
  NSArray * _affectedStores;
  NSEntityDescription * _entity;
  unsigned int _fetchLimit;
  NSPredicate * _predicate;
  NSArray * _sortDescriptors;
}

#ifndef NO_GNUSTEP

- (id) _initWithAffectedStores: (NSArray *) affectedStores
						entity: (NSEntityDescription *) entity
					fetchLimit: (unsigned int) fetchLimit
					 predicate: (NSPredicate *) predicate
			   sortDescriptors: (NSArray *) sortDescriptors;

#endif // NO_GNUSTEP

- (NSArray *) affectedStores;
- (void) setAffectedStores: (NSArray *) someStores;

- (NSEntityDescription *) entity;
- (void) setEntity: (NSEntityDescription *) anEntityDescription;

- (unsigned int) fetchLimit;
- (void) setFetchLimit: (unsigned int) aFetchLimit;

- (NSPredicate *) predicate;
- (void) setPredicate: (NSPredicate *) aPredicate;

- (NSArray *) sortDescriptors;
- (void) setSortDescriptors: (NSArray *) someSortDescriptors;

@end

#endif // _NSFetchRequest_h_
