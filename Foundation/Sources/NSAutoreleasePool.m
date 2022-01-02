/* 
 NSAutoreleasePool.m

 Implementation of auto release pool for delayed disposal.

 Copyright (C) 1995, 1996, 1997 Free Software Foundation, Inc.

 Author:  Andrew Kachites McCallum <mccallum@gnu.ai.mit.edu>
 Date:	January 1995

 This file is part of the mySTEP Library and is provided
 under the terms of the GNU Library General Public License.
 */

#include <limits.h>

#import <Foundation/NSAutoreleasePool.h>
#import <Foundation/NSException.h>
#import <Foundation/NSThread.h>

#define INITIAL_POOL_SIZE 32	// size of the first _released array.

// Each pool holds it's objects to be 
// released in a linked-list of these
// structures.

struct autorelease_array_list 
{
	struct autorelease_array_list *next;
	unsigned size;
	unsigned count;
	id objects[0];
};

// When `NO', autoreleased objects are not
// actually recorded in an NSAutoreleasePool,
// and are not sent a `release' message.

static BOOL __autoreleaseEnabled = YES;

// disable for debugging

static BOOL __enableCache = NO;

// When the _released_count of a pool gets over
// this value, we raise an exception.  This can
// be adjusted with +setPoolCountThreshhold
// set a breakpoint on +[NSException raise:]

static unsigned __poolCountThreshold = UINT_MAX;

// access to thread variables belonging to NSAutoreleasePool.

#define CURRENT_THREAD ((NSThread*)objc_thread_get_data())
#define THREAD_VARS (&(CURRENT_THREAD->_autorelease_vars))

// Functions for managing a per-thread cache of
// NSAutoreleasedPool's already alloc'ed.  The
// cache is kept in the autorelease_thread_var
// structure, which is an ivar of NSThread

static inline void init_pool_cache(struct autorelease_thread_vars *tv)
{
	tv->pool_cache_size = 32;
	tv->pool_cache_count = 0;
	tv->thread_in_dealloc = NO;
	OBJC_MALLOC (tv->pool_cache, id, tv->pool_cache_size);
}

static inline void push_pool_to_cache(struct autorelease_thread_vars *tv, NSAutoreleasePool *p)
{
#if 0
	fprintf(stderr, "ARP %p: push_pool_to_cache tv=%p cache=%d\n", p, tv, tv->pool_cache_count);
#endif
	if (!tv->pool_cache)
		init_pool_cache (tv);
	else if (tv->pool_cache_count == tv->pool_cache_size)
		{
		tv->pool_cache_size *= 2;
#if 0
		fprintf(stderr, "ARP %p: tv=%p cache resized=%d\n", p, tv, tv->pool_cache_count);
#endif
		OBJC_REALLOC (tv->pool_cache, id, tv->pool_cache_size);
		}

	tv->pool_cache[tv->pool_cache_count++] = p;
}

static inline NSAutoreleasePool *pop_pool_from_cache(struct autorelease_thread_vars *tv)
{
#if 0
	fprintf(stderr, "ARP %p: pop_pool_from_cache tv=%p cache=%d\n", tv->pool_cache[tv->pool_cache_count-1], tv, tv->pool_cache_count);
#endif
	return tv->pool_cache[--(tv->pool_cache_count)];
}

@implementation NSAutoreleasePool

+ (void) initialize
{
#if 0
	fprintf(stderr, "ARP +%p: +initialize class=%s\n", self, class_getName(self));
	fprintf(stderr, "ARP: +class=%p class=%s\n", [NSAutoreleasePool class], class_getName([NSAutoreleasePool class]));
#endif
	if (self == [NSAutoreleasePool class])
		{
		NSThread *mt=[NSThread new];
#if 0
		fprintf(stderr, "ARP: main thread %p\n", mt);
		fprintf(stderr, "  threadvars %p\n", &mt->_autorelease_vars);
		fprintf(stderr, "  cache count %d\n", (&mt->_autorelease_vars)->pool_cache_count);
#endif
		objc_thread_set_data(mt);	// configure the main thread
#if 0
		fprintf(stderr, "ARP: current thread %p\n", objc_thread_get_data());
#endif
		}
}

+ (id) allocWithZone:(NSZone *) z
{
	id arp;
	struct autorelease_thread_vars *tv = THREAD_VARS;
#if 0
	fprintf(stderr, "ARP +%p: +allocWithZone tv=%p\n", self, tv);
	fprintf(stderr, "  threadvars %p\n", tv);
	fprintf(stderr, "  cache count %d\n", tv->pool_cache_count);
#endif

	// if an existing autorelease pool is available return it
	// instead of allocating a new

	if (tv && tv->pool_cache_count)
		return pop_pool_from_cache(tv);

	arp=NSAllocateObject(self, 0, z);
#if 0
	fprintf(stderr, "ARP %p: new alloc tv=%p cache=%d\n", arp, tv, tv->pool_cache_count);
#endif
	return arp;
}

