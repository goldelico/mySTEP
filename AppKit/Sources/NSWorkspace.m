/* 
 NSWorkspace.m
 
 Description...
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:	Scott Christley <scottc@net-community.com>
 Date:	1996
 Author:  Richard Frith-Macdonald <richard@brainstorm.co.uk>
 Date:	1998
 Author:  Felipe A. Rodriguez <far@pcmagic.net>
 Date:	Feb 1999
 Author:  H. Nikolaus Schaller <hns@computer.org>
 Date:	Aug 2003-2005
 - distributed Workspace support (dws)
 - findApplications made looking for MacOS X like bundles and document types (QSLaunchServices)
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSDictionary.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSData.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSTask.h>
#import <Foundation/NSException.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSConnection.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSRunLoop.h>
#import <Foundation/NSDistantObject.h>
#import <Foundation/NSAttributedString.h>
#import <Foundation/NSURL.h>
#import <Foundation/NSPropertyList.h>
#import <Foundation/NSDistantObject.h>

#import <AppKit/NSWorkspace.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSPanel.h>

#import "NSAppKitPrivate.h"
#import "NSSystemServer.h"

#include <sys/types.h>
#include <unistd.h>		// getpid()

#define WORKSPACE(notif_name)	NSWorkspace##notif_name##Notification

@interface GSListener : NSObject
+ (GSListener*) listener;
@end

@interface QSLaunchServices : NSObject
{
	NSMutableDictionary *QSApplicationIdentsByName;		// single ident for application name
	NSMutableDictionary *QSApplicationPathsByIdent;		// array of bundle paths for application identifier
	NSMutableDictionary *QSApplicationsByExtension;		// record list by extension
	NSMutableDictionary *QSFilePackageExtensions;		// extensions for file bundles
}

// .ext -> list of idents sorted by preferred app first
// name -> ident -> path
// ident -> list of paths sorted by most recent path first

+ (QSLaunchServices *) sharedLaunchServices;
- (id) init;
- (void) mapApplicationName:(NSString *) name toIdent:(NSString *) path;
- (void) mapApplicationIdent:(NSString *) ident toPath:(NSString *) path;
- (void) mapExtension:(NSString *) ext toIdent:(NSString *) ident withIconPath:(NSString *) path andRole:(NSString *) role andType:(NSString *) type;
- (NSArray *) identsForExtension:(NSString *) ext;	// returns NSDict entries (with CFBundleIdentifier records)
- (NSDictionary *) preferredIdentForExtension:(NSString *) ext;	// return preferred entry
- (void) setPreferredIdent:(NSString *) ident forExtension:(NSString *) ext;	// change preferred entry (Editor record first)
- (NSString *) absolutePathForAppBundleWithIdentifier:(NSString *) ident;	// map ident -> path (most recent)
- (NSString *) fullPathForApplication:(NSString *)appName;	// look up by name (most recent)
- (NSString *) applicationNameForIdent:(NSString *) ident;
- (void) treatExtensionAsFilePackage:(NSString *) ext;
- (BOOL) isFilePackageAtPath:(NSString *) path;
- (void) findApplicationsInDirectory:(NSString *) path;
- (void) clearCache;
- (void) findApplications;
- (void) writeDatabase;
- (NSDictionary *) applicationList;
- (NSDictionary *) fileTypeList;
- (NSArray *) knownApplications;

- (BOOL) launchAppWithBundle:(NSBundle *) b
					 options:(NSWorkspaceLaunchOptions) options
additionalEventParamDescriptor:(id) urls
			launchIdentifier:(NSNumber **) identifiers;
@end

// Class variables
static NSWorkspace *__sharedWorkspace = nil;
static QSLaunchServices *__launchServices = nil;
static BOOL __userDefaultsChanged = NO;
static BOOL __fileSystemChanged = NO;

@implementation QSLaunchServices

#define APPDATABASE [@"~/Library/Caches/com.quantum-step.mySTEP.QSLaunchServices.plist" stringByExpandingTildeInPath]

+ (QSLaunchServices *) sharedLaunchServices;
{
	if(!__launchServices)
		__launchServices=[self new];
	return __launchServices;
}

// - (void) dealloc;	// never

- (id) init;
{
	self=[super init];
	if(self)
		{ // load database (if possible)
			NSData *data=[NSData dataWithContentsOfFile:APPDATABASE];
			NSString *error;
			NSPropertyListFormat format;
			NSDictionary *defaults=[NSPropertyListSerialization propertyListFromData:data
																	mutabilityOption:NSPropertyListMutableContainers 
																			  format:&format
																	errorDescription:&error];
#if 0
			NSLog(@"LS database=%@", defaults);
#endif
			if(data && ![defaults isKindOfClass:[NSDictionary class]])
				NSLog(@"QSLaunchServices did not load %@ due to: %@", APPDATABASE, error);
			else
				{
				QSApplicationIdentsByName = [[defaults objectForKey:@"QSApplicationIdentsByName"] retain];
				QSApplicationPathsByIdent = [[defaults objectForKey:@"QSApplicationPathsByIdent"] retain];
				QSApplicationsByExtension = [[defaults objectForKey:@"QSApplicationsByExtension"] retain];
				QSFilePackageExtensions = [[defaults objectForKey:@"QSFilePackageExtensions"] retain];
				}
		}
	return self;
}

- (void) mapApplicationName:(NSString *) name toIdent:(NSString *) ident;
{ // add application name
#if 0
	NSLog(@"map Name %@ to %@", name, ident);
#endif
	// there is only one record per name - so contradicting duplicates will result in random entries
	if(name && ident)
		{
		if(!QSApplicationIdentsByName)
			[self findApplications];	// is missing - scan for applications
		[QSApplicationIdentsByName setObject:ident forKey:name];
		}
}

- (void) mapApplicationIdent:(NSString *) ident toPath:(NSString *) path;
{ // add application identifier
	NSMutableArray *records;
#if 0
	NSLog(@"map Ident %@ to %@", ident, path);
#endif
	if(!ident)
		return;
	if(!QSApplicationPathsByIdent)
		[self findApplications];	// is missing - scan for applications
	records=[QSApplicationPathsByIdent objectForKey:ident];
	if(!records)
		[QSApplicationPathsByIdent setObject:records=[NSMutableArray arrayWithCapacity:3] forKey:ident];
	if([records containsObject:path])
		return;	// already known
	// should insert sort so that the most recent executable is coming first
	[records addObject:path];
}

- (void) mapExtension:(NSString *) ext toIdent:(NSString *) ident withIconPath:(NSString *) path andRole:(NSString *) role andType:(NSString *) type;
{ // use @"schema:" for ext to store URL schemes
	NSMutableArray *records;
	NSDictionary *dict;
#if 0
	NSLog(@"map Extension %@ to Ident %@ icon %@ role %@ type %@", ext, ident, path, role, type);
#endif
	if(!ext || !ident || !role || !type)
		return;	// any important part is missing (icon path may be nil)
	if(!QSApplicationsByExtension)
		[self findApplications];	// is missing - scan for applications
	records=[QSApplicationsByExtension objectForKey:ext];
	if(!records)
		[QSApplicationsByExtension setObject:records=[NSMutableArray arrayWithCapacity:3] forKey:ext];
	// go through records and check if entry with ident, role, type is already stored
	dict=[NSDictionary dictionaryWithObjectsAndKeys:
		  ident, @"CFBundleIdentifier",
		  role, @"CFBundleTypeRole",
		  type, @"CFBundleTypeName",
		  path, @"CFBundleTypeIconPath",	// path may be nil, so this must be the last entry
		  nil];
	[records addObject:dict];	// add record
}

- (NSArray *) identsForExtension:(NSString *) ext;
{ // return list of application records for this extension
	// returns all records with matching extension
	// sorted by preferred first and descending by Editor, Viewer, None - should be sorted when generating database
	if(!QSApplicationsByExtension)
		[self findApplications];	// is missing - scan for applications
	return [QSApplicationsByExtension objectForKey:ext];
}

- (NSDictionary *) preferredIdentForExtension:(NSString *) ext;
{ // find preferred ident for this extension
	NSArray *a=[self identsForExtension:ext];
#if 0
	NSLog(@"identsForExtension %@: %@\n%@", ext, a, QSApplicationsByExtension);
#endif
	if([a count] == 0)
		return nil;
	// FIXME: check if application (binary) really exists - otherwise update
	return [a objectAtIndex:0];	// first, i.e. preferred
}

- (void) setPreferredIdent:(NSString *) ident forExtension:(NSString *) ext;
{ // allow user interface to change preferred application
	if(!QSApplicationsByExtension)
		[self findApplications];	// is missing - scan for applications
	// move to front
	[self writeDatabase];
}

- (NSString *) absolutePathForAppBundleWithIdentifier:(NSString *) ident;
{ // find most recent version with this identifier
	NSArray *a;
#if 0
	NSLog(@"ident->path: %@", ident);
#endif
	if(!QSApplicationPathsByIdent)
		[self findApplications];	// is missing - scan for applications
	a=[QSApplicationPathsByIdent objectForKey:ident];
	if([a count] == 0)
		return nil;
	return [a objectAtIndex:0];	// first, i.e. preferred
}

- (NSString *) fullPathForApplication:(NSString *)appName
{
	NSString *last=[appName lastPathComponent];
	//	NSString *ext=[appName pathExtension];
	NSString *path;
	if(!appName)
		return nil;		// unspecified
	if([appName isAbsolutePath])
		return appName; // is already a full path
	if(![appName isEqual:last])
		return nil;		// has path components, i.e. not a plain app name - don't treat as relative name
	appName=[appName stringByDeletingPathExtension]; // remove extension (if present)
#if 0
	NSLog(@"fullPathForApplication:%@", appName);
	NSLog(@"QSApplicationIdentsByName:%@", QSApplicationIdentsByName);
#endif
	if(!QSApplicationIdentsByName)
		{ // first call
			[self findApplications];	// build database
			return [self absolutePathForAppBundleWithIdentifier:[QSApplicationIdentsByName objectForKey:appName]];	// try to map name to ident to path
		}
	path=[self absolutePathForAppBundleWithIdentifier:[QSApplicationIdentsByName objectForKey:appName]];	// try to map name to ident to path
	if(!path)
		{
#if 1
		NSLog(@"did not find %@ in database - rebuild database and try again", appName);
#endif
		[self findApplications];	// did not find -> rebuild database
		}
	return [self absolutePathForAppBundleWithIdentifier:[QSApplicationIdentsByName objectForKey:appName]];	// try again - returns nil if still unknown
}

- (NSString *) applicationNameForIdent:(NSString *) ident;
{ // look up application name for bundle identifier (randomly choosen if different bundles have same ident)
	NSArray *a;
	if(!QSApplicationIdentsByName)
		[self findApplications];	// is missing - scan for applications
	a=[QSApplicationIdentsByName allKeysForObject:ident];
	if([a count] == 0)
		return nil;	// not found
	return [a objectAtIndex:0];	// first, i.e. preferred
}

- (void) treatExtensionAsFilePackage:(NSString *) ext;
{ // treat as file package
	if(ext)
		[QSFilePackageExtensions setObject:self forKey:ext];	// add to list
}

- (BOOL) isFilePackageAtPath:(NSString *) path
{ // check if it is a file package
	NSFileManager *fm=[NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exists = [fm fileExistsAtPath:path isDirectory:&isDir];
    if(!(exists && isDir))
		return NO;	// must be a directory to be a package
	if([QSFilePackageExtensions objectForKey:[path pathExtension]])
		return YES;	// file extension is in list of Document bundles
	// otherwise we must have a subdirectory named "Contents"
	path=[path stringByAppendingPathComponent:@"Contents"];
	exists = [fm fileExistsAtPath:path isDirectory:&isDir];
    if(!(exists && isDir))
		return NO;
	// and we must have an Info.plist file
	exists = [fm fileExistsAtPath:[path stringByAppendingPathComponent:@"Info.plist"] isDirectory:&isDir];
    return ((exists && !isDir));
}

- (void) addApplicationAtPath:(NSString *) path;
{ // analyse application bundle to store in database
	NSBundle *b;
	NSDictionary *info;
	NSArray *filetypes;
	NSArray *urltypes;
	NSString *appname;
	NSString *ident;
	NSDictionary *ft;
	NSEnumerator *fte;
	b=[NSBundle bundleWithPath:path];	// open as bundle
	// check type - should have CFBundlePackageType="APPL" bundle
	info=[b infoDictionary];
	if(!info)
		{
#if 0
		NSLog(@"can't load Info.plist for %@", path);
#endif
		return;
		}
	appname=[info objectForKey:@"CFBundleName"];
	if(!appname)
		appname=[[path lastPathComponent] stringByDeletingPathExtension];	// if no display name is defined
	// should check if already defined - keep/sort newer one
	ident=[b bundleIdentifier];
	if(![[NSFileManager defaultManager] isExecutableFileAtPath:[b executablePath]])
		{
		// FIXME: Here, we could call something like '/usr/bin/softpear $BUNDLE/Contents/MacOS/$EXECUTABLE $*' 
#if 0
		NSLog(@"No executable at %@", [b executablePath]);
#endif
		return;	// not an executable at path
		}
	[self mapApplicationName:appname toIdent:ident];	// map name to identifier
	[self mapApplicationIdent:ident toPath:path];		// map identifier to path
	filetypes=[info objectForKey:@"CFBundleDocumentTypes"];
	urltypes=[info objectForKey:@"CFBundleURLTypes"];
	if(!filetypes && urltypes)
		filetypes=urltypes;	// URL types only
	else if(filetypes && urltypes)
		filetypes=[filetypes arrayByAddingObjectsFromArray:urltypes];	// merge both
	if(!filetypes)
		{
#if 0
		NSLog(@"No CFBundleDocumentTypes for %@", path);
#endif
		return;
		}
	fte=[filetypes objectEnumerator];
	while((ft=[fte nextObject]))
		{ // process file types
			NSString *iconFile;
			NSString *iconPath;
			NSString *role;
			NSString *type;
			NSEnumerator *ftex;
			NSString *ext;
			iconFile=[ft objectForKey:@"CFBundleTypeIconFile"];
			if(!iconFile)
				iconFile=[ft objectForKey:@"CFBundleURLIconFile"];
			iconPath=[iconFile length]>0?[b pathForResource:iconFile ofType:nil inDirectory:nil]:nil;	// try to look up in application bundle
			role=[ft objectForKey:@"CFBundleTypeRole"];
			type=[ft objectForKey:@"CFBundleTypeName"];
			if(!type)
				type=[ft objectForKey:@"CFBundleURLName"];
			ftex=[[ft objectForKey:@"CFBundleTypeExtensions"] objectEnumerator];
			while((ext=[ftex nextObject]))
				{ // process all potential file extensions for this type (e.g. .jpg, .jpeg, .tif, .tiff, ...)
					[self mapExtension:ext toIdent:ident withIconPath:iconPath andRole:role andType:type];
				}
			ftex=[[ft objectForKey:@"CFBundleURLSchemes"] objectEnumerator];
			while((ext=[ftex nextObject]))
				{ // process all potential URL schemes for this type (e.g. http, ftp, file, folder, ...)
					[self mapExtension:[ext stringByAppendingString:@":"] toIdent:ident withIconPath:iconPath andRole:role andType:type];
				}
			if([[ft objectForKey:@"LSTypeIsPackage"] boolValue])
				[self treatExtensionAsFilePackage:ext];
		}
	// might call findApplicationsInDirectory:Resources to get embedded .apps
}

- (void) findApplicationsInDirectory:(NSString *) path
{ // add all applications found below directory (doing a deep search)
	NSString *fp=[path stringByExpandingTildeInPath];
	NSDirectoryEnumerator *de=[[NSFileManager defaultManager] enumeratorAtPath:fp];
	NSString *dp;
#if 0
	NSLog(@"findApplications in %@", fp);
#endif
	while((dp=[de nextObject]))
		{ // all files in search path with .app extension
			NSAutoreleasePool *arp;
			// we should try to skip non-app bundles!
			if(![[dp pathExtension] isEqualToString:@"app"])
				continue;
			arp=[NSAutoreleasePool new];
			[de skipDescendents];		// don't search/find embedded applications! (why or why not?)
			dp=[fp stringByAppendingPathComponent:dp];	// make absolute path
#if 0
			NSLog(@"candidate: %@", dp);
#endif
			[self addApplicationAtPath:dp];
			[arp release];
		}
}

- (void) clearCache;
{
	[QSApplicationIdentsByName release];	// clear database
	QSApplicationIdentsByName=nil;
	[QSApplicationPathsByIdent release];
	QSApplicationPathsByIdent=nil;
	[QSApplicationsByExtension release];
	QSApplicationsByExtension=nil;
	[QSFilePackageExtensions release];
	QSFilePackageExtensions=nil;
}

- (void) findApplications
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSArray *path=NSSearchPathForDirectoriesInDomains(NSAllApplicationsDirectory,	NSAllDomainsMask, YES);
	//	NSArray *path=[[NSBundle bundleForClass:[self class]] objectForInfoDictionaryKey:@"NSApplicationSearchPath"];
	NSEnumerator *p=[path objectEnumerator];
	NSString *dir;
#if 1
	NSLog(@"findApplications");
#endif
	[self clearCache];
	QSApplicationIdentsByName=[[NSMutableDictionary dictionaryWithCapacity:50] retain];
	QSApplicationPathsByIdent=[[NSMutableDictionary dictionaryWithCapacity:50] retain];
	QSApplicationsByExtension=[[NSMutableDictionary dictionaryWithCapacity:100] retain];
	QSFilePackageExtensions=[[NSMutableDictionary dictionaryWithCapacity:20] retain];
	while((dir=[p nextObject]))
		[self findApplicationsInDirectory:dir];	// fill with applications
	[self writeDatabase];
	[arp release];
}

- (void) writeDatabase;
{
	NSDictionary *dict;
	NSData *data;
	NSString *error;
	dict=[NSDictionary dictionaryWithObjectsAndKeys:
		  QSApplicationIdentsByName, @"QSApplicationIdentsByName",
		  QSApplicationPathsByIdent, @"QSApplicationPathsByIdent",
		  QSApplicationsByExtension, @"QSApplicationsByExtension",
		  QSFilePackageExtensions, @"QSFilePackageExtensions",
		  nil
		  ];
#if 1
	NSLog(@"write application Database");
#endif
	data=[NSPropertyListSerialization dataFromPropertyList:dict
#if 0	// human readable for testing */
													format:NSPropertyListXMLFormat_v1_0
