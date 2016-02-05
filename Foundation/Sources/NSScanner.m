/* 
 NSScanner.m
 
 Implemenation of NSScanner class
 
 Copyright (C) 1996 Free Software Foundation, Inc.
 
 Author:  Eric Norum <eric@skatter.usask.ca>
 Date: 1996
 
 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */ 

#import <Foundation/NSScanner.h>
#import <Foundation/NSException.h>
#import <Foundation/NSCharacterSet.h>
#import <Foundation/NSDictionary.h>
#import "NSPrivate.h"

#import <limits.h>

@implementation NSScanner
// Create and return a scanner 
+ (id) scannerWithString:(NSString *)aString	// that scans aString.
{
	return [[[self alloc] initWithString:aString] autorelease];
}

+ (id) localizedScannerWithString: (NSString*)locale			{ NIMP; return nil; }

- (id) initWithString:(NSString *)aString		// Initialize a newly-allocated 
{												// scanner to scan aString.
	if((self=[super init]))
		{
		string = [aString copy];
		len = [string length];
		// scanRange=null range
		charactersToBeSkipped = [NSCharacterSet whitespaceAndNewlineCharacterSet];
		[charactersToBeSkipped retain];
		}
	return self;
}

- (void) dealloc
{
	[string release];
	[locale release];
	[charactersToBeSkipped release];
	[super dealloc];
}

- (BOOL) _scanCharactersFromSet:(NSCharacterSet *)set
					 intoString:(NSString **)value;
{
	unsigned int start;					// Like scanCharactersFromSet:intoString: 
	// but no initial skip
	//    NSLog(@"a11. NSRealMemoryAvailable=%u", NSRealMemoryAvailable());
	if (scanRange.location >= len)
		return NO;
	start = scanRange.location;
	//    NSLog(@"a12. NSRealMemoryAvailable=%u", NSRealMemoryAvailable());
	while (scanRange.location < len)
		{
		if(![set characterIsMember: [string characterAtIndex:scanRange.location]])
			break;
		scanRange.location++;
		}
	//    NSLog(@"a13. NSRealMemoryAvailable=%u", NSRealMemoryAvailable());
	if (scanRange.location == start)
		return NO;
	if (value)
		{
		NSRange range;
		
		range.location = start;
		range.length = scanRange.location - start;
		*value = [string substringWithRange: range];
		//		NSLog(@"a14. NSRealMemoryAvailable=%u", NSRealMemoryAvailable());
		}
	
	return YES;
}
// Scan characters to be skipped. Return YES if 
- (BOOL) _skipToNextField		// there are more characters to be scanned.
{								// Return NO if end of the string is reached.
	//    NSLog(@"a1. NSRealMemoryAvailable=%u - skip %@", NSRealMemoryAvailable(), charactersToBeSkipped);
	if(charactersToBeSkipped)
		[self _scanCharactersFromSet: charactersToBeSkipped intoString: NULL];
	//    NSLog(@"a2. NSRealMemoryAvailable=%u", NSRealMemoryAvailable());
	if (scanRange.location >= len)
		return NO;
	
	return YES;
}

// Returns YES if no more characters remain to
// be scanned.  Returns YES if all characters
// remaining to be scanned are to be skipped.
// Returns NO if there are chars left to scan.

- (BOOL) isAtEnd
{
	BOOL ret;
	unsigned int save_scanLocation = scanRange.location;
	if (scanRange.location >= len)
		return YES;
	ret = ![self _skipToNextField];
	if(!ret)
		scanRange.location = save_scanLocation;		// restore
	return ret;
}

// private actual scanInt: performs all except
// for the initial skip.  This method may move 
// the scan location even if a valid integer is 
// not scanned. Based on the strtol code from 
// the GNU C library. A little simpler since we 
// deal only with base 10.  FIXME: I don't use
// decimalDigitCharacterSet since it includes
// many more characters than the ASCII digits.
// I don't know how to convert those other
// characters, so I ignore them for now.  For
// the same reason, I don't try to support all
// the possible Unicode plus and minus chars.

// FIXME: sizeof(NSInteger) may be > sizeof(int)!
// therefore, _scanInt: should go to NSInteger and scanInt: should truncate

