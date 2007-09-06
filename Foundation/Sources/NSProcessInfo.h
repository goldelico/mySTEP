/* 
   NSProcessInfo.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <farz@mindspring.com>
   Date:	January 1999
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSProcessInfo
#define _mySTEP_H_NSProcessInfo

#import <Foundation/NSObject.h>

@class NSArray;
@class NSMutableArray;
@class NSDictionary;
@class NSData;
@class NSString;

enum {
	NSHPUXOperatingSystem=1,
	NSMACHOperatingSystem,
	NSOSF1OperatingSystem,
	NSSolarisOperatingSystem,
	NSSunOSOperatingSystem,
	NSWindows95OperatingSystem,
	NSWindowsNTOperatingSystem,
	NSLinuxOperatingSystem=256
};


@interface NSProcessInfo : NSObject
{
	NSString *_hostName;   
	NSString *_processName;
	NSString *_operatingSystem;				
	NSDictionary *_environment;
	NSArray *_arguments;
	int _pid;
}

+ (NSProcessInfo*) processInfo;						// Shared NSProcessInfo

- (NSArray*) arguments;								// Access Process Info
- (NSDictionary*) environment;
- (NSString*) globallyUniqueString;
- (NSString*) hostName;
- (unsigned int) operatingSystem;
- (NSString*) operatingSystemName;
- (NSString *) operatingSystemVersionString;
- (int) processIdentifier;
- (NSString*) processName;
- (void) setProcessName:(NSString*)newName;			// Modify Process Name

@end

#endif /* _mySTEP_H_NSProcessInfo */
