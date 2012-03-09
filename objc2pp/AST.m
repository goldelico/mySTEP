/* part of objc2pp - an obj-c 2 preprocessor */


#import "AST.h"
#include "node.h"

/* parser interface methods */

/// FIXME: can we use the Node's -hash value as the integer id ???
/// FIXME: and use a NSMapTables to map from int back to Node object

Node **nodes;

static int nodecount, nodecapacity;

static Node *get(int node)
{
	if(node <= 0 || node > nodecount)
		return nil;
	return nodes[node-1];	/* nodes start counting at 1 */
}

int leaf(char *type, const char *name)
{ /* create a leaf node - name becomes the value */
	int n;
	if(nodecount >= nodecapacity)
		{ /* (re)alloc */
			if(nodecapacity == 0)
				{ /* first allocation */
					nodecapacity=100;
					nodes=malloc(nodecapacity*sizeof(Node *));
				}
			else
				{
				nodecapacity=2*nodecapacity+10;	/* exponentially increase available capacity */
				nodes=realloc(nodes, nodecapacity*sizeof(Node *));
				}
		}
	nodes[nodecount]=[[Node alloc] initWithType:[NSString stringWithUTF8String:type] number:nodecount+1 value:name?[NSString stringWithUTF8String:name]:nil];	/* create new entry */
	nodecount++;
	return nodecount;	/* returns node index + 1 */
}

int node(char *type, int left, int right)
{ /* create a binary node */
	int n=leaf(type, NULL);
	Node *node = get(n);
	[node setLeft:get(left)];
	[node setRight:get(right)];
	return n;
}

const char *type(int node)
{
	return [[get(node) type] UTF8String];
}

void setType(int node, char *type)
{
	[get(node) setType:[NSString stringWithUTF8String:type]];
}

int left(int node)
{
	return [[get(node) left] number];
}

int right(int node)
{
	return [[get(node) right] number];
}

/* list */

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

/* dictionary */

int dictionary(void)
{
	int s=leaf("dict", NULL);	// dummy...
	Node *n=get(s);
	[n setValue:[NSMutableDictionary dictionaryWithCapacity:10]];
	return s;
}

int lookup(int table, const char *word, char *type, int value)
{ // look up identifier
	NSString *key=[NSString stringWithUTF8String:word];
	int s=[[(NSMutableDictionary *) [get(table) value] objectForKey:key] number];
	if(s == 0 && type != NULL)
		{ // create new entry
			s=leaf(type, NULL);
			if(value)
				[get(s) setValue:[NSNumber numberWithInt:value]];
			[(NSMutableDictionary *) [get(table) value] setObject:get(s) forKey:key];		// create entry
		}
	return s;
}

int value(int node)
{
	return [[get(node) value] intValue];
}

#if OLDCODE
char *keyword(int table, int t)
{ // look up keyword for given type
	int i;
	for(i=0; i<sizeof(symtab)/sizeof(symtab[0]); i++)
		{
		int s=symtab[i];
		while(s)
			{
			if(type(s) == t)
				return name(s);	// type code found - print symbol
			s=next(s);	// go to next symtab node
			}
		}
	return NULL;
}
#endif

@implementation Node 

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with Objective C source into AST and return root node
{
	extern int yyparse();
	extern void scaninit(void);
	extern int rootnode;
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
	return get(rootnode);
}

- (id) initWithType:(NSString *) t number:(int) num value:(id) val;
{
	if((self=[super init]))
		{
		type=[t retain];
		value=[val retain];
		number=num;
		}
	return self;
}

- (void) dealloc
{
	[type release];
	[left release];
	[right release];
	[value release];
	// remove from map table(s)
	[super dealloc];
}

- (int) number
{ // get object number (must be unique and different from 0)
	return number;
}

- (NSString *) type;
{
	return type;
}

- (id) value;
{
	return value;
}

- (Node *) left;
{
	return left;
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

- (Node *) right;
{
	return right;
}

- (void) setParent:(Node *) n;
{
	parent=n;
}

- (void) setLeft:(Node *) n;
{
	[left setParent:nil];
	[left autorelease];
	left=[n retain];
	[left setParent:self];
}

- (void) setRight:(Node *) n;
{
	[right setParent:nil];
	[right autorelease];
	right=[n retain];
	[right setParent:self];
}

- (void) setValue:(id) val;
{
	[value autorelease];
	value=[val retain];
}

- (void) setType:(NSString *) t;
{
	[type autorelease];
	type=[t retain];
}

+ (Node *) get:(int) number
{ // get node for given number
	return get(number);
}

@end

