//
//  NSMutableArrayTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.07.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSMutableArrayTest : XCTestCase {
	NSMutableArray *t;
}

@end

@implementation NSMutableArrayTest

- (void) setUp
{
	t=[[NSMutableArray alloc] init];
	XCTAssertNotNil(t, @"");
}

- (void) tearDown
{
	[t release];
}

- (void) test01
{
	XCTAssertEqual([t count], 0, @"");
	XCTAssertThrowsSpecific([t removeObjectsAtIndexes:nil], NSException);
	XCTAssertThrowsSpecific([t insertObjects:t atIndexes:nil], NSException);
	NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndex:1];
	XCTAssertThrowsSpecific([t insertObjects:nil atIndexes:indexes], NSException);
	XCTAssertThrowsSpecific([t objectsAtIndexes:nil], NSException);
}

- (void) test02
{ // indexes are as before removeObjectsAtIndexes begins
	// like at https://developer.apple.com/documentation/foundation/nsmutablearray/1410154-removeobjectsatindexes
	NSMutableArray *has=[NSMutableArray arrayWithObjects: @"one", @"a", @"two", @"b", @"three", @"four", nil];
	NSMutableIndexSet *idx=[NSMutableIndexSet indexSetWithIndex:1];
	NSArray *wants;
	[idx addIndex:3];
	[has removeObjectsAtIndexes:idx];
	wants=[NSArray arrayWithObjects: @"one", @"two", @"three", @"four", nil];
	XCTAssertEqualObjects(has, wants, @"has: %@", has);
}

- (void) test03
{ // indexes are after inserting previous indexes
  // like https://developer.apple.com/documentation/foundation/nsmutablearray/1416482-insertobjects
	NSMutableArray *has=[NSMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil];
	NSArray *add=[NSArray arrayWithObjects: @"a", @"b", nil];
	NSArray *wants;
	NSMutableIndexSet *idx=[NSMutableIndexSet indexSetWithIndex:1];
	[idx addIndex:3];
	[has insertObjects:add atIndexes:idx];
	wants=[NSArray arrayWithObjects: @"one", @"a", @"two", @"b", @"three", @"four", nil];
	XCTAssertEqualObjects(has, wants, @"has: %@", has);
}

- (void) test04
{ // indexes may all append to end
  // like https://developer.apple.com/documentation/foundation/nsmutablearray/1416482-insertobjects
	NSMutableArray *has=[NSMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil];
	NSArray *add=[NSArray arrayWithObjects: @"a", @"b", nil];
	NSArray *wants;
	NSMutableIndexSet *idx=[NSMutableIndexSet indexSetWithIndex:5];
	[idx addIndex:4];
	[has insertObjects:add atIndexes:idx];
	wants=[NSArray arrayWithObjects: @"one", @"two", @"three", @"four", @"a", @"b", nil];
	XCTAssertEqualObjects(has, wants, @"has: %@", has);
}

- (void) test05
{
	NSMutableArray *has=[NSMutableArray arrayWithObjects: @"one", @"two", @"three", @"four", nil];
	NSArray *gets, *wants;
	NSMutableIndexSet *idx=[NSMutableIndexSet indexSetWithIndex:1];
	[idx addIndex:3];
	gets=[has objectsAtIndexes:idx];
	wants=[NSArray arrayWithObjects: @"two", @"four", nil];
	XCTAssertEqualObjects(gets, wants, @"has: %@", gets);
}

@end
