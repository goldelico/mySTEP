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
	return firstName;
}


- (void) setFirstName:(NSString *) aName
{
	ASSIGN (firstName, aName);
}


- (NSString *) lastName
{
	return lastName;
}


- (void) setLastName:(NSString *) aName
{
	ASSIGN (lastName, aName);
}
@end