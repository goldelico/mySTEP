//
//  NSEPSImageRep.h
//  AppKit
//
//  Created by Fabian Spillner on 08.11.07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/NSImageRep.h>

@class NSImageRep;

@interface NSEPSImageRep : NSImageRep 
{

}

+ (id)imageRepWithData:(NSData *) data; 

- (NSRect) boundingBox; 
- (NSData *) EPSRepresentation; 
- (id) initWithData:(NSData *) data; 
- (void) prepareGState; 

@end
