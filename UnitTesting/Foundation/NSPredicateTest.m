//
//  NSPredicateTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SenTestingKit/SenTestingKit.h>


@interface NSPredicateTest : SenTestCase
{
	NSMutableDictionary *dict;
}

@end


@implementation NSPredicateTest

- (void) test1
{
	NSPredicate *p;
	p=[NSPredicate predicateWithFormat:@"%K like %@+$b+$c", @"$single", @"b\""];
	STAssertEqualObjects([p predicateFormat], @"$single LIKE (\"b\\\"\" + $b) + $c", nil);
#if 1
	if([p respondsToSelector:@selector(subpredicates)])
		NSLog(@"subpredicates=%@", [(NSCompoundPredicate *)p subpredicates]);
	if([p respondsToSelector:@selector(leftExpression)])
		NSLog(@"left=%@", [(NSComparisonPredicate *)p leftExpression]);
	if([p respondsToSelector:@selector(rightExpression)])
		NSLog(@"right=%@", [(NSComparisonPredicate *)p rightExpression]);
#endif
	p=[p predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
																					 @"val_for_single_string", @"single",	// why %K does not make a variable
																					 @"val_for_$b", @"b",
																					 @"val_for_$c", @"c",
																					 nil]];
	STAssertEqualObjects([p predicateFormat], @"$single LIKE (\"b\\\"\" + \"val_for_$b\") + \"val_for_$c\"", nil);
}

// add many more such tests

/* tests copied from GNUstep */
 
- (void) setUp
{
	NSDictionary *d;
	dict = [[NSMutableDictionary alloc] init];
	[dict setObject: @"A Title" forKey: @"title"];
	
	d = [NSDictionary dictionaryWithObjectsAndKeys:
		 @"John", @"Name",
		 [NSNumber numberWithInt: 34], @"Age",
		 [NSArray arrayWithObjects: @"Kid1", @"Kid2", nil], @"Children",
		 nil];
	[dict setObject: d forKey: @"Record1"];
	
	d = [NSDictionary dictionaryWithObjectsAndKeys:
		 @"Mary", @"Name",
		 [NSNumber numberWithInt: 30], @"Age",
		 [NSArray arrayWithObjects: @"Kid1", @"Girl1", nil], @"Children",
		 nil];
	[dict setObject: d forKey: @"Record2"];	
}

- (void) tearDown
{
	[dict release];
}

// FIXME: replace STAssertTrue by more verbose STAsserts

- (void) testKVC
{
	STAssertTrue([@"A Title" isEqual: [dict valueForKey: @"title"]], @"valueForKeyPath: with string");
	STAssertTrue([@"A Title" isEqual: [dict valueForKeyPath: @"title"]], @"valueForKeyPath: with string");
	STAssertTrue([@"John" isEqual: [dict valueForKeyPath: @"Record1.Name"]], @"valueForKeyPath: with string");
	STAssertTrue(30 == [[dict valueForKeyPath: @"Record2.Age"] intValue], @"valueForKeyPath: with int");
}

- (void) testContains
{
	NSPredicate *p;
	p = [NSPredicate predicateWithFormat: @"%@ CONTAINS %@", @"AABBBAA", @"BBB"];
	STAssertTrue([p evaluateWithObject: dict], @"%%@ CONTAINS %%@");
	p = [NSPredicate predicateWithFormat: @"%@ IN %@", @"BBB", @"AABBBAA"];
	STAssertTrue([p evaluateWithObject: dict], @"%%@ IN %%@");
}

- (void) testString
{
	NSPredicate *p;
	
	p = [NSPredicate predicateWithFormat: @"%K == %@", @"Record1.Name", @"John"];
	STAssertTrue([p evaluateWithObject: dict], @"%%K == %%@");
	p = [NSPredicate predicateWithFormat: @"%K MATCHES[c] %@", @"Record1.Name", @"john"];
	STAssertTrue([p evaluateWithObject: dict], @"%%K MATCHES[c] %%@");
	p = [NSPredicate predicateWithFormat: @"%K BEGINSWITH %@", @"Record1.Name", @"Jo"];
	STAssertTrue([p evaluateWithObject: dict], @"%%K BEGINSWITH %%@");
	p = [NSPredicate predicateWithFormat: @"(%K == %@) AND (%K == %@)", @"Record1.Name", @"John", @"Record2.Name", @"Mary"];
	STAssertTrue([p evaluateWithObject: dict], @"(%%K == %%@) AND (%%K == %%@)");
}

