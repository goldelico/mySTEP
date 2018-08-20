/* 
   NSParagraphStyle.m

   NSParagraphStyle and NSMutableParagraphStyle hold paragraph style 
   information NSTextTab holds information about a single tab stop

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:  Daniel Bðhringer <boehring@biomed.ruhr-uni-bochum.de>
   Date: August 1998
   
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#import <Foundation/Foundation.h>
#import <AppKit/NSParagraphStyle.h>
#import "NSAppKitPrivate.h"

NSString *NSTabColumnTerminatorsAttributeName=@"TabColumnTerminatorsAttributeName"; 

//*****************************************************************************
//
// 		NSTextTab 
//
//*****************************************************************************

@implementation NSTextTab

- (id) initWithTextAlignment:(NSTextAlignment) align location:(CGFloat) loc options:(NSDictionary *) opts;
{
	NSTextTabType type;
	switch(align)
		{
		default:
		case NSLeftTextAlignment:	type=NSLeftTabStopType; break;
		case NSRightTextAlignment:	type=NSRightTabStopType; break;
		case NSCenterTextAlignment:	type=NSCenterTabStopType; break;
		case NSJustifiedTextAlignment:	type=NSLeftTabStopType; break;
		case NSNaturalTextAlignment:	type=YES?NSLeftTabStopType:NSRightTabStopType; break;	// FIXME: get from language user setting
		}
	if((self=[self initWithType:type location:loc]))
		{
		alignment=align;
		options=[opts retain];
		}
	return self;
}

- (id) initWithType:(NSTextTabType)type location:(CGFloat)loc
{	
	if((self = [super init]))
		{
		tabStopType = type; 
		location = loc;
		}
	return self;
}

- (void) dealloc;
{
	[options release];
	[super dealloc];
}

- (NSTextAlignment) alignment;			{ return alignment; }
- (CGFloat) location						{ return location; }
- (NSTextTabType) tabStopType			{ return tabStopType; }
- (NSDictionary *) options				{ return options; }

- (id) copyWithZone:(NSZone *) zone
{
	NSTextTab *c=[[self class] allocWithZone:zone];
	c->tabStopType=tabStopType;
	c->location=location;
	return c;
}

- (id) initWithCoder:(NSCoder *) coder								// NSCoding protocol
{
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
	location=[coder decodeFloatForKey:@"NSLocation"];
	// FIXME: type?
	// NSLineBreakMode
	return self;
}

- (void) encodeWithCoder:(NSCoder *) coder
{
	NIMP;
}

@end

//*****************************************************************************
//
// 		NSParagraphStyle 
//
//*****************************************************************************

@implementation NSParagraphStyle

+ (NSParagraphStyle *) defaultParagraphStyle
{
	static NSParagraphStyle *def;
	if(!def)
		{
		NSMutableParagraphStyle *s=[NSMutableParagraphStyle new];
		int i;
		[s setAlignment:NSNaturalTextAlignment];
		for(i=1; i<=12; i++)
			{ // 12 left aligned tab stops with 28 points distance
			NSTextTab *ts=[[NSTextTab alloc] initWithType:NSLeftTabStopType location:28.0*i];
			[s addTabStop:ts];
			[ts release];
			}
		[s setLineBreakMode:NSLineBreakByWordWrapping];
		[s setBaseWritingDirection:[self defaultWritingDirectionForLanguage:nil]];
		// doc says all others are 0.0
		[s setLineSpacing:0.0];
		[s setParagraphSpacing:0.0];
		[s setFirstLineHeadIndent:0.0];
		[s setHeadIndent:0.0];
		[s setTailIndent:0.0];
		[s setMinimumLineHeight:0.0];
		[s setMaximumLineHeight:0.0];
		def=[s copy];	// immutable copy
		[s release];
		}
	return def;
}

+ (NSWritingDirection) defaultWritingDirectionForLanguage:(NSString *) name;
{
	// FIXME:
	return NSWritingDirectionLeftToRight;
}

- (id) init;
{
	if((self=[super init]))
		{
		tabStops=[NSMutableArray new];
		}
	return self;
}

- (void) dealloc
{
	[tabStops release];
	[textBlocks release];
	[textLists release];
	[super dealloc];
}

/* "Leading": distance between the bottom of one line fragment and top of next (applied between lines in the same container). Can't be negative. This value is included in the line fragment heights in layout manager. */
- (CGFloat) lineSpacing {	return lineSpacing; }

/* Distance between the bottom of this paragraph and top of next. */
- (CGFloat) paragraphSpacing { return paragraphSpacing; }

- (NSTextAlignment) alignment { return alignment; }

/* The following values are relative to the appropriate margin (depending on the paragraph direction) */

/* Distance from margin to front edge of paragraph */
- (CGFloat) headIndent { return headIndent; }

/* Distance from margin to back edge of paragraph; if negative or 0, from other margin */
- (CGFloat) tailIndent { return tailIndent; }

/* Distance from margin to edge appropriate for text direction */
- (CGFloat) firstLineHeadIndent { return firstLineHeadIndent; }

/* Distance from margin to tab stops */
- (NSArray *) tabStops { return tabStops; }

/* Line height is the distance from bottom of descenders to top of ascenders; basically the line fragment height. Does not include lineSpacing (which is added after this computation). */
- (CGFloat) minimumLineHeight { return minimumLineHeight; }

