//
//  SQLite.m
//  CoreDataBase
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jul 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//  COMPANY CONFIDENTIAL.
//

#import "SQL.h"
#include "sqlite3.h"

@implementation SQL

- (id) init
{
    self = [super init];
    return self;
}

- (void) dealloc;
{
	// cancel any pending actions 
	if(db)
		{
		int err=sqlite3_close((sqlite3 *) db);
		if(err != SQLITE_OK)
			NSLog(@"-dealloc: sqlite3_close() returns %d", err);
		}
	[type release];
	[dbname release];
	[super dealloc];
}

- (void) setDatabase:(NSString *) name;	// choose one database from list of databases
{
	// not supported for sqlite
	// formally it is closing the curend file and opening a new one
}

- (void) setDelegate:(id) d
{
	delegate=d;
}

- (id) delegate
{
	return delegate;
}

static int sql_progress(void *context)	// context should be self
{ // callback for sqlite
	SQL *this = (SQL *) context;
	NSLog(@"sql_progress");
	[[this delegate] sql:this progress:0];
	return 0;
}

- (BOOL) open:(NSURL *) url error:(NSString **) error;
{
	if(type)
		{
		*error=@"already open";
		return NO;	// already open
		}
	if([url isFileURL])
		{
		type=[[url path] pathExtension];	// take suffix
		if([type isEqualToString:@"sqlite3"])
			type=@"sqlite";
		}
	else
		type=[url scheme];
	[type retain];
	dbname=[[url path] retain];	// scheme:path
	if([type isEqualToString:@"mysql"])
		{
		if(error)
			*error=@"MySQL is not supported yet";
			// open mysql://username:password@host/database
		return NO;
		}
	if([type isEqualToString:@"sqlite"])
		{
		if(sqlite3_open([dbname fileSystemRepresentation],	/* Database filename (UTF-8) */
							(sqlite3 **)&db					/* OUT: SQLite db handle */
							) != SQLITE_OK)
			{
			if(error)
				*error=[NSString stringWithUTF8String:sqlite3_errmsg(((sqlite3 *)db))];
			return NO;
			}
		sqlite3_progress_handler((sqlite3 *)db, 20, sql_progress, (void *) self);
		}
	if([type isEqualToString:@"sql"])
		{
		// raw SQL statements
		// create temporary sqlite database
		// process SQL
		}
	if([type isEqualToString:@"csv"])
		{
		// comma separated file
		}
	if([type isEqualToString:@"tsv"])
		{
		// tab separated file
		}
	if([type isEqualToString:@"prolog"])
		{
		// prolog tuples
		}
	if([type isEqualToString:@"database"])
		{
		// .database bundle
		}
	return YES;
}

- (BOOL) saveAs:(NSURL *) url error:(NSString **) error;
{
	if([type isEqualToString:@"mysql"])
		{
		if(error)
			*error=@"Can't save MySQL at different path";
		return NO;
		}
	// change path (and potentially type?) and save
	if([type isEqualToString:@"sqlite"])
		{
		// ?
		}
	if([type isEqualToString:@"sql"])
		{
		// export as SQL statements
		}
	if([type isEqualToString:@"csv"])
		{
		// comma separated file
		}
	if([type isEqualToString:@"tsv"])
		{
		// tab separated file
		}
	if([type isEqualToString:@"prolog"])
		{
		// prolog tuples
		}
	if([type isEqualToString:@"database"])
		{
		// .database bundle
		}
	return NO;
}

static int sql_callback(void *context, int columns, char **values, char **names)	// context=self
{ // callback for sqlite
	SQL *self = (SQL *) context;
	NSMutableDictionary *record=[NSMutableDictionary dictionaryWithCapacity:columns];
	int i;
	for(i=0; i<columns; i++)
		{
		NSString *key=[NSString stringWithUTF8String:names[i]];
		if(values[i])
			[record setObject:[NSString stringWithUTF8String:values[i]] forKey:key];	// create record with data
		else
			[record setObject:[NSNull null] forKey:key];
		}
	return [[self delegate] sql:self record:record];
}

