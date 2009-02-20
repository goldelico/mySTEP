//
//  ABGlobals.h
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

// Properties

extern NSString *kABUIDProperty;
extern NSString *kABCreationDateProperty;
extern NSString *kABModificationDateProperty;
extern NSString *kABFirstNameProperty;
extern NSString *kABLastNameProperty;
extern NSString *kABFirstNamePhoneticProperty;
extern NSString *kABLastNamePhoneticProperty;
extern NSString *kABBirthdayProperty;
extern NSString *kABOrganizationProperty;
extern NSString *kABJobTitleProperty;
extern NSString *kABHomePageProperty;	// deprecated in 10.4
extern NSString *kABURLsProperty;
extern NSString *kABEmailProperty;
extern NSString *kABAddressProperty;
extern NSString *kABPhoneProperty;
extern NSString *kABAIMInstantProperty;
extern NSString *kABJabberInstantProperty;
extern NSString *kABMSNInstantProperty;
extern NSString *kABYahooInstantProperty;
extern NSString *kABICQInstantProperty;
extern NSString *kABNoteProperty;
extern NSString *kABMiddleNameProperty;
extern NSString *kABMiddleNamePhoneticProperty;
extern NSString *kABTitleProperty;
extern NSString *kABSuffixProperty;
extern NSString *kABNicknameProperty;
extern NSString *kABMaidenNameProperty;
extern NSString *kABOtherDatesProperty;
extern NSString *kABRelatedNamesProperty;
extern NSString *kABDepartmentProperty;

extern NSString *kABPersonFlags;

enum {
	kABShowAsPerson=0,			// default
	kABShowAsCompany=1,			// advanced
	kABShowAsMask=0x07,			// 8 values reserved
	kABDefaultNameOrdering=0,   // use default
	kABFirstNameFirst=0x20,		// enforce ordering
	kABLastNameFirst=0x10,		// enforce ordering
	kABNameOrderingMask=0x38	// 8 values reserved
};

extern NSString *kABGroupNameProperty;

// Keys for address dictionary

extern NSString *kABAddressStreetKey;
extern NSString *kABAddressCityKey;
extern NSString *kABAddressStateKey;
extern NSString *kABAddressZIPKey;
extern NSString *kABAddressCountryKey;
extern NSString *kABAddressCountryCodeKey;

// Labels

extern NSString *kABEmailWorkLabel;
extern NSString *kABEmailHomeLabel;
extern NSString *kABAddressHomeLabel;
extern NSString *kABAddressWorkLabel;
extern NSString *kABPhoneWorkLabel;
extern NSString *kABPhoneHomeLabel;
extern NSString *kABPhoneMobileLabel;
extern NSString *kABPhoneMainLabel;
extern NSString *kABPhoneHomeFAXLabel;
extern NSString *kABPhoneWorkFAXLabel;
extern NSString *kABPhonePagerLabel;
extern NSString *kABHomePageLabel;
extern NSString *kABAIMWorkLabel;
extern NSString *kABAIMHomeLabel;
extern NSString *kABJabberWorkLabel;
extern NSString *kABJabberHomeLabel;
extern NSString *kABMSNWorkLabel;
extern NSString *kABMSNHomeLabel;
extern NSString *kABYahooWorkLabel;
extern NSString *kABYahooHomeLabel;
extern NSString *kABICQWorkLabel;
extern NSString *kABICQHomeLabel;
extern NSString *kABAnniversaryLabel;
// mother etc.
extern NSString *kABFriendLabel;
extern NSString *kABSpouseLabel;
extern NSString *kABPartnerLabel;
extern NSString *kABAssistantLabel;
extern NSString *kABManagerLabel;

// generic Multi-Labels

extern NSString *kABWorkLabel;
extern NSString *kABHomeLabel;
extern NSString *kABOtherLabel;

// Notifications
// userInfo=(kABSenderProcessID, kABUserUID, kABInsertedRecords, kABUpdatedRecords, and kABDeletedRecords)

extern NSString *kABDatabaseChangedNotification;
extern NSString *kABDatabaseChangedExternallyNotification;

// Localized strings

NSString *ABLocalizedPropertyOrLabel(NSString *propertyOrLabel);

// EOF
