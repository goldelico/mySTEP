/* part of objc2pp - an obj-c 2 preprocessor */

#import <Cocoa/Cocoa.h>

// Abstract Syntax Tree for Objective C

@protocol Notification
// report:
// error
// expression
// statement
// external_declaration
// translation_unit
@end

@interface Node : NSObject
{ /* internal structure */
	NSString *type;	// node type
	int number;		// object number
	id value;		// leaf value (we could re-use left/right)
	Node *parent;	// parent node
	Node *left;		// left tree
	Node *right;	// right tree
}

- (id) initWithType:(NSString *) type number:(int) num value:(id) value;
- (NSString *) type;
- (void) setType:(NSString *) type;
- (int) number;
- (id) value;	// value of leaf nodes, e.g. identifier, numerical or string constant
- (void) setValue:(id) val;
- (Node *) left;
- (void) setLeft:(Node *) n;
- (Node *) right;
- (void) setRight:(Node *) n;
- (Node *) parent;
- (Node *) parentWithType:(NSString *) type;	// search parent of type t (nil if not found)
- (Node *) root;

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with (preprocessed!) Objective C source into AST and return root node

@end

// here we can either define generic nodes with type
// or real subclasses (which would simplify writing tree processing algorithms
// we could also define subclasses and use/replace the isa pointer as the 'type'