/* Interface of the NSManagedObjectModel class for the GNUstep
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

#ifndef _NSManagedObjectModel_h_
#define _NSManagedObjectModel_h_

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSDictionary, NSMutableDictionary, NSURL;
@class NSFetchRequest, NSAttributeDescription;

@interface NSManagedObjectModel : NSObject <NSCopying, NSCoding>
{
  NSArray * _entities;

  /**
   * Keys are configuration names, values are arrays of entities
   * for that one particular configuration.
   */
  NSMutableDictionary * _configurations;
  NSMutableDictionary * _fetchRequests;

  NSMutableDictionary * _defaultAttributeValues;

  /** 
   * We use a reference counting mechanism to determine whether this
   * object model is used by a persistent store coordinator. When the
   * number is zero, changes to the model are allowed - it is not used
   * by anyone. By associating with a persistent store coordinator, the
   * number is incremented, and when the coordinator is dealloc'd, this
   * number is decremented again.
   */
  unsigned _usedByPersistentStoreCoordinators;
}

// Initialization.
+ (NSManagedObjectModel *) mergedModelFromBundles: (NSArray *) someBundles;
+ (NSManagedObjectModel *) modelByMergingModels: (NSArray *) someModels;
- initWithContentsOfURL: (NSURL *) aUrl;

// Getting and setting entities and configurations.
- (NSArray *) entities;
- (NSDictionary *) entitiesByName;
- (void) setEntities: (NSArray *) someEntities;
- (NSArray *) configurations;
- (NSArray *) entitiesForConfiguration: (NSString *) aConfiguration;
// passing `nil' as the entities instead deletes the configuration
- (void) setEntities: (NSArray *) someEntities
    forConfiguration: (NSString *) aConfiguration;

// Getting and setting fetch request templates.
- (NSFetchRequest *) fetchRequestTemplateForName: (NSString *) aName;
- (NSFetchRequest *) fetchRequestFromTemplateWithName: (NSString *) aName
                         substitutionVariables: (NSDictionary *) someVariables;
- (void) setFetchRequestTemplate: (NSFetchRequest *) aFetchRequest
                         forName: (NSString *) aName;

// Localization.
- (NSDictionary *) localizationDictionary;
- (void) setLocalizationDictionary: (NSDictionary *) aLocalizationDictionary;

@end

#endif // _NSManagedObjectModel_h_
