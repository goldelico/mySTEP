/* 
 * NSRegularEspression.m
 *
 * H.N.Schaller, Aug 2017
 *
 * This file is part of the mySTEP Library and is provided
 * under the terms of the GNU Library General Public License.
 */

#import <Foundation/Foundation.h>
#import "NSPrivate.h"

@implementation NSRegularExpression

+ (NSRegularExpression *) regularExpressionWithPattern:(NSString *) pattern options:(NSRegularExpressionOptions) options error:(NSError **) outError;
{
	return [[[NSRegularExpression alloc] initWithPattern:pattern options:options error:outError] autorelease];
}

- (id) initWithPattern:(NSString *) pattern options:(NSRegularExpressionOptions) options error:(NSError **) outError;
{
	if((self=[super init]))
		{
		_pattern=[pattern retain];
		_options=options;
		}
	return self;
}

- (NSString *) pattern; { return _pattern; }
- (NSRegularExpressionOptions) options; { return _options; }

- (NSString *) stringByReplacingMatchesInString:(NSString *) string
										options:(NSMatchingOptions) options
										  range:(NSRange) range
								   withTemplate:(NSString *) template;
{
	return string;
}

// FIXME: should be the basic function
- (NSEnumerator *) enumerateMatchesInString:(NSString *) string
									options:(NSMatchingOptions) options
									  range:(NSRange) range;
{
	return [[self matchesInString:string options:options range:range] objectEnumerator];
}

// FIXME: should be a convenience function wrapping enumerateMatchesInString
- (NSArray *) matchesInString:(NSString *) string
					  options:(NSMatchingOptions) options
						range:(NSRange) range;
{
	return NIMP;
}

- (NSUInteger) numberOfMatchesInString:(NSString *) string
							   options:(NSMatchingOptions) options
								 range:(NSRange) range;
{
	return [[self matchesInString:string options:options range:range] count];
}

- (NSTextCheckingResult *) firstMatchInString:(NSString *) string
									  options:(NSMatchingOptions) options
										range:(NSRange) range;
{
	NSArray *matches=[self matchesInString:string options:options range:range];
	if([matches count] > 0)
		return [matches objectAtIndex:0];
	return nil;

}

- (NSRange) rangeOfFirstMatchInString:(NSString *) string
							  options:(NSMatchingOptions) options
								range:(NSRange) range;
{
	NSTextCheckingResult *first=[self firstMatchInString:string options:options range:range];
	if(first)
		return [first range];
	return (NSRange){ NSNotFound, 0 };
}

@end /* NSRegularExpression */
