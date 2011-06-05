//
//  CFString.h
//  CoreFoundation
//
//  Created by H. Nikolaus Schaller on 03.10.08.
//  Copyright 2008 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef _mySTEP_H_CFString
#define _mySTEP_H_CFString

#import <CoreFoundation/CFBase.h>

/*
 #import <CoreFoundation/CFLocale.h>
#import <CoreFoundation/CFArray.h>
#import <CoreFoundation/CFData.h>
*/

#if 0	// already defined in CFBase.h
typedef NSString *CFStringRef;
#endif

typedef CFOptionFlags CFStringCompareFlags;
typedef UInt32 CFStringEncoding;
typedef CFIndex CFStringEncodings;

// typedef NSComparisonResult CFComparisonResult;

// CFStringRef CFSTR(const char *str) { return (CFStringRef) [[[NSString alloc] initWithCString:str] autorelease]; }
// formally, the CFSTR generated strings should be the same if the constant is already known and should be immune against retain/release problems

#define CFSTR(str) (CFStringRef) [[[NSString alloc] initWithCString:(str)] autorelease]


#define CFStringCompare (s1, s2, opt) [(s1) compare:(s2) options:(opt)]
#define CFStringCompareWithOptions (s1, s2, rng, opt) [(s1) compare:(s2) range:(rng) options:(opt)]
#define CFStringCompareWithOptionsAndLocale (s1, s2, rng, opt, loc) [(s1) compare:(s2) range:(rng) options:(opt) locale:(loc)]

#define CFStringConvertEncodingToNSStringEncoding(enc) (enc)
#define CFStringConvertNSStringEncodingToEncoding(enc) (enc)

#define CFStringCreateArrayBySeparatingStrings (alloc, str, sep) [(str) componentsSeparatedByString:(sep)]	// allocator is ignored
#define CFStringCreateByCombiningStrings (alloc, array, sep) [(array) componentsJoinedByString:(sep)]	// allocator is ignored

#define CFStringCreateCopy (alloc, str) [(str) copy]

#define CFStringCreateExternalRepresentation (alloc, str, enc, lossByte) [(str) dataUsingEncoding:CFStringConvertEncodingToNSStringEncoding(enc)]

#define CFStringCreateWithBytes (alloc, bytes, n, enc, irep) [[NSString alloc] initWithBytes:(bytes) length:(n)]

#endif
