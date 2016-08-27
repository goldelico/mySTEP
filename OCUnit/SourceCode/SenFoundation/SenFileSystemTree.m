/*$Id: SenFileSystemTree.m,v 1.7 2001/11/22 13:11:49 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "SenFileSystemTree.h"
#import "SenUtilities.h"


static NSString				*rootPath = @"/"; // Is it correct on Windows too?
static NSMutableDictionary	*files = nil;


@implementation SenFileSystemTree

+ (void) initialize
{
    if(!files)
        files = [[NSMutableDictionary alloc] init];
}

+ (id <SenTrees>) treeAtPath:(NSString *)value
{
    SenFileSystemTree	*file;
    
    value = [value stringByStandardizingPath];
    if(!(file = [files objectForKey:value])){
        file = [[self alloc] initWithPath:value];
        [files setObject:file forKey:value];
        [file release];
    }
    
    return file;
}

+ (id <SenTrees>) fileAtPath:(NSString *)value
{
    value = [value stringByStandardizingPath];
    
    return [files objectForKey:value];
}

- (id) initWithPath:(NSString *) value
{
    if(self = [super init])
        path = [value copyWithZone:[self zone]];
    
    return self;
}

- (id) init
{
    return [self initWithPath:rootPath];
}

- (void) dealloc
{
    RELEASE(path);
    
    [super dealloc];
}

- (id) copy
{
    return self;
}

- (id) copyWithZone:(NSZone *)zone
{
    return self;
}

- (NSString *) path
{
    return path;
}

- (void) setPath:(NSString *)value
// Could be dangerous with cached values...
{
    ASSIGN(path, value);
}

- (NSArray *) children
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; // [TRH] keep temporaries in check.
    NSArray	*directoryContents = [[NSFileManager defaultManager] directoryContentsAtPath:[self path]];
    
    if(directoryContents){
        NSMutableArray	*children = [[NSMutableArray alloc] init];
        NSEnumerator	*filenameEnumerator = [directoryContents objectEnumerator];
        NSString		*filename;
        // [TRH] micro-optimization: move these outside loop.
        Class			theClass = [self class];
        NSString		*thePath = [self path];

        while(filename = [filenameEnumerator nextObject])
            [children addObject:[theClass treeAtPath:[thePath stringByAppendingPathComponent:filename]]];

        [pool release];
        return [children autorelease];
    }
    [pool release];
    return nil;
}

- (id) parent
{
    if([[self path] isEqualToString:rootPath])
        return nil;
    else
        return [[self class] treeAtPath:[[self path] stringByDeletingLastPathComponent]];
}

- (NSString *) value
{
    return [[self path] lastPathComponent];
}

- (BOOL) isLeaf
{
    return ([self children] == nil);
}

@end
