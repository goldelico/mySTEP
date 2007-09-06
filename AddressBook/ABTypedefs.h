//
//  ABTypedefs.h
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

#import <Foundation/Foundation.h>

// data types

typedef enum
{ // note: these values be passed as NSNumber values of a NSDictionary to addPropertiesAndTypes:
	kABMultiValueMask=0x100,
	kABErrorInProperty=0,
	kABStringProperty,
	kABIntegerProperty,
	kABRealProperty,
	kABDateProperty,
	kABArrayProperty,
	kABDictionaryProperty,
	kABDataProperty,		// 7
	kABMultiStringProperty       = kABMultiValueMask | kABStringProperty,
	kABMultiIntegerProperty      = kABMultiValueMask | kABIntegerProperty,
	kABMultiRealProperty         = kABMultiValueMask | kABRealProperty,
	kABMultiDateProperty         = kABMultiValueMask | kABDateProperty,
	kABMultiArrayProperty        = kABMultiValueMask | kABArrayProperty,
	kABMultiDictionaryProperty   = kABMultiValueMask | kABDictionaryProperty,
	kABMultiDataProperty         = kABMultiValueMask | kABDataProperty
} ABPropertyType;

typedef enum {
	kABSearchAnd,
    kABSearchOr
} ABSearchConjunction;

typedef enum {
	kABEqual,
	kABNotEqual,
	kABLessThan,
	kABLessThanOrEqual,
	kABGreaterThan,
	kABGreaterThanOrEqual,
	kABEqualCaseInsensitive,
	kABContainsSubString,
	kABContainsSubStringCaseInsensitive,
	kABPrefixMatch,
	kABPrefixMatchCaseInsensitive,
	kABBitsInBitFieldMatch,
	kABDoesNotContainSubString,
	kABDoesNotContainSubStringCaseInsensitive,
	kABNotEqualCaseInsensitive,
	kABSuffixMatch,
	kABSuffixMatchCaseInsensitive,
	kABWithinIntervalAroundToday,
	kABWithinIntervalAroundTodayYearless,
	kABNotWithinIntervalAroundToday,
	kABNotWithinIntervalAroundTodayYearless,
	kABWithinIntervalFromToday,
	kABWithinIntervalFromTodayYearless,
	kABNotWithinIntervalFromToday,
	kABNotWithinIntervalFromTodayYearless
} ABSearchComparison;
