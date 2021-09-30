/*
 NSFileManager.m

 Copyright (C) 1997 Free Software Foundation, Inc.

 Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>
 Author: Ovidiu Predescu <ovidiu@net-community.com>
 Date: Feb 1997

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSFileManager.h>
#import <Foundation/NSException.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDate.h>
#import <Foundation/NSString.h>
#import <Foundation/NSValue.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSProcessInfo.h>

#import "NSPrivate.h"

#include <unistd.h>
#ifdef __linux__
#include <linux/limits.h>	// for PATH_MAX
#endif

#ifndef NO_DIRENT_H
# include <dirent.h>
#elif defined(HAVE_SYS_DIR_H)
# include <sys/dir.h>
#elif defined(HAVE_SYS_NDIR_H)
# include <sys/ndir.h>
#elif defined(HAVE_NDIR_H)
# include <ndir.h>
#endif

#if !defined(_POSIX_VERSION)
#if defined(NeXT)
#define DIR_enum_item struct direct
#endif
#endif

#if !defined(DIR_enum_item)
# define DIR_enum_item struct dirent
#endif

// determine filesystem max path length
#ifdef _POSIX_VERSION
#include <limits.h>						// for PATH_MAX
#include <utime.h>
#else
#ifndef __WIN32__
#include <sys/param.h>					// for MAXPATHLEN
#endif
#endif

#ifndef PATH_MAX
# ifdef _POSIX_VERSION
#  define PATH_MAX _POSIX_PATH_MAX
# else
#  ifdef MAXPATHLEN
#   define PATH_MAX MAXPATHLEN
#  else
#   define PATH_MAX 1024
#  endif
# endif
#endif
// determine if we have statfs
// struct and function
#ifndef __APPLE__
#define HAVE_SYS_STATFS_H 1
#define HAVE_SYS_VFS_H 1
#endif

#ifdef HAVE_SYS_VFS_H
# include <sys/vfs.h>
# ifdef HAVE_SYS_STATVFS_H
#  include <sys/statvfs.h>
# endif
#endif

#ifdef HAVE_SYS_STATFS_H
# include <sys/statfs.h>
#endif

#include <sys/stat.h>

#include <fcntl.h>
#if HAVE_PWD_H
#include <pwd.h>								// For struct passwd
#endif
#if HAVE_UTIME_H
# include <utime.h>
#endif

// Class variables
static NSFileManager *__fm = nil;


@interface NSFileManager (PrivateMethods)
// Copies contents of src file
- (BOOL) _copyFile:(NSString*)source 			// to dest file. Assumes source
			toFile:(NSString*)destination		// and dest are regular files
		   handler:handler;					// or symbolic links.

- (BOOL) _copyPath:(NSString*)source 			// Recursively copies contents
			toPath:(NSString*)destination		// of src directory to dst.
		   handler:handler;

@end /* NSFileManager (PrivateMethods) */

//*****************************************************************************
//
// 		NSFileManager
//
//*****************************************************************************

@implementation NSFileManager

+ (NSFileManager*) defaultManager
{
	return (__fm) ? __fm : (__fm = (NSFileManager*) [self new]);
}

- (id) delegate;
{
	return _delegate;
}

- (void) setDelegate:(id)delegate
{
	_delegate=delegate;
}

- (BOOL) changeCurrentDirectoryPath:(NSString*)path
{														// Directory operations
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	if(!cpath)
		return NO;
#if defined(__WIN32__) || defined(_WIN32)
	return SetCurrentDirectory(cpath);
#else
	return (chdir(cpath) == 0);
#endif
}

- (BOOL) createDirectoryAtPath:(NSString*)path
					attributes:(NSDictionary*)attributes
{ // superdirectory must exist!
	return [self createDirectoryAtPath:path withIntermediateDirectories:NO attributes:attributes error:NULL];
}

- (BOOL) createDirectoryAtPath:(NSString *)path
   withIntermediateDirectories:(BOOL)flag
					attributes:(NSDictionary *)attributes
						 error:(NSError **)error;
{
	struct stat statbuf;
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	if(!cpath)
		{ // bad path
			if(error)
				*error=[NSError errorWithDomain:@"FileManager" code:1 userInfo:nil];
			return NO;
		}
	if(stat(cpath, &statbuf) == 0)
		{ // file or directory already exists!
			if(error)
				*error=[NSError errorWithDomain:@"FileManager" code:2 userInfo:nil];
			return NO;
		}
	if(flag)
		{ // recursively create intermediates first
			[self createDirectoryAtPath:[path stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:attributes error:NULL];
		}
	if(mkdir(cpath, 0777) != 0)			// will be reduced by umask
		{
		if(error)
			*error=[NSError errorWithDomain:@"FileManager" code:3 userInfo:nil];
		return NO;
		}
	if(attributes)
		{
		// call setAttributes:ofItemAtPath:error:
		if(![self changeFileAttributes:attributes atPath:path])
			{
			if(error)
				*error=[NSError errorWithDomain:@"FileManager" code:4 userInfo:nil];
			return NO;
			}
		}
	return YES;
}

- (NSString*) currentDirectoryPath
{
	char path[PATH_MAX];

#if defined(__WIN32__) || defined(_WIN32)
	if(GetCurrentDirectory(PATH_MAX, path) > PATH_MAX)
		return nil;
#else
	if(getcwd(path, PATH_MAX-1) == NULL)
		return nil;
#endif /* WIN32 */

	return [self stringWithFileSystemRepresentation:path length:strlen(path)];
}

- (BOOL) copyPath:(NSString*)source 						// File operations
		   toPath:(NSString*)destination
		  handler:handler
{
	BOOL sourceIsDir;
	NSDictionary *attributes;

	if (![self fileExistsAtPath:source isDirectory:&sourceIsDir]
		|| [self fileExistsAtPath:destination])
		return NO;

	attributes = [self fileAttributesAtPath:source traverseLink:NO];

	if (sourceIsDir) 					// If dest directory is a descendant of
		{								// src directory copying isn't possible
			if ([[destination stringByAppendingString:@"/"]
				 hasPrefix:[source stringByAppendingString:@"/"]])
				return NO;

			[handler fileManager:self willProcessPath:destination];
			if (![self createDirectoryAtPath:destination attributes:attributes])
				{
				if (handler)
					{
					NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
									   destination, @"Path",
									   @"cannot create directory", @"Error", nil];

					return [handler fileManager:self shouldProceedAfterError:e];
					}

				return NO;
				}

			if (![self _copyPath:source toPath:destination handler:handler])
				return NO;

			[self changeFileAttributes:attributes atPath:destination];

			return YES;
		}

	[handler fileManager:self willProcessPath:source];
	if (![self _copyFile:source toFile:destination handler:handler])
		return NO;

	[self changeFileAttributes:attributes atPath:destination];

	return YES;
}

