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

@interface NSRegularExpression : NSObject <NSCoding, NSCopying, NSMutableCopying>
{
	NSString *_pattern;
	NSUInteger _options;
}

+ (NSRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;

- (id) initWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;

- (NSString *) stringByReplacingMatchesInString:(NSString *) string
										options:(NSUInteger) options
										  range:(NSRange) range
								   withTemplate:(NSString *) template;

@end

#endif /* _mySTEP_H_NSRegularExpression */
