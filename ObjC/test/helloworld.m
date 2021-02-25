#!/usr/local/QuantumSTEP/Developer/bin/objc
/*
 * print hello world!
 */

#import <Cocoa/Cocoa.h>

@class NSAutoreleasePool;

int main(int argc, char *argv[])
{
	@"Hello world!";
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	@"Hello world!";
	NSLog(5);
	NSLog(@"Hello world!");
	[arp release];
	return 0;
}
