//
//  NSStringTest.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 28.03.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>


@interface NSStringTest : XCTestCase {
	
}

@end

#ifndef __mySTEP__
@interface NSCFString : NSString
@end
#endif

#if MAC_OS_X_VERSION_MAX_ALLOWED <= MAC_OS_X_VERSION_10_4
@interface NSString (MAC_OS_X_VERSION_10_5_AND_LATER)	// not in older headers
- (BOOL) boolValue;
- (int) intValue;
// - (long) longValue;	-- does not exist for NSString!
- (long long) longLongValue;
- (float) floatValue;
- (double) doubleValue;
@end
#endif

@interface NSString (Mutable)
- (BOOL) isMutable;
@end

@implementation NSString (Mutable)

/*
 * it is not easy to find out if we have a mutable or an immutable object in Cocoa
 * since CoreFoundation objects are returned from -[NSMutableString alloc] and e.g. @"constant"
 * and they all have the full NSMutableString @interface but return error messages if
 * we attempt to apply a mutable operation to an immutable object!
 *
 * see discussion:
 * http://stackoverflow.com/questions/2092637/cocoa-testing-to-find-if-an-nsstring-is-immutable-or-mutable
 */

- (BOOL) isMutable;
{
	NS_DURING
		[(NSMutableString *) self setString:self];
	NS_HANDLER
		return NO;	// we can't change the value, i.e. we are immutable
	NS_ENDHANDLER
	return YES;
}

@end

@implementation NSStringTest

- (void) testShowCocoaMutabilityAPIofStringConstants
{
#ifdef __APPLE__
	XCTAssertTrue([@"hello" respondsToSelector:@selector(setString:)], @"");
	XCTAssertTrue([[NSString string] respondsToSelector:@selector(setString:)], @"");
	XCTAssertTrue([[NSString string] isKindOfClass:[NSMutableString class]], @"");
#else
	XCTAssertFalse([@"hello" respondsToSelector:@selector(setString:)], @"");
	XCTAssertFalse([[NSString string] respondsToSelector:@selector(setString:)], @"");
	XCTAssertFalse([[NSString string] isKindOfClass:[NSMutableString class]], @"");
#endif
}

#define TESTT(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { XCTAssertTrue([INPUT METHOD], @""); }
#define TESTF(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { XCTAssertFalse([INPUT METHOD], @""); }
#define TEST0(NAME, INPUT, METHOD) - (void) test_##METHOD##NAME; { XCTAssertNil([INPUT METHOD], @""); }
#define TEST1(NAME, INPUT, METHOD, OUTPUT) - (void) test_##METHOD##NAME; { XCTAssertEqualObjects([INPUT METHOD], OUTPUT, @""); }
#define TEST2(NAME, INPUT, METHOD, ARG, OUTPUT) - (void) test_##METHOD##NAME; { XCTAssertEqualObjects([INPUT METHOD:ARG], OUTPUT, @""); }

