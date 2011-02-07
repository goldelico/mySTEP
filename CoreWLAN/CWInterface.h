#import <Foundation/Foundation.h>

@class CWConfiguration;
@class CWNetwork;
@class SFAuthorization;

@interface CWInterface : NSObject

- (BOOL) associateToNetwork:(CWNetwork *) network parameters:(NSDictionary *) params error:(NSError **) err;
- (BOOL) commitConfiguration:(CWConfiguration *) config error:(NSError **) err;
- (void) disassociate;
- (BOOL) enableIBSSWithParameters:(NSDictionary *) params; 
- (CWInterface *) init;
- (CWInterface *) initWithInterfaceName:(NSString *) name;
+ (CWInterface *) interface;
+ (CWInterface *) interfaceWithName:(NSString *) name;
- (BOOL) isEqualToInterface:(CWInterface*)interface;
- (NSArray *) scanForNetworksWithParameters:(NSDictionary*) params error:(NSError **) err;
- (BOOL) setChannel:(NSUInteger) channel error:(NSError **) err;
- (BOOL) setPower:(BOOL) power error:(NSError **) err;
+ (NSArray *) supportedInterfaces;

// ... properties

@end