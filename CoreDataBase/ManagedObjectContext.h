//
//  ManagedObjectContext.h
//  CoreDataBase
//
//  Created by H. Nikolaus Schaller on 03.05.13.
//  Copyright 2013 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ManagedObjectEntity;

@interface ManagedObjectContext : NSObject
{

}

+ (ManagedObjectContext *) managedObjectContextForHost:(NSString *) host user:(NSString *) user password:(NSString *) password database:(NSString *) database;

- (id) query:(NSString *) sql;

- (ManagedObjectEntity *) entityForTable:(NSString *) table andPrimaryKey:(NSString *) key;

@end