- (BOOL) sql:(NSString *) cmd error:(NSString **) error;
{ // execute SQL command for current database
	if([type isEqualToString:@"sqlite"])
		{
		char *error_msg;
		int result=sqlite3_exec(
								(sqlite3 *) db,           /* An open database */
								[cmd UTF8String],         /* SQL command to be executed */
								sql_callback,                 /* Callback function */
								(void *) self,                /* 1st argument to callback function */
								&error_msg                    /* Error msg written here */
								);
		if(error && result != SQLITE_OK)
			*error=[NSString stringWithUTF8String:error_msg];
		return result == SQLITE_OK;
		}
	*error=@"not yet implemented";
	return NO;
}

- (NSString *) quote:(NSString *) str;
{ // quote parameter
	return [str _quote];
}

- (NSString *) quoteIdent:(NSString *) str;
{ // quote identifier (to distinguish from SQL keywords)
	return [str _quoteIdent];
}

// higher level functions

- (BOOL) sql:(SQL *) this record:(NSDictionary *) record;
{ // we are (temporarily) our own delegate
	[tables addObject:[record objectForKey:@"name"]];
	return NO;	// don't abort
}

- (NSArray *) tables:(NSString **) error;
{ // return list of table names
	if([type isEqualToString:@"sqlite"])
		{
		id saved=delegate;
		delegate=self;	// make us collect results in tables
		tables=[NSMutableArray arrayWithCapacity:10];	// we collect here
		if(![self sql:@"SELECT name,sql FROM sqlite_master WHERE type='table'" error:error])
			{
			delegate=saved;
			return nil;
			}
		delegate=saved;
		return tables;
		}
	if([type isEqualToString:@"csv"])
		return [NSArray arrayWithObject:[dbname lastPathComponent]];
	if([type isEqualToString:@"tsv"])
		return [NSArray arrayWithObject:[dbname lastPathComponent]];
	if([type isEqualToString:@"prolog"])
		{
		// prolog tuples
		}
	if([type isEqualToString:@"database"])
		{
		// .database bundle
		// list of all embedded .tsv files
		}
	*error=@"not implemented";
	return nil;
}

- (NSArray *) databases:(NSString **) error;
{ // return list of databases on the server
	if([type isEqualToString:@"sqlite"])
		return [NSArray arrayWithObject:dbname];
	// we do not search for databases, don't we?
	return nil;
}

- (NSArray *) columnsForTable:(NSString *) table error:(NSString **) error;
{ // return list of columns names
  // "SELECT name,sql FROM sqlite_master WHERE type='table'"
	return nil;
}

- (int) newTable:(NSString *) name columns:(NSDictionary *) nameAndType error:(NSString **) error;
{
	return [self sql:[NSString stringWithFormat:@"CREATE TABLE `%@` (`%@` INTEGER)", name, @"column1"] error:error];
}

- (int) deleteTable:(NSString *) name error:(NSString **) error;
{
	// confirm and/or save table schema&dump in undo buffer
	// DROP TABLE
	return 0;
}

- (int) newColumn:(NSString *) column type:(NSString *) type forTable:(NSString *) table error:(NSString **) error;
{
	// ALTER TABLE x CREATE COLUMN (x int);
	return [self sql:[NSString stringWithFormat:@"ALTER TABLE `%@` CREATE COLUMN (`%@` %@)", table, column, type] error:error];
}

- (int) deleteColumn:(NSString *) column fromTable:(NSString *) table error:(NSString **) error;
{
	// confirm and/or save current data in undo buffer
	return 0;
}

- (int) newRow:(NSArray *) values forTable:(NSString *) table error:(NSString **) error;
{
	return [self sql:[NSString stringWithFormat:@"INSERT INTO `%@` WALUES (`%@`)", table, @""] error:error];
}

- (int) deleteRow:(int) row error:(NSString **) error;
{
	// confirm and/or save current row in undo buffer
	// DELETE FROM x WHERE index=row;
	return 0;
}

@end

@implementation NSObject (SQLite)
- (void) sql:(SQL *) this progress:(int) progress;
{
	return;	// ignore
}
- (BOOL) sql:(SQL *) this record:(NSDictionary *) record;
{
	return YES;	// abort
}
@end

@implementation NSString (SQLite)
- (NSString *) _quote; { return self; }
- (NSString *) _quoteIdent; { return self; }
@end
