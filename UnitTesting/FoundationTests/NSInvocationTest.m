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

#import <XCTest/XCTest.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, format) \
	XCTAssertEqualObjects( \
		[NSValue value:&a withObjCType:@encode(typeof(a))], \
		[NSValue value:&b withObjCType:@encode(typeof(b))], \
		format);

@interface NSInvocationTest : XCTestCase {
	int invoked;
}

@end

#ifdef __APPLE__	// & SDK before 10.5
#define sel_isEqual(A, B) ((A) == (B))
#endif

@interface NSMethodSignature (Additions)	// exposed in 10.5 and later
+ (NSMethodSignature *) signatureWithObjCTypes:(const char *)types;
@end

struct f_d
{
	float a;
	double b;
};

struct i_ll
{
	int a;
	long long b;
};

struct c_c
{
	char a;
	char b;
};

@interface NSInvocationTest (Forwarding)	// define as header so that the compiler does not complain and we know the signature
- (void) forward40;
- (int) forward41:(int) a b:(int) b;
- (int) forward42:(int) a b:(int) b c:(int) c d:(int) d e:(int) e f:(int) f;
- (id) forward43:(id) a b:(id) b;
- (void) forward44;
- (void) forward45;
- (int) forward46:(int) a b:(int) b;
- (float) forward47:(int) a b:(int) b c:(float) c d:(int) d e:(float) e f:(float) f;
- (double) forward48:(int) a b:(long long) b c:(float) c d:(int) d e:(double) e f:(float) f;
- (void) forward49:(float) a b:(double) b c:(struct f_d) c;
// test char, short, struct, array arguments and return values (alignment!)
@end

@implementation NSInvocationTest

