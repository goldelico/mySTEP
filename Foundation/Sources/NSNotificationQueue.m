/*
 NSNotificationQueue.m

 Copyright (C) 1995, 1996 Ovidiu Predescu and Mircea Oancea.
 All rights reserved.

 Author: Mircea Oancea <mircea@jupiter.elcom.pub.ro>

 This file is part of the mySTEP Library and is provided under the
 terms of the libFoundation BSD type license (See the Readme file).
 */

#import <Foundation/NSRunLoop.h>
#import <Foundation/NSNotificationQueue.h>
#import <Foundation/NSNotification.h>
#import <Foundation/NSDictionary.h>
#import <Foundation/NSArray.h>
#import <Foundation/NSString.h>
#import <Foundation/NSThread.h>

typedef struct _InstanceList {
	struct _InstanceList *next;
	struct _InstanceList *prev;
	id queue;
} _NSQueueInstanceList;

typedef struct _NSNotificationQueue_t {
#ifndef __APPLE__
	@defs(NSNotificationQueue)
#else
	struct _NSNotificationQueue_t *head, *_idleQueue, *_asapQueue;
#endif
} NSNotificationQueue_t;

// Class variables
static _NSQueueInstanceList *__notificationQueues = NULL;	// this is a list/queue of all NSNotificationQueues
static NSNotificationQueue *__defaultQueue = nil;

/*
	Queue layout

	Queue             Elem              Elem              Elem
	head ---------> prev -----------> prev -----------> prev --> nil
	nil <-- next <----------- next <----------- next
	tail --------------------------------------------->
 */


@interface _NSQueueRegistration : NSObject
{
@public
	_NSQueueRegistration *next;
	_NSQueueRegistration *prev;
	NSNotification *notification;
	id name;
	id object;
	NSArray *modes;
}

@end
@implementation _NSQueueRegistration

- (NSString *) description
{
	return [NSString stringWithFormat:@"%@ %p: %@ %@ %@", NSStringFromClass([self class]), self, name, modes, notification];
}

@end

typedef struct _NSNotificationQueueList {
	_NSQueueRegistration *head;
	_NSQueueRegistration *tail;
} NSNotificationQueueList;

@interface NSNotification (NSPrivate)

- (void) _addToQueue:(NSNotificationQueueList *)queue
			forModes:(NSArray *)modes;

@end

@implementation NSNotification (NSPrivate)

- (void) _makeSignalSafe
{ /* avoid memory allocation when calling _addToQueue:forModes: */
	if(!_queued)
		_queued = [_NSQueueRegistration new];	/* pre-allocate */
}

- (void) _addToQueue:(NSNotificationQueueList *)queue
			forModes:(NSArray *)modes
{
	if(!_queued)
		_queued = [_NSQueueRegistration new];
	else if(((_NSQueueRegistration *)_queued)->notification)
		{
		NSLog(@"warning: notification %@ to be queued is already in queue\n", self);
		return;
		}

	((_NSQueueRegistration *)_queued)->notification = [self retain];
	((_NSQueueRegistration *)_queued)->name = _name;
	((_NSQueueRegistration *)_queued)->object = _object;
	if(modes)
		((_NSQueueRegistration *)_queued)->modes = [modes copy];
	((_NSQueueRegistration *)_queued)->prev = NULL;
	((_NSQueueRegistration *)_queued)->next = queue->tail;
	queue->tail = _queued;

	if (((_NSQueueRegistration *)_queued)->next)
		((_NSQueueRegistration *)_queued)->next->prev = _queued;
	if (!queue->head)
		queue->head = _queued;
}

@end

@interface NSNotificationQueue (Private)

- (void) _postNotification:(NSNotification*) notification
				  forModes:(NSArray*) modes
					 queue:(NSNotificationQueueList *) queue
					  item:(_NSQueueRegistration *) item;

@end



