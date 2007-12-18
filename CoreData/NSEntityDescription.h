/* Interface of the NSEntityDescription class for the GNUstep
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

#ifndef _NSEntityDescription_h_
#define _NSEntityDescription_h_

#import <Foundation/NSObject.h>

@class NSString, NSArray, NSDictionary;
@class NSManagedObjectModel, NSManagedObjectContext;

@interface NSEntityDescription : NSObject <NSCopying, NSCoding>
{
  NSString * _name;
  BOOL _abstract;
  NSString * _managedObjectClassName;
  NSArray * _properties;
  NSDictionary * _userInfo;

  NSArray * _subentities;
  // weak reference
  NSEntityDescription * _superentity;

  // weak reference
  NSManagedObjectModel * _model;
  /**
   * This counts the number of references to the model of this entity.
   * It is needed because a single model may have several references
   * to an entity (such as the entity being in several configurations).
   */
  unsigned int _modelRefCount;
}

// Convenience class methods.
+ (NSEntityDescription *) entityForName: (NSString *) anEntityName
                 inManagedObjectContext: (NSManagedObjectContext *) aContext;
+ (id) insertNewObjectForEntityForName: (NSString *) anEntityName
                inManagedObjectContext: (NSManagedObjectContext *) aContext;

- (NSDictionary *) attributesByName;
// - (id) copy;
- (BOOL) isAbstract;
- (NSString *) managedObjectClassName;
- (NSManagedObjectModel *) managedObjectModel;
- (NSString *) name;
- (NSArray *) properties;
- (NSDictionary *) propertiesByName;
- (NSDictionary *) relationshipsByName;
- (NSArray *) relationshipsWithDestinationEntity:(NSEntityDescription *) _destinationEntity;
- (void) setAbstract: (BOOL) flag;
- (void) setManagedObjectClassName: (NSString *) aClassName;
- (void) setName: (NSString *) aName;
- (void) setProperties: (NSArray *) someProperties;
- (void) setSubentities: (NSArray *) someSubentities;
- (void) setUserInfo: (NSDictionary *) someUserInfo;
- (NSArray *) subentities;
- (NSDictionary *) subentitiesByName;
- (NSEntityDescription *) superentity;
- (NSDictionary *) userInfo;
- (BOOL) _isSubentityOfEntity: (NSEntityDescription *) otherEntity;

@end

#endif // _NSEntityDescription_h_
