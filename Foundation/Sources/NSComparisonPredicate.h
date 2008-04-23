/*
    NSComparisonPredicate.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.

    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	22. April 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSExpression.h>
#import <Foundation/NSPredicate.h>

typedef enum _NSComparisonPredicateModifier
{
	NSDirectPredicateModifier=0,
	NSAllPredicateModifier,
	NSAnyPredicateModifier,
} NSComparisonPredicateModifier;

typedef enum _NSComparisonPredicateOptions
{
	NSCaseInsensitivePredicateOption=0x01,
	NSDiacriticInsensitivePredicateOption=0x02,
} NSComparisonPredicateOptions;

typedef enum _NSPredicateOperatorType
{
	NSLessThanPredicateOperatorType = 0,
	NSLessThanOrEqualToPredicateOperatorType,
	NSGreaterThanPredicateOperatorType,
	NSGreaterThanOrEqualToPredicateOperatorType,
	NSEqualToPredicateOperatorType,
	NSNotEqualToPredicateOperatorType,
	NSMatchesPredicateOperatorType,
	NSLikePredicateOperatorType,
	NSBeginsWithPredicateOperatorType,
	NSEndsWithPredicateOperatorType,
	NSInPredicateOperatorType,
	NSCustomSelectorPredicateOperatorType,
	NSContainsPredicateOperatorType,
	NSBetweenPredicateOperatorType
} NSPredicateOperatorType;

@interface NSComparisonPredicate : NSPredicate
{
	NSComparisonPredicateModifier _modifier;
	SEL _selector;
	unsigned _options;
	NSPredicateOperatorType _type;
	@public
	NSExpression *_left, *_right;
}

+ (NSPredicate *) predicateWithLeftExpression:(NSExpression *) left 
							  rightExpression:(NSExpression *) right 
							   customSelector:(SEL) sel;
+ (NSPredicate *) predicateWithLeftExpression:(NSExpression *) left 
							  rightExpression:(NSExpression *) right
									 modifier:(NSComparisonPredicateModifier) modifier 
										 type:(NSPredicateOperatorType) type 
									  options:(NSUInteger) opts;

- (NSComparisonPredicateModifier) comparisonPredicateModifier;
- (SEL) customSelector;
- (NSPredicate *) initWithLeftExpression:(NSExpression *) left 
						 rightExpression:(NSExpression *) right 
						  customSelector:(SEL) sel;
- (id) initWithLeftExpression:(NSExpression *) left rightExpression:(NSExpression *)right
					 modifier:(NSComparisonPredicateModifier) modifier 
						 type:(NSPredicateOperatorType) type 
					  options:(NSUInteger) opts;
- (NSExpression *) leftExpression;
- (NSUInteger) options;
- (NSPredicateOperatorType) predicateOperatorType;
- (NSExpression *) rightExpression;

@end