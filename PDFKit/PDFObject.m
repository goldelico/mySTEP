//
//  PDFObject.m
//  PDFKit
//
//  Created by Dr. H. Nikolaus Schaller on Fri Nov 9 2005.
//  Copyright (c) 2005 DSITRI. All rights reserved.
//

#import "PDFKitPrivate.h"

@implementation NSObject (PDFKit) 
- (BOOL) isPDFAtom; { return NO; } 
- (BOOL) isPDFIndirect; { return NO; }
- (BOOL) isPDFKeyword; { return NO; } 
- (BOOL) isPDFKeyword:(NSString *) str; { return NO; }
- (NSData *) _PDFDataRepresentation; { NIMP; return nil; }	// generic object has no representation
@end

@implementation NSDictionary (PDFKit)

- (id) _objectAtIndexInNameTree:(NSString *) str;
{
	return nil;
}

- (id) _objectAtIndexInNumberTree:(int) num;
{
	id kid, numObj;
	NSEnumerator *e;
	NSArray *nums;
#if 0
	NSLog(@"_objectAtIndexInNumberTree:%d in %@", num, self);
#endif
	nums=[[self objectForKey:@"Nums"] self];
	if(nums)
		{ // this is a leaf tree node
#if 0
		NSLog(@"Nums=%@", nums);
#endif
		e=[nums objectEnumerator];	// go through all entries
		while((numObj=[e nextObject]))
			{
#if 0
			NSLog(@"numObj=%@", numObj);
#endif
			if([numObj intValue] == num)
				return [e nextObject];	// value found
			[e nextObject];	// skip value
			}
		return nil;	// not found
		}
	e=[[[self objectForKey:@"Kids"] self] objectEnumerator];	// go through kids-array
	while((kid=[[e nextObject] self]))
		{ // find the one where index is within limits
		NSArray *limits;
		limits=[[kid objectForKey:@"Limits"] self];
#if 1
		NSLog(@"limits=%@", limits);
#endif
		if(num >= [[limits objectAtIndex:0] intValue] && num <= [[limits objectAtIndex:1] intValue])
			return [kid _objectAtIndexInNumberTree:num];	// must be in that subnode or its descendants
		}
	return nil;	// out of range
}

- (id) _objectAtIndexInPageTree:(unsigned) num ofDocument:(PDFDocument *) doc parentIndex:(unsigned *) idx;
{ // we must be a tree node
	id kidRef, kid;
	unsigned dummy;
	NSEnumerator *e=[[[self objectForKey:@"Kids"] self] objectEnumerator];	// go through kids-array
	if(!idx)
		idx=&dummy;
	for(*idx=0; (kidRef=[e nextObject]); (*idx)++)
		{
		unsigned cnt;
		kid=[kidRef self];	// fetch and cache if required
		if([kid isKindOfClass:[PDFPage class]])
			{ // cached page wrapper
			if(num == 0)
				return kid;	// yes!
			num--;	// skip
			continue;
			}
		if([[kid objectForKey:@"Type"] isEqualToString:@"Page"])
			{ // page node
			if(num == 0)
				{ // wrap NSDictionary in PDFPage object and store in catalog so that we always get this wrapper - even if pages are moved around
				kid=[[[PDFPage alloc] _initWithDocument:doc andPageDictionary:kid] autorelease];
				[kidRef setObject:kid];
				return kid;	// new wrapper
				}
			num--;
			continue;	// try next one
			}
		cnt=[[kid objectForKey:@"Count"] unsignedIntValue];	// is a pages node; get total number of leafs
		if(num < cnt)
			return [kid _objectAtIndexInPageTree:num ofDocument:doc parentIndex:idx];	// must be in that subnode
		num-=cnt;	// skip cnt entries and try next one
		}
	return nil;	// out of range
}

- (unsigned) _treeCount;
{ // recursively count number of entries in page/number/name tree
	if([self isKindOfClass:[NSDictionary class]])
		{ // sum up subnodes
		unsigned sum=0;
		NSEnumerator *e;
		id obj;
		e=[[[self objectForKey:@"Kids"] self] objectEnumerator];	// enumerates objects/references
		while((obj=[e nextObject]))
			sum+=[[obj self] _treeCount];
		return sum;
		}
	return 1;
}

- (NSData *) _PDFDataRepresentation;
{
	// glue together
	return nil;
}

@end

@implementation PDFAtom
- (NSString *) description; { return [NSString stringWithFormat:@"/%@", _string]; }
- (NSData *) _PDFDataRepresentation;
{
	// glue together
	return nil;
}

- (BOOL) isPDFAtom; { return YES; } 
- (id) initWithString:(NSString *) str;
{
	if((self=[super init]))
		_string=[str retain];
	return self;
}
- (void) dealloc; { [_string release]; [super dealloc]; }
- (NSString *) value; { return _string; }
- (BOOL) isEqualToString:(NSString *) str; { return [_string isEqualToString:str]; }
@end

@implementation PDFKeyword
- (NSString *) description; { return [NSString stringWithFormat:@"%@", _string]; }
- (BOOL) isPDFAtom; { return NO; } 
- (BOOL) isPDFKeyword; { return YES; } 
- (BOOL) isPDFKeyword:(NSString *) str; { return [_string isEqualToString:str]; } 
@end

@implementation PDFReference 
- (NSData *) _PDFDataRepresentation;
{
	// glue together
	return nil;
}

- (NSString *) description; { return [NSString stringWithFormat:@"%u %u R -> %@", ref1, ref2, ref?[ref object]:@"?"]; }

+ (id) keyForNumber:(unsigned) r1 andGeneration:(unsigned) r2;
{ // make dictionary hash key
	return [NSNumber numberWithLong:100000*r1+r2];
}

- (BOOL) isPDFIndirect; { return YES; } 

- (id) initWithNumber:(unsigned) r1 andGeneration:(unsigned) r2 forDocument:(PDFDocument *) doc;  // create reference 
{
	if((self=[super init]))
		{
		// hier gleich den Key generieren und speichern
		ref1=r1;
		ref2=r2;
		data=doc;
		}
	return self;
}

- (void) dealloc;
{
	[ref release];
	[super dealloc];
}

- (id) self;
{ // load indirect object (if possible)
	if(!ref)
		ref=[[data _catalogEntryForObject:ref1 generation:ref2] retain];	// search in catalog
	return [ref object];	// get object
}

- (void) setObject:(id) obj;
{ // replace referenced object in catalog
	[ref setObject:obj];
}

@end

@implementation PDFCrossReference

- (id) initWithData:(NSData *) data pos:(unsigned) pos number:(unsigned) num generation:(unsigned) gen isFree:(BOOL) flag;
{
	if((self=[super init]))
		{
		// we don't save the number?
		_data=data;
		_position=pos;
		_generation=gen;	// why do we save the generation?
		_isFree=flag;
#if 0
		NSLog(@"%u(%u): %u%@", num, gen, pos, flag?@" free":@"");
#endif
		}
	return self;
}

- (void) dealloc;
{
	[_object release];
	[super dealloc];
}

- (NSString *) description;
{
	return [NSString stringWithFormat:@"%@: %u %u%@ obj: %u -> %@",
		NSStringFromClass([self class]),
		0/* num */, _generation, _isFree?@" free":@"",
		_position, _object];
}

- (NSData *) data; { return _data; }
- (unsigned) position; { return _position; }
- (id) object; { return _object; }
- (void) setObject:(id) obj; { [_object autorelease]; _object=[obj retain]; }

@end