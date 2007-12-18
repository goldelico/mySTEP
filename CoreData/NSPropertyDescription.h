/* Interface of the NSPropertyDescription class for the GNUstep
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

#ifndef _NSPropertyDescription_h_
#define _NSPropertyDescription_h_

#import <Foundation/NSObject.h>

@class NSstring, NSDictionary, NSArray;
@class NSEntityDescription;

@interface NSPropertyDescription : NSObject <NSCopying, NSCoding>
{
  NSString * _name;
  // a weak reference
  NSEntityDescription * _entity;
  BOOL _optional,
       _transient;
  NSDictionary * _userInfo;

  NSArray * _validationPredicates;
  NSArray * _validationWarnings;
}

- (NSEntityDescription *) entity;
- (BOOL) isOptional;
- (BOOL) isTransient;
- (NSString *) name;
- (void) setName: (NSString *) aName;
- (void) setOptional: (BOOL) flag;
- (void) setTransient: (BOOL) flag;
- (void) setUserInfo: (NSDictionary *) someUserInfo;
- (void) setValidationPredicates: (NSArray *) someValidationPredicates
          withValidationWarnings: (NSArray *) someValidationWarnings;
- (NSDictionary *) userInfo;
- (NSArray *) validationPredicates;
- (NSArray *) validationWarnings;

@end

#endif // _NSPropertyDescription_h_