#else
													format:NSPropertyListBinaryFormat_v1_0
#endif
										  errorDescription:&error];
	if(!data)
		NSLog(@"Could not create Launch Services database from %@", dict);
	else if(![data writeToFile:APPDATABASE atomically:YES])
		NSLog(@"Could not save Launch Services database to %@", APPDATABASE);
#if 1
	NSLog(@"done");
#endif
}

- (NSDictionary *) applicationList; { if(!QSApplicationIdentsByName) [self findApplications]; return QSApplicationIdentsByName; }
- (NSDictionary *) fileTypeList; { if(!QSApplicationsByExtension) [self findApplications]; return QSApplicationsByExtension; }
- (NSArray *) knownApplications; { if(!QSApplicationIdentsByName) [self findApplications]; return [QSApplicationIdentsByName allKeys]; }

// this is the core application launcher method

// FIXME: how are arguments/URLs from openURL really passed here (if we launch/send openApp event through DO)?

- (BOOL) launchAppWithBundle:(NSBundle *) b
					 options:(NSWorkspaceLaunchOptions) options
additionalEventParamDescriptor:(id) params
			launchIdentifier:(NSNumber **) identifiers;
{
	NSTask *task;
	NSDate *date;
	NSString *executable;
	NSMutableDictionary *dict;
	NSString *appname;
	NSString *appFile;	// active application file
	NSMutableArray *args;
	unsigned long psn_low, psn_high;
	struct timeval tp;
	//
	// we keep a record (Plist) for each launched application in /tmp/.QuantumSTEP.apps/<bundleIdentifier>
	// from that we can properly interlock application launch
	// we have different states:
	// a) app is not in launched applications files
	//   => launch
	// b) app is in launched applications files
	//   if multiple instances => launch
	//   try to connect through DO
	//     if no response => remove current record and launch new instance (wasn't cleaned up by crash reporter)
	//     if response => send eventParamDescriptor and arguments
	//
	if(options&NSWorkspaceLaunchInhibitingBackgroundOnly)
		{ // check if we want to launch a background only application and deny
			if([[b objectForInfoDictionaryKey:@"LSBackgroundOnly"] boolValue])
				return NO;	// is background only
		}
	appFile=[NSWorkspace _activeApplicationPath:[b bundleIdentifier]];
	while((options&NSWorkspaceLaunchNewInstance) == 0)
		{ // try to contact existing application - and launch exactly once
			int fd;
			if((fd=open([appFile fileSystemRepresentation], O_CREAT|O_EXCL, 0644)) < 0)
				{ // We are not the first to write the file. This means someone else is launching or has launched the same application
					NSDictionary *app=[NSDictionary dictionaryWithContentsOfFile:appFile];
					pid_t pid=[[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
					if(pid)
						{ // if file is non-empty and defines a pid, it is up and running (DO port is initialized)
#if 1
							NSLog(@"App is already running with pid=%d", pid);
#endif
							if([[NSFileManager defaultManager] fileExistsAtPath:[NSString stringWithFormat:@"/proc/%d", pid]])
								{ // process exists
									id a;
#if 1
									NSLog(@"process exists");
									NSLog(@"contact by DO");
#endif
									NS_DURING
									if([[b bundleIdentifier] isEqual:[[NSBundle mainBundle] bundleIdentifier]])
										a=[NSApp delegate];			// that is myself - avoid loop through DO
									else
										{
										a = [NSConnection connectionWithRegisteredName:[b bundleIdentifier] host:@""];	// Try to contact the existing instance
										if(a)
											{ // ports exists (but might not respond)
												[a setRequestTimeout:1.0];	// should answer nearly immediately
												[a setReplyTimeout:2.0];
												a = [a rootProxy];	// get root proxy
											}
										}
#if 0
									NSLog(@"connection to application=%@", a);
#endif
									[[a retain] autorelease];	// FIXME: do we really need that???
									// if we are sending to ourselves, a is the delegate - and should respond to this method!
									NS_VALUERETURN([a _application:a openURLs:params withOptions:options], BOOL);	// call the handler of GSListener
									NS_HANDLER
									NSLog(@"exception while contacting other application: %@", localException);
									return NO;	// timeout - did not respond
									NS_ENDHANDLER
								}
							else
								{ // App has crashed: launch a new instance (which will get a different pid!)
#if 1
									NSLog(@"App has crashed. Launching new instance.");
									// loop with timeout until pid changes
									// FIXME:
									//  this risks a race condition if two differnt apps try to launch the crashed one again!
									//  if we simply launch, then there is no locking
									//  if we simply delete the file and try again, we are not guaranteed that we then get an exclusive launch
									//  so we should
									
									// unlink([appFile fileSystemRepresentation];
									// if((fd=open([appFile fileSystemRepresentation], O_CREAT|O_EXCL, 0644)) < 0)
									// { // failed, i.e. someone else was faster
									// continue;		// loop again
									// }
									// else break;	// now we have the lock and can launch
									
									// FIXME: this is still not safe
									//        what happens if we unlink the file after someone else has just created the lock file???
									//        unlink&open must be atomic - or we need a different mechanism
									
#endif
									break;
								}
						}
					else
						{ // App is not (yet) up and running
#if 1
							NSLog(@"app not yet started (or crashed before launching)");
#endif
							// get attributes of appfile
							//    App is not yet running
							//    if creation date is too old
							//       App did never launch: launch a new instance
							//    else
							//       App is still launching, wait and then contact through DO
							break;
						}
				}
			else
				close(fd);	// don't leak file handle of the newly created file
		}
	executable=[b executablePath];	// get executable within bundle
	if(!executable)
		return NO;	// we have no executable to launch
	appname=[b objectForInfoDictionaryKey:@"CFBundleName"];
	if(!appname)
		appname=[[[b bundlePath] lastPathComponent] stringByDeletingPathExtension];	// use bundle name w/o .app instead
	gettimeofday(&tp, NULL);	// the unique PSNs are assigned here and passed to the app by -psn_%lu_%lu
	psn_high=tp.tv_sec;
	psn_low=tp.tv_usec;
	dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
		  [b bundlePath], @"NSApplicationPath",
		  appname, @"NSApplicationName",
		  [b bundleIdentifier], @"NSApplicationBundleIdentifier",
		  [NSNumber numberWithInt:0], @"NSApplicationProcessIdentifier",	// we don't know yet
		  [NSNumber numberWithInt:psn_high], @"NSApplicationProcessSerialNumberHigh",
		  [NSNumber numberWithInt:psn_low], @"NSApplicationProcessSerialNumberLow",
		  nil];
	[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:WORKSPACE(WillLaunchApplication)
																	  object:self
																	userInfo:dict];
	args=[NSMutableArray arrayWithCapacity:[params count]+6];
	NS_DURING   // shield caller from exceptions
	[args addObject:[NSString stringWithFormat:@"-psn_%lu_%lu", psn_high, psn_low]];
	if(params)
		{ // convert URLs to command line arguments
			NSEnumerator *e=[params objectEnumerator];
			NSURL *url;
			while((url=[e nextObject]))
				{
				if([url isFileURL])
					[args addObject:[url path]];	// add plain path - should we do a tilde abbreviation?
				else
					[args addObject:[url absoluteString]];	// full URL
				}
		}
	if(options&NSWorkspaceLaunchAndPrint)
		[args addObject:@"-NSPrint"];	// append behind files or they would become arguments to the options
	if(options&NSWorkspaceLaunchWithoutActivation)
		[args addObject:@"-NSNoActivation"];
	if((options&(NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchNewInstance)) == (NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchNewInstance))
		[args addObject:@"-NSTemp"];
	else if(options&NSWorkspaceLaunchWithoutAddingToRecents)
		[args addObject:@"-NSNoUI"];
	else if(options&NSWorkspaceLaunchNewInstance)
		[args addObject:@"-NSNew"];
#if 0
	NSLog(@"NSWorkspace launchApplication: '%@' $*=%@", executable, args);
#endif
	task=[[[NSTask alloc] init] autorelease];
	[task setLaunchPath:executable];
	[task setArguments:args];
	[task setEnvironment:[b objectForInfoDictionaryKey:@"LSEnvironment"]];	// may be nil?
	[task launch];
	NS_HANDLER
	NSLog(@"could not launchApplication %@ due to %@", [b bundlePath], [localException reason]);
	return NO;  // did not launch - e.g. bad executable
	NS_ENDHANDLER
	if(!(options&NSWorkspaceLaunchAsync))
		{ // synchronously, i.e. wait until launched
			pid_t pid;
			while(YES)
				{
				// FIXME: timeout? i.e. if App never launches
				NSDictionary *app=[NSDictionary dictionaryWithContentsOfFile:appFile];
				pid=[[app objectForKey:@"NSApplicationProcessIdentifier"] intValue];
				if(pid > 0)
					break;	// wait until app appears to have launched
#if 1
				NSLog(@"Wait until launched.");
#endif
				date=[NSDate dateWithTimeIntervalSinceNow:0.5];	// delay a little
				[[NSRunLoop currentRunLoop] runUntilDate:date];
				}
			// should be a distributed notification sent by launched application!
			[dict setObject:[NSNumber numberWithInt:pid] forKey:@"NSApplicationProcessIdentifier"];
			[[[NSWorkspace sharedWorkspace] notificationCenter] postNotificationName:WORKSPACE(DidLaunchApplication)
																			  object:self
																			userInfo:dict];
		}
	return YES;
}

@end

@implementation	NSWorkspace

+ (void) initialize
{
	if (!__sharedWorkspace)
		__sharedWorkspace = (NSWorkspace*)NSAllocateObject(self, 0, NSDefaultMallocZone());
}

+ (NSWorkspace *) sharedWorkspace				{ return __sharedWorkspace; }
+ (id) alloc									{ return NIMP; }
- (void) dealloc								{ NIMP; [super dealloc]; }
- (id) init										{ return NIMP; }

- (NSNotificationCenter *) notificationCenter;
{ // where workspace notifications originate
	return [NSNotificationCenter defaultCenter];
}

// 
// this is the most generic file launcher on which all other -open methods are based on
//

- (BOOL) openURLs:(NSArray *) list		// may be nil to denote application launch without files
withAppBundleIdentifier:(NSString *) identOrApp		// may be absolute path, appName, bundleIdentifier or nil - .app may be present or omitted
		  options:(NSWorkspaceLaunchOptions) options
additionalEventParamDescriptor:(id) ignored		// we have no NSAppleEventDescriptor
launchIdentifiers:(NSArray **) identifiers;
{
	NSMutableDictionary *apps;
	NSEnumerator *e;
#if 0
	NSLog(@"NSWorkspace: openURLs: '%@'", list);
	NSLog(@"  withAppBundleIdentifier '%@'", identOrApp);
#endif
	if(!identOrApp)
		{ // get application(s) for scheme(s) or file extension(s) in list
			NSURL *arg;
			if([list count] == 0)
				return NO;	// nothing to open with no application...
			apps=[NSMutableDictionary dictionaryWithCapacity:5];
			e=[list objectEnumerator];	// go through all arguments
			while((arg=[e nextObject]))
				{
				NSMutableArray *arglist;	// for current ident
				NSString *ext;
				if([arg isFileURL])
					{ // is file - try to find by extension
						NSString *path=[arg path];
						ext=[path pathExtension];
#if 0
						NSLog(@"  path=%@", path);
						NSLog(@"  ext=%@", ext);
#endif
						if([path isAbsolutePath] && [ext isEqualToString:@"app"] && [list count] == 1)
							{ // open single application (well, myFinder could handle this if it is asked to open)
								apps=[NSDictionary dictionaryWithObject:[NSArray array] forKey:path];
								break;
							}
						else if([ext length] == 0)
							{ // check for directory and process extension "/"
								NSFileManager *fm=[NSFileManager defaultManager];
								BOOL isDir=NO;
#if 0
								NSLog(@"check for directory at %@", path);
#endif
								if([fm fileExistsAtPath:path isDirectory:&isDir] && isDir)
									ext=@"/";
							}
					}
				else
					ext=[[arg scheme] stringByAppendingString:@":"];	// include : for lookup by URL scheme
				if(ext)
					{
#if 0
					NSLog(@"  try extension: %@", ext);
#endif
					if(!__launchServices)
						[QSLaunchServices sharedLaunchServices];
					identOrApp=[[__launchServices preferredIdentForExtension:ext] objectForKey:@"CFBundleIdentifier"];
					if(!identOrApp)
						identOrApp=[[__launchServices preferredIdentForExtension:@"*"] objectForKey:@"CFBundleIdentifier"];
					}
				if(!identOrApp)
					{ // don't know how to launch
						return NO;
					}
				arglist=[apps objectForKey:identOrApp];
				if(!arglist)
					[apps setObject:arglist=[NSMutableArray arrayWithCapacity:10] forKey:identOrApp];
				[arglist addObject:arg];	// make that app open this url
				}
		}
	else
		apps=[NSDictionary dictionaryWithObject:list forKey:identOrApp];
#if 0
	NSLog(@"openURLs -> %@", apps);
#endif
	if(identifiers)
		*identifiers=[NSMutableArray arrayWithCapacity:[apps count]];
	e=[apps keyEnumerator];
	while((identOrApp=[e nextObject]))
		{ // launch all applications needed for these URLs
			NSNumber *ident=nil;
			if(![self launchAppWithBundleIdentifier:identOrApp options:options additionalEventParamDescriptor:[apps objectForKey:identOrApp] launchIdentifier:&ident])
				return NO;
			if(identifiers && ident)
				[(NSMutableArray *) *identifiers addObject:ident];	// add to list
		}
	return YES;
}

- (BOOL) openURL:(NSURL *) url;
{
	return [self openURLs:[NSArray arrayWithObject:url]
  withAppBundleIdentifier:nil
				  options:NSWorkspaceLaunchDefault 
additionalEventParamDescriptor:nil
		launchIdentifiers:NULL];
}

- (BOOL) openFiles:(NSArray *) paths	// may be nil to open application
   withApplication:(NSString *) appName	// may be absolute path, appName, bundleIdentifier or nil - .app may be present or omitted
	 andDeactivate:(BOOL) flag
{
	NSMutableArray *a;
	if(paths)
		{ // translate paths into file URLs
			NSEnumerator *e=[paths objectEnumerator];
			NSString *path;
			a=[NSMutableArray arrayWithCapacity:[paths count]];
			while((path=[e nextObject]))
				{
				if(![path isAbsolutePath])
					{
					NSLog(@"NSWorkspace openFiles requires absolute paths (%@)", path);
					return NO;
					}
				[a addObject:[NSURL fileURLWithPath:path]];
				}
		}
	else
		a=nil;
	return			[self openURLs:a
	withAppBundleIdentifier:appName
					options:flag?(NSWorkspaceLaunchDefault|NSWorkspaceLaunchWithoutActivation):NSWorkspaceLaunchDefault
additionalEventParamDescriptor:nil		// we have no NSAppleEventDescriptor
		  launchIdentifiers:NULL];
}

- (BOOL) openFile:(NSString *) fullPath
  withApplication:(NSString *) appName	// may be full path or partially or nil - .app may be present or omitted
	andDeactivate:(BOOL) flag
{
	return [self openFiles:fullPath?[NSArray arrayWithObject:fullPath]:nil withApplication:appName andDeactivate:flag];
}

- (BOOL) openFile:(NSString *) fullPath withApplication:(NSString *) appName
{ // and deactivate
	return [self openFile:fullPath withApplication:appName andDeactivate:YES];
}

- (BOOL) openFile:(NSString *) fullPath
{ // default application
	return [self openFile:fullPath withApplication:nil andDeactivate:YES];
}

- (BOOL) openTempFile:(NSString *) fullPath
{ // open new but not adding to recents...
	return
	[self openURLs:[NSArray arrayWithObject:[NSURL fileURLWithPath:fullPath]]
withAppBundleIdentifier:nil
		   options:NSWorkspaceLaunchDefault | NSWorkspaceLaunchWithoutAddingToRecents | NSWorkspaceLaunchNewInstance
additionalEventParamDescriptor:nil
 launchIdentifiers:NULL];
}

- (BOOL) openFile:(NSString *) fullPath
		fromImage:(NSImage *) anImage
			   at:(NSPoint) point
		   inView:(NSView *) aView
{
	// animate the open process and then call
	return [self openFile:fullPath withApplication:@"myFinder"];
}

- (BOOL) selectFile:(NSString *) fullPath
inFileViewerRootedAtPath:(NSString *) rootFullpath
{
	// somehow pass rootFullpath to myFinder and make it 'show' instead of 'open'
	return [self openFile:rootFullpath withApplication:@"myFinder"];
}

- (BOOL) launchApplication:(NSString *) appName
{
	return [self launchApplication:appName showIcon:YES autolaunch:NO];
}

- (BOOL) launchApplication:(NSString *) appName
				  showIcon:(BOOL) showIcon
				autolaunch:(BOOL) autolaunch
{
	appName=[self fullPathForApplication:appName];
	if(!appName)
		return NO;	// unknown application
	
	// FIXME: how to handle showIcon and autolaunch?
	
	return [self launchAppWithBundleIdentifier:appName options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:NULL];
}

- (BOOL) launchAppWithBundleIdentifier:(NSString *) identOrApp
							   options:(NSWorkspaceLaunchOptions) options
		additionalEventParamDescriptor:(id) params
					  launchIdentifier:(NSNumber **) identifiers;
{ // launch application (without files)
	NSString *path;
	NSBundle *b;
#if 1
	NSLog(@"launchAppWithBundleIdentifier: %@ options: %d eventparam: %@", identOrApp, options, params); 
#endif
	if(!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	path=[__launchServices absolutePathForAppBundleWithIdentifier:identOrApp];	// returns nil if not found
	if(!path)
		path=[__launchServices fullPathForApplication:identOrApp];	// returns nil if not found
#if 0
	NSLog(@"  resolved application path: %@", path);
#endif
	if(!path)
		return NO;	// still not found
	b=[NSBundle bundleWithPath:path];
	if(!b)
		return NO;	// is not a valid bundle
	if([[QSLaunchServices sharedLaunchServices] launchAppWithBundle:b
															options:options
									 additionalEventParamDescriptor:params
												   launchIdentifier:identifiers])
		{ // did launch as expected
			if(options&NSWorkspaceLaunchAndHideOthers)
				[NSApp hideOtherApplications:self];
			if(options&NSWorkspaceLaunchAndHide)
				[NSApp hide:self];
			return YES;
		}
	return NO;
}

// internal for workspace file operations

- (void) _taskDidTerminate:(NSNotification *)aNotification
{
	NSTask *task = (NSTask *)[aNotification object];
	
	if ([task terminationStatus] == 0)
		{
		NSString *p = [task currentDirectoryPath];
		
		NSLog(@"workspace task ended normally");
		
		[self selectFile:p inFileViewerRootedAtPath:p];
		}
	else
		NSLog(@"workspace task did not end normally");
}

- (BOOL) performFileOperation:(NSString *)operation
					   source:(NSString *)source
				  destination:(NSString *)destination
						files:(NSArray *)files
						  tag:(NSInteger *)tag
{
	NSInteger result=NSAlertDefaultReturn, count = [files count];
	
	NSLog(@"performFileOperation %@", operation);
	
	if([operation isEqualToString:NSWorkspaceMoveOperation])
		{
		*tag = 0;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *d = [destination stringByAppendingPathComponent:f];
			NSString *a = [[NSProcessInfo processInfo] processName];
			result = NSRunAlertPanel(a, @"Move: %@ to: %@?", @"Move", 
									 @"Cancel", NULL, s, d);
			if (result == NSAlertDefaultReturn && ![[NSFileManager defaultManager] movePath:s toPath:d handler:0])
				return NO;
			NSLog(@"not moving");
			}	
		}
	else if([operation isEqualToString:NSWorkspaceCopyOperation])
		{
		*tag = 1;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *d = [destination stringByAppendingPathComponent:f];
			NSString *a = [[NSProcessInfo processInfo] processName];
			result = NSRunAlertPanel(a, @"Copy: %@ ?", @"Copy", 
									 @"Cancel", NULL, s);
			if (result == NSAlertDefaultReturn && ![[NSFileManager defaultManager] copyPath:s toPath:d handler:0])
				return NO;
			NSLog(@"not copying");
			}
		}
	else if([operation isEqualToString:NSWorkspaceLinkOperation])
		{
		*tag = 2;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *d = [destination stringByAppendingPathComponent:f];
			NSString *a = [[NSProcessInfo processInfo] processName];
			result = NSRunAlertPanel(a, @"Link: %@ ?", @"Link", 
									 @"Cancel", NULL, s);
			if (result == NSAlertDefaultReturn && ![[NSFileManager defaultManager] linkPath:s toPath:d handler:0])
				return NO;
			NSLog(@"not linking");
			}
		}
	else if([operation isEqualToString:NSWorkspaceCompressOperation])
		{
		*tag = 3;
		}
	else if([operation isEqualToString:NSWorkspaceDecompressOperation])
		{
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		
		*tag = 4;
		while (count--)
			{
			BOOL tar = NO;
			NSArray *args;
			NSString *p, *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *tmp, *ext = [s pathExtension];
			NSTask *task;
			
			/// FIXME: should open the Archiver by file extension?
			
			if ([ext isEqualToString: @"bz2"])
				p = @"/usr/bin/bunzip2";
			else if ([ext isEqualToString: @"gz"]
					 || [ext isEqualToString: @"Z"]
					 || [ext isEqualToString: @"z"])
				p = @"/bin/gunzip";
			else if ([ext isEqualToString: @"tgz"]
					 || [ext isEqualToString: @"taz"])
				{
				p = @"/bin/gunzip";
				tar = YES;
				}
			else
				continue;
			
			tmp = [NSString stringWithFormat:@"/tmp/%@.%d.workspace", f,
				   (int)[NSDate timeIntervalSinceReferenceDate]];
			NSLog(@"create temporary directory %@", tmp);
			if(![[NSFileManager defaultManager] createDirectoryAtPath:tmp
														   attributes:nil])
				return NO;
			
			if (tar || [s rangeOfString: @".tar"].length > 0)
				s = [NSString stringWithFormat:@"%@ -c %@ | tar xfpv -", p, s];
			else
				s = [NSString stringWithFormat:@"%@ %@", p, s];
			args = [NSArray arrayWithObjects: @"-c", s, nil];
			
			NSLog(@"launching with str arg %@",s);
			task = [NSTask new];
			[task setCurrentDirectoryPath: tmp];
			[task setLaunchPath: @"/bin/sh"];
			[task setArguments: args];
			
			[nc addObserver: self
				   selector: @selector(_taskDidTerminate:)
					   name: NSTaskDidTerminateNotification
					 object: task];
			[task launch];
			[task release];
			}	
		}
	else if([operation isEqualToString:NSWorkspaceEncryptOperation])
		{
		*tag = 5;
		}
	else if([operation isEqualToString:NSWorkspaceDecryptOperation])
		{
		*tag = 6;
		}
	if([operation isEqualToString:NSWorkspaceDestroyOperation])
		{
		*tag = 7;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent: f];
			NSString *a = [[NSProcessInfo processInfo] processName];
			
			result = NSRunAlertPanel(a, @"Destroy path: %@ ?", @"Destroy", 
									 @"Cancel", NULL, s);
			
			if (result == NSAlertDefaultReturn && ![[NSFileManager defaultManager] removeFileAtPath:s handler:0])
				return NO;
			NSLog(@"not deleting");
			}
		}
	else if([operation isEqualToString:NSWorkspaceRecycleOperation])
		{
		*tag = 8;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *d = [@"~/Library/Trash" stringByAppendingPathComponent:f];
			NSString *a = [[NSProcessInfo processInfo] processName];
			result = NSRunAlertPanel(a, @"Recycle: %@ to: %@?", @"Recycle", 
									 @"Cancel", NULL, s, d);
			if (result == NSAlertDefaultReturn && [[NSFileManager defaultManager] movePath:s toPath:d handler:0])
				return NO;
			NSLog(@"not moving");
			}
		}
	else if([operation isEqualToString:NSWorkspaceDuplicateOperation])
		{
		*tag = 9;
		while (count--)
			{
			NSString *f = [files objectAtIndex: count];
			NSString *n = [NSString stringWithFormat: @"CopyOf%@", f];
			NSString *s = [source stringByAppendingPathComponent:f];
			NSString *p = [source stringByAppendingPathComponent:n];
			
			if(![[NSFileManager defaultManager] copyPath:s toPath:p handler:0])
				return NO;
			}
		}
	[[self notificationCenter] postNotificationName:WORKSPACE(DidPerformFileOperation) object:self];
	return (result == NSAlertDefaultReturn) ? YES : NO;
}

