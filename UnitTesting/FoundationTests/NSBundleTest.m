//
//  NSBundleTest
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 30.08.16.
//  Copyright 2016 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AddressBook/AddressBook.h>

@interface NSBundleTest : XCTestCase {
	NSBundle *framework;
	NSBundle *application;
	NSBundle *bundle;
	NSBundle *tool;
}

@end

@implementation NSBundleTest

- (void) setUp
{
	framework=[NSBundle bundleWithPath:@"/System/Library/Frameworks/Foundation.framework"];
	XCTAssertNotNil(framework, @"");
	application=[NSBundle bundleWithPath:@"/System/Library/CoreServices/loginwindow.app"];
	XCTAssertNotNil(application, @"");
	bundle=[NSBundle bundleWithPath:@"/Library/UnitTests/Foundation.xctest"];
//	XCTAssertNotNil(bundle, @"");
	tool=[NSBundle bundleWithPath:@"/usr/bin/ocunit"];
}

- (void) tearDown
{
	[framework release];
}

- (void) test01
{
	XCTAssertEqualObjects([framework bundlePath], @"/System/Library/Frameworks/Foundation.framework", @"");
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

#if 0	// end in a look on macOS
- (void) test05
{
	// check if methods from superclasses of loaded bundles can be accessed
	ABPerson *p=[[ABPerson alloc] init];
	NSLog(@"superclass methods accessible: %d", [p respondsToSelector:@selector(forwardInvocation:)]);
	NSLog(@"class: %@", [p class]);
	NSLog(@"superclass: %@", [p superclass]);
	[p release];
}
#endif

@end
