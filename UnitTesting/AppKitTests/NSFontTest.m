//
//  NSFontTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>

// contrary to STAssertEquals(), XCTAssertEqual() can only handle scalar objects
// https://stackoverflow.com/questions/19178109/xctassertequal-error-3-is-not-equal-to-3
// http://www.openradar.me/16281876

#define XCTAssertEquals(a, b, ...) ({ \
	typeof(a) _a=a; typeof(b) _b=b; \
	XCTAssertEqualObjects( \
		[NSValue value:&_a withObjCType:@encode(typeof(a))], \
		[NSValue value:&_b withObjCType:@encode(typeof(b))], \
		##__VA_ARGS__); })


@interface NSFontTest : XCTestCase {
	
}

@end

@implementation NSFontTest

- (void) test1
{ // fonts work
	XCTAssertNotNil([NSFont userFontOfSize:20.0], @"");
	XCTAssertNotNil([NSFont systemFontOfSize:20.0], @"");
}

- (void) test2
{ // check size and name of system fonts
	// CHECKME: hos "carved into stone" are these values? Is it possible to change them?
	// ANswer: yes. Just install newer MacOS X...
	
	XCTAssertEqual([[NSFont boldSystemFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont boldSystemFontOfSize:20.0] fontName], @"LucidaGrande-Bold", @"");
	XCTAssertEqual([[NSFont boldSystemFontOfSize:0.0] pointSize], 13.0f, @"");

	XCTAssertEqual([[NSFont controlContentFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont controlContentFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont controlContentFontOfSize:0.0] pointSize], 12.0f, @"");

	XCTAssertEqual([[NSFont labelFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont labelFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont labelFontOfSize:0.0] pointSize], 10.0f, @"");

	XCTAssertEqual([[NSFont menuBarFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont menuBarFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont menuBarFontOfSize:0.0] pointSize], 14.0f, @"");

	XCTAssertEqual([[NSFont menuFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont menuFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont menuFontOfSize:0.0] pointSize], 13.0f, @"");

	XCTAssertEqual([[NSFont messageFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont messageFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont messageFontOfSize:0.0] pointSize], 13.0f, @"");

	XCTAssertEqual([[NSFont paletteFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont paletteFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont paletteFontOfSize:0.0] pointSize], 11.0f, @"");
	
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", @"");
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, @"");

	XCTAssertEqual([[NSFont systemFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont systemFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont systemFontOfSize:0.0] pointSize], 13.0f, @"");
		
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", @"");
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, @"");

	XCTAssertEqual([[NSFont titleBarFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont titleBarFontOfSize:20.0] fontName], @"LucidaGrande", @"");
	XCTAssertEqual([[NSFont titleBarFontOfSize:0.0] pointSize], 13.0f, @"");

	XCTAssertEqual([[NSFont toolTipsFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", @"");
	XCTAssertEqual([[NSFont toolTipsFontOfSize:0.0] pointSize], 11.0f, @"");

	//	+ (void) setUserFixedPitchFont:(NSFont *) aFont;				// Setting the Font
	
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", @"");
	XCTAssertEqual([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, @"");

	//	+ (void) setUserFont:(NSFont *) aFont;
	
	XCTAssertEqual([[NSFont userFontOfSize:20.0] pointSize], 20.0f, @"");
	XCTAssertEqualObjects([[NSFont userFontOfSize:20.0] fontName], @"Helvetica", @"");
	XCTAssertEqual([[NSFont userFontOfSize:0.0] pointSize], 12.0f, @"");

	XCTAssertEqual([NSFont labelFontSize], 10.0f, @"");
	XCTAssertEqual([NSFont smallSystemFontSize], 11.0f, @"");
	XCTAssertEqual([NSFont systemFontSize], 13.0f, @"");

	XCTAssertEqual([NSFont systemFontSizeForControlSize:NSRegularControlSize], 13.0f, @"");
	XCTAssertEqual([NSFont systemFontSizeForControlSize:NSSmallControlSize], 11.0f, @"");
	XCTAssertEqual([NSFont systemFontSizeForControlSize:NSMiniControlSize], 9.0f, @"");
}

- (void) test5
{ // check font metrics of Helvetica-12.0
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	XCTAssertEqualObjects([font fontName], @"Helvetica", @"");
	XCTAssertEqual([font pointSize], 12.0f, @"");
	XCTAssertEqual([font ascender], 9.240234375f, @"");
	XCTAssertEqual([font descender], -2.759765625f, @"");	// negative value!
	XCTAssertEqual([font leading], 0.0f, @"");
	XCTAssertEqual([font capHeight], 8.607421875f, @"");
	XCTAssertEqual([font xHeight], 6.275390625f, @"");
	XCTAssertFalse([font isFixedPitch], @"");
}

- (void) test7
{
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	NSGlyph g=[font glyphWithName:@"x"];
	// check glyph dimensions and advancement
}

@end
