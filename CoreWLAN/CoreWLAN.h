//
//  CoreWLAN.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifdef __linux
// missing on our Foundation
#define NSOrderedSet NSSet
#define isEqualToOrderedSet isEqualToSet
#define NSSecureCoding NSCoding
#define SecIdentityRef void *
#endif

#import <CoreWLAN/CoreWLANConstants.h>
#import <CoreWLAN/CoreWLANTypes.h>
#import <CoreWLAN/CoreWLANUtil.h>
#import <CoreWLAN/CW8021XProfile.h>
#import <CoreWLAN/CWChannel.h>
#import <CoreWLAN/CWConfiguration.h>
#import <CoreWLAN/CWInterface.h>
#import <CoreWLAN/CWNetwork.h>
#import <CoreWLAN/CWNetworkProfile.h>
#import <CoreWLAN/CWWiFiClient.h>
