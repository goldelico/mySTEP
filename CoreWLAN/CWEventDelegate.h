//
//  CWEventDelegate.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CWEventDelegate

- (void) bssidDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) clientConnectionInterrupted;
- (void) clientConnectionInvalidated;
- (void) countryCodeDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) linkDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) linkQualityDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName rssi:(NSInteger) rssi transmitRate:(double) transmitRate;
- (void) modeDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) powerStateDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) scanCacheUpdatedForWiFiInterfaceWithName:(NSString *) interfaceName;
- (void) ssidDidChangeForWiFiInterfaceWithName:(NSString *) interfaceName;

@end
