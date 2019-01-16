/* Interface of the NSFetchedPropertyDescription class for the GNUstep
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

#ifndef _NSFetchedPropertyDescription_h_
#define _NSFetchedPropertyDescription_h_

#import <CoreData/NSPropertyDescription.h>

@class NSFetchRequest;

@interface NSFetchedPropertyDescription : NSPropertyDescription <NSCoding>
{
  NSFetchRequest * _fetchRequest;
}

- (NSFetchRequest *) fetchRequest;
- (void) setFetchRequest: (NSFetchRequest *) aFetchRequest;

@end

#endif // _NSFetchedPropertyDescription_h_
