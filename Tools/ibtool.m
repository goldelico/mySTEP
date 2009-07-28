/* 
 * mdo - manage distributed objects
 *
 * mdo [-s host] name -r											get root proxy reference
 * mdo [-s host] name -m ref selector				get method signature of referred object
 * mdo [-s host] name ref selector args...   invoke method of referred object
 * mdo -l     list local MessagePort names
 */

#include <Foundation/Foundation.h>

void usage(void)
{
	fprintf(stderr, "usage: mdo server:port args...\n");
	exit(1);
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool	*arp = [NSAutoreleasePool new];
	NSConnection *conn;
	NSArray *args=[[NSProcessInfo processInfo] arguments];
	int i=2;
#if 1
	NSLog(@"%@", args);
#endif
	if([args count] < 2)
		usage();
	if([[args objectAtIndex:1] isEqualToString:@"-l"])
			{
				NSEnumerator *e=[[[NSFileManager defaultManager] directoryContentsAtPath:[NSTemporaryDirectory() stringByAppendingPathComponent:@".QuantumSTEP"]] objectEnumerator];	// directory of message ports
				NSString *name;
				if([args count] != 2)
					usage();
				while((name=[e nextObject]))
					printf("%s\n", [name UTF8String]);
				[arp release];
				exit(0);
			}
	if([[args objectAtIndex:1] isEqualToString:@"-s"])
			{ // -s host name - use SocketPort
				if([args count] < 4)
					usage();
				conn=[NSConnection connectionWithRegisteredName:[args objectAtIndex:3] host:[args objectAtIndex:2] usingNameServer:0];	// -s "" is local host; -s "*" all local hosts
				i=4;
			}
	else
			conn=[NSConnection connectionWithReceivePort:nil sendPort:[[NSMessagePortNameServer sharedInstance] portForName:[args objectAtIndex:1]]];	// local
	if(!conn)
			{
				fprintf(stderr, "can't connect\n");
				[arp release];
				exit(1);
			}
	while(i < [args count])
			{
				NSString *arg=[args objectAtIndex:i];
				if([arg isEqualToString:@"-r"])
						{
							printf("%s", [[[conn rootProxy] description] UTF8String]);
						}
				else if([arg isEqualToString:@"-m"])
						{
						}
				else
					usage();	// unknown
				i++;
			}
	[arp release];
	exit(0);
}

