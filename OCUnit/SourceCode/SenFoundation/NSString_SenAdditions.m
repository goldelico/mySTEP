/*$Id: NSString_SenAdditions.m,v 1.8 2002/07/01 10:00:58 kindov Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import "NSString_SenAdditions.h"
#import "SenCollection.h"
#import <Foundation/Foundation.h>

#define NT_PATH_SEPARATOR  @"\\"
#define UNIX_PATH_SEPARATOR @"/"

@implementation NSString (SenAdditions)

- (NSString *) asUnixPath
{
    NSArray *components = [[[self pathComponents] collectionByRejectingWithSelector:@selector(isEqualToString:) withObject:NT_PATH_SEPARATOR] asArray];
    return [[components componentsJoinedByString:UNIX_PATH_SEPARATOR] stringByStandardizingPath];
}

- (NSArray *) componentsSeparatedBySpace
{
    NSCharacterSet *space = [NSCharacterSet whitespaceCharacterSet];
    NSMutableArray *elements = [NSMutableArray array];
    NSScanner *elementScanner = [NSScanner scannerWithString:self];
    while (![elementScanner isAtEnd]) {
        NSString *element;
        if ([elementScanner scanUpToCharactersFromSet:space intoString:&element]) {
            [elements addObject:element];
        }
    }
    return elements;
}

- (NSArray *) componentsSeparatedBySpaceAndNewline
{
    NSCharacterSet *space = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSMutableArray *elements = [NSMutableArray array];
    NSScanner *elementScanner = [NSScanner scannerWithString:self];
    while (![elementScanner isAtEnd]) {
        NSString *element;
        if ([elementScanner scanUpToCharactersFromSet:space intoString:&element]) {
            [elements addObject:element];
        }
    }
    return elements;
}

- (NSArray *) words
{
    static NSMutableCharacterSet *separator = nil;
    NSMutableArray *elements = [NSMutableArray array];
    NSScanner *elementScanner = [[NSScanner alloc] initWithString:self];

    if(!separator){
        separator = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
        [separator formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
    }

    [elementScanner setCharactersToBeSkipped:separator];

    while (![elementScanner isAtEnd]) {
        NSString *element;
        if ([elementScanner scanUpToCharactersFromSet:separator intoString:&element]) {
            [elements addObject:element];
        }
    }
    [elementScanner release];
    
    return elements;
}

- (NSArray *)paragraphs
{
    NSCharacterSet *paragraphSeparators=[NSCharacterSet characterSetWithCharactersInString:@"\n\r"];
    NSCharacterSet *notParagraphSeparatorsOrWhiteSpaces = [[NSCharacterSet characterSetWithCharactersInString:@"\n\t\r  "] invertedSet];
    NSRange searchRange;
    NSRange foundRange;
    NSRange textRange;
    NSMutableArray *paragraphs=[NSMutableArray array];

    searchRange.location=0;
    searchRange.length=[self length];

    while (searchRange.length) {
        foundRange=[self rangeOfCharacterFromSet:notParagraphSeparatorsOrWhiteSpaces options:0 range:searchRange];
        if (foundRange.length) {
            searchRange.location=foundRange.location+foundRange.length-1;
            searchRange.length=[self length]-searchRange.location;
            foundRange=[self rangeOfCharacterFromSet:paragraphSeparators options:0 range:searchRange];
            if (foundRange.length) {
                textRange.location=searchRange.location;
                textRange.length=foundRange.location-searchRange.location;
                [paragraphs addObject:[self substringWithRange:textRange]];
                searchRange.location=foundRange.location+foundRange.length-1;
                searchRange.length=[self length]-searchRange.location;
            }
            else {
                textRange=searchRange;
                [paragraphs addObject:[self substringWithRange:textRange]];
                searchRange.length=0;
            }
        }
        else {
            searchRange.length=0;
        }
    }
    return paragraphs;
}

- (NSString *) stringByTruncatingAtNumberOfCharacters:(int) aValue
{
    if ([self length] <= aValue) {
        return self;
    }
    return [[self substringToIndex:MIN (aValue, [self length] - 1)] stringByAppendingString:@"..."];
}

- (NSString *) asASCIIString
{
    NSData *asciiData = [self dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    return [[[NSString alloc] initWithData:asciiData encoding:NSASCIIStringEncoding] autorelease];
}

- (NSRange) indentationRange
{
    NSCharacterSet *nonWhitespaceCharacterSet = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
    NSRange first = [self rangeOfCharacterFromSet:nonWhitespaceCharacterSet];
    return NSMakeRange (0, first.location);
}

- (NSString *) stringByTrimmingSpace
{
	NSEnumerator *componentEnumerator = [[self componentsSeparatedByString:@" "] objectEnumerator];
	NSMutableArray *components = [NSMutableArray array];
	id each;

	while (each = [componentEnumerator nextObject]) {
		if (!isNilOrEmpty (each)) {
			[components addObject:each];
		}
	}
	return [components componentsJoinedByString:@" "];
}

@end