static void
_NSRemoveFromQueue(NSNotificationQueueList *queue, _NSQueueRegistration *item)
{
#if 0
	NSLog(@"_NSRemoveFromQueue: %@", item);
#endif
	if (item->prev)
		item->prev->next = item->next;
	else if ((queue->tail = item->next))
		item->next->prev = NULL;

	if (item->next)
		item->next->prev = item->prev;
	else if ((queue->head = item->prev))
		item->prev->next = NULL;

	if (item->modes)
		[item->modes release];
	[item->notification release];
	item->notification = nil;
}

@implementation NSNotificationQueue

+ (void) initialize
{
	if (!__defaultQueue)
		__defaultQueue = [[self alloc] init];
}

+ (NSNotificationQueue*) defaultQueue		{ return __defaultQueue; }

- (id) init
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	return [self initWithNotificationCenter: nc];
}

- (id) initWithNotificationCenter:(NSNotificationCenter*)notificationCenter
{
	_NSQueueInstanceList *regItem;

	_center = [notificationCenter retain];					// init queue
	_asapQueue = objc_calloc(1, sizeof(NSNotificationQueueList));
	_idleQueue = objc_calloc(1, sizeof(NSNotificationQueueList));

	regItem = objc_calloc(1, sizeof(_NSQueueInstanceList));			// insert in global
	regItem->next = __notificationQueues;					// list of queues
	regItem->queue = self;
	__notificationQueues = regItem;

	return self;
}

- (void) dealloc
{
	_NSQueueInstanceList *regItem, *theItem;
	_NSQueueRegistration *item;
	_NSQueueInstanceList *queues = __notificationQueues;	// remove from class instances list

	if (queues->queue == self)
		__notificationQueues = __notificationQueues->next;
	else
		{
		for(regItem=__notificationQueues; regItem->next; regItem=regItem->next)
			if (regItem->next->queue == self)
				{
				theItem = regItem->next;
				regItem->next = theItem->next;
				objc_free(theItem);
				break;
				}		}
	// release self
	for (item = _asapQueue->head; item; item = item->prev)
		_NSRemoveFromQueue(_asapQueue, item);
	objc_free(_asapQueue);

	for (item = _idleQueue->head; item; item=item->prev)
		_NSRemoveFromQueue(_idleQueue, item);
	objc_free(_idleQueue);

	[_center release];
	[super dealloc];
}

- (void) dequeueNotificationsMatching:(NSNotification*)notification
						 coalesceMask:(NSUInteger)coalesceMask
{
	_NSQueueRegistration *item;					// Inserting and Removing
	_NSQueueRegistration *next;					// Notifications From a Queue
	id name = [notification name];
	id object = [notification object];
#if 0
	NSLog(@"dequeueNotificationsMatching:%@ coalesceMask: %u name: %@ object: %@",
		  notification,
		  coalesceMask,
		  name,
		  object);
#endif
	// find in asap notification queue
	for (item = _asapQueue->tail; item; item = next)
		{
		next = item->next;
		if (((!(coalesceMask & NSNotificationCoalescingOnName) || [name isEqual:item->name]) &&
			 !(coalesceMask & NSNotificationCoalescingOnSender)) || (object == item->object))
			{
			_NSRemoveFromQueue(_asapQueue, item);
			continue;
			}
		}
	// find in idle notification queue
	for (item = _idleQueue->tail; item; item = next)
		{
		next = item->next;
		if (((!(coalesceMask & NSNotificationCoalescingOnName) || [name isEqual:item->name]) &&
			 !(coalesceMask & NSNotificationCoalescingOnSender)) || (object == item->object))
			{
			_NSRemoveFromQueue(_idleQueue, item);
			continue;
			}
		}
}

- (void) enqueueNotification:(NSNotification*)notification
				postingStyle:(NSPostingStyle)postingStyle
{
	[self enqueueNotification:notification
				 postingStyle:postingStyle
				 coalesceMask:NSNotificationCoalescingOnName
	 | NSNotificationCoalescingOnSender
					 forModes:nil];
}

