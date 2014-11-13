/* 
   NSFileWrapper.h

   NSFileWrapper objects hold a file's contents in dynamic memory.

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@ix.netcom.com>
   Date: Sept 1998
 
   Author:	Fabian Spillner
   Date:	23. October 2007
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	8. November 2007 - aligned with 10.5 

   This file is part of the GNUstep GUI Library.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
*/ 

#ifndef _GNUstep_H_NSFileWrapper
#define _GNUstep_H_NSFileWrapper

#import <Foundation/NSDictionary.h>
#import <AppKit/NSImage.h>

@class NSImage;
@class NSString;

#ifndef __APPLE__	// since 10.7 this is moved to Foundation

typedef enum
{
	GSFileWrapperDirectoryType,
	GSFileWrapperRegularFileType,
	GSFileWrapperSymbolicLinkType
} GSFileWrapperType;

@interface NSFileWrapper : NSObject 
{
	NSString		*_filename;
	NSString		*_preferredFilename;
	NSMutableDictionary	*_fileAttributes;
	GSFileWrapperType	_wrapperType;
	id	_wrapperData;
	id	_iconImage;
}

- (NSString *) addFileWithPath:(NSString *) path;
- (NSString *) addFileWrapper:(NSFileWrapper *) doc;
- (NSString *) addRegularFileWithContents:(NSData *) data 
                        preferredFilename:(NSString *) filename;
- (NSString *) addSymbolicLinkWithDestination:(NSString *) path 
                            preferredFilename:(NSString *) filename;
- (NSDictionary *) fileAttributes;
- (NSString *) filename;
- (NSDictionary *) fileWrappers;
- (id) initDirectoryWithFileWrappers:(NSDictionary *) docs;
- (id) initRegularFileWithContents:(NSData *) data;		 
- (id) initSymbolicLinkWithDestination:(NSString *) path;
- (id) initWithPath:(NSString *) path;	
- (id) initWithSerializedRepresentation:(NSData *) data;
- (BOOL) isDirectory;
- (BOOL) isRegularFile;
- (BOOL) isSymbolicLink;
- (NSString *) keyForFileWrapper:(NSFileWrapper *) doc;
- (BOOL) needsToBeUpdatedFromPath:(NSString *) path;
- (NSString *) preferredFilename;
- (NSData *) regularFileContents;
- (void) removeFileWrapper:(NSFileWrapper *) doc;
- (NSData *) serializedRepresentation;
- (void) setFileAttributes:(NSDictionary *) attributes;
- (void) setFilename:(NSString *) filename;
- (void) setPreferredFilename:(NSString *) filename;
- (NSString *) symbolicLinkDestination;
- (BOOL) updateFromPath:(NSString *) path;
- (BOOL) writeToFile:(NSString *) path
          atomically:(BOOL) atomicFlag
     updateFilenames:(BOOL) updateFilenamesFlag;

@end

#endif

@interface NSFileWrapper (Additions)
- (NSImage *) icon;
- (void) setIcon:(NSImage *) icon;
@end

#endif // _GNUstep_H_NSFileWrapper
