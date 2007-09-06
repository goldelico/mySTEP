//
//  NSTypesetter.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Fri Jun 29 2006.
//  Copyright (c) 2006 DSITRI.
//
//  This is incomplete!
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSTypesetter
#define _mySTEP_H_NSTypesetter

#import "AppKit/NSResponder.h"

typedef enum _NSTypesetterControlCharacterAction
{
	NSTypesetterZeroAdvancementAction,
	NSTypesetterWhitespaceAction,
	NSTypesetterHorizontalTabAction,
	NSTypesetterLineBreakAction,
	NSTypesetterParagraphBreakAction,
	NSTypesetterContainerBreakAction,
} NSTypesetterControlCharacterAction;


@interface NSTypesetter : NSObject

+ (NSTypesetterBehavior) defaultTypesetterBehavior;
+ (id) sharedSystemTypesetter;
+ (id) sharedSystemTypesetterForBehavior:(NSTypesetterBehavior) theBehavior;

@end

#endif /* _mySTEP_H_NSTypesetter */
