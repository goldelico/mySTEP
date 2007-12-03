//
//  NSPredicateEditorRowTemplate.h
//  AppKit
//
//  Created by Fabian Spillner on 03.12.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSPredicate; 

@interface NSPredicateEditorRowTemplate : NSObject {

}

+ (NSArray *) templatesWithAttributeKeyPaths:(NSArray *) paths inEntityDescription:(NSEntityDescription *) entityDesc; 

- (NSArray *) compoundTypes; 
- (NSArray *) displayableSubpredicatesOfPredicate:(NSPredicate *) pred; 
- (id) initWithCompoundTypes:(NSArray *) types; 
- (id) initWithLeftExpressions:(NSArray *) leftExprs 
  rightExpressionAttributeType:(NSAttributeType) attrType 
					  modifier:(NSComparisonPredicateModifier) modif 
					 operators:(NSArray *) ops 
					   options:(NSUInteger) opts; 
- (id) initWithLeftExpressions:(NSArray *) leftExprs 
			  rightExpressions:(NSArray *) rightExprs 
					  modifier:(NSComparisonPredicateModifier) modif 
					 operators:(NSArray *) ops 
					   options:(NSUInteger) opts; 
- (NSArray *) leftExpressions; 
- (double) matchForPredicate:(NSPredicate *) pred; 
- (NSComparisonPredicateModifier) modifier; 
- (NSArray *) operators; 
- (NSUInteger) options; 
- (NSPredicate *) predicateWithSubpredicates:(NSArray *) subpred; 
- (NSAttributeType) rightExpressionAttributeType; 
- (NSArray *) rightExpressions; 
- (void) setPredicate:(NSPredicate *) pred; 
- (NSArray *) templateViews; 

@end
