//
//  NSBundleTest
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 30.08.16.
//  Copyright 2016 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSBundleTest : XCTestCase {
	NSBundle *b;
}

@end

@implementation NSBundleTest

- (void) setUp
{
	b=[NSBundle bundleWithPath:@"/System/Library/Frameworks/AddressBook.framework"];
	XCTAssertNotNil(b, @"");
}

- (void) tearDown
{
	[b release];
}

- (void) test01
{
	XCTAssertEqual([b bundlePath], @"/System/Library/Frameworks/AddressBook.framework");
}

- (void) test02
{
	// check executable path
}

// type
// principalClass
// infoDictionary
// if a framework is becoming listed in [NSBundle frameworks]

- (void) test03
{
}

- (void) test04
{
}

- (void) test05
{
	// check if methods from superclasses can be accessed
	ABPerson *p=[[ABPerson alloc] init];
	NSLog(@"superclass methods accessible: %d", [p respondsToSelector:@selector(forwardInvocation:)]);
	NSLog(@"class: %@", [p class]);
	NSLog(@"superclass: %@", [p superclass]);
	[p release];
}

@end
