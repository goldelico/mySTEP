/* 
   NSBundle.m

   Implementation of NSBundle class.

   Copyright (C) 1993 Free Software Foundation, Inc.

   Author:  Adam Fedor <fedor@boulder.colorado.edu>
   Date:	May 1993
   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:	January 1999
   Author:  H. Nikolaus Schaller <hns@computer.org>
   Date:	August 2003 - Adapted to use the MacOS X convention of App.app/Contents/<architecture>

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSObjCRuntime.h>
#import <Foundation/NSBundle.h>
#import <Foundation/NSException.h>
#import <Foundation/NSFileManager.h>
#import <Foundation/NSString.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSProcessInfo.h>
#import <Foundation/NSLocale.h>
#import <Foundation/NSUserDefaults.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSLock.h>
#import <Foundation/NSMapTable.h>
#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSPathUtilities.h>
#import <Foundation/NSTimeZone.h>

#import "NSPrivate.h"

typedef enum {
	NSBUNDLE_BUNDLE = 1, 
	NSBUNDLE_APPLICATION, 
	NSBUNDLE_FRAMEWORK,
} bundle_t;

//
// Class variables
//

static NSBundle *__mainBundle;
static NSMapTable *__bundles;	// map bundle path to NSBundle
static NSMapTable *__bundlesForExecutables;	// map C file name to NSBundle
static NSString *__launchCurrentDirectory;

// When we are linking in an object file, objc_load_modules 
// calls our callback routine for every Class and Category 
// loaded.  The following variable stores the bundle that 
// is currently doing the loading so we know where to store 
// the class names.

static id __loadingBundle = nil;
static NSRecursiveLock *__loadLock = nil;

void _bundleLoadCallback(Class theClass, Category *theCategory);

//*****************************************************************************
//
// 		NSBundle 
//
//*****************************************************************************

@implementation NSBundle

+ (void) initialize
{
#if 0
	NSLog(@"NSBundle +initialize");
#endif
//	fprintf(stderr, "NSBundle +initialize\n");
    if ((!__mainBundle) && self == [NSBundle class]) 
		{ // initialize for mainBundle
		NSProcessInfo *pi = [NSProcessInfo processInfo];
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *path = [[pi arguments] objectAtIndex:0];
		NSString *virtualRoot;
		int vrl;
		__bundles = NSCreateMapTable(NSObjectMapKeyCallBacks,
									 NSObjectMapValueCallBacks, 0);	// retains...
		__bundlesForExecutables = NSCreateMapTable(NSNonOwnedCStringMapKeyCallBacks,
									NSObjectMapValueCallBacks, 0);
		virtualRoot=[NSString stringWithUTF8String:[@"/" fileSystemRepresentation]];
		vrl=[virtualRoot length]-1;
//		fprintf(stderr, " vRoot=%p\n", virtualRoot);
#if 0
		NSLog(@"args=%@", [pi arguments]);
		NSLog(@"$0=%@", path);
		NSLog(@"virtualRoot=%@", virtualRoot);
#endif
		if(![path isAbsolutePath])
			{ // $0 is a relative path
			NSString *PATH=[[pi environment] objectForKey:@"PATH"];
			NSEnumerator *e=[[PATH componentsSeparatedByString:@":"] objectEnumerator];
			NSString *basepath;
			while((basepath=[e nextObject]))
				{
				NSString *p;
				if([basepath length] == 0 || [basepath isEqualToString:@"."])
					basepath=[[fm currentDirectoryPath] stringByAppendingPathComponent:path];	// denotes relative location
				p=[basepath stringByAppendingPathComponent:path];
#if 0
				NSLog(@"check %@", p);
#endif
				if([fm fileExistsAtPath:p])
					{ //  found
					path=p;
#if 0
					NSLog(@"found %@", path);
#endif
					break;
					}
				}
			}
		__launchCurrentDirectory=[[fm currentDirectoryPath] retain];
		if([path hasPrefix:@"./"])
			path=[__launchCurrentDirectory stringByAppendingPathComponent:path];	// denotes relative location
#if OLD
		if([path hasPrefix:@"/hdd2"])
			path=[path substringFromIndex:5];	// strip off - just in case of C3000...
		if([path hasPrefix:@"/home/root"])
			path=[path substringFromIndex:10];	// strip off - just in case of gdb on Zaurus (/usr/share -> /home/root/usr/share)
#endif
		if([path hasPrefix:virtualRoot])
			path=[path substringFromIndex:vrl];	// strip off - just in case...
#if 0
		NSLog(@"check for executable at %@", path);
#endif
		if(![fm fileExistsAtPath:path])
			{ // executable does not exist or is not found where it should be -> no main bundle
			[NSException raise:NSInternalInconsistencyException format: @"Can't find executable in main bundle: %@", path];
			}
		path = [path stringByDeletingLastPathComponent];		// Strip off the name of the program
		if([[path lastPathComponent] isEqualToString:@"."])
			path = [path stringByDeletingLastPathComponent];	// was called as ./executable
#ifdef __linux__
		// should be made conditionally so that we can access a binary tool like 'open' or 'defaults' as mainBundle
		path = [path stringByDeletingLastPathComponent];		// Strip off the name of the processor
		path = [path stringByDeletingLastPathComponent];		// Strip off 'Contents'
#endif
#if 0
		NSLog(@"NSBundle: main bundle path is %@", path);
#endif
#if 0
		NSLog(@"NSBundle: __loadLock lock");
#endif
		[__loadLock lock];
		__mainBundle = [[NSBundle alloc] initWithPath:path];
		if(!__mainBundle)
			[NSException raise:NSInternalInconsistencyException format: @"Not a main bundle at %@", path];
		__mainBundle->_bundleType = (unsigned int) NSBUNDLE_APPLICATION;
#if 0
		NSLog(@"NSBundle: before loadunlock 1");
#endif
		[__loadLock unlock];
#if 0
		NSLog(@"NSBundle: after loadunlock 1");
#endif
		[NSUserDefaults resetStandardUserDefaults]; // force reload
		[NSTimeZone resetSystemTimeZone];			// here too
#if 0
		NSLog(@"NSBundle: +initialize done: mainBundle=%@", __mainBundle);
#endif
		}
}

+ (NSBundle *) mainBundle			{ return __mainBundle; }				

+ (NSBundle *) bundleForClass:(Class)aClass
{
	char *file;
	NSString *path=nil;
	NSString *bpath;	// used to search the bundle
	NSBundle *bundle;
	if(!aClass)
		return nil;
#if 0
	NSLog(@"bundleForClass %@", NSStringFromClass(aClass));
#endif
	file=objc_dynamic_find_file(aClass);	// get the path of the dynamic file that defines the class record
#if 0
	NSLog(@"file=%s", file);
#endif
	if(!file)
		{
//		[NSException raise:NSInvalidArgumentException
//					format:@"No executable found for class %@", NSStringFromClass(aClass)];
		return __mainBundle;	// if nowhere defined
		}
	if((bundle = (NSBundle *)NSMapGet(__bundlesForExecutables, file)))	// look up by filename - if already known
		return bundle;
	path=[[NSFileManager defaultManager] stringWithFileSystemRepresentation:file length:strlen(file)];
	if([path hasPrefix:@"./"])
		path=[__launchCurrentDirectory stringByAppendingPathComponent:path];	// denotes relative location
#if OLD
	if([path hasPrefix:@"/hdd2"])
		path=[path substringFromIndex:5];	// strip off - just in case of C3000...
	if([path hasPrefix:@"/home/root"])
		path=[path substringFromIndex:10];	// strip off - just in case of gdb on Zaurus (/usr/share -> /home/root/usr/share)
#endif
#if 0
	NSLog(@"path=%@", path);
#endif
	bpath=path;
	while([bpath length] > 1)
		{ // search upwards until we have found the anchor point
		bpath=[bpath stringByDeletingLastPathComponent];	// remove executable name etc.
		bundle=[self bundleWithPath:bpath];	// try to open
#if 0
		NSLog(@"try %@: %@", bundle, [bundle executablePath]);
#endif
		if(bundle && [[bundle executablePath] isEqualToString:path])
			{ // found!
			NSMapInsert(__bundlesForExecutables, file, bundle); // save in cache!
#if 0
			NSLog(@"found %@ -> %@", bundle, [bundle executablePath]);
#endif
			return bundle;
			}
		}
	NSLog(@"could not locate bundle for class %@", NSStringFromClass(aClass));
	return __mainBundle;	// default if not found
}

+ (NSBundle *) bundleWithPath:(NSString *)path
{
	return [[[self alloc] initWithPath: path] autorelease];
}

- (id) initWithPath:(NSString *)path;
{
	NSBundle *bundle;
	NSString *exec;
	BOOL isdir;

	if (!path || [path length] == 0)
		{
		NSLog(@"No path specified for bundle");
		[self release];
		return nil;
		}

	if ((bundle = (NSBundle *) NSMapGet(__bundles, path)))
		{ // Check if we were already init'd for this directory
		[self release];
		return [bundle retain];
		}

	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isdir] || !isdir)
		{
#if 0
		NSLog(@"Could not access path %@ for bundle", path);
#endif
		[self release];
		return nil;
		}

	if([path hasSuffix:@".framework"])
		_bundleType = (unsigned int) NSBUNDLE_FRAMEWORK;
	else
		_bundleType = (unsigned int) NSBUNDLE_BUNDLE;
	
	_searchPaths = [[NSMutableDictionary alloc] initWithCapacity: 4];
	_path = [path copy];
	if(_bundleType == (unsigned int) NSBUNDLE_FRAMEWORK)
		_bundleContentPath=[_path stringByAppendingPathComponent:@"Versions/Current"];
	else
		_bundleContentPath=[_path stringByAppendingPathComponent:@"Contents"];
	[_bundleContentPath retain];

#if 0	// does not work for Framework bundles because the default Info.plist is in _bundleContentPath/Resources
	if (![[NSFileManager defaultManager] fileExistsAtPath:[_bundleContentPath stringByAppendingPathComponent:@"Info.plist"]])
		{
#if 0
		NSLog(@"Could not find Info.plist for bundle %@", path);
#endif
		[self release];
		return nil;
		}
#endif

#if 0
	NSLog(@"_bundleContentPath=%@", _bundleContentPath);
#endif
	NSMapInsert(__bundles, _path, self);	// map by bundle path (retains!)
	
	// CHECKME: __bundlesForExecutables uses a C string (absolute file name) as the key
	// we may have to use the fileSystemRepresentation
	
#if 0
	if((exec=[self executablePath]))
		{ // we have a executable
#if 0
			NSLog(@"info dict=%@", [self infoDictionary]);
			NSLog(@"[bundle executablePath]=%@", exec);
#endif
			NSMapInsert(__bundlesForExecutables, exec, self);	// map by executable path (retains!)			
		}
#endif
	return self;
}

- (void) dealloc
{
	NSMapRemove(__bundles, _path);
	NSMapRemove(__bundlesForExecutables, NULL);
	[_localizations release];
	[_preferredLocalizations release];
	[_bundleClasses release];
	[_infoDict release];
	[_path release];
	[_bundleContentPath release];
	[_searchPaths release];
	[super dealloc];
}

- (NSString *) bundlePath				{ return _path; }

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@: path=%@\n  infoDict=%@\n  searchPaths=%@\n  bundleClasses=%@",
		NSStringFromClass([self class]),
		_path,
		_infoDict,
		_searchPaths,
		_bundleClasses];
}

- (Class) classNamed:(NSString *)className
{
	Class theClass = Nil;

	if (!_codeLoaded && (self != __mainBundle) && ![self load]) 
		{
		NSLog(@"No classes in bundle");
		return Nil;
		}
	// look if the class was really defined in our bundle
	if (self == __mainBundle) 
		{
		theClass = NSClassFromString(className);
		if (theClass && [[self class] bundleForClass:theClass] != __mainBundle)
			theClass = Nil;
		} 
	else 
		{
		int j = [_bundleClasses indexOfObject: NSClassFromString(className)];

		if (j != NSNotFound)
			theClass = [_bundleClasses objectAtIndex: j];
		}
  
	return theClass;
}

- (Class) principalClass
{
#if 0
	NSLog(@"principalClass");
#endif
	if(!_principalClass)
		{
		NSString *n = [[self infoDictionary] objectForKey:@"NSPrincipalClass"];
#if 0
		NSLog(@"infoDictionary - principalClass: %@", n);
#endif
		if(self == __mainBundle) 
			{
			_codeLoaded = YES;
			if(n)
				_principalClass = NSClassFromString(n);
			else
				NSLog(@"NSPrincipalClass is not defined in Info.plist (%@)", [self infoDictionary]);
			}
		else
			{
			if([self load] == NO)
				return Nil;		
			if(n)
				_principalClass = NSClassFromString(n);
			if(!_principalClass && ([_bundleClasses count]))
				_principalClass = [_bundleClasses objectAtIndex:0];	// use first
			}
		}

	return _principalClass;
}

- (void) _addClass:(Class)aClass
{
	[_bundleClasses addObject:(id)aClass];
}

- (BOOL) preflightAndReturnError:(NSError **) error;
{
	if (!_codeLoaded) 
		{
		NSString *obj=[self executablePath];
		if(!obj)
			{
			if(error) *error=[NSError errorWithDomain:@"NSBundleLoading" code:0 userInfo:nil];
			return NO;
			}
		}
	return YES;	// we don't know better...
}

- (BOOL) loadAndReturnError:(NSError **) error;
{
#if 0
	NSLog(@"-load %@", self);
#endif
	[__loadLock lock];
	if (!_codeLoaded) 
		{
		NSString *obj=[self executablePath];
		if(!obj)
			{
			if(error) *error=[NSError errorWithDomain:@"NSBundleLoading" code:0 userInfo:nil];
			return NO;
			}
		_bundleClasses = [[NSMutableArray arrayWithCapacity:2] retain];
		__loadingBundle = self;
		
#ifdef NeXT_RUNTIME		// FIXME rewrite routine per NeXT to avoid this mess
		char *modPtr[2] = {"", NULL};
		modPtr[0] = (char *) [obj fileSystemRepresentation];
		if(objc_loadModules(modPtr, stderr, _bundleLoadCallback, NULL,NULL))
#else /* !NeXT_RUNTIME */
			if(objc_load_module([obj fileSystemRepresentation], stderr, _bundleLoadCallback, NULL, NULL))
