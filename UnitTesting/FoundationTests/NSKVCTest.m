//
//  NSKVCTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 27.07.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface KVCObject : NSObject
{
	NSObject *_object;
	id _id;
	int _int;
	float _float;
	double _double;
}

@end

static BOOL _accessDirectly;

@implementation KVCObject

+ (BOOL) accessInstanceVariablesDirectly
{
	return _accessDirectly;
}

- (id) init;
{
	if((self=[super init]))
		{
		_object=[NSObject new];
		_id=self;
		_int=31415;
		_float=3.1415;
		_double=3.1415926575;
		}
	return self;
}

- (NSObject *) objectValue; { return _object; }
- (id) idValue; { return _id; }
- (int) intValue; { return _int; }
- (int) floatValue; { return _float; }
- (int) doubleValue; { return _double; }

@end

@interface KVCTest : XCTestCase
{
	KVCObject *_test;
}

@end

@implementation KVCTest

- (void) setUp
{
	_test=[KVCObject new];
}

- (void) tearDown
{
}

- (void) test01
{
	XCTAssertNotNil(_test, @"");
}

- (void) test02
{
	XCTAssertEqualObjects([_test objectValue], [_test valueForKey:@"objectValue"], @"");	// use getter
	// FIXME: raises valueForUndefinedKey exception
	XCTAssertEqualObjects([_test objectValue], [_test valueForKey:@"_object"], @"");	// use iVar

	XCTAssertEqualObjects([_test idValue], [_test valueForKey:@"idValue"], @"");	// use getter
	XCTAssertNotEqualObjects([_test idValue], [_test valueForKey:@"objectValue"], @"");	// use getter
// FIXME: raises exception
	XCTAssertEqualObjects([_test idValue], [_test valueForKey:@"id"], @"");	// use iVar
}

// Problem: wenn man mit _accessDirectly=NO versucht auf eine vorhandene iVar zuzugreifen, merkt sich Cocoa das irgendwie...

- (void) test03
{
	_accessDirectly=YES;
	XCTAssertEqualObjects([_test objectValue], [_test valueForKey:@"objectValue"], @"");	// use getter
	XCTAssertEqualObjects([_test objectValue], [_test valueForKey:@"object"], @"");	// access iVar directly
	XCTAssertEqualObjects([_test idValue], [_test valueForKey:@"idValue"], @"");	// use getter
	XCTAssertEqualObjects([_test idValue], [_test valueForKey:@"id"], @"");	// use iVar
	_accessDirectly=NO;
}

- (void) test04
{
	id ret;
	ret=[_test valueForKey:@"intValue"];
	NSLog(@"%@", ret);
	XCTAssertTrue([ret isKindOfClass:[NSNumber class]]);
	XCTAssertTrue([ret integerValue] == 31415);
	_accessDirectly=YES;
	ret=[_test valueForKey:@"int"];
	NSLog(@"%@", ret);
	XCTAssertTrue([ret isKindOfClass:[NSNumber class]]);
	XCTAssertTrue([ret integerValue] == 31415);
	_accessDirectly=NO;
}

- (void) test05
{
	id ret;
	ret=[_test valueForKey:@"floatValue"];
	NSLog(@"%@", ret);
	XCTAssertTrue([ret isKindOfClass:[NSNumber class]]);
	XCTAssertTrue([ret floatValue] == 3.1415);
}

- (void) test06
{
	id ret;
	ret=[_test valueForKey:@"doubleValue"];
	NSLog(@"%@", ret);
	XCTAssertTrue([ret isKindOfClass:[NSNumber class]]);
	XCTAssertTrue([ret doubleValue] == 3.1415926575);
}

- (void) test99;
{

#if 0
	XCTAssertThrowsSpecific([has removeObjectsAtIndexes:nil], NSException);
	XCTAssertThrowsSpecific([has insertObjects:t atIndexes:nil], NSException);
	NSMutableIndexSet *idx=[NSMutableIndexSet indexSetWithIndex:1];
	XCTAssertThrowsSpecific([has insertObjects:nil atIndexes:idx], NSException);
	// FIXME: this is a method of NSArray and not NSMutableArray...
	XCTAssertThrowsSpecific([has objectsAtIndexes:nil], NSException);
#endif
}

@end
