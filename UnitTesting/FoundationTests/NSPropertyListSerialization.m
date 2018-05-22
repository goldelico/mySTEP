//
//  NSPropertyListSerialization.m
//  UnitTests
//
//  Note: SenTestingKit requires a working implementation of NSValue!
//        Therefore it is tricky do work on that class through test driven development.
//
//  Created by H. Nikolaus Schaller on 01.03.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSPropertyListSerializationTest : XCTestCase
{
	
}

@end


@implementation NSPropertyListSerializationTest

- (void) test1
{
	NSError *error=nil;
	id obj=[NSMutableDictionary dictionaryWithCapacity:100];
	NSJSONWritingOptions opts=0;
#if 1
	opts=NSJSONWritingPrettyPrinted;
#endif
	[obj setObject:[NSNull null] forKey:@"NSNull"];
	[obj setObject:[NSNumber numberWithBool:NO] forKey:@"bool_no"];
	[obj setObject:[NSNumber numberWithBool:YES] forKey:@"bool_yes"];
	[obj setObject:[NSNumber numberWithInt:12345] forKey:@"integer"];
	[obj setObject:[NSNumber numberWithDouble:M_PI] forKey:@"float"];
	// raises an exception if we find an NSURL inside!!!
	// raises exception if obj is nil!!!
	NSData *data=[NSJSONSerialization dataWithJSONObject:obj options:opts error:&error];
	NSString *str=[[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	NSLog(@"NSJSONSerialization test %@ %@", str, error);
}

@end