#endif /* NeXT_RUNTIME */
				{ // could not properly load
#if 0
					NSLog(@"NSBundle: before loadunlock 2");
#endif
					[__loadLock unlock];
#if 0
					NSLog(@"NSBundle: after loadunlock 2");
#endif
#if 0
					fprintf(stderr, "could not properly load\n");
#endif
					if(error) *error=[NSError errorWithDomain:@"NSBundleLoading" code:1 userInfo:nil];
					return NO;
				}
			else
				{
				NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
				NSDictionary *dict;
				
				dict = [NSDictionary dictionaryWithObjects: (id *) &_bundleClasses
												   forKeys: (id *) &NSLoadedClasses 
													 count: 1];
				_codeLoaded = YES;
				__loadingBundle = nil;
				[nc postNotificationName: NSBundleDidLoadNotification 
								  object: self
								userInfo: dict];
				}	
		}
#if 0
	NSLog(@"NSBundle: before loadunlock 3");
#endif
	[__loadLock unlock];
#if 0
	NSLog(@"NSBundle: after loadunlock 3");
#endif
	return YES;
}

- (BOOL) load
{
	return [self loadAndReturnError:NULL];
}

- (BOOL) unload;
{
	return NO;	// we can't unload bundles
}

+ (NSString *) _findFileInPath:(NSString *) path andName:(NSString *)name
{ // Find the first directory entry with a given name (with any extension)
	NSArray *resources=[[NSFileManager defaultManager] directoryContentsAtPath:path];
	int i;
#if 0
	NSLog(@"_resourcePathForPath:%@ andName:%@", path, name);
#endif
	for(i=[resources count]-1; i>= 0; i--)  // well, we are reading backwards, but order isn't guaranteed either...
		{
		if([[[resources objectAtIndex:i] stringByDeletingPathExtension] isEqualToString:name])
			{ // found!
			path=[path stringByAppendingPathComponent:[resources objectAtIndex:i]];   // compose
#if 0
			NSLog(@"found %@", path);
#endif
			return path;
			}
		}
#if 0
	NSLog(@"no match");
#endif
	return nil; // no match
}

