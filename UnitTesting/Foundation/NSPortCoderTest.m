//
//  NSPortCoderTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPortCoderTest.h"


@interface NSPortCoder (NSConcretePortCoder)
- (NSArray *) components;
- (void) encodeInvocation:(NSInvocation *) i;
- (void) encodeReturnValue:(NSInvocation *) r;
@end

#if 0	// test our mySTEP implementation

// make NSPrivate.h compile on Cocoa Foundation

#ifndef ASSIGN
#define ASSIGN(var, val) ([var release], var=[val retain])
#endif
#define objc_malloc(A) malloc((A))
#define objc_realloc(A, B) realloc((A), (B))
#define objc_free(A) free(A)
#define _NSXMLParserReadMode int
#define GSBaseCString NSObject
#define arglist_t void *
#define retval_t void *
#define METHOD_NULL NULL
#define SEL_EQ(S1, S2) S1==S2
#define class_get_instance_method class_getInstanceMethod
#define NIMP (NSLog(@"not implemented: %@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)), (void *) 0)

#ifdef __APPLE__
#import <objc/objc-class.h>	// #define _C_ID etc.
// unknown on Apple runtime
#define _C_ATOM     '%'
#define _C_LNG_LNG  'q'
#define _C_ULNG_LNG 'Q'
#define _C_VECTOR   '!'
#define _C_COMPLEX   'j'
#endif

// rename our implementation to avoid conflicts with Cocoa

#define NSPortCoder myNSPortCoder
#define NSPortMessage myNSPortMessage

#import "../../Foundation/Sources/NSPortCoder.h"
#import "../../Foundation/Sources/NSPortMessage.h"
#import "../../Foundation/Sources/NSPortCoder.m"
#endif

@implementation NSPortCoderTest

- (void) testInit
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have=[pc components];
	id want=[NSArray arrayWithObject:[NSData data]];	// one empty data component
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testChar1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val=1;
	id have;
	id want=@"<01>";	// has no length encoding (!)
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testChar
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val='x';
	id have;
	id want=@"<78>";
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testCharM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char val=-1;
	id have;
	id want=@"<ff>";
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInt0
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=0;
	id have;
	id want=@"<00>";	// 0 length
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInt1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=1;
	id have;
	id want=@"<0101>";	// can be encoded in 1 byte - i.e. encoder tries to figure out number of significant bytes
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInt2
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val=10240;
	id have;
	id want=@"<020028>";	// 2 bytes integer; we also see little-endian encoding (LSB first)
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testLong255
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long val=255;
	id have;
	id want=@"<01ff>";	// 1 byte integer
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testLongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long val=-1;
	id have;
	id want=@"<ffff>";	// -1 byte negative integer; we also see little-endian encoding (LSB first)
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testULongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	unsigned long val=-1;
	id have;
	id want=@"<ffff>";	// -1 byte negative integer; we also see little-endian encoding (LSB first) - coding depends on bit pattern only; not on signed/unsigned
	[pc encodeValueOfObjCType:@encode(unsigned long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testLongLong
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long long val=12345678987654321LL;
	id have;
	id want=@"<07b1f491 6254dc2b>";	// 7 significant bytes
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testLongLongM1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	long long val=-1L;
	id have;
	id want=@"<ffff>";	// hm... does this indicate "we can't encode"?
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testFloat
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	float val=M_PI;
	id have;
	id want=@"<04db0f49 40>";	// 04 bytes + data
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testFloat1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	float val=1.0;
	id have;
	id want=@"<04000080 3f>";	// 04 bytes + data, i.e. here is no compression - we also see Little-Endian encoding (at least on an Intel Mac)
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testDouble
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	double val=M_PI;
	id have;
	id want=@"<08182d44 54fb2109 40>";	// 08 bytes + data
	[pc encodeValueOfObjCType:@encode(double) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testClass
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	Class val=[NSData class];
	id have;
	id want=@"<0101074e 53446174 6100>";	// prefix 0x01, 01 bytes length, 07 bytes string, "NSData\0"
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testClassNil
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	Class val=Nil;
	id have;
	id want=@"<0101046e 696c00>";	// prefix 0x01, 01 bytes length, 04 bytes string, "nil\0"
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
#if 1	// find out what <00> returns when decoded as Class => returns Nil
	pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:[NSArray arrayWithObject:[NSData dataWithBytes:"\0" length:2]]];
	[pc decodeValueOfObjCType:@encode(Class) at:&val];
	NSLog(@"class=%@", NSStringFromClass(val));
	[pc release];
#endif
}

- (void) testClassNSObject
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	Class val=[NSObject class];
	id have;
	id want=@"<0101094e 534f626a 65637400>";	// prefix 0x01, 01 bytes length, 09 bytes string, "NSObject\0"
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
#if 1	// preliminary decoder test
	pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:[NSArray arrayWithObject:[NSData dataWithBytes:"\1\1\x9NSObject\0" length:12]]];
	[pc decodeValueOfObjCType:@encode(Class) at:&val];
	NSLog(@"class=%@", NSStringFromClass(val));
	[pc release];
