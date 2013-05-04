//
//  ManagedObject.h
//  CoreDataBase
//
//  Created by H. Nikolaus Schaller on 03.05.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ManagedObject : NSObject
{

}

- (void) fetch;
- (void) flush;

// unique id (not necessarily universal unique!)

- (NSString *) uid;
- (void) setUid:(NSString *) uid;

- (id) valueForKey:(NSString *) key;
- (void) setValue:(id) value forKey:(NSString *) key;

@end
