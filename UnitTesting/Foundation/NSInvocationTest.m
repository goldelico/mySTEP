//
//  NSInvocationTest.m
//  UnitTests
//
//  Note: SenTestingKit requires a working implementation of NSInvocation!
//        Therefore it is tricky do work on that class through test driven development.
//        And: on a broken NSInvocation the tests may not even be executed.
//		  The minimum which must be supported is to create NSInvocations
//		  for void methods without parameters.
//
//  Created by H. Nikolaus Schaller on 13.01.14.
//  Copyright 2014 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSInvocationTest.h"


@implementation NSInvocationTest

- (void) test00
{ // check initialization precondition
	STAssertThrowsSpecificNamed([NSInvocation invocationWithMethodSignature:nil], NSException, NSInvalidArgumentException, nil);	// invocation with nil signature
	STAssertNoThrow([[NSInvocation alloc] init], nil);	// init raises no exception
	STAssertNil([[NSInvocation alloc] init], nil);	// and returns no object (and prints no warning)
#if 0	// enable this code to test if the tester comes here
	STAssertTrue(NO, nil);
	sleep(19);
	abort();
#endif
	/* conclusions:
	 * a signature must be specified
	 * -init simply returns nil and does not raise an exception
	 */
}

- (void) invoke01
{ // no arguments, no return value
	invoked=1;
}

- (void) test01
{ // no arguments
	id target=self;
	SEL sel=@selector(invoke01);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 2u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	[i invoke];
	STAssertEquals(invoked, 1, nil);
}

- (id) invoke02:arg1 witharg:(id) arg2;
{ // some object arguments and return value
//	STAssertNotNil(arg1, nil);
//	STAssertNotNil(arg2, nil);
	invoked=2;
	return [[arg1 description] stringByAppendingString:[arg2 description]];
}

- (void) test02
{ // multiple object arguments and return value
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 4u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	[i invoke];
	STAssertEquals(invoked, 2, nil);
}

- (void) test03
{ // missing target or selector
	id target=self;
	SEL sel=@selector(invoke01);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	STAssertNoThrow([i invoke], nil);	// nil target ignores nil selector
	STAssertEquals(invoked, 0, nil);
	[i setTarget:target];
	STAssertThrowsSpecificNamed([i invoke], NSException, NSInvalidArgumentException, nil);	// NULL selector throws
	[i setSelector:sel];
	STAssertEquals(invoked, 0, nil);
	STAssertNoThrow([i invoke], nil);
	STAssertEquals(invoked, 1, nil);	// this one was successful
	/* conclusions
	 * a NULL selector throws an exception
	 * a nil target makes the invoication being ignored
	 */
}

- (void) test10
{ // reading/writing arguments
	id target=self;
	SEL sel=@selector(invoke01);
	id obj=nil;
	SEL sobj=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	STAssertNil(obj, nil);
	NSLog(@"target=%p", target);
	NSLog(@"target=%@", target);
	[i getArgument:&obj atIndex:0];	// read back target
	NSLog(@"obj=%p", obj);
	NSLog(@"obj=%@", obj);
	STAssertEquals(obj, target, nil);
	STAssertTrue(sobj == NULL, nil);
	[i getArgument:&sobj atIndex:1];
	STAssertEquals(sobj, sel, nil);
	STAssertThrowsSpecificNamed([i getArgument:&obj atIndex:2], NSException, NSInvalidArgumentException, nil);	// out of bounds
#if 0
	// this is not documented but reported e.g. thorugh: -[NSInvocation getArgument:atIndex:]: index (2) out of bounds [-1, 1]
	// but it makes the process crash with a TRACE&BPT trap - maybe it is not working correctly for void return values
	[i getArgument:&obj atIndex:-1];
	[i getReturnValue:&obj];
#endif
	/* conclusions
	 * there is some bug with getReturnValue: for a void method
	 */
}

