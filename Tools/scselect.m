/*
 the manual page: http://developer.apple.com/documentation/Darwin/Reference/ManPages/man8/scselect.8.html
 a description how configd works: http://www.afp548.com/article.php?story=20041015131913324
*/

#import <Foundation/Foundation.h>
#ifdef __mySTEP__

// FIXME: should not be part of SYSNetwork but a SC.framework

#import <SystemStatus/SYSNetwork.h>
#endif

// or we should directly access the relvant system files and
// notify configd by a signal to read the config file and reconfigure itself

// YES! we should be suid-root so that we can write into the config file!

#define SYS_CONFIG @"/Library/Preferences/SystemConfiguration/preferences.plist"	// we should change entry "CurrentSet"

void usage(char *str)
{
	if(str)
		fprintf(stderr, "scselect: %s\n", str);
	fprintf(stderr, "usage: scselect [-n] [new-location-name]\n");
	exit(1);
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
#ifdef __mySTEP__
	NSString *selectedLocation;
#endif
	NSString *arg;
	NSEnumerator *e;
//	if(!argv[1])
//		usage(NULL);
	e=[[[NSProcessInfo processInfo] arguments] objectEnumerator];
	[e nextObject];	// skip argv[0]
	while((arg=[e nextObject]))
		{
		if(![arg hasPrefix:@"-"])
			break;	// first non-option
		if([arg isEqualToString:@"-n"])
			continue;
		usage(NULL);
		}
	if(arg)
		{ // should be new location name
		if([e nextObject])
			usage("extra argument");
#ifdef __mySTEP__
		// FIXME: handle change on next boot - needs to update API
		[SYSNetwork selectLocation:arg /* onNextReboot:[[NSUserDefaults standardUserDefaults] objectForKey:@"n"] != nil */];
		if([[SYSNetwork selectedLocation] isEqualToString:arg])
			{ // ok
			// FIXME: handle unique identifier - needs to update API
			printf("CurrentSet updated to <uid> (%s)\n", [arg UTF8String]);
			[arp release];
			return 0;
			}
		fprintf(stderr, "Set \"%s\" not available.\n\n", [arg UTF8String]), exit(1);
#endif
		}
#ifdef __mySTEP__
	selectedLocation=[SYSNetwork selectedLocation];
	e=[[SYSNetwork networkLocationsList] objectEnumerator];
	fprintf(stderr, "Defined sets include: (* == current set)\n");
	while((arg=[e nextObject]))
		{
		if([arg isEqualToString:selectedLocation])
			fprintf(stderr, " * <uid> (%s)\n", [arg UTF8String]);
		else
			fprintf(stderr, "   <uid> (%s)\n", [arg UTF8String]);
		}
#endif
	[arp release];
	return 0;
}
