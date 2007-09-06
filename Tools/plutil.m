#include <Foundation/Foundation.h>

void usage(char *str)
{
	if(str)
		fprintf(stderr, "plutil: %s\n", str);
	fprintf(stderr, "usage:\n"
			"plutil [command_option] [other_options] file ...\n"
			"        -help\n"
			"        -lint\n" // default if no other
			"        -convert fmt\n"
			"                 xml\n"
			"                 binary\n"
			"                        --\n"
			"                        -s\n"
			"                        -o\n"
			"                        -e extension\n"
		    "        -list file\n"
		    "        -format file\n"
		    "        -get keypath file\n"
		    "        -type keypath file\n"
		    "        -set keypath value file\n"	// value is an old style PLIST!
		    "        -bool keypath value file\n"
		    "        -int keypath value file\n"
		    "        -float keypath value file\n"
		    "        -double keypath value file\n"
		    "        -time keypath value file\n"
		    "        -uid keypath value file\n"
		    "        -array keypath file\n"
		    "        -dict keypath file\n"
			 );
	exit(str?1:0);
}

static NSPropertyListFormat format;
static id plist;
static NSString *filePath;

void readfromfile(char *path)
{
	NSString *error;
	NSData *data;
	NSString *root=[NSString stringWithUTF8String:[@"/" fileSystemRepresentation]];
	if(!path)
		usage("missing file");
//	NSLog(@"cwd=%@", [[NSFileManager defaultManager] currentDirectoryPath]);
	filePath=[[NSString stringWithUTF8String:path] stringByExpandingTildeInPath];
	if(![filePath isAbsolutePath])
		filePath=[[[NSFileManager defaultManager] currentDirectoryPath] stringByAppendingPathComponent:filePath];   // prefix with current directory
//	NSLog(@"filePath=%@", filePath);
//	NSLog(@"root=%@", root);
	if([filePath hasPrefix:root])
		filePath=[filePath substringFromIndex:[root length]-1];  // will be added back by file manager
//	NSLog(@"filePath=%@", filePath);
//	system("pwd");
	data=[NSData dataWithContentsOfFile:filePath];
	if(!data)
		{
		printf("could not read plist from %s\n", [filePath UTF8String]);
		exit(1);
		}
	plist=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&error];
	if(!plist)
		{
		printf("could not parse plist due to %s\n", [error UTF8String]);
		exit(1);
		}
}

void writetofile()
{
	NSString *error;
	NSData *data;
	data=[NSPropertyListSerialization dataFromPropertyList:plist format:format errorDescription:&error];
	if(!data)
		{
		printf("could not convert plist due to %s\n", [error UTF8String]);
		exit(1);
		}
	if(![data writeToFile:filePath atomically:YES])
		{
		printf("could not write plist to %s\n", [filePath UTF8String]);
		exit(1);
		}
	exit(0);
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSString *keypath;
	char *cmd;
//	NSLog(@"plutil");
#if 1
	{
		id plist=[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:17.0], @"the key", nil];
		NSString *err;
		[NSPropertyListSerialization dataFromPropertyList:plist format:NSPropertyListBinaryFormat_v1_0 errorDescription:&err];
		exit(0);
	}
