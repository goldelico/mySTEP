//
//  SQLite.h
//  CoreDataBase
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jul 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//  COMPANY CONFIDENTIAL.
//


#import <Cocoa/Cocoa.h>

@interface SQL : NSObject
{
	NSString *filename;
	id delegate;
	void *sqlite;					// SQLite access handle
	NSMutableArray *tables;
}

- (id) initWithDatabase:(NSURL *) url;
- (BOOL) open:(NSString **) error;	// YES=ok

- (void) setDelegate:(id) d;
- (id) delegate;

- (BOOL) query:(NSString *) cmd error:(NSString **) error;	// YES=ok

- (BOOL) importSQLFromFile:(NSString *) path;
- (BOOL) exportSQLToFile:(NSString *) path;

- (NSArray *) tables:(NSString **) error;
- (NSArray *) columnsForTable:(NSString *) table error:(NSString **) error;

- (int) newTable:(NSString *) name columns:(NSDictionary *) nameAndType error:(NSString **) error;
- (int) deleteTable:(NSString *) name error:(NSString **) error;
- (int) newColumn:(NSString *) column type:(NSString *) type forTable:(NSString *) table error:(NSString **) error;
- (int) deleteColumn:(NSString *) column fromTable:(NSString *) table error:(NSString **) error;
- (int) newRow:(NSArray *) values forTable:(NSString *) table error:(NSString **) error;
- (int) deleteRow:(int) row error:(NSString **) error;

@end

// delegate methods

@interface NSObject (SQLite)
- (void) sql:(SQL *) this progress:(int) progress;
- (BOOL) sql:(SQL *) this record:(NSDictionary *) record;	// return YES to abort
@end