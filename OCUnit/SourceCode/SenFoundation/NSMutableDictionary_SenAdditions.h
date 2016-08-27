/*$Id: NSMutableDictionary_SenAdditions.h,v 1.6 2001/11/22 13:11:47 phink Exp $*/

// Copyright (c) 1997-2001, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the license in OpenSourceLicense.html
// found in this distribution and at http://www.sente.ch/software/ ,  where the
// original version of this source code can also be found.
// This notice may not be removed from this file.

#import <Foundation/Foundation.h>
@interface NSDictionary (SenAdditions)
- (id) objectForInt:(int) anInt;

- (id) senDeepMutableCopy;
// Returned object is retained (like with copy)
// Each key/value is tested against methods senDeepMutableCopy, mutableCopy or copy. If
// key/value responds to none of these methods, it is reused by the copy.

@end

@interface NSMutableDictionary (SenAdditions)
- (id) objectForKey:(id) aKey setObjectIfAbsent:(id) anObject;
@end
