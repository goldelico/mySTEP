/* Implementation of the NSManagedObject class for the GNUstep
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

/**
 * Finds out whether the passed object is a collection object.
 *
 * @return YES if the given object is a collection object (such as
 * an array, a set, etc.), and NO otherwise.
 */
static inline BOOL
IsCollection(id object)
{
  if ([object isKindOfClass: [NSSet class]] ||
      [object isKindOfClass: [NSArray class]])
    {
      return YES;
    }
  else
    {
      return NO;
    }
}

/**
 * Takes the ``errors'' array of NSError objects and does the following:
 * - If there is a single error in it, it sets ``target'' to point to
 *   to that error.
 * - If there are several, they are all complexly grouped into a new
 *   error to which ``target'' is then set. The rules by which the complex
 *   error is constructed are discussed in ``-validateValue:forKey:error:''.
 */
static inline void
ConstructComplexError(NSError ** target, NSArray * errors)
{
  unsigned int errorCount = [errors count];

  if (errorCount == 1)
    {
      *target = [errors objectAtIndex: 0];
    }
  else if (errorCount > 1)
    {
      NSError * newError;
      NSDictionary * userInfo;

      userInfo = [NSDictionary
        dictionaryWithObject: [[errors copy] autorelease]
                      forKey: NSDetailedErrorsKey];
      newError = [NSError errorWithDomain: NSCoreDataErrorDomain
                                     code: NSValidationMultipleErrorsError
                                 userInfo: userInfo];

      *target = newError;
    }
}

/**
 * Validates whether ``value'' is a valid value for ``attribute'',
 * returning YES if it is, and NO if it isn't and setting the
 * error in ``error''.
 */
/*
static BOOL
ValidateAttributeValue(NSAttributeDescription * attribute,
                       id value,
                       NSError ** error)
{
  Class attrClass = NSClassFromString([attribute attributeValueClassName]);

  // check the class is correct
  if ([value isKindOfClass: attrClass] == NO)
    {
      NSDictionary * userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        self, NSValidationObjectErrorKey,
        [attr name], NSValidationKeyErrorKey,
        value, NSValidationValueErrorKey,
        nil];

      SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationValueOfIncorrectClassError
                   userInfo: userInfo]);

      return NO;
    }

  return YES;
}
*/

/**
 * Does a simmilar job as ValidationAttributeValue, but for relationships.
 */
/*
static BOOL
ValidateRelationshipValue(NSRelationshipDescription * relationship,
                          id value,
                          NSError ** error)
  NSEntityDescription * destEntity = [relationship destinationEntity];
  Class managedObjectClass = [NSManagedObject class];
  NSDictionary * errorUserInfo = [NSDictionary dictionaryWithObjectsAndKeys:
    self, NSValidationObjectErrorKey,
    [relationship name], NSValidationKeyErrorKey,
    value, NSValidationValueErrorKey,
    nil];

  // if the relationship is a to-many relationship and the passed
  // object is a collection, check that all contained objects are
  // NSManagedObject's and have the correct entity set.
  if ([rel isToMany] && IsCollection(value))
    {
      NSEnumerator * e;
      id obj;
      int count;

      // make sure correct cardinality is kept
      count = [value count];
      if (count < [rel minCount])
        {
          SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationRelationshipLacksMinimumCountError
                   userInfo: errorUserInfo]);

          return NO;
        }
      if (count > [rel maxCount])
        {
          SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationRelationshipExceedsMaximumCountError
                   userInfo: errorUserInfo]);

          return NO;
        }

      e = [value objectEnumerator];
      while ((obj = [e nextObject]) != nil)
        {
          if ([obj isKindOfClass: managedObjectClass] == NO)
            {
              SetNonNullError(error, [NSError
                errorWithDomain: NSCoreDataErrorDomain
                           code: NSValidationValueOfIncorrectClassError
                       userInfo: errorUserInfo]);

              return NO;
            }
          if ([[obj entity] _isSubentityOf: destEntity] == NO)
            {
              SetNonNullError(error, [NSError
                errorWithDomain: NSCoreDataErrorDomain
                           code: NSValidationValueHasIncorrectEntityError
                       userInfo: errorUserInfo]);

              return NO;
            }
        }
    }
  // otherwise, check the value is an NSManagedObject itself
  else if ([value isKindOfClass: managedObjectClass])
    {
      // make sure correct cardinality is kept
      if ([rel minCount] > 1)
        {
          SetNonNullError(error, [NSError
                errorWithDomain: NSCoreDataErrorDomain
                           code: NSValidationRelationshipLacksMinimumCountError
                       userInfo: errorUserInfo]);

          return NO;
        }
      if ([rel maxCount] < 1)
        {
          SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationRelationshipExceedsMaximumCountError
                   userInfo: errorUserInfo]);

          return NO;
        }

      if ([[value entity] _isSubentityOf: destEntity] == NO)
        {
          SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationValueHasIncorrectEntityError
                   userInfo: errorUserInfo]);

          return NO;
        }
    }
  // otherwise fail - incorrect value type
  else
    {
      SetNonNullError(error, [NSError
        errorWithDomain: NSCoreDataErrorDomain
                   code: NSValidationValueOfIncorrectClassError
               userInfo: errorUserInfo]);

      return NO;
    }
}*/