- (void) test11
{ // reading/writing arguments - without invoking
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj=nil;
	SEL sobj=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	STAssertNil(obj, nil);
	[i getArgument:&obj atIndex:0];
	STAssertEquals(obj, target, nil);
	STAssertTrue(sobj == NULL, nil);
	[i getArgument:&sobj atIndex:1];
	STAssertEquals(sobj, sel, nil);
	STAssertNoThrow([i getArgument:&obj atIndex:2], nil);
	STAssertNil(obj, nil);	// arguments appear to be initialized to nil
	STAssertNoThrow([i getArgument:&obj atIndex:3], nil);
	STAssertNil(obj, nil);	// arguments appear to be initialized to nil
	STAssertThrowsSpecificNamed([i getArgument:&obj atIndex:4], NSException, NSInvalidArgumentException, nil);	// out of bounds
	STAssertNoThrow([i getReturnValue:&obj], nil);	// can be called before [i invoke] is called
//	STAssertNil(obj, nil);	// this is not guaranteed: "the result of this method is undefined"
	// this is not documented but reported e.g. though: -[NSInvocation getArgument:atIndex:]: index (2) out of bounds [-1, 1]
	STAssertNoThrow([i getArgument:&obj atIndex:-1], nil);
//	STAssertNil(obj, nil);
	[i setArgument:&self atIndex:2];
	obj=nil;
	STAssertNil(obj, nil);
	STAssertNoThrow([i getArgument:&obj atIndex:2], nil);
	STAssertEqualObjects(obj, self, nil);
	[i setArgument:&i atIndex:2];
	obj=nil;
	STAssertNil(obj, nil);
	STAssertNoThrow([i getArgument:&obj atIndex:2], nil);
	STAssertEqualObjects(obj, i, nil);
	[i setArgument:&self atIndex:-1];	// try to set the return value
	obj=nil;
	STAssertNil(obj, nil);
	STAssertNoThrow([i getReturnValue:&obj], nil);
	STAssertEqualObjects(obj, self, nil);
	STAssertNil(obj, nil);
	STAssertNoThrow([i getArgument:&obj atIndex:-1], nil);
	STAssertEqualObjects(obj, self, nil);
	obj=nil;
	/* conlcusions:
	 * return value is the same as index -1
	 * the return value can be written/read back like any other argument
	 */
}

- (float) invoke12:(double) dbl flt:(float) f
{ // test float arguments and return (have to be passed correctly to FPU)
	invoked=12;
	STAssertEquals(dbl, (double) 3.14159265358979, nil);
	STAssertEquals(f, (float) 2.71828, nil);
	return dbl+f;
}

- (void) test12
{ // reading/writing floats
	id target=self;
	SEL sel=@selector(invoke12:flt:);
	double a=3.14159265358979;
	float b=2.71828;
	float c=-1;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 12, nil);
	[i getReturnValue:&c];
	STAssertEquals(c, (float) 5.859873, nil);
	[i getArgument:&c atIndex:3];
	STAssertEquals(c, (float) 2.71828, nil);
	/* conclusions
	 * there is no type conversion for float/double
	 */
}

- (NSString *) invoke13:(NSString *) a b:(NSString *) b c:(NSString *) c d:(NSString *) d e:(NSString *) e f:(NSString *) f g:(NSString *) g
{ // more than fits into registers
	invoked=13;
	STAssertEqualObjects(a, @"a", nil);
	STAssertEqualObjects(b, @"b", nil);
	STAssertEqualObjects(c, @"c", nil);
	STAssertEqualObjects(d, @"d", nil);
	STAssertEqualObjects(e, @"e", nil);
	STAssertEqualObjects(f, @"f", nil);
	STAssertEqualObjects(g, @"g", nil);
	return @"r";
}

- (void) test13
{ // reading/writing many arguments
	id target=self;
	SEL sel=@selector(invoke13:b:c:d:e:f:g:);
	id obj;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	obj=@"a";
	[i setArgument:&obj atIndex:2];
	obj=@"b";
	[i setArgument:&obj atIndex:3];
	obj=@"c";
	[i setArgument:&obj atIndex:4];
	obj=@"d";
	[i setArgument:&obj atIndex:5];
	obj=@"e";
	[i setArgument:&obj atIndex:6];
	obj=@"f";
	[i setArgument:&obj atIndex:7];
	obj=@"g";
	[i setArgument:&obj atIndex:8];
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 13, nil);
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, @"r", nil);
	[i getArgument:&obj atIndex:2];
	STAssertEqualObjects(obj, @"a", nil);
	[i getArgument:&obj atIndex:3];
	STAssertEqualObjects(obj, @"b", nil);
	[i getArgument:&obj atIndex:4];
	STAssertEqualObjects(obj, @"c", nil);
	[i getArgument:&obj atIndex:5];
	STAssertEqualObjects(obj, @"d", nil);
	[i getArgument:&obj atIndex:6];
	STAssertEqualObjects(obj, @"e", nil);
	[i getArgument:&obj atIndex:7];
	STAssertEqualObjects(obj, @"f", nil);
	[i getArgument:&obj atIndex:8];
	STAssertEqualObjects(obj, @"g", nil);
	/* conclusions
	 * works
	 */
}