+ (void) showPools;
{ // Displays the state of the current thread's autorelease pool stack to stderr
	NIMP;
}

// this are old non-Cocoa methods!
// they come from https://www.nextop.de/NeXTstep_3.3_Developer_Documentation/Foundation/Classes/NSAutoreleasePool.htmld/index.html

+ (void) enableRelease:(BOOL)enable			{ __autoreleaseEnabled = enable; }
+ (void) setPoolCountThreshhold:(unsigned)c	{ __poolCountThreshold = c; }
+ (void) enableDoubleReleaseCheck:(BOOL)en	{ NIMP; }

/* standard methods */
#if 0
- (oneway void) release
{
	fprintf(stderr, "ARP %p: -release\n", self);
	[super release];
}
#endif

- (NSString *) description; { return [NSString stringWithFormat:@"%p %@ released:%u", self, NSStringFromClass([self class]), _released_count]; }

- (id) init
{
	struct autorelease_thread_vars *tv;

	if (!_released_head)
		{ // Allocate the array that will be the new head of the list of arrays.
			_released = (struct autorelease_array_list*)
			objc_malloc (sizeof(struct autorelease_array_list) +
						 (INITIAL_POOL_SIZE * sizeof(id)));
			// Initially there is no NEXT array in the list, so NEXT == NULL.
			_released->next = NULL;
			_released->size = INITIAL_POOL_SIZE;
			_released->count = 0;
			_released_head = _released;
		}
	else
		{ // Already initialized; (it came from autorelease_pool_cache)
		  // we don't have to allocate new array list memory.
			_released = _released_head;
			_released->count = 0;
		}

	_released_count = 0;	// Pool is initially empty

	tv = THREAD_VARS;
	_child = nil;
	if((_parent = tv->current_pool))	// Install self as current pool
		tv->current_pool->_child = self;	// make us a child of the current_pool
	tv->current_pool = self;
#if 0
	fprintf(stderr, "ARP %p: init\n", self);
#endif
	return self;
}

NSAutoreleasePool *__currentAutoreleasePool(void) { return THREAD_VARS->current_pool; }

+ (void) addObject:(id) anObj
{
	NSAutoreleasePool *pool = THREAD_VARS->current_pool;
	if (pool)
		[pool addObject: anObj];
	else
		{
		NSAutoreleasePool *arp = [NSAutoreleasePool new];	// we need one for NSString and NSLog...

		if (anObj)
			NSLog(@"autorelease called without pool for object (%@) \
				  of class %s\n", anObj,
				  [NSStringFromClass([anObj class]) cString]);
		else
			NSLog(@"autorelease called without pool for nil object.\n");
#if 1
		abort();
#endif
		[arp release];
		}
}

- (void) addObject:(id) anObj
{
#if 0
	[anObj class];	// objects put into the ARP should be able to respond to messages
#endif
	if(!anObj)
		[NSException raise: NSGenericException
					format: @"AutoreleasePool can't store nil object."];
	// do nothing if global, static variable __autoreleaseEnabled is not set
	if (!__autoreleaseEnabled)
		return;
#if 0
	fprintf(stderr, "ARP %p: -addObject:%p [%s autorelease]\n", self, anObj, class_getName(object_getClass(anObj)));
#endif
	// for debugging if setPoolCountThreshhold was lowered
	if (_released_count >= __poolCountThreshold)
		[NSException raise: NSGenericException
					format: @"AutoreleasePool count threshold exceeded."];

	if (_released->count == _released->size)
		{ // Get new array for the list, if the current one is full.
#if 0
			fprintf(stderr, "ARP %p: -addObject - count=%u chain=%u size=%u\n", self, _released_count, _released->count, _released->size);
#endif
			if (_released->next)
				{ // There is an already-allocated one in the chain; use it.
					_released = _released->next;
					_released->count = 0;
#if 0
					fprintf(stderr, "ARP %p: -addObject - use it - count=%u chain=%u size=%u\n", self, _released_count, _released->count, _released->size);
#endif
				}
			else
				{ // We are at the end of the chain, and need to allocate a new one.
					struct autorelease_array_list *new_released;
					unsigned new_size = _released->size * 2;	// make it twice as big as the current one

					new_released = (struct autorelease_array_list*)
					objc_malloc(sizeof(struct autorelease_array_list)
								+ (new_size * sizeof(id)));
					new_released->next = NULL;
					new_released->size = new_size;
					new_released->count = 0;
					_released->next = new_released;
					_released = new_released;
#if 0
					fprintf(stderr, "ARP %p: -addObject - new - count=%u chain=%u size=%u\n", self, _released_count, _released->count, _released->size);
#endif
				}
		}
	// Put object at end of the list
	_released->objects[_released->count++] = anObj;
	// Keep track of the total number of objects autoreleased across all pools.
	THREAD_VARS->total_objects_count++;

	// Track total number of objects autoreleased in this pool
	_released_count++;
#if 0
	fprintf(stderr, "ARP %p: -addObject - done count=%u chain=%u size=%u\n", self, _released_count, _released->count, _released->size);
#endif
}