- (NSString *) absolutePathForAppBundleWithIdentifier:(NSString *) bundleIdentifier;
{ // look up
	if (!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	return [__launchServices absolutePathForAppBundleWithIdentifier:bundleIdentifier];
}

- (NSString *) fullPathForApplication:(NSString *)appName
{
	if (!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	return [__launchServices fullPathForApplication:appName];
}

- (BOOL) getFileSystemInfoForPath:(NSString *)fullPath
					  isRemovable:(BOOL *)removableFlag
					   isWritable:(BOOL *)writableFlag
					isUnmountable:(BOOL *)unmountableFlag
					  description:(NSString **)description
							 type:(NSString **)fileSystemType
{
	return NO;
}

- (BOOL) getInfoForFile:(NSString *)fullPath
			application:(NSString **)appName
				   type:(NSString **)type
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSDictionary *app;
	BOOL is_dir;
	NSString *dummy;
	NSString *dummy2;
#if 0
	NSLog(@"getInfoForFile: %@", fullPath);
#endif
	if(!type)
		type=&dummy;
	if(!appName)
		appName=&dummy2;
	if(!fullPath || ![fullPath isAbsolutePath])
		{
		NSLog(@"NSWorkspace getInfoForFile requires an absolute path (%@)", fullPath);
		return NO;
		}
	if(![fm fileExistsAtPath:fullPath isDirectory:&is_dir])
		return NO;  // does not exist
	if (!__launchServices)
		[QSLaunchServices sharedLaunchServices];	// initialize if needed
	if((app = [__launchServices preferredIdentForExtension:[fullPath pathExtension]]))
		{ // try to get get application name from file extensions database
#if 1
			NSLog(@"app for extension %@ = %@", [fullPath pathExtension], app);
#endif
			*type=[app objectForKey:@"CFBundleTypeName"];
			*appName=[__launchServices applicationNameForIdent:[app objectForKey:@"CFBundleIdentifier"]];	// application name
#if 0
			NSLog(@"ext=%@", [fullPath pathExtension]);
			NSLog(@"preferred app=%@", app);
			NSLog(@"appname=%@", appName);
#endif
			if([*type length] != 0 && ![[app objectForKey:@"CFBundleTypeRole"] isEqualToString:@"None"])
				return YES; // found - and role is not None (i.e. providing Icon only)
		}
	if(is_dir)
		{ // directoy
			if([[fullPath pathExtension] isEqualToString: @"app"])  // should better check to be a bundle of type 'APPL'
				{
				*appName=fullPath;  // launch applications by themselves
				*type=NSApplicationFileType;
				return YES;
				}
			*appName=@"myFinder";	// open directories by default
			*type=NSDirectoryFileType;
			return YES;
		}
	// check for executable -> NSShellCommandFileType
	// check for mounted directory -> NSFilesystemFileType
	*appName=@"myFinder";	// default
	*type=NSPlainFileType;
	return NO;  // unknown plain file - no idea how to open
}

- (BOOL) isFilePackageAtPath:(NSString *) path
{ // check if it is a file package
	if(!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	return [__launchServices isFilePackageAtPath:path];
}

- (NSImage *) iconForFile:(NSString *)fullPath
{
	NSFileManager *fm = [NSFileManager defaultManager];
	NSImage *i=nil;
	NSBundle *b;
	NSString *icon;
	BOOL is_dir = NO;
#if 0
	NSLog(@"NSWorkspace iconForFile: %@", fullPath);
#endif
	if(!fullPath || ![fullPath isAbsolutePath])
		{
		NSLog(@"NSWorkspace iconForFile requires an absolute path (%@)", fullPath);
		return nil;
		}
	b=[NSBundle bundleWithPath:fullPath];
	icon=[b objectForInfoDictionaryKey:@"CFBundleIconFile"];
	if(icon && [icon length] > 0)
		{ // bundle exists and an icon has been defined
			icon=[icon stringByDeletingPathExtension];
#if 0
			NSLog(@"bundle icon file=%@", icon);
#endif
			icon=[b pathForResource:icon ofType:@"icns"];	// try to locate icon file within bundle
			if(icon)
				{
#if 0
				NSLog(@"bundle icon resource=%@", icon);
#endif
				i=[[[NSImage alloc] initByReferencingFile:icon] autorelease];
				if(i)
					return i;	// was able to load
				}
		}
	if([fm fileExistsAtPath:fullPath isDirectory:&is_dir])
		{
		i=[self iconForFileType:[fullPath pathExtension]];	// try on extension
#if 0
		NSLog(@"iconForFileType:%@=%@", [fullPath pathExtension], i);
#endif
		if(i)
			return i;	// found
		if(is_dir)
			{ // some type of directory
				NSString *home=NSHomeDirectory();
				NSString *lastComponent=[fullPath lastPathComponent];
				// check if directory contains a (hidden) "Icon\r" file
				if([fullPath isEqualToString:home])
					i=[NSImage imageNamed:@"GSHome.tiff"];
				else if([lastComponent isEqualToString:@"Applications"])
					i=[NSImage imageNamed:@"GSApplications.tiff"];
				else if([lastComponent isEqualToString:@"Games"])
					i=[NSImage imageNamed:@"GSGames.tiff"];
				else if([lastComponent isEqualToString:@"Utilities"])
					i=[NSImage imageNamed:@"GSUtilities.tiff"];
				else if([lastComponent isEqualToString:@"Network"])
					i=[NSImage imageNamed:@"GSNetwork.tiff"];
				else if([fullPath isEqualToString:@"/Users"])
					i=[NSImage imageNamed:@"GSUsers.tiff"];
				else if([fullPath isEqualToString:@"/Volumes"])
					i=[NSImage imageNamed:@"GSVolumes.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Documents"]])
					i=[NSImage imageNamed:@"GSDocuments.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Music"]])
					i=[NSImage imageNamed:@"GSMusic.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Pictures"]])
					i=[NSImage imageNamed:@"GSPictures.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Library/Favorites"]])
					i=[NSImage imageNamed:@"GSFavorites.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Library/Preferences"]])
					i=[NSImage imageNamed:@"GSPreferences.tiff"];
				else if([fullPath isEqualToString:[home stringByAppendingPathComponent:@"Library/.Trash"]])
					i=[NSImage imageNamed:@"GSTrash.tiff"];
				if(!i)
					i=[NSImage imageNamed:@"GSFolder.tiff"];	// default folder
			}
		else
			{ // some type of file - but unknown file extension
				// might decode more file attributes here
				if([fm isExecutableFileAtPath:fullPath])
					i=[NSImage imageNamed:@"GSUnix.tiff"];	// executable file
				else
					i=[NSImage imageNamed:@"GSDocument.tiff"];	// some default document
			}
		}
	if(i)
		return i;
	return [NSImage imageNamed: @"GSUnknown.tiff"];	// file or image does not exist
}

