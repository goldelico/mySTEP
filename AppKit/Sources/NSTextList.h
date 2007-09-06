//
//  NSTextList.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Sat Jan 07 2006.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSTextList
#define _mySTEP_H_NSTextList

#import "AppKit/NSController.h"

enum _NSTextListOptions
{
	NSTextListPrependEnclosingMarker = 0x01
};

@interface NSTextList : NSObject <NSCoding>
{
	NSString *_markerFormat;
	unsigned _listOptions;
}

- (id) initWithMarkerFormat:(NSString *) format options:(unsigned) mask;
- (unsigned) listOptions;
- (NSString *) markerForItemNumber:(int) item;
- (NSString *) markerFormat;

@end

#endif /* _mySTEP_H_NSTextList */
