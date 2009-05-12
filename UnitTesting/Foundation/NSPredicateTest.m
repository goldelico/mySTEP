//
//  NSPredicateTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSPredicateTest.h"

// see http://developer.apple.com/tools/unittest.html
// and http://www.cocoadev.com/index.pl?OCUnit


@implementation NSPredicateTest

- (void) test1
{
	NSPredicate *p, *q;
	p=[NSPredicate predicateWithFormat:@"%K like %@+$b+$c", @"$single", @"b\""];
	STAssertEqualObjects(@"%K like $single+$b+$c", [p predicateFormat], nil);

	if([p respondsToSelector:@selector(subpredicates)])
		NSLog(@"subpredicates=%@", [(NSCompoundPredicate *)p subpredicates]);
	if([p respondsToSelector:@selector(leftExpression)])
		NSLog(@"left=%@", [(NSComparisonPredicate *)p leftExpression]);
	if([p respondsToSelector:@selector(rightExpression)])
		NSLog(@"right=%@", [(NSComparisonPredicate *)p rightExpression]);
	q=[p predicateWithSubstitutionVariables:[NSDictionary dictionaryWithObjectsAndKeys:
																					 @"val_for_single_string", @"single",	// why %K does not make a variable
																					 @"val_for_$b", @"b",
																					 @"val_for_$c", @"c",
																					 nil]];
	STAssertEqualObjects(@"\"$single\" like \"b\\\"\"+val_for_$b+val_for_$c", [q predicateFormat], nil);
}

// add many more such tests


@end