/**
 * Instances of NSManagedObject (and subclasses of it) are the objects
 * of principal concern in Core Data. They serve as the primary data
 * objects in your Core Data data model.
 *
 * For more efficient functioning Core Data allows for "fault" objects,
 * i.e. managed objects which don't contain any of their key-values set.
 * Upon requesting or setting some key's value the fault is "fired"
 * and the managed object's state is read from the persistent store.
 * Methods do cause fault firing are explicitly noted as such.
 */
@implementation NSManagedObject

+ (BOOL) automaticallyNotifiesObserversForKey: (NSString *) aKey
{
  return NO;
}

- (void) dealloc
{
  TEST_RELEASE(_entity);
  TEST_RELEASE(_objectID);
  TEST_RELEASE(_changedValues);
  TEST_RELEASE(_data);

  [super dealloc];
}

/**
 * The designated initializer for NSManagedObject.
 *
 * This method initializes a managed object and inserts it into `aContext'.
 * The provided `anEntity' argument must be a non-abstract entity,
 * otherwise an exception is thrown.
 *
 * @return The receiver of the message.
 */
- (id)            initWithEntity: (NSEntityDescription *) entity
  insertIntoManagedObjectContext: (NSManagedObjectContext *) ctxt
{
  if ((self = [super init]))
    {
      if ([entity isAbstract])
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Tried to initialize a managed object "
                                @"from an abstract entity (%@)."),
            [entity name]];
        }

      ASSIGN(_entity, entity);

      [ctxt insertObject: self];

    }
	return self;
}

/**
 * Returns the managed object context to which the receiver belongs.
 * Doesn't fire a fault.
 */
- (NSManagedObjectContext *) managedObjectContext
{
  return _context;
}

/**
 * Returns the entity of the receiver. Doesn't fire a fault.
 */
- (NSEntityDescription *) entity
{
  return _entity;
}

/**
 * Returns the object ID of the receiver. If the receiver is not
 * yet saved to a persistent store the returned ID is temporary,
 * otherwise it is permanent. Doesn't fire a fault.
 */
- (NSManagedObjectID *) objectID
{
  // get a new temporary object ID, if necessary
  if (_objectID == nil)
    {
      _objectID = [[NSManagedObjectID alloc] _initWithEntity: _entity];
    }

  return _objectID;
}

/**
 * Returns YES if the receiver is inserted in a managed object context, and
 * NO otherwise. Doesn't fire a fault.
 */
- (BOOL) isInserted
{
  return [[_context insertedObjects] containsObject: self];
}

/**
 * Returns YES if the receiver has changes that have not yet been written
 * to a persistent store (the receiver has been changed since the last
 * save operation). Doesn't fire a fault.
 */
- (BOOL) isUpdated
{
  return [[_context updatedObjects] containsObject: self];
}

/**
 * Returns YES if the receiver has been scheduled in it's parent managed
 * object context for deletion from the persistent store and NO otherwise.
 * Doesn't fire a fault.
 */
- (BOOL) isDeleted
{
  return _isDeleted;
}

/**
 * Returns YES if the receiver is a fault, and NO otherwise. Doesn't fire
 * a fault.
 */
- (BOOL) isFault
{
  return _isFault;
}

/**
 * Invoked automatically after the receiver has been fetched from
 * a persistent store. You can use this to compute derived values
 * - in that case, use -setPrimitiveValue:forKey: to set the changes.
 */
- (void) awakeFromFetch
{}

/**
 * Invoked automatically after the receiver has been inserted into
 * a managed object context.
 */
- (void) awakeFromInsert
{}

- (NSDictionary *) changedValues
{
  return [[_changedValues copy] autorelease];
}

- (void) willSave
{}

- (void) didSave
{}

- (void) didTurnIntoFault
{}

