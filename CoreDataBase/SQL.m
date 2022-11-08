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
    if(self = [super init])
		{
		tableData=[[NSMutableDictionary alloc] initWithCapacity:1000];
		tableColumns=[[NSMutableDictionary alloc] initWithCapacity:20];
		}
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
	[dbName release];
	[tableData release];
	[tableColumns release];
	[super dealloc];
}

- (void) setDatabase:(NSString *) name;	// choose one database from list of databases
{
	// only supported for mysql
	// formally it is closing the curend file and opening a new one
}

- (NSString *) database;
{
	return nil;
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

- (NSString *) typeForURL:(NSURL *) url
{
	NSString *type;
	if([url isFileURL])
		{
		type=[[url path] pathExtension];	// take suffix
		if([type isEqualToString:@"sqlite3"])
			type=@"sqlite";
		}
	else
		type=[url scheme];
	return type;
}

- (BOOL) open:(NSURL *) url error:(NSString **) error;
{
	NSString *type=[self typeForURL:url];
	if(!type)
		return NO;	// invalid
	if([type isEqualToString:@"mysql"])
		{
		dbName=[[url path] retain];	// scheme:path
		if(error)
			*error=@"MySQL is not supported yet";
			// open mysql://username:password@host/database
		return NO;
		}
	if([type isEqualToString:@"sqlite"])
		{
		dbName=[[url path] retain];	// scheme:path
		if(sqlite3_open([dbName fileSystemRepresentation],	/* Database filename (UTF-8) */
							(sqlite3 **)&db					/* OUT: SQLite db handle */
							) != SQLITE_OK)
			{
			if(error)
				*error=[NSString stringWithUTF8String:sqlite3_errmsg(((sqlite3 *)db))];
			return NO;
			}
		sqlite3_progress_handler((sqlite3 *)db, 20, sql_progress, (void *) self);
		return YES;
		}
	if([type isEqualToString:@"sql"])
		{
		// raw SQL statements
		// create temporary sqlite database
		// process SQL
		}
	if([type isEqualToString:@"csv"])
		{ // process comma separated file
		NSError *err;
		NSString *db=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
		NSString *tableName=[[url lastPathComponent] stringByDeletingPathExtension];
		NSArray *lines;
		NSEnumerator *e;
		NSString *line;
		NSArray *data;
		NSArray *headers=nil;
	#if 0
		NSLog(@"load");
	#endif
		if(!db)	// try again
			db=[NSString stringWithContentsOfURL:url encoding:NSMacOSRomanStringEncoding error:&err];
		if(!db)
			{
			if(error) *error=[err description];
			return NO;
			}
	#if 0
		NSLog(@"db = %@", db);
	#endif
		lines=[db componentsSeparatedByString:@"\n"];
		e=[lines objectEnumerator];
		data=[[NSMutableArray alloc] initWithCapacity:[lines count]];
		[tableData setObject:data forKey:tableName];
		[data release];
		while((line=[e nextObject]))
			{
			// FIXME: was mit a,b,"c,d", etc. ?
			// FIXME: delimiter , oder ; ?
			NSArray *fields=[line componentsSeparatedByString:@","];
			if([line length] == 0)
				continue;	// ignore empty lines
			if(!headers)
				{ // first
				headers=[fields mutableCopy];
				[tableColumns setObject:headers forKey:tableName];
				[headers release];
				}
			else
				{ // convert into Dict by using headers?
					NSDictionary *record;
					while([fields count] < [headers count])
						fields=[fields arrayByAddingObject:@""];	// add empty records if needed
					if([fields count] > [headers count])
						fields=[fields subarrayWithRange:NSMakeRange(0, [headers count])];
					record=[NSMutableDictionary dictionaryWithObjects:fields forKeys:headers];
					[(NSMutableArray *) data addObject:record];
				}
			}
		return YES;
		}
	if([type isEqualToString:@"tsv"])
		{ // process tab separated file
		NSError *err;
		NSString *db=[NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:&err];
		NSString *tableName=[[url lastPathComponent] stringByDeletingPathExtension];
		NSArray *lines;
		NSEnumerator *e;
		NSString *line;
		NSArray *data;
		NSArray *headers=nil;
	#if 0
		NSLog(@"load");
	#endif
		if(!db)	// try again
			db=[NSString stringWithContentsOfURL:url encoding:NSMacOSRomanStringEncoding error:&err];
		if(!db)
			{
			if(error) *error=[err description];
			return NO;
			}
	#if 0
		NSLog(@"db = %@", db);
	#endif
		lines=[db componentsSeparatedByString:@"\n"];
		e=[lines objectEnumerator];
		data=[[NSMutableArray alloc] initWithCapacity:[lines count]];
		[tableData setObject:data forKey:tableName];
		[data release];
		while((line=[e nextObject]))
			{
			NSArray *fields=[line componentsSeparatedByString:@"\t"];
			if([line length] == 0)
				continue;	// ignore empty lines
			if(!headers)
				{ // first
				headers=[fields mutableCopy];
				[tableColumns setObject:headers forKey:tableName];
				[headers release];
				}
			else
				{ // convert into Dict by using headers
					NSDictionary *record;
					while([fields count] < [headers count])
						fields=[fields arrayByAddingObject:@""];	// add empty records if needed
					if([fields count] > [headers count])
						fields=[fields subarrayWithRange:NSMakeRange(0, [headers count])];
					record=[NSMutableDictionary dictionaryWithObjects:fields forKeys:headers];
					[(NSMutableArray *) data addObject:record];
				}
			}
		return YES;
		}
	if([type isEqualToString:@"prolog"])
		{ // read prolog tuples into database
		}
	if([type isEqualToString:@"database"])
		{ // .database bundle
		NSURL *file;
		// how do we properly handle this???
		// should we read .plists as an "Info.plist" table???
		file=[url URLByAppendingPathComponent:@"Info.plist"];
		NSDictionary *columnProperties=[[[NSDictionary dictionaryWithContentsOfURL:file] objectForKey:@"Column Properties"] mutableCopy];
		NSEnumerator *e=[[NSFileManager defaultManager] enumeratorAtPath:[url path]];
		NSString *filename;
		while((filename=[e nextObject]))
			{ // load all .tsv files in bundle
			file=[url URLByAppendingPathComponent:filename];
				// check for .tsv only?
				// how can we know how to store this again if it is not a .tsv?
			if(![self open:file error:error])
				// ignore errors to load what we get
				/*return NO*/;
			}
		return YES;
		}
	return NO;
}

- (BOOL) saveAs:(NSURL *) url error:(NSString **) error;
{
	NSString *type=[self typeForURL:url];
	if(!type)
		return NO;	// invalid
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
		// CREATE TABLE name DROP IF EXISTS;
		// INSERT INTO ...
		}
	if([type isEqualToString:@"tsv"])
		{
		NSMutableString *str;
		NSArray *headers=nil;
		NSEnumerator *e=[tableData objectEnumerator];
		NSDictionary *record;
		NSError *err;
		str=[NSMutableString stringWithFormat:@"%@\n", [headers componentsJoinedByString:@"\t"]];
		while((record=[e nextObject]))
			{
			NSEnumerator *e=[headers objectEnumerator];
			NSString *delim=@"";
			NSString *line=@"";
			NSString *column;
			while((column=[e nextObject]))
				{ // keep column order intact!
					id val=[record objectForKey:column];
					// FIXME: escape Tabs and newlines
					line=[line stringByAppendingFormat:@"%@%@", delim, val];
					delim=@"\t";
				}
			while([line hasSuffix:@"\t"])
				line=[line substringToIndex:[line length]-1];	// remove empty (extra) fields at line end
			[str appendFormat:@"%@\n", line];
			}
		return [str writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err];
		}
	if([type isEqualToString:@"csv"])
		{
		NSMutableString *str;
		NSArray *headers=nil;
		NSEnumerator *e=[tableData objectEnumerator];
		NSDictionary *record;
		NSError *err;
		NSString *delimiter=@";";	// oder , ???
		str=[NSMutableString stringWithFormat:@"%@\n", [headers componentsJoinedByString:delimiter]];
		while((record=[e nextObject]))
			{
			NSEnumerator *e=[headers objectEnumerator];
			NSString *delim=@"";
			NSString *line=@"";
			NSString *column;
			while((column=[e nextObject]))
				{ // keep column order intact!
					id val=[record objectForKey:column];
					// FIXME: escape ; and newlines
					line=[line stringByAppendingFormat:@"%@%@", delim, val];
					delim=delimiter;
				}
			while([line hasSuffix:delimiter])
				line=[line substringToIndex:[line length]-1];	// remove empty (extra) fields at line end
			[str appendFormat:@"%@\n", line];
			}
		return [str writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err];
		}
	if([type isEqualToString:@"prolog"])
		{
		NSArray *headers=nil;
		// table_headers(col, col, col);
		// table_properties(col, col, col);
		// table(col, col, col);
		NSMutableString *str=[NSMutableString string];
		NSEnumerator *e=[tableData objectEnumerator];
		NSError *err;
		NSDictionary *record;
		while((record=[e nextObject]))
			{
			NSEnumerator *e=[headers objectEnumerator];
			NSString *delim=@"(";
			NSString *line=@"record(";
			NSString *column;
			while((column=[e nextObject]))
				{ // keep column order intact!
					NSString *value=[record objectForKey:column];
					// FIXME: escape quotes in value
					line=[line stringByAppendingFormat:@"%@'%@'", delim, value];
					delim=@", ";
				}
			[str appendFormat:@"%@)\n", line];
			}
		return [str writeToURL:url atomically:YES encoding:NSUTF8StringEncoding error:&err];
		}
	if([type isEqualToString:@"database"])
		{
		NSMutableDictionary *info=[NSMutableDictionary dictionary];
		NSEnumerator *e=[tableData keyEnumerator];
		NSString *tableName;
		NSURL *file;
		NSError *err;
		if(![[NSFileManager defaultManager] createDirectoryAtURL:url withIntermediateDirectories:YES attributes:NULL error:&err])
		   return NO;
		while((tableName=[e nextObject]))
			{
			file=[[url URLByAppendingPathComponent:tableName] URLByAppendingPathExtension:@"tsv"];
			if(![self saveAs:file error:error])
				return NO;
			}
		file=[url URLByAppendingPathComponent:@"Info.plist"];
//		if(columnProperties)
//			[info setObject:columnProperties forKey:@"Column Properties"];
		return [info writeToURL:url atomically:YES];
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
	if(db)
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
	if(db)
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
	return [tableColumns allKeys];
}

- (NSArray *) databases:(NSString **) error;
{ // return list of databases on the server
	if(dbName)
		return [NSArray arrayWithObject:dbName];
	// we do not search for databases, don't we?
	return nil;
}

- (NSArray *) columnsForTable:(NSString *) table error:(NSString **) error;
{ // return list of columns names
  // "SELECT name,sql FROM sqlite_master WHERE type='table'"
	return nil;
}

- (NSArray *) dataForTable:(NSString *) table error:(NSString **) error;	// data of one table
{
	return [tableData objectForKey:table];
}

- (id) valueAtRow:(NSUInteger) row column:(NSString *) column forTable:(NSString *) table error:(NSString **) error;
{
	NSArray *data=[self dataForTable:table error:error];
	if(!data)
		return nil;
	return [[data objectAtIndex:row] objectForKey:column];
}

- (BOOL) setValue:(id) value atRow:(NSUInteger) row column:(NSString *) column forTable:(NSString *) table error:(NSString **) error;
{
	NSArray *data=[self dataForTable:table error:error];
	if(!data)
		return NO;
	[[data objectAtIndex:row] setObject:value forKey:column];
	return YES;
}

- (BOOL) newTable:(NSString *) name columns:(NSDictionary *) nameAndType error:(NSString **) error;
{
	return [self sql:[NSString stringWithFormat:@"CREATE TABLE `%@` (`%@` INTEGER)", name, @"column1"] error:error];
}

- (BOOL) deleteTable:(NSString *) name error:(NSString **) error;
{
	// confirm and/or save table schema&dump in undo buffer
	// DROP TABLE
	return 0;
}

- (BOOL) newColumn:(NSString *) column type:(NSString *) type forTable:(NSString *) table error:(NSString **) error;
{
	// ALTER TABLE x CREATE COLUMN (x int);
	return [self sql:[NSString stringWithFormat:@"ALTER TABLE `%@` CREATE COLUMN (`%@` %@)", table, column, type] error:error];
}

- (BOOL) deleteColumn:(NSString *) column fromTable:(NSString *) table error:(NSString **) error;
{
	// confirm and/or save current data in undo buffer
	return 0;
}

- (BOOL) newRow:(NSArray *) values forTable:(NSString *) table error:(NSString **) error;
{
	return [self sql:[NSString stringWithFormat:@"INSERT INTO `%@` WALUES (`%@`)", table, @""] error:error];
}

- (BOOL) deleteRow:(int) row error:(NSString **) error;
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
