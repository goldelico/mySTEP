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

/* FIXME:
 * allow for configuration through defaults
 * - where to store compiled binaries (if at all)
 * - always recompile (for testing)
 * - default pretty print style
 * - default compiler
 *
 * allow to build a chain of tree modification bundles
 * allow to pass parameters to stages
 * allow to call the refactor module with a set of translation strings (e.g. -r new=old)
 */

#import <Cocoa/Cocoa.h>
#import <ObjCKit/ObjcKit.h>

static void usage(void)
{
	fprintf(stderr, "usage: objc -c|-l|-p [ -d ] [ -m machine ] { -r old=new } [ file... ]\n");
	fprintf(stderr, "       objc [ -d ] [ file | -f script ] [ args... ]\n");
	exit(1);
}

static BOOL older(NSDictionary *file1attribs, NSDictionary *file2attribs)
{ // true if file1 is older (modified) than file2
	if(!file1attribs) return YES;	// not existent is older than anything
	if(!file2attribs) return NO;	// we are never older than non-existent
	return [[file1attribs fileModificationDate] compare:[file2attribs fileModificationDate]] != NSOrderedDescending;
}

int main(int argc, char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	BOOL lint=NO;		// -l
	BOOL pretty=NO;		// -p
	BOOL compile=NO;	// -c
	NSString *machine;	// -m
	BOOL interpret=NO;
	Node *result=nil;
	NSMutableDictionary *refactor=[NSMutableDictionary dictionaryWithCapacity:10];
	char *arg0=argv[0];
	machine=[[Node compileTargets] objectAtIndex:0];	// default compiler
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
				case 'd': {
					extern int yydebug;
					if(_debug) yydebug=1;	// -dd
					_debug=YES;
					break;
				}
				case 'm':
					if(*c)
						machine=[NSString stringWithUTF8String:c];
					else if(argv[2])
						machine=[NSString stringWithUTF8String:argv[2]], argv++;
					else
						usage();
					c+=strlen(c);
					break;	
				case 'r': {
					NSString *rule;
					NSRange r;
					NSString *old, *new;
					if(*c)
						rule=[NSString stringWithUTF8String:c];
					else if(argv[2])
						rule=[NSString stringWithUTF8String:argv[2]], argv++;
					else
						usage();
					c+=strlen(c);
					r=[rule rangeOfString:@"="];
					if(r.location == NSNotFound)
						usage();	// missing =
					old=[rule substringToIndex:r.length];
					new=[rule substringFromIndex:r.location+1];
					[refactor setObject:new forKey:old];
					break;					
				}
				case 'f': {
					NSString *script;
					if(*c)
						script=[NSString stringWithUTF8String:c];
					else if(argv[2])
						script=[NSString stringWithUTF8String:argv[2]], argv++;
					else
						usage();
					c+=strlen(c);
					NSLog(@"not implemented");
					usage();
					// [script writeToFile:temp]
					// or [NSInputStream streamWithString:script]
					// FIXME: result=[Node parse:script delegate:nil];	// parse script
					break;					
				}
				case 'b':	// install pipeline bundle
				case 'I':	// set include search path(s)
				default:
					usage();
			}
			}
		argv++;
		}
	interpret=!lint && !pretty && !compile;	// we run in script mode and should store a binary AST for faster execution
	while(argv[1] && (!interpret || !result))
		{ // get file arguments to process
		char first[512];
		int l;
		Node *n=nil;
		NSString *object=nil;
		NSFileManager *fm=[NSFileManager defaultManager];
		NSString *source=[fm stringWithFileSystemRepresentation:argv[1] length:strlen(argv[1])];
		if(interpret)
			{
			NSString *compiler;
			NSDictionary *sattribs;
			NSDictionary *oattribs;
			NSDictionary *cattribs;
			compiler=[fm stringWithFileSystemRepresentation:arg0 length:strlen(arg0)];
			if([[source pathExtension] length] > 0)
				object=[source stringByAppendingString:@"objc"];	// extend suffix
			else
				object=[source stringByAppendingPathExtension:@"objc"];	// first suffix
			// we may also prefix the object path to e.g. /tmp/objc and mkdir -p $(dirname $object))
			// the prefix could be made configurable (through NSUserDefaults)
			// default prefix should be "./"
			if(_debug) NSLog(@"%@ -> %@ (%@)", source, object, compiler);
			sattribs=[fm attributesOfItemAtPath:source error:NULL];
			oattribs=[fm attributesOfItemAtPath:object error:NULL];
			cattribs=[fm attributesOfItemAtPath:compiler error:NULL];
			if(_debug) NSLog(@"%@ -> %@ (%@)", sattribs, oattribs, cattribs);
			if(older(sattribs, oattribs) && older(cattribs, oattribs))
				{ // last time compile was after last update of source and compiler
				n=[Node nodeWithContentsOfFile:object];
				}
			}
		if(!n)
			{ // preparsed tree not found/not loaded
			int fd;
			if(_debug)
				NSLog(@"didn't load from %@", object);
				// stream=[[NSInputStream streamWithContentsOfFile:source];
			fd=open(argv[1], 0);
			if(fd < 0)
				{
				perror(argv[1]);
				exit(1);
				}
			dup2(fd, 0);	// use this file as stdin
				// [stream getBytes:first length:]
			l=read(0, first, sizeof(first));
			if(l < 0)
				{
				perror(argv[1]);
				exit(1);
				}
			if(l > 3 && strncmp(first, "#!/", 3) == 0)
				{ // there is a #!/path prefix for the shell
					int i=3;
					while(i < l && first[i] != '\n')
						i++;	// search first \n
					lseek(0, i, 0);	// rewind to first \n (included in parsing so that line counter is correct)
				}
			else
				lseek(0, 0l, 0);	// rewind to beginning
//				[stream setProperty:[NSNumber numberWithUnsignedInt:0 forKey:NSStreamFileCurrentOffsetKey];
			// pipe through cpp
			n=[Node parse:nil delegate:nil];	// parse stdin
			if(interpret)
				{
				if(n)
					{ // was successfully parsed
						[n simplify];
						[n writeToFile:object];	// store n as binary representation for fast execution
					}
				else
					{
					NSLog(@"could not parse");
					exit(1);
					}
				}
			}
		if(result)
			; // merge
		else
			result=n;	// first source file
		argv++;
		}
	if(!result)
		{ // no source found yet
		if(interpret)	// don't parse stdin in script mode
			usage();
			// how can we open an NSInputStream for STDIN?
			// reading from standardInput file handle as NSData and then converting into a NSStream is wasting memory
		result=[Node parse:nil delegate:nil];	// parse stdin		
		}
	/*
	 * implement these phases as loadable bundles that can be configured as a pipeline
	 * and use a default pipeline if nothing is specified elsewhere
	 */
	if(lint)
		return 0;	// print parse errors only
#if 1
	NSLog(@"parse result:\n%@", result);	// print as xml
	{
	/* FIXME: what should the parse: method return?
	 * the rootnode which represents the sequence of statements on global level
	 * or the scopestack which should be the symtab of all global objects
	 */
	extern Node *scopestack;	// scope stack
	NSLog(@"scope stack:\n%@", scopestack);
	}
#endif
	if(compile)
		{
		[result simplify];
		[result refactor:refactor];
#if 1
		NSLog(@"simplified:\n%@", result);
#endif
		// we should be able to chain several loadable bundles
		[result compile:machine];	// translate
#if 1
		NSLog(@"translated:\n%@", result);
#endif
		}
	if(pretty)
		{ // pretty print
			printf("%s", [[result prettyObjC] UTF8String]);	// pretty print
			return 0;
		}
	// manipulate NSProcessInfo so that $0 = script name, $1... are aditional parameters
	// and make us call the main() function
	[result evaluate];	// run in interpreter
	return 0;
}
