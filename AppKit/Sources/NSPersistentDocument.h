/*
	NSPersistentDocument.h
	mySTEP

	Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
	Copyright (c) 2005 DSITRI.
 
	Author:	Fabian Spillner <fabian.spillner@gmail.com>
	Date:	29. November 2007 - aligned with 10.5 	

	This file is part of the mySTEP Library and is provided
	under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPersistentDocument
#define _mySTEP_H_NSPersistentDocument

#import "AppKit/NSDocument.h"

@class NSString;
@class NSCoder;

@interface NSPersistentDocument : NSDocument
{
}

- (BOOL) configurePersistentStoreCoordinatorForURL:(NSURL *) url 
											ofType:(NSString *) type 
								modelConfiguration:(NSString *) conf 
									  storeOptions:(NSDictionary *) opts 
											 error:(NSError **) err; 
- (BOOL) hasUndoManager; 
- (BOOL) isDocumentEdited; 
- (NSManagedObjectContext *) managedObjectContext; 
- (id) managedObjectModel; 
- (NSString *) persistentStoreTypeForFileType:(NSString *) type; 
- (BOOL) readFromURL:(NSURL *) url 
			  ofType:(NSString *) type 
			   error:(NSError **) err; 
- (BOOL) revertToContentsOfURL:(NSURL *) url 
						ofType:(NSString *) type 
						 error:(NSError **) err; 
- (void) setHasUndoManager:(BOOL) flag; 
- (void) setManagedObjectContext:(NSManagedObjectContext *) moc; 
- (void) setUndoManager:(NSUndoManager *) undoManager; 
- (BOOL) writeToURL:(NSURL *) url 
			 ofType:(NSString *) type 
   forSaveOperation:(NSSaveOperationType) saveOp 
originalContentsURL:(NSURL *) originUrl 
			  error:(NSError **) err; 

@end

#endif /* _mySTEP_H_NSPersistentDocument */