- (BOOL) movePath:(NSString*)source
		   toPath:(NSString*)destination
		  handler:handler
{
	BOOL sourceIsDir;
	NSString *destinationParent;
	unsigned int sourceDevice, destinationDevice;
	const char *s, *d;

	if (![self fileExistsAtPath:source isDirectory:&sourceIsDir])
		{
		NSLog(@"NSFileManager movePath: source %@ does not exist", source);
		return NO;
		}

	if ([self fileExistsAtPath:destination])
		{
		NSLog(@"NSFileManager movePath: destination %@ exists", destination);
		return NO;
		}
	// Check to see if the source and destination's parent are on the
	// same physical device so we can perform a rename syscall directly
	sourceDevice = [[[self fileSystemAttributesAtPath:source]
					 objectForKey:NSFileSystemNumber] unsignedIntValue];
	destinationParent = [destination stringByDeletingLastPathComponent];
	if ([destinationParent isEqual:@""])
		destinationParent = @".";
	destinationDevice = [[[self fileSystemAttributesAtPath:destinationParent]
						  objectForKey:NSFileSystemNumber] unsignedIntValue];

	if (sourceDevice != destinationDevice)
		{						// If destination directory is a descendant of
								// source directory moving isn't possible.
			if (sourceIsDir && [[destination stringByAppendingString:@"/"]
								hasPrefix:[source stringByAppendingString:@"/"]])
				return NO;

			if ([self copyPath:source toPath:destination handler:handler])
				{
				NSDictionary *a=[self fileAttributesAtPath:source traverseLink:NO];

				[self changeFileAttributes:a atPath:destination];

				return [self removeFileAtPath:source handler:handler];
				}

			return NO;
		}						// src and dest are on the same device so we
								// can simply invoke rename on source.
	s = [self fileSystemRepresentationWithPath:source];
	d = [self fileSystemRepresentationWithPath:destination];

	[handler fileManager:self willProcessPath:source];
	if (rename (s, d) == -1)
		{
		if (handler)
			{
			NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
							   source, @"Path", destination, @"ToPath",
							   @"cannot move file", @"Error", nil];

			if ([handler fileManager:self shouldProceedAfterError:e])
				return YES;
			}

		return NO;
		}

	return YES;
}

- (BOOL) linkPath:(NSString*)source
		   toPath:(NSString*)destination
		  handler:handler								{ NIMP ; return NO; }

- (BOOL) removeFileAtPath:(NSString*)path handler:handler
{
	NSArray	*contents;
	int	i;

	if (handler)
		[handler fileManager: self willProcessPath: path];

	if ((contents = [self directoryContentsAtPath: path]) == nil)
		{
		if (unlink([path fileSystemRepresentation]) < 0)
			{
			BOOL result;
#if 1
			NSLog(@"unlink(%s): %s", [path fileSystemRepresentation], strerror(errno));
#endif
			if (handler)
				{
				NSMutableDictionary	*d;

				d = [[NSMutableDictionary alloc] initWithCapacity: 3];
				[d setObject: path forKey: @"Path"];
				[d setObject: [NSString stringWithCString: strerror(errno)]
					  forKey: @"Error"];
				result = [handler fileManager:self shouldProceedAfterError:d];
				[d release];
				}
			else
				result = NO;

			return result;
			}

		return YES;
		}

	for (i = 0; i < [contents count]; i++)
		{
		NSAutoreleasePool *arp = [NSAutoreleasePool new];
		NSString *item = [contents objectAtIndex: i];
		NSString *next = [path stringByAppendingPathComponent: item];
		BOOL result = [self removeFileAtPath: next handler: handler];

		[arp release];
		if (result == NO)
			return NO;
		}

	if (rmdir([path fileSystemRepresentation]) < 0)
		{
		BOOL result;
#if 1
		NSLog(@"rmdir(%s): %s", [path fileSystemRepresentation], strerror(errno));
#endif
		if (handler)
			{
			NSMutableDictionary	*d;

			d = [[NSMutableDictionary alloc] initWithCapacity: 3];
			[d setObject: path forKey: @"Path"];
			[d setObject: [NSString stringWithCString: strerror(errno)]
				  forKey: @"Error"];
			result = [handler fileManager:self shouldProceedAfterError:d];
			[d release];
			}
		else
			result = NO;

		return result;
		}

	return YES;
}

