/*$Id: SenTestInvocationEnumerator.m,v 1.3 2005/04/02 03:18:21 phink Exp $*/

// Copyright (c) 1997-2005, Sen:te (Sente SA).  All rights reserved.
//
// Use of this source code is governed by the following license:
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// (1) Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.
//
// (2) Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS ``AS IS''
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
// IN NO EVENT SHALL Sente SA OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
// HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Note: this license is equivalent to the FreeBSD license.
//
// This notice may not be removed from this file.

#import "SenTestInvocationEnumerator.h"

// FIXME: MacOS has deprecated class_nextMethodList and recommends class_copymethodList
// https://developer.apple.com/reference/objectivec/1418490-class_copymethodlist
// https://developer.apple.com/library/prerelease/content/releasenotes/Cocoa/RN-ObjectiveC/index.html#//apple_ref/doc/uid/TP40004309-CH1-DontLinkElementID_6

#define GNUSTEP

@implementation SenTestInvocationEnumerator

+ (id) instanceInvocationEnumeratorForClass:(Class) aClass
{
	return [[[self alloc] initForClass:aClass] autorelease];
}


- (void) goNextMethodList
{
#if defined (GNUSTEP) || defined(__mySTEP__)
	// not used
#else
	mlist = class_nextMethodList (class, &iterator);
	count = (mlist != NULL) ? mlist->method_count - 1 : -1;
#endif
}


- (id) initForClass:(Class) aClass
{
#if 0
	NSLog(@"SenTestInvocationEnumerator initForClass:%@", NSStringFromClass(aClass));
#endif
	if(self = [super init])
		{
		class = aClass;
		iterator = NULL;
		[self goNextMethodList];
		}
	return self;
}


- (id) nextObject
{
#if defined (GNUSTEP) || defined(__mySTEP__)
	NSInvocation *invocation;
	SEL nextSelector;
#if 0
	NSLog(@"SenTestInvocationEnumerator nextObject: mlist=%p iterator=%p count=%lu", mlist, iterator, count);
#endif
	if(iterator == NULL)
		mlist=iterator=(void *) class_copyMethodList(class, (unsigned int *) &count);	// initialize
	if(count == 0)
		{ // end of list
			if(mlist)
				free(mlist);
			mlist=NULL;
#if 0
			NSLog(@"SenTestInvocationEnumerator: end of list");
#endif
			return nil;
		}
	nextSelector=method_getName(*(Method *)iterator);
	// compiler rejects ((Method *) iterator)++ or +=1
	iterator=((Method *) iterator)+1, count--;
#if 0
	NSLog(@"selector = %@", NSStringFromSelector(nextSelector));
#endif
	invocation=[NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:nextSelector]];
	[invocation setSelector:nextSelector];
	return invocation;
#else
	if (mlist == NULL) {
		return nil;
	}
	else {
		SEL nextSelector = mlist->method_list[count].method_name;
		count--;
		if (count == -1) {
			[self goNextMethodList];
		}
		if (sel_isMapped(nextSelector)) {
#if 0
			NSLog(@"SenTestInvocationEnumerator nextObject: create invocation for %@", NSStringFromSelector(nextSelector));
#endif
			NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[class instanceMethodSignatureForSelector:nextSelector]];
			[invocation setSelector:nextSelector];
			return invocation;
		}
		else {
			return [self nextObject];
		}
	}
#endif
}

- (NSArray *) allObjects
{
	NSMutableArray *array = [NSMutableArray array];
	id each;

	while ( (each = [self nextObject]) ) {
		[array addObject:each];
	}
	return array;
}

@end
