//
//  ABGroup.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import "Private.h"

@implementation ABGroup

- (id) initWithUniqueId:(NSString *) uid;
{
	self=[super initWithUniqueId:uid];
	if(self)
		{
		members=[[NSMutableArray array] retain];
		subgroups=[[NSMutableArray array] retain];
		parentgroups=[[NSMutableArray array] retain];
		}
	return self;
}

- (id) init;
{
	self=[super init];
	if(self)
		{
		members=[[NSMutableArray array] retain];
		subgroups=[[NSMutableArray array] retain];
		parentgroups=[[NSMutableArray array] retain];
		}
	return self;
}

- (void) dealloc;
{
	[members release];
	// we must [subgroups_all_members _removeFromParentGroup:self] !!!
	[subgroups release];
	[parentgroups release];
	[super dealloc];
}

- (BOOL) addMember:(ABPerson *) person; { [members addObject:person]; [self _touch]; return YES; }

- (NSArray *) members; { return members; }

- (BOOL) removeMember:(ABPerson *) person;
{
	if([members indexOfObject:person] == NSNotFound)
		return NO;  // can't delete
	[members removeObject:person];
	[self _touch];
	return YES;
}

- (void) _addToParentGroup:(ABGroup *) grp; { [parentgroups addObject:grp]; [self _touch]; }

- (void) _removeFromParentGroup:(ABGroup *) grp; { [parentgroups removeObject:grp]; [self _touch]; }

- (NSArray *) parentGroups; { return parentgroups; }

- (BOOL) addSubgroup:(ABGroup *) group;
{
	// check for recursion
	[subgroups addObject:group];
	[group _addToParentGroup:self];
	return YES;
}

- (BOOL) removeSubgroup:(ABGroup *) group;
{
	[subgroups removeObject:group];
	[group _removeFromParentGroup:self];
	return YES;
}

- (NSArray *) subgroups; { return subgroups; };

- (NSString *) distributionIdentifierForProperty:(NSString *) property person:(ABPerson *) person; { return @"??"; }

- (BOOL) setDistributionIdentifier:(NSString *) identifier forProperty:(NSString *) property person:(ABPerson *) person; { return NO; }

- (NSString *) description; { return [NSString stringWithFormat:@"ABGroup uid=%@", [self uniqueId]]; }

- (void) encodeWithCoder:(id)aCoder
{
	[super encodeWithCoder:aCoder];
	[aCoder encodeObject: parentgroups];
	[aCoder encodeObject: members];
	[aCoder encodeObject: subgroups];
}

- (id) initWithCoder:(id)aDecoder
{
	self=[super initWithCoder:aDecoder];
	parentgroups = [[aDecoder decodeObject] retain];
	members = [[aDecoder decodeObject] retain];
	subgroups = [[aDecoder decodeObject] retain];
	return self;
}

@end
