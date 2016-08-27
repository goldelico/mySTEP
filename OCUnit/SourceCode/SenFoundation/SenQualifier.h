/*$Id: SenQualifier.h,v 1.1 2002/06/05 08:44:11 phink Exp $*/

// This is Goban, a Go program for Mac OS X.  Contact goban@sente.ch,
// or see http://www.sente.ch/software/goban for more information.
//
// Copyright (c) 1997-2002, Sen:te (Sente SA).  All rights reserved.
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation - version 2.
//
// This program is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE.  See the GNU General Public License in file COPYING
// for more details.
//
// You should have received a copy of the GNU General Public
// License along with this program; if not, write to the Free
// Software Foundation, Inc., 59 Temple Place - Suite 330,
// Boston, MA 02111, USA.

#import <Foundation/Foundation.h>

@protocol SenQualifierEvaluation
- (BOOL) evaluateWithObject:object;
@end


// These are implemented in Foundation.
#define SenQualifierOperatorEqual @selector(isEqualTo:)
#define SenQualifierOperatorNotEqual @selector(isNotEqualTo:)
#define SenQualifierOperatorLessThan @selector(isLessThan:)
#define SenQualifierOperatorGreaterThan @selector(isGreaterThan:)
#define SenQualifierOperatorLessThanOrEqualTo @selector(isLessThanOrEqualTo:)
#define SenQualifierOperatorGreaterThanOrEqualTo @selector(isGreaterThanOrEqualTo:)
#define SenQualifierOperatorContains @selector(doesContain:)
#define SenQualifierOperatorLike @selector(isLike:)
#define SenQualifierOperatorCaseInsensitiveLike @selector(isCaseInsensitiveLike:)



@interface SenQualifier : NSObject <SenQualifierEvaluation>
{
}
@end


@interface SenKeyValueQualifier:SenQualifier <SenQualifierEvaluation>
{
	SEL selector;
	NSString *key;
	id value;
}

- initWithKey:(NSString *) key operatorSelector:(SEL) selector value:(id) value;
- (SEL) selector;
- (NSString *) key;
- (id) value;
@end


@interface SenAndQualifier : SenQualifier <SenQualifierEvaluation>
{
    NSArray *qualifiers;
}

+ qualifierWithQualifierArray:(NSArray *) array;
- initWithQualifierArray: (NSArray *) array;
- (NSArray *) qualifiers;
@end


@interface SenOrQualifier : SenQualifier <SenQualifierEvaluation>
{
    NSArray *qualifiers;
}

+ qualifierWithQualifierArray:(NSArray *) array;
- initWithQualifierArray:(NSArray *)array;
- (NSArray *)qualifiers;
@end


@interface SenNotQualifier:SenQualifier <SenQualifierEvaluation>
{
    SenQualifier *qualifier;
}
+ qualifierWithQualifier:(SenQualifier *) qualifier;
- initWithQualifier:(SenQualifier *) qualifier;
- (SenQualifier *) qualifier;
@end


@interface NSArray (SenQualifierExtras)
- (NSArray *) arrayBySelectingWithQualifier:(SenQualifier *)qualifier;
@end


