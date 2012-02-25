/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>

// tree node management wrapper

@interface Node : NSObject 
{ /* internal structure */
	int type;
	char *name;
	int left;
	int right;
	int next;
}

- (id) initWithName:(char *) name type:(int) type;
- (int) type;
- (char *) name;
- (Node *) left;
- (Node *) right;

@end