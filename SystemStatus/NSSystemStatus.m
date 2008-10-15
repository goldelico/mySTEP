/* 
 SYSTEM STATUS driver.
 
 Copyright (C)	H. Nikolaus Schaller <hns@computer.org>
 Date:			2004
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <SystemStatus/NSSystemStatus.h>

#include <sys/utsname.h>

@implementation NSSystemStatus

static NSMutableDictionary *sysInfo;

/* must be a macro so that we can stringify it */

#define setmySTEP(PACKAGE_NAME, mySTEP_MAJOR_VERSION, mySTEP_MINOR_VERSION) [sysInfo setObject:[NSString stringWithFormat:@"%@.%@", @#mySTEP_MAJOR_VERSION, @#mySTEP_MINOR_VERSION] forKey:@#PACKAGE_NAME]

+ (NSDictionary *) _infoForModel:(NSString *) model fromDict:(NSDictionary *) dict
{
	NSDictionary *info=[dict objectForKey:model];	// get model description
	NSString *parentModel=[info objectForKey:@"Inherit"];
#if 0
	NSLog(@"%@ -> parent=%@ (%@)", model, parentModel, info);
#endif
	if(parentModel)
		{
		NSMutableDictionary *parent=[[self _infoForModel:parentModel fromDict:dict] mutableCopy];
		if(parent)
			{
			[parent addEntriesFromDictionary:info];	// overwrite all our specific definitions of parent
			return [parent autorelease];
			}
		}
	return info;
}

+ (NSDictionary *) sysInfo;
{ // collect all reasonable info we can get
	if(!sysInfo)
		{ // initialize
		struct utsname u;
		NSData *da;
		NSString *s;
		NSEnumerator *cpuinfo=[[[NSString stringWithContentsOfFile:@"/proc/cpuinfo"] componentsSeparatedByString:@"\n"] objectEnumerator];
		NSString *line;
		uname(&u);
		while((line=[cpuinfo nextObject]))
			{
			NSArray *l=[line componentsSeparatedByString:@":"];
#if 0
			NSLog(@"l=%@", l);
#endif
			if([l count] >= 2)
				{
				NSString *token=[[l objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
#if 0
				NSLog(@"token=%@", token);
#endif
					if([token isEqualToString:@"Hardware"])
					{ // found hardware model
					NSString *model=[[l lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"Models" ofType:@"plist"];
					NSDictionary *dict=[NSDictionary dictionaryWithContentsOfFile:path];	// read model dictionary
#if 0
						NSLog(@"model=%@ path=%@", model, path);
#endif
						if(!dict)
						NSLog(@"*** Can't read Models.plist for %@ from %@", model, path);
					sysInfo=[[self _infoForModel:model fromDict:dict] mutableCopy];	// and make a copy
					break;
					}
				// collect other values, e.g. Clock, Memory etc.
				// should we simply collect ALL entries into the dict?
				}
			}
		if(!sysInfo)	// still no model description found
			{
			sysInfo=[[NSMutableDictionary alloc] initWithCapacity:10];
			[sysInfo setObject:@"Unknown" forKey:@"Product"];
			}
		setmySTEP(PACKAGE_NAME, mySTEP_MAJOR_VERSION, mySTEP_MINOR_VERSION);
		[sysInfo setObject:[NSString stringWithCString: u.sysname] forKey:@"SysName"];
		[sysInfo setObject:[NSString stringWithCString: u.nodename] forKey:@"Nodename"];
		[sysInfo setObject:[NSString stringWithCString: u.release] forKey:@"SysRelease"];
		[sysInfo setObject:[NSString stringWithCString: u.version] forKey:@"SysVersion"];
		// read more processor details from /proc/cpuinfo
		[sysInfo setObject:[NSString stringWithCString: u.machine] forKey:@"Processor"];
		[sysInfo setObject:@"x MHz" forKey:@"Clock"];
		[sysInfo setObject:@"RAM" forKey:@"MemoryType"];
		[sysInfo setObject:@"64 MB" forKey:@"Memory"];
		// 
		da=[NSData dataWithContentsOfFile:@"/proc/deviceinfo/product"];	// override if defined
		s=da?[[[NSString alloc] initWithData:da encoding:NSUTF8StringEncoding] autorelease]:nil;
		if(s) [sysInfo setObject:[s stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] forKey:@"Product"];
#if 0
		struct sysinfo s_info;
		int error;
		error = sysinfo(&s_info);
		printf("code error = %d\n", error);
		printf("Uptime = %ds\nLoad: 1 min %d / 5 min %d / 15 min %d\n"
			   "RAM: total %d / free %d / shared %d\n"
			   "Memory in buffers = %d\nSwap: total %d / free %d\n"
			   "Number of processes = %d\n",
			   s_info.uptime, s_info.loads[0],
			   s_info.loads[1], s_info.loads[2],
			   s_info.totalram, s_info.freeram,
			   s_info.sharedram, s_info.bufferram,
			   s_info.totalswap, s_info.freeswap,
			   s_info.procs);
#endif	// read memory from /proc/meminfo
#if 1
		NSLog(@"sysInfo=%@", sysInfo);
#endif
		}
	return sysInfo;
}

+ (id) sysInfoForKey:(NSString *) key;
{
	if(!sysInfo)
		[self sysInfo];
	return [sysInfo objectForKey:key];
}

@end
