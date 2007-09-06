//
//  NSValueTransformer.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//  H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSValueTransformer
#define _mySTEP_H_NSValueTransformer

#import "Foundation/NSObject.h"

extern NSString *NSNegateBooleanTransformerName;
extern NSString *NSIsNilTransformerName;
extern NSString *NSIsNotNilTransformerName; 
extern NSString *NSUnarchiveFromDataTransformerName;

@class NSString;

@interface NSValueTransformer : NSObject

+ (BOOL) allowsReverseTransformation;
+ (void) setValueTransformer:(NSValueTransformer *) transformer forName:(NSString *) name;
+ (Class) transformedValueClass;
+ (NSValueTransformer *) valueTransformerForName:(NSString *) name;
+ (NSArray *) valueTransformerNames;

- (id) reverseTransformedValue:(id) value;
- (id) transformedValue:(id) value;

@end

// builtin transformers

@interface NSNegateBooleanTransformer : NSValueTransformer
@end

@interface NSIsNilTransformer : NSValueTransformer
@end

@interface NSIsNotNilTransformer : NSValueTransformer
@end

@interface NSUnarchiveFromDataTransformer : NSValueTransformer
@end

#endif /* _mySTEP_H_NSValueTransformer */
