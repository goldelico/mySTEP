//
//  CRTag.h
//  CoreRFID
//
//  Created by H. Nikolaus Schaller on 09.10.10.
//  Copyright 2010 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CRTag : NSObject <NSCopying, NSCoding>
{
	NSString *tagUID;
}

- (NSString *) tagUID;
- (NSString *) description;

- (NSData *) readAt:(NSUInteger) block;
- (BOOL) write:(NSData *) data at:(NSUInteger) block;

@end
