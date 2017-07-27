//
//  XCTest.h
//
//  Created by H. Nikolaus Schaller on 07.05.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  This is a wrapper around SenTestingKit to provide the newer XCTest API
//

#import <SenTestingKit/SenTestingKit.h>

#define XCTest SenTest
#define XCTestCase SenTestCase

#define XCTAssertTrue(C, ...)			STAssertTrue(C, __VA_ARGS__)
#define XCTAssertFalse(C, ...)			STAssertFalse(C, __VA_ARGS__)
#define XCTAssertNotNil(O, ...)			STAssertNotNil(O, __VA_ARGS__)
#define XCTAssertNil(O, ...)			STAssertNil(O, __VA_ARGS__)
#define XCTAssertEqual(A, B, ...)		STAssertEquals(A, B, __VA_ARGS__)
#define XCTAssertEqualObjects(A, B, ...)	STAssertEqualObjects(A, B, __VA_ARGS__)
#define XCTAssertThrows(E, ...)			STAssertThrows(E, __VA_ARGS__)
#define XCTAssertNoThrow(E, ...)		STAssertNoThrow(E, __VA_ARGS__)
