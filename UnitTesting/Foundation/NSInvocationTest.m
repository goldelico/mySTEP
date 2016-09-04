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

#import <SenTestingKit/SenTestingKit.h>

@interface NSInvocationTest : SenTestCase {
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

- (void) test01_basic
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

- (void) test02_args_and_ret
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

- (void) test03_missing_target_or_selector
{ // missing target or selector or NULL arguments
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
	STAssertThrowsSpecificNamed([i setArgument:NULL atIndex:0], NSException, NSInvalidArgumentException, nil);	// NULL address throws
	STAssertThrowsSpecificNamed([i getArgument:NULL atIndex:0], NSException, NSInvalidArgumentException, nil);
	/* conclusions
	 * a NULL selector throws an exception
	 * a nil target makes the invoication being ignored
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

- (void) test11_more_get_set_args
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
	obj=nil;
	STAssertNil(obj, nil);
	STAssertNoThrow([i getArgument:&obj atIndex:-1], nil);
	STAssertEqualObjects(obj, self, nil);
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

- (void) test12_invoke_double_and_float_with_return
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
	STAssertTrue(sel_isEqual(_cmd, @selector(invoke13:b:c:d:e:f:g:)), nil);
	STAssertEqualObjects(a, @"a", nil);
	STAssertEqualObjects(b, @"b", nil);
	STAssertEqualObjects(c, @"c", nil);
	STAssertEqualObjects(d, @"d", nil);
	STAssertEqualObjects(e, @"e", nil);
	STAssertEqualObjects(f, @"f", nil);
	STAssertEqualObjects(g, @"g", nil);
	return @"r";
}

- (void) test13_invoke_many_objects_with_return
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
	STAssertEqualObjects(obj, @"g", nil);
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, @"r", nil);
	[i getArgument:&obj atIndex:2];	// this checks if the arguments are still intact after doing the invoke+return
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
	STAssertEquals(d, 0xdd00, nil);
	STAssertEquals(e, 0x1e0000eel, nil);
	NSLog(@"%llx", f);
	STAssertEquals(f, 0x1f00ff0000ff00ffll, nil);
	STAssertEquals(g, (char *) "g", nil);
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

// this is a tricky to implement case
// on some architectures (i386) alignment may differ between stack and structs
// http://www.wambold.com/Martin/writings/alignof.html
// on armhf it *may* be that the compiler knows that the whole struct can be passed in vector registers

- (void) invoke14dfs:(float) a b:(double) b c:(struct f_d) c
{ // pass float and double and struct
	NSLog(@"invoke14dfs called");
	invoked=14;
	NSLog(@"invoked = %d", invoked);
	STAssertEquals(a, (float) 1.1, nil);
	STAssertEquals(b, 2.2, nil);
	NSLog(@"&a=%p a=%g", &a, a);
	NSLog(@"&b=%p b=%lg", &b, b);
	NSLog(@"&c=%p", &c);
	NSLog(@"&c.a=%p c.a=%g", &c.a, c.a);
	NSLog(@"&c.b=%p c.b=%lg", &c.b, c.b);
	STAssertEquals(c.a, (float) 3.3, nil);
	STAssertEquals(c.b, 4.4, nil);
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
	NSLog(@"%d+%d -- %d", sizeof(a), sizeof(b), sizeof(c));
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	[i setArgument:&c atIndex:4];	// pass by copy
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, 14, nil);
}

- (long long) invoke14ll:(char) a b:(long long) b
{ // pass long longs
	NSLog(@"invoke14ll called");
	invoked=-14;
	NSLog(@"invoked = %d", invoked);
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b, 0x1f00ff0000ff00ffll, nil);
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
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, -14, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, 0x7fff00ffff00ff00ll, nil);
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

- (struct i_ll) invoke15:(char) a b:(struct i_ll) b c:(struct i_ll *) c
{ // pass structs by copy and by reference
	NSLog(@"invoke15 called");
	invoked=15;
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b.a, 0x1234, nil);
	STAssertEquals(b.b, 0x7fff00ffff00ff00ll, nil);
	STAssertEquals(c->a, 0x4321, nil);
	STAssertEquals(c->b, 0x1f00ff0000ff00ffll, nil);
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
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
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
	STAssertEquals(invoked, 15, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, ((struct i_ll) { 0xaadd, 0xbbccddee }), nil);
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
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b.a, (char) 'b', nil);
	STAssertEquals(b.b, (char) 'B', nil);
	STAssertEquals(c->a, (char) 'c', nil);
	STAssertEquals(c->b, (char) 'C', nil);
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
	STAssertNotNil(ms, nil);
	STAssertNotNil(i, nil);
	[i setTarget:target];
	[i setSelector:sel];
	[i setArgument:&a atIndex:2];
	[i setArgument:&b atIndex:3];	// pass as copy on stack
	[i setArgument:&cp atIndex:4];	// pass as pointer to struct on stack
	invoked=0;
	[i invoke];
	STAssertEquals(invoked, -15, nil);
	[i getReturnValue:&r];
	STAssertEquals(r, ((struct c_c) { 'r', 'R' }), nil);
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

- (struct i_ll *) invoke16:(char) a b:(struct i_ll) b c:(struct i_ll *) c
{ // return struct by reference
	invoked=16;
	STAssertEquals(a, (char) 'a', nil);
	STAssertEquals(b.a, 1234, nil);
	STAssertEquals(b.b, 123456789ll, nil);
	STAssertEquals(c->a, 4321, nil);
	STAssertEquals(c->b, 987654321ll, nil);
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

// FIXME: write a test if we handle zero-sized structs byref or bycopy correctly

- (void) test17_nil_target
{ // invoke nil target
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 4u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:nil];
	[i setSelector:sel];
	[i setArgument:&self atIndex:2];
	[i setArgument:&self atIndex:3];
	// NOTE: we should also test if this is correctly released by the non-called invocation if we have -retainArguments mode
	[i setReturnValue:&self];
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, self, nil);	// has been stored
	[i invoke];	// invoke nil target
	STAssertEquals(invoked, 0, nil);	// has NOT been called
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, nil, nil);	// has been wiped out
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
	STAssertEqualObjects([anInvocation target], self, nil);
	invoked=-99;
	NSLog(@"** self=%p _cmd=%p sel=%p %@ called **", self, _cmd, sel, NSStringFromSelector(sel));
#if 0
	NSLog(@"** self=%p _cmd=%p sel=%p %@ called **", self, _cmd, sel, NSStringFromSelector(sel));
	NSLog(@"** Cstring %s **", "forward40");
	NSLog(@"** %p - %p **", sel, @selector(forward40));
	NSLog(@"** %02x - %02x **", *(char *)sel, *(char *)@selector(forward40));
	NSLog(@"** %s - %s **", sel, @selector(forward40));
#ifndef __APPLE__	// & SDK before 10.5

	NSLog(@"** %s - %s **", sel_get_name(sel), sel_get_name(@selector(forward40)));
#endif
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
			STAssertEquals(p, 1, nil);
			[anInvocation getArgument:&p atIndex:3];
			STAssertEquals(p, 2, nil);
			[anInvocation getArgument:&p atIndex:4];
			STAssertEquals(p, 3, nil);
			[anInvocation getArgument:&p atIndex:5];
			STAssertEquals(p, 4, nil);
			[anInvocation getArgument:&p atIndex:6];
			STAssertEquals(p, 5, nil);
			[anInvocation getArgument:&p atIndex:7];
			STAssertEquals(p, 6, nil);
			invoked=42;
			[anInvocation setReturnValue:&ret];
			STAssertEqualObjects([anInvocation target], s, nil);	// was not overwritten by setReturnValue - even if this is stored in the same register
			[anInvocation getArgument:&p atIndex:2];
			STAssertEquals(p, 1, nil);
			[anInvocation getArgument:&p atIndex:3];
			STAssertEquals(p, 2, nil);
			[anInvocation getArgument:&p atIndex:4];
			STAssertEquals(p, 3, nil);
			[anInvocation getArgument:&p atIndex:5];
			STAssertEquals(p, 4, nil);
			[anInvocation getArgument:&p atIndex:6];
			STAssertEquals(p, 5, nil);
			[anInvocation getArgument:&p atIndex:7];
			STAssertEquals(p, 6, nil);
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
			STAssertEquals(invoked, 44, nil);
			[anInvocation invoke];
			STAssertEquals(invoked, 1, nil);
		}
	else if(sel_isEqual(sel, @selector(forward45)))
		{ // can we forward to another dynamically implemented method?
			invoked=45;
			[anInvocation setSelector:@selector(forward40)];
			STAssertEquals(invoked, 45, nil);
			[anInvocation invoke];	// forward with a different selector
			STAssertEquals(invoked, 40, nil);
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
		STAssertEquals(ival, 0, nil);
		STAssertEquals(fval, 0.0f, nil);
		[anInvocation getArgument:&ival atIndex:2];
		STAssertEquals(ival, 1, nil);
		[anInvocation getArgument:&ival atIndex:3];
		STAssertEquals(ival, 2, nil);
		[anInvocation getArgument:&fval atIndex:4];
		STAssertEquals(fval, 3.0f, nil);
		[anInvocation getArgument:&ival atIndex:5];
		STAssertEquals(ival, 4, nil);
		[anInvocation getArgument:&fval atIndex:6];
		STAssertEquals(fval, 5.0f, nil);
		[anInvocation getArgument:&fval atIndex:7];
		STAssertEquals(fval, 6.0f, nil);
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
		STAssertEquals(ival, 0, nil);
		STAssertEquals(llval, 0ll, nil);
		STAssertEquals(fval, 0.0f, nil);
		STAssertEquals(dval, 0.0, nil);
		[anInvocation getArgument:&ival atIndex:2];
		STAssertEquals(ival, 1, nil);
		[anInvocation getArgument:&llval atIndex:3];
		STAssertEquals(llval, -2ll, nil);
		[anInvocation getArgument:&fval atIndex:4];
		STAssertEquals(fval, 3.0f, nil);
		[anInvocation getArgument:&ival atIndex:5];
		STAssertEquals(ival, 4, nil);
		[anInvocation getArgument:&dval atIndex:6];
		STAssertEquals(dval, 5.0, nil);
		[anInvocation getArgument:&fval atIndex:7];
		STAssertEquals(fval, 6.0f, nil);
		[anInvocation setReturnValue:&r];
		}
	else if(sel_isEqual(sel,@selector(forward49:b:c:)))
		{
		invoked=49;
		}
	else
		STAssertTrue(NO, @"unrecognized selector");
	NSLog(@"** %@ done **", NSStringFromSelector(sel));
}

- (void) test40_simple_forward
{
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	[self forward40];
	STAssertEquals(invoked, 40, nil);	// should have been invoked
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
	STAssertEquals(invoked, 41, nil);	// should have been invoked
	STAssertEquals(ir, 'r', nil);
}

- (void) test42_forward_with_many_args
{
	int ir=0;
	invoked=0;
	ir=[self forward42:1 b:2 c:3 d:4 e:5 f:6];
	STAssertEquals(invoked, 42, nil);	// should have been invoked
	STAssertEquals(ir, 'r', nil);
}

- (void) test43_forward_with_string_result
{
	id a=self;
	id b=self;
	id r=self;
	invoked=0;
	r=[self forward43:a b:b];
	STAssertEquals(invoked, 43, nil);	// should have been invoked
	STAssertEqualObjects(r, @"the result", nil);
}

- (void) test44_nested_invoke
{ // nested invoke
	invoked=0;
	[self forward44];
	STAssertEquals(invoked, 1, nil);	// invoke01 should have been invoked in the second step
}

- (void) test45_nested_invoke
{ // nested invoke
	invoked=0;
	[self forward45];
	STAssertEquals(invoked, 40, nil);	// forward40 should have been invoked in the second step
}

- (void) test46_missing_setReturnValue
{ // what happens if forward-invocation does not set a return value?
	int ir=0;
	invoked=0;
	ir=[self forward46:1 b:2];	// does not set a return value!
	STAssertEquals(invoked, 46, nil);	// should have been invoked
	STAssertEquals(ir, 0, @"unreliable");	// most likely because the stack frame is not initialized - it is not clear if this is reproducible by our implementation
}

- (void) test47_forward_float_return
{ // float return
	float fr=0.0;
	invoked=0;
	fr=[self forward47:1 b:2 c:3.0f d:4 e:5 f:6.0];
	STAssertEquals(invoked, 47, nil);	// should have been invoked
	STAssertEquals(fr, 3.1415f, nil);
}

- (void) test48_forward_double_return
{ // double return
	double fr=0.0;
	invoked=0;
	fr=[self forward48:1 b:-2 c:3.0f d:4 e:5 f:6.0];
	STAssertEquals(invoked, 48, nil);	// should have been invoked
	STAssertEquals(fr, 3.1415, nil);
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
	STAssertEquals(invoked, 49, nil);
}

// FIXME: forward_struct_return!

- (id) invoke60:(id) a b:(id) b
{ // return an autoreleased object
	invoked=60;
	STAssertEquals([a retainCount], 1u, nil);
	STAssertEquals([b retainCount], 1u, nil);
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
	STAssertFalse([i argumentsRetained], nil);
	[i retainArguments];
	STAssertTrue([i argumentsRetained], nil);
	STAssertEquals([a retainCount], 2u, nil);
	STAssertEquals([b retainCount], 2u, nil);
	STAssertEquals([r retainCount], 2u, nil);
	[i retainArguments];
	STAssertEquals([a retainCount], 2u, nil);
	STAssertEquals([b retainCount], 2u, nil);
	STAssertEquals([r retainCount], 2u, nil);
	[arp2 release];	// this releases the invocation - and all retained arguments
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

- (void) test61_retain_count_for_setReturnValue
{ // invoke nil target with predefined return-value
	id target=self;
	SEL sel=@selector(invoke02:witharg:);
	id obj;
	id test;
	NSMethodSignature *ms=[target methodSignatureForSelector:sel];
	NSInvocation *i=[NSInvocation invocationWithMethodSignature:ms];
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 4u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:nil];
	[i setSelector:sel];
	[i setArgument:&self atIndex:2];
	[i setArgument:&self atIndex:3];
	test=[NSObject new];
	STAssertEquals([test retainCount], 1u, nil);
	[i setReturnValue:&test];
	[i retainArguments];
	STAssertEquals([test retainCount], 2u, nil);
	invoked=0;
	STAssertEquals(invoked, 0, nil);
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, test, nil);	// has been stored
	[i invoke];	// invoke nil target
	STAssertEquals([test retainCount], 2u, nil);	// previously set return value should have been released - but has not (but may have been autoreleased)!
	STAssertEquals(invoked, 0, nil);	// has NOT been called
	[i getReturnValue:&obj];
	STAssertEqualObjects(obj, nil, nil);	// has been wiped out
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
	STAssertNotNil(ms, nil);
	STAssertEquals([ms numberOfArguments], 4u, nil);
	STAssertNotNil(i, nil);
	[i setTarget:nil];
	[i setSelector:sel];
	test=[NSObject new];
	STAssertEquals([test retainCount], 1u, nil);
	[i setArgument:&test atIndex:2];
	[i retainArguments];
	STAssertEquals([test retainCount], 2u, nil);
	test2=[NSObject new];
	STAssertEquals([test2 retainCount], 1u, nil);
	[i setArgument:&test2 atIndex:2];	// replace
	STAssertEquals([test retainCount], 2u, nil);	// likely autoreleased
	STAssertEquals([test2 retainCount], 2u, nil);
	[i setArgument:&test2 atIndex:3];	// set (with retainArguments enabled)
	STAssertEquals([test2 retainCount], 3u, nil);	// ok, is retained before setting
	/* conclusion
	 * retainArguments only instructs to retain - but does not release
	 * NOTE: this test is not able to find out if they are autoreleased later!
	 */
}

@end