- (void) test00
{ // check initialization precondition
	XCTAssertThrowsSpecificNamed([NSInvocation invocationWithMethodSignature:nil], NSException, NSInvalidArgumentException, @"");	// invocation with nil signature
	XCTAssertNoThrow([[NSInvocation alloc] init], @"");	// init raises no exception
	XCTAssertNil([[NSInvocation alloc] init], @"");	// and returns no object (and prints no warning)
#if 0	// enable this code to test if the tester comes here
	XCTAssertTrue(NO, @"");
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

- (void) test01_basic
{ // no arguments
	id target=self;
	SEL sel=@selector(invoke01);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 2, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	[i invoke];
	XCTAssertEqual(invoked, 1, @"");
}

- (id) invoke02:arg1 witharg:(id) arg2;
{ // some object arguments and return value
	//	XCTAssertNotNil(arg1, @"");
	//	XCTAssertNotNil(arg2, @"");
	invoked=2;
	return [[arg1 description] stringByAppendingString:[arg2 description]];
}

- (void) test02_args_and_ret
{ // multiple object arguments and return value
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 4, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	[i invoke];
	XCTAssertEqual(invoked, 2, @"");
}

- (void) test03_missing_target_or_selector
{ // missing target or selector or NULL arguments
	id target=self;
	SEL sel=@selector(invoke01);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	XCTAssertNoThrow([i invoke], @"");	// nil target ignores nil selector
	XCTAssertEqual(invoked, 0, @"");
	[i setTarget:target];
#ifndef __APPLE__	// segfaults on Apple
	XCTAssertThrowsSpecificNamed([i invoke], NSException, NSInvalidArgumentException, @"");	// NULL/uninitialized selector throws
#endif
	[i setSelector:sel];
	XCTAssertEqual(invoked, 0, @"");
	XCTAssertNoThrow([i invoke], @"");
	XCTAssertEqual(invoked, 1, @"");	// this one was successful
	XCTAssertThrowsSpecificNamed([i setArgument:NULL atIndex:0], NSException, NSInvalidArgumentException, @"");	// NULL address throws
	XCTAssertThrowsSpecificNamed([i getArgument:NULL atIndex:0], NSException, NSInvalidArgumentException, @"");
	/* conclusions
	 * an uninitialized/NULL selector throws an exception (NOTE: segfaults on MacOS 10.11)
	 * an uninitialized/nil target makes the invoication being ignored
	 */
}

- (void) test10_get_set_args
{ // reading/writing arguments
	id target=self;
	SEL sel=@selector(invoke01);
	id obj=nil;
	SEL sobj=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	XCTAssertNil(obj, @"");
	NSLog(@"target=%p", target);
	NSLog(@"target=%@", target);
	[i getArgument:&obj atIndex:0];	// read back target
	NSLog(@"obj=%p", obj);
	NSLog(@"obj=%@", obj);
	XCTAssertEqual(obj, target, @"");
	XCTAssertTrue(sobj == NULL, @"");
	[i getArgument:&sobj atIndex:1];
	XCTAssertEqual(sobj, sel, @"");
	XCTAssertThrowsSpecificNamed([i getArgument:&obj atIndex:2], NSException, NSInvalidArgumentException, @"");	// out of bounds
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

- (void) test11_more_get_set_args
{ // reading/writing arguments - without invoking
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj=nil;
	SEL sobj=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	XCTAssertNil(obj, @"");
	[i getArgument:&obj atIndex:0];
	XCTAssertEqual(obj, target, @"");
	XCTAssertTrue(sobj == NULL, @"");
	[i getArgument:&sobj atIndex:1];
	XCTAssertEqual(sobj, sel, @"");
	XCTAssertNoThrow([i getArgument:&obj atIndex:2], @"");
	XCTAssertNil(obj, @"");	// arguments appear to be initialized to nil
	XCTAssertNoThrow([i getArgument:&obj atIndex:3], @"");
	XCTAssertNil(obj, @"");	// arguments appear to be initialized to nil
	XCTAssertThrowsSpecificNamed([i getArgument:&obj atIndex:4], NSException, NSInvalidArgumentException, @"");	// out of bounds
	XCTAssertNoThrow([i getReturnValue:&obj], @"");	// can be called before [i invoke] is called
	//	XCTAssertNil(obj, @"");	// this is not guaranteed: "the result of this method is undefined"
	// this is not documented but reported e.g. though: -[NSInvocation getArgument:atIndex:]: index (2) out of bounds [-1, 1]
	XCTAssertNoThrow([i getArgument:&obj atIndex:-1], @"");
	//	XCTAssertNil(obj, @"");
	[i setArgument:&self atIndex:2];
	obj=nil;
	XCTAssertNil(obj, @"");
	XCTAssertNoThrow([i getArgument:&obj atIndex:2], @"");
	XCTAssertEqualObjects(obj, self, @"");
	[i setArgument:&i atIndex:2];
	obj=nil;
	XCTAssertNil(obj, @"");
	XCTAssertNoThrow([i getArgument:&obj atIndex:2], @"");
	XCTAssertEqualObjects(obj, i, @"");
	[i setArgument:&self atIndex:-1];	// try to set the return value
	obj=nil;
	XCTAssertNil(obj, @"");
	XCTAssertNoThrow([i getReturnValue:&obj], @"");
	XCTAssertEqualObjects(obj, self, @"");
	obj=nil;
	XCTAssertNil(obj, @"");
	XCTAssertNoThrow([i getArgument:&obj atIndex:-1], @"");
	XCTAssertEqualObjects(obj, self, @"");
	/* conlcusions:
	 * return value is the same as index -1
	 * the return value can be written/read back like any other argument
	 */
}

- (float) invoke12:(double) dbl flt:(float) f
{ // test float arguments and return (have to be passed correctly to FPU)
	invoked=12;
	XCTAssertEqual(dbl, (double) 3.14159265358979, @"");
	XCTAssertEqual(f, (float) 2.71828, @"");
	return dbl+f;
}

- (void) test12_invoke_double_and_float_with_return
{ // reading/writing floats
	id target=self;
	SEL sel=@selector(invoke12:flt:);
	double a=3.14159265358979;
	float b=2.71828;
	float c=-1;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	invoked=0;
	[i invoke];
	XCTAssertEqual(invoked, 12, @"");
	[i getReturnValue:&c];
	XCTAssertEqual(c, (float) 5.859873, @"");
	[i getArgument:&c atIndex:3];
	XCTAssertEqual(c, (float) 2.71828, @"");
	/* conclusions
	 * there is no type conversion for float/double
	 */
}

- (NSString *) invoke13:(NSString *) a b:(NSString *) b c:(NSString *) c d:(NSString *) d e:(NSString *) e f:(NSString *) f g:(NSString *) g
{ // more than fits into registers
	invoked=13;
	XCTAssertTrue(sel_isEqual(_cmd, @selector(invoke13:b:c:d:e:f:g:)), @"");
	XCTAssertEqualObjects(a, @"a", @"");
	XCTAssertEqualObjects(b, @"b", @"");
	XCTAssertEqualObjects(c, @"c", @"");
	XCTAssertEqualObjects(d, @"d", @"");
	XCTAssertEqualObjects(e, @"e", @"");
	XCTAssertEqualObjects(f, @"f", @"");
	XCTAssertEqualObjects(g, @"g", @"");
	return @"r";
}

- (void) test13_invoke_many_objects_with_return
{ // reading/writing many arguments
	id target=self;
	SEL sel=@selector(invoke13:b:c:d:e:f:g:);
	id obj;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
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
	XCTAssertEqual(invoked, 13, @"");
	XCTAssertEqualObjects(obj, @"g", @"");
	[i getReturnValue:&obj];
	XCTAssertEqualObjects(obj, @"r", @"");
	[i getArgument:&obj atIndex:2];	// this checks if the arguments are still intact after doing the invoke+return
	XCTAssertEqualObjects(obj, @"a", @"");
	[i getArgument:&obj atIndex:3];
	XCTAssertEqualObjects(obj, @"b", @"");
	[i getArgument:&obj atIndex:4];
	XCTAssertEqualObjects(obj, @"c", @"");
	[i getArgument:&obj atIndex:5];
	XCTAssertEqualObjects(obj, @"d", @"");
	[i getArgument:&obj atIndex:6];
	XCTAssertEqualObjects(obj, @"e", @"");
	[i getArgument:&obj atIndex:7];
	XCTAssertEqualObjects(obj, @"f", @"");
	[i getArgument:&obj atIndex:8];
	XCTAssertEqualObjects(obj, @"g", @"");
	/* conclusions
	 * works
	 */
}

- (unichar) invoke14:(char) a b:(short) b c:(unsigned char) c d:(int) d e:(long) e f:(long long) f g:(char *) g
{ // basic C data types
	invoked=14;
	XCTAssertEqual(a, (char) 'a', @"");
	XCTAssertEqual(b, (short) 0xbbb, @"");
	XCTAssertEqual(c, (unsigned char) 0xcc, @"");
	XCTAssertEqual(d, 0xdd00, @"");
	XCTAssertEqual(e, 0x1e0000eel, @"");
	NSLog(@"%llx", f);
	XCTAssertEqual(f, 0x1f00ff0000ff00ffll, @"");
	XCTAssertEqual(g, (char *) "g", @"");
	return 0x30AB;
}

- (void) test14_invoke_many_C_and_return
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke14:b:c:d:e:f:g:);
	char a='a';
	short b=0xbbb;
	unsigned char c=0xcc;
	int d=0xdd00;
	long e=0x1e0000eel;
	long long f=0x1f00ff0000ff00ffll;
	char *g="g";
	unichar r=0;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
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
	XCTAssertEqual(invoked, 14, @"");
	[i getReturnValue:&r];
	XCTAssertEqual(r, (unichar) 0x30AB, @"");
	/*
	 [i getArgument:&obj atIndex:2];
	 XCTAssertEqualObjects(obj, @"a", @"");
	 [i getArgument:&obj atIndex:3];
	 XCTAssertEqualObjects(obj, @"b", @"");
	 [i getArgument:&obj atIndex:4];
	 XCTAssertEqualObjects(obj, @"c", @"");
	 [i getArgument:&obj atIndex:5];
	 XCTAssertEqualObjects(obj, @"d", @"");
	 [i getArgument:&obj atIndex:6];
	 XCTAssertEqualObjects(obj, @"e", @"");
	 [i getArgument:&obj atIndex:7];
	 XCTAssertEqualObjects(obj, @"f", @"");
	 [i getArgument:&obj atIndex:8];
	 XCTAssertEqualObjects(obj, @"g", @"");
	 */
	/* conclusions
	 * works
	 */
}

