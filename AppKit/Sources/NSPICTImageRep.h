//
//  NSPICTImageRep.h
//  AppKit
//
//  Created by Fabian Spillner on 29.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <AppKit/NSImageRep.h>


@interface NSPICTImageRep : NSImageRep {

}

+ (id) imageRepWithData:(NSData *) data; 

- (NSRect) boundingBox; 
- (id) initWithData:(NSData *) data; 
- (NSData *) PICTRepresentation; 

@end
