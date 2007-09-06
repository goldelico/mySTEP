//
// say.m
// QuantumSTEP
//
// speaks
//    say [-v voice] [-o out.aiff] [-f file | string ...]
//
//  Created by Dr. H. Nikolaus Schaller on Thu Aug 30 2006.
//  Copyright (c) 2003 DSITRI. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void useage(const char *arg0)
{
	fprintf(stderr, "useage: %s [-v voice] [-o out.aiff] [-f file | string ...]\n", arg0);
}

int main(int argc, const char *argv[])
{
	const char *arg0=argv[0];
	NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
	NSEnumerator *e;
	NSString *arg;
	NSSpeechSynthesizer *s;
	NSString *str=nil;
	NSString *voice;
	NSString *ofile;
	if(!argv[1])
		{
		useage(arg0);
		exit(1);
		}
#if 0
	NSLog(@"set voice=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"v"]);
	NSLog(@"set outfile=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"o"]);
#endif
	e=[[[NSProcessInfo processInfo] arguments] objectEnumerator];
	while((arg=[e nextObject]))
		{
		if([arg hasPrefix:@"-"])
			{
			if([arg isEqualToString:@"-v"] || [arg isEqualToString:@"-o"])
				{
				if(![e nextObject])
					useage(arg0), exit(1);
				continue;
				}
			if([arg isEqualToString:@"-f"])
				{
				NSString *file=[e nextObject];
				NSString *ss;
				if(!file)
					useage(arg0), exit(1);
				ss=[NSString stringWithContentsOfFile:file];
				if(!ss)
					fprintf(stderr, "can't open file %s\n", [file UTF8String]), exit(1);
				if(str)
					str=[str stringByAppendingFormat:@" %@", ss];
				else 
					str=ss;	// first
				}
			else
				useage(arg0), exit(1);
			continue;
			}
		if(str)
			str=[str stringByAppendingFormat:@" %@", arg];
		else 
			str=arg;	// first
		}
	voice=[[NSUserDefaults standardUserDefaults] objectForKey:@"v"];
	ofile=[[NSUserDefaults standardUserDefaults] objectForKey:@"o"];
	s=[[NSSpeechSynthesizer alloc] initWithVoice:voice];
	if([ofile length])
		{
		if([s startSpeakingString:str toURL:[NSURL fileURLWithPath:ofile]])
			{
				fprintf(stderr, "can't speak to file %s\n", [ofile UTF8String]), exit(1);
			}
		}
	else
		[s startSpeakingString:str];
	[pool release];
	exit(0);	// all done
}
