//
//  Person.m
//  TestPerson
//
//  Created by Ph(i)Nk 0 on Tue May 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "Person.h"
#import <SenTestingKit/SenTestingKit.h>

@implementation Person
- (NSString *) firstName
{
	return firstName != nil ? firstName : @"";
}


- (void) setFirstName:(NSString *) aName
{
	ASSIGN (firstName, aName);
}


- (NSString *) lastName
{
	return lastName != nil ? lastName : @"" ;
}


- (void) setLastName:(NSString *) aName
{
	ASSIGN (lastName, aName);
}


- (NSString *) fullName
{
	return [[NSString stringWithFormat:@"%@ %@", [self firstName], [self lastName]] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

@end