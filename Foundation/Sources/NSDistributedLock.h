/* 
   NSDistributedLock.h

   Restrict access to resources shared by multiple apps.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:    1997

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSDistributedLock
#define _mySTEP_H_NSDistributedLock

#import <Foundation/NSObject.h>

@class NSString;
@class NSDate;

@interface NSDistributedLock : NSObject
{
    NSString *_lockPath;
    NSDate *_lockTime;
}

+ (NSDistributedLock*) lockWithPath:(NSString*)aPath;

- (void) breakLock;
- (NSDistributedLock*) initWithPath:(NSString*)aPath;
- (NSDate*) lockDate;
- (BOOL) tryLock;
- (void) unlock;

@end

#endif /* _mySTEP_H_NSDistributedLock */
