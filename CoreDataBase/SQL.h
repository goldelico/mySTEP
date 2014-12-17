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
	NSString *type;
	void *db;					// SQLite access handle
	NSString *dbname;
	id delegate;
	NSMutableArray *tables;		// for collecting of internal query results
}

- (id) init;
- (BOOL) open:(NSURL *) url error:(NSString **) error;	// YES=ok

- (void) setDatabase:(NSString *) name;	// choose one database from list of databases
- (void) setDelegate:(id) d;
- (id) delegate;

- (BOOL) sql:(NSString *) cmd error:(NSString **) error;	// YES=ok

- (NSString *) quote:(NSString *) str;	// quote parameter
- (NSString *) quoteIdent:(NSString *) str;	// quote identifier (to distinguish from SQL keywords)

- (NSArray *) tables:(NSString **) error;
- (NSArray *) databases:(NSString **) error;

- (NSArray *) columnsForTable:(NSString *) table error:(NSString **) error;

- (BOOL) importSQLFromFile:(NSString *) path;
- (BOOL) exportSQLToFile:(NSString *) path;

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

// NSString convenience

@interface NSString (SQLite)
- (NSString *) _quote;
- (NSString *) _quoteIdent;
@end
