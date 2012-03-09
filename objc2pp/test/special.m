// very special things

@interface MyClass

static int var;

@end

@implementation MyClass

- (oneway byref id) for:(int) x do:(int) y;
{
	typedef char *id;
	id here="string";
	struct {
		int id;
	} BOOL;
	BOOL k;
	k.id=5;
}

@end
