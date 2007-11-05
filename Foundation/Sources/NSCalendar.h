//
//  NSCalendar.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
//  Copyright (c) 2005 DSITRI.
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/NSObject.h>
#import <Foundation/NSDate.h>

enum
{
	NSEraCalendarUnit
	// ...
}; typedef NSUInteger NSCalendarUnit;

@interface NSCalendar : NSObject
// not implemented yet

+ (id) autoupdatingCurrentCalendar;

- (BOOL) rangeOfUnit:(NSCalendarUnit) unit startDate:(NSDate **) datep interval:(NSTimeInterval *) tip forDate:(NSDate *) date;

@end