- (BOOL) createFileAtPath:(NSString*)path
				 contents:(NSData*)contents
			   attributes:(NSDictionary*)attributes
{
	int fd, len, written;
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	if(!cpath)
		return NO;
	if ((fd = open (cpath, O_WRONLY|O_TRUNC|O_CREAT, 0644)) < 0)
		return NO;

	if (![self changeFileAttributes:attributes atPath:path])
		{
		close (fd);
		return NO;
		}

	written = (len = [contents length]) ? write(fd, [contents bytes], len) : 0;
	close (fd);

	return (written == len);
}

- (NSData*) contentsAtPath:(NSString*)path
{
	return [NSData dataWithContentsOfFile:path];
}

- (BOOL) contentsEqualAtPath:(NSString*)path1
					 andPath:(NSString*)path2
{
	NSData *d1 = [NSData dataWithContentsOfFile:path1];
	return [d1 isEqualToData: [NSData dataWithContentsOfFile:path2]];
}

- (BOOL) fileExistsAtPath:(NSString*)path
{
	return [self fileExistsAtPath:path isDirectory:NULL];
}

- (BOOL) fileExistsAtPath:(NSString*)path isDirectory:(BOOL*)isDirectory
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	struct stat statbuf;
	cpath=[self _traverseLink:cpath];
	if(!cpath)
		return NO;
#if 0
	fprintf(stderr, "fileExistsAtPath %s -> %s\n", [path UTF8String], cpath);
#endif
	if (stat(cpath, &statbuf) != 0)
		{
#if 0
		fprintf(stderr, "stat error=%s\n", strerror(errno));
#endif
		return NO;
		}
#if 0
	fprintf(stderr, "fileExistsAtPath %s -> %o\n", [path UTF8String], statbuf.st_mode);
#endif
	if (isDirectory)
		*isDirectory = ((statbuf.st_mode & S_IFMT) == S_IFDIR);
	return YES;
}

- (BOOL) isReadableFileAtPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	cpath=[self _traverseLink:cpath];
	if(!cpath)
		return NO;
	return (access(cpath, R_OK) == 0);
}

- (BOOL) isWritableFileAtPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	cpath=[self _traverseLink:cpath];
	if(!cpath)
		return NO;
	return (access(cpath, W_OK) == 0);
}

- (BOOL) isExecutableFileAtPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	struct stat s;
	cpath=[self _traverseLink:cpath];
	if(!cpath)
		return NO;
	// test the exec permission bits
	if (stat(cpath, &s) == 0)				// return YES if any are set
		if(s.st_mode & S_IXUSR || s.st_mode & S_IXGRP || s.st_mode & S_IXOTH)
			return YES;

	return NO;
}

- (BOOL) isDeletableFileAtPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath: path];
	if(!cpath)
		return NO;
	return (access(cpath, (X_OK | W_OK)) == 0);
}

- (NSDictionary*) fileAttributesAtPath:(NSString*)path
						  traverseLink:(BOOL)flag
{
	struct stat statbuf;
	const char *cpath = [self fileSystemRepresentationWithPath:path];
#if HAVE_PWD_H
	struct passwd *pw;
#endif
	id keys[] = {
		NSFileSize,
		NSFileModificationDate,
		NSFileCreationDate,
		NSFileOwnerAccountID,
		NSFileGroupOwnerAccountID,
		NSFileReferenceCount,
		NSFileSystemFileNumber,
		NSFileDeviceIdentifier,
		NSFilePosixPermissions,
		NSFileType,
		NSFileOwnerAccountName
	};
	int mode, count = 0;

	id values[sizeof(keys)/sizeof(keys[0])];
#if 0
	NSLog(@"fileAttributesAtPath:%s", cpath);
#endif
	if(flag)
		cpath=[self _traverseLink:cpath];

	if (!cpath || stat(cpath, &statbuf) != 0)
		{
#if 0
		NSLog(@"fileAttributesAtPath: can't stat %s", cpath);
#endif
		return nil;
		}
	values[count++] = [NSNumber numberWithUnsignedLongLong:statbuf.st_size];
	values[count++] = [NSDate dateWithTimeIntervalSince1970:statbuf.st_mtime];
	values[count++] = [NSDate dateWithTimeIntervalSince1970:statbuf.st_ctime];
	values[count++] = [NSNumber numberWithUnsignedInt:statbuf.st_uid];
	values[count++] = [NSNumber numberWithUnsignedInt:statbuf.st_gid];
	values[count++] = [NSNumber numberWithUnsignedInt:statbuf.st_nlink];
	values[count++] = [NSNumber numberWithUnsignedLong:statbuf.st_ino];
	values[count++] = [NSNumber numberWithUnsignedInt:statbuf.st_dev];
	values[count++] = [NSNumber numberWithUnsignedInt:statbuf.st_mode];

	mode = statbuf.st_mode & S_IFMT;

	if (mode == S_IFREG)
		values[count] = NSFileTypeRegular;
	else if (mode == S_IFDIR)
		values[count] = NSFileTypeDirectory;
	else if (mode == S_IFCHR)
		values[count] = NSFileTypeCharacterSpecial;
	else if (mode == S_IFBLK)
		values[count] = NSFileTypeBlockSpecial;
	else if (mode == S_IFLNK)
		values[count] = NSFileTypeSymbolicLink;
	else if (mode == S_IFIFO)
		values[count] = NSFileTypeFifo;
	else if (mode == S_IFSOCK)
		values[count] = NSFileTypeSocket;
	else
		values[count] = NSFileTypeUnknown;
	count++;
#if HAVE_PWD_H
	if((pw = getpwuid(statbuf.st_uid)))
		values[count++] = [NSString stringWithCString:pw->pw_name];
#endif /* HAVE_PWD_H */

	return [[[NSDictionary alloc] initWithObjects:values
										  forKeys:keys
											count:count] autorelease];
}