// this is a tricky to implement case
// on some architectures (i386) alignment may differ between stack and structs
// http://www.wambold.com/Martin/writings/alignof.html
// on armhf it *may* be that the compiler knows that the whole struct can be passed in vector registers

- (void) invoke14dfs:(float) a b:(double) b c:(struct f_d) c
{ // pass float and double and struct
	NSLog(@"invoke14dfs called");
	invoked=14;
	NSLog(@"invoked = %d", invoked);
	XCTAssertEqual(a, (float) 1.1, @"");
	XCTAssertEqual(b, 2.2, @"");
	NSLog(@"&a=%p a=%g", &a, a);
	NSLog(@"&b=%p b=%lg", &b, b);
	NSLog(@"&c=%p", &c);
	NSLog(@"&c.a=%p c.a=%g", &c.a, c.a);
	NSLog(@"&c.b=%p c.b=%lg", &c.b, c.b);
	XCTAssertEqual(c.a, (float) 3.3, @"");
	XCTAssertEqual(c.b, 4.4, @"");
	NSLog(@"test14dfs done");
}

- (void) test14_invoke_double_float_and_struct
{ // pass float and double
	id target=self;
	SEL sel=@selector(invoke14dfs:b:c:);
	float a=1.1;
	double b=2.2;
	struct f_d c={
		3.3,
		4.4
	};
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	NSLog(@"test14dfs started");
	NSLog(@"%lu+%lu -- %lu", sizeof(a), sizeof(b), sizeof(c));
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&c atIndex:4];	// pass by copy
	invoked=0;
	[i invoke];
	XCTAssertEqual(invoked, 14, @"");
}

- (long long) invoke14ll:(char) a b:(long long) b
{ // pass long longs
	NSLog(@"invoke14ll called");
	invoked=-14;
	NSLog(@"invoked = %d", invoked);
	XCTAssertEqual(a, (char) 'a', @"");
	XCTAssertEqual(b, 0x1f00ff0000ff00ffll, @"");
	NSLog(@"test14ll done");
	return 0x7fff00ffff00ff00ll;
}

- (void) test14_longlong
{ // pass long longs (in register on armhf)
	id target=self;
	SEL sel=@selector(invoke14ll:b:);
	char a='a';
	long long b=0x1f00ff0000ff00ffll;
	long long r;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	NSLog(@"test14ll started");
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	invoked=0;
	[i invoke];
	XCTAssertEqual(invoked, -14, @"");
	[i getReturnValue:&r];
	XCTAssertEqual(r, 0x7fff00ffff00ff00ll, @"");
	/*
	 [i getArgument:&obj atIndex:2];
	 XCTAssertEqualObjects(obj, @"a", @"");
	 [i getArgument:&obj atIndex:3];
	 XCTAssertEqualObjects(obj, @"b", @"");
	 [i getArgument:&obj atIndex:4];
	 XCTAssertEqualObjects(obj, @"c", @"");
	 [i getArgument:&obj atIndex:5];
	 XCTAssertEqualObjects(obj, @"d", @"");
	 [i getArgument:&obj atIndex:6];
	 XCTAssertEqualObjects(obj, @"e", @"");
	 [i getArgument:&obj atIndex:7];
	 XCTAssertEqualObjects(obj, @"f", @"");
	 [i getArgument:&obj atIndex:8];
	 XCTAssertEqualObjects(obj, @"g", @"");
	 */
	/* conclusions
	 * works
	 */
}

