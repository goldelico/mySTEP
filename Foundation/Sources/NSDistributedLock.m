/* 
   NSDistributedLock.m

   Restrict access to resources shared by multiple apps.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
   Date:    1997

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#include <fcntl.h>

#import <Foundation/NSDate.h>
#import <Foundation/NSDistributedLock.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSException.h>
#import <Foundation/NSValue.h>
#import "NSPrivate.h"


@implementation NSDistributedLock

+ (NSDistributedLock*) lockWithPath:(NSString*)aPath
{
    return [[[self alloc] initWithPath: aPath] autorelease];
}

- (void) breakLock
{
NSFileManager *fileManager = [NSFileManager defaultManager];

	if ([fileManager removeFileAtPath: _lockPath handler: nil] == NO)
		[NSException raise: NSGenericException 
					 format: @"Failed to remove lock directory '%@' - %s",
					 		_lockPath, strerror(errno)];
	[_lockTime release];
	_lockTime = nil;
}

- (void) dealloc
{
	[_lockPath release];
	[_lockTime release];
	[super dealloc];
}

- (NSDistributedLock*) initWithPath:(NSString*)aPath
{
NSFileManager *fm = [NSFileManager defaultManager];
NSString *lockDir = [aPath stringByDeletingLastPathComponent];
BOOL isDir = NO;

	_lockPath = [aPath copy];

	if (![fm fileExistsAtPath:lockDir isDirectory:&isDir] || (!isDir))
		{
		if (!isDir)
			return GSError(self,@"lockfile '%@' invalid dir path",_lockPath);

		return GSError(self,@"missing path segment in lock '%@'",_lockPath);
		}

	if ([fm isWritableFileAtPath:lockDir] == NO)
		return GSError(self,@"lock '%@' parent dir not writable",_lockPath);

	if ([fm isExecutableFileAtPath:lockDir] == NO)
		return GSError(self,@"lock '%@' parent dir not accessible",_lockPath);

	return self;
}

- (NSDate*) lockDate
{
NSFileManager *fm = [NSFileManager defaultManager];
NSDictionary *attribs = [fm fileAttributesAtPath:_lockPath traverseLink:YES];

	return [attribs objectForKey: NSFileModificationDate];
}

- (BOOL) tryLock
{
NSFileManager *fm = [NSFileManager defaultManager];
NSMutableDictionary *attribs = [NSMutableDictionary dictionaryWithCapacity: 1];
NSDictionary *d;

	[attribs setObject: [NSNumber numberWithUnsignedInt: 0755]
			 forKey: NSFilePosixPermissions];
	
	if ([fm createDirectoryAtPath:_lockPath attributes:attribs] == NO)
		{
		BOOL isDir;
	
		if ([fm fileExistsAtPath: _lockPath isDirectory: &isDir] == NO || !isDir)
			[NSException raise: NSGenericException 
						 format: @"Failed to create lock directory '%@' - %s",
						 		_lockPath, strerror(errno)];
		[_lockTime release];
		_lockTime = nil;

		return NO;
		}

	d = [fm fileAttributesAtPath:_lockPath traverseLink:YES];
	[_lockTime release];
	_lockTime = [[d objectForKey: NSFileModificationDate] retain];

	return YES;
}

- (void) unlock
{
NSFileManager *fileManager = [NSFileManager defaultManager];
NSDictionary *attributes;

	if (_lockTime == nil)
		[NSException raise:NSGenericException format:@"locked by another app"];

				// Don't remove the lock if it has already been broken by
				// someone else and re-created.  Unfortunately, there is a 
				// window between testing and removing, we do the best we can.
	attributes = [fileManager fileAttributesAtPath:_lockPath traverseLink:YES];
	if ([_lockTime isEqual: [attributes objectForKey: NSFileModificationDate]])
		{
		if ([fileManager removeFileAtPath: _lockPath handler: nil] == NO)
			[NSException raise: NSGenericException
						 format: @"Failed to remove lock directory '%@' - %s",
						 		_lockPath, strerror(errno)];
		}
	else
		NSLog(@"lock '%@' already broken and in use again\n", _lockPath);
	
	[_lockTime release];
	_lockTime = nil;
}

@end
