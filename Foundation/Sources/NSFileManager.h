/* 
   NSFileManager.h

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
   Author: Ovidiu Predescu <ovidiu@net-community.com>
   Date: Feb 1997

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSFileManager
#define _mySTEP_H_NSFileManager

#import <Foundation/NSObject.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSEnumerator.h>

@class NSError;
@class NSNumber;
@class NSString;
@class NSData;
@class NSDate;
@class NSArray;
@class NSMutableArray;


@interface NSDirectoryEnumerator : NSEnumerator
{
    NSMutableArray *_enumStack;
    NSMutableArray *_pathStack;
    NSString *_fileName ;
    NSString *_filePath;
    NSString *_topPath;
    struct __FileManagerFlags
		{
			unsigned int shallow:1;
			unsigned int followLinks:1;
			unsigned int reserved:6;
		} _fm;
}

- (NSDictionary*) directoryAttributes;
- (NSDictionary*) fileAttributes;
- (void) skipDescendents;								// Skip subdirectories

@end /* NSDirectoryEnumerator */

	extern NSString *NSFileAppendOnly;
	extern NSString *NSFileBusy;
	extern NSString *NSFileCreationDate;
	extern NSString *NSFileDeviceIdentifier;
	extern NSString *NSFileExtensionHidden;
	extern NSString *NSFileGroupOwnerAccountID;
	extern NSString *NSFileGroupOwnerAccountName;
	extern NSString *NSFileHFSCreatorCode;
	extern NSString *NSFileHFSTypeCode;
	extern NSString *NSFileImmutable;
	extern NSString *NSFileModificationDate;
	extern NSString *NSFileOwnerAccountID;
	extern NSString *NSFileOwnerAccountName;
	extern NSString *NSFilePosixPermissions;
	extern NSString *NSFileReferenceCount;
	extern NSString *NSFileSize;
	extern NSString *NSFileSystemFileNumber;
	extern NSString *NSFileType;

	extern NSString *NSFileTypeDirectory;
	extern NSString *NSFileTypeRegular;
	extern NSString *NSFileTypeSymbolicLink;
	extern NSString *NSFileTypeSocket;
	extern NSString *NSFileTypeCharacterSpecial;
	extern NSString *NSFileTypeBlockSpecial;
	extern NSString *NSFileTypeUnknown;
	extern NSString *NSFileTypeFifo;	// not 10.4 - mySTEP extension

	extern NSString *NSFileSystemSize;
	extern NSString *NSFileSystemFreeSize;
	extern NSString *NSFileSystemNodes;
	extern NSString *NSFileSystemFreeNodes;
	extern NSString *NSFileSystemNumber;


@interface NSFileManager : NSObject

+ (NSFileManager*) defaultManager;

- (NSDictionary *) attributesOfFileSystemForPath:(NSString *)path error:(NSError **)error;
- (NSDictionary *) attributesOfItemAtPath:(NSString *)path error:(NSError **)error;
- (BOOL) changeCurrentDirectoryPath:(NSString *)path;
- (BOOL) changeFileAttributes:(NSDictionary *)attributes atPath:(NSString *)path;
- (NSArray *) componentsToDisplayForPath:(NSString *)path;
- (NSData *) contentsAtPath:(NSString *)path;				// Access file contents
- (NSArray *) contentsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;
- (BOOL) contentsEqualAtPath:(NSString *)path1 andPath:(NSString *)path2;
- (BOOL) copyItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
- (BOOL) copyPath:(NSString *)source toPath:(NSString *)destination handler:(id)handler;
- (BOOL) createDirectoryAtPath:(NSString *)path
					attributes:(NSDictionary *)attributes;
- (BOOL)createDirectoryAtPath:(NSString *)path
  withIntermediateDirectories:(BOOL)flag
				   attributes:(NSDictionary *)attributes
						error:(NSError **)error;
- (BOOL) createFileAtPath:(NSString *)path 
				 contents:(NSData *)contents
			   attributes:(NSDictionary *)attributes;