+ (NSArray *) pathsForResourcesOfType:(NSString *) ext inDirectory:(NSString *)bundlePath;
{
	return [[self bundleWithPath:bundlePath] pathsForResourcesOfType:ext inDirectory:nil];
}

+ (NSString *) pathForResource:(NSString *)name
						ofType:(NSString *)ext
				   inDirectory:(NSString *)bundlePath;
{
	return [[self bundleWithPath:bundlePath] pathForResource:name ofType:ext];
}

- (NSString *) pathForResource:(NSString *)name
						ofType:(NSString *)ext
						inDirectory:(NSString *)bundlePath
			   forLocalization:(NSString *)locale;
{
	NSEnumerator *e;
	NSString *path;
	int extLength;
	NSAutoreleasePool *arp;
	NSString *fullpath = nil;
	NSFileManager *fm=[NSFileManager defaultManager];
#if 0
	NSLog(@"%@ pathForResource:%@ ofType:%@ inDirectory:%@ forLocalization:%@", [self bundlePath], name, ext, bundlePath, locale);
#endif
	if (!name || [name length] == 0) 
		[NSException raise: NSInvalidArgumentException
        			 format: @"No resource name specified."];
	arp=[NSAutoreleasePool new];
	e = [self _resourcePathEnumeratorFor:_path subPath:bundlePath localization:locale];
	extLength = (ext) ? [ext length] : 0;
	if (extLength > 0)
		{ // has an extension
		while((path = [e nextObject]))
			{
			fullpath = [NSString stringWithFormat:@"%@/%@.%@", path, name, ext];
#if 0
			NSLog(@"try1: %@", fullpath);
#endif
			if([fm fileExistsAtPath:fullpath]) 
				break;	// found
			}
		if(!path)
			fullpath=nil;	// not found
		}
	else
		{ // no extension given
		while((path = [e nextObject]))
			{
			fullpath = [NSString stringWithFormat: @"%@/%@", path, name];
#if 0
			NSLog(@"try2: %@", fullpath);
#endif
			if([fm fileExistsAtPath:fullpath]) 
				break;
			if((fullpath = [isa _findFileInPath:path andName:name]))
				break;
			}
		if(!path)
			fullpath=nil;	// not found
		}
#if 0
	NSLog(@"found: %@", fullpath);
#endif
	[fullpath retain];
	[arp release];
	return [fullpath autorelease];	// autorelease one level above private ARP
}