- (struct i_ll) invoke15:(char) a b:(struct i_ll) b c:(struct i_ll *) c
{ // pass structs by copy and by reference
	NSLog(@"invoke15 called");
	invoked=15;
	XCTAssertEqual(a, (char) 'a', @"");
	XCTAssertEqual(b.a, 0x1234, @"");
	XCTAssertEqual(b.b, 0x7fff00ffff00ff00ll, @"");
	XCTAssertEqual(c->a, 0x4321, @"");
	XCTAssertEqual(c->b, 0x1f00ff0000ff00ffll, @"");
	NSLog(@"invoke15 returning");
	return (struct i_ll) { 0xaadd, 0xbbccddee };
}

- (void) test15_int_longlong_struct
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke15:b:c:);
	char a='a';
	struct i_ll b={ 0x1234, 0x7fff00ffff00ff00ll };
	struct i_ll c={ 0x4321, 0x1f00ff0000ff00ffll }, *cp=&c;
	struct i_ll r={ 1, 2 };
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	NSLog(@"invoking invoke15 a");
	[i setArgument:&a atIndex:2];
	NSLog(@"invoking invoke15 b");
	[i setArgument:&b atIndex:3];	// pass as copy on stack
	NSLog(@"invoking invoke15 c");
	[i setArgument:&cp atIndex:4];	// pass as pointer to struct on stack
	invoked=0;
	NSLog(@"invoking invoke15 d");
	[i invoke];
	XCTAssertEqual(invoked, 15, @"");
	[i getReturnValue:&r];
	XCTAssertEquals(r, ((struct i_ll) { 0xaadd, 0xbbccddee }), @"");
	/*
	 [i getArgument:&obj atIndex:2];
	 XCTAssertEqualObjects(obj, @"a", @"");
	 [i getArgument:&obj atIndex:3];
	 XCTAssertEqualObjects(obj, @"b", @"");
	 [i getArgument:&obj atIndex:4];
	 XCTAssertEqualObjects(obj, @"c", @"");
	 [i getArgument:&obj atIndex:5];
	 XCTAssertEqualObjects(obj, @"d", @"");
	 [i getArgument:&obj atIndex:6];
	 XCTAssertEqualObjects(obj, @"e", @"");
	 [i getArgument:&obj atIndex:7];
	 XCTAssertEqualObjects(obj, @"f", @"");
	 [i getArgument:&obj atIndex:8];
	 XCTAssertEqualObjects(obj, @"g", @"");
	 */
	/* conclusions
	 * works
	 */
}

/* 
 * on some architectures a struct can be passed through a register if small enough
 * and the same could hold for the return value
 * so we run this test as well as the implementation may run a different algorithm
 */

- (struct c_c) invoke15s:(char) a b:(struct c_c) b c:(struct c_c *) c
{ // pass small structs by copy and by reference
	NSLog(@"invoke15s called");
	invoked=-15;
	NSLog(@"invoked = %d", invoked);
	XCTAssertEqual(a, (char) 'a', @"");
	XCTAssertEqual(b.a, (char) 'b', @"");
	XCTAssertEqual(b.b, (char) 'B', @"");
	XCTAssertEqual(c->a, (char) 'c', @"");
	XCTAssertEqual(c->b, (char) 'C', @"");
	NSLog(@"invoke15s returning");
	return (struct c_c) { 'r', 'R' };
}

- (void) test15_small_struct
{ // reading/writing small C struct arguments
	id target=self;
	SEL sel=@selector(invoke15s:b:c:);
	char a='a';
	struct c_c b={ 'b', 'B' };
	struct c_c c={ 'c', 'C' }, *cp=&c;
	struct c_c r={ 1, 2 };
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];	// pass as copy on stack
	[i setArgument:&cp atIndex:4];	// pass as pointer to struct on stack
	invoked=0;
	[i invoke];
	XCTAssertEqual(invoked, -15, @"");
	[i getReturnValue:&r];
	XCTAssertEquals(r, ((struct c_c) { 'r', 'R' }), @"");
	/*
	 [i getArgument:&obj atIndex:2];
	 XCTAssertEqualObjects(obj, @"a", @"");
	 [i getArgument:&obj atIndex:3];
	 XCTAssertEqualObjects(obj, @"b", @"");
	 [i getArgument:&obj atIndex:4];
	 XCTAssertEqualObjects(obj, @"c", @"");
	 [i getArgument:&obj atIndex:5];
	 XCTAssertEqualObjects(obj, @"d", @"");
	 [i getArgument:&obj atIndex:6];
	 XCTAssertEqualObjects(obj, @"e", @"");
	 [i getArgument:&obj atIndex:7];
	 XCTAssertEqualObjects(obj, @"f", @"");
	 [i getArgument:&obj atIndex:8];
	 XCTAssertEqualObjects(obj, @"g", @"");
	 */
	/* conclusions
	 * works
	 */
}

