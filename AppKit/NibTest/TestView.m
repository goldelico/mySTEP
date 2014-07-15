//
//  TestView.m
//  FlushTest
//
//  Created by H. Nikolaus Schaller on 22.11.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "TestView.h"


@implementation TestView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (BOOL) isFlipped;
{
	// the glyphs and lines are never flipped (i.e. text goes top down)
	// for drawInRect: the text always starts at the upper border
	// flipped drawAtPoint defines top left corner and goes down from there
	// unflipped drawAtPoint defines bottom left corner and goes down to here
	return [[NSApp delegate] isFlipped];
}

- (int) contentToShow
{
	return [[NSApp delegate] contentToShow];
}

- (void)drawRect:(NSRect)dirtyRect
{
	switch([self contentToShow]) {
		case 0: {
			// Drawing code here.
			NSMutableDictionary *attr=[NSMutableDictionary dictionaryWithCapacity:10];
			NSMutableParagraphStyle *para=[[NSMutableParagraphStyle defaultParagraphStyle] mutableCopy];
			NSRect bounds;
			NSRect r;
			NSPoint pnt;
			NSString *str=@"1234\nAnd a long second line.\nShort line.";
			NSMutableAttributedString *astr=[[NSMutableAttributedString alloc] initWithString:str];
			switch([[NSApp delegate] alignment]) {
				case 0: [para setAlignment:NSLeftTextAlignment]; break;
				case 1: [para setAlignment:NSRightTextAlignment]; break;
				case 2: [para setAlignment:NSCenterTextAlignment]; break;
				case 3: [para setAlignment:NSJustifiedTextAlignment]; break;
				case 4: [para setAlignment:NSNaturalTextAlignment]; break;
			}
			[attr setObject:para forKey:NSParagraphStyleAttributeName];
			// stringDrawing ignores the alignment - at least here
			bounds=[str boundingRectWithSize:NSMakeSize(160000, 160000) options:NSStringDrawingUsesLineFragmentOrigin attributes:attr];
			NSLog(@"bounds=%@", NSStringFromRect(bounds));
			bounds=[str boundingRectWithSize:NSMakeSize(160000, 160000) options:0 attributes:attr];
			NSLog(@"bounds2=%@", NSStringFromRect(bounds));
			bounds.size=[str sizeWithAttributes:attr];
			NSLog(@"size=%@", NSStringFromSize(bounds.size));
			// but not here
			[str drawInRect:r=NSMakeRect(10.0, 10.0, 100.0, 100.0) withAttributes:attr];
			NSFrameRect(r);
			// but here again
			[str drawAtPoint:pnt=NSMakePoint(150.0, 10.0) withAttributes:attr];
			[[NSColor redColor] set];
			NSFrameRect(NSMakeRect(pnt.x-1, pnt.y-1, 3, 3));
			// this shows that drawAtPoint is effectively using size.height and infinitely wide container
			[str drawInRect:r=NSMakeRect(300.0, 10.0, FLT_MAX, bounds.size.height) withAttributes:attr];
			// add adjustment to first paragraph
			NSLog(@"astr1=%@", astr);
			[astr addAttribute:NSParagraphStyleAttributeName value:[para copy] range:NSMakeRange(0, 5)];
			// remaining range implicitly uses default paragraph style
			NSLog(@"astr2=%@", astr);
			// size is ignored unless we set NSStringDrawingUsesLineFragmentOrigin
			// "as big as needed" is defined by size.width and/or size.height=0.0
			bounds=[astr boundingRectWithSize:NSMakeSize(160000, 160000) options:NSStringDrawingUsesLineFragmentOrigin];
			NSLog(@"bounds=%@", NSStringFromRect(bounds));
			bounds=[astr boundingRectWithSize:NSMakeSize(160000, 160000) options:0];
			NSLog(@"bounds2=%@", NSStringFromRect(bounds));
			bounds.size=[astr size];
			NSLog(@"size=%@", NSStringFromSize(bounds.size));	
			[astr drawInRect:r=NSMakeRect(10.0, 210.0, 100.0, 100.0)];
			// this is drawn in black if astr is not empty
			NSFrameRect(r);
			[astr drawAtPoint:NSMakePoint(150.0, 210.0)];
			{
			NSTextStorage *textStorage = [[NSTextStorage alloc] initWithString:@"Direct\ndrawing\nmultiple\nlines."];
			NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
			NSTextContainer *textContainer = [[NSTextContainer alloc] init];
			NSTextView *textView=[[NSTextView alloc] initWithFrame:NSMakeRect(0.0, 0.0, 500.0, 500.0)];
			NSRange glyphRange;
			NSRect usedRect;
#if 0	// enabling this modifies the result for empty strings or if no NSFontAttributeName is defined
			[textContainer setTextView:textView];
			[textView setTypingAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
										   [NSFont fontWithName:@"Helvetica" size:50],
										   NSFontAttributeName, nil]];
#endif
			NSLog(@"typesetter: %@", [layoutManager typesetter]);
			NSLog(@"textContainer: %@", textContainer);
			[layoutManager addTextContainer:textContainer];
			[textContainer release];	// The layoutManager will retain the textContainer
			[textStorage addLayoutManager:layoutManager];
			[layoutManager release];	// The textStorage will retain the layoutManager
			[layoutManager setUsesScreenFonts:NO];
			[layoutManager setBackgroundLayoutEnabled:NO];
			NSLog(@"allowsNonContiguousLayout %@", [layoutManager allowsNonContiguousLayout]?@"yes":@"no");
			NSLog(@"backgroundLayoutEnabled %@", [layoutManager backgroundLayoutEnabled]?@"yes":@"no");
			// here we see 0
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);
			[layoutManager ensureGlyphsForGlyphRange:NSMakeRange(0, 5)];
			// since we still see 0 here, firstUnlaidGlyph has nothing to do with the glyph generation
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);
			NSLog(@"isValidGlyphIndex:5 %@", [layoutManager isValidGlyphIndex:5]?@"yes":@"no");
			// here we get nil because there is no layout for this glyph
			NSLog(@"textContainer=%@", [layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES]);
			[layoutManager ensureGlyphsForCharacterRange:NSMakeRange(0, 10)];
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			NSLog(@"isValidGlyphIndex:5 %@", [layoutManager isValidGlyphIndex:5]?@"yes":@"no");
			[layoutManager ensureLayoutForGlyphRange:NSMakeRange(0, 5)];
			// here we will see 7 (first line!)
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			// here we have a text container
			NSLog(@"textContainer=%@", [layoutManager textContainerForGlyphAtIndex:0 effectiveRange:NULL withoutAdditionalLayout:YES]);
			glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
			// here we will see 30 (all lines!)
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			[layoutManager invalidateLayoutForCharacterRange:NSMakeRange(7, 5) actualCharacterRange:NULL];
			// here we will see 7 again since it has been reset
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			// drawing in a non-flipped view will draw lines from bottom to top, but glyphs are not flipped!
			// and, glyphs appear to have a different baseline origin
			[layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:pnt=NSMakePoint(300.0, 180.0)];
			// here we see 30 again because the layout has been reestablished
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			// it appears that this method also generates all glyphs at least up to the index
			NSLog(@"isValidGlyphIndex:5 %@", [layoutManager isValidGlyphIndex:5]?@"yes":@"no");
			NSLog(@"isValidGlyphIndex:10 %@", [layoutManager isValidGlyphIndex:10]?@"yes":@"no");
			NSLog(@"isValidGlyphIndex:29 %@", [layoutManager isValidGlyphIndex:29]?@"yes":@"no");
			NSLog(@"isValidGlyphIndex:30 %@", [layoutManager isValidGlyphIndex:30]?@"yes":@"no");
			NSLog(@"isValidGlyphIndex:50 %@", [layoutManager isValidGlyphIndex:50]?@"yes":@"no");
			// returns range {7, 7}
			NSLog(@"rangeOfNominallySpacedGlyphsContainingIndex:10=%@", NSStringFromRange([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10]));
			[layoutManager locationForGlyphAtIndex:10];	// needs calculation
			// range is unchanged, i.e. locationForGlyphAtIndex appears to interpolate locations within ranges if someone asks (e.g. CircleView)!
			NSLog(@"rangeOfNominallySpacedGlyphsContainingIndex:10=%@", NSStringFromRange([layoutManager rangeOfNominallySpacedGlyphsContainingIndex:10]));
			[[NSColor redColor] set];
			NSFrameRect(NSMakeRect(pnt.x-1, pnt.y-1, 3, 3));
				{
				NSAttributedString *astr;
				NSDictionary *attrs=[NSDictionary dictionaryWithObjectsAndKeys:
									[NSFont fontWithName:@"Helvetica" size:24.0], 
									NSFontAttributeName, nil];
				// what is the default line height for empty strings? Cocoa returns {0,15}, i.e. 12pt + 3
				NSLog(@"[@\"\" sizeWithAttributes:nil]: %@", NSStringFromSize([@"" sizeWithAttributes:nil]));
				// this returns {0, 30} i.e. 24pt + 6, i.e default line height is 125% of font height
				// and Cocoa can apply the attributes to an empty string!
				NSLog(@"[@\"\" sizeWithAttributes:font]: %@", NSStringFromSize([@"" sizeWithAttributes:attrs]));
				astr=[[[NSAttributedString alloc] initWithString:@""] autorelease];
				// empty attributed strings have no attributes, i.e. the default (Helvetica-12) applies
				NSLog(@"[@\"\"{} size]: %@", NSStringFromSize([astr size]));
				astr=[[[NSAttributedString alloc] initWithString:@"" attributes:attrs] autorelease];
				NSLog(@"[@\"\"{font} size]: %@", NSStringFromSize([astr size]));
				}
			// try same directly on textstorage
			[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@""];
			// now we should have no layout, i.e. 0
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			// we must ensure the layout because usedRectForTextContainer does not
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			// here we get {{0, 0}, {10, 14}} which means that the extra fragment is part of the usedRect
			// and this may be the size of the \n glyph as provided by the font
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			// this is the container we have provided
			NSLog(@"extraFragmentContainer: %@", [layoutManager extraLineFragmentTextContainer]);
			// is {{0, 0}, {1e+07, 14}}
			NSLog(@"extraLineFragmentRect: %@", NSStringFromRect([layoutManager extraLineFragmentRect]));
			// is {{0, 0}, {10, 14}}
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// size of empty string is {0, 15}, i.e. uses a different default font!
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			// [astr boundingRectWithSize:options:0]={{0, -3}, {0, 15}}
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			// [astr boundingRectWithSize:options:1]={{0, 0}, {0, 15}}
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			// try to change font - but has no influence
			[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			// has no influence, i.e. there is some default font involved
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// size of empty string
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			// add one character
			[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@" "];
			// we must ensure the layout because usedRectForTextContainer does not
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			// now we should have a layout, i.e. 1
			NSLog(@"firstUnlaidGlyph=%u", [layoutManager firstUnlaidGlyphIndex]);
			NSLog(@"firstUnlaidCharacter=%u", [layoutManager firstUnlaidCharacterIndex]);				
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			// here we get {{0, 0}, {13.334, 14}} - which appears to be the " " glyph
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			// is nil
			NSLog(@"extraFragmentContainer: %@", [layoutManager extraLineFragmentTextContainer]);
			// is NSZeroRect
			NSLog(@"extraLineFragmentRect: %@", NSStringFromRect([layoutManager extraLineFragmentRect]));
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// [astr size]={3, 15} - if this is the " " glyph, it is smaller but taller than above!
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			// [astr boundingRectWithSize:options:0]={{0, -3}, {3, 15}}
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			// [astr boundingRectWithSize:options:1]={{0, 0}, {3, 15}}
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			// add one character
			[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"j"];
			// we must ensure the layout because usedRectForTextContainer does not
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			// here we get {{0, 0}, {12.666, 14}} which is smaller
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			// still no extra rect
			NSLog(@"extraFragmentContainer: %@", [layoutManager extraLineFragmentTextContainer]);
			NSLog(@"extraLineFragmentRect: %@", NSStringFromRect([layoutManager extraLineFragmentRect]));
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// size of string
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			// single new line
			[textStorage replaceCharactersInRange:NSMakeRange(0, [textStorage length]) withString:@"\n"];
			// we must ensure the layout because usedRectForTextContainer does not
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			// here we get {{0, 0}, {10, 28}} i.e. two lines!
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			NSLog(@"extraFragmentContainer: %@", [layoutManager extraLineFragmentTextContainer]);
			NSLog(@"extraLineFragmentRect: %@", NSStringFromRect([layoutManager extraLineFragmentRect]));
			// here we see {{0, 14}, {10, 14}} i.e. the extra starts on a new line
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// size of string - here [astr size]={0, 30}
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			// [astr boundingRectWithSize:options:0]={{0, -3}, {0, 15}} -- single line!
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			// [astr boundingRectWithSize:options:1]={{0, 0}, {0, 30}} -- double line
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			// change the font
			[textStorage setFont:[NSFont fontWithName:@"Helvetica" size:24.0]];
			// we must ensure the layout because usedRectForTextContainer does not
			[layoutManager ensureLayoutForCharacterRange:NSMakeRange(0, [textStorage length])];
			usedRect = [layoutManager usedRectForTextContainer:textContainer];
			NSLog(@"usedRectForTextContainer: %@", NSStringFromRect(usedRect));
			NSLog(@"extraFragmentContainer: %@", [layoutManager extraLineFragmentTextContainer]);
			NSLog(@"extraLineFragmentRect: %@", NSStringFromRect([layoutManager extraLineFragmentRect]));
			// now we have {{0, 0}, {10, 58}} i.e. each line is 29 pt heigh
			NSLog(@"extraLineFragmentUsedRect: %@", NSStringFromRect([layoutManager extraLineFragmentUsedRect]));
			// size of string [astr size]={0, 60}
			NSLog(@"[astr size]=%@", NSStringFromSize([textStorage size]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", 0, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options:0]));
			NSLog(@"[astr boundingRectWithSize:options:%u]=%@", NSStringDrawingUsesLineFragmentOrigin, NSStringFromRect([textStorage boundingRectWithSize:NSMakeSize(FLT_MAX, FLT_MAX) options: NSStringDrawingUsesLineFragmentOrigin]));
			}
			break;
		case 1: { /* found on http://www.jwz.org/blog/2006/04/nsfont-is-full-of-lies/ */
			NSString *str = @"j";
			NSFont *font = [NSFont fontWithName:@"Helvetica-BoldOblique" size:180];
			
			NSDictionary *attr = [NSDictionary dictionaryWithObject:font
															 forKey:NSFontAttributeName];
			NSSize bbox = [str sizeWithAttributes:attr];
			NSRect frame = [self bounds];
			NSPoint pos;
			NSLog(@"bbox=%@", NSStringFromSize(bbox));
			pos.x = (frame.origin.x + ((frame.size.width  - bbox.width)  / 2));
			pos.y = (frame.origin.y + ((frame.size.height - bbox.height) / 2));
			
			NSGlyph g;
			{
			NSTextStorage *ts = [[NSTextStorage alloc] initWithString:str];
			[ts setFont:font];
			NSLayoutManager *lm = [[NSLayoutManager alloc] init];
			NSTextContainer *tc = [[NSTextContainer alloc] init];
			[lm addTextContainer:tc];
			[tc release];	// lm retains tc
			[ts addLayoutManager:lm];
			[lm release];	// ts retains lm
			g = [lm glyphAtIndex:0];
			[ts release];
			}
			
			
			/* Clear window and draw the character.
			 */
			[[NSColor whiteColor] set];
			NSRectFill([self bounds]);
			NSLog(@"origin=%@", NSStringFromPoint(pos));
			
			
			[str drawAtPoint:pos withAttributes:attr];
			
			
			/* Draw blue square marking origin.
			 */
			NSLog(@"descender=%g", [font descender]);
			frame.origin = pos;
			frame.origin.y -= [font descender];
			frame.size.width = frame.size.height = 10;
			[[NSColor blueColor] set];
			NSLog(@"origin dot=%@", NSStringFromRect(frame));
			NSRectFill (frame);
			
			
			/* Draw blue baseline according to [NSFont descender].
			 */
			frame.origin.x = 0;
			frame.origin.y = pos.y - [font descender];
			frame.size.width = [self bounds].size.width;
			frame.size.height = 1;
			[[NSColor blueColor] set];
			NSLog(@"baseline=%@", NSStringFromRect(frame));
			NSFrameRect (frame);
			
			
			/* Draw purple line according to [NSFont advancementForGlyph].
			 */
			NSLog(@"advancement=%@", NSStringFromSize([font advancementForGlyph:g]));
			
			frame.origin.x = pos.x + [font advancementForGlyph:g].width;
			frame.origin.y = 0;
			frame.size.width = 1;
			frame.size.height = [self bounds].size.height;
			[[NSColor purpleColor] set];
			NSLog(@"advancementLine=%@", NSStringFromRect(frame));
			NSFrameRect (frame);
			
			
			/* Draw red bounding box according to [NSString sizeWithAttributes].
			 */
			frame.origin = pos;
			frame.size = bbox;
			[[NSColor redColor] set];
			NSLog(@"sizeWithAttribs=%@", NSStringFromRect(frame));
			NSFrameRect (frame);
			
			
			/* Draw green bounding box according to [NSFont boundingRectForGlyph].
			 */
			NSRect bbox2 = [font boundingRectForGlyph: g];
			NSLog(@"boundingRect=%@", NSStringFromRect(bbox2));
			frame.origin.x = pos.x + bbox2.origin.x;
			// Cocoa doesn't lie if transform is applied correctly...
			// and the view is not flipped!
			frame.origin.y = pos.y - [font descender] + bbox2.origin.y;
			// for flipped if should not account for descender (?)
			frame.size = bbox2.size;
			[[NSColor greenColor] set];
			NSLog(@"boundingRectBox=%@", NSStringFromRect(frame));
			NSFrameRect (frame);
			
			
			/* Draw yellow bounding box according to [NSFont boundingRectForFont].
			 */
			bbox2 = [font boundingRectForFont];
			NSLog(@"fontBoundingRect=%@", NSStringFromRect(bbox2));
			frame.origin.x = pos.x + bbox2.origin.x;
			frame.origin.y = pos.y - [font descender] + bbox2.origin.y;
			frame.size = bbox2.size;
			[[NSColor yellowColor] set];
			NSLog(@"fontBoundingRectBox=%@", NSStringFromRect(frame));
			NSFrameRect (frame);
		}
			break;
		}
	}
}

@end

@implementation NSLayoutManager (Inspect)

#if 0
- (void)textContainerChangedGeometry:(NSTextContainer *)aTextContainer
{
	NSLog(@"textContainer=%@", aTextContainer);
}
#endif
#if 0
- (void)setUsesScreenFonts:(BOOL)flag
{
	
}
#endif

@end
