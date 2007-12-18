/* Interface of the NSManagedObjectID class for the GNUstep
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

#ifndef _NSManagedObjectID_h_
#define _NSManagedObjectID_h_

#import <Foundation/NSObject.h>

@class NSURL;
@class NSEntityDescription;
@class GSPersistentStore;

@interface NSManagedObjectID : NSObject <NSCopying>
{
  NSEntityDescription * _entity;
  GSPersistentStore * _persistentStore;
  unsigned long long _value;
}

- (NSEntityDescription *) entity;
- (BOOL) isTemporaryID;
- (id) persistentStore;
- (NSURL *) URIRepresentation;

@end

#endif // _NSManagedObjectID_h_
