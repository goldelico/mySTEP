//
// NSPortCoderTest.m
// Foundation
//
// Created by H. Nikolaus Schaller on 28.10.09.
// Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/NSMethodSignature.h>
#import "NSPortCoderTest.h"


@interface NSMethodSignature (Since10_5)
+ (NSMethodSignature *)signatureWithObjCTypes:(const char *)types;
@end

@interface NSPortCoder (NSConcretePortCoder)
- (NSArray *) components;
- (void) encodeInvocation:(NSInvocation *) i;
- (void) encodeReturnValue:(NSInvocation *) r;
- (id) decodeRetainedObject;

@end

@interface MyClass : NSObject <NSCoding>
@end

@implementation MyClass

+ (void) initialize; { NSLog(@"+[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); [self setVersion:5]; }
+ (int) version { NSLog(@"+[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return [super version]; }
- (Class) classForCoder { NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return [super classForCoder]; }
- (Class) classForPortCoder { NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return [super classForPortCoder]; }
- (id) replacementObjectForPortCoder:(NSCoder *) class { NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return self; }	// bycopy...
- (void) encodeWithCoder:(NSCoder *) c; { NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); }
- (id) initWithCoder:(NSCoder *) c; { NSLog(@"-[%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd)); return self; }

@end

@interface ByRefByCopyTester : NSObject
@end

@implementation ByRefByCopyTester

- (void) encodeWithCoder:(NSCoder *) c;
{
	NSLog(@"encodeWithCoder: byref=%d bycopy=%d", [(NSPortCoder *) c isByref], [(NSPortCoder *) c isBycopy]);
}

- (Class) classForPortCoder:(NSCoder *) c;
{
	NSLog(@"classForPortCoder: byref=%d bycopy=%d", [(NSPortCoder *) c isByref], [(NSPortCoder *) c isBycopy]);
	return [self class];
}

- (id) replacementObjectForPortCoder:(NSCoder *) c
{
	NSLog(@"replacementObjectForPortCoder: byref=%d bycopy=%d", [(NSPortCoder *) c isByref], [(NSPortCoder *) c isBycopy]);
	return self;
}

@end

/* use mock objects to provide a controllable environment for the NSPortCoder */

@interface MockPort : NSObject
@end

@implementation MockPort

- (id) init
{
	return self;
}

- (void) dealloc
{
	NSLog(@"-[MockPort dealloc]");
	[super dealloc];
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	int val=0x12345678;
	[coder encodeValueOfObjCType:@encode(int) at:&val];
}

- (unsigned) reservedSpaceLength
{
	return 0;
}

- (void) addConnection:(NSConnection *) connection toRunLoop:(NSRunLoop *) rl forMode:(NSString *) mode
{
	NSLog(@"-[MockPort addConnection:%@ toRunLoop:%p forMode:%@]", connection, rl, mode);
	// check in which modes we are added
}

- (void) removeConnection:(NSConnection *) connection fromRunLoop:(NSRunLoop *) rl forMode:(NSString *) mode
{
	NSLog(@"-[MockPort removeConnection:%@ fromRunLoop:%p forMode:%@]", connection, rl, mode);
	// check in which modes we are removed
}

#if 0	// if we want to see how a NSPort is encoded by NSPortCoder

encodeWithCoder:

#endif

@end

@implementation NSPort (override)

+ (id) allocWithZone:(NSZone *)zone
{
	NSLog(@"+[NSPort allocWithZone:]");
	[self release];
	return [MockPort allocWithZone:zone];
}

@end

@interface MockConnection : NSObject
{
	NSPort *_sendPort;
	NSPort *_receivePort;
	int localProxyCount;
}

@end

@implementation MockConnection

static NSHashTable *_allConnections;

+ (NSArray *) allConnections
{
	NSLog(@"+[MockConnection allConnections]");
	return NSAllHashTableObjects(_allConnections);
}

+ (NSConnection *) lookUpConnectionWithReceivePort:(NSPort *) receivePort
										 sendPort:(NSPort *) sendPort;
{ // look up if we already know this connection
	NSLog(@"+[MockConnection lookUpConnectionWithReceivePort:]");
	if(_allConnections)
		{
		NSHashEnumerator e=NSEnumerateHashTable(_allConnections);
		NSConnection *c;
		while((c=(NSConnection *) NSNextHashEnumeratorItem(&e)))
			{
			if([c receivePort] == receivePort && [c sendPort] == sendPort)
				return c;	// found!
			}
		}
	return nil;	// not found
}

- (id) initWithReceivePort:(NSPort *) recv sendPort:(NSPort *) send
{
	id theConnection;
	NSLog(@"-[MockConnection initWithReceivePort:%@ sendPort:%@]", recv, send);
	if((theConnection=[[self class] lookUpConnectionWithReceivePort:recv sendPort:send]))
		{
		[self release];	// this does a dealloc on the temporarily created object
		return [theConnection retain];	// we can have only one NSConnection for each pair of recv/send or NSPortCoder goes off the rails 
		}
	if((self=[super init]))
		{
		_receivePort=[recv retain];
		_sendPort=[send retain];
		if(!_allConnections)
			_allConnections=NSCreateHashTable(NSNonOwnedPointerHashCallBacks, 10);	// allocate - don't retain connections in hash table
		NSHashInsertKnownAbsent(_allConnections, self);	// add us to connections list
		}
	return self;
}

- (void) dealloc
{
	NSLog(@"-[MockConnection dealloc]");
	if(_allConnections)
		NSHashRemove(_allConnections, self);	// remove us from the connections table
	[_receivePort release];
	[_sendPort release];
	[super dealloc];
}

- (NSPort *) receivePort;
{
	return _receivePort;
}

- (NSPort *) sendPort;
{
	return _sendPort;
}

- (void) invalidate;
{
	NSLog(@"-[MockConnection invalidate] %@", self);
	if(_allConnections)
		NSHashRemove(_allConnections, self);	// remove us from the connections table
	return;
}

- (void) handlePortCoder:(NSPortCoder *) coder;
{
	NSLog(@"-[MockConnection handlePortCoder:%@]", coder);
	return;
}

// internal methods - we should not test for them being called or implemented in the same way!

- (void) addClassNamed:(char *) name version:(unsigned int) version
{
	NSLog(@"-[MockConnection addClassNamed:%s version:%d]", name, version);
}

- (unsigned int) versionForClassNamed:(NSString *) name
{
	NSLog(@"-[MockConnection versionForClassNamed:%@]", name);
	if([name isEqualToString:@"NSString"])
		return 1;
	return [NSClassFromString(name) version];
}

- (void) _incrementLocalProxyCount
{
	NSLog(@"_incrementLocalProxyCount called");
	localProxyCount++;
}

- (void) _decrementLocalProxyCount
{
	NSLog(@"_decrementLocalProxyCount called");
	localProxyCount--;
}

- (int) localProxyCount
{
	return localProxyCount;
}

@end

@implementation NSConnection (override)

// FIXME: we have a problem with these mock objects defined as categories for
// existing Foundation classes
// the problem is that one category is applied to the full FoundationTests suite!
// i.e. this override applies to all tests

// do we need to override other class methods because they are called by [NSConnection ...] from within NSPortCoder?

+ (NSArray *) allConnections
{
	NSLog(@"+[NSConnection allConnections]");
	return [MockConnection allConnections];
}

+ (NSConnection *) lookUpConnectionWithReceivePort:(NSPort *) receivePort
										 sendPort:(NSPort *) sendPort;
{ // look up if we already know this connection
	NSLog(@"+[NSConnection lookUpConnectionWithReceivePort:]");
	return [MockConnection lookUpConnectionWithReceivePort:receivePort sendPort:sendPort];
}

+ (id) allocWithZone:(NSZone *)zone
{
	NSLog(@"+[NSConnection allocWithZone:]");
	[self release];
	return [MockConnection allocWithZone:zone];
}

@end

@implementation NSPortCoderTest

- (void) setUp;
{
	NSPort *port=[NSPort port];
	unsigned int cnt=[[NSConnection allConnections] count];
	connection=[NSConnection connectionWithReceivePort:port sendPort:port];
	STAssertNotNil(connection, nil);
	STAssertEquals([[NSConnection allConnections] count], cnt+1, nil);	// is added here to the connection list
//	NSLog(@"connection object: %@", connection);
	// check if ports are added to runloop
}

- (void) tearDown;
{
	unsigned int cnt=[[NSConnection allConnections] count];
	[connection	invalidate];
	STAssertEquals([[NSConnection allConnections] count], cnt-1, nil);	// is removed here from the connection list
	// check if ports are already removed from runloop here
}

- (NSPortCoder *) portCoderForEncode
{
	NSPortCoder *pc;
	pc=[[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil] autorelease];
	STAssertEqualObjects([pc connection], connection, nil);
	STAssertNotNil([pc components], nil);
	STAssertTrue([[pc components] isKindOfClass:[NSArray class]], nil);
	STAssertEquals([[pc components] count], 1u, nil);
#if 0
	NSLog(@"components=%@", [pc components]);
	NSLog(@"components[0]=%@", [[pc components] objectAtIndex:0]);
	NSLog(@"components[0]=%@", NSStringFromClass([[[pc components] objectAtIndex:0] class]));
#endif
#ifdef __mySTEP__
	STAssertTrue([[[pc components] objectAtIndex:0] isKindOfClass:[NSData class]], nil);	// is NSMutableDataMalloc which is NOT a descendant of NSMutableData
#else
	STAssertTrue([[[pc components] objectAtIndex:0] isKindOfClass:[NSMutableData class]], nil);
#endif
	STAssertNotNil([pc connection], nil);
	return pc;
}

- (NSPortCoder *) portCoderForDecode:(NSString *) str
{
	unsigned cnt=[str length];
	NSMutableData *data=[NSMutableData dataWithCapacity:cnt/2];
	NSPortCoder *pc;
	int i;
	int d=0;
	char b=0;
	for(i=0; i<cnt; i++)
		{
			unichar c=[str characterAtIndex:i];
			if(isdigit(c))
				b=(b<<4)+(c-'0');
			else if(c >= 'a' && c <= 'f')
				b=(b<<4)+(c-'a'+10);
			else
				continue;	// ignore
			if(++d == 2)
				[data appendBytes:&b length:1], d=0;
		}
#if 0
	NSLog(@"portCoderForDecode: %@ -> %@", str, data);
#endif
	pc=[[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:[NSArray arrayWithObject:data]] autorelease];
	STAssertNotNil([pc components], nil);
	return pc;
}

- (void) test01Init
{
	NSPortCoder *pc=[self portCoderForEncode];
	STAssertEqualObjects([pc components], [NSArray arrayWithObject:[NSData data]], nil);
	pc=[[[NSPortCoder alloc] initWithReceivePort:[connection receivePort] sendPort:[connection sendPort] components:nil] autorelease];	// provide a default object
}

- (void) test02Dispatch
{
	NSPortCoder *pc=[self portCoderForDecode:@"<0101046e 696c00>"];	// <00> returns 'not enough data to decode integer'
	[pc dispatch];
#if 0
	[(MockConnection *) connection hasCalled:@selector(handlePortCoder:)];
#endif
}

- (void) test03VersionForClassName
{
	NSPortCoder *pc=[self portCoderForEncode];
	// it is unclear if versionForClassName is signed or not (running the test detects a type mismatch)
	STAssertEquals((int)[pc versionForClassName:@"NSString"], 1, nil);	// appears to be forwarded to matching connection object
#if 0
	[(MockConnection *) connection hasCalled:@selector(versionForClassNamed:)];
#endif
	STAssertEquals((int)[pc versionForClassName:@"NSNull"], 0, nil);
}

/* more tests */

- (void) test04PortCoderConnection
{
	NSPortCoder *pc=[[NSPortCoder alloc] initWithReceivePort:[[NSPort new] autorelease] sendPort:[[NSPort new] autorelease] components:nil];
	STAssertEquals([[NSConnection allConnections] count], 1u, nil);	// we already have one from -setUp
	STAssertNotNil([pc connection], nil);	// creates a new connection
	STAssertEquals([[NSConnection allConnections] count], 2u, nil);
	[pc release];
}

- (void) test10Char1
{
	NSPortCoder *pc=[self portCoderForEncode];
	char val=1;
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01>", nil);
}

- (void) test11Char
{
	NSPortCoder *pc=[self portCoderForEncode];
	char val='x';
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<78>", nil);
}

- (void) test12CharM1
{
	NSPortCoder *pc=[self portCoderForEncode];
	char val=-1;
	[pc encodeValueOfObjCType:@encode(char) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<ff>", nil);
}

- (void) test13Int0
{
	NSPortCoder *pc=[self portCoderForEncode];
	int val=0;
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
}

- (void) test14Int1
{
	NSPortCoder *pc=[self portCoderForEncode];
	int val=1;
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101>", nil);
		// can be encoded in 1 byte - i.e. encoder tries to figure out number of significant bytes
}

- (void) test15Int2
{
	NSPortCoder *pc=[self portCoderForEncode];
	int val=10240;
	[pc encodeValueOfObjCType:@encode(int) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<020028>", nil);
		// 2 bytes integer; we also see little-endian encoding (LSB first)
}

- (void) test16Long255
{
	NSPortCoder *pc=[self portCoderForEncode];
	long val=255;
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01ff>", nil);
	// 1 byte positive integer
}

- (void) test17LongM1
{
	NSPortCoder *pc=[self portCoderForEncode];
	long val=-1;
	[pc encodeValueOfObjCType:@encode(long) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<ffff>", nil);
	// -1 byte negative integer; we also see little-endian encoding (LSB first)
	// the length field is negative
}

- (void) test18ULongM1
{
	NSPortCoder *pc=[self portCoderForEncode];
	unsigned long val=-1;
	[pc encodeValueOfObjCType:@encode(unsigned long) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<ffff>", nil);
	// we also see little-endian encoding (LSB first) - coding depends on bit pattern only; not on signed/unsigned
}

- (void) test19LongLong
{
	NSPortCoder *pc=[self portCoderForEncode];
	long long val=12345678987654321LL;
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<07b1f491 6254dc2b>", nil);
	// 7 significant bytes
}

- (void) test20LongLongM1
{
	NSPortCoder *pc=[self portCoderForEncode];
	long long val=-1L;
	[pc encodeValueOfObjCType:@encode(long long) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<ffff>", nil);
	// - insignificant bytes are not encoded
	// - type and memory length is not encoded
}

- (void) test21Float
{
	NSPortCoder *pc=[self portCoderForEncode];
	float val=M_PI;
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<04db0f49 40>", nil);
	// 04 bytes + data -- byte order is the same on PowerPC and Intel Mac
}

- (void) test22Float1
{
	NSPortCoder *pc=[self portCoderForEncode];
	float val=1.0;
	[pc encodeValueOfObjCType:@encode(float) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<04000080 3f>", nil);
	// 04 bytes + data, i.e. here is no compression - we also see Little-Endian encoding
}

- (void) test23Double
{
	NSPortCoder *pc=[self portCoderForEncode];
	double val=M_PI;
	[pc encodeValueOfObjCType:@encode(double) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<08182d44 54fb2109 40>", nil);
	// 08 bytes + data
}

- (void) test24Class
{
	NSPortCoder *pc=[self portCoderForEncode];
	Class val=[NSData class];
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101074e 53446174 6100>", nil);
	// prefix 0x01, 01 bytes length, 07 bytes string, "NSData\0"
}

- (void) test25ClassNil
{
	NSPortCoder *pc=[self portCoderForEncode];
	Class val=Nil;
	id have;
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101046e 696c00>", nil);
	pc=[self portCoderForDecode:@"<0101046e 696c00>"];	// <00> returns 'not enough data to decode integer'
	[pc decodeValueOfObjCType:@encode(Class) at:&have];
	STAssertEqualObjects(have, Nil, nil);
}

- (void) test26ClassNSObject
{
	NSPortCoder *pc=[self portCoderForEncode];
	Class val=[NSObject class];
	id have;
	[pc encodeValueOfObjCType:@encode(Class) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101094e 534f626a 65637400>", nil);
	// prefix 0x01, 01 bytes length, 09 bytes string, "NSObject\0"
	pc=[self portCoderForDecode:@"<0101094e 534f626a 65637400>"];
	[pc decodeValueOfObjCType:@encode(Class) at:&have];
	STAssertEqualObjects(have, [NSObject class], nil);
}

- (void) test27Selector
{
	NSPortCoder *pc=[self portCoderForEncode];
	SEL val=@selector(testSelector);
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010d74 65737453 656c6563 746f7200>", nil);
	// prefix 0x01, 01 bytes length, 0d bytes string, "testSelector\0"
}

- (void) test28SelectorUnicode
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSString *u=[NSString stringWithFormat:@"%C", 0x20AC];	// EURO SIGN; UTF8: E2 82 AC
	SEL val=NSSelectorFromString(u);
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<010104e2 82ac00>", nil);
	// prefix 0x01, 01 bytes length, 04 bytes string, UTF-8 encoded (€ -> 0xe2 0y82 0xac)
}

- (void) test29SelectorNULL
{
	NSPortCoder *pc=[self portCoderForEncode];
	SEL val=NULL;	// NULL selector?
	[pc encodeValueOfObjCType:@encode(SEL) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
}

- (void) test30CString
{
	NSPortCoder *pc=[self portCoderForEncode];
	char *val="C-String";
	id have;
	id want=@"<01010943 2d537472 696e6700>";	// prefix 0x01, 01 bytes length, 09 bytes string, "C-String\0"
	[pc encodeValueOfObjCType:@encode(char *) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
	pc=[self portCoderForDecode:want];
	[pc decodeValueOfObjCType:@encode(char *) at:&val];
	STAssertTrue(strcmp(val, "C-String") == 0, nil);
}

- (void) test31CNULL
{
	NSPortCoder *pc=[self portCoderForEncode];
	char *val=NULL;
	id want=@"<00>";	// prefix 0x00
	[pc encodeValueOfObjCType:@encode(char *) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
	pc=[self portCoderForDecode:want];
	[pc decodeValueOfObjCType:@encode(char *) at:&val];
	STAssertTrue(val == NULL, nil);
}

- (void) test32IntArray
{
	NSPortCoder *pc=[self portCoderForEncode];
	int val[]={ 1, 2, 3, 256, 0 };
	id want=@"<01010102 01030200 0100>";	// 5 times length, byte(s)
	[pc encodeValueOfObjCType:@encode(int [5]) at:&val];	// crashes of we specify @encode(int [])
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
	val[0]=val[1]=val[2]=val[3]=val[4]=7;
	pc=[self portCoderForDecode:want];
	[pc decodeValueOfObjCType:@encode(int [5]) at:&val];
	STAssertTrue((val[0] == 1 && val[1] == 2 && val[2] == 3 && val[3] == 256 && val[4] == 0), nil);
}

- (void) test33IntPointer
{
	NSPortCoder *pc=[self portCoderForEncode];
	int a[]={ 3, 5, 9, 11 };
	int *val=a;
	id want=@"<010103>";	// looks as if this just encodes the first entry, i.e. *val
	[pc encodeValueOfObjCType:@encode(int *) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test34NULLIntPointer
{
	NSPortCoder *pc=[self portCoderForEncode];
	int *val=NULL;
	id have;
	id want=@"<00>";	// NULL pointer
	[pc encodeValueOfObjCType:@encode(int *) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

#if 0	// prints an "unencodable type (v)" error (exception?)

- (void) test35Void
{
	NSPortCoder *pc=[self portCoderForEncode];
	void *val="void";
	id have;
	id want=@"<?>";
	[pc encodeValueOfObjCType:@encode(void) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test36VoidPointer
{
	NSPortCoder *pc=[self portCoderForEncode];
	void *val="C-String";
	id want=@"<?>";
	[pc encodeValueOfObjCType:@encode(void *) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
//	STAssertThrows([pc encodeValueOfObjCType:@encode(void *) at:&val], nil);
}

#endif

- (void) test37Point
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSPoint val=NSMakePoint(1.0, 2.0);
	NSPoint phave;
	id have;
	id want=@"<04000080 3f040000 0040>";	// 04 bytes length each component of the struct
	[pc encodePoint:val];
	have=[[[pc components] objectAtIndex:0] description];	// returns NSData
	STAssertEqualObjects(have, want, nil);
	pc=[self portCoderForDecode:want];
	phave=[pc decodePoint];
	STAssertTrue(NSEqualPoints(phave, val), nil);
}

- (void) test38Struct
{
	NSPortCoder *pc=[self portCoderForEncode];
	struct testStruct { char x; char *y; } val={ 'x', "y" };
	[pc encodeValueOfObjCType:@encode(struct testStruct) at:&val];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<78010102 7900>", nil);
	// 78 is first component; 01 is ???; 01 is length of len; 02 is length; 7900 is string value
}

- (void) test39Nil
{
	NSPortCoder *pc=[self portCoderForEncode];
	id want=@"<00>";
	[pc encodeObject:nil];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test40ConstString
{
	NSPortCoder *pc=[self portCoderForEncode];
	id want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";	// Class(NSString) + contents
	[pc encodeObject:@"String"];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test41EncodeConstString
{
	NSPortCoder *pc=[self portCoderForEncode];
	id want=@"<01065374 72696e67>";
	[@"String" encodeWithCoder:pc];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test42UTF8String
{
	NSPortCoder *pc=[self portCoderForEncode];
	id want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";	// Class(NSString) + contents -- all immutable strings are encoded in the same format
	[pc encodeObject:[NSString stringWithUTF8String:"String"]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test43CString
{
	NSPortCoder *pc=[self portCoderForEncode];
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010653 7472696e 6701>";	// Class(NSString) + contents
	[pc encodeObject:[NSString stringWithCString:"String"]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
	pc=[self portCoderForDecode:want];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);	// this tests portCoderForDecode:
	// have=[pc decodeObject];
	[pc decodeValueOfObjCType:@encode(id) at:&have];
	STAssertEqualObjects(have, @"String", nil);	// error: NSString cannot decode class version 0
}

- (void) test44EncodeString
{
	NSPortCoder *pc=[self portCoderForEncode];
	id want=@"<01065374 72696e67>";	// contents
	[[@"xString" substringFromIndex:1] encodeWithCoder:pc];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
	pc=[self portCoderForDecode:want];
#if 0
	// we would have to provide the correct version number to the string class...
	have=[[[NSString alloc] initWithCoder:pc] autorelease];
	STAssertEqualObjects(have, @"String", nil);	// error: NSString cannot decode class version 0
#endif
}

- (void) test45MutableString
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSMutableString stringWithString:@"String"]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010001 06537472 696e6701>", nil);	// Class(NSMutableString) + Class(NSString) + contents
}

- (void) test45MutableStringDecode
{
	id want=@"<01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010001 06537472 696e6701>";	// Class(NSMutableString) + Class(NSString) + contents
	id have;
	NSPortCoder *pc=[self portCoderForDecode:want];
	[pc decodeValueOfObjCType:@encode(id) at:&have];
	STAssertEqualObjects(have, @"String", nil);	// error: NSString cannot decode class version 0
}

- (void) test46MutableString2
{ // encode twice to find out if the coder remembers classes or content that already have been encoded
	NSPortCoder *pc=[self portCoderForEncode];
	NSString *code=@"01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010001 06537472 696e6701";
	id want=[NSString stringWithFormat:@"<%@ %@>", code, code];	// exactly 2 repetitions of Class(NSMutableString) + Class(NSString) + contents - so there is no optimization or encoding cache
	[pc encodeObject:[NSMutableString stringWithString:@"String"]];
	[pc encodeObject:[NSMutableString stringWithString:@"String"]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test47EncodeMutableString
{
	NSPortCoder *pc=[self portCoderForEncode];
	[[NSMutableString stringWithString:@"String"] encodeWithCoder:pc];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01065374 72696e67>", nil);
}

- (void) test48LongString
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[@"" stringByPaddingToLength:257 withString:@"0123456789abcdef" startingAtIndex:0]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], 
						 @"<01010110 4e534d75 7461626c 65537472 696e6700 01010101 0101094e 53537472 696e6700 01010002 01013031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663031 32333435 36373839 61626364 65663001>",
						 nil);
}

- (void) test49StringUTF8
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSString stringWithFormat:@"%C", 0x20AC]];	// EURO SIGN; UTF8: E2 82 AC
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010109 4e535374 72696e67 00010101 000103e2 82ac01>", nil);	// 0x01 prefix + Class(NSString) + some internals + UTF-8 string + 0x01 suffix
}

- (void) test50EncodeStringUTF8
{
	NSPortCoder *pc=[self portCoderForEncode];
	[[NSString stringWithFormat:@"%C", 0x20AC] encodeWithCoder:pc];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0103e282 ac>", nil);
}

- (void) test51DecodeClassNil
{ // find out what <00> returns when decoded as Class => returns Nil
	NSPortCoder *pc=[self portCoderForDecode:@"<00>"];	// <00> returns 'not enough data to decode integer'
	id have;
	[pc decodeValueOfObjCType:@encode(Class) at:&have];
	STAssertEqualObjects(have, Nil, nil);
}

- (void) test52Data
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSData dataWithBytes:"12345" length:5]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010107 4e534461 74610000 00010531 32333435 01>", nil);
	// 0x01 prefix + Class(NSData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
}

- (void) test53MutableData
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSMutableData dataWithBytes:"12345" length:5]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101010e 4e534d75 7461626c 65446174 61000000 01053132 33343501>", nil);
	// 0x01 prefix + Class(NSMutableData) + some internals + 01 bytes for length + length 05 + 5 bytes data + 0x01 suffix
}

- (void) test54EncodeData
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeDataObject:[NSData dataWithBytes:"12345" length:5]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00010531 32333435>", nil);
	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
}

- (void) test55EncodeMutableData
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeDataObject:[NSMutableData dataWithBytes:"12345" length:5]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00010531 32333435>", nil);
	// 0x00 internal + 01 bytes for length + length 05 + 5 bytes data
}

- (void) test56Date
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSDate dateWithTimeIntervalSince1970:12345678]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010107 4e534461 74650000 08000000 99b3c9cc c101>", nil);
	// 0x01 prefix + Class(NSDate) + 0x00 + 8 bytes double + 0x01 suffix
}

- (void) test57CalendarDate
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSCalendarDate dateWithTimeIntervalSince1970:12345678]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], 
						 @"<0101010f 4e534361 6c656e64 61724461 74650000 08000000 99b3c9cc c1010101 0b4e5354 696d655a 6f6e6500 00010101 094e5353 7472696e 67000101 0100010d 4575726f 70652f42 65726c69 6e010101 0101094e 53537472 696e6700 01010100 01142559 2d256d2d 25642025 483a254d 3a255320 257a0101>",
						 nil);
}

- (void) test58TimeZone
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101010b 4e535469 6d655a6f 6e650000 01010109 4e535374 72696e67 00010101 00010347 4d540101>", nil);
}

- (void) test59EncodeTimeZone
{
	NSPortCoder *pc=[self portCoderForEncode];
	[[NSTimeZone timeZoneForSecondsFromGMT:0] encodeWithCoder:pc];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010109 4e535374 72696e67 00010101 00010347 4d5401>", nil);
}

- (void) test61Null
{ // test object on low level in class hierarchy
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSNull null]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description],
						 @"<01010107 4e534e75 6c6c0000 01>",
						 nil);	// is encoded bycopy as default (!)
}

- (void) test62Array
{ // test object on low level in class hierarchy
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSMutableArray arrayWithObjects:@"1", @"2", [NSNull null], nil]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description],
						 @"<0101010f 4e534d75 7461626c 65417272 61790000 01030101 01094e53 53747269 6e670001 01010001 01310101 0101094e 53537472 696e6700 01010100 01013201 01010107 4e534e75 6c6c0000 0101>",
						 nil);
	// the array (but not its contents) is encoded bycopy as default (!)
}

#if 0	// we can't really pass this test since this would include to have the same sequence of storing keys!
- (void) test63Dict
{ // test object on low level in class hierarchy
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:@"value", @"key1", [NSNull null], @"key2", nil]];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description],
						 @"<01010114 4e534d75 7461626c 65446963 74696f6e 61727900 00010201 0101094e 53537472 696e6700 01010100 01046b65 79320101 0101074e 534e756c 6c000001 01010109 4e535374 72696e67 00010101 0001046b 65793101 01010109 4e535374 72696e67 00010101 00010576 616c7565 0101>",
						 nil);
	// the dictionary (but not its contents) is encoded bycopy as default (!)
}
#endif

