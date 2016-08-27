/*$Id: NSString_SenAdditions.h,v 1.7 2002/05/17 11:35:14 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/NSString.h>

@interface NSString (SenAdditions)
- (NSString *) asUnixPath;
- (NSArray *) componentsSeparatedBySpace;
- (NSArray *) componentsSeparatedBySpaceAndNewline;
- (NSArray *) words;
- (NSArray *) paragraphs;
- (NSString *) stringByTruncatingAtNumberOfCharacters:(int) aValue;
- (NSString *) asASCIIString;
- (NSRange) indentationRange;

- (NSString *) stringByTrimmingSpace;

@end
