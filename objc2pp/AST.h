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
	int type;
	int number;
	NSString *name;
	Node *left;
	Node *right;
	Node *next;
}

- (id) initWithName:(NSString *) name type:(int) t number:(int) num;
- (int) type;
- (NSString *) name;
- (Node *) left;
- (Node *) right;
- (void) setLeft:(Node *) n;
- (void) setRight:(Node *) n;
- (void) setType:(int) type;

// define some delegate that receives callbacks e.g. after each expression, statement, method/function, class definition, at end of file and on errors

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with Objective C source into AST and return root node

@end

// here we can either define generic nodes with type
// or real subclasses (which would simplify writing tree processing algorithms
// we could also define subclasses and use/replace the isa pointer as the 'type'