/*
	NSObjectController.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
	Copyright (c) 2005 DSITRI.

	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	14. November 2007 - aligned with 10.5 
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSObjectController
#define _mySTEP_H_NSObjectController

#import "AppKit/NSController.h"
#import "AppKit/NSMenuItem.h"
#import "AppKit/NSUserInterfaceValidation.h"

@class NSString;
@class NSCoder;
@class NSFetchRequest; 
@class NSManagedObjectContext; 

@interface NSObjectController : NSController <NSCoding>
{
	@private
	Class _objectClass;
	id _content;
	NSMutableArray *_selection;
	BOOL _isEditable;
	BOOL _automaticallyPreparesContent;
	// ??? really BOOL flags
	BOOL _canAdd;
	BOOL _canRemove;
}

- (void) add:(id) sender;
- (void) addObject:(id) obj;
- (BOOL) automaticallyPreparesContent;
- (BOOL) canAdd;
- (BOOL) canRemove;
- (id) content;
- (NSFetchRequest *) defaultFetchRequest; 
- (NSString *) entityName; 
- (void) fetch:(id) sender; 
- (NSPredicate *) fetchPredicate; 
- (BOOL) fetchWithRequest:(NSFetchRequest *) fetchReq merge:(BOOL) flag error:(NSError **) err; 
- (id) initWithContent:(id) content;
- (BOOL) isEditable;
- (NSManagedObjectContext *) managedObjectContext; 
- (id) newObject;
- (Class) objectClass;
- (void) prepareContent;
- (void) remove:(id) sender;
- (void) removeObject:(id) obj;
- (NSArray *) selectedObjects;
- (id) selection;
- (void) setAutomaticallyPreparesContent:(BOOL) flag;
- (void) setContent:(id) content;
- (void) setEditable:(BOOL) flag;
- (void) setEntityName:(NSString *) name; 
- (void) setFetchPredicate:(NSPredicate *) fetchPred; 
- (void) setManagedObjectContext:(NSManagedObjectContext *) moc; 
- (void) setObjectClass:(Class) class;
- (void) setUsesLazyFetching:(BOOL) flag; 
- (BOOL) usesLazyFetching; 
- (BOOL) validateMenuItem:(id <NSMenuItem>) item;
- (BOOL) validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>) uiItem; 

@end

#endif /* _mySTEP_H_NSObjectController */
