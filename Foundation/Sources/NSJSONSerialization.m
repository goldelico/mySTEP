//
//  NSJSONSerialization.m
//  Foundation
//
//  Created by H. Nikolaus Schaller on 27.03.12.
//  Copyright 2012 Golden Delicious Computers GmbH&Co. KG. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSPrivate.h"


@implementation NSJSONSerialization

#if 0	// debugging
+ (void) initialize
{
	NSError *error;
	NSData *data;
	NSDictionary *root;
	NSString *json=@"{\n"
	@"\"name\":   \"Extended 45\",\n"
	@"\"eman\":   true,\n"
	@"\"enum\":   45,\n"
	@"\"requirements\": {\n"
	@"\"window\": {\n"
	@"\"width\":  480\n"
	@"}\n"
	@"}\n"
	@"}\n";
	NSLog(@"JSON1: %@", json);
	data=[json dataUsingEncoding:NSUTF8StringEncoding];
	NSLog(@"JSON2: %@", data);
	root=[NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	NSLog(@"JSON3: %@ - %@", root, error);
	abort();
}
#endif

+ (NSData *) dataWithJSONObject:(id) obj options:(NSJSONWritingOptions) opt error:(NSError **) error;
{
	NSPropertyListFormat fmt=(opt&NSJSONWritingPrettyPrinted)?NSPropertyListJSONPrettyPrintedFormat:NSPropertyListJSONFormat;	// make dependent on writing options
	NSString *err=nil;
	NSData *data=[NSPropertyListSerialization dataFromPropertyList:obj format:fmt errorDescription:&err];
	if(!data && error)
		*error=[NSError errorWithDomain:err code:0 userInfo:nil];
	return data;
}

+ (BOOL) isValidJSONObject:(id) obj;
{
	return [NSPropertyListSerialization propertyList:obj isValidForFormat:NSPropertyListJSONFormat];
}

+ (id) JSONObjectWithData:(NSData *) data options:(NSJSONReadingOptions) opt error:(NSError **) error;
{
	NSPropertyListFormat fmt;	// make dependent on writing options
	NSPropertyListMutabilityOptions opts=0;	// most likely we also have to specify that we want to see JSON and not old ASCII style PList
	NSString *err=nil;
	id plist;
	NS_TIME_START(VAR);
	plist=[NSPropertyListSerialization propertyListFromData:data mutabilityOption:opts format:&fmt errorDescription:&err];
	if(error)
		*error=err?[NSError errorWithDomain:err code:0 userInfo:nil]:nil;	// wasn't able to read
	// silently ignore if not JSONFormat but detectable, e.g. XML or binary PList
	NS_TIME_END(VAR, "JSONObjectWithData");
	return plist;
}

+ (id) JSONObjectWithStream:(NSInputStream *) stream options:(NSJSONReadingOptions) opt error:(NSError **) error;
{
	// read stream to data and convert
	// or use new stream based PListSerialization methods
	return NIMP;
}

+ (NSInteger) writeJSONObject:(id) obj toStream:(NSOutputStream *) stream options:(NSJSONWritingOptions) opt error:(NSError **) error;
{
	NSData *data=[self dataWithJSONObject:obj options:opt error:error];
	NSInteger r;
	if(!data)
		return 0;	// nothing can be written
	r=[stream write:[data bytes] maxLength:[data length]];
	if(r < 0)
		{
		if(error)
			*error=[stream streamError];
		return 0;
		}
	return r;
}

@end