- (NSImage *) iconForFiles:(NSArray *) pathArray
{
	switch([pathArray count])
	{
		case 0:	return nil;	// no file
		case 1: return [self iconForFile:[pathArray objectAtIndex:0]];	// first
	}
	return [NSImage imageNamed:@"GSMultiple.tiff"];
}

- (NSImage *) iconForFileType:(NSString *) fileType
{
	NSString *path=nil;
	NSEnumerator *e;
	NSDictionary *a;
#if 0
	NSLog(@"iconForFileType %@", fileType);
#endif
	if(!fileType)
		return nil;
	if(!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	e=[[__launchServices identsForExtension:fileType] objectEnumerator];
	while((a=[e nextObject]))
		{ // locate first app with an icon for this extension
			path=[a objectForKey:@"CFBundleTypeIconPath"];	// look up icon path for known file extensions
			if(path)
				break;	// app has defined an icon
		}
#if 0
	NSLog(@"%@ has iconFile %@", fileType, path);
#endif
	if([path length] > 0)	// string is not nil and not empty
		return [[[NSImage alloc] initByReferencingFile:path] autorelease];	// database knows about this file type (path extension)
	return nil;	// unknown
}

- (void) findApplications
{ // update database
	if (!__launchServices)
		[QSLaunchServices sharedLaunchServices];
	// check if we just have updated...
	return [__launchServices findApplications];
}

- (BOOL) unmountAndEjectDeviceAtPath:(NSString *)path		// Unmount device
{
	// FIXME: unsafe for file names containing a ' -> use NSTask instead
	if(system([[NSString stringWithFormat:@"/bin/umount '%s'", [path fileSystemRepresentation]] UTF8String]) != 0)
		return NO;	// some error
	// check if we are a memory card that can be ejected
	// -> cardctl eject %d
	[[self notificationCenter] postNotificationName:WORKSPACE(WillUnmount)
											 object:self
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													 path, @"NSDevicePath",
													 nil]];
	// send NSWorkspaceWillUnmountNotification
	return YES;
}

