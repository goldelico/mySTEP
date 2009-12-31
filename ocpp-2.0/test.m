/* comment */
// other comment

@protocol protocol
- (double) gotme;
@end

@interface Object1 <protocol> (category)
{
	int _ivar;
	Object1 *location;
}
@property Object1 *location;
- (oneway void) doSomething:(id) val;

@end

@implementation Object1

@synthesize location;

- (void) awake;
{
	NSLog(@"awake");
	self.location = self;
	NSLog(@"Bill's location: %@", self.location);
}

@end