- (struct i_ll *) invoke16:(char) a b:(struct i_ll) b c:(struct i_ll *) c
{ // return struct by reference
	invoked=16;
	XCTAssertEqual(a, (char) 'a', @"");
	XCTAssertEqual(b.a, 1234, @"");
	XCTAssertEqual(b.b, 123456789ll, @"");
	XCTAssertEqual(c->a, 4321, @"");
	XCTAssertEqual(c->b, 987654321ll, @"");
	return c;
}

- (void) test16_char_big_structs
{ // reading/writing many C type arguments
	id target=self;
	SEL sel=@selector(invoke16:b:c:);
	char a='a';
	struct i_ll b={ 1234, 123456789 };
	struct i_ll c={ 4321, 987654321 }, *cp=&c;
	struct i_ll *r=NULL;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&cp atIndex:4];	// passs pointer
	invoked=0;
	[i invoke];
	XCTAssertEqual(invoked, 16, @"");
	[i getReturnValue:&r];
	XCTAssertEqual(r, cp, @"");
	XCTAssertEqual(r->a, c.a, @"");
	XCTAssertEqual(r->b, c.b, @"");
	/*
	 [i getArgument:&obj atIndex:2];
	 XCTAssertEqualObjects(obj, @"a", @"");
	 [i getArgument:&obj atIndex:3];
	 XCTAssertEqualObjects(obj, @"b", @"");
	 [i getArgument:&obj atIndex:4];
	 XCTAssertEqualObjects(obj, @"c", @"");
	 [i getArgument:&obj atIndex:5];
	 XCTAssertEqualObjects(obj, @"d", @"");
	 [i getArgument:&obj atIndex:6];
	 XCTAssertEqualObjects(obj, @"e", @"");
	 [i getArgument:&obj atIndex:7];
	 XCTAssertEqualObjects(obj, @"f", @"");
	 [i getArgument:&obj atIndex:8];
	 XCTAssertEqualObjects(obj, @"g", @"");
	 */
	/* conclusions
	 * works
	 */
}

// FIXME: write a test if we handle zero-sized structs byref or bycopy correctly

- (void) test17_nil_target
{ // invoke nil target
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 4, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:nil];
	[i setSelector:sel];
	[i setArgument:&self atIndex:2];
	[i setArgument:&self atIndex:3];
	// NOTE: we should also test if this is correctly released by the non-called invocation if we have -retainArguments mode
	[i setReturnValue:&self];
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	[i getReturnValue:&obj];
	XCTAssertEqualObjects(obj, self, @"");	// has been stored
	[i invoke];	// invoke nil target
	XCTAssertEqual(invoked, 0, @"");	// has NOT been called
	[i getReturnValue:&obj];
	XCTAssertEqualObjects(obj, nil, @"");	// has been wiped out
}

// FIXME: write a test what happens if we use &self, &_cmd, &a in the called method
// since they are normally passed in registers (on armhf)

- (void) invoke20
{ // raise exception within invoked method
	invoked=20;
	[NSException raise:@"Test Exception" format:@"no format"];
	invoked=-20;
}

- (void) test20_raise_exception
{
	id target=self;
	SEL sel=@selector(invoke20);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 2, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:target];
	[i setSelector:sel];
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	XCTAssertThrowsSpecificNamed([i invoke], NSException, @"Test Exception", @"");
	XCTAssertEqual(invoked, 20, @"");	// should not be -20...
}

- (void) invoke30
{ // nested invocations
	invoked=30;
	
}

- (void) test30_nimp
{
	
}

- (NSMethodSignature *) methodSignatureForSelector:(SEL) aSelector
{ // handle dynamic method signatures
	if(sel_isEqual(aSelector, @selector(forward40)))
		return [NSMethodSignature signatureWithObjCTypes:"v@:"];	// void return
	if(sel_isEqual(aSelector, @selector(forward41:b:)))
		return [NSMethodSignature signatureWithObjCTypes:"i@:ii"];	// int return and several int arguments
	if(sel_isEqual(aSelector, @selector(forward42:b:c:d:e:f:)))
		return [NSMethodSignature signatureWithObjCTypes:"i@:iiiiii"];	// int return and several int arguments
	if(sel_isEqual(aSelector, @selector(forward43:b:)))
		return [NSMethodSignature signatureWithObjCTypes:"@@:@@"];	// id return and two id arguments
	if(sel_isEqual(aSelector, @selector(forward44)))
		return [NSMethodSignature signatureWithObjCTypes:"v@:"];	// void return
	if(sel_isEqual(aSelector, @selector(forward45)))
		return [NSMethodSignature signatureWithObjCTypes:"v@:"];	// void return
	if(sel_isEqual(aSelector, @selector(forward46:b:)))
		return [NSMethodSignature signatureWithObjCTypes:"i@:ii"];	// int return and several int arguments
	if(sel_isEqual(aSelector, @selector(forward47:b:c:d:e:f:)))
		return [NSMethodSignature signatureWithObjCTypes:"f@:iififf"];	// float return and several int and float arguments mixed
	if(sel_isEqual(aSelector, @selector(forward48:b:c:d:e:f:)))
		return [NSMethodSignature signatureWithObjCTypes:"d@:iqfidf"];	// double return and several int and float, double arguments mixed
	if(sel_isEqual(aSelector,@selector(forward49:b:c:)))
		return [NSMethodSignature signatureWithObjCTypes:"v@:fd{f_d=fd}"];	// double return and several int and float, double arguments mixed
	// same for structs...
	return [super methodSignatureForSelector:aSelector];	// default
}

