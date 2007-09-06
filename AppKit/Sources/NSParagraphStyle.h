/* 
NSParagraphStyle.h

NSParagraphStyle and NSMutableParagraphStyle hold paragraph style 
information NSTextTab holds information about a single tab stop

Copyright (C) 1996 Free Software Foundation, Inc.

Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
Date: August 1998

Author:	H. N. Schaller <hns@computer.org>
Date:	Jun 2006 - aligned with 10.4

This file is part of the mySTEP Library and is provided
under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/Foundation.h>
#import <AppKit/NSText.h>	// e.g. NSWritingDirection

typedef enum _NSTextTabType
{
    NSLeftTabStopType = 0,
    NSRightTabStopType,
    NSCenterTabStopType,
    NSDecimalTabStopType
} NSTextTabType;

typedef enum _NSLineBreakMode
{ // What to do with long lines
    NSLineBreakByWordWrapping = 0,	// Wrap at word boundaries, default
    NSLineBreakByCharWrapping,		// Wrap at character boundaries
    NSLineBreakByClipping,			// Simply clip
    NSLineBreakByTruncatingHead,	// Truncate at head of line: "...wxyz"
    NSLineBreakByTruncatingTail,	// Truncate at tail of line: "abcd..."
    NSLineBreakByTruncatingMiddle	// Truncate middle of line:  "ab...yz"
} NSLineBreakMode;

extern NSString *NSTabColumnTerminatorsAttributeName; 

@interface NSTextTab : NSObject  <NSCopying, NSCoding>
{
	NSDictionary *options;
	NSTextTabType tabStopType;
	NSTextAlignment alignment;
	float location;
}

- (NSTextAlignment) alignment;
- (id) initWithTextAlignment:(NSTextAlignment) align location:(float) loc options:(NSDictionary *) options;
- (id) initWithType:(NSTextTabType)type location:(float)loc;
- (float) location;
- (NSDictionary *) options;
- (NSTextTabType) tabStopType;

@end


@interface NSParagraphStyle : NSObject  <NSCopying, NSMutableCopying, NSCoding>
{
    NSMutableArray *tabStops;
	NSArray *textBlocks;
	NSArray *textLists;
	float lineSpacing;
	float paragraphSpacing;
	float paragraphSpacingBefore;
	float headIndent;
	float tailIndent;
	float firstLineHeadIndent;
	float defaultTabInterval;
	float hyphenationFactor;
	float lineHeightMultiple;
	float minimumLineHeight, maximumLineHeight;
	float tighteningFactorForTruncation;
	NSTextAlignment alignment;
	NSLineBreakMode lineBreakMode;
	NSWritingDirection writingDirection;
	int headerLevel;
}

+ (NSParagraphStyle *) defaultParagraphStyle;
+ (NSWritingDirection) defaultWritingDirectionForLanguage:(NSString *) name;

- (NSTextAlignment) alignment;
- (NSWritingDirection) baseWritingDirection;
- (float) defaultTabInterval;
- (float) firstLineHeadIndent;	/* Distance from margin to edge appropriate for text direction */
- (int) headerLevel;
- (float) headIndent;		/* Distance from margin to front edge of paragraph */
- (float) hyphenationFactor;
- (NSLineBreakMode) lineBreakMode;
- (float) lineHeightMultiple;
- (float) lineSpacing;		/* "Leading": distance between the bottom of one line fragment and top of next (applied between lines in the same container). Can't be negative. This value is included in the line fragment heights in layout manager. */
- (float) maximumLineHeight;	/* 0 implies no maximum. */ 
- (float) minimumLineHeight;	/* Line height is the distance from bottom of descenders to top of ascenders; basically the line fragment height. Does not include lineSpacing (which is added after this computation). */
- (float) paragraphSpacing; 	/* Distance between the bottom of this paragraph and top of next. */
- (float) paragraphSpacingBefore;
- (NSArray *) tabStops;		/* Distance from margin to tab stops */
- (float) tailIndent;		/* Distance from margin to back edge of paragraph; if negative or 0, from other margin */
- (NSArray *) textBlocks;
- (NSArray *) textLists;
- (float) tighteningFactorForTruncation;

@end

@interface NSMutableParagraphStyle : NSParagraphStyle

- (void) addTabStop:(NSTextTab *) tab;
- (void) removeTabStop:(NSTextTab *) tab;
- (void) setAlignment:(NSTextAlignment) alignment;
- (void) setBaseWritingDirection:(NSWritingDirection) direct;
- (void) setDefaultTabInterval:(float) interval;
- (void) setFirstLineHeadIndent:(float) indent;
- (void) setHeaderLevel:(int) level;
- (void) setHeadIndent:(float) indent;
- (void) setHyphenationFactor:(float) factor;
- (void) setLineBreakMode:(NSLineBreakMode) mode;
- (void) setLineHeightMultiple:(float) factor;
- (void) setLineSpacing:(float) leading;
- (void) setMaximumLineHeight:(float) max;
- (void) setMinimumLineHeight:(float) min;
- (void) setParagraphSpacing:(float) spacing;
- (void) setParagraphSpacingBefore:(float) spacing;
- (void) setParagraphStyle:(NSParagraphStyle *) obj;
- (void) setTabStops:(NSArray *) tabs;
- (void) setTailIndent:(float) indent;
- (void) setTextBlocks:(NSArray *) blocks;
- (void) setTextLists:(NSArray *) lists;
- (void) setTighteningFactorForTruncation:(float) factor;

@end
