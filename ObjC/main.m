/* part of objc2pp - an obj-c 2 preprocessor */

/* this is the compiler frontend
 * it can be used to run in script execution mode like
 *
 * objc file.m
 *
 * or in compiler mode as
 *
 * objc -c -o a.out file.m
 *
 * a script may begin with #!/path-to-objc
 * and if chmod +x is set, the script can be simply
 * executed by specifying its name
 *
 * the script arguments are available through NSProcessInfo
 *
 * PS: you can also interpret C programs since C is a subset of ObjC
 */

#import <Cocoa/Cocoa.h>
#import <ObjCKit/ObjcKit.h>

static void usage(void)
{
	fprintf(stderr, "usage: objc [ -cdlp ] [ file... ]\n");
	exit(1);
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	Node *n;
	BOOL lint=NO;		// -l
	BOOL pretty=NO;		// -p
	BOOL compile=NO;	// -c
	BOOL precompile=NO;
	while(argv[1] && argv[1][0] == '-')
		{
		char *c=&argv[1][1];
		while(*c)
			{
			switch(*c++) {
				case 'l': lint=YES; break;
				case 'p': pretty=YES; break;
					// FIXME: allow setting --pretty-spaciness --max-line-length etc.
				case 'c': compile=YES; break;
					// case 'b' install pipeline bundle
				case 'd': {
					extern int yydebug;
					if(_debug) yydebug=1;
					_debug=YES; break;
				}
				case 'I':
				default:
					usage();
			}
			}
		argv++;
		}
	precompile=!lint && !pretty && !compile;	// we run in script mode and should store a binary AST for faster execution
	if(argv[1])
		{
		char first[512];
		int l;
		n=nil;
		NSString *object=nil;
		if(precompile)
			{
			NSFileManager *fm=[NSFileManager defaultManager];
			NSString *source;
			NSDictionary *sattribs;
			NSDictionary *oattribs;
			source=[fm stringWithFileSystemRepresentation:argv[1] length:strlen(argv[1])];
			if([[source pathExtension] length] > 0)
				object=[source stringByAppendingString:@"objc"];	// extend suffix
			else
				object=[source stringByAppendingPathExtension:@"objc"];	// first suffix
			// we may also prefix the object path to e.g. /tmp/objc and mkdir -p $(dirname $object))
			// the prefix could be made configurable (through NSUserDefaults)
			if(_debug) NSLog(@"%@ -> %@", source, object);
			sattribs=[fm attributesOfItemAtPath:source error:NULL];
			oattribs=[fm attributesOfItemAtPath:object error:NULL];
			if(_debug) NSLog(@"%@ -> %@", sattribs, oattribs);
			if(oattribs && [[sattribs fileModificationDate] compare:[oattribs fileModificationDate]] != NSOrderedDescending)
				{ // source is older so we don't need to recompile
				n=[Node nodeWithContentsOfFile:object];
				}
			}
		if(!n)
			{
			int fd;
			if(_debug)
				NSLog(@"didn't load from %@", object);
			fd=open(argv[1], 0);
			if(fd < 0)
				{
				perror(argv[1]);
				exit(1);
				}
			dup2(fd, 0);	// use this file as stdin
			l=read(0, first, sizeof(first));
			if(l < 0)
				{
				perror(argv[1]);
				exit(1);
				}
			if(l > 3 && strncmp(first, "#!/", 3) == 0)
				{ // there is a #!/path prefix for the shell
					int i=0;
					while(i < l && first[i] != '\n')
						i++;	// search first \n
					lseek(0, i, 0);	// rewind to first \n
				}
			else
				lseek(0, 0l, 0);	// rewind to beginning
			// pipe through cpp
			n=[Node parse:nil delegate:nil];	// parse stdin
			if(n && precompile)
				{ // was successfully parsed
				[n simplify];
				[n writeToFile:object];	// store n as binary representation for fast execution
				}
			}
		else
			n=[Node parse:nil delegate:nil];	// parse stdin
		}
	/*
	 * implement these phases as loadable bundles that can be configured as a pipeline
	 * and use a default pipeline if nothing is specified elsewhere
	 */
	if(lint)
		return 0;	// print parse errors only
#if 1
	NSLog(@"parse result:\n%@", n);	// print as xml
#endif
	if(compile)
		{
		[n simplify];
#if 1
		NSLog(@"simplified:\n%@", n);
#endif
		// choose how we should translate -> 1.0 -> 2.0 -> ARM -> Std-C
		[n objc10];	// translate to Obj-C 1.0
#if 1
		NSLog(@"translated:\n%@", n);
#endif
		}
	if(pretty)
		{ // pretty print
			printf("%s", [[n prettyObjC] UTF8String]);	// pretty print
			return 0;
		}
	// manipulate NSProcessInfo so that $0 = script name, $1... are aditional parameters
	// and make us call the main() function
	[n evaluate];	// run in interpreter
	return 0;
}
