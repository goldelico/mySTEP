//
//  NSPredicateTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPredicateTest.h"


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
#define objc_sizeof_type(T) 1
#define NIMP (NSLog(@"not implemented: %@ %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd)), (void *) 0)
#define SUBCLASS 0

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

#define NSPredicate myNSPredicate
#define NSCompoundPredicate myNSCompoundPredicate
#define NSComparisonPredicate myNSComparisonPredicate
#define NSExpression myNSExpression

#define NSConstantValueExpressionType myNSConstantValueExpressionType
#define NSEvaluatedObjectExpressionType myNSEvaluatedObjectExpressionType
#define NSVariableExpressionType myNSVariableExpressionType
#define NSKeyPathExpressionType myNSKeyPathExpressionType
#define NSFunctionExpressionType myNSFunctionExpressionType
#define NSSubqueryExpressionType myNSSubqueryExpressionType
#define NSAggregateExpressionType myNSAggregateExpressionType
#define NSUnionExpressionType myNSUnionExpressionType
#define NSIntersectExpressionType myNSIntersectExpressionType
#define NSMinusExpressionType myNSMinusExpressionType

#define NSNotPredicateType myNSNotPredicateType
#define NSAndPredicateType myNSAndPredicateType
#define NSOrPredicateType myNSOrPredicateType

#define NSDirectPredicateModifier myNSDirectPredicateModifier
#define NSAllPredicateModifier myNSAllPredicateModifier
#define NSAnyPredicateModifier myNSAnyPredicateModifier

#define NSCaseInsensitivePredicateOption myNSCaseInsensitivePredicateOption
#define NSDiacriticInsensitivePredicateOption myNSDiacriticInsensitivePredicateOption

#define NSLessThanPredicateOperatorType myNSLessThanPredicateOperatorType
#define NSLessThanOrEqualToPredicateOperatorType myNSLessThanOrEqualToPredicateOperatorType
#define NSGreaterThanPredicateOperatorType myNSGreaterThanPredicateOperatorType
#define NSGreaterThanOrEqualToPredicateOperatorType myNSGreaterThanOrEqualToPredicateOperatorType
#define NSEqualToPredicateOperatorType myNSEqualToPredicateOperatorType
#define NSNotEqualToPredicateOperatorType myNSNotEqualToPredicateOperatorType
#define NSMatchesPredicateOperatorType myNSMatchesPredicateOperatorType
#define NSLikePredicateOperatorType myNSLikePredicateOperatorType
#define NSBeginsWithPredicateOperatorType myNSBeginsWithPredicateOperatorType
#define NSEndsWithPredicateOperatorType myNSEndsWithPredicateOperatorType
#define NSInPredicateOperatorType myNSInPredicateOperatorType
#define NSCustomSelectorPredicateOperatorType myNSCustomSelectorPredicateOperatorType
#define NSContainsPredicateOperatorType myNSContainsPredicateOperatorType
#define NSBetweenPredicateOperatorType myNSBetweenPredicateOperatorType
		
#import "../../Foundation/Sources/NSPredicate.h"
#import "../../Foundation/Sources/NSExpression.h"
#import "../../Foundation/Sources/NSCompoundPredicate.h"
#import "../../Foundation/Sources/NSComparisonPredicate.h"
#import "../../Foundation/Sources/NSPredicate.m"
#endif


@implementation NSPredicateTest

- (void) test1
{
	NSPredicate *p, *q;
	p=[NSPredicate predicateWithFormat:@"%K like %@+$b+$c", @"$single", @"b\""];
	STAssertEqualObjects(@"$single LIKE (\"b\\\"\" + $b) + $c", [p predicateFormat], nil);

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
	STAssertEqualObjects(@"$single LIKE (\"b\\\"\" + \"val_for_$b\") + \"val_for_$c\"", [q predicateFormat], nil);
}

// add many more such tests


@end
