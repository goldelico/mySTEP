//
//  NSTextStorageTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 08.01.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "NSTextStorageTest.h"

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

@implementation NSTextStorageTest

- (void) test1;
{
	NSTextStorage *store=[[NSTextStorage alloc] initWithString:@"The files couldn't be saved"];
	SomeLayoutManager *lm=[[[SomeLayoutManager alloc] init] autorelease];
	[store addLayoutManager:(NSLayoutManager *) lm];	// pretend to be a NSLayoutManager
	STAssertTrue([lm didsetTextStorage], nil);
	STAssertEqualObjects([lm storage], store, nil);
	STAssertEqualObjects([store string], @"The files couldn't be saved", nil);
	
	[store replaceCharactersInRange:NSMakeRange(0, 3) withString:@"Several"];	// example from documentation
	STAssertTrue([[store string] isEqual:@"Several files couldn't be saved"], nil);
	STAssertEqualObjects([store string], @"Several files couldn't be saved", nil);
	STAssertTrue([lm didtextStorageEdited], nil);
	// check values

	[store replaceCharactersInRange:NSMakeRange(8, 5) withString:@"documents"];
	STAssertEqualObjects([store string], @"Several documents couldn't be saved", nil);
	STAssertTrue([lm didtextStorageEdited], nil);
	// check values

	[store replaceCharactersInRange:NSMakeRange(18, 11) withString:@"have been"];
	STAssertEqualObjects([store string], @"Several documents have been saved", nil);
	STAssertTrue([lm didtextStorageEdited], nil);
	// check values
	
	[store setAttributes:[NSDictionary dictionary] range:NSMakeRange(5, 10)];
	STAssertEqualObjects([store string], @"Several documents have been saved", nil);
	STAssertTrue([lm didtextStorageEdited], nil);
	// check values
	
	NSAutoreleasePool *arp=[NSAutoreleasePool new];	// mutableString proxy does a retain+autorelease on the store
	[[store mutableString] setString:@"something else"];	// call through the mutableString proxy
	STAssertEqualObjects([store string], @"something else", nil);
	STAssertTrue([lm didtextStorageEdited], nil);
	// check values
	[arp release];
	
	[store release];
	STAssertTrue([lm didsetTextStorage], nil);	// this would fail without the ARP
	// check values
}

@end