- (NSString *) pathForResource:(NSString *)name ofType:(NSString *)ext;
{
	return [self pathForResource:name ofType:ext inDirectory:nil forLocalization:nil];
}

- (NSString *) pathForResource:(NSString *)name
						ofType:(NSString *)ext	
				   inDirectory:(NSString *)subpath
{
	return [self pathForResource:name
						  ofType:ext	
					 inDirectory:subpath
				 forLocalization:nil];
}

- (NSArray *) pathsForResourcesOfType:(NSString *)extension
						  inDirectory:(NSString *)bundlePath
					  forLocalization:(NSString *)locale;
{
	NSString *path;
	NSMutableArray *resources = [NSMutableArray arrayWithCapacity: 2];
	NSEnumerator *e;
	NSString *ext=[NSString stringWithFormat:@".%@", extension];	// contains nonsense if extension is empty
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
#if 0
	NSLog(@"%@ pathsForResourcesOfType:%@ inDirectory:%@", extension, bundlePath);
#endif

	e = [self _resourcePathEnumeratorFor:_path subPath:bundlePath localization:locale];

	while((path = [e nextObject]))
		{ // search path
		NSArray *files=[[NSFileManager defaultManager] directoryContentsAtPath:path];
		NSEnumerator *f=[files objectEnumerator];
		NSString *file;
#if 0
		NSLog(@"files=%@ eee=%@", files, ext);
#endif
		if(![extension length])
			[resources addObjectsFromArray:files];  // add them all
		else
			{
			while((file=[f nextObject]))
				{
				if([file hasSuffix:ext])
					[resources addObject:[path stringByAppendingPathComponent:file]];	// add only matching suffixes
				}
			}
		}
	[resources retain];
	[arp release];
	return [resources autorelease];
}

