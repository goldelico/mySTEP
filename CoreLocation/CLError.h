//
//  CLError.h
//  CoreLocation
//
//  Created by H. Nikolaus Schaller on 03.10.10.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum _CLError
{
	kCLErrorLocationUnknown = 0,
	kCLErrorDenied,
} CLError;

extern NSString *const kCLErrorDomain;
