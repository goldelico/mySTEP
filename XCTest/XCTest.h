//
//  XCTest.h
//
//  Created by H. Nikolaus Schaller on 07.05.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
// This is a wrapper around SenTestingKit to provide the newer XCTest API
//

#import <SenTestingKit/SenTestingKit.h>

#define XCTest SenTest
#define XCTestCase SenTestCase

#define XCTAssertTrue(C)			STAssertTrue(C, nil)
#define XCTAssertFalse(C)			STAssertFalse(C, nil)
#define XCTAssertNotNil(O)			STAssertNotNil(O, nil)
#define XCTAssertNil(O)				STAssertNil(O, nil)
#define XCTAssertEqual(A, B)		STAssertEquals(A, B, nil)
#define XCTAssertEqualObjects(A, B)	STAssertEqualObjects(A, B, nil)
#define XCTAssertThrows(E)			STAssertThrows(E, nil)
#define XCTAssertNoThrow(E)			STAssertNoThrow(E, nil)