/**
 * Returns the value for key `aKey' and invokes corresponding KVO methods.
 */
- (id) valueForKey: (NSString *) key
{
  id value;

  // just makes sure the key is valid
  [self _validatedPropertyForKey: key];

  [self willAccessValueForKey: key];
  value = [self _primitiveValueForKey: key doValidation: NO];
  [self didAccessValueForKey: key];

  return value;
}

/**
 * Sets the value of key `aKey' to `aValue' and invokes corresponding
 * KVO methods.
 */
- (void) setValue: (id) value
           forKey: (NSString *) key
{
  NSPropertyDescription * property;

  property = [self _validatedPropertyForKey: key];
  if ([self _validateValue: &value
                    forKey: key
                     error: NULL
                  property: property] == NO)
    {
      [NSException raise: NSInvalidArgumentException
                  format: _(@"Invalid value for key %@ specified."), key];
    }

  [self willChangeValueForKey: key];
  [self _setPrimitiveValue: value forKey: key doValidation: NO];
  [self didChangeValueForKey: key];
}

/**
 * Returns the value for key `aKey' without invoking KVO methods.
 */
- (id) primitiveValueForKey: (NSString *) key
{
  return [self _primitiveValueForKey: key doValidation: YES];
}

/**
 * Sets the value for key `aKey' without invoking KVO methods.
 */
- (void) setPrimitiveValue: (id) value
                    forKey: (NSString *) key
{
  // Validate the value - internal methods invoke the internal method
  // explicitly, so this method is invoked only by external code from
  // which proper validation can't be expected.
  [self _setPrimitiveValue: value forKey: key doValidation: YES];
}

// Validation

- (BOOL) validateValue: (id *) value
                forKey: (NSString *) key
                 error: (NSError **) error
{
  return [self _validateValue: value
                       forKey: key
                        error: error
                     property: [self _validatedPropertyForKey: key]];
}

/**
 * Validates whether the receiver can be deleted in it's present state
 * from the managed object context returning YES if it can or NO if it
 * can't. Deleting an object is not allowed if it, for example, contains
 * an established relationship with a "deny" delete rule.
 */
- (BOOL) validateForDelete: (NSError **) error
{
  NSEnumerator * e;
  NSRelationshipDescription * rel;
  NSMutableArray * errors = [NSMutableArray array];

  e = [[self _allPropertiesOfSubclass: [NSRelationshipDescription class]]
    objectEnumerator];
  while ((rel = [e nextObject]) != nil)
    {
      NSString * key = [rel name];
      id value = [self _primitiveValueForKey: key doValidation: NO];

      if ([rel deleteRule] == NSDenyDeleteRule &&
        (([rel isToMany] && value != nil && [value count] != 0) ||
        (value != nil)))
        {
          if (error == NULL)
            {
              return NO;
            }
          else
            {
              NSError * localError;
              NSDictionary * userInfo;

              userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                value, NSValidationValueErrorKey,
                key,   NSValidationKeyErrorKey,
                nil];
              localError = [NSError
                errorWithDomain: NSCoreDataErrorDomain
                           code: NSValidationRelationshipDeniedDeleteError
                       userInfo: userInfo];

              [errors addObject: localError];
            }
        }
    }

  if ([errors count] > 0)
    {
      ConstructComplexError(error, errors);

      return NO;
    }
  else
    {
      return YES;
    }
}

- (BOOL) validateForInsert: (NSError **) error
{
  // NB. What is this method actually supposed to do??

  return YES;
}

- (BOOL) validateForUpdate: (NSError **) error
{
  NSEnumerator * e;
  NSPropertyDescription * property;
  NSMutableArray * errors = [NSMutableArray array];

  e = [[self _allPropertiesOfSubclass: [NSPropertyDescription class]]
    objectEnumerator];
  while ((property = [e nextObject]) != nil)
    {
      NSString * key = [property name];
      id value = [self _primitiveValueForKey: key
                                doValidation: NO];
      NSError * localError;

      if ([self _validateValue: &value
                        forKey: key
                         error: &localError
                      property: property] == NO)
        {
          // if no errors are requested, stop at the first one
          if (error == NULL)
            {
              return NO;
            }
          else
            {
              [errors addObject: localError];
            }
        }
    }

  if ([errors count] > 0)
    {
      ConstructComplexError(error, errors);

      return NO;
    }
  else
    {
      return YES;
    }
}

// Key-value observing

- (void) didAccessValueForKey: (NSString *) key
{
}

- (void) didChangeValueForKey: (NSString *) key
{
  [super didChangeValueForKey: key];
}

