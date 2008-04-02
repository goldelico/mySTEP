//
//  UIHardware.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Thu Mar 06 2008.
//  Copyright (c) 2008 Golden Delicious Computers GmbH&Co KG. All rights reserved.
//
//  Licenced under LGPL
//

#import <Foundation/Foundation.h>

@interface UIHardware : NSObject

+ (CGRect) fullScreenApplicationContentRect;
+ (int) deviceOrientation:(BOOL) flag;

@end
