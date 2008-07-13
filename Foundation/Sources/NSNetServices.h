/*
    NSNetServices.h
    mySTEP

    Created by Dr. H. Nikolaus Schaller on Sat Aug 20 2005.
    Copyright (c) 2005 DSITRI.

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5

    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef mySTEP_NSNETSERVICES_H
#define mySTEP_NSNETSERVICES_H

#import "Foundation/NSObject.h"
#import "Foundation/NSTimer.h"

@class NSString, NSArray, NSMutableArray, NSDictionary, NSData;
@class NSRunLoop;
@class NSInputStream, NSOutputStream;
@class NSSocketPort;

extern NSString *NSNetServicesErrorCode;
extern NSString *NSNetServicesErrorDomain;

enum
{
	NSNetServicesUnknownError		= -72000,
	NSNetServicesCollisionError		= -72001,
	NSNetServicesNotFoundError		= -72002,
	NSNetServicesActivityInProgress	= -72003,
	NSNetServicesBadArgumentError	= -72004,
	NSNetServicesCancelledError		= -72005,
	NSNetServicesInvalidError		= -72006,
	NSNetServicesTimeoutError		= -72007
};

enum {
	NSNetServiceNoAutoRename = 1 << 0
};
typedef NSUInteger NSNetServiceOptions;

@interface NSNetService : NSObject
{
	id _delegate;
	NSInputStream *_inputStream;
	NSOutputStream *_outputStream;
	NSMutableArray *_addresses;	// filled by resolver
	NSString *_hostName;		// filled by resolver
	NSString *_domain;
	NSString *_name;
	NSString *_type;
	NSData *_txt;
	NSTimer *_timer;
	int _port;
	BOOL _scheduled;
	BOOL _isMonitoring;
	BOOL _isPublishing;
}

+ (NSData *) dataFromTXTRecordDictionary:(NSDictionary *) txt;
+ (NSDictionary *) dictionaryFromTXTRecordData:(NSData *) txt;

- (NSArray *) addresses;
- (id) delegate;
- (NSString *) domain;
- (BOOL) getInputStream:(NSInputStream **) input outputStream:(NSOutputStream **) output;
- (NSString *) hostName;
- (id) initWithDomain:(NSString *) domain type:(NSString *) type name:(NSString *) name;
- (id) initWithDomain:(NSString *) domain type:(NSString *) type name:(NSString *) name port:(int) port;
- (NSString *) name;
- (NSString *) protocolSpecificInformation;	// depreaced
- (NSInteger) port;
- (void) publish;
- (void) publishWithOptions:(NSNetServiceOptions) opts;
- (void) removeFromRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
- (void) resolve;	// deprecated
- (void) resolveWithTimeout:(NSTimeInterval) interval;
- (void) scheduleInRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
- (void) setDelegate:(id) obj;
- (void) setProtocolSpecificInformation:(NSString *) info;	// deprecated
- (BOOL) setTXTRecordData:(NSData *) txt;
- (void) startMonitoring;
- (void) stop;
- (void) stopMonitoring;
- (NSString *) type;
- (NSData *) TXTRecordData;

@end

@interface NSObject (NSNetService)

- (void) netService:(NSNetService *) sender didNotPublish:(NSDictionary *) error;
- (void) netService:(NSNetService *) sender didNotResolve:(NSDictionary *) error;
- (void) netServiceDidPublish:(NSNetService *) sender;
- (void) netServiceDidResolveAddress:(NSNetService *) sender;
- (void) netServiceDidStop:(NSNetService *) sender;
- (void) netService:(NSNetService *)sender didUpdateTXTRecordData:(NSData *) txt;
- (void) netServiceWillPublish:(NSNetService *) sender;
- (void) netServiceWillResolve:(NSNetService *) sender;

@end

@interface NSNetServiceBrowser : NSObject
{
	id _delegate;
	NSNetService *_netService;
}

- (id) delegate;
- (id) init;
- (void) removeFromRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
- (void) scheduleInRunLoop:(NSRunLoop *) loop forMode:(NSString *) mode;
// - (void) searchForAllDomains; -- deprecated
- (void) searchForBrowsableDomains;
- (void) searchForRegistrationDomains;
- (void) searchForServicesOfType:(NSString *) type inDomain:(NSString *) domain;
- (void) setDelegate:(id) obj;
- (void) stop;

@end

@interface NSObject(NSNetServiceBrowser)

- (void) netServiceBrowser:(NSNetServiceBrowser *) browser didFindDomain:(NSString *) domain moreComing:(BOOL) more;
- (void) netServiceBrowser:(NSNetServiceBrowser *) browser didFindService:(NSNetService *) service moreComing:(BOOL) more;
- (void) netServiceBrowser:(NSNetServiceBrowser *) browser didNotSearch:(NSDictionary *) error;
- (void) netServiceBrowser:(NSNetServiceBrowser *) browser didRemoveDomain:(NSString *) domain moreComing:(BOOL) more;
- (void) netServiceBrowser:(NSNetServiceBrowser *) browser didRemoveService:(NSNetService *) domain moreComing:(BOOL) more;
- (void) netServiceBrowserDidStopSearch:(NSNetServiceBrowser *) browser;
- (void) netServiceBrowserWillSearch:(NSNetServiceBrowser *) browser;

@end

#endif mySTEP_NSNETSERVICES_H