- (void) didChangeValueForKey: (NSString *) key
              withSetMutation: (NSKeyValueSetMutationKind) mutationKind
                 usingObjects: (NSSet *) objects
{
  [super didChangeValueForKey: key
              withSetMutation: mutationKind
                 usingObjects: objects];
}

- (void *) observationInfo
{
  return [super observationInfo];
}

- (void) setObservationInfo: (void *) info
{
  [super setObservationInfo: info];
}

- (void) willAccessValueForKey: (NSString *) key
{
}

- (void) willChangeValueForKey: (NSString *) key
{
  [super willChangeValueForKey: key];
}

- (void) willChangeValueForKey: (NSString *) key
               withSetMutation: (NSKeyValueSetMutationKind) mutationKind
                  usingObjects: (NSSet *) objects
{
  [super willChangeValueForKey: key
               withSetMutation: mutationKind
                  usingObjects: objects];
}


/**
 * Allows to initialize a managed object with explicitly defining whether
 * the object is to `insert' itself into the passed managed object context
 * or just silently create a back-reference to it. This is, for example,
 * required when an object is created when it is fetched.
 */
- (id) _initAsFaultWithEntity: (NSEntityDescription *) entity
               ownedByContext: (NSManagedObjectContext *) context
{
	if ((self = [super init]))
    {
      if ([entity isAbstract])
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Tried to initialize a managed object "
                                @"from an abstract entity (%@)."),
            [entity name]];
        }

      ASSIGN(_entity, entity);

      _context = context;
      _isFault = YES;
	}
	return self;
 }

/**
 * Sets the managed object ID of the receiver. This used when
 * the receiver is fetched from a persistent store, stored to
 * one or assigned to another one.
 *
 * Only a permanent object ID can be assigned - temporary ones will
 * cause an assertion failure.
 */
- (void) _setObjectID: (NSManagedObjectID *) newID
{
  NSAssert([newID isTemporaryID] == NO, _(@"Tried to assign to a managed "
    @"object a temporary object ID."));

  ASSIGN(_objectID, newID);
}

/**
 * Allows the managed object context to manipulate the object's flag
 * when it is inserted/deleted from it.
 */
- (void) _setDeleted: (BOOL) flag
{
  _isDeleted = flag;
}

/**
 * Allows the managed object context to manually set whether an object
 * is fault or not. This is required when fault objects are created.
 */
- (void) _setFault: (BOOL) flag
{
  _isFault = flag;
}

/**
 * Sets the inverse weak-reference from the receiver to it's parent
 * managed object context. Trying to reassign it to a different
 * context will cause an assertion failure.
 */
- (void) _insertedIntoContext: (NSManagedObjectContext *) ctxt
{
  NSAssert(_context == nil || _context == ctxt, _(@"Tried to re-insert a "
    @"managed object into different managed object context."));

  _context = ctxt;
}

/**
 * This method is invoked when the object is removed from it's managed
 * object context. It removes the weak-reference to the context and
 * makes subsequent attempts to fire a fault on this object cause an
 * error.
 *
 * Invoking it multiple times causes an assertion failure.
 */
- (void) _removedFromContext
{
  NSAssert(_context != nil, _(@"Attempted to remove from a context an "
    @"already removed managed object."));

  _context = nil;
}

/**
 * Ensures the given key is valid (it exists in the data model).
 *
 * @return The property description for the key if the key is
 * valid. If it isn't it raises an NSInvalidArgumentException.
 */
- (NSPropertyDescription *) _validatedPropertyForKey: (NSString *) key
{
  NSPropertyDescription * desc = nil;
  NSEntityDescription * entity;

  // Look for the property by name, running upwards through the
  // entity hierarchy if necessary.
  for (entity = _entity;
       desc == nil && entity != nil;
       entity = [entity superentity])
    {
      desc = [[entity propertiesByName] objectForKey: key];
    }

  if (desc != nil)
    {
      return desc;
    }
  else
    {
      [NSException raise: NSInvalidArgumentException //NSUnknownKeyException
                  format: _(@"Invalid key specified. The key does not "
                            @"exist in the model.")];

      return nil;
    }
}

/**
 * Returns an array containing all properties of the associated entity (and
 * superentities) of a specific subclass.
 */
