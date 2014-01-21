//
//  NSStringDrawingTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SenTestingKit/SenTestingKit.h>


@interface NSStringDrawingTest : SenTestCase {
	
}

@end

@implementation NSStringDrawingTest

// test sizing of strings and attributed strings

- (void) test1;
{
	NSSize sz=[@"abc" sizeWithAttributes:nil];
	STAssertEquals(sz.width, 20.0f, nil);
	STAssertEquals(sz.height, 1.25f*12.0f, nil);
	/* conclusions
	 * default font size is 12pt and 25% line spacing
	 */
}

- (void) test2;
{
	NSSize sz=[@"" sizeWithAttributes:nil];	// empty string is the same
	STAssertEquals(sz.width, 0.0f, nil);	// no width
	STAssertEquals(sz.height, 1.25f*12.0f, nil);
	/* conclusions
	 * empty string uses the same 12pt default font
	 */
}

- (void) test3;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
	NSSize sz1=[@"abc" sizeWithAttributes:nil];
	NSSize sz2=[@"abc" sizeWithAttributes:attr];
	STAssertEquals(sz1.width, sz2.width, nil);
	STAssertEquals(sz1.height, sz2.height, nil);
	sz1=[@"ABCDEF GHIJK" sizeWithAttributes:nil];
	sz2=[@"ABCDEF GHIJK" sizeWithAttributes:attr];
	STAssertEquals(sz1.width, sz2.width, nil);
	STAssertEquals(sz1.height, sz2.height, nil);
	/* conclusions
	 * it appears to be Helvetica 12 because we get same width and height for different strings
	 */
}

- (void) test4;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"abc" sizeWithAttributes:attr];
	STAssertEquals(sz.height, 1.25f*24.0f, nil);
	/* conclusions:
	 * size depends on font - as expected
	 */
}

- (void) test5;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"" sizeWithAttributes:attr];
	STAssertEquals(sz.width, 0.0f, nil);
	STAssertEquals(sz.height, 1.25f*24.0f, nil);
	/* conclusions:
	 * size depends on font attribute even for an empty string!
	 */
}

- (void) test6;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"abc" attributes:attr] autorelease];
	NSSize sz=[astr size];
	STAssertEquals(sz.height, 1.25f*24.0f, nil);
	/* conclusions:
	 * size can be stored in attributedString - as expected
	 */
}

- (void) test7;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"" attributes:attr] autorelease];
	NSSize sz=[astr size];
	STAssertEquals(sz.width, 0.0f, nil);
	STAssertEquals(sz.height, 1.25f*12.0f, nil);
	/* conclusions:
	 * an empty attributed string can't store a font - so the default applies!
	 */
}

// check that size is the same as infinite bounds for a string with multiple lines

@end
