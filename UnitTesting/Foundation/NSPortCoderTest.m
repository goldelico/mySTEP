//
//  NSPortCoderTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPortCoderTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit

@interface NSPortCoder (NSConcretePortCoder)

- (NSArray *) components;

@end

@implementation NSPortCoderTest

- (void) testInit
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have=[pc components];
	NSString *want=[NSArray arrayWithObject:[NSData data]];	// one empty data component
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testChar1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val=1;
	NSString *have;
	NSString *want=@"<01>";	// has no length encoding (!)
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testChar
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val='x';
	NSString *have;
	NSString *want=@"<78>";
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testCharM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val=-1;
	NSString *have;
	NSString *want=@"<ff>";
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testInt0
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=0;
	NSString *have;
	NSString *want=@"<00>";	// 0 length
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testInt1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=1;
	NSString *have;
	NSString *want=@"<0101>";	// can be encoded in 1 byte - i.e. encoder tries to figure out number of significant bytes
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testInt2
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=10240;
	NSString *have;
	NSString *want=@"<020028>";	// 2 bytes integer; we also see little-endian encoding (LSB first)
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testLong255
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long val=255;
	NSString *have;
	NSString *want=@"<01ff>";	// 1 byte integer
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testLongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long val=-1;
	NSString *have;
	NSString *want=@"<ffff>";	// -1 byte negative integer; we also see little-endian encoding (LSB first)
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testULongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	unsigned long val=-1;
	NSString *have;
	NSString *want=@"<ffff>";	// -1 byte negative integer; we also see little-endian encoding (LSB first) - coding depends on bit pattern only; not on signed/unsigned
	[pc encodeValueOfObjCType:@encode(unsigned long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testLongLong
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long long val=12345678987654321;
	NSString *have;
	NSString *want=@"<07b1f491 6254dc2b>";	// 7 significant bytes
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testLongLongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long long val=-1L;
	NSString *have;
	NSString *want=@"<ffff>";	// hm... does this indicate "we can't encode"?
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testFloat
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	float val=M_PI;
	NSString *have;
	NSString *want=@"<04db0f49 40>";	// 04 bytes + data
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testFloat1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	float val=1.0;
	NSString *have;
	NSString *want=@"<04000080 3f>";	// 04 bytes + data, i.e. here is no compression - we also see Little-Endian encoding (at least on an Intel Mac)
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testDouble
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	double val=M_PI;
	NSString *have;
	NSString *want=@"<08182d44 54fb2109 40>";	// 08 bytes + data
	[pc encodeValueOfObjCType:@encode(double) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testClass
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	Class val=[NSData class];
	NSString *have;
	NSString *want=@"<0101074e 53446174 6100>";	// prefix 0x01, 01 bytes length, 07 bytes string, "NSData\0"
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testClassNil
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	Class val=Nil;
	NSString *have;
	NSString *want=@"<0101046e 696c00>";	// prefix 0x01, 01 bytes length, 04 bytes string, "nil\0"
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testSelector
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	SEL val=_cmd;
	NSString *have;
	NSString *want=@"<01010d74 65737453 656c6563 746f7200>";	// prefix 0x01, 01 bytes length, 0d bytes string, "testSelector\0"
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testSelectorUTF
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	SEL val=NSSelectorFromString(@"€");
	NSString *have;
	NSString *want=@"<010104e2 82ac00>";	// prefix 0x01, 01 bytes length, 04 bytes string, UTF-8 encoded (€ -> 0xe2 0y82 0xac)
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testCString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char *val="C-String";
	NSString *have;
	NSString *want=@"<01010943 2d537472 696e6700>";	// prefix 0x01, 01 bytes length, 09 bytes string, "C-String\0"
	[pc encodeValueOfObjCType:@encode(char *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testNil
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<00>";
	[pc encodeObject:nil];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";
	[pc encodeObject:@"String"];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testStringUTF8
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<01010109 4e535374 72696e67 00010101 000103e2 82ac01>";	// 0x01 prefix + Class(NSString) + some internals + UTF-8 string + 0x01 suffix
	[pc encodeObject:@"€"];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<01010107 4e534461 74610000 00010531 32333435 01>";	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:[NSData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testEncodeData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<00010531 32333435>";	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
	[pc encodeDataObject:[NSData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testEncodeMutableData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<00010531 32333435>";	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
	[pc encodeDataObject:[NSMutableData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testDistantObject
{
	// set up connection
	// aquire a distant object
	// encode
	// strip off sequence number/object-id
}

- (void) testPort
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSPort *port=[NSPort port];
	NSString *have;
	NSString *want=@"<01010107 4e53506f 72740000 01>";	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:port];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testThisConnection
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSString *have;
	NSString *want=@"<00>";	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:connection];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testOtherConnection
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSConnection *c=nil;
	NSString *have;
	NSString *want=@"<00>";	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:c];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

- (void) testException
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSException *e=[NSException exceptionWithName:@"name" reason:@"reason" userInfo:[NSDictionary dictionaryWithObject:@"object" forKey:@"key"]];
	NSString *have;
	NSString *want=@"<0101010c 4e534578 63657074 696f6e00 00010101 094e5353 7472696e 67000101 01000104 6e616d65 01010101 094e5353 7472696e 67000101 01000106 72656173 6f6e0101 01010d4e 53446963 74696f6e 61727900 00010101 0101094e 53537472 696e6700 01010100 01036b65 79010101 01094e53 53747269 6e670001 01010001 066f626a 65637401 0101>";
	[pc encodeObject:e];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(want, have, nil);
	[pc release];
}

// could override
// - (void) setUp;
// - (void) tearDown;

@end
