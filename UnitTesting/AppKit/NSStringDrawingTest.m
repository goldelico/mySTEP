//
//  NSStringDrawingTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSStringDrawingTest.h"

#define STAssertEqualFloats(A, B) STAssertTrue(A == B, @"%g == %g", A, B)

@implementation NSStringDrawingTest

// test sizing of strings and attributed strings

- (void) test1;
{
	NSSize sz=[@"abc" sizeWithAttributes:nil];
	STAssertEqualFloats(sz.width, 20.0);
	STAssertEqualFloats(sz.height, 1.25*12);
	/* conclusions
	 * default font size is 12pt and 25% line spacing
	 */
}

- (void) test2;
{
	NSSize sz=[@"" sizeWithAttributes:nil];	// empty string is the same
	STAssertEqualFloats(sz.width, 0);	// no width
	STAssertEqualFloats(sz.height, 1.25*12);
	/* conclusions
	 * empty string uses the same 12pt default font
	 */
}

- (void) test3;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:12], NSFontAttributeName, nil];
	NSSize sz1=[@"abc" sizeWithAttributes:nil];
	NSSize sz2=[@"abc" sizeWithAttributes:attr];
	STAssertEqualFloats(sz1.width, sz2.width);
	STAssertEqualFloats(sz1.height, sz2.height);
	sz1=[@"ABCDEF GHIJK" sizeWithAttributes:nil];
	sz2=[@"ABCDEF GHIJK" sizeWithAttributes:attr];
	STAssertEqualFloats(sz1.width, sz2.width);
	STAssertEqualFloats(sz1.height, sz2.height);
	/* conclusions
	 * it appears to be Helvetica 12 because we get same width and height for different strings
	 */
}

- (void) test4;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"abc" sizeWithAttributes:attr];
	STAssertEqualFloats(sz.height, 1.25*24);
	/* conclusions:
	 * size depends on font - as expected
	 */
}

- (void) test5;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSSize sz=[@"" sizeWithAttributes:attr];
	STAssertEqualFloats(sz.width, 0.0);
	STAssertEqualFloats(sz.height, 1.25*24);
	/* conclusions:
	 * size depends on font attribute even for an empty string!
	 */
}

- (void) test6;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"abc" attributes:attr] autorelease];
	NSSize sz=[astr size];
	STAssertEqualFloats(sz.height, 1.25*24);
	/* conclusions:
	 * size can be stored in attributedString - as expected
	 */
}

- (void) test7;
{
	NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Helvetica" size:24], NSFontAttributeName, nil];
	NSAttributedString *astr=[[[NSAttributedString alloc] initWithString:@"" attributes:attr] autorelease];
	NSSize sz=[astr size];
	STAssertEqualFloats(sz.width, 0.0);
	STAssertEqualFloats(sz.height, 1.25*12);
	/* conclusions:
	 * an empty attributed string can't store a font - so the default applies!
	 */
}

// check that size is the same as infinite bounds for a string with multiple lines

@end
