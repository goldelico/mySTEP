#!/usr/share/QuantumSTEP/Developer/bin/objc
/*
 * print hello world!
 */

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSLog(@"Hello world!");
	[arp release];
	return 0;
}