//
//  SQLite.h
//  CoreDataBase
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jul 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//  COMPANY CONFIDENTIAL.
//


#import <Cocoa/Cocoa.h>

// FIXME: add .tsv and .csv support like the PHP version
// allow to run simple SQL commands on these

@interface SQL : NSObject
{
	void *db;			// SQLite access handle
	NSMutableArray *_rows;	// SQLite rows
	NSString *dbName;
	id delegate;
	// for TSV, CSV, Prolog etc. stored locally
	NSMutableDictionary *tableColumns;	// NSDict[tableName] of NSArray[column]
	NSMutableDictionary *tableColumnProperties;	// NSDict[tableName] of NSDict[column]
	NSMutableDictionary *tableData;	// NSDict[tableName] of NSArray[row] of NSDict[column]
}

- (id) init;
- (BOOL) open:(NSURL *) url error:(NSString **) error;	// YES=ok
- (BOOL) saveAs:(NSURL *) url error:(NSString **) error;

- (void) setDelegate:(id) d;
- (id) delegate;

- (NSArray *) databases:(NSString **) error;	// databases on server
- (void) setDatabase:(NSString *) name;	// choose one database from list of databases
- (NSString *) database;	// database name

// direct access
- (NSArray *) tables:(NSString **) error;	// tables on selected database
- (NSArray *) columnsForTable:(NSString *) table error:(NSString **) error;
- (NSDictionary *) columnProperties:(NSString *) table error:(NSString **) error;
- (NSArray *) dataForTable:(NSString *) table error:(NSString **) error;	// data array of one table

// SQL commands
- (BOOL) sql:(NSString *) cmd error:(NSString **) error;	// YES=ok

- (NSString *) quote:(NSString *) str;	// quote parameter
- (NSString *) quoteIdent:(NSString *) str;	// quote identifier (to distinguish from SQL keywords)

// higher level commands
- (BOOL) newTable:(NSString *) name columns:(NSDictionary *) nameAndType error:(NSString **) error;
- (BOOL) renameTable:(NSString *) from to:(NSString *) to error:(NSString **) error;
- (BOOL) deleteTable:(NSString *) name error:(NSString **) error;
- (BOOL) newColumn:(NSString *) column type:(NSString *) type forTable:(NSString *) table error:(NSString **) error;
- (BOOL) renameColumn:(NSString *) from to:(NSString *) to ofTable:(NSString *) table error:(NSString **) error;
- (BOOL) deleteColumn:(NSString *) column fromTable:(NSString *) table error:(NSString **) error;
- (BOOL) newRow:(NSArray *) values forTable:(NSString *) table error:(NSString **) error;
- (BOOL) deleteRow:(int) row fromTable:(NSString *) table error:(NSString **) error;
- (id) valueAtRow:(NSUInteger) row column:(NSString *) column ofTable:(NSString *) table error:(NSString **) error;
- (BOOL) setValue:(id) value atRow:(NSUInteger) row column:(NSString *) column ofTable:(NSString *) table error:(NSString **) error;

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
