//
//  NSAttributedStringTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 11.04.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>


@interface NSAttributedStringTest : XCTestCase {
	
}

@end

@interface Mock_NSColor : NSObject
+ (id) redColor;
+ (id) blueColor;
@end

@implementation Mock_NSColor
+ (id) redColor;
{
	return [[self new] autorelease];
}
+ (id) blueColor;
{
	return [[self new] autorelease];
}
@end

NSString *NSForegroundColorAttributeName=@"NSForegroundColorAttributeName";

@implementation NSAttributedStringTest

- (void) test1
{
	NSAttributedString *s=[[NSAttributedString alloc] initWithString:@"string"];
	XCTAssertEqualObjects(@"string", [s string], @"");
	XCTAssertEqual([s length], (NSUInteger) 6, @"");
	XCTAssertNotNil([s attributesAtIndex:0 effectiveRange:NULL], @"");	// return empty NSDictionary and not nil
	XCTAssertEqual([[s attributesAtIndex:0 effectiveRange:NULL] count], (NSUInteger) 0, @"");
	[s release];
}

- (void) test2
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"string"];
	XCTAssertEqualObjects(@"string", [s string], @"");
	XCTAssertEqual([s length], (NSUInteger) 6, @"");
	XCTAssertNotNil([s attributesAtIndex:0 effectiveRange:NULL], @"");	// return empty NSDictionary and not nil
	XCTAssertEqual([[s attributesAtIndex:0 effectiveRange:NULL] count], (NSUInteger) 0, @"");
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Mock_NSColor redColor], NSForegroundColorAttributeName, nil] range:NSMakeRange(0, 3)];
	XCTAssertEqual([[s attributesAtIndex:0 effectiveRange:NULL] count], (NSUInteger) 1, @"");
	XCTAssertEqual([[s attributesAtIndex:3 effectiveRange:NULL] count], (NSUInteger) 0, @"");
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[Mock_NSColor blueColor], NSForegroundColorAttributeName, nil] range:NSMakeRange(3, 3)];
	XCTAssertEqual([[s attributesAtIndex:0 effectiveRange:NULL] count], (NSUInteger) 1, @"");
	XCTAssertEqual([[s attributesAtIndex:3 effectiveRange:NULL] count], (NSUInteger) 1, @"");
	[s release];
}

- (void) searchData:(id) obj
{
	if([obj isKindOfClass:[NSData class]])
		NSLog(@"%@", obj);
	else if([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]])
			{
				NSEnumerator *e=[obj objectEnumerator];
				while((obj=[e nextObject]))
					[self searchData:obj];
			}
}

- (void) analyse:(NSData *) d
{
	NSPropertyListFormat format;
	NSString *error;
	id obj=[NSPropertyListSerialization propertyListFromData:d mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
	[self searchData:obj];
}

// FIXME: this is very incomplete...

- (void) test3
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"string"];
	[[s mutableString] setString:@"a much longer string"];
	// test what happens...
	[s release];
}

- (void) test4
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"type here"];
	NSRange rng;
	XCTAssertEqual([s length], (NSUInteger) 9);
	[s replaceCharactersInRange:NSMakeRange(0, 0) withString:@""];	// empty replacement
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 9);
	[s replaceCharactersInRange:NSMakeRange([s length], 0) withString:@""];	// empty replacement at end
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 9);
	[s replaceCharactersInRange:NSMakeRange(0, 0) withString:@" "];	// add at beginning
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 10);
	XCTAssertEqualObjects([s string], @" type here");
	[s replaceCharactersInRange:NSMakeRange(0, 1) withString:@""];	// remove at beginning
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 9);
	XCTAssertEqualObjects([s string], @"type here");
	[s replaceCharactersInRange:NSMakeRange([s length], 0) withString:@" "];	// add at end
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 10);
	XCTAssertEqualObjects([s string], @"type here ");
	[s replaceCharactersInRange:NSMakeRange([s length]-1, 1) withString:@""];	// remove at end
	[s attributesAtIndex:0 effectiveRange:&rng];
	XCTAssertEqual([s length], (NSUInteger) 9);
	XCTAssertEqualObjects([s string], @"type here");
	// test what happens...
	[s release];
}

// add more tests
// e.g. empty string
// trying to add nil attribute
// attributes if we insert a string w/o attributes

@end