/* 0 implies no maximum. */
- (CGFloat) maximumLineHeight { return maximumLineHeight; }

- (NSLineBreakMode) lineBreakMode { return lineBreakMode; }

- (NSWritingDirection) baseWritingDirection; { return writingDirection; }
- (CGFloat) defaultTabInterval; { return defaultTabInterval; }	// after the last defined tab stop
- (NSInteger) headerLevel; { return headerLevel; }
- (float) hyphenationFactor; { return hyphenationFactor; }
- (CGFloat) lineHeightMultiple; { return lineHeightMultiple; }
- (CGFloat) paragraphSpacingBefore; { return paragraphSpacingBefore; }
- (NSArray *) textBlocks; { return textBlocks; }
- (NSArray *) textLists; { return textLists; }
- (CGFloat) tighteningFactorForTruncation; { return tighteningFactorForTruncation; }

- (id) copyWithZone:(NSZone *) zone { return [self retain]; }

- (id) mutableCopyWithZone:(NSZone *) zone
{
	NSParagraphStyle *c=[NSMutableParagraphStyle new];
	if(c)
		{ // components are not becoming mutable!
		c->tabStops=[tabStops retain];
		c->textBlocks=[textBlocks retain];
		c->textLists=[textLists retain];
		c->lineSpacing=lineSpacing;
		c->paragraphSpacing=paragraphSpacing;
		c->paragraphSpacingBefore=paragraphSpacingBefore;
		c->headIndent=headIndent;
		c->tailIndent=tailIndent;
		c->firstLineHeadIndent=firstLineHeadIndent;
		c->defaultTabInterval=defaultTabInterval;
		c->hyphenationFactor=hyphenationFactor;
		c->lineHeightMultiple=lineHeightMultiple;
		c->minimumLineHeight=minimumLineHeight;
		c->maximumLineHeight=maximumLineHeight;
		c->tighteningFactorForTruncation=tighteningFactorForTruncation;
		c->alignment=alignment;
		c->lineBreakMode=lineBreakMode;
		c->writingDirection=writingDirection;
		c->headerLevel=headerLevel;
		}
	return c;
}

- (void) encodeWithCoder:(NSCoder *) aCoder
{ 
	NIMP;
}

- (id) initWithCoder:(NSCoder *) coder		// NSCoding protocol
{
#if 0
	NSLog(@"%@ initWithCoder: %@", self, coder);
#endif
	alignment=[coder decodeIntForKey:@"NSAlignment"];
	tabStops=[[coder decodeObjectForKey:@"NSTabStops"] retain];
	paragraphSpacing=[coder decodeFloatForKey:@"NSParagraphSpacing"];
	return self;
}

@end

@implementation NSMutableParagraphStyle 

- (id) copyWithZone:(NSZone *) zone
{
	// FIXME: should make an immutable copy!
	return [self retain];
}

- (void) setLineSpacing:(CGFloat)aFloat							{ lineSpacing=aFloat; }
- (void) setParagraphSpacing:(CGFloat)aFloat						{ paragraphSpacing=aFloat; }
- (void) setAlignment:(NSTextAlignment)align					{ alignment=align; }
- (void) setFirstLineHeadIndent:(CGFloat)aFloat					{ firstLineHeadIndent=aFloat; }
- (void) setHeadIndent:(CGFloat)aFloat							{ headIndent=aFloat; }
- (void) setTailIndent:(CGFloat)aFloat							{ tailIndent=aFloat; }
- (void) setLineBreakMode:(NSLineBreakMode)mode					{ lineBreakMode=mode; }
- (void) setMinimumLineHeight:(CGFloat)aFloat						{ minimumLineHeight=aFloat; }
- (void) setMaximumLineHeight:(CGFloat)aFloat						{ maximumLineHeight=aFloat; }
// FIXME: we should insert-sort tabs at the correct position!!!
- (void) addTabStop:(NSTextTab *)anObject						{ [(NSMutableArray *)tabStops addObject:anObject]; }
- (void) removeTabStop:(NSTextTab *)anObject					{ [(NSMutableArray *)tabStops removeObject:anObject]; }
- (void) setTabStops:(NSArray *)array							{ [tabStops release]; tabStops=[array mutableCopy]; }

- (void) setParagraphStyle:(NSParagraphStyle *)obj				{ NIMP; }

- (void) setBaseWritingDirection:(NSWritingDirection) direct;	{ writingDirection=direct; }
- (void) setDefaultTabInterval:(CGFloat) interval;				{ defaultTabInterval=interval; }
- (void) setHeaderLevel:(NSInteger) level;							{ headerLevel=level; }
- (void) setHyphenationFactor:(float) factor;					{ hyphenationFactor=factor; }
- (void) setLineHeightMultiple:(CGFloat) factor;					{ lineHeightMultiple=factor; }
- (void) setParagraphSpacingBefore:(CGFloat) spacing;				{ paragraphSpacingBefore=spacing; }
- (void) setTextBlocks:(NSArray *) blocks;						{ ASSIGN(textBlocks, blocks); }
- (void) setTextLists:(NSArray *) lists;						{ ASSIGN(textLists, lists); }
- (void) setTighteningFactorForTruncation:(float) factor;		{ tighteningFactorForTruncation=factor; }

@end
