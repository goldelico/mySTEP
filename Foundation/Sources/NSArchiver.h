/* 
   NSArchiver.h

   Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
   All rights reserved.

   Author: Ovidiu Predescu <ovidiu@bx.logicnet.ro>

   H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	01. April 2008 - aligned with 10.5
 
   This file is part of the mySTEP Library and is provided under the 
   terms of the libFoundation BSD type license (See the Readme file).
*/

#ifndef _mySTEP_H_NSArchiver
#define _mySTEP_H_NSArchiver

#import <Foundation/NSCoder.h>
#import <Foundation/NSHashTable.h>
#import <Foundation/NSMapTable.h>

@class NSMutableDictionary;
@class NSData;
@class NSMutableData;

@interface NSArchiver : NSCoder
{
    NSMutableData *mdata;
    NSHashTable *objects;		// objects written so far
    NSHashTable *conditionals;	// conditional objects
    NSMapTable *classes;		// real classname -> class info
    NSHashTable *pointers;		// set of pointers
    IMP writeIMP;				// write IMP of mdata
    BOOL writingRoot;			// YES if encodeRootObject: was sent
    BOOL findingConditionals;	// YES if finding conditionals
}

+ (NSData *) archivedDataWithRootObject:(id) rootObject;
+ (BOOL) archiveRootObject:(id) rootObject toFile:(NSString *) path;

- (NSMutableData *) archiverData;
- (NSString *) classNameEncodedForTrueClassName:(NSString *) trueName;
- (void) encodeClassName:(NSString *) trueName
		   intoClassName:(NSString *) inArchiveName;
- (void) encodeConditionalObject:(id) obj
- (void) encodeRootObject:(id) rootObject;
- (id) initForWritingWithMutableData:(NSMutableData *) mdata;
- (void) replaceObject:(id) object withObject:(id) newObject;

@end /* NSArchiver */

extern NSString * NSInconsistentArchiveException;

@interface NSUnarchiver : NSCoder
{
    NSData *rdata;
    unsigned cursor;
    IMP readIMP;				// read function of encodingFormat
    unsigned archiverVersion;	// archiver's version that wrote the data
    NSMapTable *objects;		// decoded objects: key -> object
    NSMapTable *classes;		// decoded classes: key -> class info
    NSMapTable *pointers;		// decoded pointers: key -> pointer
    NSMapTable *classAlias;		// archive name -> decoded name
    NSMapTable *classVersions;	// archive name -> class info
	
}

+ (NSString*) classNameDecodedForArchiveClassName:(NSString*)nameInArchive;
+ (void) decodeClassName:(NSString*)nameInArchive
			 asClassName:(NSString*)trueName;
+ (id) unarchiveObjectWithData:(NSData*)data;			// Decoding Objects
+ (id) unarchiveObjectWithFile:(NSString*)path;

- (NSString*) classNameDecodedForArchiveClassName:(NSString*)nameInArchive;
- (void) decodeClassName:(NSString*)nameInArchive
			 asClassName:(NSString*)trueName;
- (id) initForReadingWithData:(NSData*)data;
- (void) replaceObject:(id)object withObject:(id)newObject;

@end

@interface NSObject (NSArchiver)
- (Class) classForArchiver;
- (Class) classForKeyedArchiver;
- (id) replacementObjectForArchiver:(NSArchiver*) anEncoder;
@end

#endif /* _mySTEP_H_NSArchiver */
