/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>
#import <ObjCKit/ObjcKit.h>

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
	NSLog(@"parse result: %@", [n xml]);
	[n simplify];
	NSLog(@"simplified: %@", [n xml]);
	// choose how we should translate -> 1.0 -> 2.0 -> ARM -> Std-C
	[n objc10];	// translate to Obj-C 1.0
	NSLog(@"translated: %@", [n xml]);
	printf("%s", [[n pretty] cString]);	// pretty print
	return 0;
}

