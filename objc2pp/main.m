/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>
#import "AST.h"
#import "Printing.h"

main()
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	Node *n=[Node parse:nil delegate:nil];
//	[n simplify];
//	[n makeobjc1];	// translate to Obj-C 1.0
	[n print];	// pretty print
}