- (BOOL) _scanInt: (int*)value
{
	unsigned int num = 0;
	BOOL negative = NO;
	BOOL overflow = NO;
	BOOL got_digits = NO;
	const unsigned int limit = UINT_MAX / 10;
	
	switch ([string characterAtIndex:scanRange.location])	// Check for sign
	{
		case '+':
		scanRange.location++;
		break;
		case '-':
		negative = YES;
		scanRange.location++;
		break;
	}
	
	while (scanRange.location < len)						// Process digits
		{
		unichar digit = [string characterAtIndex: scanRange.location];
		if ((digit < '0') || (digit > '9'))
			break;
		if (!overflow) 
			{
			if (num >= limit)
				overflow = YES;
			else
				num = num * 10 + (digit - '0');
			}
		scanRange.location++;
		got_digits = YES;
		}
	
	if (!got_digits)
		return NO;
	if (value)												// Save the result
		{
		if (overflow || (num > (negative ? (unsigned int)INT_MIN : 
								(unsigned int)INT_MAX)))
			*value = negative ? INT_MIN: INT_MAX;
		else 
			if (negative)
				*value = -num;
			else
				*value = num;
		}
	
	return YES;
}

- (BOOL) scanInt: (int*)value						// Scan an int into value.
{
	unsigned int saveScanLocation = scanRange.location;
	
	if ([self _skipToNextField] && [self _scanInt: value])
		return YES;
	scanRange.location = saveScanLocation;
	
	return NO;
}

- (BOOL) scanInteger: (NSInteger *)value						// Scan an int into value.
{
	unsigned int saveScanLocation = scanRange.location;
	int val;
	if ([self _skipToNextField] && [self _scanInt: &val])
		{
		*value=val;
		return YES;
		}
	scanRange.location = saveScanLocation;
	
	return NO;
}

- (BOOL) scanHexInt:(unsigned int *) value;
{												// Scan an unsigned int of the 
	unsigned int num = 0;							// given radix into value.
	unsigned int numLimit, digitLimit, digitValue, radix;
	BOOL overflow = NO;
	BOOL got_digits = NO;
	unsigned int saveScanLocation = scanRange.location;
	
	if (![self _skipToNextField])							// Skip whitespace
		{	
			scanRange.location = saveScanLocation;
			return NO;
		}
	
	radix = 16;												// Default radix is Hex
	if((scanRange.location < len) 
	   && ([string characterAtIndex:scanRange.location] == '0'))
		{
		radix = 8;
		scanRange.location++;
		got_digits = YES;
		if (scanRange.location < len)
			{
			switch ([string characterAtIndex:scanRange.location])
				{
					case 'x':
					case 'X':
					scanRange.location++;
					radix = 16;
					got_digits = NO;
					break;
				}	}	}
	
	numLimit = UINT_MAX / radix;
	digitLimit = UINT_MAX % radix;
	
	while (scanRange.location < len)						// Process digits
		{
		unichar digit = [string characterAtIndex:scanRange.location];
		switch (digit)
			{
				case '0': digitValue = 0; break;
				case '1': digitValue = 1; break;
				case '2': digitValue = 2; break;
				case '3': digitValue = 3; break;
				case '4': digitValue = 4; break;
				case '5': digitValue = 5; break;
				case '6': digitValue = 6; break;
				case '7': digitValue = 7; break;
				case '8': digitValue = 8; break;
				case '9': digitValue = 9; break;
				case 'a': digitValue = 0xA; break;
				case 'b': digitValue = 0xB; break;
				case 'c': digitValue = 0xC; break;
				case 'd': digitValue = 0xD; break;
				case 'e': digitValue = 0xE; break;
				case 'f': digitValue = 0xF; break;
				case 'A': digitValue = 0xA; break;
				case 'B': digitValue = 0xB; break;
				case 'C': digitValue = 0xC; break;
				case 'D': digitValue = 0xD; break;
				case 'E': digitValue = 0xE; break;
				case 'F': digitValue = 0xF; break;
				default:
				digitValue = radix;
				break;
			}
		if (digitValue >= radix)
			break;
		if (!overflow)
			{
			if ((num > numLimit) || ((num == numLimit) 
									 && (digitValue > digitLimit)))
				overflow = YES;
			else
				num = num * radix + digitValue;
			}
		scanRange.location++;
		got_digits = YES;
		}
	
	if (!got_digits)											// Save result
		{
		scanRange.location = saveScanLocation;
		return NO;
		}
	if (value)
		{
		if (overflow)
			*value = UINT_MAX;
		else
			*value = num;
		}
	
	return YES;
}

