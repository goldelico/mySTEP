//
//  NSStringDrawingTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=a; typeof(b) _b=b; \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(b))], \
		##__VA_ARGS__); })


@interface NSStringDrawingTest : XCTestCase {
	
}

@end

@implementation NSStringDrawingTest

// test sizing of strings and attributed strings

- (void) test1;
{
	NSSize sz=[@"abc" sizeWithAttributes:nil];
	XCTAssertEquals(sz.width, 20.0f, @"");
	XCTAssertEquals(sz.height, 1.25f*12.0f, @"");
	/* conclusions
	 * default font size is 12pt and 25% line spacing
	 */
}

- (void) test2;
{
	NSSize sz=[@"" sizeWithAttributes:nil];	// empty string is the same
	XCTAssertEquals(sz.width, 0.0f, @"");	// no width
	XCTAssertEquals(sz.height, 1.25f*12.0f, @"");
	/* conclusions
	 * empty string uses the same 12pt default font
	 */
}

- (void) test3;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
	NSSize sz1=[@"abc" sizeWithAttributes:nil];
	NSSize sz2=[@"abc" sizeWithAttributes:attr];
	XCTAssertEquals(sz1.width, sz2.width, @"");
	XCTAssertEquals(sz1.height, sz2.height, @"");
	sz1=[@"ABCDEF GHIJK" sizeWithAttributes:nil];
	sz2=[@"ABCDEF GHIJK" sizeWithAttributes:attr];
	XCTAssertEquals(sz1.width, sz2.width, @"");
	XCTAssertEquals(sz1.height, sz2.height, @"");
	/* conclusions
	 * it appears to be Helvetica 12 because we get same width and height for different strings
	 */
}

- (void) test4;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"abc" sizeWithAttributes:attr];
	XCTAssertEquals(sz.height, 1.25f*24.0f, @"");
	/* conclusions:
	 * size depends on font - as expected
	 */
}

- (void) test5;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"" sizeWithAttributes:attr];
	XCTAssertEquals(sz.width, 0.0f, @"");
	XCTAssertEquals(sz.height, 1.25f*24.0f, @"");
	/* conclusions:
	 * size depends on font attribute even for an empty string!
	 */
}

- (void) test6;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"abc" attributes:attr] autorelease];
	NSSize sz=[astr size];
	XCTAssertEquals(sz.height, 1.25f*24.0f, @"");
	/* conclusions:
	 * size can be stored in attributedString - as expected
	 */
}

- (void) test7;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"" attributes:attr] autorelease];
	NSSize sz=[astr size];
	XCTAssertEquals(sz.width, 0.0f, @"");
	XCTAssertEquals(sz.height, 1.25f*12.0f, @"");
	/* conclusions:
	 * an empty attributed string can't store a font - so the default applies!
	 */
}

// check that size is the same as infinite bounds for a string with multiple lines

@end