- (unichar) invoke14:(char) a b:(short) b c:(unsigned char) c d:(int) d e:(long) e f:(long long) f g:(char *) g
{ // basic C data types
	invoked=14;
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b, (short) 0xbbb, nil);
	STAssertEquals(c, (unsigned char) 0xcc, nil);
	STAssertEquals(d, 12345, nil);
	STAssertEquals(e, 123456789l, nil);
	STAssertEquals(f, 123456789012345678ll, nil);
	STAssertEquals(g, (char *) "g", nil);
	return 0x30AB;
}

- (void) test14
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke14:b:c:d:e:f:g:);
	char a='a';
	short b=0xbbb;
	unsigned char c=0xcc;
	int d=12345;
	long e=123456789;
	long long f=123456789012345678ll;
	char *g="g";
	unichar r=0;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&c atIndex:4];
	[i setArgument:&d atIndex:5];
	[i setArgument:&e atIndex:6];
	[i setArgument:&f atIndex:7];
	[i setArgument:&g atIndex:8];
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 14, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, (unichar) 0x30AB, nil);
	/*
	[i getArgument:&obj atIndex:2];
	STAssertEqualObjects(obj, @"a", nil);
	[i getArgument:&obj atIndex:3];
	STAssertEqualObjects(obj, @"b", nil);
	[i getArgument:&obj atIndex:4];
	STAssertEqualObjects(obj, @"c", nil);
	[i getArgument:&obj atIndex:5];
	STAssertEqualObjects(obj, @"d", nil);
	[i getArgument:&obj atIndex:6];
	STAssertEqualObjects(obj, @"e", nil);
	[i getArgument:&obj atIndex:7];
	STAssertEqualObjects(obj, @"f", nil);
	[i getArgument:&obj atIndex:8];
	STAssertEqualObjects(obj, @"g", nil);
	 */
	/* conclusions
	 * works
	 */
}

struct mydata
{
	int a;
	long b;
};

- (struct mydata) invoke15:(char) a b:(struct mydata) b c:(struct mydata *) c
{ // pass structs by copy and by reference
	invoked=15;
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b.a, 1234, nil);
	STAssertEquals(b.b, 123456789l, nil);
	STAssertEquals(c->a, 4321, nil);
	STAssertEquals(c->b, 987654321l, nil);
	return (struct mydata) { 0xaadd, 0xbbccddee };
}

- (void) test15
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke15:b:c:);
	char a='a';
	struct mydata b={ 1234, 123456789 };
	struct mydata c={ 4321, 987654321 }, *cp=&c;
	struct mydata r={ 1, 2 };
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&cp atIndex:4];	// passs pointer
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 15, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, ((struct mydata) { 0xaadd, 0xbbccddee }), nil);
	/*
	 [i getArgument:&obj atIndex:2];
	 STAssertEqualObjects(obj, @"a", nil);
	 [i getArgument:&obj atIndex:3];
	 STAssertEqualObjects(obj, @"b", nil);
	 [i getArgument:&obj atIndex:4];
	 STAssertEqualObjects(obj, @"c", nil);
	 [i getArgument:&obj atIndex:5];
	 STAssertEqualObjects(obj, @"d", nil);
	 [i getArgument:&obj atIndex:6];
	 STAssertEqualObjects(obj, @"e", nil);
	 [i getArgument:&obj atIndex:7];
	 STAssertEqualObjects(obj, @"f", nil);
	 [i getArgument:&obj atIndex:8];
	 STAssertEqualObjects(obj, @"g", nil);
	 */
	/* conclusions
	 * works
	 */
}

