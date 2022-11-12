//
//  CWWiFiClient.h
//  CoreWLAN
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <CoreWLAN/CoreWLANTypes.h>
#import <CoreWLAN/CWEventDelegate.h>

@interface CWWiFiClient : NSObject
{
	id <CWEventDelegate> _delegate;
}
+ (CWWiFiClient *) sharedWiFiClient;
+ (NSArray *) interfaceNames;

- (id) init;
- (id) delegate;
- (void) setDelegate:(id) delegate;
- (CWInterface *) interface;
- (CWInterface *) interfaceWithName:(NSString *) name;
- (NSArray *) interfaces;

/* 10.10 */
- (BOOL) startMonitoringEventWithType:(CWEventType) type error:(NSError **) error;
- (BOOL) stopMonitoringAllEventsAndReturnError:(NSError **) error;
- (BOOL) stopMonitoringEventWithType:(CWEventType) type error:(NSError **) error;

@end
