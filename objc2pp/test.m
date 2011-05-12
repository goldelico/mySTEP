/* comment */
// other comment

@protocol protocol
@required
	- (double) gotme;
@optional
	- (double) didhide;
@end

@interface Object1 <protocol> (category)
{
	int _ivar;
	Object1 *location;
}
@property Object1 *location;

- (oneway void) doSomething:(id) val;
- (void) for:(Object1 <protocol> *) val;

@end

@implementation Object1

@synthesize location;

- (void) awake;
{
	NSLog(@"awake");
	self.location = self;
	self.location.location = self;
	NSLog(@"Bill's location: %@", self.location);
	@try {
		[self for:self];		
	}
	@catch (NSException * e) {
		NSLog(@"%@", e);
	}
	@finally {
		NSLog(@"finally cleanup");
	}
}

// -gotme is missing, -for: is missing
@end