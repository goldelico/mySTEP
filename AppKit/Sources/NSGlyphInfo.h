//
//  NSGlyphInfo.h
//  AppKit
//
//  Created by Fabian Spillner on 08.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
	NSIdentityMappingCharacterCollection = 0,
	NSAdobeCNS1CharacterCollection       = 1,
	NSAdobeGB1CharacterCollection        = 2,
	NSAdobeJapan1CharacterCollection     = 3,
	NSAdobeJapan2CharacterCollection     = 4,
	NSAdobeKorea1CharacterCollection     = 5,
} NSCharacterCollection;

@interface NSGlyphInfo : NSObject {

}

+ (NSGlyphInfo *) glyphInfoWithCharacterIdentifier:(NSUInteger) identifier 
										collection:(NSCharacterCollection) charCollection 
										baseString:(NSString *) string;
+ (NSGlyphInfo *) glyphInfoWithGlyph:(NSGlyph) glyph 
							 forFont:(NSFont *) font 
						  baseString:(NSString *) string;
+ (NSGlyphInfo *) glyphInfoWithGlyphName:(NSString *) name 
								 forFont:(NSFont *) font 
							  baseString:(NSString *) string;

- (NSCharacterCollection) characterCollection;
- (NSUInteger) characterIdentifier;
- (NSString *) glyphName;


@end
