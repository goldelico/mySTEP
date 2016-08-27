/*$Id: NSTask_SenAdditions.m,v 1.4 2001/11/22 13:11:48 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "NSTask_SenAdditions.h"
#import "SenEmptiness.h"
#import "SenCollection.h"
#import "NSArray_SenAdditions.h"
#import "NSBundle_SenAdditions.h"
#import "NSString_SenAdditions.h"

#ifdef WIN32
#define CAN_INSERT_LIBRARIES NO
#else
#define CAN_INSERT_LIBRARIES YES
#endif

#define CAN_LAUNCH_WITH_GDB  YES


//#warning FIXME: Hardcoded paths!
#ifdef WIN32
#define GDB_PATH @"C:/Next/NextDeveloper/Executables/gdb.exe"
#else
#define GDB_PATH @"/usr/bin/gdb"
#endif


#ifdef WIN32
// FIXME Shouldn't be automatic ?
static NSString *bundleInserterCommandFile = @"BundleInserter-windows";
#else
static NSString *bundleInserterCommandFile = @"BundleInserter";
#endif

@implementation NSTask (SenAdditions)

+ (id) taskWithLaunchPath:(NSString *) path arguments:(NSArray *) arguments bundlesToInsert:(NSArray *) bundles
{
    return [[[self alloc] initWithLaunchPath:path arguments:arguments bundlesToInsert:bundles] autorelease];
}


- (NSBundle *) bundle
{
    NSString *className = @"NSFramework_SenFoundation";
    return [NSBundle bundleForClass:NSClassFromString(className)];    
}


- (NSString *) insertCommandPreambleWithArguments:(NSArray *) arguments
{
    NSString *gdbCommandsPath = [[self bundle] pathForResource:bundleInserterCommandFile ofType:@"preamble"];
    NSString *gdbCommandsFormat = [NSString stringWithContentsOfFile:gdbCommandsPath];
    NSString *argumentString = (!isNilOrEmpty(arguments)) ? [arguments componentsJoinedByString:@" "] : @"";
    return  [NSString stringWithFormat:gdbCommandsFormat, argumentString];
}


- (NSString *) insertCommandsForBundles:(NSArray *) bundles
{
    NSString *gdbCommandsPath = [[self bundle] pathForResource:bundleInserterCommandFile ofType:@"gdb"];
    NSString *gdbCommandsFormat = [NSString stringWithContentsOfFile:gdbCommandsPath];
    NSMutableArray *commands = [NSMutableArray array];

    NSEnumerator *bundleEnumerator = [bundles objectEnumerator];
    id each;
        
    while (each = [bundleEnumerator nextObject]) {
        [commands addObject:[NSString stringWithFormat:gdbCommandsFormat, [[each bundlePath] asUnixPath]]];
    }
    return [commands componentsJoinedByString:@"\n"];
}


- (NSString *) insertCommandPostamble
{
    NSString *gdbCommandsPath = [[self bundle] pathForResource:bundleInserterCommandFile ofType:@"postamble"];
    return [NSString stringWithContentsOfFile:gdbCommandsPath];
}


- (NSString *) commandFileWithArguments:(NSArray *) arguments bundlesToInsert:(NSArray *) bundles
{
    NSArray *commands = [NSArray arrayWithObjects:
        [self insertCommandPreambleWithArguments:arguments],
        [self insertCommandsForBundles:bundles],
        [self insertCommandPostamble],
        nil];
    NSString *path = [NSString stringWithFormat:@"%@/%@",
        NSTemporaryDirectory(),
        [[[NSProcessInfo processInfo] globallyUniqueString] copy]];
    return [[commands componentsJoinedByString:@"\n"] writeToFile:path atomically:NO] ? path : nil;
}


- (id) initWithLaunchPath:(NSString *) path arguments:(NSArray *) arguments bundlesToInsert:(NSArray *) bundles
{
    self = [super init];
    if (CAN_INSERT_LIBRARIES) {
        [self setLaunchPath:path];
        if (!isNilOrEmpty(arguments)){
            [self setArguments:arguments];
        }
        if (!isNilOrEmpty (bundles)) {
            NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[[NSProcessInfo processInfo] environment]];
            NSArray *executablePaths = [bundles collectionByPerformingSelector:@selector (executablePath)];
            [environment setObject:[executablePaths componentsJoinedByString:@":"] forKey:@"DYLD_INSERT_LIBRARIES"];
            [environment setObject:@"YES" forKey:@"DYLD_BIND_AT_LAUNCH"];
            [self setEnvironment:environment];
        }
    }
    else if (CAN_LAUNCH_WITH_GDB) {
        [self setLaunchPath:GDB_PATH];
        [self setArguments:[NSArray arrayWithObjects:
            @"-x", [self commandFileWithArguments:arguments bundlesToInsert:bundles],
            @"-batch",
            [path asUnixPath],
            nil]];
    }
    else {
        [self dealloc];
        self = nil;
    }
    return self;
}
@end

@implementation NSMutableArray (SenTaskAddition)
- (void) setArgumentDefaultValue:(NSString *) aValue forKey:(NSString *) aKey
{
    NSString *defaultKey = [NSString stringWithFormat:@"-%@", aKey];
    unsigned int index = [self indexOfObject:defaultKey];
    if (index == NSNotFound) {
        [self addObject:defaultKey];
        [self addObject:aValue];
    }
    else {
        [self replaceObjectAtIndex:index + 1 withObject:aValue];
    }
}
@end

