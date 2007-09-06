//
//  NSValueTransformer.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#import "Foundation/Foundation.h"

@implementation NSValueTransformer

NSString *NSNegateBooleanTransformerName=@"NSNegateBooleanTransformerName";
NSString *NSIsNilTransformerName=@"NSIsNilTransformerName";
NSString *NSIsNotNilTransformerName=@"NSIsNotNilTransformerName"; 
NSString *NSUnarchiveFromDataTransformerName=@"NSUnarchiveFromDataTransformerName";

// non-abstract methods

static NSMutableDictionary *names;

+ (void) setValueTransformer:(NSValueTransformer *) transformer
					 forName:(NSString *) name;
{
	if(!names)
		[self valueTransformerNames];	// allocate if needed
	[names setObject:transformer forKey:name];
}

+ (NSValueTransformer *) valueTransformerForName:(NSString *) name;
{
	return [names objectForKey:name];
}

+ (NSArray *) valueTransformerNames;
{
	if(!names)
		names=[[NSMutableDictionary alloc] init];
	return [names allKeys];
}

// abstract methods (must be implemented in subclasses)

+ (BOOL) allowsReverseTransformation; { SUBCLASS; return NO; }
+ (Class) transformedValueClass; { return SUBCLASS; }
- (id) reverseTransformedValue:(id) value; { return SUBCLASS; }
- (id) transformedValue:(id) value; { return SUBCLASS; }

@end

// builtin transformers

@implementation NSNegateBooleanTransformer

+ (BOOL) allowsReverseTransformation; { return YES; }
+ (Class) transformedValueClass; { return [NSNumber class]; }
- (id) reverseTransformedValue:(id) value; { return [NSNumber numberWithBool:![value boolValue]]; }
- (id) transformedValue:(id) value; { return [NSNumber numberWithBool:![value boolValue]]; }

@end

@implementation NSIsNilTransformer

+ (BOOL) allowsReverseTransformation; { return NO; }
+ (Class) transformedValueClass; { return [NSNumber class]; }
- (id) reverseTransformedValue:(id) value; { return NIMP; }
- (id) transformedValue:(id) value; { return [NSNumber numberWithBool:(value == nil)]; }

@end

@implementation NSIsNotNilTransformer

+ (BOOL) allowsReverseTransformation; { return NO; }
+ (Class) transformedValueClass; { return [NSNumber class]; }
- (id) reverseTransformedValue:(id) value; { return NIMP; }
- (id) transformedValue:(id) value; { return [NSNumber numberWithBool:(value != nil)]; }

@end

@implementation NSUnarchiveFromDataTransformer

+ (BOOL) allowsReverseTransformation; { return YES; }
+ (Class) transformedValueClass; { return [NSData class]; }
- (id) reverseTransformedValue:(id) value; { return NIMP; }
- (id) transformedValue:(id) value; { return NIMP; }

@end