- (NSArray *) pathsForResourcesOfType:(NSString *)extension
						  inDirectory:(NSString *)subpath
{
	return [self pathsForResourcesOfType:extension	
							 inDirectory:subpath
						 forLocalization:nil];
}

- (NSString *) localizedStringForKey:(NSString *)key	
							   value:(NSString *)value
							   table:(NSString *)tableName
{
	NSString *ls = nil;
	if (!tableName)
		tableName = [self pathForResource:@"Localizable" ofType:@"strings"];
	if (!tableName)
		{
		NSArray *r = [self pathsForResourcesOfType:@"strings" inDirectory:nil];

		if (r && [r count])
			tableName = [r objectAtIndex: 0];
		}

	if (tableName)
		{
		NSDictionary *dict = [NSDictionary alloc];

		[[dict initWithContentsOfFile: tableName] autorelease];
		ls = [dict objectForKey: key];
		}
	if(ls == nil)			// OS spec calls for [key uppercaseString] not key
		ls = (!value || ([value length] == 0)) ? key : value;
	return ls;
}

- (NSDictionary *) infoDictionary
{
	NSString *path=nil;
#if 0
	NSLog(@"infoDictionary");
#endif
	if(_infoDict == nil)
		{ // not yet cached
		NS_DURING
			{
				NSAutoreleasePool *arp=[NSAutoreleasePool new];
				path=[self pathForResource:@"Info" ofType:@"plist"];
#if 0
				NSLog(@"infoDictionary path=%@", path);
#endif
				if(path)
					_infoDict = [NSDictionary dictionaryWithContentsOfFile:path];
				else
					_infoDict = [NSDictionary dictionary];	// empty!
				[_infoDict retain]; // keep a reference
				[arp release];	// release all temporaries
			}
		NS_HANDLER
			NSLog(@"Exception while reading Info.plist from path %@: %@", path, [localException reason]);
			path=nil;
			_infoDict=nil; // e.g. NSXMLParseError
		NS_ENDHANDLER
		}
	return _infoDict;
}

