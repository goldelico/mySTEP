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
			if([l count] >= 2)
				{
				NSString *token=[[l objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
				if([token isEqualToString:@"Hardware"])
					{ // found hardware model
					NSString *model=[[l lastObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
					NSString *path=[[NSBundle bundleForClass:[self class]] pathForResource:@"Models" ofType:@"plist"];
					NSDictionary *dict=[NSDictionary dictionaryWithContentsOfFile:path];	// read model dictionary
					do
						{
							sysInfo=[dict objectForKey:model];	// get model description
							model=[sysInfo objectForKey:@"Alias"];
						} while(model);	// loop through aliases
					sysInfo=[sysInfo mutableCopy];	// and make a copy
					break;
					}
				// collect other values, e.g. Clock, Memory etc.
				// should we simply collect ALL entries into the dict?
				}
			}
		if(!sysInfo)	// no model description found
			sysInfo=[[NSMutableDictionary alloc] initWithCapacity:10];
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
		}
	NSLog(@"sysInfo=%@", sysInfo);
	return sysInfo;
}

+ (id) sysInfoForKey:(NSString *) key;
{
	return [sysInfo objectForKey:key];
}

@end