- (void) test70ClassForPortCoder1
{
	id val=@"constant string";
#ifdef __APPLE__
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSCFString", nil);	// CoreFoundation...
#else
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSString", nil);
#endif
	STAssertEqualObjects(NSStringFromClass([val classForPortCoder]), @"NSString", nil);	// is always NSString
}

- (void) test70ClassForPortCoder2
{
	id val=[NSString stringWithFormat:@"%d", 1234];
#ifdef __APPLE__
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSCFString", nil);	// CoreFoundation...
#else
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSString", nil);
#endif
	STAssertEqualObjects(NSStringFromClass([val classForPortCoder]), @"NSString", nil);	// is always NSString
}

- (void) test70ClassForPortCoder3
{
	id val=[NSMutableString stringWithFormat:@"%d", 1234];
#ifdef __APPLE__
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSCFString", nil);	// CoreFoundation...
#else
	STAssertEqualObjects(NSStringFromClass([val class]), @"NSMutableString", nil);
#endif
	STAssertEqualObjects(NSStringFromClass([val classForPortCoder]), @"NSMutableString", nil);	// is always NSMutableString
}

- (void) test80Exception
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSException *e=[NSException exceptionWithName:@"name" reason:@"reason" userInfo:[NSDictionary dictionaryWithObject:@"object" forKey:@"key"]];
	[pc encodeObject:e];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101010c 4e534578 63657074 696f6e00 00010101 094e5353 7472696e 67000101 01000104 6e616d65 01010101 094e5353 7472696e 67000101 01000106 72656173 6f6e0101 01010d4e 53446963 74696f6e 61727900 00010101 0101094e 53537472 696e6700 01010100 01036b65 79010101 01094e53 53747269 6e670001 01010001 066f626a 65637401 0101>", nil);
}

