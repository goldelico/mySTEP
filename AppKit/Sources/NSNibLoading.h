/*
   NSNibLoading.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date: 	November 1997
   
   H.N.Schaller, Jan 2006 - API revised to be compatible to 10.4
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSNibLoading
#define _mySTEP_H_NSNibLoading

#import <AppKit/NSNib.h>
#import <Foundation/NSBundle.h>

@interface NSObject (NibAwaking)

- (void) awakeFromNib;

@end


@interface NSBundle (NSNibLoading)

+ (BOOL) loadNibFile:(NSString *) fileName externalNameTable:(NSDictionary *) context withZone:(NSZone *) zone;
+ (BOOL) loadNibNamed:(NSString*) nibName owner:(id) owner;

- (BOOL) loadNibFile:(NSString *) fileName externalNameTable:(NSDictionary *) context withZone:(NSZone *) zone;

@end

#endif /* _mySTEP_H_NSNibLoading */
