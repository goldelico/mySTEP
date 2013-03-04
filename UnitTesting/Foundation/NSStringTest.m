//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSStringTest.h"

@interface NSString (Mutable)
- (BOOL) isMutable;
@end

@implementation NSString (Mutable)

- (BOOL) isMutable;
{
#if __mySTEP__	// this fails on Cocoa!
	return [self isKindOfClass:[NSMutableString class]];
#elif 0	// this fails as well on Cocoa
	return [self respondsToSelector:@selector(setString:)];
#else
	return NO;
#endif
}

@end

@implementation NSStringTest

#define TESTT(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { STAssertTrue([INPUT METHOD], nil); }
#define TESTF(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { STAssertFalse([INPUT METHOD], nil); }
#define TEST0(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { STAssertNil([INPUT METHOD], nil); }
#define TEST1(NAME, INPUT, METHOD, OUTPUT) - (void) test_##METHOD##NAME; { STAssertEqualObjects([INPUT METHOD], OUTPUT, nil); }
#define TEST2(NAME, INPUT, METHOD, ARG, OUTPUT) - (void) test_##METHOD##NAME; { STAssertEqualObjects([INPUT METHOD:ARG], OUTPUT, nil); }

// FIXME: test creation, conversions, appending, mutability, sorting, isEqual, intValue, floatValue etc.

- (void) testMutablility
{
	STAssertFalse([@"hello" isMutable], nil);
	STAssertFalse([[NSString string] isMutable], nil);
	STAssertTrue([[NSMutableString string] isMutable], nil);
}

TEST2(01, @"a:b", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"a", @"b", nil]));
TEST2(02, @"ab", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"ab", nil]));
TEST2(03, @":b", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"", @"b", nil]));
TEST2(04, @"a:", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"a", @"", nil]));
TEST2(05, @"a::b", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
TEST2(06, @"a:::b", componentsSeparatedByString, @"::", ([NSArray arrayWithObjects:@"a", @":b", nil]));
TEST2(07, @"a::::b", componentsSeparatedByString, @"::", ([NSArray arrayWithObjects:@"a", @"", @"b", nil]));
TEST2(08, @":", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"", @"", nil]));
TEST2(09, @"", componentsSeparatedByString, @":", ([NSArray arrayWithObjects:@"", nil]));
TEST2(10, @"ab", componentsSeparatedByString, @"", ([NSArray arrayWithObjects:@"ab", nil]));

TESTT(01, @"/here", isAbsolutePath);
TESTT(02, @"/", isAbsolutePath);
TESTF(03, @"here", isAbsolutePath);
TESTF(04, @"here/", isAbsolutePath);

- (void) testisEqualToString;
{ // -lowercaseString converts into an Unicode String
	STAssertTrue([@"" isEqualToString:@""], nil);
	STAssertTrue([@"" isEqualToString:[@"" lowercaseString]], nil);	// fails...
	STAssertTrue([[@"" lowercaseString] isEqualToString:@""], nil);
	STAssertTrue([[@"" lowercaseString] isEqualToString:[@"" lowercaseString]], nil);
	STAssertTrue([@"" isEqual:@""], nil);
	STAssertTrue([@"" isEqual:[@"" lowercaseString]], nil);	// fails...
	STAssertTrue([[@"" lowercaseString] isEqual:@""], nil);
	STAssertTrue([[@"" lowercaseString] isEqual:[@"" lowercaseString]], nil);
}

TEST1(01, @"/tmp/scratch.tiff", lastPathComponent, @"scratch.tiff");
TEST1(02, @"tmp/scratch.tiff", lastPathComponent, @"scratch.tiff");
TEST1(03, @"/tmp/lock/", lastPathComponent, @"lock");
TEST1(04, @"/tmp/", lastPathComponent, @"tmp");
TEST1(05, @"/tmp", lastPathComponent, @"tmp");
TEST1(06, @"/", lastPathComponent, @"/");
TEST1(06a, @"", lastPathComponent, @"");
TEST1(07, @"scratch.tiff", lastPathComponent, @"scratch.tiff");
TEST1(07a, @"scratch.tiff/", lastPathComponent, @"scratch.tiff");
TEST1(08, @"//tmp/scratch.tiff", lastPathComponent, @"scratch.tiff");
TEST1(09, @"//", lastPathComponent, @"/");
TEST1(10, @"///", lastPathComponent, @"/");
TEST1(11, @"//tmp//scratch.tiff/", lastPathComponent, @"scratch.tiff");