// added by HNS

+ (NSBundle *) bundleWithIdentifier:(NSString *) ident;
{
	// FIXME: make faster by using a mapping table for ident -> bundle
	void *key; 
	NSBundle *bundle;
	NSMapEnumerator e;
	e=NSEnumerateMapTable(__bundles);
	while(NSNextMapEnumeratorPair(&e, &key, (void **)&bundle))	// key is the path
		{
		if([[bundle bundleIdentifier] isEqualToString:ident])
			return bundle;
		}
	return nil;	// not found
}

+ (NSArray *) allBundles;
{ // MapTable has a function to get all values...
	void *key; 
	NSBundle *bundle;
	NSMapEnumerator e;
	NSMutableArray *list=[NSMutableArray arrayWithCapacity:NSCountMapTable(__bundles)];
	e=NSEnumerateMapTable(__bundles);
	while(NSNextMapEnumeratorPair(&e, &key, (void **)&bundle))
		[list addObject:bundle];
	return list;
}

+ (NSArray *) allFrameworks;
{
	void *key; 
	NSBundle *bundle;
	NSMapEnumerator e;
	NSMutableArray *list=[NSMutableArray arrayWithCapacity:NSCountMapTable(__bundles)];
	e=NSEnumerateMapTable(__bundles);
	while(NSNextMapEnumeratorPair(&e, &key, (void **)&bundle))
		{
		if(bundle->_bundleType == (unsigned int) NSBUNDLE_FRAMEWORK)
			[list addObject:bundle];
		}
	return list;
}

- (id) objectForInfoDictionaryKey:(NSString *) key; { return [[self infoDictionary] objectForKey:key]; }

- (NSDictionary *) localizedInfoDictionary;	{ return NIMP; }

- (NSString *) bundleIdentifier;
{
	NSString *ident=[self objectForInfoDictionaryKey:@"CFBundleIdentifier"];
	if(!ident)
		ident=[[_path lastPathComponent] stringByDeletingPathExtension];	// use bundle name w/o .app instead
	return ident;
}

- (NSString *) developmentLocalization;	{ return [self objectForInfoDictionaryKey:@"CFBundleDevelopmentRegion"]; }


