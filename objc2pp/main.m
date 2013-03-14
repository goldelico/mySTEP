/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>
#import "Print.h"
#import "Simplify.h"
#import "objc10.h"

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	Node *n;
	if(argc == 2)
		{
		int fd=open(argv[1], 0);
		dup2(fd, 0);	// use this file as stdin
		}
//	n=[Node parse:nil delegate:nil];	// gives linker error but I don't know why
	n=[NSClassFromString(@"Node") parse:nil delegate:nil];
	n=[n simplify];
	n=[n objc10];	// translate to Obj-C 1.0
	printf("%s", [[n description] cString]);	// pretty print
	return 0;
}