- (BOOL) scanHexDouble:(double *) value;
{
	NIMP; return NO;
}

- (BOOL) scanHexFloat:(float *) value;
{
	NIMP; return NO;
}

- (BOOL) scanHexLongLong:(unsigned long long *) value;
{
	NIMP; return NO;
}

// FIXME: we seem to know long long at other locations - where should LONG_LONG_MAX be defined? <limits.h>?

// Scan a long long int into 
// value. Same as scanInt, 
- (BOOL) scanLongLong: (long long *)value		// except with different
{												// variable types and limits.
#if defined(ULLONG_MAX)
	
	unsigned long long num = 0;
	const unsigned long long limit = ULLONG_MAX / 10;
	BOOL negative = NO;
	BOOL overflow = NO;
	BOOL got_digits = NO;
	unsigned int saveScanLocation = scanRange.location;
	
	if (![self _skipToNextField])							// Skip whitespace
		{
		scanRange.location = saveScanLocation;
		return NO;
		}
	
	switch ([string characterAtIndex:scanRange.location])	// Check for sign
	{
		case '+':
		scanRange.location++;
		break;
		case '-':
		negative = YES;
		scanRange.location++;
		break;
	}
	
	while (scanRange.location < len)						// Process digits
		{
		unichar digit = [string characterAtIndex:scanRange.location];
		
		if ((digit < '0') || (digit > '9'))
			break;
		if (!overflow) 
			{
			if (num >= limit)
				overflow = YES;
			else
				num = num * 10 + (digit - '0');
			}
		scanRange.location++;
		got_digits = YES;
		}
	
	if (!got_digits)										// Save result
		{
		scanRange.location = saveScanLocation;
		
		return NO;
		}
	
	if (value)
		{
		if (overflow || (num > (negative ? (unsigned long long) LLONG_MIN : (unsigned long long) LLONG_MAX)))
			*value = negative ? LLONG_MIN: LLONG_MAX;
		else 
			if (negative)
				*value = -num;
			else
				*value = num;
		}
	
	return YES;
	
#else /* defined(LONG_LONG_MAX) */
	// Provide compile-time warning and run-time exception.
#warning "Can't use long long variables."
	[NSException raise: NSGenericException
				format:@"Can't use long long variables."];
	return NO;
#endif /* defined(LONG_LONG_MAX) */
}
// Scan a double into value. Returns 
- (BOOL) scanDouble:(double *)value		// YES if a valid floating-point expr
{										// was scanned.  Returns NO otherwise.
	unichar decimal;						// On overflow, HUGE_VAL or -HUGE_VAL
	unichar c = 0;							// is put in value and YES is returned.
	double num = 0.0;						// On underflow, 0.0 is put into value 
	long int exponent = 0;					// and YES is returned.  Based on the
	BOOL negative = NO;						// strtod code from the GNU C library.
	BOOL got_dot = NO;
	BOOL got_digit = NO;
	unsigned int saveScanLocation = scanRange.location;
	
	if (![self _skipToNextField])							// Skip whitespace
		{
		scanRange.location = saveScanLocation;
		return NO;
		}				// FIXME: Should get decimal point character from 
	// locale.  The problem is that I can't find anything 
	// in the OPENSTEP specification about the format of 
	decimal = '.';		// the locale dictionary.
	
	switch ([string characterAtIndex:scanRange.location])	// Check for sign
	{
		case '+':
		scanRange.location++;
		break;
		case '-':
		negative = YES;
		scanRange.location++;
		break;
	}
	
	while (scanRange.location < len)						// Process number
		{
		c = [string characterAtIndex: scanRange.location];
		if ((c >= '0') && (c <= '9'))
			{		// Ensure that number being accumulated will not overflow
				if (num >= (DBL_MAX / 10.000000001))
					++exponent;
				else
					{
					num = (num * 10.0) + (c - '0');
					got_digit = YES;
					}					// Keep track of the number of digits after 
				// the decimal point. If we just divided  
				if (got_dot)			// by 10 here, we would lose precision.
					--exponent;
			}
		else 
			if (!got_dot && (c == decimal))			// found the decimal point
				got_dot = YES;
			else				// Any other character terminates the number.
				break;
		scanRange.location++;
		}
	
	if (!got_digit)
		{
		scanRange.location = saveScanLocation;
        return NO;
      	}
	
	saveScanLocation = scanRange.location;	// save exponent location
	if ((scanRange.location < len) && ((c == 'e') || (c == 'E')))
		{									// Check for trailing exponent
			int exp;							// Numbers like 1.23eFOO ignore the e character 
			scanRange.location++;
			if (![self _scanInt: &exp])
				scanRange.location = saveScanLocation;
			
			else if (num)							// Check for exponent overflow
				{
				if ((exponent > 0) && (exp > (LONG_MAX - exponent)))
					exponent = LONG_MAX;
				else if ((exponent < 0) && (exp < (LONG_MIN - exponent)))
					exponent = LONG_MIN;
				else
					exponent += exp;
				}
		}
	
	if (value)
		{
		if (num && exponent)
			num *= pow(10.0, (double) exponent);
		if (negative)
			*value = -num;
		else
			*value = num;
		}
	
	return YES;
}										 