- (struct mydata *) invoke16:(char) a b:(struct mydata) b c:(struct mydata *) c
{ // return struct by reference
	invoked=16;
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b.a, 1234, nil);
	STAssertEquals(b.b, 123456789l, nil);
	STAssertEquals(c->a, 4321, nil);
	STAssertEquals(c->b, 987654321l, nil);
	return c;
}

- (void) test16
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke16:b:c:);
	char a='a';
	struct mydata b={ 1234, 123456789 };
	struct mydata c={ 4321, 987654321 }, *cp=&c;
	struct mydata *r=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&cp atIndex:4];	// passs pointer
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 16, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, cp, nil);
	STAssertEquals(r->a, c.a, nil);
	STAssertEquals(r->b, c.b, nil);
	/*
	 [i getArgument:&obj atIndex:2];
	 STAssertEqualObjects(obj, @"a", nil);
	 [i getArgument:&obj atIndex:3];
	 STAssertEqualObjects(obj, @"b", nil);
	 [i getArgument:&obj atIndex:4];
	 STAssertEqualObjects(obj, @"c", nil);
	 [i getArgument:&obj atIndex:5];
	 STAssertEqualObjects(obj, @"d", nil);
	 [i getArgument:&obj atIndex:6];
	 STAssertEqualObjects(obj, @"e", nil);
	 [i getArgument:&obj atIndex:7];
	 STAssertEqualObjects(obj, @"f", nil);
	 [i getArgument:&obj atIndex:8];
	 STAssertEqualObjects(obj, @"g", nil);
	 */
	/* conclusions
	 * works
	 */
}

- (void) invoke20
{ // raise exception within invoked method
	invoked=20;
	[NSException raise:@"Test Exception" format:@"no format"];
	invoked=-20;
}

- (void) test20
{
	id target=self;
	SEL sel=@selector(invoke20);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 2u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	STAssertThrowsSpecificNamed([i invoke], NSException, @"Test Exception", nil);
	STAssertEquals(invoked, 20, nil);	// should not be -20...
}

- (void) invoke30
{ // nested invocations
	invoked=30;
	
}

- (void) test30
{
	
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{ // test forward:: and forwardInvocation: - even with nesting
	invoked=40;
	
}

- (void) test40
{
	
}

- (void) invoke50
{ // retain/release
	invoked=50;
	
}

- (void) test50
{
	
}

- (id) invoke60:(id) a b:(id) b
{ // retainArguments (also retains returnValue? double call? what happens if we setArgument after that call?)
	invoked=60;
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
	return [[[NSObject alloc] init] autorelease];	// should be placed in the ARP where the -invoke is issued
}

- (void) test60
{
	id target=self;
	SEL sel=@selector(invoke60:b:);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	id a=[[[NSObject alloc] init] autorelease];
	id b=[[[NSObject alloc] init] autorelease];
	NSAutoreleasePool *arp2=[NSAutoreleasePool new];	// create an ARP where the NSInvocation is autoreleased
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	NSAutoreleasePool *arp;
	unsigned int rc;
	id r;
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 4u, nil);
	STAssertNotNil(i, nil);
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
	rc=[target retainCount];
	[i setTarget:target];
	STAssertEquals([target retainCount], rc, nil);	// has not changed
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	arp=[NSAutoreleasePool new];	// create a private ARP so that r is autoreleased there
	[i invoke];
	STAssertEquals(invoked, 60, nil);
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
	[i getReturnValue:&r];
	STAssertEquals([r retainCount], 1u, nil);
	[r retain];
	STAssertEquals([r retainCount], 2u, nil);
	[arp release];	// this should release r
	STAssertEquals([r retainCount], 1u, nil);
	[i retainArguments];
	STAssertEquals([a retainCount], 2u, nil);
	STAssertEquals([b retainCount], 2u, nil);
	STAssertEquals([r retainCount], 2u, nil);
	[i retainArguments];
	STAssertEquals([a retainCount], 2u, nil);
	STAssertEquals([b retainCount], 2u, nil);
	STAssertEquals([r retainCount], 2u, nil);
	[arp2 release];	// this releases the invocation - and the retained arguments
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
	STAssertEquals([r retainCount], 1u, nil);
	[r release];
	/* conclusions
	 * the current APR is used for invocations (i.e. it does not have a private one)
	 * -retainArguments also retains the returnValue
	 * calling -retainArguments twice does not retain twice
	 */
}


@end
