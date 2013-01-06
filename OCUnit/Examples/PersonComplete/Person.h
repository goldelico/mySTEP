//
//  Person.h
//  TestPerson
//
//  Created by Ph(i)Nk 0 on Tue May 07 2002.
//  Copyright (c) 2001 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Person : NSObject
{
	NSString *firstName;
	NSString *lastName;
}

- (NSString *) firstName;
- (void) setFirstName:(NSString *) aName;

- (NSString *) lastName;
- (void) setLastName:(NSString *) aName;

- (NSString *) fullName;

@end
