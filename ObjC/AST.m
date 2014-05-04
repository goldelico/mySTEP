/* part of objc2pp - an obj-c 2 preprocessor */


#import <ObjCKit/AST.h>

BOOL _debug;
int yydebug;

@implementation Node

+ (Node *) parse:(NSInputStream *) stream delegate:(id <Notification>) delegate;	// parse stream with Objective C source into AST and return root node
{
	extern int yyparse();
	extern void scaninit(void);
	extern Node *rootnode;
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

