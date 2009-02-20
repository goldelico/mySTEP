//
//  ABGroup.h
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

#import <AddressBook/ABRecord.h>
#import <AddressBook/ABSearchElement.h>
#import <AddressBook/ABGlobals.h>

@interface ABGroup : ABRecord
{
	NSMutableArray *parentgroups;
	NSMutableArray *members;
	NSMutableArray *subgroups;
}

- (BOOL) addMember:(ABPerson *) person;
- (BOOL) addSubgroup:(ABGroup *) group;
- (NSString*) distributionIdentifierForProperty:(NSString *) property person:(ABPerson *) person;
- (NSArray *) members;
- (NSArray *) parentGroups;
- (BOOL) removeMember:(ABPerson *) person;
- (BOOL) removeSubgroup:(ABGroup *) group;
- (BOOL) setDistributionIdentifier:(NSString *) identifier forProperty:(NSString *) property person:(ABPerson *) person;
- (NSArray *) subgroups;

@end

@interface ABGroup(Properties)
+ (int) addPropertiesAndTypes:(NSDictionary *) properties;
+ (NSArray *) properties;
+ (int) removeProperties:(NSArray *) properties;
// + (ABSearchElement *) searchElementForProperty:(NSString*) property label:(NSString*) label key:(NSString*) key value:(id) value comparison:(ABSearchComparison) comparison;
+ (ABPropertyType) typeOfProperty:(NSString*) property;
@end
