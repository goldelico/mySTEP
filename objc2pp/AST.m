/* part of objc2pp - an obj-c 2 preprocessor */


#import <ObjCKit/AST.h>

#if OLD

#include "node.h"

/* parser interface methods */

Node **nodes;

static int nodecapacity;

static Node *get(int n)
{
	if(n <= 0 || n > nodecapacity)
		return nil;
	return nodes[n];	/* nodes start counting at 1 */
}

int leaf(char *type, const char *value)
{ /* create a leaf node - name becomes the value */
	int n;
	Node *node=[[Node alloc] initWithType:[NSString stringWithUTF8String:type] value:value?[NSString stringWithUTF8String:value]:nil];	/* create new entry */
	n=[node number];	// unique number
	if(n >= nodecapacity)
		{ /* (re)alloc */
			if(nodecapacity == 0)
				{ /* first allocation */
					nodecapacity=100;
					nodes=calloc(nodecapacity*sizeof(Node *), 1);
				}
			else
				{
					int old=nodecapacity;
					nodecapacity=2*nodecapacity+10;	/* exponentially increase available capacity */
					nodes=realloc(nodes, nodecapacity*sizeof(Node *));
				memset(&nodes[old], 0, (nodecapacity-old)*sizeof(Node *));
				}
		}
	nodes[n]=node;	/* store entry */
	return n;	/* returns node index */
}

int node(char *type, ...)	// create a node with optional child nodes (0-terminated list)
{
	int n=leaf(type, NULL);
	int cn;
	Node *node = get(n);
	va_list va;
    va_start(va, type);
    while (cn = va_arg(va, int))
		[node addChild:get(cn)];	// add children
	va_end(va);
	return n;
}

int append(int list, int node)	// append a node as child
{
	[get(list) addChild:get(node)];
}

void removelast(int list)
{
	[get(list) removeLastChild];
}

const char *type(int node)
{
	NSString *t=[get(node) type];
	if(!t) return "<null>";
	return [t UTF8String];
}

void setType(int node, char *type)
{
	[get(node) setType:[NSString stringWithUTF8String:type]];
}

int value(int node)
{
	return [[get(node) value] intValue];
}

const char *stringValue(int node)
{
	NSString *val=[get(node) value];
	if(!val) return "<nil>";
	return [val UTF8String];
}

void setStringValue(int node, char *value)
{
	[get(node) setValue:[NSString stringWithUTF8String:value]];
}

/* list */

#if 0
int list(void)
{ // create a list object
	int s=leaf("list", NULL);	// dummy...
	Node *n=get(s);
	[n setValue:[NSMutableArray arrayWithCapacity:10]];
	return s;
}

int first(int list)
{ // get first entry of a list
	NSArray *a=[get(list) value];
	if([a count] == 0)
		return 0;
	return [[a objectAtIndex:0] number];	// first entry
}

int nth(int list, int n)
{ // get n-th entry of a list
	NSArray *a=[get(list) value];
	if(n  < 0 || n >= [a count])
		return 0;
	return [[a objectAtIndex:n] number];	// n-th entry
}

int last(int list)
{ // count elements in a list
	return [[[get(list) value] lastObject] number];
}

int count(int list)
{ // count elements in a list
	return [[get(list) value] count];
}

void push(int lifo, int node)
{ // add to lifo
	[[get(lifo) value] addObject:get(node)];
}

void pop(int lifo)
{ // pop last entry
	[[get(lifo) value] removeLastObject];
}
#endif

int last(int list)	// get last of a list
{
	return [[get(list) lastChild] number];	
}

int nth(int list, int n)
{ // get n-th entry of a list
	return [[get(list) childAtIndex:n] number];
}

int count(int list)
{ // count elements in a list
	return [get(list) childrenCount];
}

/* dictionary */

int dictionary(void)
{
	int s=leaf("$dict$", NULL);	// dictionary object
	[get(s) setValue:[NSMutableDictionary dictionaryWithCapacity:10]];
	return s;
}

int lookup(int table, const char *word, char *type, int value)
{ // look up identifier
	NSString *key=[NSString stringWithUTF8String:word];
	NSMutableDictionary *dict=[get(table) value];
	int s=[[dict objectForKey:key] number];
	if(s == 0 && type != NULL)
		{ // create new entry
			s=leaf(type, NULL);
			if(value)
				[get(s) setValue:[NSNumber numberWithInt:value]];
			[dict setObject:get(s) forKey:key];		// create entry
		}
	return s;
}