- (void) test81Invocation0
{ // ask remote side for rootProxy
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000001 0201010b 726f6f74 4f626a65 63740001 01044040 3a000140 01>";
	[i setTarget:[NSDistantObject proxyWithTarget:0 connection:connection]];
	[i setSelector:@selector(rootObject)];
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation1
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000001 02010105 73656c66 00010104 40403a00 014001>";
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation2
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000001 02010105 73656c66 00010104 40403a00 014001>";
	[i retainArguments];	// makes no difference in encoding!
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation3
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id want=@"<00010201 01057365 6c660001 01044040 3a000140>";	// the pure invocation
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[pc encodeInvocation:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation4
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	id want=@"<01010109 4e535374 72696e67 00010101 00010673 7472696e 67010102 01010573 656c6600 01010440 403a0001 40>";	// the pure invocation
	[i setTarget:@"string"];
	[i setSelector:@selector(self)];
	[pc encodeInvocation:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation5
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:@"]];
	id want=@"<01010109 4e535374 72696e67 00010101 00010673 7472696e 67010103 01010673 656c663a 00010105 40403a40 00014000>";	// the pure invocation
	[i setTarget:@"string"];
	[i setSelector:@selector(self:)];
	[pc encodeInvocation:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation6
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:@"]];
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000101 01094e53 53747269 6e670001 01010001 06737472 696e6701 01030101 0673656c 663a0001 01054040 3a400001 400001>";
	[i setTarget:@"string"];
	[i setSelector:@selector(self:)];
	// argument is nil
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation7
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:@"]];
	id have;
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000101 01094e53 53747269 6e670001 01010001 06737472 696e6701 01030101 11746573 74496e76 6f636174 696f6e37 3a000101 0540403a 40000140 01010109 4e535374 72696e67 00010101 00010461 72673201 01>";
	[i setTarget:@"string"];
	[i setSelector:@selector(testInvocation7:)];
	have=@"arg2";	// encode [@"string" testInvocation7:@"args"]
	[i setArgument:&have atIndex:2];
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation8	// selector name is encoded
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@::"]];
	id want=@"<0101010d 4e53496e 766f6361 74696f6e 00000101 01094e53 53747269 6e670001 01010001 06737472 696e6701 01030101 11746573 74496e76 6f636174 696f6e38 3a000101 0540403a 3a000140 01011274 65737438 31496e76 6f636174 696f6e38 0001>";
	[i setTarget:@"string"];
	[i setSelector:@selector(testInvocation8:)];
	[i setArgument:&_cmd atIndex:2];
	[pc encodeObject:i];	// encode [@"string" testInvocation8:@selector(testInvocation8)]
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test81Invocation9
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"c@::"]];
	SEL sel=@selector(descriptionWithLocale:);
	[i setTarget:[NSDistantObject proxyWithLocal:self connection:[pc connection]]];
	[i setSelector:@selector(respondsToSelector:)];
	[i setArgument:&sel atIndex:2];
	[pc encodeObject:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<0101010d 4e53496e 766f6361 74696f6e 00000101 01104e53 44697374 616e744f 626a6563 74000001 01000101 03010114 72657370 6f6e6473 546f5365 6c656374 6f723a00 01010563 403a3a00 01630101 17646573 63726970 74696f6e 57697468 4c6f6361 6c653a00 01>", nil);
}

#if 0
- (void) test81Invocation10
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSString *r=@"<01 01010d4e 53496e76 6f636174 696f6e00 00010101 104e5344 69737461 6e744f62 6a656374 00000001 01010103 01011e6d 6574686f 64446573 63726970 74696f6e 466f7253 656c6563 746f723a 00010126 5e7b6f62 6a635f6d 6574686f 645f6465 73637269 7074696f 6e3d3a2a 7d313240 303a343a 3800255e 7b6f626a 635f6d65 74686f64 5f646573 63726970 74696f6e 3d3a2a7d 31324030 3a343a38 01010b72 6f6f744f 626a6563 74000100 00>>";
	id want=@"?";
	pc=[self portCoderForDecode:r];
	// raises an exception: more significant bytes (37) than room to hold them (4)
	have=[pc decodeRetainedObject];	// should be NSInvocation
	NSLog(@"textInvocation10: %@", [[[pc components] objectAtIndex:0] description]);
//	STAssertEqualObjects(have, want, nil);
}
#endif

- (void) test82ReturnInvocation
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	NSString *r=@"return";
	id have;
	id want=@"<01010109 4e535374 72696e67 00010101 00010672 65747572 6e01>";
	[i setTarget:nil];
	[i setSelector:@selector(self)];
	[i setReturnValue:&r];
	[pc encodeReturnValue:i];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
#if FIXME	// we can't decode -> "NSString can't decode class version 0"
	pc=[self portCoderForDecode:have];
	[pc decodeReturnValue:i];
	[i getReturnValue:&have];
	NSLog(@"r=%@", have);
#endif
}

