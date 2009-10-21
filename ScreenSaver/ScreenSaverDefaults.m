//
//  ScreenSaverDefaults.m
//  ScreenSaver
//
//  Created by H. Nikolaus Schaller on 20.10.09.
//  Copyright 2009 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import "ScreenSaverDefaults.h"


@implementation ScreenSaverDefaults

+ (id) defaultsForModuleWithName:(NSString *) name;
{
	return [super standardUserDefaults];
}

@end