- (void) testMutablility
{
	XCTAssertFalse([@"hello" isMutable], @"");
	XCTAssertTrue([[[@"hello" mutableCopy] autorelease] isMutable], @"");
	XCTAssertFalse([[NSString string] isMutable], @"");
	XCTAssertTrue([[NSMutableString string] isMutable], @"");
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
	XCTAssertTrue([@"" isEqualToString:@""], @"");
	XCTAssertTrue([@"" isEqualToString:[@"" lowercaseString]], @"");	// fails...
	XCTAssertTrue([[@"" lowercaseString] isEqualToString:@""], @"");
	XCTAssertTrue([[@"" lowercaseString] isEqualToString:[@"" lowercaseString]], @"");
	XCTAssertTrue([@"" isEqual:@""], @"");
	XCTAssertTrue([@"" isEqual:[@"" lowercaseString]], @"");	// fails...
	XCTAssertTrue([[@"" lowercaseString] isEqual:@""], @"");
	XCTAssertTrue([[@"" lowercaseString] isEqual:[@"" lowercaseString]], @"");
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
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:nil]]), @"", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", nil]]), @"", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"", @"", nil]]), @"", @"");	// empty entries are ignored
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", nil]]), @"/", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", nil]]), @"/", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", nil]]), @"/", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"path", nil]]), @"/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"path", @"", @"/", nil]]), @"path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"", nil]]), @"/", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"/", nil]]), @"/", @"");	// not the inverse of pathComponents
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"path", @"/", nil]]), @"path", @"");	// not the inverse of pathComponents
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"path", nil]]), @"/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"path", @"/", nil]]), @"/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"tmp", @"scratch.tiff", @"/", nil]]), @"/tmp/scratch.tiff", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"/", @"/", @"/", nil]]), @"/", @"");	// multiple / are merged
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/path", @"", @"/", nil]]), @"/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"/path", @"/", nil]]), @"/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"some", @"/path", @"/", nil]]), @"/some/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/", @"", @"some/", @"/path", @"/", nil]]), @"/some/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"some/path", @"", @"/", nil]]), @"some/path", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"some/", @"", @"/", nil]]), @"some", @"");
	XCTAssertEqualObjects(([NSString pathWithComponents:[NSArray arrayWithObjects:@"", @"/some/", @"", @"/path/", nil]]), @"/some/path", @"");
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
TEST2(02, @"", stringByAppendingPathExtension, @"tiff", @"");	// does not append to empty string, i.e. if there is no lastPathComponent - prints a warning on NSLog
TEST2(03, @"/tmp/scratch.gif", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.gif.tiff");
TEST2(04, @"/tmp/scratch.gif.", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.gif..tiff");
TEST2(05, @"/tmp/scratch.gif.", stringByAppendingPathExtension, @".tiff", @"/tmp/scratch.gif...tiff");
TEST2(06, @"/tmp/scratch.gif", stringByAppendingPathExtension, @"", @"/tmp/scratch.gif.");
TEST2(07, @"/tmp/scratch", stringByAppendingPathExtension, @"", @"/tmp/scratch.");	// empty suffix adds a .
TEST2(08, @"/tmp/scratch/", stringByAppendingPathExtension, @"tiff", @"/tmp/scratch.tiff");	// trailing / is deleted
TEST2(09, @"/tmp/scratch/", stringByAppendingPathExtension, @"", @"/tmp/scratch.");
TEST2(09b, @"/tmp", stringByAppendingPathExtension, @"", @"/tmp.");
TEST2(09c, @"/", stringByAppendingPathExtension, @"tmp", @"/");	// extension not added - prints a warning on NSLog
TEST2(10, @"//tmp///scratch////", stringByAppendingPathExtension, @"", @"/tmp/scratch.");	// empty path components are always removed
TEST2(11, @"//", stringByAppendingPathExtension, @"something", @"//");	// extension not added - prints a warning on NSLog
TEST2(12, @"////", stringByAppendingPathExtension, @"something", @"////");	// extension not added - prints a warning on NSLog
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
// FIXME: test creation, conversions, appending, mutability, sorting, isEqual etc.

- (void) testReplacements
{
	NSString *obj=@"abcdefgabcdefg";
	XCTAssertEqualObjects([obj self], @"abcdefgabcdefg", @"");
	XCTAssertEqualObjects([obj stringByReplacingOccurrencesOfString:@"def" withString:@"rep"], @"abcrepgabcrepg", @"");	// two pattern matches and replacements
	XCTAssertEqualObjects([obj stringByReplacingOccurrencesOfString:@"def" withString:@"rep" options:0 range:NSMakeRange(0, 6)], @"abcrepgabcdefg", @"");	// range covers only one pattern
	XCTAssertEqualObjects([obj stringByReplacingOccurrencesOfString:@"def" withString:@"rep" options:0 range:NSMakeRange(0, 5)], @"abcdefgabcdefg", @"");	// pattern must be fully in range
	XCTAssertEqualObjects([obj stringByReplacingOccurrencesOfString:@"def" withString:@"rep" options:0 range:NSMakeRange(3, 3)], @"abcrepgabcdefg", @"");	// pattern is in range
	XCTAssertEqualObjects([obj stringByReplacingOccurrencesOfString:@"def" withString:@"rep" options:0 range:NSMakeRange(4, 3)], @"abcdefgabcdefg", @"");	// pattern must be fully in range
	// replacing range
	// replacing with options
}

- (void) testGetNumericalValues
{
	NSString *obj=@"0";
	XCTAssertEqualObjects([obj self], @"0", @"");
	XCTAssertFalse([obj class] == [NSString class], @"");	// constant strings have a private class
	// starts availability in 10.5
	XCTAssertEqual([obj boolValue], NO, @"");
	XCTAssertEqual([obj intValue], 0, @"");
//	XCTAssertEqual([obj longValue], 0l, @"");
	XCTAssertEqual([obj longLongValue], 0ll, @"");
	XCTAssertEqual([obj floatValue], 0.0f, @"");
	XCTAssertEqual([obj doubleValue], 0.0, @"");
	obj=@"1";
	XCTAssertEqualObjects([obj self], @"1", @"");
	XCTAssertEqual([obj boolValue], YES, @"");
	XCTAssertEqual([obj intValue], 1, @"");
//	XCTAssertEqual([obj longValue], 1l, @"");
	XCTAssertEqual([obj longLongValue], 1ll, @"");
	XCTAssertEqual([obj floatValue], 1.0f, @"");
	XCTAssertEqual([obj doubleValue], 1.0, @"");
	obj=@"3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679";
	XCTAssertEqualObjects([obj self], @"3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679", @"");
	XCTAssertEqual([obj boolValue], YES, @"");
	XCTAssertEqual([obj intValue], 3, @"");
//	XCTAssertEqual([obj longValue], 3l, @"");
	XCTAssertEqual([obj longLongValue], 3ll, @"");
	XCTAssertEqual([obj floatValue], 3.1415926535f, @"");
	XCTAssertEqual([obj doubleValue], 3.14159265358979323846264, @"");
}

@end