static NSArray *prevList;

- (void) checkForRemovableMedia
{
	NSMutableArray *thisList;
	thisList=[NSMutableArray arrayWithCapacity:10];
#if 0
	// check /etc/mtab and /Volumes to identify removable media
	// check for changes
	// -> send NSWorkspaceDidMountNotification with NSDevicePath as the userInfo
	[[self notificationCenter] postNotificationName:WORKSPACE(DidMount)
											 object:self
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													 path, @"NSDevicePath",
													 nil]];
	[[self notificationCenter] postNotificationName:WORKSPACE(DidUnmount)
											 object:self
										   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
													 path, @"NSDevicePath",
													 nil]];
	//      or NSWorkspaceDidUnmountNotification if it disappeared
#endif
	[prevList release];
	prevList=[thisList retain];
}

- (NSArray *) mountNewRemovableMedia
{
	[self checkForRemovableMedia];
	// wait until they are mounted
	return prevList;
}

- (NSArray *) mountedRemovableMedia
{
	return prevList;
}

- (BOOL) fileSystemChanged						{ BOOL r=__fileSystemChanged; __fileSystemChanged=NO; return r; }
- (void) noteFileSystemChanged					{ __fileSystemChanged=YES; return; }
- (void) noteFileSystemChanged:(NSString *) path { __fileSystemChanged=YES; return; }
- (void) noteUserDefaultsChanged				{ __userDefaultsChanged = YES;}

