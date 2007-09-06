//
//  NSUserDefaultsController.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Mon Mar 21 2005.
//  Copyright (c) 2005 DSITRI.
//
//    This file is part of the mySTEP Library and is provided
//    under the terms of the GNU Library General Public License.
//

#ifndef _mySTEP_H_NSUserDefaultsController
#define _mySTEP_H_NSUserDefaultsController

#import "Foundation/NSObject.h"
#import "AppKit/NSController.h"
@class NSString;
@class NSCoder;

@interface NSUserDefaultsController : NSController <NSCoding>
{
	NSUserDefaults *_defaults;
	NSDictionary *_initialValues;
	id _values;
	BOOL _appliesImmediately;
}

+ (id) sharedUserDefaultsController;
- (BOOL) appliesImmediately;
- (NSUserDefaults *) defaults;
- (NSDictionary *) initialValues;
- (id) initWithDefaults:(NSUserDefaults *) defaults
		  initialValues:(NSDictionary *) values;
- (void) revert:(id) sender;
- (void) revertToInitialValues:(id) sender;
- (void) save:(id) sender;
- (void) setAppliesImmediately:(BOOL) flag;
- (void) setInitialValues:(NSDictionary *) values;
- (id) values;

@end

#endif /* _mySTEP_H_NSUserDefaultsController */
