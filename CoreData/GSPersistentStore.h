/* Interface of the GSPersistentStore class for the GNUstep
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

#ifndef _GSPersistentStore_h_
#define _GSPersistentStore_h_

#include <Foundation/NSObject.h>

@class NSString,
       NSDictionary,
       NSMutableDictionary,
       NSArray,
       NSError,
       NSSet,
       NSPredicate;
@class NSURL,
       NSEntityDescription,
       NSManagedObjectModel,
       NSManagedObjectID,
       NSFetchRequest;

@interface GSPersistentStore : NSObject
{
  NSURL * _URL;
  NSManagedObjectModel * _model;
  NSString * _configuration;

  NSDictionary * _metadata;

  NSMutableDictionary * _versionNumbers;
}

-       initWithURL: (NSURL *) URL
 managedObjectModel: (NSManagedObjectModel *) model
      configuration: (NSString *) configuration
            options: (NSDictionary *) options;

- (NSURL *) URL;
- (NSString *) configuration;
- (void) setUUID: (NSString *) newUUID;

// store metadata manipulation
- (void) setMetadata: (NSDictionary *) metadata;
- (NSDictionary *) metadata;

- (BOOL) saveObjects: (NSSet *) objects
               error: (NSError **) error;

- (unsigned long long) versionNumberForObjectID:(NSManagedObjectID *)objectID;

// subclasses must override these methods

- (NSString *) storeType;
- (unsigned long long) highestIDValue;
- (NSDictionary *) fetchObjectsWithEntity: (NSEntityDescription *) entity
                                predicate: (NSPredicate *) predicate
                                    error: (NSError **) error;
- (NSDictionary *) fetchObjectWithID: (NSManagedObjectID *) objectID
                     fetchProperties: (NSSet *) propertiesToFetch;
- (NSDictionary *) fetchObjectsWithEntity: (NSEntityDescription *) entity
                                predicate: (NSPredicate *) predicate
                                    error: (NSError **) error;
- (BOOL) writeSavingObjects: (NSSet *) objectsToWrite
			deletingObjects: (NSSet *) objectIDsToDelete
                      error: (NSError **) error;
@end

#endif // _GSPersistentStore_h_
