//
// abook.m
// QuantumSTEP
//
// speaks
//    abook [-?dtxgmp]
//		-?		print help
//		--help	print help
//		-d uid	delete
//		-t uid	list all attributes
//		-l uid attrib list attribute
//		-x uid attrib value	change attribute
//		-ag uid Group	add to (existing) or new group
//		-me	uid	set the me record
//         .    as uid refers to the last one created by -cg or -cp or explicitly specified
//		-cg		create group
//		-cp		create person
//		-m		show me record
//		-g		show groups
//		-p		show people
//
//  Created by Dr. H. Nikolaus Schaller on Jan 21 2008.
//  Copyright (c) 2008 DSITRI. All rights reserved.
//

#include <Foundation/Foundation.h>
#include <AddressBook/AddressBook.h>

#define AB [ABAddressBook sharedAddressBook]

@interface ABPerson (private)
- (NSString *) format;
@end

@implementation ABPerson (private)

- (NSString *) format;
{
	NSMutableString *s=[NSMutableString string];
	[s appendFormat:@"%@, %@", [self valueForProperty:kABLastNameProperty], [self valueForProperty:kABFirstNameProperty]];
	return s;
}

@end

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*pool;
	NSProcessInfo		*proc;
	NSArray		*args;
	unsigned int		i;
	NSString *lastuid=@"?";
	
	pool = [NSAutoreleasePool new];
	proc = [NSProcessInfo processInfo];
	if (proc == nil)
		{
		NSLog(@"defaults: unable to get process information!\n");
		[pool release];
		exit(1);
		}
	
	args = [proc arguments];
	
	for (i = 1; i < [args count]; i++)
		{
		if (i == 1 && ([[args objectAtIndex: i] isEqual: @"--help"] ||
			[[args objectAtIndex: i] isEqual: @"-?"]))
			{
			printf("help...\n\n");
			break;
			}
		else if ([[args objectAtIndex: i] isEqual: @"-g"])
			{
			NSEnumerator *e=[[AB groups] objectEnumerator];
			ABGroup *g;
			while((g=[e nextObject]))
				printf("%s\n", [[NSString stringWithFormat:@"%@: %@", [g uniqueId], [g valueForProperty:kABGroupNameProperty]] UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-m"])
			{
			if([AB me])
				printf("%s\n", [[NSString stringWithFormat:@"%@: %@", [[AB me] uniqueId], [[AB me] format]] UTF8String]);
			else
				printf("no ME-Record defined\n");
			}
		else if ([[args objectAtIndex: i] isEqual: @"-p"])
			{
			NSEnumerator *e=[[AB people] objectEnumerator];
			ABPerson *p;
			while((p=[e nextObject]))
				printf("%s\n", [[NSString stringWithFormat:@"%@: %@", [p uniqueId], [p format]] UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-cg"])
			{
			ABGroup *np=[[[ABGroup alloc] init] autorelease]; // create new (empty!) record
			[np setValue:@"new group" forProperty:kABGroupNameProperty];
			[AB addRecord:np];
//			if([currentRecord isKindOfClass:[ABGroup class]])
//				[(ABGroup *) currentRecord addSubgroup:np];	// if a group is seleced -> automatically add to that group
			printf("c %s\n", [[NSString stringWithFormat:@"%@: %@", lastuid=[np uniqueId], [np valueForProperty:kABGroupNameProperty]] UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-cp"])
			{
			ABPerson *np=[[[ABPerson alloc] init] autorelease]; // create new (empty!) record
			[np setValue:@"new person" forProperty:kABLastNameProperty];
			[AB addRecord:np];
//			if([currentRecord isKindOfClass:[ABGroup class]])
//				[(ABGroup *) currentRecord addMember:np];	// if a group is seleced -> automatically add to that group
			printf("c %s\n", [[NSString stringWithFormat:@"%@: %@", lastuid=[np uniqueId], [np format]] UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-ag"])
			{
			NSString *uid = [args objectAtIndex: ++i];
			NSString *group = [args objectAtIndex: ++i];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else
				{
				NSEnumerator *e=[[AB groups] objectEnumerator];
				ABGroup *g;
				while((g=[e nextObject]))
					{
					if([[g valueForProperty:kABGroupNameProperty] isEqualToString:group])
						break;
					}
				if(!g)
					{ // create a new group
					g=[[[ABGroup alloc] init] autorelease];
					[g setValue:group forProperty:kABGroupNameProperty];
					[AB addRecord:g];
					}
				if([r isKindOfClass:[ABPerson class]])
					[g addMember:(ABPerson *) r];
				else
					[g addSubgroup:(ABGroup *) r];
				}
			}
		else if ([[args objectAtIndex: i] isEqual: @"-d"])
			{
			NSString *uid = [args objectAtIndex: ++i];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else if([AB removeRecord:r])
				printf("d %s\n", [uid UTF8String]);
			else
				printf("! %s not removed\n", [uid UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-me"])
			{
			NSString *uid = [args objectAtIndex: ++i];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else if([r isKindOfClass:[ABPerson class]])
				{
				[AB setMe:(ABPerson *) r];
				printf("m %s\n", [uid UTF8String]);
				}
			else
				printf("! %s not set\n", [uid UTF8String]);
			}
		else if ([[args objectAtIndex: i] isEqual: @"-t"])
			{
			NSString *uid = [args objectAtIndex: ++i];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else
				printf("%s", [[[[r class] properties] description] UTF8String]); // list attributes
			}
		else if ([[args objectAtIndex: i] isEqual: @"-x"])
			{
			NSString *uid = [args objectAtIndex: ++i];
			NSArray *attrib = [[args objectAtIndex: ++i] componentsSeparatedByString:@"."];
			NSString *value = [args objectAtIndex: ++i];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else
				{
				int j;
				id val=nil;
				NSString *prop=@"<nil>";
				for(j=0; j<[attrib count]; j++)
					{ // process dotted path components
					prop=[attrib objectAtIndex:j];
					if(j == 0)
						{ // no sublevels
						if(j+1 == [attrib count])
							[r setValue:value forProperty:prop], val=value;	// last one
						else
							val=[r valueForProperty:prop];	// first level
						}
					else if(j == 1 && [[r class] typeOfProperty:prop] & kABMultiValueMask)
						{ // first level can be a labeled multivalue object
						int k;
						for(k=0; k<[val count]; k++)
							if([[val labelAtIndex:k] isEqualToString:prop])
								break;
						if(k == [val count])
							{ // label not found, create new entry
							if(!val)
								val=[[ABMutableMultiValue alloc] init];	// create new
							else
								val=[val mutableCopy];	// val comes from previous level
							[(ABMutableMultiValue *) val addValue:value withLabel:prop];
							[r setValue:val forProperty:[attrib objectAtIndex:j-1]];	// update one level before
							[val release];
							}
						else if(j+1 == [attrib count])
							[val replaceValueAtIndex:k withValue:value], val=value;	// change existing label
						else
							val=[val valueAtIndex:k];	// get from multivalue
						}
					else
						{ // dictionary sublevels
						if(j+1 == [attrib count])
							[val setObject:value forKey:prop], val=value;	// last one
						else
							val=[val objectForKey:prop];	// assume NSDictionary
						}
					}
				if(!val)
					printf("? %s (%s) not found\n", [[args objectAtIndex: i-1] UTF8String], [prop UTF8String]);
				else
					printf("= %s %s\n", [[args objectAtIndex: i-1] UTF8String], [val UTF8String]);
				}
			}
		else if ([[args objectAtIndex: i] isEqual: @"-l"])
			{ // list
			NSString *uid = [args objectAtIndex: ++i];
			NSArray *attrib = [[args objectAtIndex: ++i] componentsSeparatedByString:@"."];
			ABRecord *r;
			if([uid isEqualToString:@"."])
				uid=lastuid;
			else
				lastuid=uid;
			r = [AB recordForUniqueId:uid];
			// handle special case with multi-value and directory value records!
			if(!r)
				printf("? %s not found\n", [uid UTF8String]);
			else
				{
				int j;
				id val=nil;
				NSString *prop=@"<nil>";
				for(j=0; j<[attrib count]; j++)
					{ // process dotted path components
					prop=[attrib objectAtIndex:j];
					if(j == 0)
						val=[r valueForProperty:prop];	// first level
					else if(j == 1 && [[r class] typeOfProperty:prop] & kABMultiValueMask)
						{ // first level can be a labeled multivalue object
						int k;
						for(k=0; k<[val count]; k++)
							if([[val labelAtIndex:k] isEqualToString:prop])
								break;
						if(k == [val count])
							val=nil;	// not found
						else
							val=[val valueAtIndex:k];	// get from multivalue
						}
					else
						val=[val objectForKey:prop];	// assume NSDictionary
					}
				if(val)
					printf("%s\n", [[val description] UTF8String]);
				else
					printf("? %s (%s) not found\n", [[args objectAtIndex: i-1] UTF8String], [prop UTF8String]);
				}
			}
		else if ([[args objectAtIndex: i] isEqual: @"-f"])
			{
			// filter
			}
		else
			{
			fprintf(stderr, "Unknown option\n");
			exit(1);
			}
		}
	[AB save];
	[pool release];
	exit(0);
}