- (void) testInteger
{
	NSPredicate *p;
	
	p = [NSPredicate predicateWithFormat: @"%K == %d", @"Record1.Age", 34];
	STAssertTrue([p evaluateWithObject: dict], @"%%K == %%d");
	p = [NSPredicate predicateWithFormat: @"%K = %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K = %%@");
	p = [NSPredicate predicateWithFormat: @"%K == %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K == %%@");
	p = [NSPredicate predicateWithFormat: @"%K < %d", @"Record1.Age", 40];
	STAssertTrue([p evaluateWithObject: dict], @"%%K < %%d");
	p = [NSPredicate predicateWithFormat: @"%K < %@", @"Record1.Age", [NSNumber numberWithInt: 40]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K < %%@");
	p = [NSPredicate predicateWithFormat: @"%K <= %@", @"Record1.Age", [NSNumber numberWithInt: 40]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K <= %%@");
	p = [NSPredicate predicateWithFormat: @"%K <= %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K <= %%@");
	p = [NSPredicate predicateWithFormat: @"%K > %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K > %%@");
	p = [NSPredicate predicateWithFormat: @"%K >= %@", @"Record1.Age", [NSNumber numberWithInt: 34]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K >= %%@");
	p = [NSPredicate predicateWithFormat: @"%K >= %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K >= %%@");
	p = [NSPredicate predicateWithFormat: @"%K != %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K != %%@");
	p = [NSPredicate predicateWithFormat: @"%K <> %@", @"Record1.Age", [NSNumber numberWithInt: 20]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K <> %%@");
	p = [NSPredicate predicateWithFormat: @"%K BETWEEN %@", @"Record1.Age", [NSArray arrayWithObjects: [NSNumber numberWithInt: 20], [NSNumber numberWithInt: 40], nil]];
	STAssertTrue([p evaluateWithObject: dict], @"%%K BETWEEN %%@");
	p = [NSPredicate predicateWithFormat: @"(%K == %d) OR (%K == %d)", @"Record1.Age", 34, @"Record2.Age", 34];
	STAssertTrue([p evaluateWithObject: dict], @"(%%K == %%d) OR (%%K == %%d)");
	
	
}

- (void) testFloat
{
	NSPredicate *p;
	
	p = [NSPredicate predicateWithFormat: @"%K < %f", @"Record1.Age", 40.5];
	STAssertTrue([p evaluateWithObject: dict], @"%%K < %%f");
	p = [NSPredicate predicateWithFormat: @"%f > %K", 40.5, @"Record1.Age"];
	STAssertTrue([p evaluateWithObject: dict], @"%%f > %%K");
}

- (void) testAggregate
{
	NSPredicate *p;
	
	p = [NSPredicate predicateWithFormat: @"%@ IN %K", @"Kid1", @"Record1.Children"];
	STAssertTrue([p evaluateWithObject: dict], @"%%@ IN %%K");
	p = [NSPredicate predicateWithFormat: @"Any %K == %@", @"Record2.Children", @"Girl1"];
	STAssertTrue([p evaluateWithObject: dict], @"Any %%K == %%@");
}

- (void) testFiltered
{
	NSArray *filtered;
	NSArray *pitches;
	NSArray *expect;
	NSPredicate *p;
	NSDictionary *d;
	
	
	pitches = [NSArray arrayWithObjects:
			   @"Do", @"Re", @"Mi", @"Fa", @"So", @"La", nil];
	expect = [NSArray arrayWithObjects: @"Do", nil];
	
	filtered = [pitches filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat: @"SELF == 'Do'"]];  
	STAssertTrue([filtered isEqual: expect], @"filter with SELF");
	
	filtered = [pitches filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat: @"description == 'Do'"]];
	STAssertTrue([filtered isEqual: expect], @"filter with description");
	
	filtered = [pitches filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat: @"SELF == '%@'", @"Do"]];
	STAssertTrue([filtered isEqual: [NSArray array]], @"filter with format");
	
	STAssertTrue([NSExpression expressionForEvaluatedObject]
		 == [NSExpression expressionForEvaluatedObject],
		 @"expressionForEvaluatedObject is unique");
	
	p = [NSPredicate predicateWithFormat: @"SELF == 'aaa'"];
	STAssertTrue([p evaluateWithObject: @"aaa"], @"SELF equality works");
}

#ifndef __APPLE__	// only for 10.7 or later
- (void) testExpression
{
	NSExpression *e;
	
	e = [NSExpression expressionWithFormat: @"3*5+2"];
	STAssertTrue([[e expressionValueWithObject:nil context:nil] intValue] == 17, nil);
	e = [NSExpression expressionWithFormat: @"self"];
	STAssertTrue([[e expressionValueWithObject:@"23" context:nil] intValue] == 23, nil);
}
#endif

@end
