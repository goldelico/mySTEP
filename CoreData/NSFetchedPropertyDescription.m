/* Implementation of the NSFetchedPropertyDescription class for the GNUstep
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

@implementation NSFetchedPropertyDescription

- (void) dealloc
{
  TEST_RELEASE(_fetchRequest);

  [super dealloc];
}

/**
 * Returns the fetch request of the receiver. See also
 * -[NSFetchedPropertyDescription setFetchRequest:].
 */
- (NSFetchRequest *) fetchRequest
{
  return _fetchRequest;
}

/**
 * Sets the fetch request of the receiver.
 */
- (void) setFetchRequest: (NSFetchRequest *) request
{
  [self _ensureEditableWithReason: _(@"Tried to set the fetch request "
                                     @"of a fetched property already in use")];

  ASSIGN(_fetchRequest, request);
}

- (id) initWithCoder: (NSCoder *) coder
{
	if ((self = [super initWithCoder: coder]))
    {
      if ([coder allowsKeyedCoding])
        {
          ASSIGN(_fetchRequest, [coder decodeObjectForKey: @"FetchRequest"]);
        }
      else
        {
          ASSIGN(_fetchRequest, [coder decodeObject]);
        }
	}
	return self;
 }

- (void) encodeWithCoder: (NSCoder *) coder
{
  if ([coder allowsKeyedCoding])
    {
      [coder encodeObject: _fetchRequest forKey: @"FetchRequest"];
    }
  else
    {
      [coder encodeObject: _fetchRequest];
    }
}

@end
