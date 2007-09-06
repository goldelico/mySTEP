//
//  ABMultiValue.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//
//	reviewed for 10.4 compatibility, Aug 2007
//
//  for documentation please refer to
//  http://developer.apple.com/documentation/UserExperience/Reference/AddressBook/Classes/ABAddressBook_Class/Reference/Reference.html
//

#import <AddressBook/ABTypedefs.h>

@interface ABMultiValue : NSObject <NSCopying, NSMutableCopying>
{
@public
	NSString *primaryIdentifier;
	NSMutableArray *values;
	NSMutableArray *labels;
	NSMutableArray *identifiers;
	ABPropertyType propertyType;
}

- (unsigned int) count;
- (id) valueAtIndex:(int) index;
- (NSString *) labelAtIndex:(int) index;
- (NSString *) identifierAtIndex:(int) index;
- (int) indexForIdentifier:(NSString *) identifier;
- (NSString *) primaryIdentifier;
- (ABPropertyType) propertyType;
@end

@interface ABMutableMultiValue : ABMultiValue
{
}

- (NSString *) addValue:(id) value withLabel:(NSString *) label;
- (NSString *) insertValue:(id) value withLabel:(NSString *) label atIndex:(int) index;
- (BOOL) removeValueAndLabelAtIndex:(int) index;
- (BOOL) replaceValueAtIndex:(int) index withValue:(id) value;
- (BOOL) replaceLabelAtIndex:(int) index withLabel:(NSString*) label;
- (BOOL) setPrimaryIdentifier:(NSString *) identifier;

@end
