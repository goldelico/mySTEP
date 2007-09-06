//
//  ABAddressBook.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "Private.h"

@interface NSFileManager (Extension)
- (BOOL) _createDirectoryDownToPath:(NSString *) path;
@end

@implementation ABAddressBook

- (id) init;
{
	self=[super init];
	if(self)
		{
		NSDictionary *records=[NSDictionary dictionaryWithContentsOfFile:AB_FILE];	// read file
		// warning: must be deep mutable!!!
		if(!records)
			{ // create new property dictionaries
			NSBundle *bndl=[NSBundle bundleForClass:[self class]];
			[[NSFileManager defaultManager] _createDirectoryDownToPath:[AB_DIRECTORY stringByExpandingTildeInPath]];  // create directory
			properties=[NSDictionary dictionaryWithObjectsAndKeys:
				[[[bndl objectForInfoDictionaryKey:@"ABPerson"] mutableCopy] autorelease], @"ABPerson",
				[[[bndl objectForInfoDictionaryKey:@"ABGroup"] mutableCopy] autorelease], @"ABGroup",
				nil];
			ich=nil;	// not defined
			hasUnsavedChanges=NO;  // need not save yet
			}
		else
			{ // fetch
			ich=[records objectForKey:AB_KEY_ME];
			groups=[NSUnarchiver unarchiveObjectWithFile:AB_GROUPS];
			persons=[NSUnarchiver unarchiveObjectWithFile:AB_PERSONS];
//			persons=[records objectForKey:AB_KEY_PERSONS];
//			groups=[records objectForKey:AB_KEY_GROUPS];
			}
		if(!properties) properties=[records objectForKey:AB_KEY_PROPERTIES];
		if(!persons) persons=[NSMutableArray arrayWithCapacity:10];
		if(!groups) groups=[NSMutableArray arrayWithCapacity:10];
		[properties retain];
		[persons retain];
		[groups retain];
#if 0
		NSLog(@"properties=%@", properties);
		NSLog(@"persons=%@", properties);
		NSLog(@"groups=%@", properties);
#endif
		}
	return self;
}

- (void) dealloc;
{
	[properties release];
	[ich release];
	[persons release];
	[groups release];
	[super dealloc];
}

- (NSMutableDictionary *) _properties; { return properties; }  // has sub-dictionaries ABPerson and ABGroup

- (void) _touch;
{
#if 1
	NSLog(@"ABAddressBook touch");
#endif
	hasUnsavedChanges=YES;
	/* collect for kABDatabaseChangedNotification */
}

+ (ABAddressBook *) sharedAddressBook 
{
	static ABAddressBook *shared;
	if(!shared)
		shared=[[self alloc] init];	// reads database
	return shared;
}

- (NSArray *) people; { return persons; }
- (NSArray *) groups; { return groups; }
- (ABPerson *) me;
{
	return (ABPerson *) [self recordForUniqueId:ich];
} 

- (void) setMe:(ABPerson *) ego;
{
	[ich autorelease];
	ich=[[ego uniqueId] retain];
	[self _touch];
}

- (NSString *) recordClassFromUniqueId:(NSString *) uid;
{ // uid is a : separated list of components - the last one is the Obj-C class
	return [[uid componentsSeparatedByString:@":"] lastObject];
}

- (ABRecord *) recordForUniqueId:(NSString *) str;
{ // scan all records - well, we could also have a 'records' dictionary for mapping uniqueIds to records
	NSEnumerator *e=[persons objectEnumerator];
	id obj;
	while((obj=[e nextObject]))
		{
		if([[obj uniqueId] isEqualToString:str])
			return obj;	// found
		}
	e=[groups objectEnumerator];
	while((obj=[e nextObject]))
		{
		if([[obj uniqueId] isEqualToString:str])
			return obj;	// found
		}
	return nil;	// not found
}

- (NSArray *) recordsMatchingSearchElement:(ABSearchElement *) search; 
{ // scan all persons and/or groups
  // collect to temp array where [search matchesRecord:obj]
	return nil;
}

- (BOOL) addRecord:(ABRecord *) record;
{
	// check for duplicates?
	NSLog(@"addRecord: %@", record);
	if([record isKindOfClass:[ABPerson class]])
		{
		NSLog(@"persons=%@", groups);
		[persons addObject:record];
		}
	else if([record isKindOfClass:[ABGroup class]])
		{
		NSLog(@"groups=%@", groups);
		[groups addObject:record];
		}
	else
		return NO;
	[self _touch];
	return YES;
}
 
- (BOOL) removeRecord:(ABRecord *) record;
{
	if([persons indexOfObject:record] != NSNotFound)
		[persons removeObject:record];
	else if([groups indexOfObject:record] != NSNotFound)
		[groups removeObject:record];
	else
		return NO;  // not found
	if(record == (ABRecord *) ich)
		[self setMe:nil];
	[self _touch];
	return YES;
}

- (BOOL) hasUnsavedChanges; { return hasUnsavedChanges; }

- (BOOL) save;
{
	NSMutableDictionary *d;
#if 0
	NSLog(@"save");
#endif
	if(!hasUnsavedChanges)
		return YES;
	d=[NSMutableDictionary dictionaryWithCapacity:4];
	[d setObject:properties forKey:AB_KEY_PROPERTIES];
	if(ich)
		[d setObject:ich forKey:AB_KEY_ME];
//	[d setObject:persons forKey:AB_KEY_PERSONS];
//	[d setObject:groups forKey:AB_KEY_GROUPS];
	hasUnsavedChanges=NO;   // reset anyway
#if 0
	NSLog(@"save %@", d);
#endif
	return [d writeToFile:AB_FILE atomically:YES] && 
		   [NSArchiver archiveRootObject:groups toFile:AB_GROUPS] &&
		   [NSArchiver archiveRootObject:persons toFile:AB_PERSONS];
}

// read from NSUserDefaults from @"de.dsitri.myPDA.ABAddressBook" persistent domain - or NSGlobalDomain

- (NSString *) defaultCountryCode; { return @"int"; }

- (int) defaultNameOrdering; { return kABLastNameFirst; }

- (NSAttributedString *) formattedAddressFromDictionary:(NSDictionary *) addr;
{
	return nil;
}

@end