- (void) forwardInvocation:(NSInvocation *)anInvocation
{ // test forward:: and forwardInvocation: - should also test nesting, i.e. modifying the target and sending again
	SEL sel=[anInvocation selector];
	XCTAssertEqualObjects([anInvocation target], self, @"");
	XCTAssertTrue(sel_isEqual(_cmd, @selector(forwardInvocation:)), @"");
	invoked=-99;
	NSLog(@"** self=%p _cmd=%p %@ sel=%p %@ called **", self, _cmd, NSStringFromSelector(_cmd), sel, NSStringFromSelector(sel));
#if 0
	NSLog(@"** self=%p _cmd=%p sel=%p %@ called **", self, _cmd, sel, NSStringFromSelector(sel));
	NSLog(@"** Cstring %s **", "forward40");
	NSLog(@"** %p - %p **", sel, @selector(forward40));
	NSLog(@"** %02x - %02x **", *(char *)sel, *(char *)@selector(forward40));
	NSLog(@"** %s - %s **", sel, @selector(forward40));
	NSLog(@"** %s - %s **", sel_getName(sel), sel_getName(@selector(forward40)));
#endif
	if(sel_isEqual(sel, @selector(forward40)))
		{
		NSLog(@"here forward40");
		invoked=40;
		}
	else if(sel_isEqual(sel, @selector(forward41:b:)))
		{ // return an int
			int ret='r';
			NSLog(@"here forward41:b:");
			invoked=41;
			[anInvocation setReturnValue:&ret];
		}
	else if(sel_isEqual(sel, @selector(forward42:b:c:d:e:f:)))
		{ // return an int
			int p;
			int ret='r';
			id s=self;
			[anInvocation getArgument:&p atIndex:2];
			XCTAssertEqual(p, 1, @"");
			[anInvocation getArgument:&p atIndex:3];
			XCTAssertEqual(p, 2, @"");
			[anInvocation getArgument:&p atIndex:4];
			XCTAssertEqual(p, 3, @"");
			[anInvocation getArgument:&p atIndex:5];
			XCTAssertEqual(p, 4, @"");
			[anInvocation getArgument:&p atIndex:6];
			XCTAssertEqual(p, 5, @"");
			[anInvocation getArgument:&p atIndex:7];
			XCTAssertEqual(p, 6, @"");
			invoked=42;
			[anInvocation setReturnValue:&ret];
			XCTAssertEqualObjects([anInvocation target], s, @"");	// was not overwritten by setReturnValue - even if this is stored in the same register
			[anInvocation getArgument:&p atIndex:2];
			XCTAssertEqual(p, 1, @"");
			[anInvocation getArgument:&p atIndex:3];
			XCTAssertEqual(p, 2, @"");
			[anInvocation getArgument:&p atIndex:4];
			XCTAssertEqual(p, 3, @"");
			[anInvocation getArgument:&p atIndex:5];
			XCTAssertEqual(p, 4, @"");
			[anInvocation getArgument:&p atIndex:6];
			XCTAssertEqual(p, 5, @"");
			[anInvocation getArgument:&p atIndex:7];
			XCTAssertEqual(p, 6, @"");
		}
	else if(sel_isEqual(sel, @selector(forward43:b:)))
		{ // return a string
			id ret=@"the result";
			invoked=43;
			[anInvocation setReturnValue:&ret];
		}
	else if(sel_isEqual(sel, @selector(forward44)))
		{ // forward with a modified selector
			invoked=44;
			[anInvocation setSelector:@selector(invoke01)];
			XCTAssertEqual(invoked, 44, @"");
			[anInvocation invoke];
			XCTAssertEqual(invoked, 1, @"");
		}
	else if(sel_isEqual(sel, @selector(forward45)))
		{ // can we forward to another dynamically implemented method?
			invoked=45;
			[anInvocation setSelector:@selector(forward40)];
			XCTAssertEqual(invoked, 45, @"");
			[anInvocation invoke];	// forward with a different selector
			XCTAssertEqual(invoked, 40, @"");
		}
	else if(sel_isEqual(sel, @selector(forward46:b:)))
		{ // we explicitly don't set a return value to see if that raises an exception or something!
			int ret='r';
			invoked=46;
			/*
			 * [anInvocation setReturnValue:&ret];
			 */
		}
	else if(sel_isEqual(sel, @selector(forward47:b:c:d:e:f:)))
		{
		int ival=0;
		float fval=0.0;
		float r=3.1415;
		invoked=47;
		XCTAssertEqual(ival, 0, @"");
		XCTAssertEqual(fval, 0.0f, @"");
		[anInvocation getArgument:&ival atIndex:2];
		XCTAssertEqual(ival, 1, @"");
		[anInvocation getArgument:&ival atIndex:3];
		XCTAssertEqual(ival, 2, @"");
		[anInvocation getArgument:&fval atIndex:4];
		XCTAssertEqual(fval, 3.0f, @"");
		[anInvocation getArgument:&ival atIndex:5];
		XCTAssertEqual(ival, 4, @"");
		[anInvocation getArgument:&fval atIndex:6];
		XCTAssertEqual(fval, 5.0f, @"");
		[anInvocation getArgument:&fval atIndex:7];
		XCTAssertEqual(fval, 6.0f, @"");
		[anInvocation setReturnValue:&r];
		}
	else if(sel_isEqual(sel, @selector(forward48:b:c:d:e:f:)))
		{
		int ival=0;
		long long llval=0;
		float fval=0.0;
		double dval=0;
		double r=3.1415;
		invoked=48;
		XCTAssertEqual(ival, 0, @"");
		XCTAssertEqual(llval, 0ll, @"");
		XCTAssertEqual(fval, 0.0f, @"");
		XCTAssertEqual(dval, 0.0, @"");
		[anInvocation getArgument:&ival atIndex:2];
		XCTAssertEqual(ival, 1, @"");
		[anInvocation getArgument:&llval atIndex:3];
		XCTAssertEqual(llval, -2ll, @"");
		[anInvocation getArgument:&fval atIndex:4];
		XCTAssertEqual(fval, 3.0f, @"");
		[anInvocation getArgument:&ival atIndex:5];
		XCTAssertEqual(ival, 4, @"");
		[anInvocation getArgument:&dval atIndex:6];
		XCTAssertEqual(dval, 5.0, @"");
		[anInvocation getArgument:&fval atIndex:7];
		XCTAssertEqual(fval, 6.0f, @"");
		[anInvocation setReturnValue:&r];
		}
	else if(sel_isEqual(sel,@selector(forward49:b:c:)))
		{
		invoked=49;
		}
	else
		XCTAssertTrue(NO, @"unrecognized selector");
	NSLog(@"** %@ done **", NSStringFromSelector(sel));
}