- (NSDictionary*) fileSystemAttributesAtPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath: path];
	struct stat statbuf;
#if HAS_STATFS
	struct statfs statfsbuf;
#endif
	long long totalsize=0, freesize=0;
	id keys[5] = {
		NSFileSystemSize,
		NSFileSystemFreeSize,
		NSFileSystemNodes,
		NSFileSystemFreeNodes,
		NSFileSystemNumber
	};
	id values[sizeof(keys)/sizeof(keys[0])];
#if 0
	NSLog(@"fileSystemAttributesAtPath:%s", cpath);
#endif


	if (!cpath || stat(cpath, &statbuf) != 0)
		{
#if 1
		NSLog(@"fileSystemAttributesAtPath: can't stat %s", cpath);
#endif
		return nil;
		}
#if HAS_STATFS
	if (statfs(cpath, &statfsbuf) != 0)
		return nil;

	totalsize = statfsbuf.f_bsize * statfsbuf.f_blocks;
	freesize = statfsbuf.f_bsize * statfsbuf.f_bavail;

	values[2] = [NSNumber numberWithLong: statfsbuf.f_files];
	values[3] = [NSNumber numberWithLong: statfsbuf.f_ffree];
	values[4] = [NSNumber numberWithUnsignedInt: statbuf.st_dev];
#endif

	values[0] = [NSNumber numberWithLongLong: totalsize];
	values[1] = [NSNumber numberWithLongLong: freesize];

	return [[[NSDictionary alloc] initWithObjects:values
										  forKeys:keys
											count:5] autorelease];
}

- (BOOL) changeFileAttributes:(NSDictionary*)attributes
					   atPath:(NSString*)path
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	NSNumber *num;
	NSDate *date;
	BOOL allOk = YES;

	if(!cpath)
		return NO;
#ifndef __WIN32__
	if ((num = [attributes objectForKey:NSFileOwnerAccountID]))
		allOk &= (chown(cpath, [num intValue], -1) == 0);

	if ((num = [attributes objectForKey:NSFileGroupOwnerAccountID]))
		allOk &= (chown(cpath, -1, [num intValue]) == 0);
#endif

	if ((num = [attributes objectForKey:NSFilePosixPermissions]))
		allOk &= (chmod(cpath, [num intValue]) == 0);

	if ((date = [attributes objectForKey:NSFileModificationDate]))
		{
		struct stat sb;
#ifdef  _POSIX_VERSION
		struct utimbuf ub;
#else
		time_t ub[2];
#endif

		if (stat(cpath, &sb) != 0)
			allOk = NO;
		else
			{
#ifdef _POSIX_VERSION
			ub.actime = sb.st_atime;
			ub.modtime = [date timeIntervalSince1970];
			allOk &= (utime(cpath, &ub) == 0);
#else
			ub[0] = sb.st_atime;
			ub[1] = [date timeIntervalSince1970];
			allOk &= (utime((char*)cpath, ub) == 0);
#endif
			}	}

	return allOk;
}

- (NSArray*) directoryContentsAtPath:(NSString*)path
{
	return [self contentsOfDirectoryAtPath:path error:NULL];
}

- (NSDirectoryEnumerator*) enumeratorAtPath:(NSString*)path
{
	NSDirectoryEnumerator *de;
	BOOL isDir;
	DIR *dir;

	if (![self fileExistsAtPath:path isDirectory:&isDir] || !isDir)
		return nil;

	de = [[NSDirectoryEnumerator alloc] _initWithPath:path];
	// sys dir enumerator onto enumPath
	//
	// FIXME: handle virtual home /Users/*
	//
	if ((dir = opendir([__fm  fileSystemRepresentationWithPath:path])))
		{
		[de _pathStackAddObject:@""];
		[de _enumStackAddObject:[NSValue valueWithPointer:dir]];
		}

	return [de autorelease];
}

- (NSArray*) subpathsAtPath:(NSString*)path
{
	// return [self subpathsOfDirectory:path error:NULL];
	NSDirectoryEnumerator *de = [self enumeratorAtPath: path];
	NSMutableArray *c;

	if (!de)
		return nil;

	c = [[NSMutableArray alloc] init];
	while ((path = [de nextObject]))
		[c addObject:path];

	return [c autorelease];
}

- (BOOL) createSymbolicLinkAtPath:(NSString*)path
					  pathContent:(NSString*)otherPath
{
#ifdef __WIN32__							// can't handle symbolic-link operations
	return NO;
#else
	const char *linkPath = [self fileSystemRepresentationWithPath:path];
	const char *contentPath = [self fileSystemRepresentationWithPath:otherPath];
	if(!linkPath || !contentPath)
		return NO;
#if 0
	NSLog(@"ln -s %s %s", contentPath, linkPath);
#endif
	if(symlink(contentPath, linkPath) < 0)
		{
		// FIXME: raise exception?
		NSLog(@"createSymbolicLinkAtPath error: %s", strerror(errno));
		return NO;
		}
	return YES;
#endif
}

- (NSString *) pathContentOfSymbolicLinkAtPath:(NSString *)path
{
	const char *cpath = [self fileSystemRepresentationWithPath:path];
	NSString *str=nil;
	if(cpath)
		{
		char *lpath=objc_malloc(PATH_MAX+1);
		int llen = readlink(cpath, lpath, PATH_MAX);
		if(llen > 0)
			str=[self stringWithFileSystemRepresentation:lpath length:llen];
		objc_free(lpath);
		}
	return str;
}

