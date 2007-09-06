//
//  NSObjectController.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSObjectController
#define _mySTEP_H_NSObjectController

#import "AppKit/NSController.h"
#import "AppKit/NSMenuItem.h"

@class NSString;
@class NSCoder;

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
- (id) initWithContent:(id) content;
- (BOOL) isEditable;
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
- (void) setObjectClass:(Class) class;
- (BOOL) validateMenuItem:(id <NSMenuItem>) item;

@end

#endif /* _mySTEP_H_NSObjectController */