TEST1(01, @"LowerCase", lowercaseString, @"lowercase");
TEST1(02, @"Lower Case", lowercaseString, @"lower case");
TEST1(03, @"Lower Case ÄÖÜ", lowercaseString, @"lower case äöü");	// FIXME: unicode string constant makes problems on -isEqual:
TEST1(04, @"lowercase", lowercaseString, @"lowercase");
TEST1(05, @"", lowercaseString, @"");

TEST1(01, @"", pathComponents, ([NSArray arrayWithObjects:nil]));
TEST1(02, @"/", pathComponents, ([NSArray arrayWithObjects:@"/", nil]));
TEST1(02a, @"/tmp", pathComponents, ([NSArray arrayWithObjects:@"/", @"tmp", nil]));
TEST1(02b, @"///tmp", pathComponents, ([NSArray arrayWithObjects:@"/", @"tmp", nil]));
TEST1(02c, @"first/", pathComponents, ([NSArray arrayWithObjects:@"first", @"/", nil]));
TEST1(02d, @"//", pathComponents, ([NSArray arrayWithObjects:@"/", @"/", nil]));
TEST1(02e, @"///", pathComponents, ([NSArray arrayWithObjects:@"/", @"/", nil]));
TEST1(02f, @"first///", pathComponents, ([NSArray arrayWithObjects:@"first", @"/", nil]));
TEST1(03, @"/tmp/scratch.tiff", pathComponents, ([NSArray arrayWithObjects:@"/", @"tmp", @"scratch.tiff", nil]));	// a leading / is explicitly stored
TEST1(04, @"/tmp/scratch.tiff/", pathComponents, ([NSArray arrayWithObjects:@"/", @"tmp", @"scratch.tiff", @"/", nil]));
TEST1(05, @"///tmp////scratch.tiff///", pathComponents, ([NSArray arrayWithObjects:@"/", @"tmp", @"scratch.tiff", @"/", nil]));	// empty components are removed but not a trailing /
TEST1(06, @"   ///", pathComponents, ([NSArray arrayWithObjects:@"   ", @"/", nil]));

TEST1(01, @"/tmp/scratch.tiff", pathExtension, @"tiff");
TEST1(02, @"tmp/scratch.tiff", pathExtension, @"tiff");
TEST1(03, @"/tmp/lock/", pathExtension, @"");
TEST1(03b, @"/tmp/lock.tiff/", pathExtension, @"tiff");	// deletes trailing / before extracting the pathExtension
TEST1(03c, @"/tmp/lock.tiff//", pathExtension, @"tiff");	// deletes trailing // before extracting the pathExtension
TEST1(04, @"/", pathExtension, @"");
TEST1(04a, @"", pathExtension, @"");
TEST1(05, @"tiff", pathExtension, @"");
TEST1(06, @".", pathExtension, @"");
TEST1(07, @"..", pathExtension, @"");
TEST1(07b, @"...", pathExtension, @"");
TEST1(07c, @"....", pathExtension, @"");
TEST1(07d, @"..../", pathExtension, @"");
TEST1(08, @".tiff", pathExtension, @"");
TEST1(08b, @"x.tiff", pathExtension, @"tiff");
TEST1(08c, @"x.", pathExtension, @"");
TEST1(09, @"..tiff", pathExtension, @"tiff");
TEST1(10, @"...tiff", pathExtension, @"tiff");

- (void) testpathWithComponents
{
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:nil]]), @"", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", nil]]), @"", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"", @"", nil]]), @"", nil);	// empty entries are ignored
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", nil]]), @"/", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", nil]]), @"/", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", nil]]), @"/", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"path", nil]]), @"/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"path", @"", @"/", nil]]), @"path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"", nil]]), @"/", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"/", nil]]), @"/", nil);	// not the inverse of pathComponents
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"path", @"/", nil]]), @"path", nil);	// not the inverse of pathComponents
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"path", nil]]), @"/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"path", @"/", nil]]), @"/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"tmp", @"scratch.tiff", @"/", nil]]), @"/tmp/scratch.tiff", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"/", @"/", nil]]), @"/", nil);	// multiple / are merged
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/path", @"", @"/", nil]]), @"/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"/path", @"/", nil]]), @"/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"some", @"/path", @"/", nil]]), @"/some/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"some/", @"/path", @"/", nil]]), @"/some/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"some/path", @"", @"/", nil]]), @"some/path", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"some/", @"", @"/", nil]]), @"some", nil);
	STAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/some/", @"", @"/path/", nil]]), @"/some/path", nil);
	/* conclusions
	 * there appears to be no way to produce a path that ends in a /
	 * [NSString pathWithComponents:[str pathComponents]] is not always the same str
	 * empty components are ignored
	 * / characters at the beginning or end of components are removed/ignored (except when deciding about absolute paths)
	 */
}

