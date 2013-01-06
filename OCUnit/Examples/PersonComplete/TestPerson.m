//
//  TestPerson.m
//  Person
//
//  Created by Ph(i)Nk 0 on Fri May 17 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import "TestPerson.h"
#import "Person.h"


@implementation TestPerson

- (void) setUp
{
	person = [[Person alloc] init];
}


- (void) tearDown
{
	[person release];
}


- (void) testFullName
{
	[person setFirstName:@"Pablo"];
	[person setLastName:@"Picasso"];

	STAssertTrue ([[person fullName] isEqual:@"Pablo Picasso"],
                  @"Full name should equal Pablo Picasso.");
}


- (void) testEmptyFirstName
{
	[person setFirstName:@""];
	[person setLastName:@"Picasso"];
	STAssertEqualObjects ([person fullName], [person lastName], 
                          @"Last name should equal full name.");
}


- (void) testNilFirstName
{
	[person setFirstName:nil];
	[person setLastName:@"Picasso"];
	STAssertEqualObjects ([person firstName], @"",
                          @"First name should be empty.");
	STAssertEqualObjects ([person fullName], [person lastName], 
                          @"Last name should equal full name.");
}


- (void) testEmptyLastName
{
	[person setFirstName:@"Pablo"];
	[person setLastName:@""];
	STAssertEqualObjects ([person fullName], [person firstName], 
                          @"Full name should equal first name.");
}


- (void) testNilLastName
{
	[person setFirstName:@"Pablo"];
	[person setLastName:nil];
	STAssertEqualObjects ([person lastName], @"",
                          @"Last name should be empty.");
	STAssertEqualObjects ([person fullName], [person firstName], 
                          @"Full name should equal first name.");
}
@end