- (const char *) _traverseLink:(const char *) cpath;
{ // if cpath is a symlink, find real file
#if 0
	NSLog(@"_traverseLink %s", cpath);
#endif
	while(YES)
		{ // try to expand symlink
			char *buffer=_autoFreedBufferWithLength(PATH_MAX+1);
			int llen = readlink(cpath, buffer, PATH_MAX);
#if 0
			NSLog(@"_traverseLink readlink %s -> %d", cpath, llen);
#endif
			if(llen < 0)
				{
#if 0
				NSLog(@"_traverseLink -> %s", cpath);
#endif
				return cpath;	// no symlink or symlink pointing to nowhere
				}
			buffer[llen]=0;	// 0-terminate
#if 0
			NSLog(@"_traverseLink: %s -> %s", cpath, buffer);
#endif
			if(buffer[0] != '/')
				{ // handle relative links
				const char *dirname=strrchr(cpath, '/');
				char *newpath=_autoFreedBufferWithLength(PATH_MAX+1);
				int dlen;
				if(!dirname) dirname=cpath-1;	// cpath itself is relative
				strncpy(newpath, cpath, dirname-cpath+1);	// keep / intact
				strcpy(newpath+(dirname-cpath+1), buffer);
#if 0
				NSLog(@"_traverseLink handle relative link: %s %s %s %s", cpath, dirname, buffer, newpath);
#endif
				buffer=newpath;
				}
			cpath=buffer;
		}
}

- (const char *) fileSystemRepresentationWithPath:(NSString*)path
{
	//	fprintf(stderr, "fileSystemRepresentation path=%p\n", path);
#if 0
	NSLog(@"fileSystemRepresentationWithPath:%@", path);
#endif
	if([path hasPrefix:@"/"])
		{ // adapt absolute paths
			static NSString *virtualRoot;
#if 0	// really deprecated...
			BOOL uflag;
			if((uflag=[path hasPrefix:@"/Users/"]) || [path isEqualToString:@"/Users"])
				{ // do search on /mnt/card for virtual home!
					NSString *alternatePath=[@"/mnt/card" stringByAppendingString:path];
					const char *cpath = [alternatePath UTF8String];
					struct stat statbuf;
					if(stat(cpath, &statbuf) == 0)
						return cpath; // exists - use that version
									  // FIXME: should check if we are allowed to write to that directory!
					if(uflag && stat([[alternatePath stringByDeletingLastPathComponent] UTF8String], &statbuf) == 0)
						{ // file exists - and is not /Users itself
							if(((statbuf.st_mode & S_IFMT) == S_IFDIR) && (statbuf.st_mode & S_IWUSR))
								return cpath; // directory exists and is user-writeable: still use file name in case we want to create that file
						}
				}
#endif
			if(!virtualRoot)
				{
				NSProcessInfo *pi = [NSProcessInfo processInfo];
				virtualRoot = [[[pi environment] objectForKey:@"QuantumSTEP"] retain];
				//			fprintf(stderr, "virtualRoot=%p\n", virtualRoot);
				if(!virtualRoot)
					virtualRoot=@"/usr/local/QuantumSTEP";		// default
#if 0
				NSLog(@"virtualRoot=%@", virtualRoot);
#endif
				}
			if(![path hasPrefix:@"/dev"] && ![path hasPrefix:@"/sys"] && ![path hasPrefix:@"/proc"] && ![path hasPrefix:@"/tmp"] && ![path hasPrefix:@"/bin"] && ![path hasPrefix:@"/etc"])	// we could also check for upper/lower case?
				path=[virtualRoot stringByAppendingString:path]; // virtually do a chroot("/home/myPDA")
		}
#if 0
	NSLog(@" -> %@", path);
#endif
	//	fprintf(stderr, "fileSystemRepresentation path=%p\n", path);
	{
	const char *s=[path UTF8String];
	//		fprintf(stderr, " -> %p\n", s);
	return s;
	}
}

- (NSString *) stringWithFileSystemRepresentation:(const char*)string
										   length:(NSUInteger)len
{
#if __mySTEP__
	if(len > 0 && string[0] == '/')
		{ // absolute path
			static char *virtualCRoot;	// with trailing /
			static int clen;
			if(!virtualCRoot)
				{
				const char *str=[@"/" fileSystemRepresentation];
#if 0
				NSLog(@"virtualCRoot=%s", str);
#endif
				clen=strlen(str);
				virtualCRoot=objc_malloc(clen+1);
				strcpy(virtualCRoot, str);	// save (retain) a copy
				}
#if 0
			NSLog(@"stringWithFileSystemRepresentation: %s len:%d virtualRoot=%s", string, len, virtualCRoot);
#endif
			if(len >= clen && strncmp(string, virtualCRoot, clen) == 0)
				return [NSString stringWithCString:string+clen-1 length:len-clen+1];	// is relative to root
			if(len == clen-1 && strncmp(string, virtualCRoot, len) == 0)
				return @"/";	// this is virtual root /
#if 0
			if(len >= 15 && strncmp(string, "/mnt/card/Users/", 15) == 0)
				return [NSString stringWithFormat:@"/Users/%.*s", len-15, string+15];	// translate virtual home
			if(strcmp(string, "/mnt/card/Users") == 0)
				return @"/Users";	// translate virtual home
			if(len >= 17 && strncmp(string, "/media/card/Users/", 17) == 0)
				return [NSString stringWithFormat:@"/Users/%.*s", len-17, string+17];	// translate virtual home (OpenMoko)
			if(len >= 12 && strncmp(string, "/hdd3/Users/", 12) == 0)
				return [NSString stringWithFormat:@"/Users/%.*s", len-12, string+12];	// translate virtual home (Zaurus)
			if(strcmp(string, "/media/card/Users") == 0)
				return @"/Users";	// translate virtual home
			if(len >= 9 && strncmp(string, "/mnt/net/", 9) == 0)
				return [NSString stringWithFormat:@"/Network/%.*s", len-8, string+8];	// translate
			if(len >= 5 && strncmp(string, "/mnt/", 5) == 0)
				return [NSString stringWithFormat:@"/Volumes/%.*s", len-4, string+4];	// translate
#endif
		}
	return [NSString _stringWithUTF8String:string length:len];  // all others unchanged
#else
	return [NSString _stringWithUTF8String:string length:len];
#endif
}

