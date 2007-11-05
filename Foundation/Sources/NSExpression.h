//
//  NSExpression.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

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

+ (NSExpression *) expressionForConstantValue:(id) obj;			// 123, "123" etc.
+ (NSExpression *) expressionForEvaluatedObject;				// i.e. SELF
+ (NSExpression *) expressionForFunction:(NSString *) name arguments:(NSArray *) args;	// function(args, ...)
+ (NSExpression *) expressionForFunction:(NSString *) name selectorName:(SEL) sel arguments:(NSArray *) args;	// function(args, ...)
+ (NSExpression *) expressionForKeyPath:(NSString *) path;		// object.path incl. indexed expressions (?)
+ (NSExpression *) expressionForVariable:(NSString *) string;	// $VARIABLE

- (NSArray *) arguments;
- (id) constantValue;
- (NSExpressionType) expressionType;
- (id) expressionValueWithObject:(id) object context:(NSMutableDictionary *) context;
- (NSString *) function;
- (id) initWithExpressionType:(NSExpressionType) type;	// returns a subclass instance but does not initialize expression arguments!
- (NSString *) keyPath;
- (NSExpression *) operand;
- (NSString *) variable;

@end