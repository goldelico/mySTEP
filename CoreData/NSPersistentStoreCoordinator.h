/* Interface of the NSPersistentStoreCoordinator class for the GNUstep
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

#ifndef _NSPersistentStoreCoordinator_h_
#define _NSPersistentStoreCoordinator_h_

#import <Foundation/NSObject.h>
#import <Foundation/NSLock.h>

@class NSString,
       NSDictionary,
       NSMutableDictionary,
       NSURL,
       NSError;
@class NSManagedObjectModel,
       NSManagedObjectID;

// Persistent store types.
extern NSString * const NSSQLiteStoreType;
extern NSString * const NSXMLStoreType;
extern NSString * const NSBinaryStoreType;
extern NSString * const NSInMemoryStoreType;

// Persistent store option keys.
extern NSString * const NSReadOnlyPersistentStoreOption;
extern NSString * const NSValidateXMLStoreOption;

// Persistent store type keys.
extern NSString * const NSStoreTypeKey;
extern NSString * const NSStoreUUIDKey;

@interface NSPersistentStoreCoordinator : NSObject <NSLocking>
{
  NSManagedObjectModel * _model;

  // a dictionary where stores are keyed to their URLs
  NSMutableDictionary * _persistentStores;
  NSRecursiveLock * _lock;

  /**
   * When the first store is added to a persistent store coordinator,
   * the `configuration' argument determines which configurations are
   * permitted:
   *
   * - configuration = nil means that subsequent store additions may
   *   only use a `nil' configuration.
   * - configuration != nil means that subsequent store additions may
   *   use any configuration.
   */
  BOOL _configurationSet;
  // YES if the first added store passed a non-nil configuration,
  // NO otherwise.
  BOOL _multipleConfigurationsAllowed;

  /**
   * This determines whether we have already incremented the use count
   * of our managed object model, and thus made it uneditable. The model
   * isn't acquired in the moment the receiver is initialized, but instead
   * in the moment when the first data fetch is done.
   */
  BOOL _acquiredModel;
}

// Initialization.
- (id) initWithManagedObjectModel: (NSManagedObjectModel *) aModel;
- (NSManagedObjectModel *) managedObjectModel;

// Managing the persistent stores.
- (id) addPersistentStoreWithType: (NSString *) aStoreType
                    configuration: (NSString *) aConfiguration
                              URL: (NSURL *) aStoreURL
                          options: (NSDictionary *) someOptions
                            error: (NSError **) anErrorPointer;

- (BOOL) removePersistentStore: (id) aPersistentStore
                         error: (NSError **) errorPointer;

- (id) migratePersistentStore: (id) aPersistentStore
                        toURL: (NSURL *) aURL
                      options: (NSDictionary *) options
                     withType: (NSString *) newStoreType
                        error: (NSError **) errorPointer;

- (NSArray *) persistentStores;
- (id) persistentStoreForURL: (NSURL *) aURL;
- (NSURL *) URLForPersistentStore: (id) aPersistentStore;

// Locking.
- (void) lock;
- (void) unlock;
- (BOOL) tryLock;

// Store meta-data handling.
+ (NSDictionary *) metadataForPersistentStoreWithURL: (NSURL *) aUrl
                                               error: (NSError **) errorPtr;
- (NSDictionary *) metadataForPersistentStore: (id) store;
- (void) setMetadata: (NSDictionary *) metadata
  forPersistentStore: (id) store;

// Getting managed object IDs.
- (NSManagedObjectID *) managedObjectIDForURIRepresentation: (NSURL *) uri;

@end

#endif // _NSPersistentStoreCoordinator_h_
