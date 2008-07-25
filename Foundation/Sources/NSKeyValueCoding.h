/*
    NSKeyValueCoding.h
    mySTEP
 
    Created by Dr. H. Nikolaus Schaller on Tue Oct 05 2004.
    Copyright (c) 2004 DSITRI.

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
    Defines only methods that are not deprecated or announced to be deprecated

    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSKEYVALUECODING_H
#define mySTEP_NSKEYVALUECODING_H

#import <Foundation/Foundation.h>

extern NSString *NSUndefinedKeyException;

extern NSString *NSAverageKeyValueOperator;
extern NSString *NSCountKeyValueOperator;
extern NSString *NSDistinctUnionOfArraysKeyValueOperator;
extern NSString *NSDistinctUnionOfObjectsKeyValueOperator;
extern NSString *NSDistinctUnionOfSetsKeyValueOperator;
extern NSString *NSMaximumKeyValueOperator;
extern NSString *NSMinimumKeyValueOperator;
extern NSString *NSSumKeyValueOperator;
extern NSString *NSUnionOfArraysKeyValueOperator;
extern NSString *NSUnionOfObjectsKeyValueOperator;
extern NSString *NSUnionOfSetsKeyValueOperator;

@class NSMutableSet;

@interface NSObject (NSKeyValueCoding)

+ (BOOL) accessInstanceVariablesDirectly;

- (NSDictionary *) dictionaryWithValuesForKeys:(NSArray *) strings;
- (NSMutableArray *) mutableArrayValueForKey:(NSString *) str;
- (NSMutableArray *) mutableArrayValueForKeyPath:(NSString *) str;
- (NSMutableSet *) mutableSetValueForKey:(NSString *) key;
- (NSMutableSet *) mutableSetValueForKeyPath:(NSString *) keyPath;
- (void) setNilValueForKey:(NSString *) str;
- (void) setValue:(id) val forKey:(NSString *) str;
- (void) setValue:(id) val forKeyPath:(NSString *) str;
- (void) setValue:(id) val forUndefinedKey:(NSString *) str;
- (void) setValuesForKeysWithDictionary:(NSDictionary *) values;
- (BOOL) validateValue:(id *) val forKey:(NSString *) str error:(NSError **) error;
- (BOOL) validateValue:(id *) val forKeyPath:(NSString *) str error:(NSError **) error;
- (id) valueForKey:(NSString *) str;
- (id) valueForKeyPath:(NSString *) str;
- (id) valueForUndefinedKey:(NSString *) str;

@end

#endif mySTEP_NSKEYVALUECODING_H
