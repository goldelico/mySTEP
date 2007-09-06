//
//  ABAddressBook.h
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
#import <AddressBook/ABGlobals.h>
#import <AddressBook/ABPerson.h>
#import <AddressBook/ABRecord.h>
#import <AddressBook/ABSearchElement.h>

@interface ABAddressBook : NSObject {
	BOOL hasUnsavedChanges;
	NSMutableDictionary *properties;	// ABGroup and ABPerson properties
	NSString *ich;						// uniqueID of me-record
	NSMutableArray *groups;
	NSMutableArray *persons;
}

+ (ABAddressBook *) sharedAddressBook;
- (BOOL) addRecord:(ABRecord *) record;
- (NSString *) defaultCountryCode;
- (int) defaultNameOrdering;
- (NSAttributedString *) formattedAddressFromDictionary:(NSDictionary *) addr;
- (NSArray *) groups;
- (BOOL) hasUnsavedChanges;
- (ABPerson *) me;
- (NSArray *) people;
- (NSString *) recordClassFromUniqueId:(NSString *) uid;
- (ABRecord *) recordForUniqueId:(NSString *) uniqueId;
- (NSArray *) recordsMatchingSearchElement:(ABSearchElement *) search;
- (BOOL) removeRecord:(ABRecord *) record;
- (BOOL) save;
- (void) setMe:(ABPerson *) ich;

@end

@interface ABAddressBook (UndocumentedPrivateExtensions)
+ (id) _getUniqueId;	// create new unique-ID
- (void) _touch;
- (void) _touch:(NSString *) uid inserted:(BOOL) flag deleted:(BOOL) flag;	// collect unique-IDs and create notification(s)
@end