static void drain(NSAutoreleasePool *self)
{
	struct autorelease_array_list *released;
#if 0
	fprintf(stderr, "ARP %p: drain() - initial memory=%lu count=%u\n", self, NSRealMemoryAvailable(), self->_released_count);
#endif
	// If there are NSAutoreleasePools below us in the
	// stack of NSAutoreleasePools, then deallocate
	// them also.  The (only) way we could get in this
	// situation (in correctly written programs, that
	// don't release NSAutoreleasePools in weird ways),
	// is if an exception threw us up the stack.
	if (self->_child)
		{
		// CHECKME: release? If someone retained the ARP?
#if 0
		fprintf(stderr, "ARP %p: drain() - child dealloc %p\n", self, self->_child);
#endif
		[self->_child dealloc];
		self->_child=nil;
		}
	for(released = self->_released_head; released; released=released->next)
		{ // just release objects added to array containers
			id *p=released->objects;
			while(released->count > 0)
				{
				id anObject=*p;
#if 0
				// CHECKME: what is this check good for if we use released->count?
				if(!anObject)
					fprintf(stderr, "ARP %p: drain() - release nil?\n", self);
#endif
#if 0
				fprintf(stderr, "ARP %p: drain() - release obj=%p\n", self, anObject);
#endif
				[anObject release];
				p++;
				released->count--;
				self->_released_count--;
				}
		}
#if 0
	fprintf(stderr, "ARP %p: drain() - final memory=%lu count=%u allocated=%u\n", self, NSRealMemoryAvailable(), self->_released_count, __NSAllocatedObjects);
#endif
}

- (void) drain
{
	drain(self);
}

- (void) dealloc
{
	struct autorelease_thread_vars *tv;
	NSAutoreleasePool **cp;
	struct autorelease_array_list *released;
#if 0
	fprintf(stderr, "ARP %p: -dealloc\n", self);
#endif
	drain(self);	// drain the pool objects
	tv = THREAD_VARS;
	cp = &(tv->current_pool); 	// current pool
	*cp = _parent;	// install our parent pool as the new current pool
	if (*cp)
		(*cp)->_child = nil;
	if(!__enableCache || tv->thread_in_dealloc)
		{ // cleanup if cache disabled or thread in dealloc
			struct autorelease_array_list *next;
			for(released = _released_head; released; released=next)
				{ // release array container chain
					next = released->next;
					objc_free(released);
				}
			// NO!?			_released_head=NULL;	// will dealloc anyways
			if(!(_parent))
				{ // if no parent we are top pool
					while(tv->pool_cache_count)
						{ // release inactive pools in the pools stack cache
							NSAutoreleasePool *pool = pop_pool_from_cache(tv);
							NSDeallocateObject(pool);	// ignore retainCount
						}
					if (tv->pool_cache)
						{
						OBJC_FREE(tv->pool_cache);
						tv->pool_cache=NULL;
						}
				}
			[super dealloc];
		}
	else
		push_pool_to_cache (tv, self);	// Don't deallocate self, just push to cache for later use
#if 0
	fprintf(stderr, "ARP %p: dealloc - done memory=%lu\n", self, NSRealMemoryAvailable());
#endif
}

- (id) retain
{
#if 1
	fprintf(stderr, "ARP %p: retain - don't call!\n", self);
	abort();
#endif
	[NSException raise: NSGenericException
				format: @"Don't call `-retain' on NSAutoreleasePool"];
	return self;
}

- (id) autorelease
{
#if 1
	fprintf(stderr, "ARP %p: autorelease - don't call!\n", self);
	abort();
#endif
	[NSException raise: NSGenericException
				format: @"Don't call `-autorelease' on NSAutoreleasePool"];
	return self;
}

@end