- (void) test83DecodeReturnInvocation
{
	NSPortCoder *pc=[self portCoderForDecode:@"<01010109 4e535374 72696e67 00010101 00010672 65747572 6e01>"];
	id have=nil;
	id want=nil;
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:[NSMethodSignature signatureWithObjCTypes:"@@:"]];
	[i setTarget:nil];
	[i setSelector:@selector(self)];
#if FIXME	// we can't decode -> "NSString can't decode class version 0"
	[pc decodeReturnValue:i];
	[i getReturnValue:&have];
	STAssertEqualObjects(have, want, nil);
#endif
}

// since byref objects get a unique serial number - even if portcoders and connections are released,
// the order of executing these tests is important

- (void) test90CompoundPredicate
{ // test object on low level in class hierarchy - that is encoded byref
	NSPortCoder *pc=[self portCoderForEncode];
	id obj=[NSCompoundPredicate notPredicateWithSubpredicate:[NSPredicate predicateWithValue:YES]];
	id want=@"<01010110 4e534469 7374616e 744f626a 65637400 00010400 01>";	// NSCompoundPredicate is encoded byref by default 
	[pc encodeObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test90ByrefObject
{
	NSPortCoder *pc=[self portCoderForEncode];
	id obj=@"string", obj2;
	[pc encodeByrefObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010200 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001
	// try again
	pc=[self portCoderForEncode];
	[pc encodeByrefObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010200 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001 -- same id again, even for a new port coder!
	// try another string
	pc=[self portCoderForEncode];
	obj2=@"STRING";
	[pc encodeByrefObject:obj2];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010300 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0102* 0001 -- next object id
	// try again
	pc=[self portCoderForEncode];
	[pc encodeByrefObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010200 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001 -- same id again, even for a new port coder!
	/* conclusions
	 * byref (local) objects are numbered
	 * encoding the same object again "remembers" the number
	 * the list of known local objects for a NSConnection is stored somewhere
	 * differently from NSConnection objects because we don't need methods of
	 * the MockConnection to make that work
	 *
	 * the question is if it is tied to a connection at all or if all connections share a common object counter
	 * to find out we must be able to instantiate two connections and encode alternatingly
	 *
	 */
}

- (void) test91ByrefObjectOnMultipleConnections
{
	NSPortCoder *pc1=[self portCoderForEncode];
	NSPortCoder *pc2=[[[NSPortCoder alloc] initWithReceivePort:[[NSPort new] autorelease] sendPort:[[NSPort new] autorelease] components:nil] autorelease];
	STAssertFalse(pc1 == pc2, nil);
	STAssertFalse([pc1 connection] == [pc2 connection], nil);	// are indeed different connections
	id obj=@"samestring";
	[pc1 encodeByrefObject:obj];
	STAssertEqualObjects([[[pc1 components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010500 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001
	// now on other connection
	[pc2 encodeByrefObject:obj];
	STAssertEqualObjects([[[pc2 components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010600 01>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001 -- same id again, even for a new port coder!
	// and again on first connection
	[pc1 encodeByrefObject:obj];
	STAssertEqualObjects([[[pc1 components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010500 01010101 104e5344 69737461 6e744f62 6a656374 00000105 0001>", nil);	// 0x01 lenlen len "NSDistantObject\0" 00 *0101* 0001
	/* conclusions
	 * objects encoded for different connections get a different sequence number (!)
	 * so there *is* some storage that stores an association tuple (object, connection, number)
	 * but the sequence number space is shared between all connections
	 * most likely this is implemented in NSDistantObject and not NSPortCoder
	 * and we don't see that NSConnection methods are called, i.e. it is not the NSConnection that stores (object, number)
	 */
}
- (void) test92BycopyObject
{
	NSPortCoder *pc=[self portCoderForEncode];
	id obj=@"string";
	id want=@"<01010109 4e535374 72696e67 00010101 00010673 7472696e 6701>";
	[pc encodeBycopyObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], want, nil);
}

- (void) test93ByRefAndByCopy
{ // find out how byref/bycopy is passed to [pc isByref] [isByCopy]
	ByRefByCopyTester *obj=[ByRefByCopyTester new];
	NSPortCoder *pc=[self portCoderForEncode];
	STAssertFalse([pc isByref], nil);
	STAssertFalse([pc isBycopy], nil);
	[pc encodeObject:obj];
	// STAssertTrue([obj didSeeByref:0 byCopy:0], nil);
	STAssertFalse([pc isByref], nil);
	STAssertFalse([pc isBycopy], nil);
	[pc encodeByrefObject:obj];
	// STAssertTrue([obj didSeeByref:1 byCopy:0], nil);
	STAssertFalse([pc isByref], nil);	// is only set while we are within encodeByrefObject
	STAssertFalse([pc isBycopy], nil);
	[pc encodeBycopyObject:obj];
	// STAssertTrue([obj didSeeByref:0 byCopy:1], nil);
	STAssertFalse([pc isByref], nil);
	STAssertFalse([pc isBycopy], nil);	// is only set while we are within encodeBycopyObject
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010112 42795265 66427943 6f707954 65737465 72000001 01010112 42795265 66427943 6f707954 65737465 72000001 01010112 42795265 66427943 6f707954 65737465 72000001>", nil);
	/* conclusions
	 * byref and bycopy are only valid while an encodeBy*: method is running
	 */
}

- (void) test94DistantObjectLocalProxy
{
	NSPortCoder *pc=[self portCoderForEncode];
	id obj;
	obj=[NSDistantObject proxyWithLocal:[[NSObject new] autorelease] connection:connection];
	[pc encodeBycopyObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010700 01>", nil);	// stores the object and assignes a fresh object-id (4 in this case)
}

// FIXME: we don't get an initialized NSDistantObject on cocoa

- (void) test95DistantObjectRemoteProxy
{
	NSPortCoder *pc=[self portCoderForEncode];
	id obj=[NSDistantObject proxyWithTarget:(id) 44 connection:connection];	// this fails on Cocoa
	[pc encodeBycopyObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
}

- (void) test95DistantObjectRemoteProxy0
{
	NSPortCoder *pc=[self portCoderForEncode];
	id obj=[NSDistantObject proxyWithTarget:(id) 0 connection:connection];
	[pc encodeBycopyObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<00>", nil);
}

- (void) test96MyClass
{
	NSPortCoder *pc=[self portCoderForEncode];
	MyClass *obj=[[[MyClass alloc] init] autorelease];
	STAssertEquals((int)[[obj class] version], 5, nil);
	[pc encodeObject:obj];
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010108 4d79436c 61737300 01010500 01>", nil);
	// 0x01 prefix + Class(MyObject) + 1 byte 00 (uninitialized?) + 0x01 suffix
}

- (void) test97EncodePort
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSPort *port=[NSPort port];
	[pc encodePortObject:port];
	STAssertEquals([[pc components] count], 2u, nil);
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<>", nil);	// remains empty
	STAssertEqualObjects([[pc components] objectAtIndex:1], port, nil);	// encodePortObject adds another component - and does not check for a subclass of NSPort
}

- (void) test98PortObject
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSPort *port=[NSPort port];
	[pc encodeObject:port];
	if(![port respondsToSelector:@selector(encodeWithCoder:)])
		{
		STAssertEquals([[pc components] count], 2u, nil);
		STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010107 4e53506f 72740000 01>", nil);
		STAssertEqualObjects([[pc components] objectAtIndex:1], port, nil);
		// 0x01 prefix + Class(NSPort) + 1 byte 00 (uninitialized?) + 0x01 suffix
		// and port is also added to the components, i.e. the -encodePortObject method is the more primitive
		}
	else
		{
		STAssertEquals([[pc components] count], 1u, nil);
		STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010800 01>", nil);
		// 0x01 prefix + Class(NSPort) + 1 byte 00 + 04 bytes value (signature of our MyPort) + 0x01 suffix
		}
}

- (void) test99_1ThisConnection
{
	NSPortCoder *pc=[self portCoderForEncode];
	[pc encodeObject:connection];		// encoded as NSDistantObject - gets its own unique serial number!
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010900 01>", nil);
}

- (void) test99_2OtherConnection
{
	NSPortCoder *pc=[self portCoderForEncode];
	NSConnection *c=[NSConnection connectionWithReceivePort:[[NSPort new] autorelease] sendPort:[[NSPort new] autorelease]];
	[pc encodeObject:c];	// just another distant object
	STAssertEqualObjects([[[pc components] objectAtIndex:0] description], @"<01010110 4e534469 7374616e 744f626a 65637400 00010a00 01>", nil);
	/* conclusion
	 * there is no special encoding for "this connection"
	 * which indicates that [connection rootProxy] and [connection rootObject] is some special code
	 */
}

@end
