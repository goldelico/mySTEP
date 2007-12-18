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

#import <CoreData/CoreData.h>
#import "CoreDataUtilities.h"

@interface NSAttributeDescription (GSCoreDataPrivate)

- (void) _setAttributeValueClassName: (NSString *) aClassName;

@end

@interface NSPropertyDescription (GSCoreDataPrivate)

- (void) _setEntity: (NSEntityDescription *) entity;
- (void) _ensureEditableWithReason: (NSString *) aReason;

@end

@interface NSEntityDescription (GSCoreDataPrivate)

- (void) _addReferenceToManagedObjectModel: (NSManagedObjectModel *) aModel;
- (NSDictionary *) _fetchedPropertiesByName;
- (void) _removeReferenceToManagedObjectModel: (NSManagedObjectModel *) aModel;
- (void) _setSuperentity: (NSEntityDescription *) anEntityDescription;	// private

@end

@interface NSManagedObject (GSCoreDataPrivate)

- (id) _initAsFaultWithEntity: (NSEntityDescription *) entity
               ownedByContext: (NSManagedObjectContext *) context;

- (void) _setObjectID: (NSManagedObjectID *) newID;

- (void) _setDeleted: (BOOL) flag;
- (void) _setFault: (BOOL) flag;

- (void) _insertedIntoContext: (NSManagedObjectContext *) context;
- (void) _removedFromContext;

@end

@interface NSManagedObjectID (GSCoreDataPrivate)

- (BOOL) _isEqualToManagedObjectID: (NSManagedObjectID *) otherID;

	// initializes a temporary ID
- (id) _initWithEntity: (NSEntityDescription *) entity;

	// initializes a permanent ID
- (id) _initWithEntity: (NSEntityDescription *) entity
       persistentStore: (GSPersistentStore *) persistentStore
                 value: (unsigned long long) value;

	// returns the ID's value
- (unsigned long long) _value;

@end


@interface NSManagedObjectModel (GSCoreDataPrivate)

#ifndef NO_GNUSTEP
// Convenience method.
- (id) _initWithContentsOfFile: (NSString *) aFilePath;
#endif

#ifndef NO_GNUSTEP
- (NSDictionary *) _entitiesByNameForConfiguration: (NSString *) aConfiguration;
#endif

#ifndef NO_GNUSTEP
	// returns all configurations bound to their respective names in this model.
- (NSDictionary *) _configurationsByName;
#endif
#ifndef NO_GNUSTEP

- (void) _removeFetchRequestTemplateForName: (NSString *) aName;

	// returns all fetch requests bound to their respective names in this model.
- (NSDictionary *) _fetchRequestsByName;
#endif

#ifndef NO_GNUSTEP

	/**
	* Returns YES if the model is not associated with a persistent store
	 * coordinator (and thus is editable), and NO if it is (and thus isn't
															* editable.
															*
															* Before trying to change any part of the model you should first use
															* this method to make sure it is editable, because any attempt to mutate
															* a non-editable model will result in an exception being raised.
															*/
- (BOOL) _isEditable;

#endif

- (void) _incrementUseCount;

- (void) _decrementUseCount;

@end

@interface NSPersistentStoreCoordinator (GSCoreDataPrivate)

#ifndef NO_GNUSTEP

/**
* With this you can teach Core Data about new stores types at runtime.
 * The provided class must be a subclass of GSPersistentStore, otherwise
 * an NSInvalidArgumentException is thrown.
 *
 * The method emmits a warning if you try to replace an already defined
 * store type with a different class.
 */
+ (void) _addPersistentStoreType: (NSString *) newStoreType
				  handledByClass: (Class) aClass;

	/**
	* Returns the store types which Core Data knows about.
	 */
+ (NSArray *) _supportedPersistentStoreTypes;

#endif // NO_GNUSTEP

@end



