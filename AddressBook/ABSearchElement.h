//
//  ABSearchElement.h
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

@class ABRecord;

@interface ABSearchElement : NSObject
{
	ABSearchComparison _comparison;
	NSString *_property;
	NSString *_label;
	NSString *_key;
	id _value;
	Class _class;
	ABSearchConjunction _conjunction;
	NSArray *_children;  // if not nil - conjunction
}

+ (ABSearchElement *) _searchElementForClass:(Class) cls property:(NSString*) property label:(NSString*) label key:(NSString*) key value:(id) value comparison:(ABSearchComparison) comparison; 
+ (ABSearchElement *) searchElementForConjunction:(ABSearchConjunction) conjuction children:(NSArray *) children;
- (BOOL) matchesRecord:(ABRecord *) record;

@end

@interface _ABSearchConjunction : ABSearchElement
{
//	ABSearchConjunction conjunction;
//	NSArray *children;  // if not nil - conjunction
}

+ (ABSearchElement *) searchElementForConjunction:(ABSearchConjunction) conjuction children:(NSArray *) children;

@end
