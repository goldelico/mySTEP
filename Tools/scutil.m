/*
 the manual page: http://developer.apple.com/documentation/Darwin/Reference/ManPages/man8/scutil.8.html
 a description how configd works: http://www.afp548.com/article.php?story=20041015131913324
 about IPConfiguration.bundle: http://www.afp548.com/article.php?story=20050916014900714
*/

#import <Foundation/Foundation.h>
#ifdef __mySTEP__
#import <SystemStatus/SYSNetwork.h>
#endif

#define BUNDLES_DIR @"/System/Library/SystemConfiguration/"
#define CONFIG_DIR @"/Library/Preferences/SystemConfiguration/"
#define SYS_CONFIG @"/Library/Preferences/SystemConfiguration/preferences.plist"
#define NET_CONFIG @"/Library/Preferences/SystemConfiguration/NetworkInterfaces.plist"

void usage(char *str)
{
	if(str)
		fprintf(stderr, "scutil: %s\n", str);
	fprintf(stderr,
			"scutil usage:\n"
			"scutil\n"
			"scutil -r { nodename | address | local-address remote-address }\n"
			"scutil -w dynamic-store-key [-t timeout]\n"
			"scutil --get pref\n"
			"scutil --set pref [newval]\n"
			);
	exit(1);
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	usage(NULL);
	[arp release];
	return 0;
}
