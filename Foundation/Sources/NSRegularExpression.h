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
@class NSError;

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

@interface NSRegularExpression : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	NSString *_pattern;
	NSUInteger _options;
}

+ (NSRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;

- (id) initWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;
- (NSString *) pattern;
- (NSRegularExpressionOptions) options;

- (NSString *) stringByReplacingMatchesInString:(NSString *) string
										options:(NSUInteger) options
										  range:(NSRange) range
								   withTemplate:(NSString *) template;

@end

#endif /* _mySTEP_H_NSRegularExpression */
