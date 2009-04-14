//
//  NSPathComponentCell.h
//  AppKit
//
//  Created by Fabian Spillner on 29.11.07.
//  Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <AppKit/NSTextFieldCell.h>

@class NSImage; 

@interface NSPathComponentCell : NSTextFieldCell 
{
	NSImage *_image;
	NSURL *_URL;
}

- (NSImage *) image;
- (void) setImage:(NSImage *) image;
- (void) setURL:(NSURL *) url;
- (NSURL *) URL; 

@end
