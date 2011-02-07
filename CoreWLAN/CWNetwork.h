#import <Foundation/Foundation.h>

@class CWWirelessProfile;

@interface CWNetwork : NSObject <NSCopying, NSCoding>

- (BOOL) isEqualToNetwork:(CWNetwork *) network; 

// some of these are also available through CWInterface (so use subclassing/forwarding?)

- (NSString *) bssid;
- (NSData *) bssidData;
- (NSNumber *) channel;
- (NSData *) ieData;
- (BOOL) isIBSS;
- (NSNumber *) noise;
- (NSNumber *) phyMode;
- (NSNumber *) rssi;
- (NSNumber *) securityMode;
- (NSString *) ssid;
- (CWWirelessProfile *) irelessProfile;

@end