TEST1(01, (NSHomeDirectory()), stringByAbbreviatingWithTildeInPath, @"~");
TEST1(02, ([NSHomeDirectory() stringByAppendingPathComponent:@"Documents"]), stringByAbbreviatingWithTildeInPath, @"~/Documents");
TEST1(02b, ([NSHomeDirectory() stringByAppendingString:@"/Documents/"]), stringByAbbreviatingWithTildeInPath, @"~/Documents");	// trailing / removed
TEST1(02c, ([NSHomeDirectory() stringByAppendingString:@"//Documents///"]), stringByAbbreviatingWithTildeInPath, @"~/Documents");	// blank components standardized
TEST1(02d, ([NSHomeDirectory() stringByAppendingString:@"/Documents//.."]), stringByAbbreviatingWithTildeInPath, @"~/Documents/..");	// // reduced
TEST1(02e, ([NSHomeDirectory() stringByAppendingString:@"/Documents/./.."]), stringByAbbreviatingWithTildeInPath, @"~/Documents/./..");	// // reduced
TEST1(03, (NSHomeDirectoryForUser(@"root")), stringByAbbreviatingWithTildeInPath, NSHomeDirectoryForUser(@"root"));	// not abbreviated
TEST1(04, ([NSString stringWithFormat:@"////%@//Documents///", NSHomeDirectory()]), stringByAbbreviatingWithTildeInPath, @"~/Documents");	// is standardized
TEST1(05, ([NSString stringWithFormat:@"//////Documents///"]), stringByAbbreviatingWithTildeInPath, @"/Documents");	// path is simplified even if it does not match
TEST1(06, ([NSString stringWithFormat:@".//////Documents///"]), stringByAbbreviatingWithTildeInPath, @"./Documents");	// path is simplified even if it does not match

TEST2(01, @"/tmp", stringByAppendingPathComponent, @"file", @"/tmp/file");
TEST2(02, @"/tmp/", stringByAppendingPathComponent, @"file", @"/tmp/file");
TEST2(03, @"", stringByAppendingPathComponent, @"file", @"file");
TEST2(04, @"/", stringByAppendingPathComponent, @"file", @"/file");	// first / is honoured
TEST2(05, @"/tmp", stringByAppendingPathComponent, @"/file", @"/tmp/file");
TEST2(06, @"/tmp/", stringByAppendingPathComponent, @"/file", @"/tmp/file");
TEST2(07, @"", stringByAppendingPathComponent, @"/file", @"/file");
TEST2(08, @"/", stringByAppendingPathComponent, @"/file", @"/file");
TEST2(09, @"/tmp", stringByAppendingPathComponent, @"/file/", @"/tmp/file");
TEST2(10, @"/tmp/", stringByAppendingPathComponent, @"/file/", @"/tmp/file");
TEST2(11, @"", stringByAppendingPathComponent, @"/file/", @"/file");
TEST2(12, @"/", stringByAppendingPathComponent, @"/file/", @"/file");
TEST2(13, @"///", stringByAppendingPathComponent, @"//file///", @"/file");	// leading and trailing / are stripped off before concatenating
TEST2(13b, @"///", stringByAppendingPathComponent, @"file///", @"/file");
TEST2(14, @"/", stringByAppendingPathComponent, @"/", @"/");
TEST2(15, @"/file", stringByAppendingPathComponent, @"/", @"/file");
TEST2(16, @"file", stringByAppendingPathComponent, @"/", @"file");
TEST2(17, @"file/", stringByAppendingPathComponent, @"/", @"file");
TEST2(18, @"file/", stringByAppendingPathComponent, @"//", @"file");
TEST2(19, @"//", stringByAppendingPathComponent, @"file", @"/file");
TEST2(20, @"//", stringByAppendingPathComponent, @"/file", @"/file");
TEST2(21, @"//", stringByAppendingPathComponent, @"//file", @"/file");
TEST2(22a, @"file/", stringByAppendingPathComponent, @"/other", @"file/other");
TEST2(22b, @"file//", stringByAppendingPathComponent, @"//other", @"file/other");
TEST2(22c, @"file//", stringByAppendingPathComponent, @"other", @"file/other");

