//
//  NSRegularExpressionTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 21.08.17.
//
//

#import <XCTest/XCTest.h>

@interface NSRegularExpressionTest : XCTestCase

@end

@implementation NSRegularExpressionTest

- (void) setUp {
	[super setUp];
	// Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void) tearDown {
	// Put teardown code here. This method is called after the invocation of each test method in the class.
	[super tearDown];
}

- (void) test01
{
	NSError *error=nil;
	NSRegularExpression *ex=[NSRegularExpression regularExpressionWithPattern:@"pattern" options:0 error:&error];
	XCTAssertNotNil(ex);
	XCTAssertNil(error);
	XCTAssertEqualObjects([ex pattern], @"pattern");
	XCTAssertEqual([ex options], 0);
}

@end
