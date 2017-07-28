//
//  NSTextStorageTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.01.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <Cocoa/Cocoa.h>


// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=a; typeof(b) _b=b; \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(b))], \
		##__VA_ARGS__); })


@interface NSTextStorageTest : XCTestCase {
	
}

@end

@interface SomeLayoutManager : NSObject
{
	BOOL didtextStorageEdited;
	unsigned mask;
	NSRange range;
	int d;
	NSRange invalidated;
	BOOL didsetTextStorage;
	NSTextStorage *storage;
}

- (void) textStorage:(NSTextStorage *) str edited:(unsigned) editedMask range:(NSRange) newCharRange changeInLength:(int) delta invalidatedRange:(NSRange) invalidatedCharRange;
- (void) setTextStorage:(NSTextStorage *) str;

// getters to check events
- (BOOL) didtextStorageEdited;
- (BOOL) didsetTextStorage;
- (unsigned) editedMask;
- (NSRange) range;
- (int) delta;
- (NSRange) invalidated;
- (NSTextStorage *) storage;
@end

@implementation SomeLayoutManager

- (void) textStorage:(NSTextStorage *) str edited:(unsigned) editedMask range:(NSRange) newCharRange changeInLength:(int) delta invalidatedRange:(NSRange) invalidatedCharRange;
{
	mask=editedMask;
	range=newCharRange;
	d=delta;
	invalidated=invalidatedCharRange;
	storage=str;
	didtextStorageEdited=YES;
}

- (void) setTextStorage:(NSTextStorage *) str;
{
	storage=str;
	didsetTextStorage=YES;
}

// getters to check events
- (BOOL) didtextStorageEdited;
{
	BOOL r=didtextStorageEdited;
	didsetTextStorage=NO;
	return r;
}

- (BOOL) didsetTextStorage;
{
	BOOL r=didsetTextStorage;
	didsetTextStorage=NO;
	return r;
}

- (unsigned) editedMask; { return mask; }
- (NSRange) range; { return range; }
- (int) delta; { return d; }
- (NSRange) invalidated; { return invalidated; }
- (NSTextStorage *) storage; { return storage; }

@end

#define REFCNT	1

@implementation NSTextStorageTest

- (void) test1;
{
	NSTextStorage *store=[[NSTextStorage alloc] initWithString:@"The files couldn't be saved"];
#if REFCNT
	XCTAssertEqual([store retainCount], 1u, @"");
#endif
	SomeLayoutManager *lm=[[[SomeLayoutManager alloc] init] autorelease];
#if REFCNT
	XCTAssertEqual([lm retainCount], 1u, @"");
#endif
	[store addLayoutManager:(NSLayoutManager *) lm];	// pretend to be a NSLayoutManager
#if REFCNT
	XCTAssertEqual([store retainCount], 1u, @"");
#endif
	
	XCTAssertTrue([lm didsetTextStorage], @"");
	XCTAssertEqualObjects([lm storage], store, @"");
	XCTAssertEqualObjects([store string], @"The files couldn't be saved", @"");
	
	[store replaceCharactersInRange:NSMakeRange(0, 3) withString:@"Several"];	// example from documentation
	XCTAssertTrue([[store string] isEqual:@"Several files couldn't be saved"], @"");
	XCTAssertEqualObjects([store string], @"Several files couldn't be saved", @"");
	
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 2u, @"");
	XCTAssertEquals([lm range], NSMakeRange(0, 7), @"");
	XCTAssertEquals([lm delta], 4, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(0, 7), @"");

	[store replaceCharactersInRange:NSMakeRange(8, 5) withString:@"documents"];
	XCTAssertEqualObjects([store string], @"Several documents couldn't be saved", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 2u, @"");
	XCTAssertEquals([lm range], NSMakeRange(8, 9), @"");
	XCTAssertEquals([lm delta], 4, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(8, 9), @"");
	
	[store replaceCharactersInRange:NSMakeRange(18, 11) withString:@"have been"];
	XCTAssertEqualObjects([store string], @"Several documents have been saved", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 2u, @"");
	XCTAssertEquals([lm range], NSMakeRange(18, 9), @"");
	XCTAssertEquals([lm delta], -2, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(18, 9), @"");
	
	[store setAttributes:[NSDictionary dictionary] range:NSMakeRange(5, 10)];
	XCTAssertEqualObjects([store string], @"Several documents have been saved", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 1u, @"");
	XCTAssertEquals([lm range], NSMakeRange(5, 10), @"");
	XCTAssertEquals([lm delta], 0, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(5, 10), @"");
	
	[store addAttribute:NSFontAttributeName value:[NSFont systemFontOfSize:0.0] range:NSMakeRange(0, 4)];
	XCTAssertEqualObjects([store string], @"Several documents have been saved", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 1u, @"");
	XCTAssertEquals([lm range], NSMakeRange(0, 4), @"");
	XCTAssertEquals([lm delta], 0, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(0, 4), @"");

	[store replaceCharactersInRange:NSMakeRange(11, 5) withString:@""];
	XCTAssertEqualObjects([store string], @"Several docs have been saved", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 2u, @"");
	XCTAssertEquals([lm range], NSMakeRange(11, 0), @"");
	XCTAssertEquals([lm delta], -5, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(11, 0), @"");
	
	// test if we can change the string through the mutableString proxy
	
#if REFCNT
	XCTAssertEquals([store retainCount], 1u, @"");
#endif
	NSAutoreleasePool *arp=[NSAutoreleasePool new];	// mutableString proxy does a retain+autorelease on the store
	XCTAssertEquals([store length], 28u, @"");
#if REFCNT
	XCTAssertEquals([store retainCount], 1u, @"");
#endif
	NSMutableString *str=[store mutableString];
#if REFCNT
	XCTAssertEquals([str retainCount], 1u, @"");
#endif
	[str setString:@"something else"];	// call through the mutableString proxy
	XCTAssertEqualObjects([store string], @"something else", @"");
	XCTAssertTrue([lm didtextStorageEdited], @"");
	XCTAssertEquals([lm editedMask], 2u, @"");
	XCTAssertEquals([lm range], NSMakeRange(0, 14), @"");
	XCTAssertEquals([lm delta], -14, @"");
	XCTAssertEquals([lm invalidated], NSMakeRange(0, 14), @"");
#if REFCNT
	XCTAssertEquals([lm retainCount], 2u, @"");
	XCTAssertEquals([store retainCount], 2u, @"");
#endif
	[arp release];
	
#if REFCNT
	XCTAssertEquals([store retainCount], 1u, @"");
#endif
	[store release];
	XCTAssertTrue([lm didsetTextStorage], @"");	// this would fail without the ARP
	XCTAssertNil([lm storage], @"");	// has no text storage (we could check how a LM behaves... throws exceptions or ignores everything?)
	// check values
}

// more tests:
// we should test setting individual attributes
// and what happens if we embrace changes by -beginEditing and -endEditing to test how adding/deleting is coalesced
// we should test fixing attributes and if it raises exceptions as specified
// i.e. attachment characters w/o attachments, attachments w/o character (is the character deleted?)
//   missing paragraph styles (where does the style come from? what if several styles in same paragraph?)
//   or unsupported fonts

@end