void setkeyval(int dictionary, const char *key, int value)
{
	
}

#endif

@implementation Node 

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with Objective C source into AST and return root node
{
	extern int yyparse();
	extern void scaninit(void);
	extern Node *rootnode;
#if 0
	extern int yydebug;
	yydebug=1;
#endif
	static BOOL busy=NO;
	NSAssert(!busy, @"parser is busy");
	busy=YES;
	// setup stream and delegate
	scaninit();
	yyparse();
	busy=NO;
	return rootnode;
}

+ (Node *) node:(NSString *) type, ...;
{
	Node *node=[[[self alloc] initWithType:type] autorelease];
	va_list va;
	Node *cn;
    va_start(va, type);
    while (cn = va_arg(va, Node *))
		[node addChild:cn];	// add children
	va_end(va);
	return node;
}

+ (Node *) node:(NSString *) type children:(NSArray *) children;
{
	Node *n=[[self alloc] initWithType:type];
	n->children=[children mutableCopy];
	return [n autorelease];	
}

+ (Node *) leaf:(NSString *) type;
{
	return [[[self alloc] initWithType:type] autorelease];
}

+ (Node *) leaf:(NSString *) type value:(NSString *) value;
{
	Node *n=[[[self alloc] initWithType:type] autorelease];
	if(value)
		[n setValue:value];
	return n;
}

+ (Node *) nodeWithContentsOfFile:(NSString *) path;
{ // unarchive from file
	id obj=nil;
#if 1
	NSLog(@"unarchive %@", path);
#endif
	NS_DURING
		obj=[NSUnarchiver unarchiveObjectWithFile:path];
	NS_HANDLER
	NS_ENDHANDLER
	if([obj isKindOfClass:self])
		return obj;	// did properly unarchive
	return nil;	// unarchiving error
}

- (BOOL) writeToFile:(NSString *) path;
{ // archive to file
#if 1
	NSLog(@"archive to %@", path);
#endif
	return [NSArchiver archiveRootObject:self toFile:path];
}

- (id) attributeForKey:(NSString *) key
{ // look up identifier
	return [attributes objectForKey:key];
}

- (void) setAttribute:(id) value forKey:(NSString *) key;
{
	if(!value)
		[attributes removeObjectForKey:key];
	else if(attributes)
		[attributes setObject:value forKey:key];
	else
		attributes=[[NSMutableDictionary alloc] initWithObjects:&value forKeys:&key count:1];
}

- (id) initWithType:(NSString *) t;
{
	if((self=[super init]))
		{
		type=[t retain];
		}
	return self;
}

- (id) copyWithZone:(NSZone *) zone
{
	Node *c=[Node alloc];
	c->type=[type copyWithZone:zone];
	c->attributes=[attributes copyWithZone:zone];	// NOTE: this is not a deep copy!
	c->children=[children copyWithZone:zone];	// NOTE: this is not a deep copy!
	return c;
}

- (Node *) deepCopy
{
	Node *c=[Node alloc];
	c->type=[type copy];
	if(attributes)
		{
		NSEnumerator *e=[attributes keyEnumerator];
		NSString *key;
		c->attributes=[[NSMutableDictionary alloc] initWithCapacity:[attributes count]];
		while((key=[e nextObject]))
			// we need a category of NSObject that defines deepCopy as the same as copy so that we can deepCopy ordinary objects
			[c->attributes setObject:[[[attributes objectForKey:key] deepCopy] autorelease] forKey:key];
		}
	if(children)
		{
		NSEnumerator *e=[children objectEnumerator];
		Node *child;
		c->children=[[NSMutableArray alloc] initWithCapacity:[children count]];
		while((child=[e nextObject]))
			// we need a category of NSObject that defines deepCopy as the same as copy so that we can deepCopy ordinary objects
			[c->children addObject:[[child deepCopy] autorelease]];
		}
	return c;
}

