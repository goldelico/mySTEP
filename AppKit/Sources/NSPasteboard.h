/* 
   NSPasteboard.h

   Class to transfer data to and from the pasteboard server

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Scott Christley <scottc@net-community.com>
   Date: 	1996
 
   Author:	Fabian Spillner <fabian.spillner@gmail.com>
   Date:	14. December 2007 - aligned with 10.5 
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSPasteboard
#define _mySTEP_H_NSPasteboard

#import <Foundation/NSObject.h>
#import <Foundation/NSString.h>
#import <Foundation/NSURL.h>


@class NSString;
@class NSArray;
@class NSData;
@class NSMutableArray;
@class NSFileWrapper; 
@class NSURL; 

//
// Pasteboard global types
//
extern NSString *NSStringPboardType;
extern NSString *NSColorPboardType;
extern NSString *NSFileContentsPboardType;
extern NSString *NSFilenamesPboardType;
extern NSString *NSFontPboardType;
extern NSString *NSHTMLPboardType; 
extern NSString *NSPDFPboardType; 
extern NSString *NSPICTPboardType; 
extern NSString *NSPostScriptPboardType; 
extern NSString *NSRulerPboardType;
extern NSString *NSPostScriptPboardType;
extern NSString *NSTabularTextPboardType;
extern NSString *NSRTFPboardType;
extern NSString *NSRTFDPboardType;
extern NSString *NSTIFFPboardType;
extern NSString *NSDataLinkPboardType;
extern NSString *NSGeneralPboardType;
extern NSString *NSURLPboardType; 
extern NSString *NSVCardPboardType; 
extern NSString *NSFilesPromisePboardType; 
extern NSString *NSInkTextPboardType; 
extern NSString *NSMultipleTextSelectionPboardType; 

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
+ (NSPasteboard *) pasteboardByFilteringData:(NSData *) data
									  ofType:(NSString *) type;
+ (NSPasteboard *) pasteboardByFilteringFile:(NSString *) filename;
+ (NSPasteboard *) pasteboardByFilteringTypesInPasteboard:(NSPasteboard *) pb;
+ (NSPasteboard *) pasteboardWithName:(NSString *) name;
+ (NSPasteboard *) pasteboardWithUniqueName;															// Filter contents 
+ (NSArray *) typesFilterableTo:(NSString *) type;

- (NSInteger) addTypes:(NSArray *) newTypes owner:(id) newOwner;	// Writing Data
- (NSString *) availableTypeFromArray:(NSArray *) types;		// Available Types
- (NSInteger) changeCount;										// Reading Data
- (NSData *) dataForType:(NSString *) dataType;
- (NSInteger) declareTypes:(NSArray *) newTypes owner:(id) newOwner;
- (NSString *) name;										// Pasteboard Name
- (id) propertyListForType:(NSString *) dataType;
- (NSString *) readFileContentsType:(NSString *) type toFile:(NSString *) name;
- (NSFileWrapper *) readFileWrapper; 
- (void) releaseGlobally;
- (BOOL) setData:(NSData *) data forType:(NSString *) dataType;
- (BOOL) setPropertyList:(id) propertyList forType:(NSString *) dataType;
- (BOOL) setString:(NSString *) string forType:(NSString *) dataType;
- (NSString *) stringForType:(NSString *) dataType;
- (NSArray *) types;
- (BOOL) writeFileContents:(NSString *) filename;
- (BOOL) writeFileWrapper:(NSFileWrapper *) fileWrapper; 

@end


@interface NSObject (NSPasteboardDelegate)

- (void) pasteboard:(NSPasteboard *) sender provideDataForType:(NSString *) type;
- (void) pasteboardChangedOwner:(NSPasteboard *) sender;

@end

@interface NSURL (NSURLPasteboardAdditions)

+ (NSURL *) URLFromPasteboard:(NSPasteboard *) pboard;
- (void) writeToPasteboard:(NSPasteboard *) pboard;

@end

//
// Return File-related Pasteboard Types
//
NSString *NSCreateFileContentsPboardType(NSString *fileType);
NSString *NSCreateFilenamePboardType(NSString *filename);
NSString *NSGetFileType(NSString *pboardType);
NSArray  *NSGetFileTypes(NSArray *pboardTypes);

#endif /* _mySTEP_H_NSPasteboard */
