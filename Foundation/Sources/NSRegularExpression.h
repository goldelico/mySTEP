/* 
   NSRegularExpression.h

   H.N.Schaller, Aug 2017
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSRegularExpression
#define _mySTEP_H_NSRegularExpression

#import <Foundation/NSObject.h>
#import <Foundation/NSRange.h>

@class NSString;
@class NSMutableString;
@class NSError;
@class NSArray;
@class NSEnumerator;

typedef enum NSRegularExpressionOptions
{
	NSRegularExpressionCaseInsensitive				= 1 << 0,
	NSRegularExpressionAllowCommentsAndWhitespace	= 1 << 1,
	NSRegularExpressionIgnoreMetacharacters			= 1 << 2,
	NSRegularExpressionDotMatchesLineSeparators		= 1 << 3,
	NSRegularExpressionAnchorsMatchLines			= 1 << 4,
	NSRegularExpressionUseUnixLineSeparators		= 1 << 5,
	NSRegularExpressionUseUnicodeWordBoundaries		= 1 << 6
} NSRegularExpressionOptions;

typedef enum NSMatchingFlags
{
	NSMatchingProgress		= 1 << 0,
	NSMatchingCompleted		= 1 << 1,
	NSMatchingHitEnd		= 1 << 2,
	NSMatchingRequiredEnd	= 1 << 3,
	NSMatchingInternalError	= 1 << 4
} NSMatchingFlags;

typedef enum NSMatchingOptions
{
	NSMatchingReportProgress			= 1 << 0,
	NSMatchingReportCompletion			= 1 << 1,
	NSMatchingAnchored					= 1 << 2,
	NSMatchingWithTransparentBounds		= 1 << 3,
	NSMatchingWithoutAnchoringBounds	= 1 << 4
} NSMatchingOptions;

@interface NSTextCheckingResult : NSObject
// has complex internal clockwork...
- (NSRange) range;
@end

@interface NSRegularExpression : NSObject <NSCopying, NSCoding>
{
	NSString *_pattern;
	unsigned int _options;
}

+ (NSRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSRegularExpressionOptions) options error:(NSError **) outError;
+ (NSString *) escapedTemplateForString:(NSString *) string;
+ (NSString *) escapedPatternForString:(NSString *) string;

- (id) initWithPattern:(NSString *) pattern options:(NSRegularExpressionOptions) options error:(NSError **) outError;
- (NSString *) pattern;
- (NSRegularExpressionOptions) options;
- (NSUInteger) numberOfCaptureGroups;

- (NSString *) stringByReplacingMatchesInString:(NSString *) string
										options:(NSMatchingOptions) options
										  range:(NSRange) range
								   withTemplate:(NSString *) theTemplate;
- (NSUInteger) replaceMatchesInString:(NSMutableString *) string
							  options:(NSMatchingOptions) options
								range:(NSRange) range
						withTemplate:(NSString *) theTemplate;
- (NSString *) replacementStringForResult:(NSTextCheckingResult *) result
								 inString:(NSString *) string
								   offset:(NSInteger) offset
								 template:(NSString *) theTemplate;
- (NSUInteger) numberOfMatchesInString:(NSString *) string
							   options:(NSMatchingOptions) options
								 range:(NSRange) range;
// should be: - enumerateMatchesInString:options:range:usingBlock:
- (NSEnumerator *) enumerateMatchesInString:(NSString *) string
									options:(NSMatchingOptions) options
									  range:(NSRange) range;
- (NSArray *) matchesInString:(NSString *) string
					  options:(NSMatchingOptions) options
						range:(NSRange) range;
- (NSTextCheckingResult *) firstMatchInString:(NSString *) string
									  options:(NSMatchingOptions) options
										range:(NSRange) range;
- (NSRange) rangeOfFirstMatchInString:(NSString *) string
							  options:(NSMatchingOptions) options
								range:(NSRange) range;

@end

#endif /* _mySTEP_H_NSRegularExpression */
