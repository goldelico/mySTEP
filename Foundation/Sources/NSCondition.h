/*
    NSCondition.h
    Foundation

    Created by H. Nikolaus Schaller on 05.11.07.
    Copyright 2007 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
 
    Author:	Fabian Spillner <fabian.spillner@gmail.com>
    Date:	22. April 2008 - aligned with 10.5
 
    This file is part of the mySTEP Library and is provided
    under the terms of the GNU Library General Public License.
*/

#import <Foundation/NSObject.h>


@interface NSCondition : NSObject
{

}

- (void) broadcast;
- (NSString *) name;
- (void) setName:(NSString *) newName;
- (void) signal;
- (void) wait;
- (BOOL) waitUntilDate:(NSDate *) limit;

@end
