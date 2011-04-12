/*
    NSExpression.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	9. May 2008 - aligned with 10.5 

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSPredicate.h>

@class NSMutableDictionary;

typedef enum _NSExpressionType
{
	NSConstantValueExpressionType=0,
	NSEvaluatedObjectExpressionType,
	NSVariableExpressionType,
	NSKeyPathExpressionType,
	NSFunctionExpressionType,
	NSSubqueryExpressionType,
	NSAggregateExpressionType,
	NSUnionExpressionType,
	NSIntersectExpressionType,
	NSMinusExpressionType 
} NSExpressionType;

@interface NSExpression : NSObject <NSCoding, NSCopying>

+ (NSExpression *) expressionForAggregate:(NSArray *) elements;
+ (NSExpression *) expressionForConstantValue:(id) obj;			// 123, "123" etc.
+ (NSExpression *) expressionForEvaluatedObject;				// i.e. SELF
+ (NSExpression *) expressionForFunction:(NSString *) name arguments:(NSArray *) args;	// function(args, ...)
+ (NSExpression *) expressionForFunction:(NSExpression *) exp selectorName:(NSString *) selectorName arguments:(NSArray *) params;
+ (NSExpression *) expressionForIntersectSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
+ (NSExpression *) expressionForKeyPath:(NSString *) path;		// object.path incl. indexed expressions (?)
+ (NSExpression *) expressionForMinusSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
+ (NSExpression *) expressionForSubquery:(NSExpression *) exp usingIteratorVariable:(NSString *) var predicate:(id) pred;
+ (NSExpression *) expressionForUnionSet:(NSExpression *) leftExp with:(NSExpression *) rightExp;
+ (NSExpression *) expressionForVariable:(NSString *) string;	// $VARIABLE

- (NSArray *) arguments;
- (id) collection;
- (id) constantValue;
- (NSExpressionType) expressionType;
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context;
- (NSString *) function;
- (id) initWithExpressionType:(NSExpressionType) type;	// returns a subclass instance but does not initialize expression arguments!
- (NSString *) keyPath;
- (NSExpression *) leftExpression;
- (NSExpression *) operand;
- (NSPredicate *) predicate;
- (NSExpression *) rightExpression;
- (NSString *) variable;

@end
