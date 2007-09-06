//
//  ABGroup.m
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Aug 18 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <AddressBook/AddressBook.h>

// properties

NSString *kABUIDProperty=@"UIDProperty";
NSString *kABCreationDateProperty=@"CreationDateProperty";
NSString *kABModificationDateProperty=@"ModificationDateProperty";
NSString *kABFirstNameProperty=@"FirstNameProperty";
NSString *kABLastNameProperty=@"LastNameProperty";
NSString *kABFirstNamePhoneticProperty=@"FirstNamePhoneticProperty";
NSString *kABLastNamePhoneticProperty=@"LastNamePhoneticProperty";
NSString *kABBirthdayProperty=@"BirthdayProperty";
NSString *kABOrganizationProperty=@"OrganizationProperty";
NSString *kABJobTitleProperty=@"JobTitleProperty";
NSString *kABHomePageProperty=@"HomePageProperty";
NSString *kABEmailProperty=@"EmailProperty";
NSString *kABAddressProperty=@"AddressProperty";
NSString *kABPhoneProperty=@"PhoneProperty";
NSString *kABAIMInstantProperty=@"AIMInstantProperty";
NSString *kABJabberInstantProperty=@"JabberInstantProperty";
NSString *kABMSNInstantProperty=@"MSNInstantProperty";
NSString *kABYahooInstantProperty=@"YahooInstantProperty";
NSString *kABICQInstantProperty=@"ICQInstantProperty";
NSString *kABNoteProperty=@"NoteProperty";
NSString *kABMiddleNameProperty=@"MiddleNameProperty";
NSString *kABMiddleNamePhoneticProperty=@"MiddleNamePhoneticProperty";
NSString *kABTitleProperty=@"TitleProperty";
NSString *kABSuffixProperty=@"SuffixProperty";
NSString *kABNicknameProperty=@"NicknameProperty";
NSString *kABMaidenNameProperty=@"MaidenNameProperty";
NSString *kABOtherDatesProperty=@"OtherDatesProperty";
NSString *kABRelatedNamesProperty=@"RelatedNamesProperty";
NSString *kABDepartmentProperty=@"DepartmentProperty";

NSString *kABPersonFlags=@"PersonFlags";

NSString *kABGroupNameProperty=@"GroupNameProperty";

// keys

NSString *kABAddressStreetKey=@"AddressStreetKey";
NSString *kABAddressCityKey=@"AddressCityKey";
NSString *kABAddressStateKey=@"AddressStateKey";
NSString *kABAddressZIPKey=@"AddressZIPKey";
NSString *kABAddressCountryKey=@"AddressCountryKey";
NSString *kABAddressCountryCodeKey=@"AddressCountryCodeKey";

// labels

NSString *kABEmailWorkLabel=@"EmailWorkLabel";
NSString *kABEmailHomeLabel=@"EmailHomeLabel";
NSString *kABAddressHomeLabel=@"AddressHomeLabel";
NSString *kABAddressWorkLabel=@"AddressWorkLabel";
NSString *kABPhoneWorkLabel=@"PhoneWorkLabel";
NSString *kABPhoneHomeLabel=@"PhoneHomeLabel";
NSString *kABPhoneMobileLabel=@"PhoneMobileLabel";
NSString *kABPhoneMainLabel=@"PhoneMainLabel";
NSString *kABPhoneHomeFAXLabel=@"PhoneHomeFAXLabel";
NSString *kABPhoneWorkFAXLabel=@"PhoneWorkFAXLabel";
NSString *kABPhonePagerLabel=@"PhonePagerLabel";
NSString *kABAIMWorkLabel=@"AIMWorkLabel";
NSString *kABAIMHomeLabel=@"AIMHomeLabel";
NSString *kABJabberWorkLabel=@"JabberWorkLabel";
NSString *kABJabberHomeLabel=@"JabberHomeLabel";
NSString *kABMSNWorkLabel=@"MSNWorkLabel";
NSString *kABMSNHomeLabel=@"MSNHomeLabel";
NSString *kABYahooWorkLabel=@"YahooWorkLabel";
NSString *kABYahooHomeLabel=@"YahooHomeLabel";
NSString *kABICQWorkLabel=@"ICQWorkLabel";
NSString *kABICQHomeLabel=@"ICQHomeLabel";
NSString *kABAnniversaryLabel=@"AnniversaryLabel";
NSString *kABWorkLabel=@"WorkLabel";
NSString *kABHomeLabel=@"HomeLabel";
NSString *kABOtherLabel=@"OtherLabel";

// notifications

NSString *kABDatabaseChangedNotification=@"DatabaseChangedNotification";
NSString *kABDatabaseChangedExternallyNotification=@"DatabaseChangedExternallyNotification";

NSString *ABLocalizedPropertyOrLabel(NSString *propertyOrLabel)
{
	return propertyOrLabel; // should access localization dictionary
}