- (void) enqueueNotification:(NSNotification*)notification
				postingStyle:(NSPostingStyle)postingStyle
				coalesceMask:(NSUInteger)coalesceMask
					forModes:(NSArray*)modes
{
#if 0
	NSLog(@"enqueue:%@ postingStyle %u coalesceMask: %lu forModes: %@",
		  notification,
		  postingStyle,
		  (unsigned long)coalesceMask,
		  modes);
#endif
	if (coalesceMask != NSNotificationNoCoalescing)
		[self dequeueNotificationsMatching:notification
							  coalesceMask:coalesceMask];

	switch (postingStyle) {
		case NSPostNow:
			[self _postNotification:notification forModes:modes queue:NULL item:NULL];
			break;
		case NSPostASAP:
			[notification _addToQueue:_asapQueue forModes:modes];
			break;
		case NSPostWhenIdle:
			[notification _addToQueue:_idleQueue forModes:modes];
			break;
	}
}

- (void) _postNotification:(NSNotification*) notification
				  forModes:(NSArray*) modes
					 queue:(NSNotificationQueueList *) queue
					  item:(_NSQueueRegistration *) item
{
	NSString *mode;	// check to see if run loop is in a valid mode
#if 0
	NSLog(@"postNotification: %@ forModes: %@", notification, modes);
#endif
	if (!modes || !(mode = [[NSRunLoop currentRunLoop] currentMode]) || [modes containsObject:mode])	// if no modes (i.e. all) or specific mode is valid then post
		{
		[notification retain];
		if(queue && item)
			_NSRemoveFromQueue(queue, item);	// remove *before* posting the notification so that the handler can dequeue/enqueue with coalescing etc.
		[_center postNotification:notification];
		[notification release];
		}
}

- (void) _notifyIdle
{ // post all IDLE notifications in queue that match the current mode
	_NSQueueRegistration *item = _idleQueue->head;
	while(item)
		{
		_NSQueueRegistration *n = item->prev;	// get next before removing item
#if 0
		NSAssert(item->notification, @"should not be nil");
#endif
		[self _postNotification:item->notification forModes:item->modes queue:_idleQueue item:item];
		item=n;
		}
}

- (void) _notifyASAP
{ // post all ASAP notifications in queue that match the current mode
	_NSQueueRegistration *item = _asapQueue->head;
	while(item)
		{
		_NSQueueRegistration *n = item->prev;	// get next before removing item
#if 0
		NSAssert(item->notification, @"should not be nil");
#endif
		[self _postNotification:item->notification forModes:item->modes queue:_asapQueue item:item];
		item=n;
		}
}

+ (BOOL) _runLoopMore
{ // return YES if the idle or asap queue is not empty - this makes the runloop timeout immediately
	_NSQueueInstanceList *item;
#if 0
	NSLog(@"_runLoopMore mode=%@", [[NSRunLoop currentRunLoop] currentMode]);
#endif
	for (item = __notificationQueues; item; item = item->next)
		{
		if(((NSNotificationQueue_t *)item->queue)->_idleQueue->head)
			return YES;	// found something
		if(((NSNotificationQueue_t *)item->queue)->_asapQueue->head)
			return YES;	// found something
		}
#if 0
	NSLog(@"_runLoopMore: no");
#endif
	return NO;
}

+ (void) _runLoopIdle
{ // trigger the Idle items
	_NSQueueInstanceList *item;
#if 0
	NSLog(@"_runLoopIdle mode=%@", [[NSRunLoop currentRunLoop] currentMode]);
#endif
	for (item = __notificationQueues; item; item = item->next)
		if(((NSNotificationQueue_t *)item->queue)->_idleQueue->head)
			[item->queue _notifyIdle];
}

+ (void) _runLoopASAP
{ // trigger the ASAP items
	_NSQueueInstanceList *item;
#if 0
	NSLog(@"_runLoopASAP mode=%@", [[NSRunLoop currentRunLoop] currentMode]);
#endif
	for (item = __notificationQueues; item; item = item->next)
		if(((NSNotificationQueue_t *)item->queue)->_asapQueue->head)
			[item->queue _notifyASAP];
}

@end