- (void) test40_simple_forward
{
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	[self forward40];
	XCTAssertEqual(invoked, 40, @"");	// should have been invoked
	// we could also test parameter passing for indirect calls
	/* conclusions
	 * -methodSignatureForSelector must be overwritten or we can't call the dynamically defined method
	 * it is possible to forward an invocation within forwardInvocation to a different selector/object
	 */
}

- (void) test41_forward_with_args
{
	int ir=0;
	invoked=0;
	ir=[self forward41:1 b:2];
	XCTAssertEqual(invoked, 41, @"");	// should have been invoked
	XCTAssertEqual(ir, 'r', @"");
}

- (void) test42_forward_with_many_args
{
	int ir=0;
	invoked=0;
	ir=[self forward42:1 b:2 c:3 d:4 e:5 f:6];
	XCTAssertEqual(invoked, 42, @"");	// should have been invoked
	XCTAssertEqual(ir, 'r', @"");
}

- (void) test43_forward_with_string_result
{
	id a=self;
	id b=self;
	id r=self;
	invoked=0;
	r=[self forward43:a b:b];
	XCTAssertEqual(invoked, 43, @"");	// should have been invoked
	XCTAssertEqualObjects(r, @"the result", @"");
}

- (void) test44_nested_invoke
{ // nested invoke
	invoked=0;
	[self forward44];
	XCTAssertEqual(invoked, 1, @"");	// invoke01 should have been invoked in the second step
}

- (void) test45_nested_invoke
{ // nested invoke
	invoked=0;
	[self forward45];
	XCTAssertEqual(invoked, 40, @"");	// forward40 should have been invoked in the second step
}

- (void) test46_missing_setReturnValue
{ // what happens if forward-invocation does not set a return value?
	int ir=0;
	invoked=0;
	ir=[self forward46:1 b:2];	// does not set a return value!
	XCTAssertEqual(invoked, 46, @"");	// should have been invoked
	XCTAssertEqual(ir, 0, @"unreliable");	// most likely because the stack frame is not initialized - it is not clear if this is reproducible by our implementation
}

- (void) test47_forward_float_return
{ // float return
	float fr=0.0;
	invoked=0;
	fr=[self forward47:1 b:2 c:3.0f d:4 e:5 f:6.0];
	XCTAssertEqual(invoked, 47, @"");	// should have been invoked
	XCTAssertEqual(fr, 3.1415f, @"");
}

- (void) test48_forward_double_return
{ // double return
	double fr=0.0;
	invoked=0;
	fr=[self forward48:1 b:-2 c:3.0f d:4 e:5 f:6.0];
	XCTAssertEqual(invoked, 48, @"");	// should have been invoked
	XCTAssertEqual(fr, 3.1415, @"");
}

- (void) test49_forward_struct
{ // similar to test14df
	id target=self;
	SEL sel=@selector(invoke14dfs:b:c:);
	float a=1.1;
	double b=2.2;
	struct f_d c={
		3.3,
		4.4
	};
	[self forward49:a b:b c:c];
	XCTAssertEqual(invoked, 49, @"");
}

