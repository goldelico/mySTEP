//
//  CoreWLANUtil.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __linux__
typedef NSInteger OSStatus;
#endif

extern OSStatus CWKeychainCopyEAPIdentityList(NSArray *list);
extern NSSet *CWMergeNetworks(NSSet *networks);
