//
//  CLExtensions.h
//  myNavigator
//
//  Created by H. Nikolaus Schaller on 08.11.11.
//  Copyright 2011 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#ifndef __mySTEP__

#ifndef __CLExtenstions__
#define __CLExtenstions__

// provides classes n/a on Mac OS X (10.6)

#import <MapKit/CLHeading.h>
#import <MapKit/CLPlacemark.h>
#import <MapKit/CLGeocoder.h>
#import <MapKit/CLRegion.h>

@interface NSBlockHandler : NSObject
{
	id delegate;
	SEL action;
}

+ (NSBlockHandler *) handlerWithDelegate:(id) delegate action:(SEL) action;
- (id) initWithDelegate:(id) delegate action:(SEL) action;
- (id) performSelector;
- (id) performSelectorWithObject:(id) obj;
- (id) performSelectorWithObject:(id) obj1 withObject:(id) obj2;

@end

#endif

#endif