//
//  CoreWLANConstants.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSString;

extern NSString * const kCWAssocKey8021XProfile;
extern NSString * const kCWAssocKeyPassphrase;
extern NSString * const kCWBSSIDDidChangeNotification;
extern NSString * const kCWCountryCodeDidChangeNotification;
extern NSString * const kCWErrorDomain;
extern NSString * const kCWIBSSKeyChannel;
extern NSString * const kCWIBSSKeyPassphrase;
extern NSString * const kCWIBSSKeySSID;
extern NSString * const kCWLinkDidChangeNotification;
extern NSString * const kCWModeDidChangeNotification;
extern NSString * const kCWPowerDidChangeNotification;
extern NSString * const kCWScanKeyBSSID;
extern NSString * const kCWScanKeyDwellTime;
extern NSString * const kCWScanKeyMerge;
extern NSString * const kCWScanKeyRestTime;
extern NSString * const kCWScanKeyScanType;
extern NSString * const kCWScanKeySSID;
extern NSString * const kCWSSIDDidChangeNotification;

#define CWErrorDomain kCWErrorDomain
#define CWGenericErrorDomain kCWGenericErrorDomain
#define CWServiceDidChangeNotification kCWServiceDidChangeNotification

#if 1	// deprecated
#define CWBSSIDDidChangeNotification kCWBSSIDDidChangeNotification
#define CWCountryCodeDidChangeNotification kCWCountryCodeDidChangeNotification
#define CWLinkDidChangeNotification kCWLinkDidChangeNotification
#define CWLinkQualityDidChangeNotification kCWLinkQualityDidChangeNotification
#define CWLinkQualityNotificationRSSKey kCWLinkQualityNotificationRSSKey
#define CWLinkQualityNotificationTransmitRateKey kCWLinkQualityNotificationTransmitRateKey
#define CWModeDidChangeNotification kCWModeDidChangeNotification
#define CWPowerDidChangeNotification kCWPowerDidChangeNotification
#define CWScanCacheDidChangeNotification kCWScanCacheDidChangeNotification
#define CWSSIDDidChangeNotification kCWSSIDDidChangeNotification
#endif
