//
//  ABRecord.h
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

@class ABSearchElement;

@interface ABRecord : NSObject <NSCoding> {
	NSMutableDictionary *data;  // property data
}

- (BOOL) isReadOnly;
- (id) valueForProperty:(NSString *) property;
- (BOOL) setValue:(id) value forProperty:(NSString *) property;
- (BOOL) removeValueForProperty:(NSString *) property;
- (NSString *) uniqueId;

@end

@interface ABRecord (SubclassSupport)
+ (ABSearchElement *) searchElementForProperty:(NSString *) property label:(NSString *) label key:(NSString *) key value:(id) value comparison:(ABSearchComparison) comparison;
+ (id) builtInProperties;
- (id) initWithUniqueId:(NSString *) str;
- (void) setNilValueForKey:(NSString *) key;
@end