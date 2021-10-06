/* 
   NSPathUtilities.h

   Interface to file path utilities

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
   Date:	May 1996
   
   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Fabian Spillner, July 2008 - API revised to be compatible to 10.5 (only NSString)
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPathUtilities
#define _mySTEP_H_NSPathUtilities

#import <Foundation/NSString.h>

@class NSArray;

typedef enum _NSSearchPathDirectory
{
	NSApplicationDirectory = 1,
	NSDemoApplicationDirectory,
	NSDeveloperApplicationDirectory,
	NSAdminApplicationDirectory,
	NSLibraryDirectory,
	NSDeveloperDirectory,
	NSUserDirectory,
	NSDocumentationDirectory,
	NSDocumentDirectory,
	NSCoreServiceDirectory,
	NSDesktopDirectory = 12,
	NSCachesDirectory,
	NSApplicationSupportDirectory,
	NSDownloadsDirectory, 
	NSPreferencePanesDirectory = 22,
	NSAllApplicationsDirectory = 100,
	NSAllLibrariesDirectory
} NSSearchPathDirectory;

typedef enum _NSSearchPathDomainMask
{
	NSUserDomainMask		=(1<<0),
	NSLocalDomainMask		=(1<<1),
	NSNetworkDomainMask		=(1<<2),
	NSSystemDomainMask		=(1<<3),
	NSAllDomainsMask		=0x0ffff,
} NSSearchPathDomainMask;

extern NSString *NSFullUserName(void);
extern NSString *NSHomeDirectory(void);
extern NSString *NSHomeDirectoryForUser(NSString *login_name);
extern NSString *NSOpenStepRootDirectory(void);
extern NSArray *NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory directory, NSSearchPathDomainMask domainMask, BOOL expandTilde);
extern NSString *NSTemporaryDirectory(void);
extern NSString *NSUserName(void);

@interface NSString (PathUtilities)

- (NSUInteger) completePathIntoString:(NSString **) outputName
						caseSensitive:(BOOL) flag
					 matchesIntoArray:(NSArray **) outputArray
						  filterTypes:(NSArray *) filterTypes;
- (const char *) fileSystemRepresentation;
- (BOOL) getFileSystemRepresentation:(char *) buffer maxLength:(NSUInteger) l;
- (BOOL) isAbsolutePath;
- (NSString *) lastPathComponent;
- (NSArray *) pathComponents;
- (NSString *) pathExtension;
- (NSString *) stringByAbbreviatingWithTildeInPath;
- (NSString *) stringByAppendingPathComponent:(NSString *) aString;
- (NSString *) stringByAppendingPathExtension:(NSString *) aString;
- (NSString *) stringByDeletingLastPathComponent;
- (NSString *) stringByDeletingPathExtension;
- (NSString *) stringByExpandingTildeInPath;
- (NSString *) stringByResolvingSymlinksInPath;
- (NSString *) stringByStandardizingPath;
- (NSString *) stringByTrimmingCharactersInSet:(NSCharacterSet *) set;
- (NSArray *) stringsByAppendingPaths:(NSArray *) paths;

@end

#endif /* _mySTEP_H_NSPathUtilities */