#endif
}

- (void) testSelector
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	SEL val=_cmd;
	id have;
	id want=@"<01010d74 65737453 656c6563 746f7200>";	// prefix 0x01, 01 bytes length, 0d bytes string, "testSelector\0"
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testSelectorUTF
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	SEL val=NSSelectorFromString(@"€");
	id have;
	id want=@"<010104e2 82ac00>";	// prefix 0x01, 01 bytes length, 04 bytes string, UTF-8 encoded (€ -> 0xe2 0y82 0xac)
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testCString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char *val="C-String";
	id have;
	id want=@"<01010943 2d537472 696e6700>";	// prefix 0x01, 01 bytes length, 09 bytes string, "C-String\0"
	[pc encodeValueOfObjCType:@encode(char *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testCNULL
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	char *val=NULL;
	id have;
	id want=@"<00>";	// prefix 0x00
	[pc encodeValueOfObjCType:@encode(char *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testIntArray
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int val[]={ 1, 2, 3, 256, 0 };
	id have;
	id want=@"<01010102 01030200 0100>";	// 5 times length, byte(s)
	[pc encodeValueOfObjCType:@encode(int [5]) at:&val];	// crashes of one specifies @encode(int [])
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testIntPointer
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int a[]={ 3, 5, 9, 11 };
	int *val=a;
	id have;
	id want=@"<010103>";	// looks as if this just encodes the first entry, i.e. *val
	[pc encodeValueOfObjCType:@encode(int *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testNULLIntPointer
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	int *val=NULL;
	id have;
	id want=@"<00>";	// NULL pointer
	[pc encodeValueOfObjCType:@encode(int *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

#if 0	// prints an "unencodable type (v)" error (exception?)

- (void) testVoid
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	void *val="void";
	id have;
	id want=@"<?>";
	[pc encodeValueOfObjCType:@encode(void) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testVoidPointer
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	void *val="C-String";
	id have;
	id want=@"<?>";
	[pc encodeValueOfObjCType:@encode(void *) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
//	STAssertThrows([pc encodeValueOfObjCType:@encode(void *) at:&val], nil);
	[pc release];
}

#endif

- (void) testPoint
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSPoint val=NSMakePoint(1.0, 2.0);
	id have;
	id want=@"<04000080 3f040000 0040>";	// 04 bytes length each component of the struct
	[pc encodePoint:val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testStruct
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	struct testStruct { char x; char *y; } val={ 'x', "y" };
	id have;
	id want=@"<78010102 7900>";	// 78 is first component; 01 is ???; 01 is length of len; 02 is length; 7900 is string value
	[pc encodeValueOfObjCType:@encode(struct testStruct) at:&val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testNil
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<00>";
	[pc encodeObject:nil];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testConstString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";	// Class(NSString) + contents
	[pc encodeObject:@"String"];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodeConstString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01065374 72696e67>";
	[@"String" encodeWithCoder:pc];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";	// Class(NSString) + contents
	[pc encodeObject:[@"xString" substringFromIndex:1]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodeString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01065374 72696e67>";	// contents
	[[@"xString" substringFromIndex:1] encodeWithCoder:pc];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testMutableString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010001 06537472 696e6701>";	// Class(NSMutableString) + Class(NSString) + contents
	[pc encodeObject:[NSMutableString stringWithString:@"String"]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodeMutableString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01065374 72696e67>";
	[[NSMutableString stringWithString:@"String"] encodeWithCoder:pc];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testLongString
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010002 01013031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663001>";
	[pc encodeObject:[@"" stringByPaddingToLength:257 withString:@"0123456789abcdef" startingAtIndex:0]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testStringUTF8
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 000103e2 82ac01>";	// 0x01 prefix + Class(NSString) + some internals + UTF-8 string + 0x01 suffix
	[pc encodeObject:@"€"];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<01010107 4e534461 74610000 00010531 32333435 01>";	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:[NSData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testMutableData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<0101010e 4e534d75 7461626c 65446174 61000000 01053132 33343501>";	// 0x01 prefix + Class(NSMutableData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
	[pc encodeObject:[NSMutableData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodeData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<00010531 32333435>";	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
	[pc encodeDataObject:[NSData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodeMutableData
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<00010531 32333435>";	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
	[pc encodeDataObject:[NSMutableData dataWithBytes:"12345" length:5]];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testDate
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id obj=[NSDate dateWithTimeIntervalSince1970:12345678];
	id have;
	id want=@"<01010107 4e534461 74650000 08000000 99b3c9cc c101>";	// 0x01 prefix + Class(NSDate) + 0x00 + 8 bytes double + 0x01 suffix
	[pc encodeObject:obj];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testCalendarDate
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id obj=[NSCalendarDate dateWithTimeIntervalSince1970:12345678];
	id have;
	id want=@"<0101010f 4e534361 6c656e64 61724461 74650000 08000000 99b3c9cc c1010101 0b4e5354 696d655a 6f6e6500 01010100 01010109 4e535374 72696e67 00010101 00010d45 75726f70 652f4265 726c696e 01010101 0e4e534d 75746162 6c654461 74610000 00024a03 545a6966 00000000 00000000 00000000 00000000 00000008 00000008 00000000 00000090 00000008 0000000e 9b0c1760 9bd5daf0 9cd9ae90 9da4b590 9eb99090 9f849790 c8097190 cce74b10 cda91790 cea24310 cf923410 d0822510 d1721610 d1b69600 d258be80 d2a14f10 d2db34f0 d3631b90 d44b2390 d539d120 d567e790 d5a87300 d629b410 d72c1a10 d8099610 d902c190 d9e97810 12ce97f0 134d4410 1433fa90 1523eb90 1613dc90 1703cd90 17f3be90 18e3af90 19d3a090 1ac39190 1bbcbd10 1cacae10 1d9c9f10 1e8c9010 1f7c8110 206c7210 215c6310 224c5410 233c4510 242c3610 251c2710 260c1810 27054390 27f53490 28e52590 29d51690 2ac50790 2bb4f890 2ca4e990 2d94da90 2e84cb90 2f74bc90 3064ad90 315dd910 3272b410 333dbb10 34529610 351d9d10 36327810 36fd7f10 381b9490 38dd6110 39fb7690 3abd4310 3bdb5890 3ca65f90 3dbb3a90 3e864190 3f9b1c90 40662390 41843910 42460590 43641b10 4425e790 4543fd10 4605c990 4723df10 47eee610 4903c110 49cec810 4ae3a310 4baeaa10 4cccbf90 4d8e8c10 4eaca190 4f6e6e10 508c8390 51578a90 526c6590 53376c90 544c4790 55174e90 562c2990 56f73090 58154610 58d71290 59f52810 5ab6f490 5bd50a10 5ca01110 5db4ec10 5e7ff310 5f94ce10 605fd510 617dea90 623fb710 635dcc90 641f9910 653dae90 6608b590 671d9090 67e89790 68fd7290 69c87990 6add5490 6ba85b90 6cc67110 6d883d90 6ea65310 6f681f90 70863510 71513c10 72661710 73311e10 7445f910 75110010 762f1590 76f0e210 780ef790 78d0c410 79eed990 7ab0a610 7bcebb90 7c99c290 7dae9d90 7e79a490 7f8e7f90 00010203 02030203 02030203 02040003 01020302 05000302 03020301 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 06070607 00001c20 01000000 0e100005 00001c20 01000000 0e100005 00002a30 01090000 2a300109 00001c20 01000000 0e100005 43455354 00434554 0043454d 54000000 01010001 01010000 00000000 01010101 01010109 4e535374 72696e67 00010101 00011425 592d256d 2d256420 25483a25 4d3a2553 20257a01 01>";
	NSLog(@"%@", NSStringFromSelector(_cmd));
	[pc encodeObject:obj];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testByrefObject
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id obj=@"string";
	id have;
	id want=@"???";
	if(!connection)
		want=@"<00>";		// if we have no connection, we can't propery encode...
	[pc encodeByrefObject:obj];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testBycopyObject
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id obj=@"string";
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010673 7472696e 6701>";
	[pc encodeBycopyObject:obj];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testDistantObject
{
}

- (void) testPort
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSPort *port=[NSPort port];
	id have;
	id want=@"<01010107 4e53506f 72740000 01>";	// 0x01 prefix + Class(NSPort) + 1 byte 00 (uninitialized?) + 0x01 suffix
	[pc encodeObject:port];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testEncodePort
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSPort *port=[NSPort port];
	id have;
	id want=@"<>";	// encodePortObject adds to components
	[pc encodePortObject:port];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	want=port;
	have=[[pc components] objectAtIndex:1];	// returns the port
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testThisConnection
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id have;
	id want=@"<00>";	// 0x00
	[pc encodeObject:connection];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testOtherConnection
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSConnection *c=nil;
	id have;
	id want=@"<00>";	// 0x00
	[pc encodeObject:c];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testException
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSException *e=[NSException exceptionWithName:@"name" reason:@"reason" userInfo:[NSDictionary dictionaryWithObject:@"object" forKey:@"key"]];
	id have;
	id want=@"<0101010c 4e534578 63657074 696f6e00 00010101 094e5353 7472696e 67000101 01000104 6e616d65 01010101 094e5353 7472696e 67000101 01000106 72656173 6f6e0101 01010d4e 53446963 74696f6e 61727900 00010101 0101094e 53537472 696e6700 01010100 01036b65 79010101 01094e53 53747269 6e670001 01010001 066f626a 65637401 0101>";
	[pc encodeObject:e];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInvocation1
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id have;
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000001 02010105 73656c66 00010104 40403a00 014001>";
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeObject:i];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInvocation2
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id have;
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000001 02010105 73656c66 00010104 40403a00 014001>";
	[i retainArguments];	// makes no difference in encoding!
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeObject:i];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testInvocation3
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id have;
	id want=@"<00010201 01057365 6c660001 01044040 3a000140>";
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeInvocation:i];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testReturnInvocation
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	NSString *r=@"return";
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010672 65747572 6e01>";
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[i setReturnValue:&r];
	[pc encodeReturnValue:i];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

- (void) testClassForPortCoder1
{
	id val=@"constant string";
	id have;
	id want=@"NSCFString";
	have=NSStringFromClass([val class]);
	STAssertEqualObjects(have, want,  nil);
	want=@"NSString";
	have=NSStringFromClass([val classForPortCoder]);
	STAssertEqualObjects(have, want,  nil);
}

- (void) testClassForPortCoder2
{
	id val=[NSString stringWithFormat:@"%d", 1234];
	id have;
	id want=@"NSCFString";
	have=NSStringFromClass([val class]);
	STAssertEqualObjects(have, want,  nil);
	want=@"NSString";
	have=NSStringFromClass([val classForPortCoder]);
	STAssertEqualObjects(have, want,  nil);
}

- (void) testClassForPortCoder3
{
	id val=[NSMutableString stringWithFormat:@"%d", 1234];
	id have;
	id want=@"NSCFString";
	have=NSStringFromClass([val class]);
	STAssertEqualObjects(have, want,  nil);
	want=@"NSMutableString";
	have=NSStringFromClass([val classForPortCoder]);
	STAssertEqualObjects(have, want,  nil);
}

- (void) testCompoundPredicate
{ // test object on low level in class hierarchy
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil];
	id obj=[NSCompoundPredicate notPredicateWithSubpredicate:[NSPredicate predicateWithValue:YES]];
	id have;
	id want=@"<00>";	// maybe because we don't have a connection and a NSCompoundPredicate is encoded byref by default 
	NSLog(@"obj=%@", obj);
	[pc encodeObject:obj];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want,  nil);
	[pc release];
}

// could override
// - (void) setUp;
// - (void) tearDown;

@end