- (NSString *) displayNameAtPath:(NSString *)path;
{
	return [[self componentsToDisplayForPath:path] lastObject];
}

- (NSArray *) componentsToDisplayForPath:(NSString *)path;
{
	return [path pathComponents];
	// should translate components to localized version
	// i.e. Applications -> Programme, Users -> Benutzer
}

// FIXME: make these the core implementation and the older variants a wrapper with error:NULL

- (NSDictionary *) attributesOfFileSystemForPath:(NSString *) path error:(NSError **) error;
{
	return NIMP;
}

- (NSDictionary *) attributesOfItemAtPath:(NSString *) path error:(NSError **) error;
{
	// FIXME: base fileAttributesAtPath:error: on this...
	NSDictionary *r=[self fileAttributesAtPath:path traverseLink:NO];;
	if(!r)
		{
		if(error)
			*error=[NSError errorWithDomain:@"NSFileManager" code:0 userInfo:[NSDictionary dictionaryWithObject:path forKey:@"path"]];
		return nil;
		}
	return r;
}

- (NSArray *) contentsOfDirectoryAtPath:(NSString *) path error:(NSError **) error;
{
	NSDirectoryEnumerator *de = [self enumeratorAtPath: path];
	NSMutableArray *c;
	NSArray *hidden=[[NSString stringWithContentsOfFile:[path stringByAppendingPathComponent:@".hidden"]] componentsSeparatedByString:@"\n"];
	if(!de)
		{
		if(error)
			*error=[NSError errorWithDomain:@"NSFileManager" code:0 userInfo:[NSDictionary dictionaryWithObject:path forKey:@"path"]];
		return nil;
		}
	[de _setShallow:YES];
	c = [NSMutableArray arrayWithCapacity:25];	// guess for average sized directories
	while((path = [de nextObject]))
		{
		if([hidden containsObject:path])
			continue;  // is in hidden-list
		[c addObject:path];
		}
	return c;
}

- (BOOL) copyItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
{
	NIMP; return NO;
}
- (BOOL) createSymbolicLinkAtPath:(NSString *) path withDestinationPath:(NSString *) destPath error:(NSError **) error;
{
	NIMP; return NO;
}
- (NSString *) destinationOfSymbolicLinkAtPath:(NSString *) path error:(NSError **) error;
{
	return NIMP;
}
- (BOOL) linkItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
{
	NIMP; return NO;
}
- (BOOL) moveItemAtPath:(NSString *) src toPath:(NSString *) dst error:(NSError **) error;
{
	NIMP; return NO;
}
- (BOOL) removeItemAtPath:(NSString *) src error:(NSError **) error;
{
	NIMP; return NO;
}
- (BOOL) setAttributes:(NSDictionary *) attribs ofItemAtPath:(NSString *) path error:(NSError **) error;
{
	NIMP; return NO;
}
- (NSArray *) subpathsOfDirectoryAtPath:(NSString *) path error:(NSError **) error;
{
	return NIMP;
}

@end /* NSFileManager */

//*****************************************************************************
//
// 		NSDirectoryEnumerator
//
//*****************************************************************************

@implementation NSDirectoryEnumerator

- (void) dealloc
{
	while ([_pathStack count])
		{
		closedir((DIR*)[[_enumStack lastObject] pointerValue]);
		[_enumStack removeLastObject];
		[_pathStack removeLastObject];
		[_fileName release];
		[_filePath release];
		_fileName  = _filePath = nil;
		}
	[_pathStack release];
	[_enumStack release];
	[_fileName release];
	[_filePath release];
	[_topPath release];
	[super dealloc];
}

- (id) _initWithPath:(NSString *) path
{
	if((self=[super init]))
		{
		_pathStack = [NSMutableArray new];	// recurse into directory `path',
		_enumStack = [NSMutableArray new];	// push relative path (to root of
		_topPath = [path retain];			// search) on _pathStack and push
		}
	return self;
}

- (void) _pathStackAddObject:(id) object
{
	[_pathStack addObject:object];
}

- (void) _enumStackAddObject:(id) object
{
	[_enumStack addObject:object];
}

- (void) _setShallow:(BOOL) val
{
	_fm.shallow=val;
}

// Getting attributes
- (NSDictionary*) directoryAttributes
{
	return [__fm fileAttributesAtPath:_filePath traverseLink:_fm.followLinks];
}

- (NSDictionary*) fileAttributes
{
	return [__fm fileAttributesAtPath:_filePath traverseLink:_fm.followLinks];
}

- (NSUInteger) level;
{
	return [_pathStack count];
}

// something for FoundationTests:
// if called while we got a plain file, this aborts reading the current directory
// what happens if called before the first nextObject? probably nothing

- (void) skipDescendents
{// Skip remainder of current directory
	if ([_pathStack count])
		{
		closedir((DIR*)[[_enumStack lastObject] pointerValue]);
		[_enumStack removeLastObject];
		[_pathStack removeLastObject];
		[_fileName  release];
		[_filePath release];
		_fileName  = _filePath = nil;
		}
}

