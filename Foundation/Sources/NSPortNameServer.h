/* 
    NSPortNameServer.h

    Interface to the port registration service used by the DO system.

    Copyright (C) 1998 Free Software Foundation, Inc.

    Author:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
    Date:	October 1998

    H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
    Fabian Spillner, July 2008 - API revised to be compatible to 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSPortNameServer
#define _mySTEP_H_NSPortNameServer

#import <Foundation/NSObject.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSStream.h>

@class NSPort;
@class NSString;
@class NSMutableData;

@interface NSPortNameServer : NSObject

+ (NSPortNameServer *) systemDefaultPortNameServer;

- (NSPort *) portForName:(NSString *) name;
- (NSPort *) portForName:(NSString *) name host:(NSString *) host;	// use the most appropriate subclass (local/remote)
- (BOOL) registerPort:(NSPort *) port name:(NSString *) name;
- (BOOL) removePortForName:(NSString *) name;
- (NSPort *) servicePortWithName:(NSString *) name;

@end

@interface NSSocketPortNameServer : NSPortNameServer	// implemented using NSNetService
{
	unsigned short defaultNameServerPortNumber;
	NSMutableDictionary *_publishedSocketPorts;	// list of published NSNetService objects
}

+ (id) sharedInstance;

- (unsigned short) defaultNameServerPortNumber;
- (NSPort *) portForName:(NSString *) name;
- (NSPort *) portForName:(NSString *) name host:(NSString *) host;
- (NSPort *) portForName:(NSString *) name host:(NSString *) host nameServerPortNumber:(unsigned short) portNumber;
- (BOOL) registerPort:(NSPort *) port name:(NSString *) name;
- (BOOL) registerPort:(NSPort *) port name:(NSString *) name nameServerPortNumber:(unsigned short) portNumber;
- (BOOL) removePortForName:(NSString *) name;
- (void) setDefaultNameServerPortNumber:(unsigned short) portNumber;

@end

@interface NSMessagePortNameServer : NSPortNameServer	// message ports are mapped through a shared database file

+ (id) sharedInstance;

- (NSPort *) portForName:(NSString *) portName;
- (NSPort *) portForName:(NSString *) portName host:(NSString *) hostName;	// host must be nil or empty
- (BOOL) registerPort:(NSPort *) port name:(NSString *) name;
- (BOOL) removePortForName:(NSString *) name;	// can't unregister

@end

#endif /* _mySTEP_H_NSPortNameServer */
