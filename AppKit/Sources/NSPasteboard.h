/* 
   NSPasteboard.h

   Class to transfer data to and from the pasteboard server

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 	1996
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPasteboard
#define _mySTEP_H_NSPasteboard

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>

@class NSString;
@class NSArray;
@class NSData;
@class NSMutableArray;

//
// Pasteboard global types
//
extern NSString *NSStringPboardType;
extern NSString *NSColorPboardType;
extern NSString *NSFileContentsPboardType;
extern NSString *NSFilenamesPboardType;
extern NSString *NSFontPboardType;
extern NSString *NSRulerPboardType;
extern NSString *NSPostScriptPboardType;
extern NSString *NSTabularTextPboardType;
extern NSString *NSRTFPboardType;
extern NSString *NSRTFDPboardType;
extern NSString *NSTIFFPboardType;
extern NSString *NSDataLinkPboardType;
extern NSString *NSGeneralPboardType;

//
// Pasteboard global names
//
extern NSString *NSDragPboard;
extern NSString *NSFindPboard;
extern NSString *NSFontPboard;
extern NSString *NSGeneralPboard;
extern NSString *NSRulerPboard;

//
// Pasteboard Exceptions
//
extern NSString *NSPasteboardCommunicationException;


@interface NSPasteboard : NSObject
{
    NSString *_name;	// name of this pasteboard.
    int _changeCount;	// What we think the current count is.
    id _target;			// Proxy to the object in the server.
    id _owner;			// Local pasteboard owner.
	NSArray *_types;
    NSMutableArray *_typesProvided;
}

+ (NSPasteboard *) generalPasteboard;
+ (NSPasteboard *) pasteboardWithName:(NSString *)name;
+ (NSPasteboard *) pasteboardWithUniqueName;
- (void) releaseGlobally;
															// Filter contents 
+ (NSPasteboard *) pasteboardByFilteringData:(NSData *)data
									 ofType:(NSString *)type;
+ (NSPasteboard *) pasteboardByFilteringFile:(NSString *)filename;
+ (NSPasteboard*) pasteboardByFilteringTypesInPasteboard:(NSPasteboard *)pb;
+ (NSArray *) typesFilterableTo:(NSString *)type;

- (NSString *) name;										// Pasteboard Name

- (int) addTypes:(NSArray *)newTypes owner:(id)newOwner;	// Writing Data
- (int) declareTypes:(NSArray *)newTypes owner:(id)newOwner;
- (BOOL) setData:(NSData *)data forType:(NSString *)dataType;
- (BOOL) setPropertyList:(id)propertyList forType:(NSString *)dataType;
- (BOOL) setString:(NSString *)string forType:(NSString *)dataType;
- (BOOL) writeFileContents:(NSString *)filename;

- (NSString *) availableTypeFromArray:(NSArray *)types;		// Available Types
- (NSArray *) types;

- (int) changeCount;										// Reading Data
- (NSData *) dataForType:(NSString *)dataType;
- (id) propertyListForType:(NSString *)dataType;
- (NSString *) readFileContentsType:(NSString *)type toFile:(NSString *)name;
- (NSString *) stringForType:(NSString *)dataType;

@end


@interface NSObject (NSPasteboardOwner)

- (void) pasteboard:(NSPasteboard *)sender provideDataForType:(NSString *)type;
- (void) pasteboardChangedOwner:(NSPasteboard *)sender;

@end

//
// Return File-related Pasteboard Types
//
NSString *NSCreateFileContentsPboardType(NSString *fileType);
NSString *NSCreateFilenamePboardType(NSString *filename);
NSString *NSGetFileType(NSString *pboardType);
NSArray  *NSGetFileTypes(NSArray *pboardTypes);

#endif /* _mySTEP_H_NSPasteboard */