TEST2(01, @"/tmp/scratch", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.tiff");
TEST2(02, @"", stringByAppendingPathExtension, @"tiff", @"");	// does not append to empty string, i.e. if there is no lastPathComponent
TEST2(03, @"/tmp/scratch.gif", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.gif.tiff");
TEST2(04, @"/tmp/scratch.gif.", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.gif..tiff");
TEST2(05, @"/tmp/scratch.gif.", stringByAppendingPathExtension, @".tiff", @"/tmp/scratch.gif...tiff");
TEST2(06, @"/tmp/scratch.gif", stringByAppendingPathExtension, @"", @"/tmp/scratch.gif.");
TEST2(07, @"/tmp/scratch", stringByAppendingPathExtension, @"", @"/tmp/scratch.");	// empty suffix adds a .
TEST2(08, @"/tmp/scratch/", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.tiff");	// trailing / is deleted
TEST2(09, @"/tmp/scratch/", stringByAppendingPathExtension, @"", @"/tmp/scratch.");
TEST2(09b, @"/tmp", stringByAppendingPathExtension, @"", @"/tmp.");
TEST2(09c, @"/", stringByAppendingPathExtension, @"tmp", @"/");	// extension not added
TEST2(10, @"//tmp///scratch////", stringByAppendingPathExtension, @"", @"/tmp/scratch.");	// empty path components are always removed
TEST2(11, @"//", stringByAppendingPathExtension, @"something", @"//");
TEST2(12, @"////", stringByAppendingPathExtension, @"something", @"////");	// not touched
TEST2(13, @"   ////", stringByAppendingPathExtension, @"something", @"   .something");

TEST1(01, @"/tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
TEST1(02, @"tmp/scratch.tiff", stringByDeletingLastPathComponent, @"tmp");
TEST1(03, @"/tmp/lock/", stringByDeletingLastPathComponent, @"/tmp");	// trailing / is also deleted
TEST1(04, @"/tmp/", stringByDeletingLastPathComponent, @"/");
TEST1(05, @"/tmp", stringByDeletingLastPathComponent, @"/");
TEST1(06, @"/", stringByDeletingLastPathComponent, @"/");
TEST1(07, @"scratch.tiff", stringByDeletingLastPathComponent, @"");
TEST1(08, @"//tmp/scratch.tiff", stringByDeletingLastPathComponent, @"/tmp");
TEST1(09, @"//", stringByDeletingLastPathComponent, @"/");
TEST1(10, @"///", stringByDeletingLastPathComponent, @"/");
TEST1(11, @"//tmp////scratch.tiff///", stringByDeletingLastPathComponent, @"/tmp");	// empty path components are removed
TEST1(12, @"", stringByDeletingLastPathComponent, @"");

TEST1(01, @"/tmp/scratch.tiff", stringByDeletingPathExtension, @"/tmp/scratch");
TEST1(02, @"tmp/scratch.tiff", stringByDeletingPathExtension, @"tmp/scratch");
TEST1(03, @"/tmp/lock/", stringByDeletingPathExtension, @"/tmp/lock");	// deletes trailing /
TEST1(03b, @"/tmp/lock.tiff/", stringByDeletingPathExtension, @"/tmp/lock");	// deletes trailing /
TEST1(03c, @"/tmp/lock.tiff//", stringByDeletingPathExtension, @"/tmp/lock");	// deletes trailing //
TEST1(04, @"/", stringByDeletingPathExtension, @"/");
TEST1(05, @"tiff", stringByDeletingPathExtension, @"tiff");
TEST1(06, @".", stringByDeletingPathExtension, @".");
TEST1(07, @"..", stringByDeletingPathExtension, @".");	// deletes one .
TEST1(07b, @"...", stringByDeletingPathExtension, @"..");	// deletes one .
TEST1(07c, @"....", stringByDeletingPathExtension, @"...");	// deletes one .
TEST1(07d, @"..../", stringByDeletingPathExtension, @"...");	// deletes one . and the /
TEST1(08, @".tiff", stringByDeletingPathExtension, @".tiff");
TEST1(08b, @"x.tiff", stringByDeletingPathExtension, @"x");
TEST1(08c, @"x.", stringByDeletingPathExtension, @"x");
TEST1(09, @"..tiff", stringByDeletingPathExtension, @".");
TEST1(10, @"...tiff", stringByDeletingPathExtension, @"..");

TEST1(01, @"~", stringByExpandingTildeInPath, NSHomeDirectory());
TEST1(02, @"~/", stringByExpandingTildeInPath, NSHomeDirectory());
TEST1(03, @"~/blah", stringByExpandingTildeInPath, [NSHomeDirectory() stringByAppendingPathComponent:@"blah"]);
TEST1(04, @"~/blah/", stringByExpandingTildeInPath, [NSHomeDirectory() stringByAppendingPathComponent:@"blah"]);
TEST1(01a, @"~root", stringByExpandingTildeInPath, NSHomeDirectoryForUser(@"root"));
TEST1(02a, @"~root/", stringByExpandingTildeInPath, NSHomeDirectoryForUser(@"root"));
TEST1(03a, @"~root/blah", stringByExpandingTildeInPath, [NSHomeDirectoryForUser(@"root") stringByAppendingPathComponent:@"blah"]);
TEST1(04a, @"~root/blah/", stringByExpandingTildeInPath, [NSHomeDirectoryForUser(@"root") stringByAppendingPathComponent:@"blah"]);
// this test assumes that the user does NOT exist!
TEST1(01b, @"~unknownuser", stringByExpandingTildeInPath, @"~unknownuser");
TEST1(02b, @"~unknownuser/", stringByExpandingTildeInPath, @"~unknownuser");
TEST1(03b, @"~unknownuser/blah", stringByExpandingTildeInPath, @"~unknownuser/blah");
TEST1(04b, @"~unknownuser/blah/", stringByExpandingTildeInPath, @"~unknownuser/blah");
TEST1(01c, @"~*-#no-user", stringByExpandingTildeInPath, @"~*-#no-user");
TEST1(05, @"other", stringByExpandingTildeInPath, @"other");
TEST1(06, @"/other", stringByExpandingTildeInPath, @"/other");
TEST1(06a, @"/", stringByExpandingTildeInPath, @"/");
TEST1(06b, @"/other/", stringByExpandingTildeInPath, @"/other");	// always strips off trailing /
TEST1(06c, @"////other////", stringByExpandingTildeInPath, @"/other");	// merges multiple /
TEST1(07, @"/~other", stringByExpandingTildeInPath, @"/~other");	// ~must be first character
TEST1(07b, @" ~/other", stringByExpandingTildeInPath, @" ~/other");	// ~must be first character
TEST1(08, @"", stringByExpandingTildeInPath, @"");	// empty

TEST1(01, @"/path", stringByStandardizingPath, @"/path");
TEST1(02, @"/path/", stringByStandardizingPath, @"/path");	// trailing / removed
TEST1(03, @"path/", stringByStandardizingPath, @"path");	// trailing / removed
TEST1(04, @"", stringByStandardizingPath, @"");
TEST1(05, @"//path", stringByStandardizingPath, @"/path");
TEST1(06, @"/path///", stringByStandardizingPath, @"/path");
TEST1(07, @"/path/..", stringByStandardizingPath, @"/");	// .. resolved
TEST1(08, @"/path/down/..", stringByStandardizingPath, @"/path");
TEST1(09, @"/..", stringByStandardizingPath, @"/");	// initial .. removed - for absolute paths only
TEST1(10, @"/path/../", stringByStandardizingPath, @"/");
TEST1(11, @"/path/down/../", stringByStandardizingPath, @"/path");
TEST1(12, @"/../", stringByStandardizingPath, @"/");
TEST1(13, @"/path/./", stringByStandardizingPath, @"/path");
TEST1(14, @"/path/down/./", stringByStandardizingPath, @"/path/down");
TEST1(15, @"/./", stringByStandardizingPath, @"/.");	// /. is not removed
TEST1(15a, @"/./path", stringByStandardizingPath, @"/path");	// remove .
TEST1(16, @"./", stringByStandardizingPath, @".");
TEST1(16a, @"./path", stringByStandardizingPath, @"path");
TEST1(16b, @"./path/.", stringByStandardizingPath, @"path");
TEST1(17, @"/.", stringByStandardizingPath, @"/.");	// keep . after root (special case)
TEST1(17b, @"path/.", stringByStandardizingPath, @"path");
TEST1(19, @"./..", stringByStandardizingPath, @"..");	// initial ./ is removed but not final ..
TEST1(19b, @"./.", stringByStandardizingPath, @".");	// initial ./ is removed
TEST1(20, @"./../", stringByStandardizingPath, @"..");
TEST1(20b, @"./../../..", stringByStandardizingPath, @"../../..");
TEST1(20c, @"down/../../..", stringByStandardizingPath, @"down/../../..");
TEST1(20d, @"down/../other/../..", stringByStandardizingPath, @"down/../other/../..");	// ../ is only reduced for absolute paths!
TEST1(20e, @"down/..//./other/../..", stringByStandardizingPath, @"down/../other/../..");	// ./ and // are always reduced
TEST1(20f, @"/../../..", stringByStandardizingPath, @"/");	// for absolute paths only
TEST1(21, @"~/path", stringByStandardizingPath, [NSHomeDirectory() stringByAppendingPathComponent:@"path"]);	// ~ is also expanded
TEST1(22, @"/../path/down/", stringByStandardizingPath, @"/path/down");	// implicitly assumes that /.. is the same as /

// add many more such tests


@end
