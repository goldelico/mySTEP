/* 
 * NSRegularEspression.m
 *
 * H.N.Schaller, Aug 2017
 *
 * This file is part of the mySTEP Library and is provided
 * under the terms of the GNU Library General Public License.
 */

#import <Foundation/NSRegularExpression.h>
#import <Foundation/NSString.h>

#import "NSPrivate.h"

@implementation NSRegularExpression

+ (NSRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;
{
	return [[[NSRegularExpression alloc] initWithPattern:pattern options:options error:outError] autorelease];
}

- (id) initWithPattern:(NSString *) pattern options:(NSUInteger) options error:(NSError **) outError;
{
	if((self=[super init]))
		{
		_pattern=[pattern retain];
		_options=options;
		}
	return self;
}

- (NSString *) stringByReplacingMatchesInString:(NSString *) string
										options:(NSUInteger) options
										  range:(NSRange) range
								   withTemplate:(NSString *) template;
{
	return string;
}
@end /* NSRegularExpression */
