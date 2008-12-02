//
//  NSZone.h
//  mySTEP
//
//  Created by Dr. H. Nikolaus Schaller on Wed Dec 28 2005.
//  Copyright (c) 2005 DSITRI.
//
//  H.N.Schaller, Dec 2005 - API revised to be compatible to 10.4
//
//  This file is part of the mySTEP Library and is provided
//  under the terms of the GNU Library General Public License.
//

#import <Foundation/NSObjCRuntime.h>

typedef void NSZone;					// simplified definition for mySTEP

#define NSDefaultMallocZone() ((NSZone *) 1)	// zones are ignored
#define NSZoneCalloc(zone, numElems, byteSize)	objc_calloc(numElems, byteSize)
#define NSZoneFree(zone, pointer)				objc_free(pointer)
#define NSZoneMalloc(zone, size)				objc_malloc(size)
#define NSZoneRealloc(zone, ptr, size)			objc_realloc(ptr, size)

/* NSGarbageCollector.h */

enum {
	NSScannedOption = (1<<0),
	NSCollectorDisabledOption = (2<<0),
};

extern NSUInteger NSLogPageSize(void);
extern void *__strong NSAllocateCollectable(NSUInteger size, NSUInteger opts);
extern void * NSAllocateMemoryPages(NSUInteger bytes);
/* EOF */
