//
//  NSController.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import "AppKit/NSController.h"
#import "AppKit/NSArrayController.h"
#import "AppKit/NSObjectController.h"
#import "AppKit/NSTreeController.h"
#import "AppKit/NSUserDefaultsController.h"

@interface _NSManagedProxy : NSObject	// object loaded by NSObjectController
@end

@implementation _NSManagedProxy

- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if(![aDecoder allowsKeyedCoding])
		{ [self release]; return nil; }
	return self;
}

@end

@implementation NSController

- (BOOL) commitEditing; { SUBCLASS; return NO; }
- (void) discardEditing; { SUBCLASS; }
- (BOOL) isEditing; { SUBCLASS; return NO; }
- (void) objectDidBeginEditing:(id) editor; { SUBCLASS; }
- (void) objectDidEndEditing:(id) editor; { SUBCLASS; }

- (id) copyWithZone:(NSZone *) zone { return SUBCLASS; }
- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }
- (id) initWithCoder:(NSCoder *) aDecoder { return self; }

@end

@implementation NSArrayController

- (void) addObject:(id) obj; { NIMP; }
- (void) addObjects:(NSArray *) obj; { NIMP; }
- (BOOL) addSelectedObjects:(NSArray *) obj; { NIMP; return NO; }
- (BOOL) addSelectionIndexes:(NSIndexSet *) idx; { NIMP; return NO; }
- (NSArray *) arrangeObjects:(NSArray *) obj; { return NIMP; }
- (id) arrangedObjects; { return NIMP; }
- (BOOL) avoidsEmptySelection; { NIMP; return NO; }
- (BOOL) canInsert; { NIMP; return NO; }
- (BOOL) canSelectNext; { NIMP; return NO; }
- (BOOL) canSelectPrevious; { NIMP; return NO;}
- (void) insert:(id) Sender; { NIMP; }
- (void) insertObject:(id) obj atArrangedObjectIndex:(unsigned int) idx; { NIMP; }
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexes:(NSIndexSet *) idx; { NIMP; }
- (BOOL) preservesSelection; { NIMP; return NO;}
- (void) rearrangeObjects; { NIMP; }
- (void) remove:(id) Sender; { NIMP; }
- (void) removeObject:(id) obj; { NIMP; }
- (void) removeObjectAtArrangedObjectIndex:(unsigned int) idx; { NIMP; }
- (void) removeObjects:(NSArray *) obj; { NIMP; }
- (void) removeObjectsAtArrangedObjectIndexes:(NSIndexSet *) idx; { NIMP; }
- (BOOL) removeSelectedObjects:(NSArray *) obj; { NIMP; return NO;}
- (BOOL) removeSelectionIndexes:(NSIndexSet *) idx; { NIMP; return NO;}
- (void) selectNext:(id) Sender; { NIMP; }
- (void) selectPrevious:(id) Sender; { NIMP; }
- (NSArray *) selectedObjects; { return NIMP; }
- (unsigned int) selectionIndex; { NIMP; return 0; }
- (NSIndexSet *) selectionIndexes; { return NIMP; }
- (BOOL) selectsInsertedObjects; { NIMP; return NO;}
- (void) setAvoidsEmptySelection:(BOOL) flag; { NIMP; }
- (void) setPreservesSelection:(BOOL) flag; { NIMP; }
- (BOOL) setSelectedObjects:(NSArray *) obj; { NIMP; return NO; }
- (BOOL) setSelectionIndex:(unsigned int) idx; { NIMP; return NO; }
- (BOOL) setSelectionIndexes:(NSIndexSet *) idx; { NIMP; return NO; }
- (void) setSelectsInsertedObjects:(BOOL) flag; { NIMP; }
- (void) setSortDescriptors:(NSArray *) desc; { NIMP; }
- (NSArray *) sortDescriptors; { return _sortDescriptors; }

- (id) copyWithZone:(NSZone *) zone { return [self retain]; }
- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }
- (id) initWithCoder:(NSCoder *) aDecoder { return self; }

@end

@implementation NSObjectController

- (void) add:(id) sender; { NIMP; }
- (void) addObject:(id) obj; { NIMP; }
- (BOOL) automaticallyPreparesContent; { return _automaticallyPreparesContent;}
- (BOOL) canAdd; { return _canAdd;}
- (BOOL) canRemove; { return _canRemove;}
- (id) content; { return _content; }
- (id) initWithContent:(id) content; { return NIMP; }
- (BOOL) isEditable; { return _isEditable; }
- (id) newObject; { return NIMP; }
- (Class) objectClass; { return _objectClass; }
- (void) prepareContent; { NIMP; }
- (void) remove:(id) sender; { NIMP; }
- (void) removeObject:(id) obj; { NIMP; }
- (NSArray *) selectedObjects; { return NIMP; }
- (id) selection; { return NIMP; }
- (void) setAutomaticallyPreparesContent:(BOOL) flag; { _automaticallyPreparesContent=flag; }
- (void) setContent:(id) content; { ASSIGN(_content, content); }
- (void) setEditable:(BOOL) flag; { _isEditable=flag; }
- (void) setObjectClass:(Class) class; { _objectClass=class; }
- (BOOL) validateMenuItem:(NSMenuItem *) item; { NIMP; return NO; }

