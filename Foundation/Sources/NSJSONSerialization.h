//
//  NSJSONSerialization.h
//  Foundation
//
//  Created by H. Nikolaus Schaller on 27.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/NSData.h>
#import <Foundation/NSError.h>
#import <Foundation/NSStream.h>

enum _NSJSONWritingOptions
{
	NSJSONWritingPrettyPrinted = (1UL << 0),
};

typedef NSUInteger NSJSONWritingOptions;

enum{
	NSJSONReadingMutableContainers = (1UL << 0),
	NSJSONReadingMutableLeaves = (1UL << 1),
	NSJSONReadingAllowFragments = (1UL << 2)
};

typedef NSUInteger NSJSONReadingOptions;

@interface NSJSONSerialization : NSObject
{

}

+ (NSData *) dataWithJSONObject:(id) obj options:(NSJSONWritingOptions) opt error:(NSError **) error;
+ (BOOL) isValidJSONObject:(id) obj;
+ (id) JSONObjectWithData:(NSData *) data options:(NSJSONReadingOptions) opt error:(NSError **) error;
+ (id) JSONObjectWithStream:(NSInputStream *) stream options:(NSJSONReadingOptions) opt error:(NSError **) error;
+ (NSInteger) writeJSONObject:(id) obj toStream:(NSOutputStream *) stream options:(NSJSONWritingOptions) opt error:(NSError **) error;

@end