// #define NOTICE(notif_name) NSApplication##notif_name##Notification

- (NSString *) pathForAuxiliaryExecutable:(NSString *) name;
{
#ifdef __APPLE__
	return [[_bundleContentPath stringByAppendingPathComponent:@"MacOS"] stringByAppendingPathComponent:name];
#else
	if(_bundleType == (unsigned int) NSBUNDLE_FRAMEWORK)
		// ARCHITECTURE macro is defined on cc command line
		return [_path stringByAppendingFormat:@"/Versions/Current/%@/%@", ARCHITECTURE, name];
	return [[_bundleContentPath stringByAppendingPathComponent:ARCHITECTURE] stringByAppendingPathComponent:name];
#endif
}

- (NSString *) executablePath;
{ // determine platform dependent location of executable
	NSString *name=[self objectForInfoDictionaryKey:@"CFBundleExecutable"];
	if(!name)
		name=[self objectForInfoDictionaryKey:@"NSExecutable"];
	if(!name)
		return nil;	// no executable defined
	return [self pathForAuxiliaryExecutable:name];
}

- (NSArray *) executableArchitectures;
{ // should return an array of NSNumbers with architecture numbers...
	return NIMP;
}

- (NSString *) resourcePath { return [_bundleContentPath stringByAppendingPathComponent:@"Resources"]; }
- (NSString *) builtInPlugInsPath; { return [_bundleContentPath stringByAppendingPathComponent:@"PlugIns"]; }
- (NSString *) privateFrameworksPath; { return [_bundleContentPath stringByAppendingPathComponent:@"PrivateFrameworks"]; }
- (NSString *) sharedFrameworksPath; { return [_bundleContentPath stringByAppendingPathComponent:@"Frameworks"]; }
- (NSString *) sharedSupportPath; { return [_bundleContentPath stringByAppendingPathComponent:@"Framework Support"]; }

- (BOOL) isLoaded;	{ return _codeLoaded; }

- (NSArray *) localizations;
{ // find all localizations
#if 0
	NSLog(@"localizations");
#endif
	if(!_localizations)
		{
		NSArray *files=[[NSFileManager defaultManager] directoryContentsAtPath:[self resourcePath]];
		NSEnumerator *f=[files objectEnumerator];
		NSString *file;
		if(!_infoDict)
			{ // we are bootstrapping (i.e. looking for global Info.plist)
#if 0
			NSLog(@"bootstrapping localization");
#endif
			return [NSArray arrayWithObject:@"English"];
			}
		_localizations=[[NSMutableArray alloc] initWithCapacity:10];
		while((file=[f nextObject]))
			{
#if 0
			NSLog(@"check %@", file);
#endif
			if([file hasSuffix:@".lproj"])
				[_localizations addObject:[file substringToIndex:[file length]-6]];	// add basic name
			}
		}
#if 0
	NSLog(@"localizations=%@", _localizations);
#endif
	return _localizations;
}

- (NSArray *) preferredLocalizations;
{
	if(!_preferredLocalizations)
		_preferredLocalizations=[[isa preferredLocalizationsFromArray:[self localizations] forPreferences:nil] retain];
#if 0
	NSLog(@"preferredLocalizations=%@", _preferredLocalizations);
#endif
	return _preferredLocalizations;
}

+ (NSArray *) preferredLocalizationsFromArray:(NSArray *) array;
{
	return [self preferredLocalizationsFromArray:array forPreferences:nil];
}

