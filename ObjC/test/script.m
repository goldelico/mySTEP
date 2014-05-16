#!/usr/share/QuantumSTEP/Developer/bin/objc
/*
 * this is an Obj-C script
 * i.e. a source file that can simply be called
 * from the shell command line (the suffix .m is arbitrary):
 *
 * script.m parameters...
 *
 * If enabled, it will store a binary intermediate file
 * as script.mobjc so that the source needs to be reparsed
 * only if modified.
 *
 * or it can be compiled into a binary
 */

#import <Cocoa/Cocoa.h>

int x;
int y=5;

int main()
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSLog(@"hello world");
	NSLog(@"x=%d y=%d", x, y);
	[arp release];
	exit(0);
}