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
	/*
	 * implement these phases as loadable bundles that can be configured as a pipeline
	 * and use a default pipeline if nothing is specified elsewhere
	 */
#if 1
	NSLog(@"parse result:\n%@", n);	// print as xml
#endif
	[n simplify];
#if 1
	NSLog(@"simplified:\n%@", n);
#endif
	// choose how we should translate -> 1.0 -> 2.0 -> ARM -> Std-C
	[n objc10];	// translate to Obj-C 1.0
#if 1
	NSLog(@"translated:\n%@", n);
#endif
	printf("%s", [[n prettyObjC] UTF8String]);	// pretty print
	return 0;
}

