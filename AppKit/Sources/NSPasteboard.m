/*
   NSPasteboard.m

   Manage cut/copy/paste operations.

   Copyright (C) 1997 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    August 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <AppKit/NSPasteboard.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSWorkspace.h>

#import <Foundation/NSArray.h>
#import <Foundation/NSData.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSException.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSTimer.h>

//
// Class variables
//
static NSMutableDictionary *__pasteboards = nil;
static NSString *_contentsPrefix = @"NSTypedFileContentsPboardType:";
static NSString *_namePrefix = @"NSTypedFilenamesPboardType:";


@implementation NSPasteboard

+ (NSPasteboard *) generalPasteboard
{
	return [self pasteboardWithName: NSGeneralPboard];
}

+ (NSPasteboard *) pasteboardWithName:(NSString *)aName
{
NSPasteboard *pb;

	if(!(pb = [__pasteboards objectForKey: aName]))
		{
		pb = [NSPasteboard new];
		pb->_name = aName;

		if(!__pasteboards)
			__pasteboards = [[NSMutableDictionary alloc] initWithCapacity:8];
		[__pasteboards setObject:pb forKey:aName];
		}

	return pb;
}

+ (NSPasteboard *) pasteboardWithUniqueName
{
NSProcessInfo *p = [NSProcessInfo processInfo];

	return [self pasteboardWithName:[p globallyUniqueString]];
}
															// Filter contents
+ (NSPasteboard *) pasteboardByFilteringData:(NSData *)data
									  ofType:(NSString *)type
{
	return nil;
}

+ (NSPasteboard *) pasteboardByFilteringFile:(NSString *)filename
{
	// NSData *data = [NSData dataWithContentsOfFile:filename];
	// NSString *type = NSCreateFileContentsPboardType([filename pathExtension]);

	return nil;
}

+ (NSPasteboard *) pasteboardByFilteringTypesInPasteboard:(NSPasteboard *)pb
{
	return nil;
}

+ (NSArray *) typesFilterableTo:(NSString *)type
{
NSArray *types = nil;

	return types;
}

- (void) dealloc
{
	[_target release];
	[_name release];
	[_owner release];
	[super dealloc];
}

- (void) releaseGlobally
{
	[_target releaseGlobally];
	[__pasteboards removeObjectForKey: _name];
}

- (NSString *) name						{ return _name; }
- (NSArray *) types						{ return _types; }
- (int) changeCount						{ return _changeCount; }

- (int) addTypes:(NSArray *)newTypes owner:(id)newOwner
{
	ASSIGN(_owner, newOwner);
	ASSIGN(_types, [_types arrayByAddingObjectsFromArray: newTypes]);
	[_typesProvided addObjectsFromArray: newTypes];

	return _changeCount++;
}

- (int) declareTypes:(NSArray *)newTypes owner:(id)newOwner
{
	ASSIGN(_types, newTypes);
	ASSIGN(_typesProvided, [_types mutableCopy]);
	ASSIGN(_owner, newOwner);

	return _changeCount++;
}

- (BOOL) setData:(NSData *)data forType:(NSString *)dataType
{
	return NO;
}

- (BOOL) setPropertyList:(id)propertyList forType:(NSString *)dataType
{
int i = [_types indexOfObjectIdenticalTo:dataType];

	[_typesProvided replaceObjectAtIndex:i withObject:propertyList];

	return YES;
}

- (BOOL) setString:(NSString *)string forType:(NSString *)dataType
{
	return [self setPropertyList:string forType:dataType];
}

- (NSString *) availableTypeFromArray:(NSArray *)types
{
	if (!_types)		// FIX ME hack for paste in app that did not copy/cut
		_types = [[NSArray arrayWithObjects: NSStringPboardType, nil] retain];

	return [_types firstObjectCommonWithArray:types];
}

- (NSData *) dataForType:(NSString *)dataType
{
	return nil;
}

- (id) propertyListForType:(NSString *)dt
{
	if (!_owner)
		{
		NSMutableDictionary *d = [NSMutableDictionary new];
		NSMutableArray *files = [NSMutableArray new];
		NSString *s = [self stringForType:dt];
		
		NSLog(@"********* propertyListForType: %@\n",dt);
		
		[files addObject:s];
		[d setObject:s forKey:@"SourcePath"];
		[d setObject:files forKey:@"SelectedFiles"];
		
		return d;
		}
	
	[_owner pasteboard:self provideDataForType:dt];
	
	return [_typesProvided objectAtIndex:[_types indexOfObjectIdenticalTo:dt]];
}

- (NSString *) stringForType:(NSString *)dataType
{
	return [self propertyListForType: dataType];
}

- (BOOL) writeFileContents:(NSString *)filename
{
// NSData *data = [NSData dataWithContentsOfFile:filename];
// NSString *type = NSCreateFileContentsPboardType([filename pathExtension]);

	return NO;
}

- (NSString *) readFileContentsType:(NSString *)type
							 toFile:(NSString *)filename
{
NSData *d;

	if (type == nil) 
		type = NSCreateFileContentsPboardType([filename pathExtension]);

	d = [self dataForType: type];
	if ([d writeToFile: filename atomically: NO] == NO) 
		return nil;

	return filename;
}

@end /* NSPasteboard */


NSString *
NSCreateFileContentsPboardType(NSString *fileType)
{
	return [NSString stringWithFormat:@"%@%@", _contentsPrefix, fileType];
}

NSString *
NSCreateFilenamePboardType(NSString *filename)
{
	return [NSString stringWithFormat:@"%@%@", _namePrefix, filename];
}

NSString *
NSGetFileType(NSString *pboardType)
{
	if ([pboardType hasPrefix: _contentsPrefix]) 
		return [pboardType substringFromIndex: [_contentsPrefix length]];

	if ([pboardType hasPrefix: _namePrefix]) 
		return [pboardType substringFromIndex: [_namePrefix length]];

	return nil;
}

NSArray *
NSGetFileTypes(NSArray *pboardTypes)
{
NSMutableArray *a = [NSMutableArray arrayWithCapacity: [pboardTypes count]];
unsigned int i;

	for (i = 0; i < [pboardTypes count]; i++) 
		{
		NSString *s = NSGetFileType([pboardTypes objectAtIndex:i]);
	
		if (s && ! [a containsObject:s]) 
			[a addObject:s];
		}

	if ([a count] > 0) 
		return [[a copy] autorelease];

	return nil;
}