- (NSArray *) _allPropertiesOfSubclass: (Class) aClass
{
  NSMutableArray * properties;
  NSEntityDescription * entity;

  NSAssert(aClass != nil, _(@"Nil class argument."));

  properties = [NSMutableArray array];

  for (entity = _entity; entity != nil; entity = [entity superentity])
    {
      NSEnumerator * e;
      NSPropertyDescription * property;

      e = [[entity properties] objectEnumerator];
      while ((property = [e nextObject]) != nil)
        {
          if ([property isKindOfClass: aClass])
            {
              [properties addObject: property];
            }
        }
    }

  return [[properties copy] autorelease];
}

/**
 * Does the actual validation. This special version is used
 * by internal methods that already know the property description
 * to use - this is to avoid searching the entity hierarchy again
 * and improve perfomance.
 *
 * @return YES if the value is valid and NO otherwise. If the value
 * isn't valid also the ``error'' argument is filled with a detailed
 * error description.
 */
// TODO - finish this method. Validation is partially broken until
// we have predicate support in Foundation.
- (BOOL) _validateValue: (id *) val
                 forKey: (NSString *) key
                  error: (NSError **) error
               property: (NSPropertyDescription *) property
{
  id value = *val;
  SEL customValidationSel;

  // TODO - use predicates to validate the value

  if (value != nil)
    {
/*      if ([desc isKindOfClass: [NSAttributeDescription class]])
        {
          if (ValidateAttributeValue((NSAttributeDescription *) desc,
            value, error) == NO)
            {
              return NO;
            }
        }
      else if ([desc isKindOfClass: [NSRelationshipDescription class]])
        {
          if (ValidateRelationshipValue((NSRelationshipDescription *) desc,
            value, error) == NO)
            {
              return NO;
            }
      else
        {
          [NSException raise: NSInternalInconsistencyException
                      format: _(@"Passed non-attribute, non-relationship "
                                @"property description to internal validation "
                                @"method.")];
        }*/
    }
  // if `nil' is specified, the property must be optional
  else
    {
      if ([property isOptional] == NO)
        {
          SetNonNullError(error, [NSError
            errorWithDomain: NSCoreDataErrorDomain
                       code: NSValidationMissingMandatoryPropertyError
                   userInfo: [NSDictionary dictionaryWithObjectsAndKeys:
            self, NSValidationObjectErrorKey,
            key, NSValidationKeyErrorKey,
            nil]]);

          return NO;
        }
    }

  // now do the customizable "validate<Key>:error:" validation
  customValidationSel = NSSelectorFromString([NSString stringWithFormat:
    @"validate%@:error:", key]);
  if ([self respondsToSelector: customValidationSel])
    {
      BOOL retval;
      NSInvocation * invocation = [[NSInvocation new] autorelease];

      [invocation setTarget: self];
      [invocation setSelector: customValidationSel];
      [invocation setArgument: &value
                      atIndex: 2];
      [invocation setArgument: &error
                      atIndex: 3];
      [invocation invoke];
      [invocation getReturnValue: &retval];

      return retval;
    }
  else
    {
      return YES;
    }
}

/**
 * Primitive accessor method. This method has an additional argument
 * that specifies whether the provided key needs validation or not.
 * Internal methods which already did the validation set this flag to
 * NO in order to save execution time.
 */
- (id) _primitiveValueForKey: (NSString *) key doValidation: (BOOL) validate
{
  if (validate == YES)
    {
      [self _validatedPropertyForKey: key];
    }
  if (_isFault)
    {
      [self _fireFault];
    }

  return [_data objectForKey: key];
}

/**
 * Performs the actual setting of the primitive value. This method
 * allows invocations from internal methods (such as "-setValue:forKey:")
 * which have already done validation of the value. They invoke this
 * method telling it not to do any more unnecessary validation
 * (which can be expensive). On the other hand, "-setPrimitiveValue:forKey:"
 * invoke this method and request validation, since they are invoked only
 * from external code.
 */
- (void) _setPrimitiveValue: (id) value
                     forKey: (NSString *) key
               doValidation: (BOOL) validate
{
  NSPropertyDescription * property;
  NSError * error;

  property = [self _validatedPropertyForKey: key];

  // validate the value if requested
  if (validate)
    {
      if ([self _validateValue: &value
                        forKey: key
                         error: &error
                      property: property] != YES)
        {
          [NSException raise: NSInvalidArgumentException
                      format: _(@"Invalid value for key \"%@\" specified."),
            key];
        }
    }

  if (_isFault)
    {
      [self _fireFault];
    }

  [_data setObject: value forKey: key];

  if ([property isTransient] == NO)
    {
      if (_changedValues == nil)
        {
          _changedValues = [NSMutableDictionary new];
        }
      [_changedValues setObject: value forKey: key];
    }
}

@end
