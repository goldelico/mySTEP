//
//  AppController.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on 11.11.05.
//  Copyright 2005 __MyCompanyName__. All rights reserved.
//

#import "AppController.h"
#import <Quartz/Quartz.h>	// imports PDFKit

int main(int argc, const char *argv[])
{
    return NSApplicationMain(argc, argv);
}

@implementation AppController

- (void) awakeFromNib;
{
	[self load:nil];
}

- (IBAction) load:(id) Sender;
{
	PDFDocument *doc;
	unsigned int i, cnt;
	doc=[[PDFDocument alloc] initWithURL:[NSURL URLWithString:@"file://localhost/Volumes/Data/hns/Documents/Projects/QuantumSTEP/System/Sources/PrivateFrameworks/PDFKit/Samples/Abschleppkran.pdf"]];
	NSLog(@"doc=%@", doc);
	cnt=[doc pageCount];
	for(i=0; i<cnt; i++)
		{
		NSLog(@"page %d: %@", i, [doc pageAtIndex:i]);
		NSLog(@"p[%u] %08x", i, [doc pageAtIndex:i]);
		NSLog(@"p[0] %08x", [doc pageAtIndex:0]);
		NSLog(@"p[%u] %08x", i, [doc pageAtIndex:i]);	// is it the same?
		NSLog(@"  data: %@", [[[NSString alloc] initWithData:[[doc pageAtIndex:i] dataRepresentation] encoding:NSASCIIStringEncoding] autorelease]);
		NSLog(@"  string: %@", [[doc pageAtIndex:i] string]);
		}
	[pdf setBackgroundColor:[NSColor blueColor]];
	[pdf setDocument:doc];
	[doc release];
}

@end
