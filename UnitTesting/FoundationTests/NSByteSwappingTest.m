//
//  NSByteSwappingTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>


@interface NSByteSwappingTest : XCTestCase {
	
}

@end


@implementation NSByteSwappingTest

- (void) test1
{ // test byte swapping methods for correctness
	float flt=M_PI;
	double dbl=M_PI;
#if OLD
		{
			float want, have;
			float dwant, dhave;
			NSLog(@"host is %@", NSHostByteOrder() == NS_BigEndian?@"BigEndian":@"LittleEndian");
			NSLog(@"%.30g", NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt)));
			have=NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt));
			want=-4.033146e+16;
			NSLog(@"%08x %08x", *(long *)&have, *(long *)&want);
			NSLog(@"%.30g", NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt)));
			have=NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt));
			want=M_PI;
			NSLog(@"%08x %08x", *(long *)&have, *(long *)&want);
			NSLog(@"%.30g", NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl)));
			dhave=NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl));
			dwant=3.20737563067636581208678536384e-192;
			NSLog(@"%016llx %016llx", *(long long *)&have, *(long long *)&want);
			NSLog(@"%.30g", NSSwapLittleDoubleToHost(*((NSSwappedDouble *)&dbl)));
		}
#endif
	XCTAssertEqual(NSSwapShort(0x1234), (unsigned short)0x3412, @"NSSwapShort failed");
	XCTAssertEqual(NSSwapLong(0x12345678L), 0x7856341200000000UL, @"NSSwapLong failed");
	XCTAssertEqual(NSSwapLongLong(0x123456789abcdef0LL), 0xf0debc9a78563412LL, @"NSSwapLongLong failed");
	XCTAssertEqual(NSSwapBigFloatToHost(*((NSSwappedFloat *)&flt)), ((NSHostByteOrder() == NS_LittleEndian)?(float)-40331460896358400.0:(float)M_PI), @"NSSwapBigFloatToHost failed");
	XCTAssertEqual(NSSwapLittleFloatToHost(*((NSSwappedFloat *)&flt)), ((NSHostByteOrder() == NS_BigEndian)?(float)-40331460896358400.0:(float)M_PI), @"NSSwapLittleFloatToHost failed");
	XCTAssertEqual(NSSwapBigDoubleToHost(*((NSSwappedDouble *)&dbl)), ((NSHostByteOrder() == NS_LittleEndian)?3.20737563067636581208678536384e-192:M_PI), @"NSSwapBigDoubleToHost failed");
	XCTAssertEqual(NSSwapLittleDoubleToHost(*((NSSwappedDouble *)&dbl)), ((NSHostByteOrder() == NS_BigEndian)?3.20737563067636581208678536384e-192:M_PI), @"NSSwapLittleDoubleToHost failed");
}

@end