#endif
	if(!argv[1] || strcmp(argv[1], "-help") == 0)
		usage(NULL), exit(0);
	if(strcmp(argv[1], "-convert") == 0)
		{
		// handle convert command
		// readfromfile
		// update format
		// writetofile
		fprintf(stderr, "not implemented\n");
		exit(1);
		}
	if(strcmp(argv[1], "-format") == 0)
		{ // -format file
		readfromfile(argv[2]);
		switch(format)
			{
			case NSPropertyListOpenStepFormat:	printf("openstep\n"); break;
			case NSPropertyListXMLFormat_v1_0:	printf("xml1\n"); break;
			case NSPropertyListBinaryFormat_v1_0:	printf("binary1\n"); break;
			default: printf("unknown %d\n", format); break;
			}
		exit(0);
		}
	if(strcmp(argv[1], "-list") == 0)
		{ // -list file
		readfromfile(argv[2]);
		printf("%s\n", [[plist description] UTF8String]);
		exit(0);
		}
	if(strcmp(argv[1], "-get") == 0 ||
	   strcmp(argv[1], "-type") == 0 ||
	   strcmp(argv[1], "-array") == 0 ||
	   strcmp(argv[1], "-dict") == 0)
		{ // -cmd keypath file
		cmd=argv[1];
		if(!argv[2])
			usage("missing keypath");
		keypath=[NSString stringWithUTF8String:argv[2]];
		readfromfile(argv[3]);
		if(strcmp(argv[1], "-get") == 0)
			{
			printf("%s\n", [[plist valueForKey:keypath] UTF8String]);
			exit(0);
			}
		if(strcmp(argv[1], "-type") == 0)
			{
			printf("%s\n", [NSStringFromClass([plist valueForKey:keypath]) UTF8String]);
			exit(0);
			}
		if(strcmp(argv[1], "-array") == 0)
			{
			[plist setValue:[NSMutableArray array] forKey:keypath];
			writetofile();
			}
		if(strcmp(argv[1], "-dict") == 0)
			{
			[plist setValue:[NSMutableDictionary dictionary] forKey:keypath];
			writetofile();
			}
		}
	if(strcmp(argv[1], "-set") == 0 ||
	   strcmp(argv[1], "-bool") == 0 ||
	   strcmp(argv[1], "-int") == 0 ||
	   strcmp(argv[1], "-float") == 0 ||
	   strcmp(argv[1], "-double") == 0 ||
	   strcmp(argv[1], "-time") == 0 ||
	   strcmp(argv[1], "-uid") == 0)
		{ // -cmd keypath value file
		cmd=argv[1];
		exit(1);
		}
	if(strcmp(argv[1], "-lint") == 0)
		argv++;
	readfromfile(argv[1]);
#if OLD
	if(!create && !data)
		fprintf(stderr, "can't read file: %s\n", file), exit(1);
	plutil=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:NSPropertyListMutableContainersAndLeaves format:&format errorDescription:&error];
	if(!create && !plutil)
		fprintf(stderr, "can't read as property list: %s\n", file), exit(1);
	if(!plutil)
		plutil=[NSMutableDictionary dictionaryWithCapacity:10];	// create root object
	argv++;
	while(argv[1])
		{
		BOOL type=NO;
		NSString *keypath;
		if(argv[1] && strcmp(argv[1], "-t"))
			type=YES, argv++;
		keypath=[NSString stringWithUTF8String:argv[1]];
		if(!keypath)
			usage("missing keypath");
		argv++;
		if(argv[1] && argv[1][0] == '=')
			{ // assignment
			id newval=nil;
			char *cmd=argv[1];
			argv++;
			if(strcmp(cmd, "=a"))
				newval=[NSMutableArray arrayWithCapacity:10];
			else if(strcmp(cmd, "=d"))
				newval=[NSMutableDictionary dictionaryWithCapacity:10];
			else if(strcmp(cmd, "=b"))
				{
				BOOL bval=NO;
				if(!argv[1])
					usage("missing boolean value");
				if((strcmp(argv[1], "true") == 0) ||
				   (strcmp(argv[1], "yes") == 0))
					bval=YES;
				argv++;
				newval=[NSNumber numberWithBool:bval];
				}
			else if(strcmp(cmd, "=i"))
				{
				int ival;
				if(!argv[1])
					usage("missing integer value");
				ival=atoi(argv[1]);
				argv++;
				newval=[NSNumber numberWithInt:ival];
				}
			// usw...
			[plutil setValue:newval forKeyPath:keypath];
			}
		else
			{ // print value or type
			id val = [plutil valueForKeyPath:keypath];
			if(type)
				printf("%s\n", [NSStringFromClass([val class]) UTF8String]);
			else
				printf("%s\n", [[val description] UTF8String]);
			}
		}
#endif
	// if any change, write back
	[arp release];
	return 0;
}
