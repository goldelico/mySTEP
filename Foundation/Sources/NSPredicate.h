//
//  NSPredicate.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Tue Dec 22 2005.
//  Copyright (c) 2005 DSITRI.
//
//	H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef mySTEP_NSPREDICATE_H
#define mySTEP_NSPREDICATE_H

#import "Foundation/NSObject.h"
#import "Foundation/NSArray.h"

@interface NSPredicate : NSObject <NSCoding, NSCopying>

+ (NSPredicate *) predicateWithFormat:(NSString *) format, ...;
+ (NSPredicate *) predicateWithFormat:(NSString *) format argumentArray:(NSArray *) args;
+ (NSPredicate *) predicateWithFormat:(NSString *) format arguments:(va_list) args;
+ (NSPredicate *) predicateWithValue:(BOOL) value;	// returns private subclass

- (BOOL) evaluateWithObject:(id) object;
- (BOOL) evaluateWithObject:(id) object substitutionVariables:(NSDictionary *) variables;
- (NSString *) predicateFormat;
- (NSPredicate *) predicateWithSubstitutionVariables:(NSDictionary *) variables;

@end

@interface NSArray (NSPredicate)
- (NSArray *) filteredArrayUsingPredicate:(NSPredicate *) predicate;
@end

@interface NSMutableArray (NSPredicate)
- (void) filterUsingPredicate:(NSPredicate *) predicate;
@end

@interface NSMutableSet
- (void) filterUsingPredicate:(NSPredicate *) predicate;
@end

#endif mySTEP_NSPREDICATE_H
