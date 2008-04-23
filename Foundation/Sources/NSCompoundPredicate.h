/*
    NSCompoundPredicate.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
    Copyright (c) 2005 DSITRI.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	22. April 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSPredicate.h>

typedef enum _NSCompoundPredicateType
{
	NSNotPredicateType = 0,
	NSAndPredicateType,
	NSOrPredicateType
} NSCompoundPredicateType;

@interface NSCompoundPredicate : NSPredicate

+ (NSPredicate *) andPredicateWithSubpredicates:(NSArray *) list;
+ (NSPredicate *) notPredicateWithSubpredicate:(NSPredicate *) predicate;
+ (NSPredicate *) orPredicateWithSubpredicates:(NSArray *) list;

- (NSCompoundPredicateType) compoundPredicateType;
- (id) initWithType:(NSCompoundPredicateType) type subpredicates:(NSArray *) list;
- (NSArray *) subpredicates;

@end