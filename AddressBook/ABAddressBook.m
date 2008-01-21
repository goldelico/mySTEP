//
//  ABAddressBook.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "Private.h"

@implementation ABAddressBook

- (id) init;
{
#if 1
	NSLog(@"init %@", self);
#endif
	if((self=[super init]))
		{
		NSDictionary *records=[NSMutableDictionary dictionaryWithContentsOfFile:AB_FILE];	// read file
		// warning: result read from file must be deep mutable!!!
		if(!records)
			{ // create new property dictionaries
			NSBundle *bndl=[NSBundle bundleForClass:[self class]];
			// warning on MacOS X 10.4...
			[[NSFileManager defaultManager] createDirectoryAtPath:[AB_DIRECTORY stringByExpandingTildeInPath]
									  withIntermediateDirectories:YES
													   attributes:nil
															error:NULL
				];  // create directory
			properties=[NSDictionary dictionaryWithObjectsAndKeys:
				[[[bndl objectForInfoDictionaryKey:AB_KEY_PERSONS] mutableCopy] autorelease], AB_KEY_PERSONS,
				[[[bndl objectForInfoDictionaryKey:AB_KEY_GROUPS] mutableCopy] autorelease], AB_KEY_GROUPS,
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
#if 1
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
		shared=[[self alloc] init];	// this also reads database
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
	// NIMP;
	return nil;
}

- (BOOL) addRecord:(ABRecord *) record;
{
	// check for duplicates?
#if 1
	NSLog(@"addRecord: %@", record);
#endif
	if([record isKindOfClass:[ABPerson class]])
		{
		[persons addObject:record];
#if 1
		NSLog(@"persons=%@", groups);
#endif
		}
	else if([record isKindOfClass:[ABGroup class]])
		{
		[groups addObject:record];
#if 1
		NSLog(@"groups=%@", groups);
#endif
		}
	else
		return NO;	// something else
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
#if 1
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
#if 1
	NSLog(@"save %@", d);
#endif
	return [d writeToFile:AB_FILE atomically:YES] && 
		   [NSArchiver archiveRootObject:groups toFile:AB_GROUPS] &&
		   [NSArchiver archiveRootObject:persons toFile:AB_PERSONS];
	// send distributed notification?
}

// read this from NSUserDefaults from @"de.dsitri.myPDA.ABAddressBook" persistent domain - or NSGlobalDomain?

- (NSString *) defaultCountryCode; { return @"un"; }

- (int) defaultNameOrdering; { return kABLastNameFirst; }

- (NSAttributedString *) formattedAddressFromDictionary:(NSDictionary *) addr;
{
	// NIMP
	return nil;
}

@end
