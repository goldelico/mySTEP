//
//  NSBDataTest
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 30.08.16.
//  Copyright 2016 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <AddressBook/AddressBook.h>


@interface NSDataTest : XCTestCase {
}

@end

@implementation NSDataTest

- (void) setUp
{
}

- (void) tearDown
{
}

- (void) test100
{ // decoding
	NSData *has;
	NSData *wants;
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ=" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQg" options:0] autorelease];
	wants=[@"hello world " dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQNCg==" options:0] autorelease];
	wants=[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"" options:0] autorelease];
	wants=[@"" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test101
{ // decoding options
	NSData *has;
	NSData *wants;
	// invalid characters
	has=[[[NSData alloc] initWithBase64EncodedString:@"a#!%GVsbG8gd29ybGQ=" options:0] autorelease];
	XCTAssertNil(has);
	has=[[[NSData alloc] initWithBase64EncodedString:@"a#!%GVsbG8gd29ybGQ=" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	// invalid characters in padding
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQNCg=#!%=" options:0] autorelease];
	XCTAssertNil(has);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQNCg=#!%=" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test102
{ // whitespace (space, tab, \r, \n) is not always allowed
	NSData *has;
	NSData *wants;
	has=[[[NSData alloc] initWithBase64EncodedString:@"a   GVsbG8gd29ybGQ=" options:0] autorelease];
	XCTAssertNil(has);
	has=[[[NSData alloc] initWithBase64EncodedString:@"a   GVsbG8gd29ybGQ=" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQNCg=   =" options:0] autorelease];
	XCTAssertNil(has);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQNCg=   =" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGV sbG8	gd29\rybG\nQNCg=   =" options:0] autorelease];
	XCTAssertNil(has);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGV sbG8	gd29\rybG\nQNCg=   =" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test103
{ // ignore UTF8
	NSData *has;
	NSData *wants;
	has=[[[NSData alloc] initWithBase64EncodedString:@"a ä€😀 GVsbG8gd29ybGQ=" options:NSDataBase64DecodingIgnoreUnknownCharacters] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test110
{ // wrong padding
	NSData *has;
	NSData *wants;
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ=" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ==" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ" options:0] autorelease];
	XCTAssertNil(has);
	// extra padding is ignored!
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ======" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsb=G8gd29ybGQ==" options:0] autorelease];
	XCTAssertNil(has);
	// characters after padding are ignored
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ=abc" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
	// even invalid characters after padding are ignored
	has=[[[NSData alloc] initWithBase64EncodedString:@"aGVsbG8gd29ybGQ=#!%" options:0] autorelease];
	wants=[@"hello world" dataUsingEncoding:NSASCIIStringEncoding];
}

- (void) test120
{ // nil argument
	XCTAssertThrows([[[NSData alloc] initWithBase64EncodedString:nil options:0] autorelease]);
}

- (void) test200
{ // encoding
	NSData *has;
	NSData *wants;
	NSString *shas;
	NSString *swants;
	has=[[@"hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:0];
	wants=[@"aGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	shas=[[@"hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedStringWithOptions:0];
	swants=@"aGVsbG8gd29ybGQ=";
	XCTAssertEqualObjects(has, wants);
	has=[[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:0];
	wants=[@"aGVsbG8gd29ybGQNCg==" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	shas=[[@"hello world\r\n" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedStringWithOptions:0];
	swants=@"aGVsbG8gd29ybGQNCg==";
	XCTAssertEqualObjects(has, wants);
	// empty string
	has=[[@"" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:0];
	wants=[@"" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test201
{ // encoding options - are ignored for short lines, no final CRLF
	NSData *has;
	NSData *wants;
	has=[[@"hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[@"hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

- (void) test202
{ // encoding options
	NSData *has;
	NSData *wants;
	// CRLF options only if line length given
	has=[[@"hello world hello world hello world hello world hello world hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	has=[[@"hello world hello world hello world hello world hello world hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQg\naGVsbG8gd29ybGQgaGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	// 76 length
	has=[[@"hello world hello world hello world hello world hello world hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29y\nbGQgaGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	// exactly 76 length does not adds a CRLF at the end
	has=[[@"hello world hello world hello world hello world hello w" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gdw==" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqual([has length], 76);
	XCTAssertEqualObjects(has, wants);
	// 64 + 76 length -> is like infinite
	has=[[@"hello world hello world hello world hello world hello world hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength | NSDataBase64Encoding76CharacterLineLength | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
	// CR comes before LF
	has=[[@"hello world hello world hello world hello world hello world hello world" dataUsingEncoding:NSASCIIStringEncoding] base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength | NSDataBase64EncodingEndLineWithCarriageReturn | NSDataBase64EncodingEndLineWithLineFeed];
	wants=[@"aGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQgaGVsbG8gd29ybGQg\r\naGVsbG8gd29ybGQgaGVsbG8gd29ybGQ=" dataUsingEncoding:NSASCIIStringEncoding];
	XCTAssertEqualObjects(has, wants);
}

@end
