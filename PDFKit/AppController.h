//
//  AppController.h
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on 11.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class PDFView;

@interface AppController : NSObject
{
	IBOutlet PDFView *pdf;
}

- (IBAction) load:(id) Sender;

@end