- (BOOL) createSymbolicLinkAtPath:(NSString *)path pathContent:(NSString *)otherPath;
- (BOOL) createSymbolicLinkAtPath:(NSString *)path withDestinationPath:(NSString *)destPath error:(NSError **)error;
- (NSString *) currentDirectoryPath;
- (id) delegate;
- (NSString *) destinationOfSymbolicLinkAtPath:(NSString *)path error:(NSError **)error;
- (NSArray *) directoryContentsAtPath:(NSString *)path;	// List dir contents
- (NSString *) displayNameAtPath:(NSString *)path;
- (NSDirectoryEnumerator *) enumeratorAtPath:(NSString *)path;
- (NSDictionary *) fileAttributesAtPath:(NSString *)path traverseLink:(BOOL) flag;
- (BOOL) fileExistsAtPath:(NSString *)path;				// Detemine file access
- (BOOL) fileExistsAtPath:(NSString *)path isDirectory:(BOOL *)isDirectory;
- (NSDictionary *) fileSystemAttributesAtPath:(NSString *)path;
- (const char *) fileSystemRepresentationWithPath:(NSString *)path;
- (BOOL) isDeletableFileAtPath:(NSString *)path;
- (BOOL) isExecutableFileAtPath:(NSString *)path;
- (BOOL) isReadableFileAtPath:(NSString *)path;
- (BOOL) isWritableFileAtPath:(NSString *)path;
- (BOOL) linkItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
- (BOOL) linkPath:(NSString*)source toPath:(NSString*)destination handler:(id)handler;
- (BOOL) moveItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
- (BOOL) movePath:(NSString*)source toPath:(NSString*)destination handler:(id)handler;
- (NSString *) pathContentOfSymbolicLinkAtPath:(NSString *)path;
- (BOOL) removeFileAtPath:(NSString *)path handler:(id)handler;
- (BOOL) removeItemAtPath:(NSString *) src error:(NSError **) error;
- (BOOL) setAttributes:(NSDictionary *) attribs ofItemAtPath:(NSString *)path error:(NSError **)error;
- (void) setDelegate:(id) delegate;
- (NSString*) stringWithFileSystemRepresentation:(const char *)string
										  length:(unsigned int)len;
- (NSArray*) subpathsAtPath:(NSString *)path;
- (NSArray *) subpathsOfDirectoryAtPath:(NSString *)path error:(NSError **)error;

@end /* NSFileManager */


@interface NSObject (NSFileManagerDelegate)

- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSDictionary *)errorDictionary;
- (void) fileManager:(NSFileManager *)fileManager willProcessPath:(NSString *)path;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldCopyItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error copyingItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldMoveItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldLinkItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error linkingItemAtPath:(NSString *)src toPath:(NSString *)dst;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldRemoveItemAtPath:(NSString *)src;
- (BOOL) fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error removingItemAtPath:(NSString *)src;

@end /* NSObject (NSFileManagerDelegate) */


@interface NSDictionary (NSFileAttributes)

typedef unsigned long OSType;

- (NSDate *) fileCreationDate;
- (BOOL) fileExtensionHidden;
- (NSNumber *) fileGroupOwnerAccountID;
- (NSString *) fileGroupOwnerAccountName;
- (OSType) fileHFSCreatorCode;
- (OSType) fileHFSTypeCode;
- (BOOL) fileIsAppendOnly;
- (BOOL) fileIsImmutable;
- (NSDate *) fileModificationDate;
- (NSNumber *) fileOwnerAccountID;
- (NSString *) fileOwnerAccountName;
- (NSNumber *) filePosixPermissions;
- (NSNumber *) fileSize;
- (unsigned long) fileSystemFileNumber;
- (unsigned long) fileSystemNumber;
- (NSString *) fileType;

@end

#endif /* _mySTEP_H_NSFileManager */
