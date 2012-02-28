/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>

// tree node management wrapper

@interface Node : NSObject 
{ /* internal structure */
	int type;
	const char *name;
	Node *left;
	Node *right;
	Node *next;
}

- (id) initWithName:(const char *) name type:(int) type;
- (int) type;
- (const char *) name;
- (Node *) left;
- (Node *) right;
- (void) setLeft:(Node *) n;
- (void) setRight:(Node *) n;
- (void) setType:(Class) type;

@end

// here we can either define generic nodes with type
// or real subclasses (which would simplify writing tree processing algorithms
// we could also define subclasses and use/replace the isa pointer as the 'type'