- (id) nextObject
{ // finds the next file according to the top
  // enumerator.  if there is a next file it
  // is put in _fileName.  if the current
  // file is a directory and if isRecursive
  // calls recurseIntoDirectory:currentFile.  if current file is a
  // symlink to a directory and if isRecursive and followLinks calls
  // recurseIntoDirectory:currentFile.  if at end of current dir pops
  // stack and attempts to find the next entry in the parent.  Then
  // sets currentFile to nil if there are no more files to enumerate.
	[_fileName release];
	[_filePath release];
	_fileName = _filePath = nil;
	while ([_pathStack count])
		{
		DIR *dir = (DIR*)[[_enumStack lastObject] pointerValue];
		DIR_enum_item *dirbuf = readdir(dir);
		struct stat statbuf;
		const char *cpath;
#if 0
		NSLog(@"dir = %p dirbuf = %p path=%@", dir, dirbuf, [_pathStack lastObject]);
#endif
		if (dirbuf)
			{							// Skip "." and ".." directory entries
				if (strcmp(dirbuf->d_name, ".") == 0
					|| strcmp(dirbuf->d_name, "..") == 0)
					continue;
				if (strncmp(dirbuf->d_name, "._", 2) == 0)
					continue;				// skip resource forks
											// Name of current file
				_fileName = [__fm stringWithFileSystemRepresentation:dirbuf->d_name  length:strlen(dirbuf->d_name)];
				_fileName = [[_pathStack lastObject] stringByAppendingPathComponent:_fileName];
				// Full path of current file
				_filePath = [_topPath stringByAppendingPathComponent:_fileName];
				[_fileName retain];
				[_filePath retain];
#if 0
				NSLog(@"fileName=%@ filepath=%@", _fileName, _filePath);
#endif
				if(_fm.shallow)
					break;	// no need to check for directory
				cpath=[__fm fileSystemRepresentationWithPath:_filePath];
				if (!_fm.followLinks)
					{ // default is not to follow symlinks
#if 0
						NSLog(@"lstat(%s, %p)", cpath, &statbuf);
#endif
						if (lstat(cpath, &statbuf) < 0)
							break;
						// If link (even into directoy) then return it as link and don't traverse
						if (S_IFLNK == (S_IFMT & statbuf.st_mode))
							break;
					}
				else
					{ // Follow links check for directory
#if 0
						NSLog(@"stat(%s, %p)", cpath, &statbuf);
#endif
						if (stat(cpath, &statbuf) < 0)
							break;
						// FIXME: should readlink and substitute file name for _pathStack
					}
#if 0
				NSLog(@"statbuf.st_mode=%08x", statbuf.st_mode);
#endif
				if (S_IFDIR == (S_IFMT & statbuf.st_mode))
					{	// recurses into directory `path', push
						// path relative to root of search onto
						// _pathStack and push system dir
						// enumerator on enumPath
						if ((dir = opendir(cpath)))
							{ // if successfully opened
#if 0
								NSLog(@"traverse %@", _fileName);
#endif
								[_pathStack addObject: _fileName];
								[_enumStack addObject: [NSValue valueWithPointer:dir]];
							}
					}
#if 0
				NSLog(@"done %@", _fileName);
#endif
				break;
			}
		else
			{ // end of this directory (or readdir eror), go up one level
#if 0
				NSLog(@"go up one level");
#endif
				closedir(dir);
				[_enumStack removeLastObject];
				[_pathStack removeLastObject];
				[_fileName release];
				[_filePath release];
				_fileName = _filePath = nil;	// if we end the while loop due to empty stack, this will return nil
			}
		}
#if 0
	NSLog(@"return %@ retaincnt=%u", _fileName, [_fileName retainCount]);
#endif
	return _fileName ;
}

@end /* NSDirectoryEnumerator */

//*****************************************************************************
//
// 		NSDictionary (NSFileAttributes)
//
//*****************************************************************************

@implementation NSDictionary (NSFileAttributes)

- (unsigned long long) fileSize
{
	id o=[self objectForKey:NSFileSize];
	return o?[o unsignedLongLongValue]:0;	// may not return 0ul id o == nil!
}

- (NSString*) fileType;		{ return [self objectForKey:NSFileType]; }

- (NSString*) fileOwnerAccountName;
{
	return [self objectForKey:NSFileOwnerAccountName];
}

- (NSNumber*) fileOwnerAccountID;
{
	return [self objectForKey:NSFileOwnerAccountID];
}

- (NSString*) fileGroupOwnerAccountName;
{
	return [self objectForKey:NSFileGroupOwnerAccountName];
}

- (NSNumber*) fileGroupOwnerAccountID;
{
	return [self objectForKey:NSFileGroupOwnerAccountID];
}

- (NSDate*) fileCreationDate;
{
	return [self objectForKey:NSFileCreationDate];
}

- (NSDate*) fileModificationDate;
{
	return [self objectForKey:NSFileModificationDate];
}

- (unsigned long) filePosixPermissions;
{
	id o=[self objectForKey:NSFilePosixPermissions];
	return o?[o unsignedIntValue]:0;
}

- (BOOL) fileIsAppendOnly;
{
	id o=[self objectForKey:NSFileAppendOnly];
	return o?[o boolValue]:NO;
}

- (BOOL) fileIsImmutable;
{
	id o=[self objectForKey:NSFileImmutable];
	return o?[o boolValue]:NO;
}

- (BOOL) fileExtensionHidden;
{
	id o=[self objectForKey:NSFileExtensionHidden];
	return o?[o boolValue]:NO;
}

// will default to '????' as it is not set by NSFileManager
- (unsigned long) fileHFSCreatorCode;
{
	id o=[self objectForKey:NSFileHFSCreatorCode];
	return o?[o unsignedLongValue]:('?'*257*65537);
}

- (unsigned long) fileHFSTypeCode;
{
	id o=[self objectForKey:NSFileHFSTypeCode];
	return o?[o unsignedLongValue]:('?'*257*65537);
}