// FIXME: forward_struct_return!

- (id) invoke60:(id) a b:(id) b
{ // return an autoreleased object
	invoked=60;
	XCTAssertEqual([a retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 1, @"");
	return [[[NSObject alloc] init] autorelease];	// should be placed in the ARP where the -invoke is issued
}

- (void) test60_retain_count
{
	id target=self;
	SEL sel=@selector(invoke60:b:);
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	id a=[[[NSObject alloc] init] autorelease];
	id b=[[[NSObject alloc] init] autorelease];
	NSAutoreleasePool *arp2=[NSAutoreleasePool new];	// create an ARP where the NSInvocation is autoreleased
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	NSAutoreleasePool *arp;
	NSUInteger rc;
	id r;
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 4, @"");
	XCTAssertNotNil(i, @"");
	XCTAssertEqual([a retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 1, @"");
	rc=[target retainCount];
	[i setTarget:target];
	XCTAssertEqual([target retainCount], rc, @"");	// has not changed
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	XCTAssertEqual([a retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 1, @"");
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	arp=[NSAutoreleasePool new];	// create a private ARP so that r is autoreleased there
	[i invoke];
	XCTAssertEqual(invoked, 60, @"");
	XCTAssertEqual([a retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 1, @"");
	[i getReturnValue:&r];
	XCTAssertEqual([r retainCount], (NSUInteger) 1, @"");
	[r retain];
	XCTAssertEqual([r retainCount], (NSUInteger) 2, @"");
	[arp release];	// this should release r
	XCTAssertEqual([r retainCount], (NSUInteger) 1, @"");
	XCTAssertFalse([i argumentsRetained], @"");
	[i retainArguments];
	XCTAssertTrue([i argumentsRetained], @"");
	XCTAssertEqual([a retainCount], (NSUInteger) 2, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 2, @"");
	XCTAssertEqual([r retainCount], (NSUInteger) 2, @"");
	[i retainArguments];
	XCTAssertEqual([a retainCount], (NSUInteger) 2, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 2, @"");
	XCTAssertEqual([r retainCount], (NSUInteger) 2, @"");
	[arp2 release];	// this releases the invocation - and all retained arguments
	XCTAssertEqual([a retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([b retainCount], (NSUInteger) 1, @"");
	XCTAssertEqual([r retainCount], (NSUInteger) 1, @"");
	[r release];
	/* conclusions
	 * the current APR is used for invocations (i.e. it does not have a private one)
	 * -retainArguments also retains the returnValue
	 * calling -retainArguments twice does not retain twice
	 */
}

- (void) test61_retain_count_for_setReturnValue
{ // invoke nil target with predefined return-value
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj;
	id test;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 4, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:nil];
	[i setSelector:sel];
	[i setArgument:&self atIndex:2];
	[i setArgument:&self atIndex:3];
	test=[NSObject new];
	XCTAssertEqual([test retainCount], (NSUInteger) 1, @"");
	[i setReturnValue:&test];
	[i retainArguments];
	XCTAssertEqual([test retainCount], (NSUInteger) 2, @"");
	invoked=0;
	XCTAssertEqual(invoked, 0, @"");
	[i getReturnValue:&obj];
	XCTAssertEqualObjects(obj, test, @"");	// has been stored
	[i invoke];	// invoke nil target
	XCTAssertEqual([test retainCount], (NSUInteger) 2, @"");	// previously set return value should have been released - but has not (but may have been autoreleased)!
	XCTAssertEqual(invoked, 0, @"");	// has NOT been called
	[i getReturnValue:&obj];
	XCTAssertEqualObjects(obj, nil, @"");	// has been wiped out
	/* conclusion
	 * invoking a nil target leaks a previously retained returnValue on OS X 10.6
	 * NOTE: this test is not able to find out if the value is autoreleased later!
	 */
}

- (void) test63_retain_count_for_setArguments
{ // test if setArguments releases previous retain
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj;
	id test, test2;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	XCTAssertNotNil(ms, @"");
	XCTAssertEqual([ms numberOfArguments], (NSUInteger) 4, @"");
	XCTAssertNotNil(i, @"");
	[i setTarget:nil];
	[i setSelector:sel];
	test=[NSObject new];
	XCTAssertEqual([test retainCount], (NSUInteger) 1, @"");
	[i setArgument:&test atIndex:2];
	[i retainArguments];
	XCTAssertEqual([test retainCount], (NSUInteger) 2, @"");
	test2=[NSObject new];
	XCTAssertEqual([test2 retainCount], (NSUInteger) 1, @"");
	[i setArgument:&test2 atIndex:2];	// replace
	XCTAssertEqual([test retainCount], (NSUInteger) 2, @"");	// likely autoreleased
	XCTAssertEqual([test2 retainCount], (NSUInteger) 2, @"");
	[i setArgument:&test2 atIndex:3];	// set (with retainArguments enabled)
	XCTAssertEqual([test2 retainCount], (NSUInteger) 3, @"");	// ok, is retained before setting
	/* conclusion
	 * retainArguments only instructs to retain - but does not release
	 * NOTE: this test is not able to find out if they are autoreleased later!
	 */
}

@end
