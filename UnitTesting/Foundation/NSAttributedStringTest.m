//
//  NSAttributedStringTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 11.04.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSAttributedStringTest.h"

@interface NSColor : NSObject
+ (id) redColor;
+ (id) blueColor;
@end

@implementation NSColor
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
	STAssertEqualObjects(@"string", [s string], nil);
	STAssertEquals([s length], 6u, nil);
	STAssertNotNil([s attributesAtIndex:0 effectiveRange:NULL], nil);	// return empty NSDictionary and not nil
	STAssertEquals([[s attributesAtIndex:0 effectiveRange:NULL] count], 0u, nil);	
	[s release];
}

- (void) test2
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"string"];
	STAssertEqualObjects(@"string", [s string], nil);
	STAssertEquals([s length], 6u, nil);
	STAssertNotNil([s attributesAtIndex:0 effectiveRange:NULL], nil);	// return empty NSDictionary and not nil
	STAssertEquals([[s attributesAtIndex:0 effectiveRange:NULL] count], 0u, nil);	
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor redColor], NSForegroundColorAttributeName, nil] range:NSMakeRange(0, 3)];
	STAssertEquals([[s attributesAtIndex:0 effectiveRange:NULL] count], 1u, nil);	
	STAssertEquals([[s attributesAtIndex:3 effectiveRange:NULL] count], 0u, nil);	
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSColor blueColor], NSForegroundColorAttributeName, nil] range:NSMakeRange(3, 3)];
	STAssertEquals([[s attributesAtIndex:0 effectiveRange:NULL] count], 1u, nil);	
	STAssertEquals([[s attributesAtIndex:3 effectiveRange:NULL] count], 1u, nil);	
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

- (void) test3
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"string"];
	[[s mutableString] setString:@"a much longer string"];
	// test what happens...
	[s release];
}

// add more tests
// e.g. empty string
// trying to add nil attribute
// attributes if we insert a string w/o attributes

@end
