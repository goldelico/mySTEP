//
// open.m
// QuantumSTEP
//
// launches myPDA applications
//    open [-a application] file/url ...		open by rules or application
//    open [-e] file/url ...					open by myTextEdit.app
//         [-n]									don't open but print paths to stdout
//		   [-p]									print file(s)
//		   [-t]									open temporary file
//		   [-x]									open without UI
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jul 25 2003.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void useage(const char *arg0)
{
	fprintf(stderr, "useage: %s [-a application] [-enptx] file/url ...\n", arg0);
	fprintf(stderr, "  -a application    application name (or identifier)\n");
	fprintf(stderr, "  -e                same as -a myText\n");
	fprintf(stderr, "  -n                don't open but print file names to stdout\n");
	fprintf(stderr, "  -p                print file(s)\n");
	fprintf(stderr, "  -t                open temporary file\n");
	fprintf(stderr, "  -x                open file without UI\n");
	fprintf(stderr, "  file/url          file name(s) and/or URL(s)\n");
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSString *app=nil;
	NSString *arg;
	NSURL *url;
	NSMutableArray *urls=[NSMutableArray arrayWithCapacity:20];
	const char *arg0=argv[0];
	BOOL nflag=NO;
	NSWorkspaceLaunchOptions opts=NSWorkspaceLaunchDefault;
	if(!argv[1])
		{
		useage(arg0);
		exit(1);
		}
	while(argv[1])
		{ // collect arguments
		if(argv[1][0] == '-')
			{
			const char *a=argv[1]+1;
			argv++;	// move to next arg
			while(*a++)
				{
				switch(a[-1])
					{
					case 'n':
						nflag=YES;
						break;
					case 'p':
						opts |= NSWorkspaceLaunchAndPrint;
						break;
					case 't':
						opts |= NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchNewInstance;
						break;
					case 'x':
						opts |= NSWorkspaceLaunchWithoutAddingToRecents;
						break;
					case 'e':
						app=@"myText";	// use myText.app
						break;
					case 'a':
						if(!argv[1])
							{
							fprintf(stderr, "missing application name for -a\n");
							exit(1);
							}
						app=[NSString stringWithUTF8String:argv[1]];
						argv++;
						break;
					default:
						useage(arg0);
						exit(1);
					}
				continue;	// next option
				}
			continue;	// next argument
			}
#if 0
		NSLog(@"open %s with %@", argv[1], app);
#endif
		arg=[NSString stringWithUTF8String:argv[1]];
		url=nil;
#if 0
		NSLog(@"  arg %@", arg);
		NSLog(@"  components %@", [arg componentsSeparatedByString:@":"]);
#endif
		if(![arg isAbsolutePath] && [[arg componentsSeparatedByString:@":"] count] == 2)
			url=[NSURL URLWithString:arg];	// assume that it is a URL
#if 0
		NSLog(@"url=%@", url);
		NSLog(@"fileSystemRepresentation=%s", [@"/" fileSystemRepresentation]);
		NSLog(@"fileSystemRepresentation=%s", [@"/tmp" fileSystemRepresentation]);
		NSLog(@"fileSystemRepresentation=%s", [@"/Users" fileSystemRepresentation]);
#endif
		if(!url)
			{ // prepare relative file names
			NSString *root=[NSString stringWithUTF8String:[@"/" fileSystemRepresentation]];
#if 0
			NSLog(@"root=%@", root);
#endif
			arg=[arg stringByExpandingTildeInPath];
			if(![arg isAbsolutePath])
				arg=[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:arg];   // prefix with current directory
			if([arg hasPrefix:root])
				arg=[arg substringFromIndex:[root length]-1];  // will be added back by file manager
			url=[NSURL fileURLWithPath:arg];
#if 0
			NSLog(@"arg=%@ url=%@", arg, url);
#endif
			}
		if(nflag)
			printf("%s\n", [[url absoluteString] UTF8String]);	// print file name only
		else
			[urls addObject:url];
		argv++;
		}
	if(!nflag && !app && [urls count] == 0)
		{ // simply launch application
		fprintf(stderr, "%s: neither application nor files defined\n", arg0);
		exit(1);
		}
	if(app && [urls count] == 0)
		{ // simply launch application
		opts |= NSWorkspaceLaunchNewInstance;
		}
	if(nflag)
		{
		// FIXME: look up application to launch
		NSString *p=[[NSWorkspace sharedWorkspace] fullPathForApplication:app];
		if(p)
			printf("%s\n", [p UTF8String]);
		else
			{
			fprintf(stderr, "%s: could not locate applicaton %s\n", arg0, [[app description] UTF8String]);
			exit(1);
			}
		}
	else
		{
		BOOL b=[[NSWorkspace sharedWorkspace] openURLs:urls	// might be empty
							   withAppBundleIdentifier:app	// might be nil
											   options:opts
						additionalEventParamDescriptor:NULL
									 launchIdentifiers:NULL];
		if(!b && app)
			{
			fprintf(stderr, "%s: could not launch applicaton %s\n", arg0, [[app description] UTF8String]);
			exit(1);
			}
		if(!b)
			{
			fprintf(stderr, "%s: could not open files\n", arg0);
#if 0
			NSLog(@"urls=%@", urls);
#endif
			exit(1);
			}
		}
	[pool release];
	exit(0);	// all done
}
