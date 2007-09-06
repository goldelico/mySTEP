//
//  ABPerson.h
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
#import <AddressBook/ABImageLoading.h>

@interface ABPerson : ABRecord <ABImageClient>
{
	NSMutableArray *parentgroups;
}

+ (void) cancelLoadingImageDataForTag:(int) tag;

- (int) beginLoadingImageDataForClient:(id <ABImageClient>) client;
- (NSData *) imageData;
- (id) initWithVCardRepresentation:(NSData *) vCardData;
- (NSArray *) parentGroups;
- (BOOL) setImageData:(NSData *) data;
- (NSData *) vCardRepresentation;

@end

@interface ABPerson(Undocumented)
- (id) initWithUniqueId:(id) uniqueId;
@end

@interface ABPerson(Properties)
+ (int) addPropertiesAndTypes:(NSDictionary *) properties;
+ (NSArray *) properties;
+ (int) removeProperties:(NSArray *) properties;
// + (ABSearchElement *) searchElementForProperty:(NSString *) property label:(NSString *) label key:(NSString *) key value:(id) value comparison:(ABSearchComparison) comparison;
+ (ABPropertyType) typeOfProperty:(NSString*) property;
@end
