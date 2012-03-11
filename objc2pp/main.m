/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>
#import "AST.h"
#import "Printing.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	Node *n;
	if(argc == 2)
		{
		int fd=open(argv[1], 0);
		dup2(fd, 0);	// use this file as stdin
		}
	n=[Node parse:nil delegate:nil];
//	[n simplify];
//	[n makeobjc1];	// translate to Obj-C 1.0
	[n print];	// pretty print
	return 0;
}

