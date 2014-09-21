//
//  main.h
//

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

void searchData(id obj)
{
	if([obj isKindOfClass:[NSData class]])
		NSLog(@"%@", obj);
	else if([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSDictionary class]])
			{
				NSEnumerator *e=[obj objectEnumerator];
				while((obj=[e nextObject]))
					searchData(obj);
			}
}

void analyse(NSAttributedString *s)
{
	NSPropertyListFormat format;
	NSString *error=nil;
	NSData *d;
	NSLog(@"string=%@", s);
	d=[NSKeyedArchiver archivedDataWithRootObject:s];
	id obj=[NSPropertyListSerialization propertyListFromData:d mutabilityOption:NSPropertyListImmutable format:&format errorDescription:&error];
    if(!obj)
        NSLog(@"error: %@", error);
	searchData(obj);
}

void test(void)
{
	NSMutableAttributedString *s=[[NSMutableAttributedString alloc] initWithString:@"string"];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12], NSFontAttributeName, nil] range:NSMakeRange(0, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14], NSFontAttributeName, nil] range:NSMakeRange(3, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14], NSFontAttributeName, nil] range:NSMakeRange(2, 4)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14], NSFontAttributeName, nil] range:NSMakeRange(1, 1)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12], NSFontAttributeName, nil] range:NSMakeRange(0, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:12], NSFontAttributeName, nil] range:NSMakeRange(0, 5)];
	analyse(s);
	[[s mutableString] setString:@"a much longer string"];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14], NSFontAttributeName, nil] range:NSMakeRange(5, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:16], NSFontAttributeName, nil] range:NSMakeRange(8, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:14], NSFontAttributeName, nil] range:NSMakeRange(11, 3)];
	analyse(s);
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:18], NSFontAttributeName, nil] range:NSMakeRange(11, 3)];
	analyse(s);
	[[s mutableString] setString:@"0123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789012345678901234567890123456789"];
	[s setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[NSFont systemFontOfSize:18], NSFontAttributeName, nil] range:NSMakeRange(11, 3)];
	analyse(s);
	[s release];
}

int main(int argc, const char *argv[])
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];
	NSLog(@"started");
	test();
}