- (unsigned long) fileSystemFileNumber;
{
	id o=[self objectForKey:NSFileSystemFileNumber];
	return o?[o unsignedLongValue]:NO;
}

- (unsigned long) fileSystemNumber;
{
	id o=[self objectForKey:NSFileSystemNumber];
	return o?[o unsignedLongValue]:NO;
}

@end /* NSFileAttributes */

//*****************************************************************************
//
// 		NSFileManager (PrivateMethods)
//
//*****************************************************************************

@implementation NSFileManager (PrivateMethods)

- (BOOL) _copyFile:(NSString*)source
			toFile:(NSString*)destination
		   handler:handler
{
	int i, bufsize = 2*4096;
	int sourceFd, destFd, fileSize, fileMode;
	int rbytes;
	char *buffer=objc_malloc(bufsize);
	const char *cpath = [self fileSystemRepresentationWithPath:source];
	NSDictionary *attributes = [self fileAttributesAtPath:source traverseLink:NO];
	// Assumes source is file and exists
	NSAssert1([self fileExistsAtPath:source],@"source '%@' missing", source);
	NSAssert1(attributes,@"could not get the attributes for file '%@'",source);

	fileSize = [[attributes objectForKey:NSFileSize] intValue];
	fileMode = [[attributes objectForKey:NSFilePosixPermissions] intValue];

	if ((sourceFd = open(cpath, O_RDONLY)) < 0)
		{										// Open source file. In case
			if (handler) 							// of error call the handler
				{
				NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
								   source, @"Path",
								   @"cannot open file for reading", @"Error",nil];
				objc_free(buffer);

				return [handler fileManager:self shouldProceedAfterError:e];
				}

			return NO;
		}									// Open destination file. In case
											// of error call the handler.
	cpath = [self fileSystemRepresentationWithPath:destination];
	if ((destFd = open(cpath, O_WRONLY|O_CREAT|O_TRUNC, fileMode)) < 0)
		{
		if (handler)
			{
			NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
							   destination, @"ToPath",
							   @"cannot open file for writing", @"Error", nil];
			close (sourceFd);
			objc_free(buffer);

			return [handler fileManager:self shouldProceedAfterError:e];
			}

		return NO;			// Read bufsize bytes from source file and write
		}					// them into the destination file. In case of
							// errors call the handler and abort the operation.
	for (i = 0; i < fileSize; i += rbytes)
		{
		if ((rbytes = read(sourceFd, buffer, bufsize)) < 0)
			{
			if (handler)
				{
				NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
								   source, @"Path",
								   @"cannot read from file", @"Error", nil];
				close(sourceFd);
				close(destFd);
				objc_free(buffer);

				return [handler fileManager:self shouldProceedAfterError:e];
				}

			return NO;
			}

		if ((write(destFd, buffer, rbytes)) != rbytes)
			{
			if (handler)
				{
				NSDictionary *e = [NSDictionary dictionaryWithObjectsAndKeys:
								   source, @"Path", destination, @"ToPath",
								   @"cannot write to file", @"Error", nil];
				close(sourceFd);
				close(destFd);
				objc_free(buffer);

				return [handler fileManager:self shouldProceedAfterError:e];
				}

			return NO;
			}
		}

	close(sourceFd);
	close(destFd);
	objc_free(buffer);
	return YES;
}

- (BOOL) _copyPath:(NSString*)source
			toPath:(NSString*)destination
		   handler:handler
{
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	NSDirectoryEnumerator *en = [self enumeratorAtPath:source];
	NSString *dirEntry;

	while ((dirEntry = [en nextObject]))
		{
		NSDictionary *attributes = [en fileAttributes];
		NSString *fileType = [attributes objectForKey:NSFileType];
		NSString *sf = [source stringByAppendingPathComponent:dirEntry];
		NSString *df = [destination stringByAppendingPathComponent:dirEntry];

		[handler fileManager:self willProcessPath:sf];
		if ([fileType isEqual:NSFileTypeDirectory])
			{
			if (![self createDirectoryAtPath:df attributes:attributes])
				{
				if (handler)
					{
					NSDictionary *e=[NSDictionary dictionaryWithObjectsAndKeys:
									 df, @"Path",
									 @"cannot create directory", @"Error", nil];

					if (![handler fileManager:self shouldProceedAfterError:e])
						{
						[pool release];
						return NO;
						}
					}
				else
					{
					[pool release];
					return NO;
					}
				}
			else
				{
				[en skipDescendents];
				if (![self _copyPath:sf toPath:df handler:handler])
					{
					[pool release];
					return NO;
					}
				}
			}
		else
			if ([fileType isEqual:NSFileTypeRegular])
				{
				if (![self _copyFile:sf toFile:df handler:handler])
					{
					[pool release];
					return NO;
					}
				}
			else
				if ([fileType isEqual:NSFileTypeSymbolicLink])
					{
					if (![self createSymbolicLinkAtPath:df pathContent:sf])
						{
						if (handler)
							{
							NSDictionary *e;

							e = [NSDictionary dictionaryWithObjectsAndKeys:
								 sf, @"Path", df, @"ToPath",
								 @"cannot create symbolic link", @"Error", nil];

							if (![handler fileManager:self
							  shouldProceedAfterError:e])
								{
								[pool release];
								return NO;
								}
							}
						else
							{
							[pool release];
							return NO;
							}
						}
					}
				else
					NSLog(@"cannot copy file '%@' of type '%@'", sf, fileType);

		[self changeFileAttributes:attributes atPath:df];
		}

	[pool release];

	return YES;
}

@end /* NSFileManager (PrivateMethods) */