- (BOOL) userDefaultsChanged
{
	BOOL hasChanged = __userDefaultsChanged;
	__userDefaultsChanged = NO;
	return hasChanged;
}

+ (NSString *) _activeApplicationPath:(NSString *) path;	// get access to the active applications data base
{
	static NSString *lsdatabase;
	if(!lsdatabase) lsdatabase=[[NSTemporaryDirectory() stringByAppendingPathComponent:@".QuantumSTEP.apps"] retain];
	if(path)
		return [lsdatabase stringByAppendingPathComponent:path];
	return lsdatabase;
}

- (NSArray *) launchedApplications;
{	// get list of launched applications from file system, i.e. a Plist for each app in /tmp/.QuantumSTEP - here we don't check if the app is still alive!
	NSString *lsdatabase=[NSWorkspace _activeApplicationPath:nil];
	NSEnumerator *e=[[NSFileManager defaultManager] enumeratorAtPath:lsdatabase];
	NSString *path;
	NSMutableArray *list=[NSMutableArray arrayWithCapacity:10];
	while((path=[e nextObject]))
		{
		NSDictionary *app;
		if([path hasPrefix:@"."])
			continue;	// skip
		if([path isEqualToString:@"active"])
			continue;	// skip active application
		path=[lsdatabase stringByAppendingPathComponent:path];	// get full path
		NS_DURING
			app=[NSDictionary dictionaryWithContentsOfFile:path];
#if 0
		NSLog(@"+ %@ -> %@", path, app);
#endif
			if([app count] == 6)	// appears to be complete (ignored otherwise)
				[list addObject:app];
		NS_HANDLER
			; // ignore exceptions
		NS_ENDHANDLER
		}
#if 0
	NSLog(@"launchedApplications=%@", list);
#endif
	return list;
}

