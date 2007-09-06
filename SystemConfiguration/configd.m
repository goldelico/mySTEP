/*
 the manual page: http://developer.apple.com/documentation/Darwin/Reference/ManPages/man8/configd.8.html
 a description how configd works: http://www.afp548.com/article.php?story=20041015131913324
 about IPConfiguration.bundle: http://www.afp548.com/article.php?story=20050916014900714
*/

#include <Foundation/Foundation.h>
#include <signal.h>
#include <unistd.h>

#define BUNDLES_DIR @"/System/Library/SystemConfiguration/"
#define CONFIG_DIR @"/Library/Preferences/SystemConfiguration/"
#define SYS_CONFIG @"/Library/Preferences/SystemConfiguration/preferences.plist"
#define NET_CONFIG @"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"

void usage(char *str)
{
	if(str)
		fprintf(stderr, "configd: %s/n", str);
	fprintf(stderr, "configd: usage: [-bdv] [-B bundleID] [-V bundleID] [-t bundle-path]/n"
			"configd -b\n"				// don't load bundles
			"configd -B bundleID\n"		// prevent bundle(s) with ID from loading
			"configd -d\n"				// don't fork and run in foreground
			"configd -v\n"				// verbose mode
			"configd -V bundleID\n"		// verbose for bundle(s) with ID
			"configd -t bundle-path\n"	// load only bundle(s) specified by path
			);
	exit(1);
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSMutableArray *preventedBundles=[NSMutableArray arrayWithCapacity:10];
	NSMutableArray *verboseBundles=[NSMutableArray arrayWithCapacity:10];
	NSMutableArray *explicitBundles=[NSMutableArray arrayWithCapacity:10];
	BOOL dontLoad=NO;
	BOOL dontFork=NO;
	BOOL verbose=NO;
	if(!argv[1])
		usage(NULL);
	while(argv[1] != NULL)
		{
		if(argv[1][0]=='-')
			{ // option
			char *options=argv[1]+1;
			while(*options)
				{
				switch(*options++)
					{
					case 'b':
						dontLoad=YES;
						break;
					case 'd':
						dontFork=YES;
						break;
					case 'v':
						verbose=YES;
						break;
					case 'B':
					case 'V':
					case 't':
						{
							int cmd=options[-1];
							NSString *arg;
							if(!*options)
								argv++, options=argv[1];	// get next argument - otherwise all characters after option letter
							if(!options)
								usage("missing argument");
							arg=[NSString stringWithUTF8String:options];
							switch(cmd)
								{
								case 'B':
									[preventedBundles addObject:arg];
									break;
								case 'V':
									[verboseBundles addObject:arg];
									break;
								case 't':									
									[explicitBundles addObject:arg];
									break;
								default:
									usage("internal option error");
								}
							break;
						}
					default:
						usage("unrecognized option");
					}
				}
			argv++;
			}
		else
			usage("unrecognized argument");
		}
	if(!dontFork)
		{
		int pid;
		if(verbose)
			fprintf(stderr, "forking...\n");
		if((pid=fork()) != 0)
			{
			if(verbose)
				fprintf(stderr, "parent exits\n");
			return 0;	// parent is done
			}
		if(verbose)
			fprintf(stderr, "forked.\n");
		}
	else if(verbose)
		fprintf(stderr, "no forking\n");
	signal(SIGHUP, SIG_IGN);
	while(YES)
		{ // loop
		// monitor config file for changes
		}
	[arp release];
	return 0;
}
