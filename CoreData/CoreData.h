/* Main include file of the GNUstep Core Data framework.
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

#ifndef _CoreData_h_
#define _CoreData_h_

#include <Foundation/Foundation.h>

#include <CoreData/CoreDataErrors.h>
#include <CoreData/NSAttributeDescription.h>
#include <CoreData/NSEntityDescription.h>
#include <CoreData/NSFetchRequest.h>
#include <CoreData/NSFetchedPropertyDescription.h>
#include <CoreData/NSManagedObject.h>
#include <CoreData/NSManagedObjectContext.h>
#include <CoreData/NSManagedObjectID.h>
#include <CoreData/NSManagedObjectModel.h>
#include <CoreData/NSPersistentStoreCoordinator.h>
#include <CoreData/NSPropertyDescription.h>
#include <CoreData/NSRelationshipDescription.h>

#ifndef ASSIGN
#define ASSIGN(VAR, VAL) [(VAR) autorelease], (VAR)=[(VAL) retain]
#endif
#ifndef DESTROY
#define DESTROY(VAR) [(VAR) release], (VAR)=nil
#endif
#ifndef TEST_RELEASE
#define TEST_RELEASE(VAR) if(VAR) [(VAR) release]
#endif
#ifndef _
#define _(STR) STR
#endif

#endif // _CoreData_h_
