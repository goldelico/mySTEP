//
//  NSGlyphInfo.m
//  AppKit
//
//  Created by Fabian Spillner on 08.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSGlyphInfo.h"
#import "NSAppKitPrivate.h"


@implementation NSGlyphInfo

- (id) _initWithGlyph:(NSGlyph) glyph
			glyphName:(NSString *) name
		forCollection:(NSCharacterCollection) chars
	withCharacterIdentifier:(NSUInteger) identifier
			  forFont:(NSFont *) font 
		   baseString:(NSString *) string;
{
	if((self=[super init]))
		{
		_collection=chars;
		_identifier=identifier;
		_name=[name retain];
		}
	return self;
}

+ (NSGlyphInfo *) glyphInfoWithCharacterIdentifier:(NSUInteger) identifier 
										collection:(NSCharacterCollection) chars 
										baseString:(NSString *) string;
{
	return [[[self alloc] _initWithGlyph:0 glyphName:nil forCollection:chars withCharacterIdentifier:identifier forFont:nil baseString:string] autorelease];
}

+ (NSGlyphInfo *) glyphInfoWithGlyph:(NSGlyph) glyph 
							 forFont:(NSFont *) font 
						  baseString:(NSString *) string;
{
	return [[[self alloc] _initWithGlyph:glyph glyphName:nil forCollection:NSIdentityMappingCharacterCollection withCharacterIdentifier:0 forFont:font baseString:string] autorelease];
}

+ (NSGlyphInfo *) glyphInfoWithGlyphName:(NSString *) name 
								 forFont:(NSFont *) font 
							  baseString:(NSString *) string;
{
	return [[[self alloc] _initWithGlyph:[font glyphWithName:name] glyphName:name forCollection:NSIdentityMappingCharacterCollection withCharacterIdentifier:0 forFont:font baseString:string] autorelease];
}

- (void) dealloc
{
	[_name release];
	[super dealloc];
}

- (NSCharacterCollection) characterCollection; { return _collection; }
- (NSUInteger) characterIdentifier; { return _identifier; }
- (NSString *) glyphName; { return _name; }

- (void) encodeWithCoder:(NSCoder *) coder;
{
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder;
{
	return self;
}

@end
