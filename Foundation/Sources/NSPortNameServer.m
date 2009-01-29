/* 
   NSPortNameServer.m

   Interface to the port registration service used by the DO system.

   Copyright (C) 1998 Free Software Foundation, Inc.

   Author:	Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:	October 1998

   Author:	H. N. Schaller <hns@computer.org>
   Date:	June 2006
			reworked to be based on NSStream, NSMessagePort etc.
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#include <sys/types.h>
#include <sys/stat.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSByteOrder.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSData.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSSet.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSTimer.h>
#import <Foundation/NSPort.h>
#import <Foundation/NSPortNameServer.h>
#import <Foundation/NSHost.h>
#import <Foundation/NSBundle.h>

#import "NSPrivate.h"

@implementation NSPortNameServer

static NSPortNameServer *__systemDefaultPortNameServer;

+ (NSPortNameServer *) systemDefaultPortNameServer;
{
	if(!__systemDefaultPortNameServer)
		__systemDefaultPortNameServer=[self new];
	return __systemDefaultPortNameServer;
}

- (NSPort *) servicePortWithName:(NSString *) name;
{
	return [[[self class] systemDefaultPortNameServer] portForName:name];
}

- (NSPort *) portForName:(NSString *) portName; { return [self portForName:portName host:nil]; }

- (NSPort *) portForName:(NSString *) portName host:(NSString *) hostName;
{
	if([hostName length] != 0)
		return [[NSSocketPortNameServer sharedInstance] portForName:portName host:hostName];	// remote sould use NSSocketPort
	return [[NSMessagePortNameServer sharedInstance] portForName:portName host:nil];			// use MessagePort local by default
}

- (BOOL) registerPort:(NSPort *) port name:(NSString *) name;
{ // register locally and remote
	if([port isKindOfClass:[NSMessagePort class]])
		return [[NSMessagePortNameServer sharedInstance] registerPort:port name:name];
	else
		return [[NSSocketPortNameServer sharedInstance] registerPort:port name:name];
}

- (BOOL) removePortForName:(NSString *) name;
{
	return [[NSSocketPortNameServer sharedInstance] removePortForName:name];	// only socketport can unregister explicitly
}

@end

@implementation NSSocketPortNameServer

static NSSocketPortNameServer *defaultServer;

// implementation should be based on NSNetServices!

+ (id) sharedInstance
{
	if(!defaultServer)
		defaultServer=[self new];
	return defaultServer;
}

- (id) init;
{
	if((self=[super init]))
		{
		_publishedSocketPorts=[NSMutableDictionary new];
		}
	return self;
}

- (void) dealloc
{
	[NSException raise: NSGenericException
				 format: @"attempt to deallocate default port name server"]; 
	[_publishedSocketPorts release];
	[super dealloc];	// makes gcc not complain
}

- (unsigned short) defaultNameServerPortNumber; { return defaultNameServerPortNumber; }
- (void) setDefaultNameServerPortNumber:(unsigned short) portNumber; { defaultNameServerPortNumber=portNumber; }

- (NSPort *) portForName:(NSString *)name
{
	return [self portForName: name host: nil];
}

- (NSPort *) portForName:(NSString *)name host:(NSString *)host
{
	return [self portForName:name host:host nameServerPortNumber:0];
}

- (NSPort *) portForName:(NSString *)name host:(NSString *)host nameServerPortNumber:(unsigned short) portNumber;
{
	NSNetService *ns;
#if 0
	NSLog(@"NSSocketPortNameServer portForName:%@ host:%@ nameServerPortNumber:%u", name, host, portNumber);
#endif
	if(!host)
		host=@"local.";
	ns=[[[NSNetService alloc] initWithDomain:host type:@"_nssocketport._tcp." name:name] autorelease];
	[ns resolveWithTimeout:10.0];
	if([[ns addresses] count] == 0)
		return nil;	// not resolved
	// FIXME:
	return NIMP;
//	return [[[NSSocketPort alloc] initRemoteWithProtocolFamily:AF_INET socketType:(int)type protocol:(int)protocol address:[[ns addresses] lastObject]] autorelease];	// create socket that will connect to resolved service on first send request
}

- (BOOL) registerPort:(NSPort *)port name:(NSString *)name;
{
	return [self registerPort:port name:name nameServerPortNumber:0];
}

- (BOOL) registerPort:(NSPort *)port name:(NSString *)name nameServerPortNumber:(unsigned short) portNumber;
{
	NSNetService *s=[_publishedSocketPorts objectForKey:name];
#if 0
	NSLog(@"NSSocketPortNameServer registerPort:%@ name:%@ nameServerPortNumber:%u", port, name, portNumber);
#endif
	if(s)
		return NO;	// already known to be published
	s=[[[NSNetService alloc] initWithDomain:@"local." type:@"_nssocketport._tcp." name:name port:portNumber] autorelease];
	// [s setDelegate:self];
	if(!s)
		return NO;
	[s publish];		// publish through ZeroConf
	[_publishedSocketPorts setObject:s forKey:name];	// so that we can remove the port...
	return YES;
}

- (BOOL) removePortForName:(NSString *)name
{
	NSNetService *s=[_publishedSocketPorts objectForKey:name];
	if(!s)
		return NO;	// wasn't published before
	[s stop];	// stop publishing
	[_publishedSocketPorts removeObjectForKey:name];	// will release
	return YES;
}

- (void) _removePort:(NSPort *)port
{ // Remove all names for a particular port.  Called when a port is invalidated.
	NIMP;
}

@end /* NSPortNameServer (Private) */

@implementation NSMessagePortNameServer

static NSMessagePortNameServer *__sharedNSMessagePortNameServer;

+ (id) sharedInstance;
{
	if(!__sharedNSMessagePortNameServer)
		__sharedNSMessagePortNameServer=[self new];
	return __sharedNSMessagePortNameServer;
}

- (NSPort *) portForName:(NSString *) portName; { return [self portForName:portName host:nil]; }

- (NSPort *) portForName:(NSString *) portName host:(NSString *) hostName;
{ // get named socket through alias
#if 0
	NSLog(@"NSMessagePortNameServer portForName:%@ host:%@", portName, hostName);
#endif	  
	if([hostName length] != 0)
		return nil; // host name must be nil or empty!
	return [[[NSMessagePort alloc] _initRemoteWithName:portName] autorelease];	// connect to AF_UNIX file
}

- (BOOL) registerPort:(NSPort *) port name:(NSString *) name;
{ // make a named alias for the port (named FIFO)
	if(![port isKindOfClass:[NSMessagePort class]])
		return NO;	// not a message port
	[(NSMessagePort *) port _setName:name];	// substitute public name
	// we might have to move in cache!
	[(NSMessagePort *) port _unlink];		// remove existing socket
	return [port _bindAndListen];			// create socket and start listening (if scheduled)
}

- (BOOL) removePortForName:(NSString *) name;
{ // remove name
	NSPort *port=nil;	// how do we get the port for this name?
	[(NSMessagePort *) port _setName:name];	// substitute public name
	return [(NSMessagePort *) port _unlink];
}

@end