- (NSString *) description
{
	NSAutoreleasePool *arp=[NSAutoreleasePool new];	// we may collect quite a lot of temporary NSStrings
	NSMutableString *s;
	NSEnumerator *e;
	Node *c;
	NSMutableString *attribs=[NSMutableString string];
	NSString *key;
	e=[attributes keyEnumerator];
	while((key=[e nextObject]))
		{
		if(![key isEqualToString:@"value"])
			[attribs appendFormat:@" \"%@\"=\"%@\"", key, [[attributes objectForKey:key] description]];
		}
	if([self childrenCount] == 0)
		{
		if([self value])
			s=[NSMutableString stringWithFormat:@"<%@%@>%@</%@>\n", type, attribs, [self value], type];
		else
			s=[NSMutableString stringWithFormat:@"<%@%@/>\n", attribs, type];
		}
	else
		{
		s=[NSMutableString stringWithFormat:@"<%@%@>\n", type, attribs];
		e=[children objectEnumerator];
		while((c=[e nextObject]))
			{
			NSEnumerator *cd=[[[c description] componentsSeparatedByString:@"\n"] objectEnumerator];
			NSString *cdc;
			while((cdc=[cd nextObject]))
				if([cdc length] > 0)
					[s appendFormat:@"  %@\n", cdc];	// indent each line of the (sub) component
			}
		[s appendFormat:@"</%@>\n", type];
		}
	[s retain];
	[arp release];
	return [s autorelease];
}


- (void) dealloc
{
	[type release];
	[attributes release];
	[children release];
	[super dealloc];
}

- (NSString *) type;
{
	return type;
}

- (id) value;
{
	return [attributes objectForKey:@"value"];
}

- (Node *) parent;
{
	return parent;
}

- (Node *) parentWithType:(NSString *) t;
{
	while(self && ![type isEqualToString:t])
		self=parent;
	return self;	// has type or is nil
}

- (Node *) root;
{
	while(parent)
		self=parent;
	return self;
}

- (void) _setParent:(Node *) n;
{
	parent=n;
}

- (void) setValue:(id) val;
{
	[self setAttribute:val forKey:@"value"];
}

- (void) setType:(NSString *) t;
{
	[type autorelease];
	type=[t retain];
}

- (NSArray *) children
{
	return children;
}

- (void) insertChild:(Node *)n atIndex:(unsigned)idx
{
	if(!children)
		children=[[NSMutableArray alloc] initWithCapacity:10];
	[children insertObject:n atIndex:idx];
}

- (void) addChild:(Node *)n
{
	if(children)
		[children addObject:n];
	else
		children=[[NSMutableArray alloc] initWithObjects:&n count:1];
}

- (void) removeChild:(Node *)n
{
	[children removeObject:n];
}

- (void) removeChildAtIndex:(unsigned)idx
{
	[children removeObjectAtIndex:idx];
}

- (Node *) lastChild
{
	return [children lastObject];
}

- (void) removeLastChild
{
	[children removeLastObject];
}

- (unsigned) childrenCount;
{
	return [children count];
}

- (Node *) childAtIndex:(unsigned) idx;
{
	return [children objectAtIndex:idx];
}

- (NSEnumerator *) childrenEnumerator;
{
	return [children objectEnumerator];
}

- (void) replaceBy:(Node *) other;	// replace in parent's children list
{
	unsigned idx=[(NSMutableArray *) [parent children] indexOfObject:self];
	if(idx == NSNotFound)
		return;
	[self retain];
	if(other)
		[(NSMutableArray *) [parent children] replaceObjectAtIndex:idx withObject:other];
	else
		[parent removeChildAtIndex:idx];	// remove me from parent
	[self release];
}

- (SEL) selectorForType:(NSString *) prefix;
{
	SEL sel=NSSelectorFromString([prefix stringByAppendingString:type]);
	if(![self respondsToSelector:sel])
		sel=NSSelectorFromString(prefix);	// default selector
	return sel;
}

- (void) doSelectorByType:(NSString *) prefix;	// call tag specific (or general) method
{
	[self performSelector:[self selectorForType:prefix]];
}

- (void) doSelectorByType:(NSString *) prefix withObject:(id) obj;	// call tag specific (or general) method
{
	[self performSelector:[self selectorForType:prefix] withObject:obj];
}

- (void) performSelectorForAllChildren:(SEL) aSelector;
{
	[children makeObjectsPerformSelector:aSelector];
}

- (void) performSelectorForAllChildren:(SEL) aSelector withObject:(id) object;
{
	[children makeObjectsPerformSelector:aSelector withObject:object];
}

@end

