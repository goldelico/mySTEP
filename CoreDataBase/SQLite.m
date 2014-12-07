//
//  SQLite.m
//  CoreDataBase
//
//  Created by Dr. H. Nikolaus Schaller on Wed Jul 30 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//  COMPANY CONFIDENTIAL.
//

#import "SQLite.h"
#include "sqlite3.h"

@implementation SQLite

- (id) initWithFileName:(NSString *) name
{
    self = [super init];
    if (self)
		{ // If an error occurs here, send a [self release] message and return nil.
			filename=[name retain];
		}
    return self;
}

- (void) dealloc;
{
	// cancel any pending actions 
	if(sqlite)
		{
		int err=sqlite3_close((sqlite3 *) sqlite);
		if(err != SQLITE_OK)
			NSLog(@"-dealloc: sqlite3_close() returns %d", err);
		}
	[filename release];
	[super dealloc];
}

static int sql_progress(void *context)	// context should be self
{
	SQLite *self = (SQLite *) context;
	NSLog(@"sql_progress");
	[[self delegate] sqlite:self progress:0];
	return 0;
}

- (void) setDelegate:(id) d
{
	delegate=d;
}

- (id) delegate
{
	return delegate;
}

- (BOOL) open:(NSString **) error;
{
	if(sqlite3_open([filename fileSystemRepresentation],	/* Database filename (UTF-8) */
					 (sqlite3 **)&sqlite					/* OUT: SQLite db handle */
					 ) != SQLITE_OK)
		{
		if(error)
			*error=[NSString stringWithUTF8String:sqlite3_errmsg(((sqlite3 *)sqlite))];
		return NO;
		}
	sqlite3_progress_handler((sqlite3 *)sqlite, 20, sql_progress, (void *) self);
	return YES;
}

static int sql_callback(void *context, int columns, char **values, char **names)	// context=self
{
	SQLite *self = (SQLite *) context;
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
	return [[self delegate] sqlite:self record:record];
}

- (BOOL) sql:(NSString *) cmd error:(NSString **) error;
{ // execute SQL command for current database
	char *error_msg;
	int result=sqlite3_exec(
					 (sqlite3 *) sqlite,           /* An open database */
					 [cmd UTF8String],             /* SQL to be executed */
					 sql_callback,                 /* Callback function */
					 (void *) self,                /* 1st argument to callback function */
					 &error_msg                    /* Error msg written here */
					 );
	if(error && result != SQLITE_OK)
		*error=[NSString stringWithUTF8String:error_msg];
	return result == SQLITE_OK;
}

// higher level functions

- (BOOL) sqlite:(SQLite *) this record:(NSDictionary *) record;
{ // we are (temporarily) our own delegate
	[tables addObject:[record objectForKey:@"name"]];
	return NO;	// don't abort
}

- (NSArray *) tables:(NSString **) error;
{ // return list of table names
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
- (void) sqlite:(SQLite *) this progress:(int) progress;
{
	return;	// ignore
}
- (BOOL) sqlite:(SQLite *) this record:(NSDictionary *) record;
{
	return YES;	// abort
}
@end