- (BOOL) scanFloat:(float*)value		// Scan a float into value. Returns YES
{										// if a valid floating-point expression 
	double num;								// was scanned.  Returns NO otherwise.
	// On overflow, HUGE_VAL or -HUGE_VAL
	if (value == NULL)					// is put in value and YES is returned.
		return [self scanDouble:NULL];	// On underflow, 0.0 is put into value
	if ([self scanDouble:&num])			// and YES is returned.
		{
		//		NSLog(@"scanfloat = %lf", num);
		*value = num;
		return YES;
		}
	
	return NO;
}
// Scan as long as characters from aSet are encountered. Returns YES if 
// any characters were scanned.  Returns NO if no charss were scanned.
// If value is non-NULL, and any characters were scanned, a string
// containing the scanned characters is returned by reference in value.
- (BOOL) scanCharactersFromSet:(NSCharacterSet *)aSet 
					intoString:(NSString **)value;
{
	unsigned int saveScanLocation = scanRange.location;
	
	if ([self _skipToNextField] 
		&& [self _scanCharactersFromSet: aSet intoString: value])
		return YES;
	scanRange.location = saveScanLocation;
	
	return NO;
}
// Scan until a character from aSet is encountered. Returns YES if any 
// characters were scanned.  Returns NO if no characters were scanned.
// If value is non-NULL, and any characters were scanned, a string
// containing the scanned characters is returned by reference in value.
- (BOOL) scanUpToCharactersFromSet:(NSCharacterSet *)set 
						intoString:(NSString **)value;
{
	unsigned int saveScanLocation = scanRange.location;
	unsigned int start;
	
	if (![self _skipToNextField])
		return NO;
	start = scanRange.location;
	while (scanRange.location < len)
		{
		if([set characterIsMember:[string characterAtIndex:scanRange.location]])
			break;
		scanRange.location++;
		}
	if (scanRange.location == start)
		{
		scanRange.location = saveScanLocation;
		return NO;
		}
	if (value)
		{
		NSRange range = {start, scanRange.location - start};
		
		*value = [string substringWithRange: range];
		}
	
	return YES;
}
// Scans for aString. Returns YES if chars at the scan location match 
// aString. Returns NO if the characters at the scan location do not 
// match aString. If the characters at the scan location match aString.
// If value is non-NULL, and the characters at the scan location match 
// aString, a string containing the matching string is returned by 
// reference in value.
- (BOOL) scanString:(NSString *)aString intoString:(NSString **)value;
{
	NSRange range;
	unsigned int i;
	unsigned int saveScanLocation = scanRange.location;
	//	unsigned int m;
	//    NSLog(@"a. NSRealMemoryAvailable=%u", NSRealMemoryAvailable ());
	//	m=NSRealMemoryAvailable ();
	[self _skipToNextField];
	//	if(m != NSRealMemoryAvailable())
	//		NSLog(@"b. NSRealMemoryAvailable: %u -> %u", m, NSRealMemoryAvailable ());
	range.location = scanRange.location;
	range.length = [aString length];
	if (range.location + range.length > len)
		return NO;
	for(i=0; i<range.length; i++)
		{ // fast pre-check for literal match
			if([aString characterAtIndex:i] != [string characterAtIndex:scanRange.location+i])
				break;
		}
	if(i != range.length)
		{ // not a literal match: try again - may match in case insensitive mode or by composed characters
			//	m=NSRealMemoryAvailable ();
			range = [string rangeOfString:aString
								  options:caseSensitive ? NSAnchoredSearch : (NSAnchoredSearch+NSCaseInsensitiveSearch)
									range:range];
			//	if(m != NSRealMemoryAvailable())
			//		NSLog(@"c. NSRealMemoryAvailable: %u -> %u", m, NSRealMemoryAvailable ());
			if (range.length == 0)
				{ // no match - go back
					scanRange.location = saveScanLocation;
					return NO;
				}
		}
	if (value)
		*value = [string substringWithRange:range];
	//	NSLog(@"d. NSRealMemoryAvailable=%u", NSRealMemoryAvailable ());
	scanRange.location += range.length;
	
	return YES;
}
// Scans string until aString
- (BOOL) scanUpToString:(NSString *)aString 	// is encountered.  Return YES
			 intoString:(NSString **)value		// if chars were scanned, NO 
{												// otherwise.  If value is not  
	NSRange range;									// NULL, and any chars were  
	NSRange found;									// scanned, return by reference
	unsigned int saveScanLocation = scanRange.location;	// in value a string containing
	// the scanned characters
	[self _skipToNextField];
	range.location = scanRange.location;
	range.length = len - scanRange.location;
	if([aString length] == 1)
		{ // speed search for single character (can not be a composed sequence)
			unichar c=[aString characterAtIndex:0]; // first character
			unsigned int i;
			found=NSMakeRange(NSNotFound, 0);
			for(i=0; i<range.length; i++)
				{
				if([string characterAtIndex:range.location+i] == c)
					{ // found!
						found=NSMakeRange(range.location+i, 1);
						break;
					}
				}
#if 0
			NSLog(@"range=%@ found=%@", NSStringFromRange(range), NSStringFromRange(found));
#endif
		}
	else
		{ // try full scan
			found = [string rangeOfString:aString
								  options:caseSensitive ? 0 : NSCaseInsensitiveSearch
									range:range];
		}
	if (found.length)
		range.length = found.location - scanRange.location; // limit to found character - otherwise return to end of string
	if (range.length == 0)
		{
		scanRange.location = saveScanLocation;
		// unclear if we should return an empty string in *value!
		return NO;
		}
	if (value)
		*value = [string substringWithRange:range];
	scanRange.location += range.length;
	
	return YES;
}
// Returns the string being scanned
- (NSString *) string			{ return string; }
- (NSUInteger) scanLocation		{ return scanRange.location; }
// char index at 
// which next scan 
// will begin
- (void) setScanLocation:(NSUInteger)anIndex
{															// set char index 
	scanRange.location = anIndex;							// at which next
}															// scan will begin

- (BOOL) caseSensitive						{ return caseSensitive; }	
- (void) setCaseSensitive:(BOOL)flag		{ caseSensitive = flag; }
- (NSCharacterSet *) charactersToBeSkipped	{ return charactersToBeSkipped; }

- (void) setCharactersToBeSkipped:(NSCharacterSet *)aSet	
{														// set characters to be
	[charactersToBeSkipped release];					// ignored during scan
	charactersToBeSkipped = [aSet copy];
}

- (void) setLocale:(NSDictionary *)localeDictionary		// Set dict containing
{														// locale info used by
	locale = [localeDictionary retain];					// the scanner
}
// return local dict
- (NSDictionary *) locale					{ return locale; }

- (id) copyWithZone:(NSZone *) z												// NSCopying protocol
{
	NSScanner *n = [[[self class] alloc] initWithString: string];
	[n setCharactersToBeSkipped: charactersToBeSkipped];
	[n setLocale: locale];
	[n setScanLocation: scanRange.location];
	[n setCaseSensitive: caseSensitive];
	return n;
}

@end
