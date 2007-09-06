/* comment */
// other comment

@protocol protocol
- (double) gotme;
@end

@interface Object1 <protocol> (category)
{
	int _ivar;
}
- (oneway void) doSomething:(id) val;

@end

@implementation Object1

- (void) awake;
{
	NSLog(@"awake");
}

@end