- (NSDictionary *) activeApplication;
{
	return [NSDictionary dictionaryWithContentsOfFile:[NSWorkspace _activeApplicationPath:@"active"]];	// get description of active application
}

- (void) hideOtherApplications;
{
	// we should loop through launchedApplications
	// and send all others a note to hide message
	NSLog(@"hideOtherApplications");
	[[NSWorkspace _loginWindowServer] hideApplicationsExcept:getpid()];
}

+ (id <_NSLoginWindowProtocol>) _loginWindowServer;			// distributed workspace
{
	static id _loginWindowServer;	// system UI server used for inking, sound etc.
#if 0	// option to disable
	if(!_loginWindowServer)
		{
#if 1
		NSLog(@"get _loginWindowServer");
#endif
		NS_DURING
		_loginWindowServer = [NSConnection rootProxyForConnectionWithRegisteredName:NSLoginWindowPort host:nil];
#if 1
		NSLog(@"created _loginWindowServer=%@", _loginWindowServer);
#endif
		[_loginWindowServer retain];
#if 0
		NSLog(@"retained");
#endif
		[((NSDistantObject *) _loginWindowServer) setProtocolForProxy:@protocol(_NSLoginWindowProtocol)];
		NS_HANDLER
		NSLog(@"could not contact %@ due to %@ - %@", NSLoginWindowPort, [localException name], [localException reason]);
		_loginWindowServer=nil;	// no connection established
		// we could alternatively setup ourselves as a (local) server
		NS_ENDHANDLER
		}
#endif
#if 1
	NSLog(@"_loginWindowServer=%@", _loginWindowServer);
#endif
	return _loginWindowServer;
}

