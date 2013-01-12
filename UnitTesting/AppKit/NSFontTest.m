//
//  NSFontTest.m
//  UnitTests
//
//  Created by H. Nikolaus Schaller on 26.12.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSFontTest.h"

@implementation NSFontTest

- (void) test1
{ // fonts work
	STAssertNotNil([NSFont userFontOfSize:20.0], nil);
	STAssertNotNil([NSFont systemFontOfSize:20.0], nil);
}

- (void) test2
{ // check size and name of system fonts
	// CHECKME: hos "carved into stone" are these values? Is it possible to change them?
	
	STAssertEquals([[NSFont boldSystemFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont boldSystemFontOfSize:20.0] fontName], @"LucidaGrande-Bold", nil);
	STAssertEquals([[NSFont boldSystemFontOfSize:0.0] pointSize], 13.0f, nil);

	STAssertEquals([[NSFont controlContentFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont controlContentFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont controlContentFontOfSize:0.0] pointSize], 12.0f, nil);

	STAssertEquals([[NSFont labelFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont labelFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont labelFontOfSize:0.0] pointSize], 10.0f, nil);

	STAssertEquals([[NSFont menuBarFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont menuBarFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont menuBarFontOfSize:0.0] pointSize], 14.0f, nil);

	STAssertEquals([[NSFont menuFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont menuFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont menuFontOfSize:0.0] pointSize], 13.0f, nil);

	STAssertEquals([[NSFont messageFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont messageFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont messageFontOfSize:0.0] pointSize], 13.0f, nil);

	STAssertEquals([[NSFont paletteFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont paletteFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont paletteFontOfSize:0.0] pointSize], 11.0f, nil);
	
	STAssertEquals([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", nil);
	STAssertEquals([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, nil);

	STAssertEquals([[NSFont systemFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont systemFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont systemFontOfSize:0.0] pointSize], 13.0f, nil);
		
	STAssertEquals([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", nil);
	STAssertEquals([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, nil);

	STAssertEquals([[NSFont titleBarFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont titleBarFontOfSize:20.0] fontName], @"LucidaGrande", nil);
	STAssertEquals([[NSFont titleBarFontOfSize:0.0] pointSize], 13.0f, nil);

	STAssertEquals([[NSFont toolTipsFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", nil);
	STAssertEquals([[NSFont toolTipsFontOfSize:0.0] pointSize], 11.0f, nil);

	//	+ (void) setUserFixedPitchFont:(NSFont *) aFont;				// Setting the Font
	
	STAssertEquals([[NSFont userFixedPitchFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont userFixedPitchFontOfSize:20.0] fontName], @"Monaco", nil);
	STAssertEquals([[NSFont userFixedPitchFontOfSize:0.0] pointSize], 10.0f, nil);

	//	+ (void) setUserFont:(NSFont *) aFont;
	
	STAssertEquals([[NSFont userFontOfSize:20.0] pointSize], 20.0f, nil);
	STAssertEqualObjects([[NSFont userFontOfSize:20.0] fontName], @"Helvetica", nil);
	STAssertEquals([[NSFont userFontOfSize:0.0] pointSize], 12.0f, nil);

	STAssertEquals([NSFont labelFontSize], 10.0f, nil);
	STAssertEquals([NSFont smallSystemFontSize], 11.0f, nil);
	STAssertEquals([NSFont systemFontSize], 13.0f, nil);

	STAssertEquals([NSFont systemFontSizeForControlSize:NSRegularControlSize], 13.0f, nil);
	STAssertEquals([NSFont systemFontSizeForControlSize:NSSmallControlSize], 11.0f, nil);
	STAssertEquals([NSFont systemFontSizeForControlSize:NSMiniControlSize], 9.0f, nil);
}

- (void) test5
{ // check font metrics of Helvetica-12.0
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	STAssertEqualObjects([font fontName], @"Helvetica", nil);
	STAssertEquals([font pointSize], 12.0f, nil);
	STAssertEquals([font ascender], 9.240234375f, nil);
	STAssertEquals([font descender], -2.759765625f, nil);	// negative value!
	STAssertEquals([font leading], 0.0f, nil);
	STAssertEquals([font capHeight], 8.607421875f, nil);
	STAssertEquals([font xHeight], 6.275390625f, nil);
	STAssertFalse([font isFixedPitch], nil);
}

- (void) test7
{
	NSFont *font=[NSFont fontWithName:@"Helvetica" size:12.0];
	NSGlyph g=[font glyphWithName:@"x"];
	// check glyph dimensions and advancement
}

@end
