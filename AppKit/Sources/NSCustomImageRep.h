/* 
   NSCustomImageRep.h

   Render self via method selector of delegate.

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Felipe A. Rodriguez <far@pcmagic.net>
   Date:    June 2000
   
   Author:	H. N. Schaller <hns@computer.org>
   Date:	Feb 2006 - aligned with 10.4

   This file is part of the mySTEP Library and is provided
   under the terms of the GNU Library General Public License.
*/ 

#ifndef _mySTEP_H_NSCustomImageRep
#define _mySTEP_H_NSCustomImageRep

#import <AppKit/NSImageRep.h>

@interface NSCustomImageRep : NSImageRep
{
	id _delegate;
	SEL _selector;
}

- (id) delegate;
- (SEL) drawSelector;
- (id) initWithDrawSelector:(SEL)aSelector delegate:(id)anObject;

@end

#endif /* _mySTEP_H_NSCustomImageRep */