+ (NSArray *) preferredLocalizationsFromArray:(NSArray *) array
							   forPreferences:(NSArray *) pref;
{
	NSMutableArray *r=[NSMutableArray arrayWithCapacity:[array count]];
	NSEnumerator *e=[array objectEnumerator];
	NSString *locale;
#if 0
	NSLog(@"preferredLocalizationsFromArray:%@ forPreferences:%@", array, pref);
#endif
	if(!pref)
		{
		// get from user defaults
		pref=[NSArray arrayWithObjects:@"English", @"German", @"French", nil];
		}
	while((locale=[e nextObject]))
		{
#if 0
		NSLog(@"preferredLocalizationsFromArray: %@", locale);
#endif
		if([pref containsObject:locale])
			[r addObject:locale];	// included in preferences
		}
#if 0
	NSLog(@"preferredLocalizationsFromArray=%@ array=%@", r, array);
#endif
	if([r count] == 0 && [array count] > 0)	// intersection is empty
		[r addObject:[array lastObject]];	// take any one
#if 0
	NSLog(@"preferredLocalizationsFromArray=%@", r);
#endif
	return r;
}

	//*****************************************************************************
	//
	//	Constructs an array of paths, where each path is a possible location
	//	for a resource in the bundle.  The current algorithm for searching goes:
	//
	//     <root bundle path> /Resources/ <subpath>
	//     <root bundle path> /Resources/ <subpath> / <language.lproj>
	//     <root bundle path> / <subpath>
	//     <root bundle path> / <subpath> / <language.lproj>
	//
	//*****************************************************************************


+ (NSString *) _bundleResourcePath:(NSString *) root subpath:(NSString *) bundlePath language:(NSString *)lang
{ // Construct a potential resource path from components
	if(bundlePath && [bundlePath length] != 0)
		{ // there is a subpath
		if([bundlePath isAbsolutePath])
			root=bundlePath;	// override any primary path
		else
			root=[root stringByAppendingPathComponent:bundlePath];
		}
	if(lang)
		root=[NSString stringWithFormat: @"%@/%@.lproj", root, lang];
#if 0
	NSLog(@"_bundleResourcePath... = %@", root);
#endif
	return root;
}

- (NSEnumerator *) _resourcePathEnumeratorFor:(NSString*) path subPath:(NSString *) subpath localization:(NSString *) locale;
{
	NSMutableArray *paths;
	NSString *cachekey=[NSString stringWithFormat:@"%@//%@", locale, subpath];	// might add <nil> - but we don't care...
#if 0
	NSLog(@"_resourcePathEnumeratorFor:%@ subPath:%@ localization:%@", path, subpath, locale);
	NSLog(@"cachekey=%@", cachekey);
#endif
	paths=[_searchPaths objectForKey:cachekey];	// get from cache for given locale and subpath
	if(!paths)
		{
		NSAutoreleasePool *arp=[NSAutoreleasePool new];
		NSArray *languages=[locale length]?(NSArray *)[NSArray arrayWithObject:locale]:[self preferredLocalizations];	// search specific or all
		NSEnumerator *e;
		NSString *language;
		NSString *primary;
		paths=[NSMutableArray arrayWithCapacity:12];	// typical size
#if 1	// Cocoa appears to recognize this as well although not documented
		[paths addObject:[isa _bundleResourcePath:_path subpath:subpath language:nil]];
#endif
		if(!_searchPaths)
			_searchPaths=[[NSMutableDictionary dictionaryWithCapacity:2] retain];
		[_searchPaths setObject:paths forKey:cachekey];	// cache search paths for given locale and subpath
		primary=[_bundleContentPath stringByAppendingPathComponent:@"Resources"];
		[paths addObject:[isa _bundleResourcePath:primary subpath:subpath language:nil]];
		e=[languages objectEnumerator];
		while((language = [e nextObject]))
			[paths addObject:[isa _bundleResourcePath:primary subpath:subpath language:language]];
		[paths addObject:[isa _bundleResourcePath:_bundleContentPath subpath:subpath language:nil]];
		e=[languages objectEnumerator];
		while((language = [e nextObject]))
			[paths addObject:[isa _bundleResourcePath:_bundleContentPath subpath:subpath language:language]];
		[arp release];
#if 0
		NSLog(@"  -> %@", paths);
#endif	
		}
	return [paths objectEnumerator];
}

@end /* NSBundle */

void _bundleLoadCallback(Class theClass, Category *theCategory)
{
#if 0
		fprintf(stderr, "_bundleLoadCallback\n");
#endif
		NSCAssert(__loadingBundle, NSInternalInconsistencyException);
		if(!theCategory)								// Don't store categories
			[__loadingBundle _addClass:theClass];
#if 1
	else
		NSLog(@"Warning: _bundleLoadCallback __loadingBundle=%@ theClass=%08x is not a class, theCategory=%08x", __loadingBundle, theClass, theCategory);
#endif
}

/* EOF */