// should be replaced by directly calling [[QSLaunchServices sharedLaunchServices] applicationList] etc. (?)

- (NSDictionary *) _applicationList; { return [[QSLaunchServices sharedLaunchServices] applicationList]; }
- (NSDictionary *) _fileTypeList; { return [[QSLaunchServices sharedLaunchServices] fileTypeList]; }
+ (NSArray *) _knownApplications; { return [[QSLaunchServices sharedLaunchServices] knownApplications]; }

+ (NSDictionary *) _standardAboutOptions;
{
	NSMutableDictionary *d=[NSMutableDictionary dictionaryWithCapacity:6];
	id o;
	[d setObject:[[[NSAttributedString alloc] initWithString:@""] autorelease] forKey:@"Credits"];	// should look for ressource file Credits.rtf and load as NSAttributedString
	if((o=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"]))
		[d setObject:o forKey:@"ApplicationName"];
	else
		[d setObject:[[[[NSBundle mainBundle] bundlePath] lastPathComponent] stringByDeletingPathExtension] forKey:@"ApplicationName"];
	if((o=[NSImage imageNamed:@"NSApplicationIcon"]))
		[d setObject:o forKey:@"ApplicationIcon"];
	else if((o=[NSImage imageNamed:@"generic Application Icon in AppKit.framework"]))
		[d setObject:o forKey:@"ApplicationIcon"];
	if((o=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBuildVersion"]))
		[d setObject:o forKey:@"Version"];
	else if((o=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSHumanReadableCopyright"]))
		[d setObject:o forKey:@"Version"];
#if 0
	applicationVersion=[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
	applicationVersion=[NSString stringWithFormat:@"Version %@", version];
#endif
	return d;
}

- (int) extendPowerOffBy:(int)requested;
{
	// touch some system file so that the loginwindow process can monitor
	return 0;
}

- (void) slideImage:(NSImage *)image
			   from:(NSPoint)fromPoint
				 to:(NSPoint)toPoint;
{
	static NSWindow *window;
	static NSImageView *view;
	NSSize size=[image size];
	NSRect fromRect={ fromPoint, size };
	NSRect toRect={ toPoint, size };
	if(!window)
		{
		window=[[NSWindow alloc] initWithContentRect:fromRect styleMask:NSBorderlessWindowMask backing:NSBackingStoreRetained defer:YES];
		view=[[[NSImageView alloc] initWithFrame:(NSRect){ NSZeroPoint, size }] autorelease];
		[window setContentView:view];
		}
	else
		[window setFrame:fromRect display:NO];
	[view setImage:image];
	[window orderFront:nil];
	[window setFrame:toRect display:NO animate:YES];	// slide to new location
	// make window disappear after sliding ends!
}

@end
