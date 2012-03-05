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

int leaf(int type, const char *name)
{ /* create a leaf node */
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
	nodes[nodecount]=[[Node alloc] initWithName:name?[NSString stringWithUTF8String:name]:@"" type:type number:nodecount+1];	/* create new entry */
	nodecount++;
	return nodecount;	/* returns node index + 1 */
}

int node(int type, int left, int right)
{ /* create a binary node */
	int n=leaf(type, NULL);
	Node *node = get(n);
	[node setLeft:get(left)];
	[node setRight:get(right)];
	return n;
}

int type(int node)
{
	return [get(node) type];
}

const char *name(int node)
{
	return [[get(node) name] UTF8String];
}

int left(int node)
{
	return [[get(node) left] number];
}

int right(int node)
{
	return [[get(node) right] number];
}

void process(int node)
{ // called for each declaration
	[get(node) process];
}

/* list */

int list(void)
{ // create a list object
	return leaf(0, NULL);	// dummy...
}

int first(int list)
{ // get first entry of a list
	return get(list)->next;
}

int next(int node)
{
	return get(node)->next;
}

/* static? */ void setNext(int node, int next)
{
	get(node)->next=next;
}

int nth(int list, int n)
{ // get n-th entry of a list
	int r=first(list);
	while(n-- > 0)
		r=next(r);
	return r;
}

int count(int list)
{ // count elements in a list
	int r=first(list);
	int c=0;
	while(r != 0)
		c++, r=next(r);
	return c;	
}

int push(int lifo, int node)
{ // add to lifo (first entry)
	setNext(node, first(lifo));	// attach current first object
	setNext(lifo, node);	// make it the new first
}

int pop(int lifo)
{ // pop first entry
	int r=first(lifo);
	if(r)
		setNext(lifo, next(r));	// remove from LIFO
	return r;
}

/* dictionary */

int dictionary(void)
{
	int s=leaf(0, NULL);	// dummy...
	Node *n=get(s);
	[n setRight:(id) [NSMutableDictionary dictionaryWithCapacity:10]];
	return s;
}

int lookup(int table, const char *word, int type)
{ // look up identifier
	NSString *key=[NSString stringWithUTF8String:word];
	int s=[[(NSMutableDictionary *) [get(table) right] objectForKey:key] number];
	if(s == 0 && type > 0)
		{ // create new entry
			s=leaf(type, word);
			[(NSMutableDictionary *) [get(table) right] setObject:get(s) forKey:key];		// create entry
		}
	return s;
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
	scaninit();
	yyparse();
	return get(rootnode);
}

- (id) initWithName:(NSString *) n type:(int) t number:(int) num
{
	if((self=[super init]))
		{
		if(n)
			name=[n retain];
		type=t;
		number=num;
		}
	return self;
}

- (void) dealloc
{
	[left release];
	[right release];
	[name release];
	// remove from map table(s)
	[super dealloc];
}

- (int) number
{ // get object number (must be unique and different from 0)
	return number;
}

- (int) type;
{
	return type;
}

- (NSString *) name;
{
	return name;
}

- (Node *) left;
{
	return left;
}

- (Node *) right;
{
	return right;
}

- (void) setLeft:(Node *) n;
{
	[left autorelease];
	left=[n retain];
}

- (void) setRight:(Node *) n;
{
	[right autorelease];
	right=[n retain];
}

- (void) setType:(int) type;
{
	
}

+ (Node *) get:(int) number
{ // get node for given number
	return get(number);
}

@end
