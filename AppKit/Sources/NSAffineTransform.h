/*
   NSAffineTransform.h

   Copyright (C) 1996 Free Software Foundation, Inc.

   Author:	Ovidiu Predescu <ovidiu@net-community.com>
   Date:	August 1997
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Jan 2006 - aligned with 10.4
 
   Author:	Fabian Spillner
   Date:	16. October 2007
 
   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/

#ifndef _mySTEP_H_NSAffineTransformAdditions
#define _mySTEP_H_NSAffineTransformAdditions

#import <Foundation/NSAffineTransform.h>

@class NSBezierPath;

@interface NSAffineTransform (AppKit)

- (void) concat;
- (void) set;

- (NSBezierPath *) transformBezierPath:(NSBezierPath *) path;

@end

#endif /* _mySTEP_H_NSAffineTransformAdditions */
