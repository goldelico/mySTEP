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
// request substream for #import and #include...
@end

extern BOOL _debug;

@interface Node : NSObject <NSCoding>
{ /* internal structure */
	NSString *type;	// node type
	NSMutableDictionary *attributes;		// e.g. leaf value, keyword code, assigned typedef etc.
	Node /*nonretained*/ *parent;	// parent node
	NSMutableArray *children;	// subnodes
}

+ (Node *) nodeWithContentsOfFile:(NSString *) path;	// unarchive from file
- (BOOL) writeToFile:(NSString *) path;	// archive to file

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with (preprocessed!) Objective C source into AST and return root node

// type should be ordinary alphanum or we can't define the methods for doSelectorByType:
+ (Node *) node:(NSString *) type, ...;
+ (Node *) node:(NSString *) type children:(NSArray *) children;
+ (Node *) leaf:(NSString *) type;	// nil value
+ (Node *) leaf:(NSString *) type value:(NSString *) value;

- (id) attributeForKey:(NSString *) key;	// look up entry with key in dictionary
- (void) setAttribute:(id) value forKey:(NSString *) key;
- (NSDictionary *) attributes;

- (id) initWithType:(NSString *) type;
- (NSString *) type;
- (void) setType:(NSString *) type;
- (id) value;	// direct access to the @"value" attribute
- (void) setValue:(id) val;
- (NSArray *) children;
- (unsigned) childrenCount;
- (void) addChild:(Node *) n;
- (void) insertChild:(Node *) n atIndex:(unsigned) idx;
- (void) removeChild:(Node *) n;
- (void) removeChildAtIndex:(unsigned) idx;
- (Node *) firstChild;
- (Node *) lastChild;
- (void) removeLastChild;
- (Node *) childAtIndex:(unsigned) idx;
- (NSEnumerator *) childrenEnumerator;
- (void) replaceBy:(Node *) other;	// replace in parent's children list (if other = nil, we are removed from our parent)
- (void) treeWalk:(NSString *) prefix;
- (void) treeWalk:(NSString *) prefix withObject:(id) object;
- (Node *) parent;
- (Node *) parentWithType:(NSString *) type;	// search parent of type t (nil if not found)
- (void) _setParent:(Node *) n;
- (Node *) root;

- (NSString *) description;	// create an XML representation
- (void) inspect;	// open in GUI

@end

/* for lex and yacc */

#define YYSTYPE Node *

// EOF
