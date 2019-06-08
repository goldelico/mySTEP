//
//  XCTest.h
//
//  Created by H. Nikolaus Schaller on 07.05.17.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//
//  This is a wrapper around SenTestingKit to provide the newer XCTest API
//  The special gcc only syntax ##__VA_ARGS__ allows to omit the ... part
//

#ifdef __mySTEP__
#import <SenTestingKit/SenTestingKit.h>

/*
 map to
 #define STAssertNotNil(a1, description, ...)
 #define STAssertTrue(expression, description, ...)
 #define STAssertFalse(expression, description, ...)
 #define STAssertEqualObjects(a1, a2, description, ...)
 #define STAssertEquals(a1, a2, description, ...)
 #define STAssertEqualsWithAccuracy(left, right, accuracy, description, ...)
 #define STAssertThrows(expression, description, ...)
 #define STAssertThrowsSpecific(expression, specificException, description, ...)
 #define STAssertThrowsSpecificNamed(expr, specificException, aName, description, ...)
 #define STAssertNoThrow(expression, description, ...)
 #define STAssertNoThrowSpecific(expression, specificException, description, ...)
 #define STAssertNoThrowSpecificNamed(expr, specificException, aName, description, ...)
 #define STFail(description, ...)
 #define STAssertTrueNoThrow(expression, description, ...)
 #define STAssertFalseNoThrow(expression, description, ...)
 
 So the key issue to be solved is mapping the optional description of the XC macros,
 i.e. that ... is empty to an existing (nil or @"") one of the ST macros
*/

// handle the case that the ... is empty
// some tricks with macros:
// refer to http://blog.refu.co/?p=593

#define XCTest SenTest
#define XCTestCase SenTestCase

#define XCTAssert(C, ...)				STAssertTrue(C, @"" __VA_ARGS__)
#define XCTAssertTrue(C, ...)			STAssertTrue(C, @"" __VA_ARGS__)
#define XCTAssertFalse(C, ...)			STAssertFalse(C, @"" __VA_ARGS__)
#define XCTAssertNotNil(O, ...)			STAssertNotNil(O, @"" __VA_ARGS__)
#define XCTAssertNil(O, ...)			STAssertNil(O, @"" __VA_ARGS__)
#define XCTAssertEqual(A, B, ...)		STAssertEquals(A, B, @"" __VA_ARGS__)
#define XCTAssertEqualObjects(A, B, ...) \
										STAssertEqualObjects(A, B, @"" __VA_ARGS__)
#define XCTAssertThrows(E, ...)			STAssertThrows(E, @"" __VA_ARGS__)
#define XCTAssertNoThrow(E, ...)		STAssertNoThrow(E, @"" __VA_ARGS__)
#define XCTAssertThrowsSpecific(E, C, ...) \
										STAssertThrowsSpecific(E, C, @"" __VA_ARGS__)
#define XCTAssertThrowsSpecificNamed(E, C, N, ...) \
										STAssertThrowsSpecificNamed(E, C, N, @"" __VA_ARGS__)

#endif