- (id) copyWithZone:(NSZone *) zone { return [self retain]; }
- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }

- (id) initWithCoder:(NSCoder *) aDecoder
{
	if(![aDecoder allowsKeyedCoding])
		{ [self release]; return nil; }
	self=[super initWithCoder: aDecoder];
	_isEditable=[aDecoder decodeBoolForKey:@"NSEditable"];
	_objectClass=NSClassFromString([aDecoder decodeObjectForKey:@"NSObjectClassName"]);
	// FIXME: what to do with this from a NIB?
	[aDecoder decodeObjectForKey:@"NSDeclaredKeys"];
	[aDecoder decodeObjectForKey:@"_NSManagedProxy"];
	return self;
}

@end

@implementation NSTreeController

- (void) add:(id) Sender; { NIMP; }
- (void) addChild:(id) Sender; { NIMP; }
- (BOOL) addSelectionIndexPaths:(NSArray *) paths; { NIMP; return NO; }
- (BOOL) alwaysUsesMultipleValuesMarker; { NIMP; return NO; }
- (id) arrangedObjects; { return NIMP; }
- (BOOL) avoidsEmptySelection; { NIMP; return NO; }
- (BOOL) canAddChild; { NIMP; return NO; }
- (BOOL) canInsert; { NIMP; return NO; }
- (BOOL) canInsertChild; { NIMP; return NO; }
- (NSString *) childrenKeyPath; { return NIMP; }
- (NSString *) countKeyPath; { return NIMP; }
- (void) insert:(id) Sender; { NIMP; }
- (void) insertChild:(id) Sender; { NIMP; }
- (void) insertObject:(id) obj atArrangedObjectIndexPath:(NSIndexPath *) idx; { NIMP; }
- (void) insertObjects:(NSArray *) obj atArrangedObjectIndexPaths:(NSArray *) idx; { NIMP; }
- (NSString *) leafKeyPath; { return NIMP; }
- (BOOL) preservesSelection; { NIMP; return NO; }
- (void) rearrangeObjects; { NIMP; }
- (void) remove:(id) Sender; { NIMP; }
- (void) removeObject:(id) obj; { NIMP; }
- (void) removeObjectAtArrangedObjectIndexPath:(NSIndexPath *) idx; { NIMP; }
- (void) removeObjectsAtArrangedObjectIndexPaths:(NSArray *) idx; { NIMP; }
- (BOOL) removeSelectionIndexPaths:(NSArray *) obj; { NIMP; return NO; }
- (NSArray *) selectedObjects; { return NIMP; }
- (NSIndexPath *) selectionIndexPath; { return NIMP; }
- (NSIndexPath *) selectionIndexPaths; { return NIMP; }
- (BOOL) selectsInsertedObjects; { NIMP; return NO; }
- (void) setAlwaysUsesMultipleValuesMarker:(BOOL) flag; { NIMP; }
- (void) setAvoidsEmptySelection:(BOOL) flag; { NIMP; }
- (void) setChildrenKeyPath:(NSString *) key; { NIMP; }
- (void) setCountKeyPath:(NSString *) key; { NIMP; }
- (void) setLeafKeyPath:(NSString *) key; { NIMP; }
- (void) setPreservesSelection:(BOOL) flag; { NIMP; }
- (BOOL) setSelectionIndexPath:(NSIndexPath *) path; { NIMP; return NO; }
- (BOOL) setSelectionIndexPaths:(NSArray *) paths; { NIMP; return NO; }
- (void) setSelectsInsertedObjects:(BOOL) flag; { NIMP; }
- (void) setSortDescriptors:(NSArray *) desc; { NIMP; }
- (NSArray *) sortDescriptors; { return _sortDescriptors; }

- (id) copyWithZone:(NSZone *) zone { return [self retain]; }
- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }
- (id) initWithCoder:(NSCoder *) aDecoder { return self; }

@end

@implementation NSUserDefaultsController

+ (id) sharedUserDefaultsController; { static id _obj; if(!_obj) _obj=[[self alloc] initWithDefaults:nil initialValues:nil]; return _obj; }
- (BOOL) appliesImmediately; { return _appliesImmediately; }
- (NSUserDefaults *) defaults; { return _defaults; }
- (NSDictionary *) initialValues; { return _initialValues; }
- (id) initWithDefaults:(NSUserDefaults *) defaults
		  initialValues:(NSDictionary *) values; { return NIMP; }
- (void) revert:(id) sender; { NIMP; }
- (void) revertToInitialValues:(id) sender; { NIMP; }
- (void) save:(id) sender; { NIMP; }
- (void) setAppliesImmediately:(BOOL) flag; { _appliesImmediately=flag; }
- (void) setInitialValues:(NSDictionary *) values; { NIMP; }
- (id) values; { return _values; }

- (id) copyWithZone:(NSZone *) zone { return [self retain]; }
- (void) encodeWithCoder:(NSCoder *) aCoder	{ return; }
- (id) initWithCoder:(NSCoder *) aDecoder { return self; }

@end
