/* Error constant declarations for the GNUstep Core Data framework.
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

#ifndef _CoreDataErrors_h_
#define _CoreDataErrors_h_

@class NSString;

extern NSString * const NSCoreDataErrorDomain;

// Error user info dictionary keys in CoreData errors.
extern NSString * const NSDetailedErrorsKey;
extern NSString * const NSValidationObjectErrorKey;
extern NSString * const NSValidationKeyErrorKey;
extern NSString * const NSValidationPredicateErrorKey;
extern NSString * const NSValidationValueErrorKey;
extern NSString * const NSAffectedStoresErrorKey; 
extern NSString * const NSAffectedObjectsErrorKey;

// Core data error codes.
enum {
   /**
    * GNUstep Core Data addition. Set when the value of an attribute isn't
    * of the correct class, as dictated by the attribute description, or if
    * the contents of a relationship isn't an instance of NSManagedObject.
    */
  NSValidationValueOfIncorrectClassError           = 10000000,
   /**
    * GNUstep Core Data addition. Set when the value of a relationship
    * doesn't have the correct entity, as dictated by the relationship
    * description.
    */
  NSValidationValueHasIncorrectEntityError         = 10000010,

  NSManagedObjectValidationError                   = 1550,
  NSValidationMultipleErrorsError                  = 1560,
  NSValidationMissingMandatoryPropertyError        = 1570,
  NSValidationRelationshipLacksMinimumCountError   = 1580,
  NSValidationRelationshipExceedsMaximumCountError = 1590,
  NSValidationRelationshipDeniedDeleteError        = 1600,
  NSValidationNumberTooLargeError                  = 1610,
  NSValidationNumberTooSmallError                  = 1620,
  NSValidationDateTooLateError                     = 1630,
  NSValidationDateTooSoonError                     = 1640,
  NSValidationInvalidDateError                     = 1650,
  NSValidationStringTooLongError                   = 1660,
  NSValidationStringTooShortError                  = 1670,
  NSValidationStringPatternMatchingError           = 1680,
  NSManagedObjectContextLockingError               = 132000,
  NSPersistentStoreCoordinatorLockingError         = 132010,
  NSManagedObjectReferentialIntegrityError         = 133000,
  NSManagedObjectExternalRelationshipError         = 133010,
  NSManagedObjectMergeError                        = 133020,
  NSPersistentStoreInvalidTypeError                = 134000,
  NSPersistentStoreTypeMismatchError               = 134010,
  NSPersistentStoreIncompatibleSchemaError         = 134020,
  NSPersistentStoreSaveError                       = 134030,
  NSPersistentStoreIncompleteSaveError             = 134040,
  /**
   * GNUstep Core Data addition. Occurs when a store is added but it's
   * initialization fails.
   */
  NSPersistentStoreInitializationError             = 10100000
};

#endif // _CoreDataErrors_h_
